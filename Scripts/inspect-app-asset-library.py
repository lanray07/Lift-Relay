#!/usr/bin/env python3
"""Read-only inspection of the App Store Connect 4.5 asset-library model."""

from __future__ import annotations

import json
import os
import time

import jwt
import requests


API_ROOT = "https://api.appstoreconnect.apple.com/v1"
APP_ID = "6816682268"


def token() -> str:
    now = int(time.time())
    return jwt.encode(
        {"iss": os.environ["API_ISSUER_ID"], "iat": now, "exp": now + 1200,
         "aud": "appstoreconnect-v1"},
        os.environ["API_PRIVATE_KEY"], algorithm="ES256",
        headers={"kid": os.environ["API_KEY_ID"], "typ": "JWT"},
    )


def get(path: str, params: dict | None = None) -> dict:
    url = path if path.startswith("https://") else f"{API_ROOT}{path}"
    response = requests.get(
        url, params=params,
        headers={"Authorization": f"Bearer {token()}"}, timeout=90,
    )
    if not response.ok:
        raise RuntimeError(f"GET {path} failed ({response.status_code}): {response.text}")
    return response.json()


def get_all(path: str, params: dict | None = None) -> list[dict]:
    items: list[dict] = []
    page = get(path, params)
    while True:
        items.extend(page["data"])
        next_url = page.get("links", {}).get("next")
        if not next_url:
            return items
        page = get(next_url)


def main() -> None:
    library = get(f"/apps/{APP_ID}/assetLibrary")["data"]
    versions = get(
        f"/apps/{APP_ID}/appStoreVersions",
        {"filter[platform]": "IOS", "filter[versionString]": "1.0", "limit": 10},
    )["data"]
    if len(versions) != 1:
        raise RuntimeError(f"Expected one iOS 1.0 version; found {len(versions)}")
    localizations = get_all(
        f"/appStoreVersions/{versions[0]['id']}/appStoreVersionLocalizations",
        {"fields[appStoreVersionLocalizations]": "locale", "limit": 200},
    )
    images = get_all(
        f"/appAssetLibraries/{library['id']}/images",
        {"fields[appAssetLibraryImages]": "referenceName,state,placements", "limit": 200},
    )
    lift_relay_images = [
        item for item in images
        if item.get("attributes", {}).get("referenceName", "").startswith("lift-relay/")
        and item.get("attributes", {}).get("state") != "FAILED"
    ]
    placement_count = sum(
        len(item.get("relationships", {}).get("placements", {}).get("data", []))
        for item in lift_relay_images
    )
    ref_data = get("/appAssetLibraryRefData")["data"]
    relevant = []
    for item in ref_data:
        attributes = item.get("attributes", {})
        duo = [group for group in attributes.get("placementProfileGroups", [])
                if group.get("displayClassId") == "IPHONE_DUO"]
        product_specs = [
            spec for spec in attributes.get("imageSpecs", [])
            if set(spec.get("compatiblePlacementTypes", []))
            & {"APP_SCREENSHOT", "PRODUCT_PAGE_HEADER_ASSET", "APP_STORE_SEARCH_RESULTS_ASSET"}
        ]
        if duo or product_specs:
            relevant.append({
                "id": item["id"],
                "duoPlacementProfileGroups": duo,
                "features": attributes.get("features", []),
                "imageSpecs": product_specs,
                "placementTypes": [
                    entry for entry in attributes.get("placementTypes", [])
                    if entry.get("placementTypeId") in {
                        "APP_SCREENSHOT", "PRODUCT_PAGE_HEADER_ASSET", "APP_STORE_SEARCH_RESULTS_ASSET"
                    }
                ],
            })
    print(json.dumps({
        "assetLibraryId": library["id"],
        "versionLocalizationCount": len(localizations),
        "versionLocales": sorted(item["attributes"]["locale"] for item in localizations),
        "liftRelayReadyImageCount": len(lift_relay_images),
        "liftRelayPlacementCount": placement_count,
        "referenceData": relevant,
    }, indent=2))


if __name__ == "__main__":
    main()
