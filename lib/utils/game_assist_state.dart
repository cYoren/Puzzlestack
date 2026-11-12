/// Solves that came from the solve button, by game.
///
/// A solve for the player still finishes the board, but it does not earn XP and
/// does not extend a streak. `GameStreakNotifier.completeGame` consumes the flag
/// exactly once, and the flag is cleared on every `newGame`, so an old assisted
/// solve can never mark a later honest one.
class GameAssist {
  GameAssist._();

  static final Set<String> _assisted = <String>{};

  static void markAssisted(String gameId) => _assisted.add(gameId);

  static void clear(String gameId) => _assisted.remove(gameId);

  static bool consumeAssisted(String gameId) => _assisted.remove(gameId);
}
