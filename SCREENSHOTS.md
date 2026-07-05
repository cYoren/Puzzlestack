# Automated store screenshots

PuzzleBox captures store screenshots with a Flutter `integration_test` and
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
- `screenshots/store/play_phone/` — 1080×1920 (Google Play phone)
- `screenshots/store/ios_6_7/` — 1290×2796 (App Store 6.7" iPhone)

Reframe without recapturing (after editing captions):

```bash
python3 tool/frame_screenshots.py
```

## Run it in CI

`.github/workflows/screenshots.yml` boots an Android emulator, captures, frames,
and uploads everything as the `puzzlebox-screenshots` artifact. Trigger it from
the **Actions** tab (Run workflow), or it runs automatically when the screenshot
harness changes on `main`.

## Customizing

- **Which games:** edit `kHeroGameIds` in `integration_test/screenshot_test.dart`.
- **Captions / sizes / colors:** edit `CAPTIONS` and `PRESETS` in
  `tool/frame_screenshots.py`.
- **Real device frames:** the bezel is drawn by PIL so this stays dependency-free
  and license-clean. Swap in official device-frame PNGs in `frame_one()` if you
  want photoreal mockups.
