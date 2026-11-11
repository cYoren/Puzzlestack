#!/bin/sh
# Xcode Cloud runs this after the clone and before it resolves dependencies. It lives in
# <flutter app>/ios/ci_scripts/, which can be a subdirectory of the repository.
set -eu

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin:$PATH"

APP_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$APP_DIR"
echo "ci_post_clone: app dir $APP_DIR"

if ! command -v flutter >/dev/null 2>&1; then
  echo "ci_post_clone: Flutter not found, installing stable"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
fi

flutter --version
flutter precache --ios
# Only apps with a plugin published as a Swift package (sentry_flutter) need SPM. Forcing it on
# breaks plugins that ship only a podspec, and the app then fails with "Module 'x' not found".
if grep -q "sentry_flutter" pubspec.yaml; then
  echo "ci_post_clone: sentry_flutter present, enabling Swift Package Manager"
  flutter config --enable-swift-package-manager
else
  flutter config --no-enable-swift-package-manager
fi
flutter pub get

if [ -f ios/Podfile ]; then
  if command -v pod >/dev/null 2>&1; then
    (cd ios && pod install)
  elif command -v gem >/dev/null 2>&1; then
    echo "ci_post_clone: CocoaPods missing, installing with gem"
    gem install cocoapods --no-document
    (cd ios && pod install)
  else
    echo "ci_post_clone: no pod and no gem available; continuing without pods"
  fi
fi

# Xcode Cloud turns automatic package resolution off and rejects a resolved file that does not
# match the graph Flutter just generated, so resolve now and write the real pins.
RES="ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if flutter config | grep -q "enable-swift-package-manager: true"; then
  mkdir -p "$(dirname "$RES")"
  xcodebuild -resolvePackageDependencies -workspace ios/Runner.xcworkspace -scheme Runner
  echo "ci_post_clone: pins in $RES: $(grep -c identity "$RES" || true)"
fi

echo "ci_post_clone: ready"
