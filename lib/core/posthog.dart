library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'posthog_transport.dart';

/// The whole PostHog integration: events, the opt-out, and the off switches.
///
/// Nothing here is an SDK. One plain HTTPS POST to PostHog's batch endpoint,
/// fire and forget, small enums and numbers only. No board, no seed, no answer,
/// no nickname, no streak, no email: those are not ours to send.
///
/// Three ways to switch it off, cheapest first:
///
///  1. Reset the project API key in PostHog. Every installed build is rejected
///     at the edge; nothing to ship, no store review.
///  2. Set [postHogKey] to `''`. [active] turns false, every call returns
///     without touching the network, and the next build goes out quiet.
///  3. Delete this file and its four call sites: `main.dart` (start),
///     `ui/core/juice/game_scaffold.dart` (a board started),
///     `ui/core/assist/hint_request.dart` (a hint was taken),
///     `providers/user_providers.dart` (a solve and the first value),
///     `providers/daily_five_providers.dart`, `ui/features/plus/plus_sheet.dart`
///     and `data/purchase/plus_controller.dart`. Settings loses its switch.
///
/// The transport is the only thing split into another file, because `dart:io`
/// cannot compile for the browser; the app's web build sends nothing. The
/// website's pages have their own tiny module (`docs/js/analytics.js`).
///
/// A release build must not reach live players through an over-the-air update,
/// and this app ships with Shorebird configured (`shorebird.yaml`).
/// [kLiveStoreVersion] is the version currently in the stores; a build at or
/// below it does not send, and neither does a build that predates this file.
///
/// The version that decides is the **installed native version**, read from the
/// platform at runtime, never the Dart constant below: a Shorebird patch
/// replaces this file but not the binary, so a patched 1.1.0 build reports
/// 1.1.0 and stays silent. `package_info_plus` is a native plugin, which also
/// means Shorebird itself refuses to patch a release that never had it.

/// The PostHog project "Games and small sites". A project key is public by
/// design, like a Sentry DSN; it can only ingest, not read.
const String postHogKey = 'phc_zLwpAJq2pqBggPtCN2VF4EvuNR8wk2uoSpK62A6hhT6o';

/// Names this product in every event. The site's pages use `puzzlestack-web`.
const String postHogApp = 'puzzlestack';

/// The version this source tree is. Only the test that keeps it equal to
/// `pubspec.yaml` reads it: what an event reports is the *installed native*
/// version ([PostHog.nativeVersion]), so a patch cannot claim a newer build.
const String postHogBuildVersion = '1.1.0';

/// The version live on the stores when this file was written. Not what this
/// code is: it is the floor. Anything at or below it was built before this
/// file existed, so it stays silent however new its Dart code is.
///
/// On 2026-11-22 no version had been released: the App Store has `1.1.0`
/// waiting for review and Play has `1.1.0+16` on the internal track only. That
/// `1.1.0` binary is the one a patch could reach, so it is the floor. The next
/// release above it is the first build that reports anything.
const String kLiveStoreVersion = '1.1.0';

final Uri postHogEndpoint = Uri.parse('https://us.i.posthog.com/batch/');

/// A batched payload as the wire sends it. Injected in tests.
typedef PostHogSender = Future<bool> Function(Uri endpoint, String body);

const String _installIdRow = 'posthog.install_id';
const String _consentRow = 'posthog.consent';

/// Any property whose key looks like something a person typed or owns is
/// dropped before the payload is built. It is applied to the properties a call
/// site supplies, never to this module's own envelope (`app`, `platform`,
/// `app_version`, `locale`), which every event needs. Belt and braces: no call
/// site sends a personal key in the first place.
final RegExp postHogBlockedKey = RegExp(
  r'(email|name|token|password|secret|message|text|query|prompt|content|transcript|note)',
  caseSensitive: false,
);

/// A duration as one of five buckets. Exact milliseconds are kept alongside,
/// but a bucket survives a chart that a single 900 ms outlier would ruin.
String postHogDurationBucket(Duration duration) {
  final int ms = duration.inMilliseconds;
  if (ms < 30000) return 'under_30s';
  if (ms < 60000) return '30_to_60s';
  if (ms < 180000) return '1_to_3m';
  if (ms < 600000) return '3_to_10m';
  return 'over_10m';
}

/// How many hints a board took, as a bucket.
String postHogHintBucket(int hints) {
  if (hints <= 0) return '0';
  if (hints == 1) return '1';
  if (hints == 2) return '2';
  return '3_plus';
}

/// Keeps only properties this module is allowed to send: enums, numbers,
/// booleans and short strings, with any personal-looking key dropped.
Map<String, Object?> postHogSafeProperties(Map<String, Object?> properties) {
  final Map<String, Object?> safe = <String, Object?>{};
  properties.forEach((String key, Object? value) {
    if (value == null) return;
    if (postHogBlockedKey.hasMatch(key)) return;
    if (value is num || value is bool || value is String) safe[key] = value;
  });
  return safe;
}

/// Where the install id and the switch survive a restart.
abstract class PostHogStorage {
  String? read(String key);
  Future<void> write(String key, String value);
}

/// The real one: `SharedPreferences`, already a dependency.
class PostHogPrefsStorage implements PostHogStorage {
  PostHogPrefsStorage(this._prefs);

  final SharedPreferences _prefs;

  /// Null when the platform store cannot be opened. Analytics then works for
  /// this launch and remembers nothing, which is the harmless way to fail.
  static Future<PostHogPrefsStorage?> open() async {
    try {
      return PostHogPrefsStorage(await SharedPreferences.getInstance());
    } catch (_) {
      return null;
    }
  }

  @override
  String? read(String key) {
    try {
      return _prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (_) {
      // A full disk must not be this module's problem.
    }
  }
}

class MemoryPostHogStorage implements PostHogStorage {
  MemoryPostHogStorage([Map<String, String>? seed]) : _rows = {...?seed};

  final Map<String, String> _rows;

  @override
  String? read(String key) => _rows[key];

  @override
  Future<void> write(String key, String value) async => _rows[key] = value;
}

class PostHog {
  PostHog({
    String? apiKey,
    this.app = postHogApp,
    this.version = postHogBuildVersion,
    this.platform = 'unknown',
    this.locale = '',
    PostHogSender? sender,
    DateTime Function()? clock,
    String Function()? newId,
  })  : apiKey = apiKey ?? postHogKey,
        _send = sender ?? postHogPost,
        _clock = clock ?? DateTime.now,
        _newId = newId ?? _randomId;

  /// The one instance the app talks to. Tests build their own.
  static PostHog instance = PostHog();

  final String apiKey;
  final String app;
  final String version;

  /// `android`, `ios`, `linux`, `windows`, `macos`, or `web` in a site build.
  String platform;

  /// The UI language, so a funnel can be read per language without asking who
  /// the player is.
  String locale;

  final PostHogSender _send;
  final DateTime Function() _clock;
  final String Function() _newId;

  PostHogStorage? _storage;
  String _installId = '';
  bool _consent = true;
  int _boardHints = 0;

  /// The version of the **binary** this Dart code is running inside, read from
  /// the platform. A Shorebird patch cannot change it, which is the whole
  /// point: a patched 1.1.0 still says 1.1.0.
  String? _nativeVersion;

  /// The installed binary's version, once [start] has read it. Null when the
  /// platform could not answer, which is a reason to stay silent.
  String? get nativeVersion => _nativeVersion;

  /// Does this build send at all? False with an empty key, false on the web
  /// build, false when the player turned the switch off, and false unless the
  /// installed native version is above the one live in the stores.
  bool get active {
    final String? version = _nativeVersion;
    return apiKey.isNotEmpty &&
        _consent &&
        !isPostHogWebBuild &&
        version != null &&
        version.isNotEmpty &&
        compareVersions(version, kLiveStoreVersion) > 0;
  }

  /// What the Settings switch shows. The player's choice, whether or not this
  /// build happens to have a key.
  bool get consent => _consent;

  /// The random per-install id. Never an account, never a device id.
  String get installId => _installId;

  /// How many hints the board on screen has taken.
  int get boardHints => _boardHints;

  /// Called once from `main()` before the first frame: reads the switch, the
  /// install id and the installed native version, remembers the first two, and
  /// reports the open that just happened.
  ///
  /// [nativeVersion] exists for tests. Left null, the version is read from the
  /// platform; a version that cannot be read is a version that does not send.
  Future<void> start({
    String? platform,
    String? locale,
    PostHogStorage? storage,
    String? nativeVersion,
  }) async {
    if (platform != null && platform.isNotEmpty) this.platform = platform;
    if (locale != null && locale.isNotEmpty) this.locale = locale;
    _storage = storage ?? await PostHogPrefsStorage.open();
    _nativeVersion = nativeVersion != null && nativeVersion.isNotEmpty
        ? nativeVersion
        : (nativeVersion == null ? await _readNativeVersion() : null);

    final String? storedId = _storage?.read(_installIdRow);
    if (storedId != null && storedId.isNotEmpty) {
      _installId = storedId;
    } else {
      _installId = _newId();
      await _storage?.write(_installIdRow, _installId);
    }

    _consent = _storage?.read(_consentRow) != 'false';

    capture('app_opened');
  }

  /// The installed app's own version, so a patch cannot claim to be newer than
  /// the release it landed in.
  Future<String?> _readNativeVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return info.version.isEmpty ? null : info.version;
    } catch (_) {
      return null;
    }
  }

  /// The Settings switch. Turning it off follows the one event that records the
  /// choice, so the reason a player disappears is visible in the funnel.
  Future<void> setConsent(bool enabled) async {
    if (_consent == enabled) return;
    if (!enabled) capture('settings_analytics_opt_out');
    _consent = enabled;
    await _storage?.write(_consentRow, enabled ? 'true' : 'false');
  }

  /// A board became visible. Resets the hint count for it.
  void boardStarted({required String gameId, String? difficulty}) {
    _boardHints = 0;
    capture('puzzle_started', <String, Object?>{
      'game_id': gameId,
      if (difficulty != null && difficulty.isNotEmpty) 'difficulty': difficulty,
    });
  }

  /// One hint was taken on the board on screen.
  void boardHinted() {
    if (_boardHints < 99) _boardHints += 1;
  }

  /// A board was finished, solved or given up on. [firstValue] is the first
  /// puzzle the player ever finished.
  void boardFinished({
    required String gameId,
    String? difficulty,
    Duration? elapsed,
    bool assisted = false,
    bool firstValue = false,
  }) {
    capture('puzzle_completed', <String, Object?>{
      'game_id': gameId,
      if (difficulty != null && difficulty.isNotEmpty) 'difficulty': difficulty,
      'duration_bucket':
          elapsed == null ? 'unknown' : postHogDurationBucket(elapsed),
      if (elapsed != null) 'duration_ms': elapsed.inMilliseconds,
      'hints': postHogHintBucket(_boardHints),
      'assisted': assisted,
    });
    if (firstValue) {
      capture('first_value', <String, Object?>{'game_id': gameId});
    }
    _boardHints = 0;
  }

  /// One event. Never throws, never waits, never retries.
  void capture(String event, [Map<String, Object?> properties = const {}]) {
    if (!active) return;
    final Map<String, Object?> payload = <String, Object?>{
      'app': app,
      'platform': platform,
      if (locale.isNotEmpty) 'locale': locale,
      'app_version': _nativeVersion,
      r'$process_person_profile': false,
      ...postHogSafeProperties(properties),
    };
    final Map<String, Object?> entry = <String, Object?>{
      'event': event,
      'distinct_id': _installId.isEmpty ? 'unstarted' : _installId,
      'timestamp': _clock().toUtc().toIso8601String(),
      'properties': payload,
    };
    unawaited(_post(<Map<String, Object?>>[entry]));
  }

  Future<void> _post(List<Map<String, Object?>> batch) async {
    if (batch.isEmpty || apiKey.isEmpty) return;
    final String body = jsonEncode(<String, Object?>{
      'api_key': apiKey,
      'batch': batch,
    });
    try {
      await _send(postHogEndpoint, body).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Analytics is never a player-visible failure.
    }
  }

  /// Compares dotted versions numerically: "1.1.10" is above "1.1.9", which a
  /// string comparison gets backwards. Build numbers after `+` are compared
  /// too, so two builds of the same version are ordered.
  static int compareVersions(String a, String b) {
    final List<int> left = _numbers(a);
    final List<int> right = _numbers(b);
    final int length = left.length > right.length ? left.length : right.length;
    for (int i = 0; i < length; i++) {
      final int l = i < left.length ? left[i] : 0;
      final int r = i < right.length ? right[i] : 0;
      if (l != r) return l < r ? -1 : 1;
    }
    return 0;
  }

  static List<int> _numbers(String version) => version
      .split(RegExp(r'[^0-9]+'))
      .where((String part) => part.isNotEmpty)
      .map((String part) => int.tryParse(part) ?? 0)
      .toList();

  static String _randomId() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final String hex =
        bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

/// The app's instance, so a call site reads `postHog.capture(...)`.
PostHog get postHog => PostHog.instance;

/// The Settings switch, as state so the row repaints.
final StateProvider<bool> analyticsConsentProvider =
    StateProvider<bool>((ref) => postHog.consent);

/// What the Settings row calls.
Future<void> setAnalyticsConsent(bool enabled) async {
  await postHog.setConsent(enabled);
}
