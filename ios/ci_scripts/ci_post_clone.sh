#!/bin/sh
# Xcode Cloud runs this after cloning the repository and before it resolves packages.
# A Flutter iOS build needs the Flutter SDK and the generated plugin package, neither of
# which exists in a fresh clone or in Apple's build image.
set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"
export PATH="$HOME/flutter/bin:$PATH"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter not found, installing the stable channel"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$HOME/flutter"
  flutter --version
  flutter precache --ios
fi

flutter pub get

if [ -f ios/Podfile ]; then
  if ! command -v pod >/dev/null 2>&1; then
    echo "CocoaPods not found, installing"
    gem install cocoapods --no-document
  fi
  (cd ios && pod install)
fi

echo "ci_post_clone: Flutter ready and pods installed"
