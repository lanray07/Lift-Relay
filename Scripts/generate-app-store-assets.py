#!/usr/bin/env python3
"""Render localized iPhone Duo screenshots and product-page artwork."""

from __future__ import annotations

import argparse
import json
import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps


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
    if locale.startswith(RTL_PREFIXES):
        names = ["Nirmala.ttc", "arialbd.ttf" if bold else "arial.ttf"]
    elif locale.startswith("zh-Hans"):
        names = ["msyhbd.ttc", "msyh.ttc"]
    elif locale.startswith("zh-Hant"):
        names = ["msjhbd.ttc", "msjh.ttc"]
    elif locale.startswith("ja"):
        names = ["YuGothB.ttc", "YuGothM.ttc"]
    elif locale.startswith("ko"):
        names = ["malgunbd.ttf", "malgun.ttf"]
    elif locale.split("-")[0] in {"bn", "gu", "hi", "kn", "ml", "mr", "or", "pa", "ta", "te"}:
        names = ["Nirmala.ttc"]
    else:
        names = ["arialbd.ttf" if bold else "arial.ttf", "segoeuib.ttf" if bold else "segoeui.ttf"]
    candidates = [windows / name for name in names]
    # GitHub Actions installs these in the upload workflow.
    linux_roots = [Path("/usr/share/fonts/opentype/noto"), Path("/usr/share/fonts/truetype/noto")]
    patterns = ["*Sans*Bold*", "*Sans*Regular*"] if bold else ["*Sans*Regular*", "*Sans*"]
    for root in linux_roots:
        for pattern in patterns:
            candidates.extend(sorted(root.glob(pattern)))
    return candidates


def load_font(locale: str, size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    for candidate in font_candidates(locale, bold):
        if candidate.exists() and candidate.suffix.lower() in {".ttf", ".ttc", ".otf"}:
            try:
                return ImageFont.truetype(str(candidate), size=size, index=0)
            except OSError:
                pass
    return ImageFont.truetype("arial.ttf", size=size)


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, width: int) -> list[str]:
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
        if draw.textbbox((0, 0), trial, font=font)[2] <= width:
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
        lines = wrap_text(draw, headline.upper() if locale.startswith("en") else headline, font, max_width)
        line_height = math.ceil(size * 1.04)
        if len(lines) <= 3 and line_height * len(lines) <= max_height:
            break
        size -= 4
    direction = "rtl" if locale.startswith(RTL_PREFIXES) else "ltr"
    y = top
    for index, line in enumerate(lines):
        colour = LIME if index == len(lines) - 1 else WHITE
        try:
            draw.text((canvas.width // 2, y), line, font=font, fill=colour, anchor="ma", direction=direction)
        except (KeyError, ValueError):
            draw.text((canvas.width // 2, y), line, font=font, fill=colour, anchor="ma")
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
        try:
            draw.text(position, subtitle, font=small, fill=WHITE,
                      anchor="ra" if rtl else "la", direction="rtl" if rtl else "ltr")
        except (KeyError, ValueError):
            draw.text(position, subtitle, font=small, fill=WHITE,
                      anchor="ra" if rtl else "la")
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
