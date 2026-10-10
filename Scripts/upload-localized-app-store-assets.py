#!/usr/bin/env python3
"""Create localized product pages and upload iPhone Duo creative assets.

The uploader uses the App Store Connect 4.5 asset-library endpoints. It is
resume-safe: each generated image has a checksum-based reference name and an
existing placement is reused instead of uploaded again.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import tempfile
import time
from pathlib import Path

import jwt
import requests


ROOT = Path(__file__).resolve().parents[1]
API_ROOT = "https://api.appstoreconnect.apple.com/v1"
APP_ID = "6816682268"
VERSION = "1.0"
PLATFORM = "IOS"
SUPPORT_URL = "https://github.com/lanray07/Lift-Relay/blob/main/SUPPORT.md"
MARKETING_URL = "https://github.com/lanray07/Lift-Relay"

SCREENSHOT_GROUP = "IPHONE_DUO_PROFILE"
DEFAULT_GROUP = "DEFAULT_PROFILE"


def token() -> str:
    now = int(time.time())
    return jwt.encode(
        {"iss": os.environ["API_ISSUER_ID"], "iat": now, "exp": now + 1200,
         "aud": "appstoreconnect-v1"},
        os.environ["API_PRIVATE_KEY"], algorithm="ES256",
        headers={"kid": os.environ["API_KEY_ID"], "typ": "JWT"},
    )


class ASC:
    def __init__(self, apply: bool) -> None:
        self.apply = apply
        self.session = requests.Session()
        self.session.headers.update({"Authorization": f"Bearer {token()}", "Content-Type": "application/json"})

    def request(self, method: str, path: str, **kwargs) -> dict | None:
        if method != "GET" and not self.apply:
            print(f"PLAN {method} {path}")
            return None
        response = self.session.request(method, f"{API_ROOT}{path}", timeout=120, **kwargs)
        if not response.ok:
            raise RuntimeError(f"ASC {method} {path} failed ({response.status_code}): {response.text}")
        if response.status_code == 204 or not response.content:
            return None
        return response.json()


def one(items: list[dict], label: str) -> dict:
    if len(items) != 1:
        raise RuntimeError(f"Expected one {label}; found {len(items)}")
    return items[0]


def fit_keywords(value: str) -> str:
    selected: list[str] = []
    for term in (part.strip() for part in value.split(",")):
        if not term:
            continue
        candidate = ",".join([*selected, term])
        if len(candidate.encode("utf-8")) <= 100:
            selected.append(term)
    return ",".join(selected)


def version_resource(api: ASC) -> dict:
    data = api.request(
        "GET", f"/apps/{APP_ID}/appStoreVersions",
        params={"filter[platform]": PLATFORM, "filter[versionString]": VERSION,
                "fields[appStoreVersions]": "versionString,platform,appStoreState", "limit": 10},
    )["data"]
    return one(data, "iOS app version 1.0")


def version_localizations(api: ASC, version_id: str) -> dict[str, dict]:
    data = api.request(
        "GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations",
        params={"fields[appStoreVersionLocalizations]": "locale,description,keywords,marketingUrl,promotionalText,supportUrl",
                "limit": 200},
    )["data"]
    return {item["attributes"]["locale"]: item for item in data}


def ensure_version_localization(api: ASC, version_id: str, locale: str, copy: dict,
                                existing: dict[str, dict]) -> str | None:
    attributes = {
        "locale": locale,
        "description": copy["description"],
        "keywords": fit_keywords(copy["keywords"]),
        "marketingUrl": MARKETING_URL,
        "promotionalText": copy["promotionalText"],
        "supportUrl": SUPPORT_URL,
    }
    if locale in existing:
        localization_id = existing[locale]["id"]
        api.request("PATCH", f"/appStoreVersionLocalizations/{localization_id}", json={
            "data": {"type": "appStoreVersionLocalizations", "id": localization_id,
                     "attributes": {key: value for key, value in attributes.items() if key != "locale"}}
        })
        return localization_id
    response = api.request("POST", "/appStoreVersionLocalizations", json={
        "data": {
            "type": "appStoreVersionLocalizations", "attributes": attributes,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
        }
    })
    return response["data"]["id"] if response else None


def app_info_resource(api: ASC) -> dict:
    data = api.request("GET", f"/apps/{APP_ID}/appInfos", params={"limit": 20})["data"]
    if not data:
        raise RuntimeError("No appInfo resource found")
    return data[0]


def app_info_localizations(api: ASC, app_info_id: str) -> dict[str, dict]:
    data = api.request(
        "GET", f"/appInfos/{app_info_id}/appInfoLocalizations",
        params={"fields[appInfoLocalizations]": "locale,name,subtitle", "limit": 200},
    )["data"]
    return {item["attributes"]["locale"]: item for item in data}


def ensure_app_info_localization(api: ASC, app_info_id: str, locale: str, copy: dict,
                                 existing: dict[str, dict]) -> None:
    attributes = {"name": copy["name"], "subtitle": copy["subtitle"]}
    if locale in existing:
        localization_id = existing[locale]["id"]
        api.request("PATCH", f"/appInfoLocalizations/{localization_id}", json={
            "data": {"type": "appInfoLocalizations", "id": localization_id, "attributes": attributes}
        })
        return
    api.request("POST", "/appInfoLocalizations", json={
        "data": {
            "type": "appInfoLocalizations", "attributes": {"locale": locale, **attributes},
            "relationships": {"appInfo": {"data": {"type": "appInfos", "id": app_info_id}}},
        }
    })


def upload_bytes(operations: list[dict], contents: bytes) -> None:
    for operation in operations:
        headers = {header["name"]: header["value"] for header in operation.get("requestHeaders", [])}
        offset, length = operation["offset"], operation["length"]
        response = requests.request(operation["method"], operation["url"], headers=headers,
                                    data=contents[offset:offset + length], timeout=240)
        if not response.ok:
            raise RuntimeError(f"Asset upload failed ({response.status_code}): {response.text}")


def find_asset(api: ASC, library_id: str, reference_name: str) -> dict | None:
    data = api.request(
        "GET", f"/appAssetLibraries/{library_id}/images",
        params={"filter[referenceName]": reference_name,
                "fields[appAssetLibraryImages]": "fileName,referenceName,specId,state,stateDetails", "limit": 10},
    )["data"]
    if len(data) > 1:
        raise RuntimeError(f"Multiple asset-library images use reference name {reference_name}")
    return data[0] if data else None


def wait_for_image(api: ASC, image_id: str) -> dict:
    deadline = time.time() + 10 * 60
    while time.time() < deadline:
        image = api.request(
            "GET", f"/appAssetLibraryImages/{image_id}",
            params={"fields[appAssetLibraryImages]": "fileName,referenceName,specId,state,stateDetails"},
        )["data"]
        state = image["attributes"].get("state")
        if state in {"COMPLETE", "PREPARE_FOR_SUBMISSION", "READY_FOR_REVIEW", "APPROVED"}:
            return image
        if state == "FAILED":
            raise RuntimeError(f"Apple failed to process {image['attributes']['fileName']}: "
                               f"{image['attributes'].get('stateDetails')}")
        time.sleep(4)
    raise TimeoutError(f"Timed out processing asset-library image {image_id}")


def ensure_image(api: ASC, library_id: str, path: Path, category: str, reference_prefix: str) -> str | None:
    contents = path.read_bytes()
    checksum = hashlib.sha256(contents).hexdigest()[:16]
    reference_name = f"lift-relay/{reference_prefix}/{path.name}/{checksum}"
    existing = find_asset(api, library_id, reference_name)
    if existing:
        print(f"Reusing {reference_name}")
        if api.apply:
            return wait_for_image(api, existing["id"])["id"]
        return existing["id"]
    if not api.apply:
        print(f"PLAN upload {path} as {category} ({reference_name})")
        return None
    image = api.request("POST", "/appAssetLibraryImages", json={
        "data": {
            "type": "appAssetLibraryImages",
            "attributes": {"category": category, "fileName": path.name,
                           "fileSize": len(contents), "referenceName": reference_name},
            "relationships": {"assetLibrary": {"data": {"type": "appAssetLibraries", "id": library_id}}},
        }
    })["data"]
    upload_bytes(image["attributes"]["uploadOperations"], contents)
    api.request("PATCH", f"/appAssetLibraryImages/{image['id']}", json={
        "data": {"type": "appAssetLibraryImages", "id": image["id"], "attributes": {"uploaded": True}}
    })
    return wait_for_image(api, image["id"])["id"]


def placement_exists(api: ASC, image_id: str, localization_id: str, placement_type: str,
                     placement_group: str) -> bool:
    data = api.request(
        "GET", f"/appAssetLibraryImages/{image_id}/placements",
        params={"fields[appAssetLibraryPlacements]": "placementType,placementGroup,appStoreVersionLocalization",
                "include": "appStoreVersionLocalization", "limit": 50},
    )
    included_ids = {item["id"] for item in data.get("included", [])
                    if item["type"] == "appStoreVersionLocalizations"}
    return any(
        item.get("attributes", {}).get("placementType") == placement_type
        and item.get("attributes", {}).get("placementGroup") == placement_group
        for item in data["data"]
    ) and localization_id in included_ids


def ensure_placement(api: ASC, image_id: str | None, localization_id: str | None,
                     placement_type: str, placement_group: str) -> str | None:
    if image_id is None or localization_id is None:
        print(f"PLAN placement {placement_type}/{placement_group}")
        return None
    if placement_exists(api, image_id, localization_id, placement_type, placement_group):
        print(f"Reusing placement {placement_type}/{placement_group} for {image_id}")
        return None
    response = api.request("POST", "/appAssetLibraryPlacements", json={
        "data": {
            "type": "appAssetLibraryPlacements",
            "attributes": {"placementType": placement_type, "placementGroup": placement_group},
            "relationships": {
                "image": {"data": {"type": "appAssetLibraryImages", "id": image_id}},
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": localization_id}
                },
            },
        }
    })
    return response["data"]["id"] if response else None


def locale_asset_files(locale_dir: Path) -> list[tuple[Path, str, str, str]]:
    screenshots: list[Path] = []
    for directory in (locale_dir / "iPhoneDuoOuter", locale_dir / "iPhoneDuoInner"):
        screenshots.extend(directory.glob("*.jpg"))
    screenshots.sort(key=lambda path: path.name)
    items = [(path, "APP_SCREENSHOTS_AND_PREVIEWS", "APP_SCREENSHOT", SCREENSHOT_GROUP)
             for path in screenshots]
    items.extend([
        (locale_dir / "ProductPage" / "header-3840x1646.jpg",
         "CREATIVE_ASSETS", "PRODUCT_PAGE_HEADER_ASSET", DEFAULT_GROUP),
        (locale_dir / "ProductPage" / "search-1920x1280.jpg",
         "CREATIVE_ASSETS", "APP_STORE_SEARCH_RESULTS_ASSET", DEFAULT_GROUP),
    ])
    return items


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="Perform writes; otherwise print a read-only plan")
    parser.add_argument("--locale", action="append", help="Process only these locales")
    args = parser.parse_args()
    metadata = json.loads((ROOT / "AppStore" / "metadata.json").read_text(encoding="utf-8"))
    localizations = metadata["localizations"]
    locales = args.locale or list(localizations)
    unknown = sorted(set(locales) - set(localizations))
    if unknown:
        raise SystemExit(f"Unknown locales: {', '.join(unknown)}")

    api = ASC(apply=args.apply)
    version = version_resource(api)
    version_existing = version_localizations(api, version["id"])
    app_info = app_info_resource(api)
    info_existing = app_info_localizations(api, app_info["id"])
    library_id = api.request("GET", f"/apps/{APP_ID}/assetLibrary")["data"]["id"]

    with tempfile.TemporaryDirectory(prefix="lift-relay-assets-") as temp:
        output_root = Path(temp)
        for locale in locales:
            copy = localizations[locale]
            print(f"\n=== {locale} ===", flush=True)
            localization_id = ensure_version_localization(
                api, version["id"], locale, copy, version_existing
            )
            ensure_app_info_localization(api, app_info["id"], locale, copy, info_existing)
            subprocess.run(
                ["python", str(ROOT / "Scripts" / "generate-app-store-assets.py"),
                 "--locale", locale, "--output", str(output_root)],
                cwd=ROOT, check=True,
            )
            for path, category, placement_type, placement_group in locale_asset_files(output_root / locale):
                if not path.exists():
                    raise RuntimeError(f"Missing generated asset {path}")
                image_id = ensure_image(api, library_id, path, category, f"{locale}/{placement_type}")
                ensure_placement(api, image_id, localization_id, placement_type, placement_group)
        print(f"\n{'Applied' if args.apply else 'Planned'} {len(locales)} localized product pages.")


if __name__ == "__main__":
    main()
