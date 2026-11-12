#!/usr/bin/env python3
"""Compose Puzzlestack store screenshots in the portfolio house style.

THIS IS THE ONLY SUPPORTED SCREENSHOT PIPELINE FOR THIS APP:

    raw capture -> resize to the screen rect -> house device frame
    -> dark gradient, indigo glow, wordmark above, frame below

It is self-contained on purpose. An earlier version shelled out to a shared
compose.py that lived in a skills directory outside the repo, and when that
directory went away the pipeline silently could not run. Everything it needs is
here or under tool/assets.

Capture prerequisites (both matter, see SCREENSHOTS.md):
  - Capture on an **iOS simulator**, not an Android emulator. Android's native
    1080x2400 stretches when fitted to the iPhone screen rect.
  - Set the simulator locale to en-US **before** capturing. Device locale drives
    the app's own language; a pt-BR simulator silently produced a mixed set.

Usage:
    python3 tool/compose_house_style.py
    python3 tool/compose_house_style.py --raw-dir screenshots/raw

Needs Pillow: `uv run --with pillow python3 tool/compose_house_style.py`.
"""
import argparse
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

PROJECT = Path(__file__).resolve().parent.parent
# The frame is vendored in-repo so the pipeline is self-contained.
FRAME = PROJECT / "tool/assets/house-device-frame-iphone-6.9.png"
BEBAS = PROJECT / "assets/fonts/Bebas_Neue/BebasNeue-Regular.ttf"
GEIST = PROJECT / "assets/fonts/Geist/static/Geist-Regular.ttf"

# Screen rectangle inside the shared frame (measured, exact).
SCREEN_W, SCREEN_H = 1290, 2796
SCREEN_X, SCREEN_Y = 67, 55

# Puzzlestack brand palette. The bars in the icon are these three.
BG_TOP = (10, 10, 14)
BG_BOTTOM = (18, 16, 34)
GLOW = (67, 56, 202)  # indigo-700, the app's primary
HEADLINE_COLOR = (255, 255, 255)
SUB_COLOR = (148, 163, 184)  # slate-400

# Two canvases, because the stores do not agree. Apple takes 1290x2796 (the 6.9"
# slot). Play refuses anything past a 2:1 aspect, and 1290x2796 is 2.17:1, so the
# Play set is 16:9 at 1080x1920. Shipping one set to both was quietly wrong.
CANVASES = {"ios": (1290, 2796), "play": (1080, 1920)}

# The eight shots that ship, in listing order. Play caps a listing at 8 images;
# Apple allows 10. Ordered so the suite hook lands first.
SHOTS = [
    ("00_deal", "Swipe. Solve. Repeat.",
     "313 puzzles, one card at a time. Swipe up for the next"),
    ("01_stack", "Six Rooms, 313 Puzzles",
     "Logic, math, memory, spatial, attention and word"),
    ("02_sudoku", "Sudoku, Clean and Uncluttered",
     "Every classic you know, stripped back to what actually matters"),
    ("04_nonogram", "Nonograms That Click",
     "Read the numbers, fill the grid, watch the picture appear"),
    ("06_crossword", "Crosswords Without the Clutter",
     "Tap a clue, fill a word, nothing breaking your focus"),
    ("09_water_sort", "Sort, Pour, Solve",
     "Colour-sorting puzzles that are genuinely hard to put down"),
    ("03_game_2048", "2048 and Every Other Classic",
     "Slide, merge, chase a new best, one swipe at a time"),
    ("07_minesweeper", "Minesweeper, Perfected",
     "Careful deduction on a grid that never fights you"),
]


def frame_one(raw_path: Path, framed_path: Path) -> None:
    """Resize a raw capture to the screen rect and composite the house frame over it."""
    frame = Image.open(FRAME).convert("RGBA")
    shot = Image.open(raw_path).convert("RGB").resize((SCREEN_W, SCREEN_H), Image.LANCZOS)
    canvas = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    canvas.paste(shot, (SCREEN_X, SCREEN_Y))
    Image.alpha_composite(canvas, frame).save(framed_path)


def background(size: tuple[int, int]) -> Image.Image:
    """Near-black, with an indigo wash rising from the bottom and a few embers."""
    width, height = size
    image = Image.new("RGB", size)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        t = y / (height - 1)
        draw.line(
            [(0, y), (width, y)],
            fill=tuple(round(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM)),
        )

    # The glow sits behind where the device will be, so the frame reads as lit.
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse(
        [width * 0.08, height * 0.42, width * 0.92, height * 1.05],
        fill=GLOW + (120,),
    )
    image = Image.alpha_composite(
        image.convert("RGBA"), glow.filter(ImageFilter.GaussianBlur(width // 6))
    )

    rng = random.Random(11)  # the same dust every run
    dust = ImageDraw.Draw(image)
    for _ in range(int(width * height / 16000)):
        x = rng.randrange(width)
        y = rng.randrange(int(height * 0.72))
        r = rng.choice((1, 1, 1, 2))
        dust.ellipse([x - r, y - r, x + r, y + r], fill=(226, 224, 255, rng.randrange(70, 170)))
    return image.convert("RGB")


def wrap(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont,
         max_width: float) -> list[str]:
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=font) <= max_width:
            line = trial
        else:
            lines.append(line)
            line = word
    return lines + [line]


def text_block(canvas: Image.Image, headline: str, sub: str) -> int:
    """Draws the wordmark and its line, and returns the y the device starts at."""
    draw = ImageDraw.Draw(canvas)
    width, height = canvas.size
    head_size = int(width * 0.083)
    sub_size = int(width * 0.034)
    y = int(height * 0.055)

    head = ImageFont.truetype(str(BEBAS), head_size)
    for line in wrap(draw, headline, head, width * 0.88):
        draw.text((width / 2, y), line, font=head, fill=HEADLINE_COLOR, anchor="mt")
        y += int(head_size * 0.94)

    y += int(sub_size * 0.55)
    body = ImageFont.truetype(str(GEIST), sub_size)
    for line in wrap(draw, sub, body, width * 0.88):
        draw.text((width / 2, y), line, font=body, fill=SUB_COLOR, anchor="mt")
        y += int(sub_size * 1.32)
    return y


def compose_one(framed_path: Path, out_path: Path, headline: str, sub: str,
                size: tuple[int, int]) -> None:
    width, height = size
    canvas = background(size).convert("RGBA")
    text_bottom = text_block(canvas, headline, sub)

    device = Image.open(framed_path).convert("RGBA")
    room = height - text_bottom - int(height * 0.02)
    scale = min(width * 0.86 / device.width, room / device.height)
    device = device.resize(
        (round(device.width * scale), round(device.height * scale)), Image.LANCZOS
    )
    # Anchored to the bottom, not floating in the middle: the device is the
    # subject of the image and its edge is what the eye reads as the floor.
    x = (width - device.width) // 2
    top = height - device.height
    if top < text_bottom:
        top = text_bottom
    canvas.alpha_composite(device, (x, top))
    canvas.convert("RGB").save(out_path, optimize=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw-dir", default="screenshots/raw")
    ap.add_argument("--out-dir", default="screenshots/aso-refresh")
    args = ap.parse_args()

    raw_dir = (PROJECT / args.raw_dir).resolve()
    out_root = (PROJECT / args.out_dir).resolve()
    framed_dir = out_root / "framed"
    outs = {name: out_root / f"final/{name}" for name in CANVASES}
    for directory in (framed_dir, *outs.values()):
        directory.mkdir(parents=True, exist_ok=True)

    if not FRAME.exists():
        print(f"missing shared frame: {FRAME}", file=sys.stderr)
        return 1

    for font in (BEBAS, GEIST):
        if not font.exists():
            print(f"missing font: {font}", file=sys.stderr)
            return 1

    missing = [stem for stem, _, _ in SHOTS if not (raw_dir / f"{stem}.png").exists()]
    if missing:
        print(f"missing raws in {raw_dir}: {', '.join(missing)}", file=sys.stderr)
        return 1

    for index, (stem, headline, sub) in enumerate(SHOTS, start=1):
        raw = raw_dir / f"{stem}.png"
        framed = framed_dir / f"{stem}_framed.png"
        name = f"{index:02d}_{stem.split('_', 1)[1]}.png"

        frame_one(raw, framed)
        for store, size in CANVASES.items():
            compose_one(framed, outs[store] / name, headline, sub, size)
        print(f"  [{index}/{len(SHOTS)}] {name}")

    for store, directory in outs.items():
        print(f"{store:4}: {directory}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
