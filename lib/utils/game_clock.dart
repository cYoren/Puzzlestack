/// The clock a game is timed with, kept outside the widgets.
///
/// Every game screen is wrapped by `GameScaffold`, so starting the clock there
/// and reading it in `GameStreakNotifier.completeGame` times every one of the
/// 313 games without touching a single screen.
class GameClock {
  GameClock._();

  static final Map<String, Stopwatch> _clocks = <String, Stopwatch>{};

  /// The game that most recently started. The completion dialog uses it to
  /// name the game whose record it is showing.
  static String? lastGameId;

  static void start(String gameId) {
    lastGameId = gameId;
    final clock = _clocks[gameId] ??= Stopwatch();
    clock
      ..reset()
      ..start();
  }

  /// Stops the clock and returns what it measured. Null when this game was
  /// never timed (a widget test, or a completion that arrived without a screen).
  static Duration? stop(String gameId) {
    final clock = _clocks[gameId];
    if (clock == null || !clock.isRunning) return null;
    clock.stop();
    return clock.elapsed;
  }

  /// A peek without stopping, for a HUD that wants to show elapsed time.
  static Duration? elapsed(String gameId) {
    final clock = _clocks[gameId];
    return clock?.elapsed;
  }
}
