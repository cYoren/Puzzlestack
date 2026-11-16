import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/game_categories.dart';
import '../data/game_metadata.dart';
import '../data/game_registry.dart';
import '../providers/user_providers.dart';

part 'game_providers.g.dart';

@riverpod
List<GameMetadata> filteredGames(FilteredGamesRef ref,
    {required String searchQuery,
    required String selectedCategory,
    required Map<String, String> localizedTitles}) {
  final data = ref.watch(userDataNotifierProvider);
  return GameFeed.browse(
    searchQuery: searchQuery,
    selectedCategory: selectedCategory,
    localizedTitles: localizedTitles,
    favoriteIds: (data.favoriteGameIds ?? const []).toSet(),
    hiddenIds: (data.hiddenGameIds ?? const []).toSet(),
    // Archived games are kept in the registry but are not part of the app unless
    // the player turns them on in settings. This provider feeds the "next game"
    // after a solve, which is how a lab task used to come back after a win.
    includeArchived: data.showArchivedGames ?? false,
  );
}

@riverpod
Map<String, int> categoryStats(CategoryStatsRef ref) {
  final allGames = allGamesMetadata;
  final Map<String, int> stats = {};
  for (final game in allGames) {
    stats[game.category] = (stats[game.category] ?? 0) + 1;
  }
  stats['ALL'] = allGames.length;
  return stats;
}

@riverpod
Map<String, int> solvedStats(SolvedStatsRef ref) {
  final streaks = ref.watch(gameStreakNotifierProvider);
  final allGames = allGamesMetadata;
  final Map<String, int> stats = {};

  for (final game in allGames) {
    if (streaks.containsKey(game.id)) {
      stats[game.category] = (stats[game.category] ?? 0) + 1;
    }
  }
  stats['ALL'] = streaks.length;
  return stats;
}

@riverpod
int solvedTodayCount(SolvedTodayCountRef ref) {
  return ref.watch(gameStreakNotifierProvider.select(
    (streaks) => streaks.values.where((s) => s.solvedToday).length,
  ));
}
