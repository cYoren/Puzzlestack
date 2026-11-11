# Puzzlestack store screenshots

## What is canonical

| Path | What it is |
|------|-----------|
| `aso-refresh/final/ios/` | **Ships to the App Store.** 8 images, 1290×2796, no alpha. |
| `aso-refresh/final/play/` | **Ships to Google Play.** The same 8 shots at 1080×1920. |
| `aso-refresh/framed/` | Intermediate: the raw capture pasted into the device frame. Safe to delete. |
| `raw/` | Raw device captures. Regenerated on every capture run. |

Anything else under `screenshots/` is not canonical.

## Two canvases, because the stores disagree

The App Store takes 1290×2796 (the 6.9" slot). Play refuses anything past a 2:1 aspect, and
1290×2796 is 2.17:1, so shipping one set to both was wrong: the Play set is 16:9. Both are
produced in the same run by `tool/compose_house_style.py`.

## Regenerating

```bash
tool/screenshots.sh <device_id>
```

Two prerequisites, each of which has already cost a full capture run:

1. **Use an iOS simulator, not an Android emulator.** Android's native 1080×2400 stretches when
   fitted to the 1290×2796 screen rect inside the frame. The Play canvas is derived from the same
   capture, so the stretch does not go away on the Play set.
2. **Set the simulator locale to `en-US` first.** Device locale drives the app's own language.
   A `pt-BR` simulator produced a *mixed* English/Portuguese set: a localized Flutter app falls
   back to the template locale only for keys its active locale is missing, so the home screen
   looked correct while Water Sort read "Ordene as cores…". Verify a text-heavy screen after
   capturing; spot-checking one image will not catch it.

Headline copy lives in the `SHOTS` list at the top of `tool/compose_house_style.py`. To recompose
after editing copy, without recapturing:

```bash
uv run --with pillow python3 tool/compose_house_style.py
```

The composer is **self-contained in this repo** and needs only Pillow. It used to shell out to a
shared `compose.py` living in a skills directory outside the repo; when that directory went away
the pipeline stopped working, which is why the framing, glow, wordmark and canvas sizes are all
here now.

## Known weakness

Four of the eight shots (`03_nonogram`, `04_crossword`, `06_game_2048`, `07_minesweeper`) capture
each game at its **start state**, so the grids are largely empty. Beside the Cirdoku set, which
shows a populated board mid-solve, these read as unfinished, and Apple has rejected sibling apps
in this portfolio under guideline 2.3.3 for screenshots that don't show the app meaningfully in
use. Driving a few moves in `integration_test/screenshot_test.dart` before capturing would fix it.

Eleven screens are captured; eight ship, because Google Play caps a listing at 8 images.
`04_word_search`, `07_kenken` and `09_lights_out` are captured but held back.
