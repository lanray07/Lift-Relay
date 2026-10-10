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
    response = requests.get(
        f"{API_ROOT}{path}", params=params,
        headers={"Authorization": f"Bearer {token()}"}, timeout=90,
    )
    if not response.ok:
        raise RuntimeError(f"GET {path} failed ({response.status_code}): {response.text}")
    return response.json()


def main() -> None:
    library = get(f"/apps/{APP_ID}/assetLibrary")["data"]
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
    print(json.dumps({"assetLibraryId": library["id"], "referenceData": relevant}, indent=2))


if __name__ == "__main__":
    main()
