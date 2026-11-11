#!/usr/bin/env python3
"""Compose the Google Play feature graphic (1024x500).

The listing is the one place the app's own fonts appear outside the app, so this
uses the same two faces the home screen does: Bebas Neue for the wordmark and
Geist for the line under it, on the app's own near-black, with the app icon's
three bars on the right.

Run it whenever the game count or the name changes:

    uv run --with pillow python3 tool/feature_graphic.py

Writes fastlane/metadata/android/en-US/images/featureGraphic.png
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

PROJECT = Path(__file__).resolve().parent.parent
OUT = PROJECT / "fastlane/metadata/android/en-US/images/featureGraphic.png"

BEBAS = PROJECT / "assets/fonts/Bebas_Neue/BebasNeue-Regular.ttf"
GEIST = PROJECT / "assets/fonts/Geist/static/Geist-Regular.ttf"

WIDTH, HEIGHT = 1024, 500
BACKGROUND = (10, 10, 10)
WORDMARK = (255, 255, 255)
SUBTITLE = (148, 163, 184)  # slate-400, the same grey the app uses for notes
BARS = [(49, 46, 129), (67, 56, 202), (217, 119, 6)]  # indigo-900, indigo-700, amber-600

# The three bars are the app icon, redrawn rather than scaled: 190x62 at a 31px
# radius, stepping 30px right and down, ending at the same right edge as before.
BAR_W, BAR_H, BAR_R, BAR_STEP = 190, 62, 31, 30
BAR_X, BAR_Y = 725, 189


def fit(font_path: Path, text: str, target_height: int) -> ImageFont.FreeTypeFont:
    """A font size whose ink is [target_height] tall for [text]."""
    size = target_height
    while size > 8:
        font = ImageFont.truetype(str(font_path), size)
        box = font.getbbox(text)
        height = box[3] - box[1]
        if height <= target_height:
            return font
        size -= 1
    raise SystemExit(f"could not fit {text!r}")


def main() -> None:
    image = Image.new("RGB", (WIDTH, HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(image)

    for index, colour in enumerate(BARS):
        x = BAR_X + index * BAR_STEP
        y = BAR_Y + index * BAR_STEP
        draw.rounded_rectangle(
            (x, y, x + BAR_W, y + BAR_H), radius=BAR_R, fill=colour
        )

    wordmark = "PUZZLESTACK"
    font = fit(BEBAS, wordmark, 92)
    box = font.getbbox(wordmark)
    # Bebas sits on the baseline; place it so the caps start where the bars do.
    draw.text((67, BAR_Y - box[1]), wordmark, font=font, fill=WORDMARK)

    line = "313 minimalist brain puzzles"
    sub = fit(GEIST, line, 31)
    draw.text((67, 296), line, font=sub, fill=SUBTITLE)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT, optimize=True)
    print(f"{OUT.relative_to(PROJECT)}  {image.size[0]}x{image.size[1]}")


if __name__ == "__main__":
    main()
