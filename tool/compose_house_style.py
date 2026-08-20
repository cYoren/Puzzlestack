#!/usr/bin/env python3
"""
Compose Mindstack store screenshots in the shared portfolio house style.

THIS IS THE ONLY SUPPORTED SCREENSHOT PIPELINE FOR THIS APP. It produces the same look as
the Cirdoku and medhub listings, so Mindstack stays visually consistent with the portfolio:

    raw capture -> resize to 1290x2796 -> paste into the house device frame
    -> compose.py (gradient background, starfield, device glow, headline + subheadline)

It replaced tool/frame_screenshots.py, which rendered a flat background and a thin drawn
outline that did not match any other app's listing. That script and its screenshots/store/
output tree were deleted on 2026-08-20 so no future run can resurrect the off-brand set.

Capture prerequisites (both matter, see SCREENSHOTS.md):
  - Capture on an **iOS simulator**, not an Android emulator. Android's 1080x2400 stretches
    ~2.5% when fitted to the 1290x2796 iPhone canvas.
  - Set the simulator locale to en-US **before** capturing. Device locale drives the app's
    own language; a pt-BR simulator silently produced a mixed English/Portuguese set.

Usage:
    python3 tool/compose_house_style.py
    python3 tool/compose_house_style.py --raw-dir screenshots/raw
"""
import argparse
import subprocess
import sys
from pathlib import Path

from PIL import Image

PROJECT = Path(__file__).resolve().parent.parent
# The frame is vendored in-repo so the pipeline is self-contained (CI has no access to the
# portfolio-wide shared-assets directory). Games/shared-assets/ holds the master copy.
FRAME = PROJECT / "tool/assets/house-device-frame-iphone-6.9.png"
COMPOSE = Path.home() / ".claude/skills/appstore-screenshots/scripts/compose.py"

# Screen rectangle inside the shared frame (measured, exact).
SCREEN_W, SCREEN_H = 1290, 2796
SCREEN_X, SCREEN_Y = 67, 55

# Mindstack brand palette, sampled from assets/icon/mindstack_icon.png.
BG_COLOR = "#0A0A0A"
BG_GRADIENT = "#312E81"
DEVICE_GLOW = "#D97706"
HEADLINE_COLOR = "#FFFFFF"
SUB_COLOR = "#C7C5F0"

# The eight shots that ship, in listing order. Play caps a listing at 8 images;
# Apple allows 10. Ordered so the suite hook lands first.
SHOTS = [
    ("00_home", "161 Puzzles, One Calm Home",
     "Logic, math, memory and reflex — all in a single quiet app"),
    ("01_sudoku", "Sudoku, Clean and Uncluttered",
     "Every classic you know, stripped back to what actually matters"),
    ("03_nonogram", "Nonograms That Click",
     "Read the numbers, fill the grid, watch the picture appear"),
    ("05_crossword", "Crosswords Without the Clutter",
     "Tap a clue, fill a word — nothing breaking your focus"),
    ("08_water_sort", "Sort, Pour, Solve",
     "Colour-sorting puzzles that are genuinely hard to put down"),
    ("02_game_2048", "2048 and Every Other Classic",
     "Slide, merge, chase a new best — one swipe at a time"),
    ("06_minesweeper", "Minesweeper, Perfected",
     "Careful deduction on a grid that never fights you"),
    ("10_schulte_table", "Train Focus in Under Two Minutes",
     "Schulte tables and reflex drills for a quick mental reset"),
]


def frame_one(raw_path: Path, framed_path: Path) -> None:
    """Resize a raw capture to the screen rect and composite the house frame over it."""
    frame = Image.open(FRAME).convert("RGBA")
    shot = Image.open(raw_path).convert("RGB").resize((SCREEN_W, SCREEN_H), Image.LANCZOS)
    canvas = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    canvas.paste(shot, (SCREEN_X, SCREEN_Y))
    Image.alpha_composite(canvas, frame).save(framed_path)


def compose_one(framed_path: Path, out_path: Path, headline: str, sub: str) -> None:
    subprocess.run([
        sys.executable, str(COMPOSE),
        "--screenshot", str(framed_path),
        "--output", str(out_path),
        "--size", f"{SCREEN_W}x{SCREEN_H}",
        "--bg-color", BG_COLOR,
        "--bg-gradient", BG_GRADIENT,
        "--headline", headline,
        "--subheadline", sub,
        "--headline-color", HEADLINE_COLOR,
        "--subheadline-color", SUB_COLOR,
        "--device-glow", DEVICE_GLOW,
        "--particles", "60",
        "--device-scale", "0.78",
    ], check=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw-dir", default="screenshots/raw")
    ap.add_argument("--out-dir", default="screenshots/aso-refresh")
    args = ap.parse_args()

    raw_dir = (PROJECT / args.raw_dir).resolve()
    out_root = (PROJECT / args.out_dir).resolve()
    framed_dir = out_root / "framed"
    ios_dir = out_root / "final/ios/iphone"
    play_dir = out_root / "final/android/phone"
    for d in (framed_dir, ios_dir, play_dir):
        d.mkdir(parents=True, exist_ok=True)

    if not FRAME.exists():
        print(f"missing shared frame: {FRAME}", file=sys.stderr)
        return 1

    missing = [s for s, _, _ in SHOTS if not (raw_dir / f"{s}.png").exists()]
    if missing:
        print(f"missing raws in {raw_dir}: {', '.join(missing)}", file=sys.stderr)
        return 1

    for idx, (stem, headline, sub) in enumerate(SHOTS, start=1):
        raw = raw_dir / f"{stem}.png"
        framed = framed_dir / f"{stem}_framed.png"
        name = f"{idx:02d}_{stem.split('_', 1)[1]}.png"

        frame_one(raw, framed)
        compose_one(framed, ios_dir / name, headline, sub)
        # Play accepts the 1290x2796 iPhone set, so the same render serves both stores.
        Image.open(ios_dir / name).save(play_dir / name)
        print(f"  [{idx}/{len(SHOTS)}] {name}")

    print(f"\niOS  : {ios_dir}")
    print(f"Play : {play_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
