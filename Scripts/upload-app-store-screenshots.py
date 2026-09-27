#!/usr/bin/env python3
"""Upload and verify the English (U.K.) iPhone 6.5-inch App Store screenshots."""

from __future__ import annotations

import hashlib
import os
import time
from pathlib import Path

import jwt
import requests


API_ROOT = "https://api.appstoreconnect.apple.com/v1"
APP_ID = "6816682268"
VERSION = "1.0"
LOCALE = "en-GB"
DISPLAY_TYPE = "APP_IPHONE_65"


def make_token() -> str:
    now = int(time.time())
    return jwt.encode(
        {
            "iss": os.environ["API_ISSUER_ID"],
            "iat": now,
            "exp": now + 20 * 60,
            "aud": "appstoreconnect-v1",
        },
        os.environ["API_PRIVATE_KEY"],
        algorithm="ES256",
        headers={"kid": os.environ["API_KEY_ID"], "typ": "JWT"},
    )


class AppStoreConnect:
    def __init__(self) -> None:
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"Bearer {make_token()}",
                "Content-Type": "application/json",
            }
        )

    def request(self, method: str, path: str, **kwargs):
        response = self.session.request(method, f"{API_ROOT}{path}", timeout=90, **kwargs)
        if not response.ok:
            raise RuntimeError(
                f"App Store Connect {method} {path} failed "
                f"({response.status_code}): {response.text}"
            )
        if response.status_code == 204 or not response.content:
            return None
        return response.json()


def one(items: list[dict], label: str) -> dict:
    if len(items) != 1:
        raise RuntimeError(f"Expected one {label}, found {len(items)}")
    return items[0]


def main() -> None:
    screenshots_dir = Path("AppStore/Screenshots/EnglishUK/iPhone65")
    files = sorted(screenshots_dir.glob("*.png"))
    if len(files) != 10:
        raise RuntimeError(f"Expected 10 screenshots, found {len(files)}")

    api = AppStoreConnect()
    versions = api.request(
        "GET",
        f"/apps/{APP_ID}/appStoreVersions",
        params={
            "filter[platform]": "IOS",
            "filter[versionString]": VERSION,
            "fields[appStoreVersions]": "versionString,platform,appStoreState",
            "limit": 10,
        },
    )["data"]
    editable = [
        item
        for item in versions
        if item.get("attributes", {}).get("appStoreState") == "PREPARE_FOR_SUBMISSION"
    ]
    version = one(editable or versions, "editable iOS version 1.0")

    localizations = api.request(
        "GET",
        f"/appStoreVersions/{version['id']}/appStoreVersionLocalizations",
        params={"filter[locale]": LOCALE, "fields[appStoreVersionLocalizations]": "locale"},
    )["data"]
    localization = one(localizations, f"{LOCALE} localization")

    screenshot_sets = api.request(
        "GET",
        f"/appStoreVersionLocalizations/{localization['id']}/appScreenshotSets",
        params={"filter[screenshotDisplayType]": DISPLAY_TYPE},
    )["data"]
    if screenshot_sets:
        screenshot_set = one(screenshot_sets, f"{DISPLAY_TYPE} screenshot set")
    else:
        screenshot_set = api.request(
            "POST",
            "/appScreenshotSets",
            json={
                "data": {
                    "type": "appScreenshotSets",
                    "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
                    "relationships": {
                        "appStoreVersionLocalization": {
                            "data": {
                                "type": "appStoreVersionLocalizations",
                                "id": localization["id"],
                            }
                        }
                    },
                }
            },
        )["data"]

    existing = api.request(
        "GET",
        f"/appScreenshotSets/{screenshot_set['id']}/appScreenshots",
        params={
            "fields[appScreenshots]": "fileName,sourceFileChecksum,assetDeliveryState",
            "limit": 200,
        },
    )["data"]
    reusable_by_name: dict[str, list[dict]] = {}
    for item in existing:
        reusable_by_name.setdefault(item["attributes"]["fileName"], []).append(item)

    screenshot_ids: list[str] = []
    reused_ids: set[str] = set()
    for path in files:
        contents = path.read_bytes()
        checksum = hashlib.md5(contents, usedforsecurity=False).hexdigest()
        reusable = next(
            (
                item
                for item in reusable_by_name.get(path.name, [])
                if item["attributes"].get("sourceFileChecksum") == checksum
                and item["attributes"].get("assetDeliveryState", {}).get("state") == "COMPLETE"
            ),
            None,
        )
        if reusable is not None:
            screenshot_ids.append(reusable["id"])
            reused_ids.add(reusable["id"])
            print(f"Reused unchanged {path.name} ({reusable['id']})", flush=True)
            continue

        reservation = api.request(
            "POST",
            "/appScreenshots",
            json={
                "data": {
                    "type": "appScreenshots",
                    "attributes": {"fileSize": len(contents), "fileName": path.name},
                    "relationships": {
                        "appScreenshotSet": {
                            "data": {
                                "type": "appScreenshotSets",
                                "id": screenshot_set["id"],
                            }
                        }
                    },
                }
            },
        )["data"]

        for operation in reservation["attributes"]["uploadOperations"]:
            offset = operation["offset"]
            length = operation["length"]
            headers = {
                header["name"]: header["value"]
                for header in operation.get("requestHeaders", [])
            }
            response = requests.request(
                operation["method"],
                operation["url"],
                headers=headers,
                data=contents[offset : offset + length],
                timeout=180,
            )
            if not response.ok:
                raise RuntimeError(
                    f"Asset upload for {path.name} failed ({response.status_code}): {response.text}"
                )

        screenshot_id = reservation["id"]
        api.request(
            "PATCH",
            f"/appScreenshots/{screenshot_id}",
            json={
                "data": {
                    "type": "appScreenshots",
                    "id": screenshot_id,
                    "attributes": {
                        "uploaded": True,
                        "sourceFileChecksum": checksum,
                    },
                }
            },
        )
        screenshot_ids.append(screenshot_id)
        print(f"Committed {path.name} ({screenshot_id})", flush=True)

    deadline = time.time() + 8 * 60
    pending = set(screenshot_ids)
    while pending and time.time() < deadline:
        time.sleep(5)
        for screenshot_id in list(pending):
            screenshot = api.request(
                "GET",
                f"/appScreenshots/{screenshot_id}",
                params={"fields[appScreenshots]": "fileName,assetDeliveryState"},
            )["data"]
            delivery = screenshot["attributes"]["assetDeliveryState"]
            state = delivery["state"]
            if state == "COMPLETE":
                pending.remove(screenshot_id)
            elif state == "FAILED":
                raise RuntimeError(
                    f"Apple failed to process {screenshot['attributes']['fileName']}: "
                    f"{delivery.get('errors', [])}"
                )
        print(f"Waiting for Apple processing: {len(pending)} remaining", flush=True)

    if pending:
        raise TimeoutError(f"Timed out waiting for {len(pending)} screenshot(s)")

    api.request(
        "PATCH",
        f"/appScreenshotSets/{screenshot_set['id']}/relationships/appScreenshots",
        json={
            "data": [
                {"type": "appScreenshots", "id": screenshot_id}
                for screenshot_id in screenshot_ids
            ]
        },
    )
    obsolete_ids = [item["id"] for item in existing if item["id"] not in reused_ids]
    for screenshot_id in obsolete_ids:
        api.request("DELETE", f"/appScreenshots/{screenshot_id}")
        print(f"Removed superseded screenshot {screenshot_id}", flush=True)

    print("Reconciled, processed, and ordered all 10 iPhone screenshots.")


if __name__ == "__main__":
    main()
