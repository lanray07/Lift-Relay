#!/usr/bin/env python3
"""Normalize browser-translated copy into the App Store metadata manifest."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "AppStore" / "translation-output.json"
TARGET = ROOT / "AppStore" / "metadata.json"
EULA = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"


def remove_transliteration(value: str) -> str:
    value = re.split(r"\n\s*\|\s*\|\s*\|\s*LR\s*\d+", value, maxsplit=1)[0]
    return re.sub(r"\n(?:Show more\n?)?$", "", value.strip()).strip()


def shorten(value: str, limit: int) -> str:
    value = " ".join(value.split())
    if len(value) <= limit:
        return value
    candidate = value[: limit - 1].rstrip()
    if " " in candidate:
        candidate = candidate.rsplit(" ", 1)[0]
    return candidate.rstrip(" ,.;:-") + "…"


def keywords(value: str, byte_limit: int = 100) -> str:
    value = re.sub(r"[،，、;؛]", ",", value)
    terms = [term.strip() for term in value.split(",") if term.strip()]
    packed: list[str] = []
    for term in terms:
        candidate = ",".join([*packed, term])
        if len(candidate.encode("utf-8")) <= byte_limit:
            packed.append(term)
    return ",".join(packed)


def main() -> None:
    translated = json.loads(SOURCE.read_text(encoding="utf-8"))
    current = json.loads(TARGET.read_text(encoding="utf-8"))
    existing = current.get("localizations", {})
    aliases = {"ar-SA": "ar", "it": "it-IT"}
    result: dict[str, dict] = {}
    for locale, values in translated.items():
        if len(values) != 14:
            raise RuntimeError(f"{locale}: expected 14 translated values, found {len(values)}")
        values = [remove_transliteration(value) for value in values]
        prior = existing.get(locale) or existing.get(aliases.get(locale, "")) or {}
        description = prior.get("description") or values[2]
        if EULA not in description:
            description = f"{description}\n\nTerms of Use: {EULA}"
        result[locale] = {
            "name": prior.get("name", "Lift Relay: Gym Workout"),
            "subtitle": shorten(prior.get("subtitle") or values[0].splitlines()[0], 30),
            "promotionalText": shorten(prior.get("promotionalText") or values[1].splitlines()[0], 170),
            "description": description,
            "keywords": keywords(prior.get("keywords") or values[3].splitlines()[0]),
            "screenshotHeadlines": [shorten(value.splitlines()[0], 58) for value in values[4:]],
        }
    current["localizations"] = result
    TARGET.write_text(json.dumps(current, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Imported {len(result)} complete localizations into {TARGET}")


if __name__ == "__main__":
    main()
