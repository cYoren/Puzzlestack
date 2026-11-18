/// The clock a game is timed with, kept outside the widgets.
///
/// Every game screen is wrapped by `GameScaffold`, so starting the clock there
/// and reading it in `GameStreakNotifier.completeGame` times every one of the
/// 313 games without touching a single screen.
class GameClock {
  GameClock._();

  static final Map<String, Stopwatch> _clocks = <String, Stopwatch>{};

  /// The game that most recently started.
  static String? lastGameId;

  /// The most recently completed duration captured before `completeGame`
  /// restarts the clock for the next board.
  static String? lastStoppedGameId;
  static Duration? lastStoppedElapsed;
  static DateTime? _lastStoppedAt;

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
    lastStoppedGameId = gameId;
    lastStoppedElapsed = clock.elapsed;
    _lastStoppedAt = DateTime.now();
    return clock.elapsed;
  }

  /// A peek without stopping, for a HUD that wants to show elapsed time.
  static Duration? elapsed(String gameId) {
    final clock = _clocks[gameId];
    return clock?.elapsed;
  }

  /// Completed solve duration for [gameId], preferring [lastStoppedElapsed]
  /// when `completeGame` has just reset the running stopwatch.
  static Duration? completedElapsed(String gameId) {
    final DateTime? stoppedAt = _lastStoppedAt;
    if (lastStoppedGameId == gameId &&
        lastStoppedElapsed != null &&
        stoppedAt != null &&
        DateTime.now().difference(stoppedAt) < const Duration(seconds: 2)) {
      return lastStoppedElapsed;
    }
    return elapsed(gameId);
  }
}
