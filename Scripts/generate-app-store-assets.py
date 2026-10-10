#!/usr/bin/env python3
"""Render localized iPhone Duo screenshots and product-page artwork."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps, features

try:
    import arabic_reshaper
    from bidi.algorithm import get_display as bidi_display
except ImportError:  # Optional when Pillow was built with libraqm support.
    arabic_reshaper = None
    bidi_display = None


ROOT = Path(__file__).resolve().parents[1]
METADATA = ROOT / "AppStore" / "metadata.json"
SOURCE_DIR = ROOT / "AppStore" / "Screenshots" / "EnglishUK" / "iPhone65"
DEFAULT_OUTPUT = ROOT / "AppStore" / "GeneratedAssets"
LIME = (194, 255, 58)
WHITE = (250, 252, 255)
MUTED = (183, 191, 201)
RTL_PREFIXES = ("ar", "he", "ur")

DEVICE_SIZES = {
    "iPhoneDuoOuter": (1398, 2034),
    "iPhoneDuoInner": (2007, 2853),
}


def font_candidates(locale: str, bold: bool) -> list[Path]:
    windows = Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts"
    language = locale.split("-")[0]
    if language == "ar":
        # Nirmala UI does not contain Arabic glyphs on Windows. It rendered
        # every localized headline as identical .notdef squares, which were
        # then accepted by App Store Connect because the bitmap dimensions
        # were otherwise valid.
        names = ["arialbd.ttf" if bold else "arial.ttf", "segoeuib.ttf" if bold else "segoeui.ttf"]
        noto_names = ["NotoSansArabic-Bold.ttf" if bold else "NotoSansArabic-Regular.ttf"]
    elif language == "he":
        names = ["arialbd.ttf" if bold else "arial.ttf", "segoeuib.ttf" if bold else "segoeui.ttf"]
        noto_names = ["NotoSansHebrew-Bold.ttf" if bold else "NotoSansHebrew-Regular.ttf"]
    elif language == "ur":
        names = ["arialbd.ttf" if bold else "arial.ttf", "Nirmala.ttc"]
        noto_names = ["NotoNastaliqUrdu-Bold.ttf" if bold else "NotoNastaliqUrdu-Regular.ttf",
                      "NotoSansArabic-Bold.ttf" if bold else "NotoSansArabic-Regular.ttf"]
    elif locale.startswith("zh-Hans"):
        names = ["msyhbd.ttc", "msyh.ttc"]
        noto_names = ["NotoSansCJK-Bold.ttc" if bold else "NotoSansCJK-Regular.ttc"]
    elif locale.startswith("zh-Hant"):
        names = ["msjhbd.ttc", "msjh.ttc"]
        noto_names = ["NotoSansCJK-Bold.ttc" if bold else "NotoSansCJK-Regular.ttc"]
    elif locale.startswith("ja"):
        names = ["YuGothB.ttc", "YuGothM.ttc"]
        noto_names = ["NotoSansCJK-Bold.ttc" if bold else "NotoSansCJK-Regular.ttc"]
    elif locale.startswith("ko"):
        names = ["malgunbd.ttf", "malgun.ttf"]
        noto_names = ["NotoSansCJK-Bold.ttc" if bold else "NotoSansCJK-Regular.ttc"]
    elif language in {"bn", "gu", "hi", "kn", "ml", "mr", "or", "pa", "ta", "te"}:
        names = ["Nirmala.ttc"]
        script_names = {
            "bn": "Bengali", "gu": "Gujarati", "hi": "Devanagari", "kn": "Kannada",
            "ml": "Malayalam", "mr": "Devanagari", "or": "Oriya", "pa": "Gurmukhi",
            "ta": "Tamil", "te": "Telugu",
        }
        script = script_names[language]
        noto_names = [f"NotoSans{script}-Bold.ttf" if bold else f"NotoSans{script}-Regular.ttf"]
    elif language == "th":
        names = ["leelawdb.ttf" if bold else "leelawad.ttf", "tahomabd.ttf" if bold else "tahoma.ttf"]
        noto_names = ["NotoSansThai-Bold.ttf" if bold else "NotoSansThai-Regular.ttf"]
    else:
        names = ["arialbd.ttf" if bold else "arial.ttf", "segoeuib.ttf" if bold else "segoeui.ttf"]
        noto_names = ["NotoSans-Bold.ttf" if bold else "NotoSans-Regular.ttf"]
    candidates = [windows / name for name in names]
    # GitHub Actions installs these in the upload workflow.
    linux_roots = [Path("/usr/share/fonts/opentype/noto"), Path("/usr/share/fonts/truetype/noto")]
    for root in linux_roots:
        candidates.extend(root / name for name in noto_names)
    return candidates


def load_font(locale: str, size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    for candidate in font_candidates(locale, bold):
        if candidate.exists() and candidate.suffix.lower() in {".ttf", ".ttc", ".otf"}:
            try:
                return ImageFont.truetype(str(candidate), size=size, index=0)
            except OSError:
                pass
    return ImageFont.truetype("arial.ttf", size=size)


def prepared_text(text: str, locale: str) -> str:
    """Shape and reorder RTL copy when Pillow cannot delegate to libraqm."""
    if not locale.startswith(RTL_PREFIXES) or features.check("raqm"):
        return text
    if arabic_reshaper is None or bidi_display is None:
        raise RuntimeError(
            "RTL rendering requires Pillow with libraqm or the arabic-reshaper and python-bidi packages"
        )
    return bidi_display(arabic_reshaper.reshape(text))


def text_bbox(draw: ImageDraw.ImageDraw, text: str, locale: str,
              font: ImageFont.FreeTypeFont) -> tuple[int, int, int, int]:
    if locale.startswith(RTL_PREFIXES) and features.check("raqm"):
        return draw.textbbox((0, 0), text, font=font, direction="rtl")
    return draw.textbbox((0, 0), prepared_text(text, locale), font=font)


def draw_localized_text(draw: ImageDraw.ImageDraw, position: tuple[int, int], text: str,
                        locale: str, font: ImageFont.FreeTypeFont, fill: tuple,
                        anchor: str) -> None:
    if locale.startswith(RTL_PREFIXES) and features.check("raqm"):
        draw.text(position, text, font=font, fill=fill, anchor=anchor, direction="rtl")
    else:
        draw.text(position, prepared_text(text, locale), font=font, fill=fill, anchor=anchor)


def assert_font_has_localized_glyphs(font: ImageFont.FreeTypeFont, text: str, locale: str) -> None:
    """Reject a font that maps every localized character to one missing-glyph box."""
    characters = sorted({character for character in text if ord(character) > 127 and not character.isspace()})
    if len(characters) < 2:
        return
    fingerprints = set()
    for character in characters:
        mask = font.getmask(character)
        fingerprints.add((mask.size, hashlib.sha256(bytes(mask)).digest()))
    if len(fingerprints) == 1:
        raise RuntimeError(f"Selected font has no usable localized glyphs for {locale}")


def wrap_text(draw: ImageDraw.ImageDraw, text: str, locale: str,
              font: ImageFont.FreeTypeFont, width: int) -> list[str]:
    words = text.replace("\n", " \n ").split()
    lines: list[str] = []
    current = ""
    for word in words:
        if word == "\n":
            if current:
                lines.append(current)
                current = ""
            continue
        trial = word if not current else f"{current} {word}"
        if text_bbox(draw, trial, locale, font)[2] <= width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def rounded_image(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *image.size), radius=radius, fill=255)
    result = image.convert("RGBA")
    result.putalpha(mask)
    return result


def draw_headline(
    canvas: Image.Image,
    locale: str,
    headline: str,
    top: int,
    max_width: int,
    max_height: int,
    base_size: int,
) -> None:
    draw = ImageDraw.Draw(canvas)
    size = base_size
    while size >= max(42, base_size // 2):
        font = load_font(locale, size, bold=True)
        assert_font_has_localized_glyphs(font, headline, locale)
        lines = wrap_text(
            draw, headline.upper() if locale.startswith("en") else headline, locale, font, max_width
        )
        line_height = math.ceil(size * 1.04)
        if len(lines) <= 3 and line_height * len(lines) <= max_height:
            break
        size -= 4
    y = top
    for index, line in enumerate(lines):
        colour = LIME if index == len(lines) - 1 else WHITE
        draw_localized_text(draw, (canvas.width // 2, y), line, locale, font, colour, "ma")
        y += line_height


def screenshot_frame(source: Image.Image, locale: str, headline: str, size: tuple[int, int], index: int) -> Image.Image:
    width, height = size
    background = ImageOps.fit(source, size, method=Image.Resampling.LANCZOS)
    background = background.filter(ImageFilter.GaussianBlur(radius=max(26, width // 42)))
    overlay = Image.new("RGBA", size, (2, 7, 10, 175))
    canvas = Image.alpha_composite(background.convert("RGBA"), overlay)
    draw = ImageDraw.Draw(canvas)
    top_band = int(height * 0.30)
    draw.rectangle((0, 0, width, top_band), fill=(4, 9, 12, 238))
    draw.rectangle((0, top_band - max(8, width // 100), width, top_band), fill=(*LIME, 255))

    label_font = load_font(locale, max(24, width // 44), bold=True)
    draw.text((width // 2, max(36, height // 55)), "LIFT RELAY", font=label_font, fill=MUTED, anchor="ma")
    draw_headline(
        canvas, locale, headline,
        top=max(88, height // 20),
        max_width=int(width * 0.84),
        max_height=int(top_band * 0.68),
        base_size=max(74, width // 10),
    )

    # Remove the old baked-in marketing headline and retain the product/lifestyle proof.
    content = source.crop((0, int(source.height * 0.24), source.width, source.height))
    lower_top = top_band + int(height * 0.035)
    lower_height = height - lower_top - int(height * 0.035)
    panel = ImageOps.fit(content, (int(width * 0.88), lower_height), method=Image.Resampling.LANCZOS)
    panel = rounded_image(panel, radius=max(34, width // 30))
    px = (width - panel.width) // 2
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (px - 14, lower_top + 18, px + panel.width + 14, lower_top + panel.height + 36),
        radius=max(42, width // 28), fill=(0, 0, 0, 150),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(18, width // 55)))
    canvas = Image.alpha_composite(canvas, shadow)
    canvas.alpha_composite(panel, (px, lower_top))

    badge_font = load_font(locale, max(22, width // 55), bold=True)
    badge = f"{index:02d} / 10"
    ImageDraw.Draw(canvas).text((width - int(width * 0.06), height - int(height * 0.02)), badge,
                                font=badge_font, fill=(255, 255, 255, 170), anchor="rs")
    return canvas.convert("RGB")


def product_asset(source: Image.Image, locale: str, headline: str, subtitle: str,
                  size: tuple[int, int], variant: str) -> Image.Image:
    width, height = size
    canvas = ImageOps.fit(source, size, method=Image.Resampling.LANCZOS).convert("RGBA")
    gradient = Image.new("L", (width, 1))
    gradient.putdata([int(235 * (1 - x / max(1, width - 1))) for x in range(width)])
    gradient = gradient.resize((width, height))
    shade = Image.new("RGBA", size, (0, 0, 0, 0))
    shade.putalpha(gradient)
    canvas = Image.alpha_composite(canvas, shade)
    draw = ImageDraw.Draw(canvas)
    label_font = load_font(locale, max(34, height // 22), bold=True)
    draw.text((int(width * .075), int(height * .15)), "LIFT RELAY", font=label_font, fill=LIME, anchor="la")
    draw_headline(canvas, locale, headline, int(height * .24), int(width * .46), int(height * .53), max(72, height // 8))
    if variant == "search":
        small = load_font(locale, max(28, height // 35), bold=False)
        rtl = locale.startswith(RTL_PREFIXES)
        position = (int(width * (.925 if rtl else .075)), int(height * .86))
        draw_localized_text(
            draw, position, subtitle, locale, small, WHITE, "ra" if rtl else "la"
        )
    return canvas.convert("RGB")


def render_locale(locale: str, copy: dict, output_root: Path) -> None:
    sources = [Image.open(path).convert("RGB") for path in sorted(SOURCE_DIR.glob("*.png"))]
    if len(sources) != 10:
        raise RuntimeError(f"Expected ten source screenshots in {SOURCE_DIR}")
    headlines = copy["screenshotHeadlines"]
    if len(headlines) != 10:
        raise RuntimeError(f"Expected ten headlines for {locale}")
    locale_dir = output_root / locale
    selections = {
        "iPhoneDuoOuter": [0, 2, 4, 6, 8],
        "iPhoneDuoInner": [1, 3, 5, 7, 9],
    }
    for device, size in DEVICE_SIZES.items():
        target = locale_dir / device
        target.mkdir(parents=True, exist_ok=True)
        for source_index in selections[device]:
            index = source_index + 1
            image = screenshot_frame(sources[source_index], locale, headlines[source_index], size, index)
            image.save(target / f"{index:02d}.jpg", quality=91, optimize=True, progressive=True)

    product_dir = locale_dir / "ProductPage"
    product_dir.mkdir(parents=True, exist_ok=True)
    header = product_asset(sources[9], locale, headlines[9], copy["subtitle"], (3840, 1646), "header")
    # Use RGB PNG for creative placements. Apple's asset-library processor can
    # reject otherwise valid JPEG encodings for these placements; RGB PNG is a
    # documented format and carries no alpha/transparency channel.
    header.save(product_dir / "header-3840x1646.png", optimize=True, compress_level=7)
    search = product_asset(sources[0], locale, headlines[4], copy["subtitle"], (1920, 1280), "search")
    search.save(product_dir / "search-1920x1280.png", optimize=True, compress_level=7)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--locale", action="append", help="Locale to render; repeat as needed")
    parser.add_argument("--all", action="store_true", help="Render every locale")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    metadata = json.loads(METADATA.read_text(encoding="utf-8"))
    localizations = metadata["localizations"]
    locales = list(localizations) if args.all else (args.locale or ["en-GB"])
    for locale in locales:
        if locale not in localizations:
            raise KeyError(f"Unknown locale: {locale}")
        print(f"Rendering {locale}", flush=True)
        render_locale(locale, localizations[locale], args.output)


if __name__ == "__main__":
    main()
