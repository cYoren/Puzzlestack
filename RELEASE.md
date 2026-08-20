# Releasing Mindstack

## Identity

| Field | Value |
| --- | --- |
| Android `applicationId` | `com.medhub.mindstack` |
| iOS / macOS bundle id | `com.medhub.mindstack` |
| Display name | Mindstack |
| Current version | see `version:` in `pubspec.yaml` (`name+buildNumber`) |

The internal Dart package is still `puzzle`. That is deliberate — it is
referenced by ~126 files and is never shown to users.

## Building

Release artifacts are built by `.github/workflows/build.yml` (Actions → Build &
Release → Run workflow, with a version tag). It produces a universal APK,
per-ABI APKs, an AAB, and a Linux tarball, then attaches them to a GitHub
release.

Signing comes from repository secrets, decoded into `android/key.properties` at
build time:

- `KEYSTORE_BASE64` — base64 of the upload keystore
- `STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`

**Keep a durable backup of that keystore.** If it is lost, the app can never be
updated under the same Play identity again.

Locally, `flutter build appbundle --release` works but falls back to the debug
signing key when `android/key.properties` is absent, so local artifacts are not
uploadable. That is fine for verifying the release compile path.

### Verified builds

Confirmed building from a clean tree on macOS (August 2026):

| Platform | Command | Result |
| --- | --- | --- |
| Android (AAB) | `flutter build appbundle --release` | 49.1 MB bundle; ~20 MB per-device after Play splits it |
| Android (APK) | `flutter build apk --debug` | package id `com.medhub.mindstack` |
| iOS | `flutter build ios --simulator --debug` | builds as `com.medhub.mindstack` |
| macOS | `flutter build macos --release` | `Mindstack.app` |
| Web | `flutter build web --release` | title, manifest and favicon all branded |

Windows and Linux have platform directories and workflows but were not built
here — they need their own hosts.

## Play Console: Data Safety answers

Verified against the source, not assumed:

- **Does your app collect or share any of the required user data types?** No.
- **Is all of the user data collected by your app encrypted in transit?** N/A —
  no data is transmitted.
- **Do you provide a way for users to request that their data is deleted?**
  Uninstalling the app or clearing its storage deletes everything.

Basis for those answers:

- All state is local, via Hive: nickname, XP, level, totals, per-game streaks,
  favourites, and settings. See `lib/data/models/`.
- There is no networking code anywhere in `lib/`, and no ads, analytics,
  attribution, or crash-reporting SDK in `pubspec.yaml`.
- `android.permission.INTERNET` is declared but currently unused by app code.
  It is retained for Shorebird OTA updates (see below).

If any of that changes, update this file, `PRIVACY.md`, and the Data Safety
form together — they must agree.

## Shorebird (OTA updates)

`shorebird.yaml` is committed and bundled as an asset, but the
`shorebird_code_push` package is **not** a dependency, and CI builds with plain
`flutter build`. So shipped builds contain no Shorebird updater and make no
network calls.

Turning Shorebird on means building via the Shorebird CLI instead of
`flutter build`. That adds a launch-time patch check to Shorebird's servers,
which **must** be disclosed in `PRIVACY.md` and the Data Safety form before
such a build is released.

## Store listing

Listing text and imagery live in `fastlane/metadata/android/en-US/`:

- `title.txt` (max 30 chars), `short_description.txt` (max 80),
  `full_description.txt` (max 4000)
- `images/icon.png` (512×512), `images/featureGraphic.png` (1024×500)
- `images/phoneScreenshots/1–8.png` (1080×1920)

Regenerate screenshots after any UI change:

```bash
tool/screenshots.sh emulator-5554
```

Then copy the ones you want from `screenshots/aso-refresh/final/android/phone/` into
`phoneScreenshots/`, numbered `1.png`–`8.png` (Play accepts at most 8).

## Still open

- **Privacy policy hosting.** `PRIVACY.md` is written and accurate but not yet
  hosted. Play and the App Store both require a public URL, and the in-app
  Privacy Policy / Terms links in `lib/ui/features/settings/settings_screen.dart`
  are placeholders pointing at the repo until one exists.
- **iOS distribution.** The `ios/` project builds, but shipping a GPL-3.0 app
  through the App Store is legally contested — the FSF's position is that
  Apple's terms conflict with the licence. Resolve before submitting. This does
  not affect Google Play.
- **First Play release.** `applicationId` changed during the rebrand, so this
  is a new listing rather than an update to any previous one.
- **Flutter SDK skew.** CI runs Flutter stable, which is ahead of the SDK this
  project builds against, and reports one deprecation:
  `cacheExtent` → `scrollCacheExtent` in
  `lib/ui/features/home/home_screen.dart`. The replacement does not exist in
  the older stable, so fix it as part of a deliberate SDK upgrade rather than
  on its own. It is an info, not a warning, and does not fail CI.
