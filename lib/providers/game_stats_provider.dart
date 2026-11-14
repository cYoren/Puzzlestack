import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/game_stats_repository.dart';

/// The local record for every game, as one map.
///
/// A hand-written notifier instead of `@riverpod`: adding a stat must not cost
/// a code-generation pass over the whole app.
final gameStatsProvider =
    NotifierProvider<GameStatsNotifier, Map<String, GameStat>>(
  GameStatsNotifier.new,
);

class GameStatsNotifier extends Notifier<Map<String, GameStat>> {
  @override
  Map<String, GameStat> build() => GameStatsRepository.instance.stats;

  GameStat statFor(String gameId) =>
      state[gameId] ?? GameStatsRepository.instance.statFor(gameId);

  /// The game's best time beats this share of the player's own solves, or null
  /// while there is not enough history to say anything honest.
  int? fasterThan(String gameId) => statFor(gameId).fasterThan;

  Future<void> record(
    String gameId,
    Duration elapsed, {
    bool assisted = false,
  }) async {
    final next = await GameStatsRepository.instance.record(
      gameId,
      elapsed,
      assisted: assisted,
    );
    state = {...state, gameId: next};
  }
}
