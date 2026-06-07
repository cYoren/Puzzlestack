import 'dart:math';
import 'package:flutter/material.dart';
import 'game_data.dart';
import '../utils/design_system.dart';

/// A single playable game, typed view over the raw maps in [GameData.allGamesList].
class GameInfo {
  final String id;
  final String title;
  final String category; // e.g. 'LOGIC'
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const GameInfo({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.color,
    required this.builder,
  });

  factory GameInfo.fromMap(Map<String, dynamic> m) => GameInfo(
        id: m['id'] as String,
        title: m['title'] as String,
        category: m['category'] as String,
        icon: m['icon'] as IconData,
        color: m['color'] as Color,
        builder: m['builder'] as WidgetBuilder,
      );

  Widget buildScreen(BuildContext context) => builder(context);
}

/// Metadata for one of the six game categories ("rooms").
class CategoryInfo {
  final String id; // matches GameInfo.category, e.g. 'LOGIC'
  final String label; // human label, e.g. 'Logic'
  final String tagline;
  final IconData icon;
  final Color color;

  const CategoryInfo({
    required this.id,
    required this.label,
    required this.tagline,
    required this.icon,
    required this.color,
  });
}

/// Catalog helpers used by the discovery home and the shuffle feed.
/// Pure derived data over [GameData.allGamesList]; holds no mutable state.
class GameCatalog {
  GameCatalog._();

  /// All games as typed objects.
  static final List<GameInfo> all =
      GameData.allGamesList.map(GameInfo.fromMap).toList(growable: false);

  static final Map<String, GameInfo> _byId = {for (final g in all) g.id: g};

  static GameInfo? find(String id) => _byId[id];

  /// The six categories, in the order shown on the home grid.
  static const List<CategoryInfo> categories = [
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

  static CategoryInfo categoryInfo(String id) =>
      categories.firstWhere((c) => c.id == id, orElse: () => categories.first);

  static List<GameInfo> inCategory(String id) =>
      all.where((g) => g.category == id).toList(growable: false);

  static int countInCategory(String id) =>
      all.where((g) => g.category == id).length;

  /// Curated set of fast games for the "Quick Play (under 2 min)" row.
  /// Every id here exists in the registry; unknown ids are skipped safely.
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

  static List<GameInfo> get quickPlay =>
      _quickPlayIds.map(find).whereType<GameInfo>().toList(growable: false);

  /// A deterministic "puzzle of the day": same for everyone on a given date,
  /// changes at local midnight.
  static GameInfo dailyPick([DateTime? now]) {
    final d = now ?? DateTime.now();
    final seed = d.year * 10000 + d.month * 100 + d.day;
    return all[seed % all.length];
  }

  /// A random game, optionally excluding [exceptId] to avoid immediate repeats.
  static GameInfo randomGame({String? exceptId, Random? random}) {
    final r = random ?? Random();
    if (all.length <= 1 || exceptId == null) {
      return all[r.nextInt(all.length)];
    }
    GameInfo g;
    do {
      g = all[r.nextInt(all.length)];
    } while (g.id == exceptId);
    return g;
  }

  /// A freshly shuffled ordering of every game, for the vertical feed.
  static List<GameInfo> shuffledOrder({Random? random}) {
    final list = List<GameInfo>.from(all);
    list.shuffle(random ?? Random());
    return list;
  }
}
