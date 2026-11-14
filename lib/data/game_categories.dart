import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/design_system.dart';
import 'curation.dart';
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

  /// The games that fit in under two minutes: reflex and stroop drills, plus
  /// the one-answer games, which load a single task and end on the answer.
  ///
  /// This row used to list twelve ids, so "under 2 min" was promised by 4% of
  /// the catalogue while 38 games ended the run on one answer. Unknown ids are
  /// skipped, so a retired game cannot break the home screen, and
  /// `test/content/quick_play_test.dart` keeps the list honest.
  static const List<String> _quickPlayIds = [
    // Reflex and speed drills.
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
    // One answer, then the run is over.
    'affix_factory',
    'anagram_definition',
    'attentional_blink',
    'balance_scale',
    'cognate_catch',
    'collatz',
    'compound_connect',
    'cryptogram',
    'dual_mirror',
    'etymology_origin',
    'etymon_oddball',
    'letter_bridge',
    'letter_frequency_scan',
    'magic_squares',
    'missing_vowels',
    'object_shuffle',
    'odd_rotation',
    'one_letter_shift',
    'palindrome_builder',
    'path_recall',
    'phonetic_guess',
    'pixel_mimic',
    'silent_letter_search',
    'sopt',
    'spoonerism_solver',
    'symbol_logic',
    'target_number',
    'word_scramble',
  ];

  static List<GameMetadata> get quickPlay => _quickPlayIds
      .map(find)
      .whereType<GameMetadata>()
      .where((g) => !feedBlocklist.contains(g.id))
      .toList(growable: false);

  /// The pool the reel draws from: the registry minus the hand-curated blocklist
  /// (see `data/curation.dart`) minus [exclude] (the player's own hidden games).
  /// Never empty: a blocklist that covers everything would otherwise hand the
  /// feed a dead stream, so an empty pool falls back to the whole registry.
  static List<GameMetadata> feedPool({Set<String> exclude = const {}}) {
    final pool = allGamesMetadata
        .where((g) => !feedBlocklist.contains(g.id) && !exclude.contains(g.id))
        .toList(growable: false);
    return pool.isEmpty ? allGamesMetadata : pool;
  }

  /// A deterministic "puzzle of the day": same for everyone on a given date,
  /// changes at local midnight.
  ///
  /// Two rules earn the word "everyone". The order is fixed by a hash of the id
  /// rather than by registry order, because the registry is grouped by category
  /// and indexing it straight gave 23 MATH days in a row. And the draw is over
  /// the whole registry, never over the caller's hidden games, because a pool
  /// that differs per player makes the daily differ per player too. A player who
  /// hid today's game is served no card that day (`dailyPickIsHidden`), which is
  /// the display's business, not the selection's.
  static GameMetadata dailyPick({DateTime? now}) {
    final order = _hashOrderedRegistry();
    return order[_dayNumber(now ?? DateTime.now()) % order.length];
  }

  /// Whether the player's own hidden list covers today's pick. The daily stays
  /// shared; the card is simply not offered, exactly as the reel hides it.
  static bool dailyPickIsHidden({DateTime? now, required Set<String> exclude}) =>
      exclude.contains(dailyPick(now: now).id);

  /// Days since the epoch, counted on the calendar date the player sees. A
  /// `year * 10000 + month * 100 + day` seed looks equivalent and is not: at a
  /// month boundary it jumps by 70 instead of 1, so the stride skips entries and
  /// a third of the catalogue could never be a daily pick.
  static int _dayNumber(DateTime date) => DateTime.utc(date.year, date.month, date.day)
      .difference(DateTime.utc(1970))
      .inDays;

  /// The registry in a stable, category-blind order: FNV-1a over the id, then
  /// the id itself to break ties. Deterministic across runs and platforms, so
  /// every copy of the app computes the same order.
  static List<GameMetadata> _hashOrderedRegistry() {
    final seen = _hashOrder;
    if (seen != null) return seen;
    final ordered = List<GameMetadata>.from(allGamesMetadata)
      ..sort((a, b) {
        final byHash = _fnv1a(a.id).compareTo(_fnv1a(b.id));
        return byHash != 0 ? byHash : a.id.compareTo(b.id);
      });
    return _hashOrder = List<GameMetadata>.unmodifiable(ordered);
  }

  static List<GameMetadata>? _hashOrder;

  static int _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = (hash ^ unit) * 0x01000193 & 0xffffffff;
    }
    return hash;
  }

  /// A random game from the reel pool. [exclude] removes the player's hidden
  /// games from the draw.
  static GameMetadata randomGame({
    String? exceptId,
    Random? random,
    Set<String> exclude = const {},
  }) {
    final rng = random ?? Random();
    final source = feedPool(exclude: exclude);
    if (source.length <= 1 || exceptId == null) {
      return source[rng.nextInt(source.length)];
    }
    GameMetadata game;
    do {
      game = source[rng.nextInt(source.length)];
    } while (game.id == exceptId);
    return game;
  }

  /// A freshly shuffled ordering of the reel pool, for the vertical feed.
  static List<GameMetadata> shuffledOrder({Random? random}) =>
      List<GameMetadata>.from(feedPool())..shuffle(random ?? Random());
}
