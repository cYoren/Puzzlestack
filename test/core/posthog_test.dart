import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/posthog.dart';

/// A store build that carries this file: above the version live in the stores.
/// The number is the binary's, not this source tree's.
const String _storeBuild = '1.1.1';

/// The version currently in the stores, per `kLiveStoreVersion`.
const String _liveVersion = '1.1.0';

/// Records what would have gone on the wire, without a socket.
class _FakeWire {
  final List<Map<String, Object?>> bodies = <Map<String, Object?>>[];

  Future<bool> send(Uri endpoint, String body) async {
    bodies.add(jsonDecode(body) as Map<String, Object?>);
    return true;
  }

  List<Map<String, Object?>> get events => bodies
      .expand(
        (Map<String, Object?> b) =>
            (b['batch'] as List<dynamic>).cast<Map<String, Object?>>(),
      )
      .toList(growable: false);

  List<Map<String, Object?>> get properties => events
      .map((Map<String, Object?> e) => e['properties'] as Map<String, Object?>)
      .toList(growable: false);
}

PostHog _postHog(_FakeWire wire, {String key = 'phc_test'}) {
  return PostHog(
    apiKey: key,
    sender: wire.send,
    clock: () => DateTime.utc(2026, 11, 22, 12),
    newId: () => 'install-1',
  );
}

/// A cold start, with the installed native version a build would report. An
/// empty string stands for a platform that could not answer.
Future<void> _start(
  PostHog analytics, {
  PostHogStorage? storage,
  String nativeVersion = _storeBuild,
}) =>
    analytics.start(
      platform: 'android',
      locale: 'en',
      storage: storage ?? MemoryPostHogStorage(),
      nativeVersion: nativeVersion,
    );

String _pubspecVersion() {
  final String pubspec = File('pubspec.yaml').readAsStringSync();
  final RegExpMatch? match =
      RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)', multiLine: true)
          .firstMatch(pubspec);
  if (match == null) fail('pubspec.yaml has no version line');
  return match.group(1)!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sends nothing when the project key is empty', () async {
    final _FakeWire wire = _FakeWire();
    final PostHog analytics = _postHog(wire, key: '');

    await _start(analytics);
    analytics.boardStarted(gameId: 'sudoku');
    analytics.capture('paywall_viewed');

    expect(analytics.active, isFalse);
    expect(wire.bodies, isEmpty);
  });

  test('sends nothing when the player switched it off', () async {
    final _FakeWire wire = _FakeWire();
    final MemoryPostHogStorage storage =
        MemoryPostHogStorage(<String, String>{'posthog.consent': 'false'});
    final PostHog analytics = _postHog(wire);
    await _start(analytics, storage: storage);
    analytics.boardStarted(gameId: 'sudoku');
    analytics.boardFinished(gameId: 'sudoku');

    expect(analytics.consent, isFalse);
    expect(wire.bodies, isEmpty);
  });

  test('the installed version decides, not this Dart code', () async {
    // New Dart code (this file) inside the release already in the stores: the
    // binary still says 1.1.0, so a Shorebird patch of it sends nothing. The
    // source tree is at the floor, and that must not be enough.
    expect(
      PostHog.compareVersions(_pubspecVersion(), _liveVersion),
      greaterThanOrEqualTo(0),
      reason:
          'this tree is older than what is live, so the release that carries '
          'this file would be behind the stores',
    );

    final _FakeWire wire = _FakeWire();
    final PostHog analytics = _postHog(wire);

    await _start(analytics, nativeVersion: _liveVersion);
    expect(analytics.active, isFalse);
    expect(analytics.nativeVersion, _liveVersion);
    analytics.capture('app_opened');
    expect(wire.bodies, isEmpty,
        reason: 'a patch of a live build must stay silent');

    // A build that predates this code, reported as such, is silent too.
    await _start(analytics, nativeVersion: '1.0.9');
    analytics.capture('app_opened');
    expect(wire.bodies, isEmpty);

    // A store build above the floor does send. Cleared first, so the only
    // event in the wire is the launch `start()` reports.
    wire.bodies.clear();
    await _start(analytics, nativeVersion: _storeBuild);
    expect(wire.bodies, hasLength(1));
    expect(wire.properties.single['app_version'], _storeBuild);
  });

  test('an unreadable installed version fails closed', () async {
    final _FakeWire wire = _FakeWire();
    final PostHog analytics = _postHog(wire);

    await _start(analytics, nativeVersion: '');

    expect(analytics.nativeVersion, isNull);
    expect(analytics.active, isFalse);
    analytics.capture('app_opened');
    expect(
      wire.bodies,
      isEmpty,
      reason: 'a version it cannot read is not a licence to send',
    );
  });

  test('versions compare numerically, not as strings', () {
    expect(PostHog.compareVersions('1.1.10', '1.1.9'), 1);
    expect(PostHog.compareVersions('1.1.0', '1.1.0'), 0);
    expect(PostHog.compareVersions('1.0.9', '1.1.0'), -1);
    expect(PostHog.compareVersions('1.1.0+16', '1.1.0'), 1);
    expect(PostHog.compareVersions('1.1.1+17', '1.1.1+16'), 1);
  });

  test('every payload carries the app, the platform and no personal keys',
      () async {
    final _FakeWire wire = _FakeWire();
    final PostHog analytics = _postHog(wire);
    await _start(analytics);
    analytics.boardStarted(gameId: 'sudoku', difficulty: 'easy');
    analytics.boardHinted();
    analytics.boardFinished(
      gameId: 'sudoku',
      difficulty: 'easy',
      elapsed: const Duration(seconds: 47),
      firstValue: true,
    );
    analytics.capture('contact_click', <String, Object?>{
      'email': 'someone@example.com',
      'player_name': 'Gus',
      'free_text': 'my answer was 42',
      'token': 'abc',
      'screen': 'settings',
    });

    final List<String> events = wire.events
        .map((Map<String, Object?> e) => e['event'] as String)
        .toList();
    expect(
      events,
      <String>[
        'app_opened',
        'puzzle_started',
        'puzzle_completed',
        'first_value',
        'contact_click',
      ],
    );

    for (final Map<String, Object?> properties in wire.properties) {
      expect(properties['app'], 'puzzlestack');
      expect(properties['platform'], 'android');
      expect(properties['app_version'], _storeBuild);
      expect(properties['locale'], 'en');
      expect(properties[r'$process_person_profile'], isFalse);
      for (final String key in properties.keys) {
        expect(postHogBlockedKey.hasMatch(key), isFalse, reason: key);
      }
    }

    final Map<String, Object?> completed = wire.properties[2];
    expect(completed['game_id'], 'sudoku');
    expect(completed['difficulty'], 'easy');
    expect(completed['duration_bucket'], '30_to_60s');
    expect(completed['duration_ms'], 47000);
    expect(completed['hints'], '1');
    expect(completed['assisted'], isFalse);

    final Map<String, Object?> contact = wire.properties[4];
    expect(contact['screen'], 'settings');
    expect(contact.containsKey('email'), isFalse);

    for (final Map<String, Object?> event in wire.events) {
      expect(event['distinct_id'], 'install-1');
      expect(event['timestamp'], '2026-11-22T12:00:00.000Z');
    }
  });

  test('the reportable version matches pubspec.yaml', () {
    expect(postHogBuildVersion, _pubspecVersion());
  });

  test('the version in the stores cannot catch up with this tree', () {
    // The floor in the module is the release in the stores when it was
    // written. This tree is that release today (it cannot be inside a binary
    // already in review), so equality is the expected state: the build that
    // carries this file is the next version, and it must be above the floor.
    expect(
      PostHog.compareVersions(_pubspecVersion(), kLiveStoreVersion),
      greaterThanOrEqualTo(0),
      reason: 'pubspec.yaml must not be below kLiveStoreVersion in '
          'lib/core/posthog.dart; that constant is bumped with a store '
          'release, not a patch',
    );
  });

  test('turning the switch off sends the opt-out first, then nothing',
      () async {
    final _FakeWire wire = _FakeWire();
    final MemoryPostHogStorage storage = MemoryPostHogStorage();
    final PostHog analytics = _postHog(wire);
    await _start(analytics, storage: storage);
    wire.bodies.clear();

    await analytics.setConsent(false);
    analytics.boardStarted(gameId: 'akari');

    expect(analytics.active, isFalse);
    expect(storage.read('posthog.consent'), 'false');
    expect(
      wire.events.map((Map<String, Object?> e) => e['event']),
      <String>['settings_analytics_opt_out'],
    );
  });

  test('duration and hint buckets are stable', () {
    expect(postHogDurationBucket(const Duration(seconds: 12)), 'under_30s');
    expect(postHogDurationBucket(const Duration(seconds: 45)), '30_to_60s');
    expect(postHogDurationBucket(const Duration(minutes: 2)), '1_to_3m');
    expect(postHogDurationBucket(const Duration(minutes: 5)), '3_to_10m');
    expect(postHogDurationBucket(const Duration(minutes: 30)), 'over_10m');
    expect(postHogHintBucket(0), '0');
    expect(postHogHintBucket(1), '1');
    expect(postHogHintBucket(2), '2');
    expect(postHogHintBucket(9), '3_plus');
  });
}
