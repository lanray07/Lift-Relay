#!/usr/bin/env python3
"""Validate localized App Store metadata and generated image deliverables."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
METADATA = ROOT / "AppStore" / "metadata.json"
ASSETS = ROOT / "AppStore" / "GeneratedAssets"
EXPECTED_SIZES = {
    "iPhoneDuoOuter": (1398, 2034),
    "iPhoneDuoInner": (2007, 2853),
    "header-3840x1646.jpg": (3840, 1646),
    "search-1920x1280.jpg": (1920, 1280),
}


def check_metadata() -> list[str]:
    data = json.loads(METADATA.read_text(encoding="utf-8"))
    errors: list[str] = []
    localizations = data.get("localizations", {})
    if len(localizations) != 50:
        errors.append(f"Expected 50 localizations; found {len(localizations)}")
    for locale, item in localizations.items():
        for key, limit in (("name", 30), ("subtitle", 30), ("promotionalText", 170), ("description", 4000)):
            value = item.get(key, "")
            if not value:
                errors.append(f"{locale}: missing {key}")
            elif len(value) > limit:
                errors.append(f"{locale}: {key} has {len(value)} characters (limit {limit})")
        keywords = item.get("keywords", "")
        if not keywords:
            errors.append(f"{locale}: missing keywords")
        elif len(keywords.encode("utf-8")) > 100:
            errors.append(f"{locale}: keywords use {len(keywords.encode('utf-8'))} bytes (limit 100)")
        headlines = item.get("screenshotHeadlines", [])
        if len(headlines) != 10 or any(not headline.strip() for headline in headlines):
            errors.append(f"{locale}: expected ten non-empty screenshot headlines")
    return errors


def check_assets() -> list[str]:
    errors: list[str] = []
    data = json.loads(METADATA.read_text(encoding="utf-8"))
    for locale in data["localizations"]:
        locale_dir = ASSETS / locale
        for device, size in list(EXPECTED_SIZES.items())[:2]:
            paths = sorted((locale_dir / device).glob("*.jpg"))
            if len(paths) != 5:
                errors.append(f"{locale}/{device}: expected five JPEGs; found {len(paths)}")
            for path in paths:
                with Image.open(path) as image:
                    if image.size != size:
                        errors.append(f"{path}: {image.size} != {size}")
                    if image.mode != "RGB":
                        errors.append(f"{path}: expected RGB without alpha, found {image.mode}")
        for file_name, size in list(EXPECTED_SIZES.items())[2:]:
            path = locale_dir / "ProductPage" / file_name
            if not path.exists():
                errors.append(f"Missing {path}")
                continue
            with Image.open(path) as image:
                if image.size != size or image.mode != "RGB":
                    errors.append(f"{path}: expected {size} RGB, found {image.size} {image.mode}")
    return errors


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata-only", action="store_true")
    args = parser.parse_args()
    errors = check_metadata()
    if not args.metadata_only:
        errors.extend(check_assets())
    if errors:
        raise SystemExit("\n".join(f"ERROR: {error}" for error in errors))
    print("App Store metadata and assets are valid.")


if __name__ == "__main__":
    main()
