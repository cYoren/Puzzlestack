import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/design_system.dart';
import 'game_metadata.dart';
import 'game_registry.dart';

/// Metadata for one of the six game categories ("rooms").
class CategoryInfo {
  const CategoryInfo({
    required this.id,
    required this.label,
    required this.tagline,
    required this.icon,
    required this.color,
  });

  /// Matches [GameMetadata.category], e.g. `LOGIC`.
  final String id;

  /// Human label, e.g. `Logic`.
  final String label;
  final String tagline;
  final IconData icon;
  final Color color;
}

/// The six rooms, in the order shown on the home grid.
class GameCategories {
  const GameCategories._();

  static const List<CategoryInfo> all = [
    CategoryInfo(
      id: 'LOGIC',
      label: 'Logic',
      tagline: 'Deduce, place, solve.',
      icon: Icons.extension_rounded,
      color: DesignSystem.gameIndigo,
    ),
    CategoryInfo(
      id: 'MATH',
      label: 'Math',
      tagline: 'Numbers, fast and sharp.',
      icon: Icons.calculate_rounded,
      color: DesignSystem.gameAmber,
    ),
    CategoryInfo(
      id: 'MEMORY',
      label: 'Memory',
      tagline: 'Hold it, recall it.',
      icon: Icons.psychology_rounded,
      color: DesignSystem.gameTeal,
    ),
    CategoryInfo(
      id: 'SPATIAL',
      label: 'Spatial',
      tagline: 'Rotate, fold, navigate.',
      icon: Icons.threed_rotation_rounded,
      color: DesignSystem.gamePurple,
    ),
    CategoryInfo(
      id: 'ATTENTION',
      label: 'Attention',
      tagline: 'Focus under pressure.',
      icon: Icons.bolt_rounded,
      color: DesignSystem.gameRose,
    ),
    CategoryInfo(
      id: 'WORD',
      label: 'Word',
      tagline: 'Letters into meaning.',
      icon: Icons.abc_rounded,
      color: DesignSystem.gameGreen,
    ),
  ];

  static CategoryInfo info(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);

  static List<GameMetadata> inCategory(String id) => allGamesMetadata
      .where((game) => game.category == id)
      .toList(growable: false);

  static int countIn(String id) =>
      allGamesMetadata.where((game) => game.category == id).length;
}

/// Derived feeds over the one registry. Pure functions, no state.
class GameFeed {
  const GameFeed._();

  static final Map<String, GameMetadata> _byId = {
    for (final game in allGamesMetadata) game.id: game,
  };

  static GameMetadata? find(String id) => _byId[id];

  /// Curated set of fast games for the "Quick Play (under 2 min)" row.
  /// Unknown ids are skipped, so a retired game cannot break the home screen.
  static const List<String> _quickPlayIds = [
    'reflex_tap',
    'quick_math',
    'orbit_tap',
    'stroop_test',
    'go_no_go',
    'color_match',
    'math_guess',
    'schulte_table',
    'target_10',
    'odd_one_out',
    'reverse_stroop',
    'flanker_test',
  ];

  static List<GameMetadata> get quickPlay =>
      _quickPlayIds.map(find).whereType<GameMetadata>().toList(growable: false);

  /// A deterministic "puzzle of the day": same for everyone on a given date,
  /// changes at local midnight.
  static GameMetadata dailyPick([DateTime? now]) {
    final date = now ?? DateTime.now();
    final seed = date.year * 10000 + date.month * 100 + date.day;
    return allGamesMetadata[seed % allGamesMetadata.length];
  }

  /// A random game. [exclude] removes ids from the draw (hidden games); if that
  /// leaves nothing, the exclusion is ignored rather than handing back null.
  static GameMetadata randomGame({
    String? exceptId,
    Random? random,
    Set<String> exclude = const {},
  }) {
    final rng = random ?? Random();
    final pool = exclude.isEmpty
        ? allGamesMetadata
        : allGamesMetadata
            .where((g) => !exclude.contains(g.id))
            .toList(growable: false);
    final source = pool.isEmpty ? allGamesMetadata : pool;
    if (source.length <= 1 || exceptId == null) {
      return source[rng.nextInt(source.length)];
    }
    GameMetadata game;
    do {
      game = source[rng.nextInt(source.length)];
    } while (game.id == exceptId);
    return game;
  }

  /// A freshly shuffled ordering of every game, for the vertical feed.
  static List<GameMetadata> shuffledOrder({Random? random}) =>
      List<GameMetadata>.from(allGamesMetadata)..shuffle(random ?? Random());
}
