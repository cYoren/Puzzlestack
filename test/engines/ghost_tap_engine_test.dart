import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/ghost_tap/ghost_tap_engine.dart';

void main() {
  group('GhostTapSession', () {
    test('a drawn session is inside every band it documents', () {
      final random = Random(7);
      for (var i = 0; i < 200; i++) {
        final session = GhostTapSession.random(random);
        expect(session.periodMs,
            greaterThanOrEqualTo(GhostTapSession.minPeriodMs));
        expect(
            session.periodMs, lessThanOrEqualTo(GhostTapSession.maxPeriodMs));
        expect(session.visibleCycles,
            greaterThanOrEqualTo(GhostTapSession.minVisibleCycles));
        expect(session.visibleCycles,
            lessThanOrEqualTo(GhostTapSession.maxVisibleCycles));
        expect(session.toleranceMs, 180);
      }
    });

    test('two hundred draws are not one repeated session', () {
      final random = Random(11);
      final periods = <int>{};
      final delays = <int>{};
      for (var i = 0; i < 200; i++) {
        final session = GhostTapSession.random(random);
        periods.add(session.periodMs);
        delays.add(session.visibleCycles);
      }
      // The band has 701 periods and 2 ghost delays: a fixed session would give
      // one of each, which is the defect this replaced.
      expect(periods.length, greaterThan(20));
      expect(delays.length, 2);
    });

    test('a tap at a peak is on the beat, and one midway between peaks is not',
        () {
      const session = GhostTapSession(periodMs: 1000, visibleCycles: 2);

      expect(session.distanceToPeak(0), 0);
      expect(session.isOnBeat(0), isTrue);
      expect(session.distanceToPeak(1000), 0);
      expect(session.isOnBeat(1000), isTrue);
      // 500 ms after a peak is the far side of the same breath.
      expect(session.distanceToPeak(500), 500);
      expect(session.isOnBeat(500), isFalse);
      expect(
          session.isOnBeat(
              GhostTapSession(periodMs: 1000, visibleCycles: 2).periodMs - 100),
          isTrue);
    });

    test('the tolerance window is two-sided and does not depend on the period',
        () {
      const slow = GhostTapSession(periodMs: 1900, visibleCycles: 3);
      const fast = GhostTapSession(periodMs: 1200, visibleCycles: 2);

      expect(slow.isOnBeat(180), isTrue);
      expect(slow.isOnBeat(181), isFalse);
      expect(fast.isOnBeat(180), isTrue);
      expect(fast.isOnBeat(181), isFalse);
      // Just before the end of a cycle is the same distance as just after 0.
      expect(fast.distanceToPeak(1200 - 60), 60);
    });

    test('bpm is the period inverted, and gets faster as the period shortens',
        () {
      expect(const GhostTapSession(periodMs: 1000, visibleCycles: 2).bpm, 60);
      expect(const GhostTapSession(periodMs: 1500, visibleCycles: 2).bpm, 40);
      expect(
        const GhostTapSession(periodMs: 1200, visibleCycles: 2).bpm,
        greaterThan(
            const GhostTapSession(periodMs: 1900, visibleCycles: 2).bpm),
      );
    });
  });
}
