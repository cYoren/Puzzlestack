import 'dart:math';

/// One Ghost Tap session: how fast the pulse runs, and how many cycles it stays
/// visible before it vanishes.
///
/// Both are drawn per game. A fixed 1.5 s pulse made every session the same
/// exercise; two games in a row were one game twice (check 5, "it stays fresh").
/// The band is narrow on purpose: below [minPeriodMs] the peak is not humanly
/// readable, above [maxPeriodMs] it stops being a rhythm.
class GhostTapSession {
  const GhostTapSession({
    required this.periodMs,
    required this.visibleCycles,
    this.toleranceMs = 180,
  });

  /// Length of one full breath of the pulse, in milliseconds.
  final int periodMs;

  /// How many cycles the circle stays visible before the first ghost cycle.
  final int visibleCycles;

  /// How far off a peak a tap may land and still count, in milliseconds.
  final int toleranceMs;

  static const int minPeriodMs = 1200;
  static const int maxPeriodMs = 1900;
  static const int minVisibleCycles = 2;
  static const int maxVisibleCycles = 3;

  /// A session drawn from [random], inside every band this class documents.
  factory GhostTapSession.random(Random random, {int toleranceMs = 180}) =>
      GhostTapSession(
        periodMs: minPeriodMs + random.nextInt(maxPeriodMs - minPeriodMs + 1),
        visibleCycles: minVisibleCycles +
            random.nextInt(maxVisibleCycles - minVisibleCycles + 1),
        toleranceMs: toleranceMs,
      );

  /// Beats per minute, for a session label.
  double get bpm => 60000 / periodMs;

  /// How far a tap landed from the nearest peak, given the time since the last
  /// peak. Peak is at the start and at the end of a cycle, so the distance is
  /// folded onto the shorter side.
  int distanceToPeak(int sincePeakMs) {
    final into = sincePeakMs % periodMs;
    return min(into, periodMs - into);
  }

  /// Whether a tap this far from a peak counts as on the beat.
  bool isOnBeat(int sincePeakMs) => distanceToPeak(sincePeakMs) <= toleranceMs;
}
