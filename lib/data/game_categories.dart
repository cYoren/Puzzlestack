import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/design_system.dart';
import 'game_metadata.dart';
import 'game_profiles.dart';
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

  /// A room shows the games a player can open: the deal and the library.
  /// Archived games stay in the repo and out of every list.
  ///
  /// [includeArchived] is the settings switch, and the only way in: a room with
  /// it on lists the archived games after the playable ones, each marked.
  static List<GameMetadata> inCategory(String id,
          {bool includeArchived = false}) =>
      _playableFirst(allGamesMetadata.where((game) =>
          game.category == id &&
          (includeArchived || visibleIds.contains(game.id))));

  static int countIn(String id, {bool includeArchived = false}) =>
      allGamesMetadata
          .where((game) =>
              game.category == id &&
              (includeArchived || visibleIds.contains(game.id)))
          .length;

  /// Every game a player can open, across all rooms.
  static List<GameMetadata> get visible => allGamesMetadata
      .where((game) => visibleIds.contains(game.id))
      .toList(growable: false);

  /// Every game in the registry, archived ones last.
  static List<GameMetadata> library({bool includeArchived = false}) {
    if (!includeArchived) return visible;
    return _playableFirst(allGamesMetadata);
  }

  /// Playable games keep their order; the archive follows in one block, so an
  /// opt-in shelf reads as reference material instead of interrupting the room.
  static List<GameMetadata> _playableFirst(Iterable<GameMetadata> games) {
    final List<GameMetadata> playable = [];
    final List<GameMetadata> archived = [];
    for (final GameMetadata game in games) {
      (visibleIds.contains(game.id) ? playable : archived).add(game);
    }
    return [...playable, ...archived];
  }

  /// Whether this game is archived (kept, but not dealt and not searched by
  /// default).
  static bool isArchived(String id) => !visibleIds.contains(id);

  /// Every game in the deal.
  static List<GameMetadata> get deck => allGamesMetadata
      .where((game) => deckIds.contains(game.id))
      .toList(growable: false);
}

/// Derived feeds over the one registry. Pure functions, no state.
class GameFeed {
  const GameFeed._();

  static final Map<String, GameMetadata> _byId = {
    for (final game in allGamesMetadata) game.id: game,
  };

  static GameMetadata? find(String id) => _byId[id];

  /// The games that fit in under two minutes.
  ///
  /// Two sources, both in this one predicate: every `snap` card in the deal (the
  /// reflex and tap games, 15-40 seconds by the bar), plus the short think and word
  /// cards listed below. A list alone could not keep the promise as the catalog
  /// moves, and a kind alone would leave out the one-answer word cards.
  /// `test/content/quick_play_test.dart` keeps it honest.
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

  static List<GameMetadata> get quickPlay => GameCategories.deck
      .where((g) =>
          profileOf(g.id)?.kind == CardKind.snap ||
          _quickPlayIds.contains(g.id))
      .toList(growable: false);

  /// The browse list: what the player can reach, filtered and ordered.
  ///
  /// Pure on purpose. It decides which games a surface may show — archived games
  /// only behind the settings switch, hidden games never, one room at a time —
  /// and a decision about the game belongs somewhere a test can call it without
  /// a Hive box (`filteredGamesProvider` is a two-line wrapper over this).
  static List<GameMetadata> browse({
    required String searchQuery,
    required String selectedCategory,
    required Map<String, String> localizedTitles,
    Set<String> favoriteIds = const {},
    Set<String> hiddenIds = const {},
    bool includeArchived = false,
    List<GameMetadata>? registry,
  }) {
    final pool = registry ?? allGamesMetadata;
    final query = searchQuery.toLowerCase();
    final filtered = pool.where((game) {
      if (hiddenIds.contains(game.id)) return false;
      if (!includeArchived && !visibleIds.contains(game.id)) return false;
      final title = localizedTitles[game.id]?.toLowerCase() ?? '';
      final matchesSearch = game.id.toLowerCase().contains(query) ||
          title.contains(query) ||
          game.category.toLowerCase().contains(query);
      final matchesCategory =
          selectedCategory == 'ALL' || game.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    int priority(GameMetadata game) {
      if (favoriteIds.contains(game.id)) return -1;
      if (game.popularity == Popularity.high) return 0;
      if (game.popularity == Popularity.low) return 2;
      return 1;
    }

    // Archived games are listed last whatever their popularity: they are the
    // reference shelf, not a better card.
    int tier(GameMetadata game) => visibleIds.contains(game.id) ? 0 : 1;

    filtered.sort((a, b) {
      final int byTier = tier(a).compareTo(tier(b));
      return byTier != 0 ? byTier : priority(a).compareTo(priority(b));
    });
    return filtered;
  }

  /// The pool the deal draws from: the Deck (see `data/game_profiles.dart`, generated
  /// from `docs/CATALOG.md`) minus [exclude], the player's own hidden games.
  ///
  /// Never empty: a player who hid everything would otherwise be handed a dead
  /// stream, so an empty pool falls back to the whole deal.
  static List<GameMetadata> feedPool({Set<String> exclude = const {}}) {
    final pool = allGamesMetadata
        .where((g) => deckIds.contains(g.id) && !exclude.contains(g.id))
        .toList(growable: false);
    if (pool.isNotEmpty) return pool;
    final deck = GameCategories.deck;
    return deck.isEmpty ? allGamesMetadata : deck;
  }

  /// A deterministic "puzzle of the day": same for everyone on a given date,
  /// changes at local midnight, always drawn from the deal.
  ///
  /// Two rules earn the word "everyone". The order is fixed by a hash of the id
  /// rather than by registry order, because the registry is grouped by category
  /// and indexing it straight gave 23 MATH days in a row. And the draw is over
  /// the whole registry, never over the caller's hidden games, because a pool
  /// that differs per player makes the daily differ per player too. A player who
  /// hid today's game is served no card that day (`dailyPickIsHidden`), which is
  /// the display's business, not the selection's.
  static GameMetadata dailyPick({DateTime? now}) {
    final order = _hashOrderedDeal();
    return order[_dayNumber(now ?? DateTime.now()) % order.length];
  }

  /// Whether the player's own hidden list covers today's pick. The daily stays
  /// shared; the card is simply not offered, exactly as the reel hides it.
  static bool dailyPickIsHidden(
          {DateTime? now, required Set<String> exclude}) =>
      exclude.contains(dailyPick(now: now).id);

  /// Days since the epoch, counted on the calendar date the player sees. A
  /// `year * 10000 + month * 100 + day` seed looks equivalent and is not: at a
  /// month boundary it jumps by 70 instead of 1, so the stride skips entries and
  /// a third of the catalogue could never be a daily pick.
  static int _dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day)
          .difference(DateTime.utc(1970))
          .inDays;

  /// The deal in a stable order that also spreads the rooms, for the daily.
  ///
  /// Consecutive days read consecutive entries here, so this order decides what a week
  /// of dailies looks like. Sorting by a hash of the id alone was category-blind and let
  /// four LOGIC days run together; indexing the registry was worse (23 MATH days, the bug
  /// #49 fixed). Round-robin by position collapses at the tail, where the small rooms have
  /// run out and the biggest one takes every remaining day.
  ///
  /// So each room's own games are spread evenly over the whole lap by their fraction of
  /// that room (`(i + 0.5) / count`), and the lap is the merge of those room schedules.
  /// A room with 44 of 139 cards lands about every third day across the entire lap, never
  /// in a block, and the order is deterministic across runs and platforms: every copy of
  /// the app computes the same order, so everyone gets the same daily.
  static List<GameMetadata> _hashOrderedDeal() {
    final seen = _hashOrder;
    if (seen != null) return seen;

    final keyed = <MapEntry<double, GameMetadata>>[];
    final rooms = GameCategories.deck.map((g) => g.category).toSet().toList()
      ..sort((a, b) {
        final byHash = _fnv1a(a).compareTo(_fnv1a(b));
        return byHash != 0 ? byHash : a.compareTo(b);
      });
    for (final room in rooms) {
      final games =
          GameCategories.deck.where((g) => g.category == room).toList()
            ..sort((a, b) {
              final byHash = _fnv1a(a.id).compareTo(_fnv1a(b.id));
              return byHash != 0 ? byHash : a.id.compareTo(b.id);
            });
      for (var i = 0; i < games.length; i++) {
        keyed.add(MapEntry((i + 0.5) / games.length, games[i]));
      }
    }
    keyed.sort((a, b) {
      final byKey = a.key.compareTo(b.key);
      return byKey != 0 ? byKey : a.value.id.compareTo(b.value.id);
    });
    return _hashOrder =
        List<GameMetadata>.unmodifiable(keyed.map((entry) => entry.value));
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
