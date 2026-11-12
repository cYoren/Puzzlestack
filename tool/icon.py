#!/usr/bin/env python3
"""Generate the Puzzlestack app icon.

The app is a deck of puzzle cards, so the icon is the deck mark: three cards
fanned up and to the left, the live one filled. Two colours only — paper and
indigo — because that is the whole palette of the app (see DESIGN.md).

    uv run --with pillow python3 tool/icon.py

Writes assets/icon/puzzlestack_icon.png (1024) and assets/icon/mark_1024.png.
The launcher icons themselves are generated from that file by
`dart run flutter_launcher_icons`.
"""
from pathlib import Path

from PIL import Image, ImageDraw

PROJECT = Path(__file__).resolve().parent.parent
OUT = PROJECT / "assets/icon/puzzlestack_icon.png"
MARK = PROJECT / "assets/icon/mark_1024.png"
FOREGROUND = PROJECT / "assets/icon/foreground_1024.png"

S = 1024
PAPER = (235, 230, 216, 255)   # design_system paper
INK = (20, 19, 14, 255)        # design_system ink
SIGNAL = (67, 56, 202, 255)    # design_system primary
NIGHT = (10, 10, 14, 255)


def rounded(draw, box, radius, fill=None, outline=None, width=0):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline,
                           width=width)


def cards(canvas_size, bg, back, front, stroke_scale=1.0):
    """Three cards, the live one filled, drawn inside a square canvas."""
    img = Image.new("RGBA", (canvas_size, canvas_size), bg)
    d = ImageDraw.Draw(img)
    s = canvas_size / 1024.0

    card_w, card_h = 430 * s, 550 * s
    radius = 44 * s
    stroke = max(1, int(22 * s * stroke_scale))

    # Back cards: outlines only, stepping down and to the right so each one
    # stays visible; the gap is what makes the deck read at 48px.
    for bx, by in ((165, 155), (243, 233)):
        rounded(d, [bx * s, by * s, (bx * s) + card_w, (by * s) + card_h],
                radius, outline=back, width=stroke)

    # The live card, low and right, solid.
    x, y = 321 * s, 311 * s
    rounded(d, [x, y, x + card_w, y + card_h], radius, fill=front)
    return img


def main():
    # Light icon: paper field, ink cards behind, the live card in indigo.
    light = cards(S, PAPER, INK, SIGNAL)
    light.convert("RGB").save(OUT, optimize=True)

    # A transparent mark for docs and the wordmark, no field.
    mark = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    base = cards(S, (0, 0, 0, 0), INK, SIGNAL)
    mark.alpha_composite(base)
    mark.save(MARK)

    # Android adaptive foreground: the same mark, scaled into the 66% safe
    # zone so a circular mask never cuts a card.
    safe = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    scaled = mark.resize((int(S * 0.66), int(S * 0.66)), Image.LANCZOS)
    safe.alpha_composite(scaled, ((S - scaled.width) // 2,
                                  (S - scaled.height) // 2))
    safe.save(FOREGROUND)

    print(f"wrote {OUT.relative_to(PROJECT)}, {MARK.relative_to(PROJECT)} " +
          f"and {FOREGROUND.relative_to(PROJECT)}")


if __name__ == "__main__":
    main()
