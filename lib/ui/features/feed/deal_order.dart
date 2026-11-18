import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../data/game_profiles.dart';
import '../../../data/key_value_store.dart';

/// Fixed first-session onboarding hand (`docs/FEED.md` "The first session"):
/// ten readable Deck games alternating Think, Word, and Snap.
const List<String> firstTenIds = <String>[
  'water_sort',
  'find_word',
  'lights_out',
  'color_match',
  'sudoku',
  'word_scramble',
  'game_2048',
  'schulte_table',
  'nonogram',
  'word_ladder',
];

/// Repeating eight-card rhythm (`docs/FEED.md` "The deal order"):
/// `Think Word Think Snap Think Word Think Snap`.
const List<CardKind> dealRhythm = <CardKind>[
  CardKind.think,
  CardKind.word,
  CardKind.think,
  CardKind.snap,
  CardKind.think,
  CardKind.word,
  CardKind.think,
  CardKind.snap,
];

/// Minimum distance before the same game may be dealt again (`docs/FEED.md`).
const int minRepeatSpacing = 20;

/// Window (in days) within which a puzzle seed is not repeated on one device.
const int seedNoRepeatDays = 30;

/// Player history inputs to the pure deal-order function.
@immutable
class DealHistory {
  const DealHistory({
    this.blocked = const <String>{},
    this.liked = const <String>{},
    this.solved = const <String>{},
    this.quickSkips = const <String, int>{},
    this.seen = const <String>{},
    this.cardsSeen = 0,
    this.localeCode = 'en',
  });

  final Set<String> blocked;
  final Set<String> liked;
  final Set<String> solved;

  /// Number of times each game was skipped within 5 seconds.
  final Map<String, int> quickSkips;
  final Set<String> seen;
  final int cardsSeen;
  final String localeCode;

  bool get supportsWordCards => localeCode.toLowerCase().startsWith('en');
}

/// Family bucket used to prevent dealing two cousins back to back (for example
/// two loop puzzles or two anagram games).
String dealFamilyOf(String gameId) {
  const Map<String, String> explicit = <String, String>{
    'slitherlink': 'loop',
    'masyu': 'loop',
    'yajilin': 'loop',
    'gokigen_naname': 'loop',
    'futoshiki': 'latin',
    'skyscrapers': 'latin',
    'kenken': 'latin',
    'sudoku': 'sudoku_family',
    'killer_sudoku': 'sudoku_family',
    'word_scramble': 'anagram',
    'conundrum_anagram': 'anagram',
    'word_wheel': 'anagram',
    'find_word': 'word_guess',
    'word_ladder': 'word_step',
    'word_ladder_step': 'word_step',
    'classic_maze': 'maze',
    'compass_maze': 'maze',
    'rotating_maze': 'maze',
    'water_sort': 'sort',
    'hue_sort': 'sort',
    'hitori': 'shade',
    'kurodoko': 'shade',
    'nurikabe': 'shade',
    'heyawake': 'shade',
    'norinori': 'shade',
    'tapa': 'shade',
  };
  final String? bucket = explicit[gameId];
  if (bucket != null) return bucket;
  final String? catalogFamily = gameProfiles[gameId]?.family;
  if (catalogFamily != null && catalogFamily.isNotEmpty) return catalogFamily;
  return gameId;
}

/// Kind of [gameId] in the catalog, defaulting to [CardKind.think].
CardKind cardKindOf(String gameId) =>
    gameProfiles[gameId]?.kind ?? CardKind.think;

/// Filters [deck] by [history]: removes blocked games and drops Word cards when
/// the active language has no curated word pool yet.
List<String> eligibleDealPool(Iterable<String> deck, DealHistory history) {
  final List<String> languageFiltered = <String>[
    for (final String id in deck)
      if (history.supportsWordCards || cardKindOf(id) != CardKind.word) id,
  ];
  final List<String> unblocked = <String>[
    for (final String id in languageFiltered)
      if (!history.blocked.contains(id)) id,
  ];
  if (unblocked.isNotEmpty) return unblocked;
  if (languageFiltered.isNotEmpty) return languageFiltered;
  return deck.toList(growable: false);
}

/// Weight of [gameId] inside its [CardKind] (`docs/FEED.md` §4):
/// - liked: x3
/// - solved before and not quick-skipped: x1.5
/// - skipped within 5s k times: x(0.5^k), floored at x0.1
/// - never seen: x2 for first 100 cards, x1.2 after
double dealWeightFor(String gameId, DealHistory history) {
  double weight = 1.0;
  if (history.liked.contains(gameId)) {
    weight *= 3.0;
  }
  final int skips = history.quickSkips[gameId] ?? 0;
  if (history.solved.contains(gameId) && skips == 0) {
    weight *= 1.5;
  }
  if (skips > 0) {
    weight *= max(0.1, pow(0.5, skips).toDouble());
  }
  if (!history.seen.contains(gameId)) {
    weight *= history.cardsSeen < 100 ? 2.0 : 1.2;
  }
  return weight;
}

/// Pure deal-order generator (`docs/FEED.md`).
///
/// Given [deck], [history], and [random], produces [count] game ids obeying:
/// - `firstTenIds` on a brand-new player's first session (`includeFirstTen`),
/// - the 8-beat `Think Word Think Snap` rhythm (with `Think` filling empty
///   slots),
/// - no repeat within [minRepeatSpacing] cards (bounded by `pool.length - 1`),
/// - no two adjacent cards from the same family when another family is
///   available,
/// - weighted selection inside each kind.
List<String> dealSequence({
  required Iterable<String> deck,
  required DealHistory history,
  required Random random,
  required int count,
  List<String> recent = const <String>[],
  bool includeFirstTen = false,
}) {
  if (count <= 0) return const <String>[];
  final List<String> pool = eligibleDealPool(deck, history);
  if (pool.isEmpty) return const <String>[];
  final Set<String> poolSet = pool.toSet();

  final List<String> out = <String>[];
  final List<String> trail = <String>[...recent];
  final int spacing = min(minRepeatSpacing, max(0, pool.length - 1));

  if (includeFirstTen && history.cardsSeen == 0 && trail.isEmpty) {
    for (final String id in firstTenIds) {
      if (out.length >= count) break;
      if (poolSet.contains(id)) {
        out.add(id);
        trail.add(id);
      } else if (!history.supportsWordCards &&
          cardKindOf(id) == CardKind.word) {
        final String pick = _pickNext(
          pool: pool,
          wantedKind: CardKind.think,
          trail: trail,
          spacing: spacing,
          history: history,
          random: random,
        );
        out.add(pick);
        trail.add(pick);
      }
    }
  }

  while (out.length < count) {
    final int beat = (history.cardsSeen + trail.length) % dealRhythm.length;
    final CardKind wanted = dealRhythm[beat];
    final String pick = _pickNext(
      pool: pool,
      wantedKind: wanted,
      trail: trail,
      spacing: spacing,
      history: history,
      random: random,
    );
    out.add(pick);
    trail.add(pick);
  }

  return out;
}

String _pickNext({
  required List<String> pool,
  required CardKind wantedKind,
  required List<String> trail,
  required int spacing,
  required DealHistory history,
  required Random random,
}) {
  final Set<String> recentWindow = spacing <= 0 || trail.isEmpty
      ? const <String>{}
      : trail.sublist(max(0, trail.length - spacing)).toSet();
  final String? lastId = trail.isEmpty ? null : trail.last;
  final String? lastFamily = lastId == null ? null : dealFamilyOf(lastId);

  List<String> filterCandidates({
    required CardKind? kind,
    required bool enforceSpacing,
    required bool enforceFamily,
  }) {
    return <String>[
      for (final String id in pool)
        if ((kind == null || cardKindOf(id) == kind) &&
            (!enforceSpacing || !recentWindow.contains(id)) &&
            (!enforceFamily ||
                lastFamily == null ||
                dealFamilyOf(id) != lastFamily) &&
            id != lastId)
          id,
    ];
  }

  // 1. Wanted kind with full spacing + family guard.
  List<String> candidates = filterCandidates(
    kind: wantedKind,
    enforceSpacing: true,
    enforceFamily: true,
  );
  // 2. Fallback to Think with full spacing + family guard (`FEED.md` §2).
  if (candidates.isEmpty && wantedKind != CardKind.think) {
    candidates = filterCandidates(
      kind: CardKind.think,
      enforceSpacing: true,
      enforceFamily: true,
    );
  }
  // 3. Any kind with full spacing + family guard.
  if (candidates.isEmpty) {
    candidates = filterCandidates(
      kind: null,
      enforceSpacing: true,
      enforceFamily: true,
    );
  }
  // 4. Relax family guard before ever breaking spacing.
  if (candidates.isEmpty) {
    candidates = filterCandidates(
      kind: null,
      enforceSpacing: true,
      enforceFamily: false,
    );
  }
  // 5. Tiny-pool fallback: avoid immediate repeat if pool has > 1 game.
  if (candidates.isEmpty) {
    candidates = pool.where((String id) => id != lastId).toList();
  }
  if (candidates.isEmpty) {
    candidates = pool;
  }

  return _weightedPick(candidates, history, random);
}

String _weightedPick(
  List<String> candidates,
  DealHistory history,
  Random random,
) {
  if (candidates.length == 1) return candidates.first;
  double total = 0;
  final List<double> weights = <double>[];
  for (final String id in candidates) {
    final double w = dealWeightFor(id, history);
    weights.add(w);
    total += w;
  }
  if (total <= 0) {
    return candidates[random.nextInt(candidates.length)];
  }
  double target = random.nextDouble() * total;
  for (int i = 0; i < candidates.length; i++) {
    target -= weights[i];
    if (target <= 0) return candidates[i];
  }
  return candidates.last;
}

/// Orders one full pass of [pool] without duplicates while respecting the
/// `Think Word Think Snap` rhythm, weights, family separation, and optional
/// [leadingIds] (`firstTenIds` on a new player's first pass).
List<T> orderPassByRhythm<T extends Object>({
  required List<T> pool,
  required String Function(T item) idOf,
  required DealHistory history,
  required Random random,
  String? previousLastId,
  List<String> leadingIds = const <String>[],
}) {
  if (pool.length <= 1) return List<T>.from(pool);
  final Map<String, T> byId = <String, T>{
    for (final T item in pool) idOf(item): item,
  };
  final Set<String> remaining = byId.keys.toSet();
  final List<T> ordered = <T>[];
  String? lastId = previousLastId;

  for (final String lead in leadingIds) {
    if (remaining.remove(lead)) {
      ordered.add(byId[lead]!);
      lastId = lead;
    }
  }

  int beat = ordered.length;
  while (remaining.isNotEmpty) {
    final CardKind wanted = dealRhythm[beat % dealRhythm.length];
    beat++;
    final String? lastFamily = lastId == null ? null : dealFamilyOf(lastId);

    List<String> pickFrom(
        {required CardKind? kind, required bool familyGuard}) {
      return <String>[
        for (final String id in remaining)
          if ((kind == null || cardKindOf(id) == kind) &&
              id != lastId &&
              (!familyGuard ||
                  lastFamily == null ||
                  dealFamilyOf(id) != lastFamily))
            id,
      ];
    }

    List<String> candidates = pickFrom(kind: wanted, familyGuard: true);
    if (candidates.isEmpty && wanted != CardKind.think) {
      candidates = pickFrom(kind: CardKind.think, familyGuard: true);
    }
    if (candidates.isEmpty) {
      candidates = pickFrom(kind: null, familyGuard: true);
    }
    if (candidates.isEmpty) {
      candidates = pickFrom(kind: null, familyGuard: false);
    }
    if (candidates.isEmpty) {
      candidates = remaining.toList();
    }

    final String chosen = _weightedPick(candidates, history, random);
    remaining.remove(chosen);
    ordered.add(byId[chosen]!);
    lastId = chosen;
  }

  return ordered;
}

/// Remembers puzzle seeds dealt on this device over the last 30 days so the
/// same puzzle instance is never dealt twice within [seedNoRepeatDays] days.
class SeedHistoryStore {
  SeedHistoryStore(this._store);

  static const String rowKey = 'feed.seed_history';

  final KeyValueStore _store;

  /// Picks a positive 31-bit seed for [gameId] on [today] (`YYYY-MM-DD`) that
  /// has not been used for [gameId] within [seedNoRepeatDays] days, and records
  /// it.
  int nextSeed({
    required String gameId,
    required DateTime today,
    required Random random,
  }) {
    final DateTime dayFloor = DateTime(today.year, today.month, today.day);
    final Map<String, List<_SeedEntry>> all = _readAll(dayFloor);
    final List<_SeedEntry> entries = all[gameId] ?? <_SeedEntry>[];
    final Set<int> usedRecently = <int>{for (final e in entries) e.seed};

    int candidate = random.nextInt(0x7fffffff - 1) + 1;
    int guard = 0;
    while (usedRecently.contains(candidate) && guard < 1024) {
      candidate = random.nextInt(0x7fffffff - 1) + 1;
      guard++;
    }

    entries.add(_SeedEntry(seed: candidate, day: _fmtDay(dayFloor)));
    all[gameId] = entries;
    _writeAll(all);
    return candidate;
  }

  Map<String, List<_SeedEntry>> _readAll(DateTime today) {
    final Object? raw = _store.read(rowKey);
    if (raw is! Map) return <String, List<_SeedEntry>>{};
    final Map<String, List<_SeedEntry>> out = <String, List<_SeedEntry>>{};
    raw.forEach((Object? gameKey, Object? listRaw) {
      if (gameKey is! String || listRaw is! List) return;
      final List<_SeedEntry> kept = <_SeedEntry>[];
      for (final Object? item in listRaw) {
        if (item is! Map) continue;
        final Object? seed = item['s'];
        final Object? dayStr = item['d'];
        if (seed is! int || dayStr is! String) continue;
        final DateTime? parsed = DateTime.tryParse(dayStr);
        if (parsed == null) continue;
        final int age = today
            .difference(DateTime(parsed.year, parsed.month, parsed.day))
            .inDays;
        if (age >= 0 && age < seedNoRepeatDays) {
          kept.add(_SeedEntry(seed: seed, day: dayStr));
        }
      }
      if (kept.isNotEmpty) out[gameKey] = kept;
    });
    return out;
  }

  void _writeAll(Map<String, List<_SeedEntry>> all) {
    _store.write(rowKey, <String, Object>{
      for (final entry in all.entries)
        entry.key: <Map<String, Object>>[
          for (final e in entry.value)
            <String, Object>{'s': e.seed, 'd': e.day},
        ],
    });
  }

  static String _fmtDay(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _SeedEntry {
  const _SeedEntry({required this.seed, required this.day});
  final int seed;
  final String day;
}
