#!/usr/bin/env python3
"""Frame raw app screenshots into store-ready images.

Reads PNGs from screenshots/raw/ and, for each store preset, composites every
screenshot onto a colored background inside a rounded "device" bezel with a
caption above it. Outputs to screenshots/store/<preset>/.

No external device-frame art is used (those are copyrighted); the bezel is
drawn with PIL so this runs anywhere with Pillow installed.

Usage:
    python3 tool/frame_screenshots.py
    python3 tool/frame_screenshots.py --raw screenshots/raw --out screenshots/store
"""
from __future__ import annotations

import argparse
import os
import re
from PIL import Image, ImageDraw, ImageFont

# Store presets: name -> (canvas_w, canvas_h)
PRESETS = {
    # Google Play phone (16:9-ish portrait)
    "play_phone": (1080, 1920),
    # App Store 6.7" iPhone portrait
    "ios_6_7": (1290, 2796),
}

# Brand
BG_TOP = (18, 19, 22)
BG_BOTTOM = (10, 10, 12)
ACCENT = (99, 102, 241)  # indigo, matches DesignSystem.primary
CAPTION_COLOR = (245, 247, 250)

# Per-screenshot captions (by raw filename stem, ignoring the NN_ prefix).
CAPTIONS = {
    "home": "161 puzzles, one calm home",
    "sudoku": "Classic Sudoku, three difficulties",
    "game_2048": "2048: merge your way up",
    "nonogram": "Reveal the hidden picture",
    "word_search": "Hunt every hidden word",
    "crossword": "A fresh mini crossword daily",
    "minesweeper": "Flag the mines, clear the field",
    "kenken": "KenKen: logic meets arithmetic",
    "water_sort": "Sort the colors, one pour at a time",
    "lights_out": "Switch every light off",
    "schulte_table": "Schulte Table: train your focus",
}

STEM_RE = re.compile(r"^\d+_(.+)$")


def _stem(filename: str) -> str:
    name = os.path.splitext(filename)[0]
    m = STEM_RE.match(name)
    return m.group(1) if m else name


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/Library/Fonts/Arial Bold.ttf",
    ):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def _vertical_gradient(w: int, h: int, top, bottom) -> Image.Image:
    base = Image.new("RGB", (w, h), top)
    draw = ImageDraw.Draw(base)
    for y in range(h):
        t = y / max(1, h - 1)
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))
    return base


def _rounded(im: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, im.size[0], im.size[1]], radius=radius, fill=255)
    out = im.convert("RGBA")
    out.putalpha(mask)
    return out


def _wrap(draw, text, font, max_w):
    words, lines, cur = text.split(), [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if draw.textlength(trial, font=font) <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def frame_one(shot: Image.Image, caption: str, canvas_w: int, canvas_h: int) -> Image.Image:
    canvas = _vertical_gradient(canvas_w, canvas_h, BG_TOP, BG_BOTTOM)
    draw = ImageDraw.Draw(canvas)

    # Caption band (top ~16%).
    cap_font = _font(int(canvas_w * 0.058))
    margin = int(canvas_w * 0.08)
    lines = _wrap(draw, caption, cap_font, canvas_w - 2 * margin)
    line_h = int(cap_font.size * 1.25)
    y = int(canvas_h * 0.06)
    for line in lines:
        tw = draw.textlength(line, font=cap_font)
        draw.text(((canvas_w - tw) / 2, y), line, font=cap_font, fill=CAPTION_COLOR)
        y += line_h

    # Device area below the caption.
    top = int(canvas_h * 0.20)
    bottom = int(canvas_h * 0.94)
    avail_h = bottom - top
    avail_w = int(canvas_w * 0.82)

    # Fit the shot to the device area, preserving aspect ratio.
    sw, sh = shot.size
    scale = min(avail_w / sw, avail_h / sh)
    dw, dh = int(sw * scale), int(sh * scale)
    shot_r = shot.convert("RGBA").resize((dw, dh), Image.LANCZOS)

    bezel = int(canvas_w * 0.018)
    radius = int(canvas_w * 0.06)
    device_w, device_h = dw + 2 * bezel, dh + 2 * bezel
    dx = (canvas_w - device_w) // 2
    dy = top + (avail_h - device_h) // 2

    # Drop shadow.
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [dx, dy + int(bezel * 1.5), dx + device_w, dy + device_h + int(bezel * 1.5)],
        radius=radius, fill=(0, 0, 0, 150),
    )
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)

    # Bezel.
    bez = Image.new("RGBA", (device_w, device_h), (0, 0, 0, 0))
    ImageDraw.Draw(bez).rounded_rectangle(
        [0, 0, device_w, device_h], radius=radius, fill=(28, 29, 33, 255),
        outline=ACCENT + (255,), width=max(2, bezel // 6),
    )
    canvas.paste(bez, (dx, dy), bez)

    # Screen.
    screen = _rounded(shot_r, max(8, radius - bezel))
    canvas.paste(screen, (dx + bezel, dy + bezel), screen)

    return canvas.convert("RGB")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default="screenshots/raw")
    ap.add_argument("--out", default="screenshots/store")
    args = ap.parse_args()

    if not os.path.isdir(args.raw):
        raise SystemExit(f"No raw screenshots found in {args.raw}. Run the capture step first.")

    files = sorted(f for f in os.listdir(args.raw) if f.lower().endswith(".png"))
    if not files:
        raise SystemExit(f"{args.raw} is empty. Run tool/screenshots.sh first.")

    for preset, (cw, ch) in PRESETS.items():
        out_dir = os.path.join(args.out, preset)
        os.makedirs(out_dir, exist_ok=True)
        for f in files:
            shot = Image.open(os.path.join(args.raw, f))
            caption = CAPTIONS.get(_stem(f), _stem(f).replace("_", " ").title())
            framed = frame_one(shot, caption, cw, ch)
            framed.save(os.path.join(out_dir, f))
        print(f"{preset}: wrote {len(files)} images to {out_dir}")


if __name__ == "__main__":
    main()
