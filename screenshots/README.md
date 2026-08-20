# Mindstack store screenshots

> **This app ships as “Mindstack”.** The directory is named `Puzzlebox` for historical reasons
> only — the GitHub repo, the `android:label`, the iOS `CFBundleDisplayName` and the store
> listings all say Mindstack. Never use “Puzzlebox” in a store context.

## What is canonical

| Path | What it is |
|------|-----------|
| `aso-refresh/final/ios/iphone/` | **Ships to the App Store.** 8 images, 1290×2796, no alpha. |
| `aso-refresh/final/android/phone/` | **Ships to Google Play.** Same 8 images (Play accepts the iPhone set). |
| `aso-refresh/framed/` | Intermediate — raw pasted into the device frame. Safe to delete. |
| `raw/` | Raw device captures, 1320×2868. Regenerated on every capture run. |

Anything else under `screenshots/` is not canonical.

## History — read before "fixing" anything

Until 2026-08-20 this app had a second, competing pipeline: `tool/frame_screenshots.py`
writing to `screenshots/store/{play_phone,ios_6_7}/`. It produced a flat black background with
a thin drawn outline, which matched no other app in the portfolio. **That script and its output
tree were deleted**, and `tool/screenshots.sh` now calls `tool/compose_house_style.py` instead.

If you find references to `screenshots/store/`, `play_phone`, `ios_6_7` or `frame_screenshots.py`
anywhere, they are stale — update them to point here rather than recreating the old pipeline.

## Regenerating

```bash
tool/screenshots.sh <simulator-UDID>
```

Two prerequisites, each of which has already cost a full capture run:

1. **Use an iOS simulator, not an Android emulator.** Android's 1080×2400 stretches ~2.5% when
   fitted to the 1290×2796 iPhone canvas.
2. **Set the simulator locale to `en-US` first.** Device locale drives the app's own language.
   A `pt-BR` simulator produced a *mixed* English/Portuguese set — a localized Flutter app falls
   back to the template locale only for keys its active locale is missing, so the home screen
   looked correct while Water Sort read “Ordene as cores…”. Verify a text-heavy screen after
   capturing; spot-checking one image will not catch this.

Headline copy lives in the `SHOTS` list at the top of `tool/compose_house_style.py`. To recompose
after editing copy, without recapturing:

```bash
python3 tool/compose_house_style.py
```

## Known weakness

Four of the eight shots (`03_nonogram`, `04_crossword`, `06_game_2048`, `07_minesweeper`) capture
each game at its **start state**, so the grids are largely empty. Beside the Cirdoku set, which
shows a populated board mid-solve, these read as unfinished — and Apple has rejected sibling apps
in this portfolio under guideline 2.3.3 for screenshots that don't show the app meaningfully in
use. Driving a few moves in `integration_test/screenshot_test.dart` before capturing would fix it.

Eleven screens are captured; eight ship, because Google Play caps a listing at 8 images.
`04_word_search`, `07_kenken` and `09_lights_out` are captured but held back.
