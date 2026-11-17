import 'dart:math';

class RhythmMasterEngine {
  /// Calculates the accuracy score based on the time difference from the beat
  /// diff: difference in milliseconds
  /// interval: time between beats in milliseconds
  int calculateAccuracy(int diff, int interval) {
    if (diff < 50) return 100; // Perfect
    if (diff < 100) return 80; // Great
    if (diff < 150) return 50; // Good
    if (diff < 250) return 20; // OK
    return 0; // Miss
  }

  String getAccuracyLabel(int accuracy) {
    if (accuracy >= 100) return "PERFECT";
    if (accuracy >= 80) return "GREAT";
    if (accuracy >= 50) return "GOOD";
    if (accuracy >= 20) return "OK";
    return "MISS";
  }
}

/// One Rhythm Master session: the tempo it opens at and how much it speeds up
/// per beat.
///
/// Both are drawn per game. A fixed 60 bpm start with a fixed 2 bpm step made
/// every session the same 20 beats (check 5, "it stays fresh").
class RhythmMasterSession {
  const RhythmMasterSession({
    required this.startBpm,
    required this.stepBpm,
  });

  /// The tempo of the first beat.
  final int startBpm;

  /// How many bpm each beat adds.
  final int stepBpm;

  /// Tempo choices a session may open at.
  static const List<int> startBpms = [48, 54, 60, 66, 72, 78];

  /// Speed-ups a session may use.
  static const List<int> stepBpms = [1, 2, 3];

  /// A session drawn from [random].
  factory RhythmMasterSession.random(Random random) => RhythmMasterSession(
        startBpm: startBpms[random.nextInt(startBpms.length)],
        stepBpm: stepBpms[random.nextInt(stepBpms.length)],
      );

  /// The tempo of the beat after [beatsPlayed] beats have been played.
  int bpmAt(int beatsPlayed) => startBpm + beatsPlayed * stepBpm;

  /// Milliseconds between beats at [beatsPlayed].
  int intervalAt(int beatsPlayed) => (60000 / bpmAt(beatsPlayed)).toInt();
}
