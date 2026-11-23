# Releasing Puzzlestack

## Identity

| Field | Value |
| --- | --- |
| Android `applicationId` | `com.medhub.puzzlestack` |
| iOS / macOS bundle id | `com.medhub.puzzlestack` |
| Display name | Puzzlestack |
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
| Android (APK) | `flutter build apk --debug` | package id `com.medhub.puzzlestack` |
| iOS | `flutter build ios --simulator --debug` | builds as `com.medhub.puzzlestack` |
| macOS | `flutter build macos --release` | `Puzzlestack.app` |
| Web | `flutter build web --release` | title, manifest and favicon all branded |

Windows and Linux have platform directories and workflows but were not built
here — they need their own hosts.

## Play Console: Data Safety answers

**Entering and submitting this form is a human step in the Play Console.** No
file or command in this repo can tick a box there. The answers below are what
to tick, checked line by line against `lib/core/posthog.dart`, the only code we
wrote that talks to a server. Store billing is the platform's own network call,
not ours.

The form describes the app, not one build. The `1.1.0+16` binary reports itself
at `kLiveStoreVersion`, so it sends nothing at all; the first build above that
floor sends by default. Declare the analytics now, because the form is held
against what the app can do, not against one binary.

| Play question | Answer to tick |
| --- | --- |
| Does your app collect or share any of the required user data types? | Yes |
| Data types | App activity: App interactions (in-app actions). Device or other IDs: an app scoped anonymous install id |
| Collected or shared | Collected. Not shared: PostHog, Inc. (USA) is our processor under the EU Standard Contractual Clauses. If the console treats a processor as a third party, mark it shared with PostHog and change nothing else |
| Ephemeral | No. Events are kept in PostHog. Retention is a PostHog project setting, not something the repo can prove |
| Required or optional | Optional. On by default, switched off in Settings > Privacy > Share anonymous usage data |
| Purpose | Analytics |
| Linked to your identity | No. No account, no device id, no advertising id |
| Encrypted in transit | Yes. HTTPS to `https://us.i.posthog.com/batch/` |
| Deletion | Uninstalling the app or clearing its storage deletes the install id and the switch, so nothing further is sent. Events already sent carry only that random id, which no screen in the app displays, so a request to the contact address in `PRIVACY.md` is answered as best it can be with nothing to look up. There is no in app delete button and no web form |

### What the analytics module sends

One JSON POST to `https://us.i.posthog.com/batch/`, fired and forgotten, with a
five second ceiling and no retry. No SDK, no session recording, no heatmap, no
crash reporter. The body is:

```json
{"api_key": "phc_...", "batch": [{"event": "puzzle_completed",
  "distinct_id": "<random uuid stored on the device>",
  "timestamp": "<ISO 8601 UTC>",
  "properties": {"app": "puzzlestack", "platform": "android",
    "locale": "en", "app_version": "1.1.0+17",
    "$process_person_profile": false, "game_id": "sudoku",
    "difficulty": "medium", "duration_bucket": "30_to_60s",
    "duration_ms": 41520, "hints": "1", "assisted": false}}]}
```

- **Identifier:** a random UUID v4, made on the device at first launch and kept
  in SharedPreferences as `posthog.install_id`. Not an account, not a device id,
  not an advertising id, not derived from anything about the player. It is sent
  as `distinct_id` and is what makes two events look like one install.
- **Events:** `app_opened`, `puzzle_started`, `puzzle_completed`,
  `first_value`, `daily_completed`, `paywall_viewed`, `purchase_started`,
  `purchase_completed`, `purchase_restored`, `purchase_failed`, and
  `settings_analytics_opt_out`.
- **Properties:** `game_id`, `difficulty`, a duration bucket, the exact duration
  in milliseconds, a hint count, `assisted`, the Plus sheet reason, and the
  purchase result. Every key is filtered: a key matching
  `email|name|token|password|secret|message|text|query|prompt|content|transcript|note`
  is dropped before the payload is built.
- **Never sent:** a board, a seed, an answer, a nickname, an email, a streak, a
  solve history, a screen recording, an IP address the app chose.
- **The switch:** on by default, off in Settings > Privacy > Share anonymous
  usage data. Off is stored as `posthog.consent=false`; the next launch reads it
  and sends nothing. Turning it off first sends one event that records the
  choice, then stops.
- **Key on or off:** the key is present in the build (`postHogKey`), so the
  capability ships. Sending is still gated on four conditions: the key is
  present, the build is not the web build, the installed version is above
  `kLiveStoreVersion`, and the player's switch is on. A release build therefore
  starts reporting at the first version above `1.1.0+16`, not in this one.
- **The IP the network sees:** the app does not send one. PostHog sees the
  connection address as any server does. Whether the PostHog project stores it
  is a project setting (GeoIP), not something the repo can prove, so turn that
  setting off. The policy in `PRIVACY.md` claims neither way.

Everything else the app stores is local, via Hive and SharedPreferences:
nickname, XP, level, solve times, totals, per game streaks, Daily Five progress
and streaks, daily pick and hint counters, favourites, hidden puzzles,
difficulty preferences, theme settings, and the local Puzzlestack Plus row.

The website has its own analytics, under the same PostHog project and the name
`puzzlestack-web` (`docs/js/analytics.js`). It is not part of this form, which
covers the Android app; it is disclosed in `PRIVACY.md` and `docs/privacy.html`.

- In-app purchase (`puzzlestack_plus`, one time non-consumable) uses platform
  billing (`in_app_purchase`: Google Play Billing on Android, StoreKit on iOS).
  Apple and Google process the payment directly; Puzzlestack operates no server
  and receives no personal or payment data.
- There is no developer server, advertising SDK, attribution SDK, or
  crash-reporting SDK in `pubspec.yaml`.
- `android.permission.INTERNET` is used by the platform billing client, the
  review prompt (`in_app_review`) and that one analytics module.
  `com.android.vending.BILLING` is merged in from `in_app_purchase`, not declared
  in `android/`. `Shorebird` stays off for `1.1.0`.

If any of that changes, update this file, `PRIVACY.md`, `docs/privacy.html`,
and the Data Safety form together.

## In-app purchase (`puzzlestack_plus`)

| Field | Value |
| --- | --- |
| Product ID | `puzzlestack_plus` |
| Type | Non-consumable (one-time purchase) |
| Base price | US$4.99 (175 App Store territories / 174 Google Play regions) |
| App Store Connect | Created (`6836154241`, `READY_TO_SUBMIT`, review screenshot attached) |
| Google Play | Create and activate immediately after uploading the first `1.1.0+16` AAB (which adds `com.android.vending.BILLING`): `gplay onetimeproducts create --package com.medhub.puzzlestack --product-id puzzlestack_plus --json @tool/play_puzzlestack_plus.json --regions-version "2026/01"` followed by `gplay purchase-options batch-update-states --package com.medhub.puzzlestack --product-id puzzlestack_plus --json '{"requests":[{"activatePurchaseOptionRequest":{"packageName":"com.medhub.puzzlestack","productId":"puzzlestack_plus","purchaseOptionId":"default"}}]}'` |

## Shorebird (OTA updates)

`shorebird.yaml` is committed and bundled as an asset, but the
`shorebird_code_push` package is **not** a dependency, and CI builds with plain
`flutter build`. So shipped builds contain no Shorebird updater and make no
Shorebird network calls. The only call any build makes is the analytics POST in
the Data Safety section above.

Turning Shorebird on means building via the Shorebird CLI instead of
`flutter build`. That adds a launch-time patch check to Shorebird's servers,
which **must** be disclosed in `PRIVACY.md` and the Data Safety form before
such a build is released.

Usage analytics is gated on the **installed native version**, read at launch
with `package_info_plus`, being above `kLiveStoreVersion` in
`lib/core/posthog.dart`. A patch cannot raise that number, so a patched build
of a release at or below the floor stays silent. Bump the constant with a
store release, never with a patch, and keep `pubspec.yaml` at or above it
(`test/core/posthog_test.dart` fails otherwise).

**The `app_id` in `shorebird.yaml` belongs to the pre-rename bundle id.**
Shorebird registers an app per bundle id, so before the first Shorebird build
run `shorebird init` (or `shorebird apps create`) for `com.medhub.puzzlestack`
and commit the new `app_id`. Nothing breaks today because no shipped build
contains the updater.

## Store listing

Listing text and imagery live in two places, one per store.

Google Play — `fastlane/metadata/android/en-US/`:

- `title.txt` (max 30 chars), `short_description.txt` (max 80),
  `full_description.txt` (max 4000)
- `images/icon.png` (512×512)
- `images/featureGraphic.png` (1024×500), generated by `tool/feature_graphic.py` from the
  app's own fonts and palette, so it never drifts from the product
- `images/phoneScreenshots/1–8.png` (1080×1920)

App Store — `fastlane/metadata/ios/en-US/` and `fastlane/screenshots/en-US/`:

- `name.txt` (30), `subtitle.txt` (30), `keywords.txt` (100, comma-separated, no spaces),
  `promotional_text.txt` (170), `description.txt` (4000), `support_url.txt`,
  `marketing_url.txt`, `privacy_url.txt`, `copyright.txt`
- `fastlane/screenshots/en-US/1–8.png` at 1290×2796, which is what `deliver` reads by default

Regenerate screenshots after any UI change:

```bash
tool/screenshots.sh emulator-5554      # an emulator id or a simulator UDID
```

The script writes raw captures to `screenshots/raw/` and composes both canvases with
`tool/compose_house_style.py`: `screenshots/aso-refresh/final/play/` at 1080×1920 and
`screenshots/aso-refresh/final/ios/` at 1290×2796. Copy the Play set into
`images/phoneScreenshots/` and the App Store set into `fastlane/screenshots/en-US/`, numbered
`1.png`–`8.png` (Play accepts at most 8). Two canvases, because Play refuses an aspect past
2:1 and 1290×2796 is 2.17:1; the App Store set is composed from the same raw captures, which
stretches the Android pixels about 2.5%, so a simulator capture is preferable when one is at
hand.

`test/content/store_images_test.dart` fails if either set is missing, the wrong size, or the
two listings disagree about the number of games.

## Legal pages

`PRIVACY.md` is the policy; it is published, with the terms, at:

- <https://cyoren.github.io/Puzzlestack/privacy.html>
- <https://cyoren.github.io/Puzzlestack/terms.html>

Those pages are `docs/privacy.html` and `docs/terms.html`, served by GitHub Pages from the
`main` branch's `/docs` folder. The in-app Privacy Policy and Terms links point at them. Change
`PRIVACY.md` and `docs/privacy.html` together; the date at the top of both moves when either
does.

## iOS distribution

The `ios/` project builds, and the GPL question is settled: the upstream author of "Puzzle" gave
permission for this derivative to ship through the App Store, whose terms are otherwise held to
conflict with GPL-3.0. The permission is recorded in `NOTICE`. iOS ships with Android, same
version, same copy.

## Still open

- **Store screenshots, eyes needed.** Captured on 2026-11-13 with `tool/screenshots.sh` on an
  Android 15 emulator (`emulator-5554`, wm size 1080×1920) and composed into both canvases:
  eight Play shots at 1080×1920 and eight App Store shots at 1290×2796. Sizes, existence and
  the game count in both descriptions are asserted in `test/content/store_images_test.dart`,
  which finds the `N puzzles` number and requires it to equal the visible count, 184. Nobody
  has looked at the pictures: glance at the eight before uploading, and recapture the App
  Store set on a simulator when one is at hand.
- **Play Data Safety form.** The answers above are checked against the source and ready to
  enter. Entering and submitting them is a human step in the Play Console; the repo cannot do
  it.
- **Shorebird `app_id`.** Still the pre-rename id. Harmless while no shipped build bundles the
  updater; create a new one if OTA is wanted at launch.
- **First Play release.** `applicationId` changed during the rebrand, so this is a new listing
  rather than an update to any previous one.
- **Flutter SDK skew.** CI runs Flutter stable, which is ahead of the SDK this
  project builds against, and reports one deprecation:
  `cacheExtent` → `scrollCacheExtent` in
  `lib/ui/features/home/home_screen.dart`. The replacement does not exist in
  the older stable, so fix it as part of a deliberate SDK upgrade rather than
  on its own. It is an info, not a warning, and does not fail CI.
