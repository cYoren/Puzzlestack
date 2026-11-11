# Automated store screenshots

Puzzlestack captures store screenshots with a Flutter `integration_test` and
frames them into store-sized images with a small Python script. Nothing is
hand-cropped.

## What it captures

The discovery home plus a curated **hero set** of games, edited in
`integration_test/screenshot_test.dart` (`kHeroGameIds`). It captures visually
static games on purpose; continuously animated screens never settle and would
stall the run.

## Run it locally

You need a running Android emulator, iOS simulator, or `-d chrome`.

```bash
tool/screenshots.sh                 # first available device
tool/screenshots.sh emulator-5554   # a specific device id
```

Output:

- `screenshots/raw/` — raw device PNGs, named `NN_<gameId>.png`
- `screenshots/aso-refresh/final/ios/` — 1290×2796, ships to the App Store
- `screenshots/aso-refresh/final/play/` — 1080×1920, ships to Google Play

Two canvases, not one: Play refuses an aspect past 2:1 and 1290×2796 is 2.17:1.

See `screenshots/README.md` for which paths are canonical and why.

> ⚠️ **Capture on an iOS simulator set to `en-US`.** Device locale drives the app's own
> language — a `pt-BR` simulator produces a silently *mixed* English/Portuguese set. And
> Android's 1080×2400 stretches ~2.5% when fitted to the iPhone canvas.

Recompose without recapturing (after editing headline copy):

```bash
uv run --with pillow python3 tool/compose_house_style.py
```

The composer lives in `tool/compose_house_style.py` and needs only Pillow. It used to call a
shared `compose.py` from a skills directory outside the repo; that directory is gone, so the
framing and composition are vendored here.

## Run it in CI

`.github/workflows/screenshots.yml` boots an Android emulator, captures and composes,
and uploads everything as the `puzzlestack-screenshots` artifact. Its Android captures are for
review only — **store-quality images must come from an iOS simulator in `en-US`**. It is
manual-only: trigger it from the **Actions** tab (Run workflow).

## Customizing

- **Which games:** edit `kHeroGameIds` in `integration_test/screenshot_test.dart`.
- **Headlines / order / which shots ship:** edit the `SHOTS` list at the top of
  `tool/compose_house_style.py`.
- **Brand colours:** the constants under `SHOTS` in the same file, sampled from
  `assets/icon/puzzlestack_icon.png`.
- **Device frame:** `tool/assets/house-device-frame-iphone-6.9.png`, shared across the
  portfolio (master copy in `Games/shared-assets/`). Screenshot is pasted at offset (67, 55).

> The former `tool/frame_screenshots.py` pipeline, which wrote to `screenshots/store/`, was
> deleted on 2026-08-20 — it rendered a flat background that matched no other app's listing.
