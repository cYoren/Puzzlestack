import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/posthog.dart';

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

Future<void> _start(PostHog analytics, [PostHogStorage? storage]) =>
    analytics.start(
      platform: 'android',
      locale: 'en',
      storage: storage ?? MemoryPostHogStorage(),
    );

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
    final MemoryPostHogStorage storage = MemoryPostHogStorage(<String, String>{
      'posthog.consent': 'false',
    });
    final PostHog analytics = _postHog(wire);
    await _start(analytics, storage);
    analytics.boardStarted(gameId: 'sudoku');
    analytics.boardFinished(gameId: 'sudoku');

    expect(analytics.consent, isFalse);
    expect(wire.bodies, isEmpty);
  });

  test(
    'every payload carries the app, the platform and no personal keys',
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
      expect(events, <String>[
        'app_opened',
        'puzzle_started',
        'puzzle_completed',
        'first_value',
        'contact_click',
      ]);

      for (final Map<String, Object?> properties in wire.properties) {
        expect(properties['app'], 'puzzlestack');
        expect(properties['platform'], 'android');
        expect(properties['app_version'], postHogBuildVersion);
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
    },
  );

  test('the reported version matches pubspec.yaml', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? match = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml has no version line');
    expect(postHogBuildVersion, match!.group(1));
  });

  test(
    'turning the switch off sends the opt-out first, then nothing',
    () async {
      final _FakeWire wire = _FakeWire();
      final MemoryPostHogStorage storage = MemoryPostHogStorage();
      final PostHog analytics = _postHog(wire);
      await _start(analytics, storage);
      wire.bodies.clear();

      await analytics.setConsent(false);
      analytics.boardStarted(gameId: 'akari');

      expect(analytics.active, isFalse);
      expect(storage.read('posthog.consent'), 'false');
      expect(wire.events.map((Map<String, Object?> e) => e['event']), <String>[
        'settings_analytics_opt_out',
      ]);
    },
  );

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
