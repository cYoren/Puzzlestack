#!/usr/bin/env bash
# Capture + compose Puzzlestack store screenshots locally.
#
# Usage:
#   tool/screenshots.sh <device_id>     # a simulator UDID, or emulator-5554
#
# ⚠️ Capture on an **iOS simulator** set to **en-US**. Two traps, both of which have already
# cost a full run:
#   1. Device locale drives the app's own language. A pt-BR simulator produces a mixed
#      English/Portuguese set, because a localized Flutter app falls back to the template
#      locale only for keys its active locale is missing.
#   2. Android's 1080x2400 stretches ~2.5% when fitted to the 1290x2796 iPhone canvas.
#
#   xcrun simctl spawn <UDID> defaults write "Apple Global Domain" AppleLanguages -array "en-US"
#   xcrun simctl spawn <UDID> defaults write "Apple Global Domain" AppleLocale -string "en_US"
#   xcrun simctl shutdown <UDID> && xcrun simctl boot <UDID>
#
# Output:
#   screenshots/raw/                              raw device PNGs
#   screenshots/aso-refresh/final/ios/iphone/     1290x2796, App Store
#   screenshots/aso-refresh/final/android/phone/  1290x2796, Google Play
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:-}"

echo "==> flutter pub get"
flutter pub get

echo "==> generating code (riverpod / freezed)"
dart run build_runner build --delete-conflicting-outputs

echo "==> capturing screenshots"
rm -rf screenshots/raw
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_test.dart \
  ${DEVICE:+-d "$DEVICE"}

echo "==> composing store images (house style)"
python3 tool/compose_house_style.py

echo "==> done. Store-ready images:"
find screenshots/aso-refresh/final -type f | sort
