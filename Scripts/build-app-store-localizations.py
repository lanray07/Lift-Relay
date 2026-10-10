#!/usr/bin/env python3
"""Build the complete App Store localization manifest for Lift Relay.

The script preserves hand-curated copy already present in metadata.json and
fills every other App Store Connect locale from the English source copy.  It
also adds a ten-frame, keyword-led screenshot story for every locale.
"""

from __future__ import annotations

import json
import os
import time
from pathlib import Path

import requests


METADATA_PATH = Path("AppStore/metadata.json")
TRANSLATE_URL = "https://translate.googleapis.com/translate_a/single"
GITHUB_MODELS_URL = "https://models.github.ai/inference/chat/completions"

# App Store Connect locale -> translation service language.
LOCALES = {
    "ar-SA": "ar", "bn": "bn", "ca": "ca", "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW", "hr": "hr", "cs": "cs", "da": "da",
    "nl-NL": "nl", "en-AU": "en", "en-CA": "en", "en-GB": "en",
    "en-US": "en", "fi": "fi", "fr-FR": "fr", "fr-CA": "fr",
    "de-DE": "de", "el": "el", "gu": "gu", "he": "he", "hi": "hi",
    "hu": "hu", "id": "id", "it": "it", "ja": "ja", "kn": "kn",
    "ko": "ko", "ms": "ms", "ml": "ml", "mr": "mr", "no": "no",
    "or": "or", "pl": "pl", "pt-BR": "pt", "pt-PT": "pt", "pa": "pa",
    "ro": "ro", "ru": "ru", "sk": "sk", "sl": "sl", "es-MX": "es",
    "es-ES": "es", "sv": "sv", "ta": "ta", "te": "te", "th": "th",
    "tr": "tr", "uk": "uk", "ur": "ur", "vi": "vi",
}

SOURCE = {
    "name": "Lift Relay: Gym Workout",
    "subtitle": "Workout Planner & Gym Tracker",
    "promotionalText": (
        "Adapt every gym session to the equipment available now. Plan workouts, "
        "swap exercises, log strength training and keep momentum."
    ),
    "description": (
        "THE GYM IS BUSY. YOUR WORKOUT DOESN'T HAVE TO STOP.\n\n"
        "Lift Relay adapts structured workouts when equipment isn't available. "
        "Choose what you planned and what is free to get clear exercise swaps "
        "that preserve your training goal and movement pattern. Log sets, reps "
        "and weight, rebuild a disrupted session with Relay Mode, shorten it with "
        "Time Rescue, use voice logging, review strength progress and save each "
        "gym's equipment. Core workout logging and local substitutions work offline.\n\n"
        "Lift Relay is a fitness tool, not medical advice. Some advanced features "
        "require Lift Relay Pro."
    ),
    "keywords": (
        "workout planner,gym tracker,strength log,exercise swaps,weight training,fitness coach"
    ),
    "screenshotHeadlines": [
        "Workout planner for busy gyms",
        "Smart exercise swaps",
        "Rescue every workout",
        "Adapt to available equipment",
        "Log lifting sets by voice",
        "Train when time is tight",
        "Track strength progress",
        "Save every gym profile",
        "Plan. Swap. Keep moving.",
        "Build muscle. Keep momentum.",
    ],
}


def translate(text: str, language: str) -> str:
    if language == "en":
        return text
    last_error: Exception | None = None
    for attempt in range(5):
        try:
            response = requests.post(
                TRANSLATE_URL,
                params={"client": "gtx", "sl": "en", "tl": language, "dt": "t"},
                data={"q": text},
                timeout=60,
            )
            response.raise_for_status()
            translated = "".join(part[0] for part in response.json()[0] if part[0])
            time.sleep(0.12)
            return translated.strip()
        except (requests.RequestException, ValueError, TypeError) as error:
            last_error = error
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"Translation failed for {language}") from last_error


def fit_keywords(text: str, byte_limit: int = 100) -> str:
    terms = [term.strip() for term in text.replace("，", ",").split(",") if term.strip()]
    selected: list[str] = []
    for term in terms:
        candidate = ",".join([*selected, term])
        if len(candidate.encode("utf-8")) <= byte_limit:
            selected.append(term)
    return ",".join(selected)


def translate_bundle(language: str) -> dict[str, object]:
    keys = ["subtitle", "promotionalText", "description", "keywords"]
    values = [SOURCE[key] for key in keys] + SOURCE["screenshotHeadlines"]
    if language == "en":
        translated = values
    else:
        markers = [f"|||LR{index:02d}|||" for index in range(len(values))]
        payload = "\n".join(
            part for pair in zip(markers, values) for part in pair
        )
        result = translate(payload, language)
        translated = []
        for index, marker in enumerate(markers):
            start = result.find(marker)
            if start < 0:
                raise RuntimeError(f"Translation marker {marker} was not preserved for {language}")
            start += len(marker)
            end = result.find(markers[index + 1], start) if index + 1 < len(markers) else len(result)
            translated.append(result[start:end].strip())
    return {
        **dict(zip(keys, translated[:4])),
        "screenshotHeadlines": translated[4:],
    }


def translate_bundle_github(locale: str, language: str) -> dict[str, object]:
    if language == "en":
        return {key: SOURCE[key] for key in ("subtitle", "promotionalText", "description", "keywords", "screenshotHeadlines")}
    prompt = f"""Translate this App Store product-page copy into locale {locale}.
Return JSON only with exactly these keys: subtitle, promotionalText, description, keywords, screenshotHeadlines.
Keep Lift Relay, Lift Relay Pro, Relay Mode, Time Rescue, and URLs unchanged.
Use natural App Store language, not literal word-for-word translation.
Keep subtitle at most 30 characters, promotionalText at most 170 characters, and each screenshot headline concise enough for three display lines.
keywords must contain six locally searched fitness terms separated only by ASCII commas.
screenshotHeadlines must contain exactly ten strings in the same order.

Source JSON:
{json.dumps({key: SOURCE[key] for key in ('subtitle', 'promotionalText', 'description', 'keywords', 'screenshotHeadlines')}, ensure_ascii=False)}"""
    response = requests.post(
        GITHUB_MODELS_URL,
        headers={
            "Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}",
            "Accept": "application/vnd.github+json",
            "Content-Type": "application/json",
            "X-GitHub-Api-Version": "2026-03-10",
            "User-Agent": "Lift-Relay-App-Store-Localization",
        },
        json={
            "model": os.environ.get("GITHUB_MODELS_MODEL", "openai/gpt-4o-mini"),
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.15,
            "response_format": {"type": "json_object"},
        },
        timeout=120,
    )
    response.raise_for_status()
    if "json" not in response.headers.get("content-type", "").lower():
        raise RuntimeError(
            f"GitHub Models returned {response.headers.get('content-type')}: {response.text[:200]}"
        )
    content = response.json()["choices"][0]["message"]["content"]
    result = json.loads(content)
    if len(result.get("screenshotHeadlines", [])) != 10:
        raise RuntimeError(f"Model returned an invalid screenshot story for {locale}")
    return result


def normalized_existing(metadata: dict, locale: str) -> dict:
    aliases = {
        "ar-SA": "ar", "it": "it-IT",
    }
    return dict(metadata.get("localizations", {}).get(locale)
                or metadata.get("localizations", {}).get(aliases.get(locale, ""))
                or {})


def main() -> None:
    metadata = json.loads(METADATA_PATH.read_text(encoding="utf-8"))
    completed: dict[str, dict] = {}
    for locale, language in LOCALES.items():
        current = normalized_existing(metadata, locale)
        print(f"Localizing {locale}", flush=True)
        translated = (
            translate_bundle_github(locale, language)
            if os.environ.get("GITHUB_TOKEN")
            else translate_bundle(language)
        )
        result = {
            "name": current.get("name", SOURCE["name"]),
            "subtitle": current.get("subtitle") or translated["subtitle"],
            "promotionalText": current.get("promotionalText") or translated["promotionalText"],
            "description": current.get("description") or (
                translated["description"]
                + "\n\n"
                + "Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
            ),
            "keywords": fit_keywords(
                current.get("keywords") or translated["keywords"]
            ),
            "screenshotHeadlines": translated["screenshotHeadlines"],
        }
        completed[locale] = result

    metadata["localizations"] = completed
    METADATA_PATH.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Wrote {len(completed)} localizations to {METADATA_PATH}")


if __name__ == "__main__":
    main()
