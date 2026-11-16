import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/game_metadata.dart';
import '../data/game_registry.dart';
import '../providers/user_providers.dart';

part 'game_providers.g.dart';

@riverpod
List<GameMetadata> filteredGames(Ref ref, {required String searchQuery, required String selectedCategory, required Map<String, String> localizedTitles}) {
  final allGames = allGamesMetadata;
  final favoriteIds = ref.watch(userDataProvider.select((d) => d.favoriteGameIds ?? []));
  final hiddenIds = ref.watch(userDataProvider.select((d) => d.hiddenGameIds ?? []));
  final favoriteSet = favoriteIds.toSet();
  final hiddenSet = hiddenIds.toSet();
  final query = searchQuery.toLowerCase();

  final filtered = allGames.where((game) {
    if (hiddenSet.contains(game.id)) return false;
    final title = localizedTitles[game.id]?.toLowerCase() ?? '';
    final matchesSearch = game.id.toLowerCase().contains(query) ||
        title.contains(query) ||
        game.category.toLowerCase().contains(query);
    final matchesCategory =
        selectedCategory == 'ALL' || game.category == selectedCategory;
    return matchesSearch && matchesCategory;
  }).toList();

  int getPriority(GameMetadata game) {
    if (favoriteSet.contains(game.id)) return -1;
    if (game.popularity == Popularity.high) return 0;
    if (game.popularity == Popularity.low) return 2;
    return 1;
  }

  filtered.sort((a, b) => getPriority(a).compareTo(getPriority(b)));

  return filtered;
}

@riverpod
Map<String, int> categoryStats(Ref ref) {
  final allGames = allGamesMetadata;
  final Map<String, int> stats = {};
  for (final game in allGames) {
    stats[game.category] = (stats[game.category] ?? 0) + 1;
  }
  stats['ALL'] = allGames.length;
  return stats;
}

@riverpod
Map<String, int> solvedStats(Ref ref) {
  final streaks = ref.watch(gameStreakProvider);
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
int solvedTodayCount(Ref ref) {
  return ref.watch(gameStreakProvider.select(
    (streaks) => streaks.values.where((s) => s.solvedToday).length,
  ));
}
