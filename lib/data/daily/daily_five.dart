import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../ui/features/feed/deal_order.dart';
import '../game_profiles.dart';
import '../key_value_store.dart';
import '../picks/pick_ledger.dart';

/// Deck Think games whose generators accept a deterministic seed.
const List<String> dailyFiveThinkIds = <String>[
  'sudoku',
  'futoshiki',
  'lights_out',
  'signpost',
  'skyscrapers',
  'dominosa',
  'cube',
  'twiddle',
  'minesweeper',
];

/// Deck Word games whose generators accept a deterministic seed (English pool).
const List<String> dailyFiveWordIds = <String>[
  'find_word',
  'word_scramble',
  'word_search',
];

/// Deck Snap games whose generators accept a deterministic seed.
const List<String> dailyFiveSnapIds = <String>[
  'schulte_table',
  'color_match',
];

/// Fixed five-card Daily Five order (`docs/FEED.md`):
/// `Think, Word, Think, Snap, Think` (Word becomes Think outside English).
List<CardKind> dailyFiveKindsForLocale(String localeCode) {
  final bool english = localeCode.toLowerCase().startsWith('en');
  return <CardKind>[
    CardKind.think,
    english ? CardKind.word : CardKind.think,
    CardKind.think,
    CardKind.snap,
    CardKind.think,
  ];
}

/// Stable 31-bit FNV-1a hash so every platform and Dart version computes the
/// exact same seed for a date string.
int stableSeedHash(String input) {
  int hash = 0x811c9dc5;
  for (int i = 0; i < input.length; i++) {
    hash ^= input.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}

/// Deterministic seed for one card of a Daily Five hand.
int dailySeedFor(String dayKey, int slotIndex, String gameId) =>
    stableSeedHash('daily5:$dayKey:$slotIndex:$gameId');

/// Deterministic five-card Daily Five hand for [dayKey] (`YYYY-MM-DD`).
///
/// Every player on the same date and language receives the exact same five
/// games in the exact same order, with no repeated game or adjacent family.
List<String> dailyFiveForDate(
  String dayKey, {
  String localeCode = 'en',
}) {
  final Random rng = Random(stableSeedHash('hand:$dayKey'));
  final List<CardKind> kinds = dailyFiveKindsForLocale(localeCode);
  final Set<String> used = <String>{};
  final List<String> hand = <String>[];

  for (final CardKind kind in kinds) {
    final List<String> source = switch (kind) {
      CardKind.think => dailyFiveThinkIds,
      CardKind.word => dailyFiveWordIds,
      CardKind.snap => dailyFiveSnapIds,
    };
    final String? prevFamily = hand.isEmpty ? null : dealFamilyOf(hand.last);
    List<String> candidates = <String>[
      for (final String id in source)
        if (deckIds.contains(id) &&
            !used.contains(id) &&
            (prevFamily == null || dealFamilyOf(id) != prevFamily))
          id,
    ];
    if (candidates.isEmpty) {
      candidates = <String>[
        for (final String id in dailyFiveThinkIds)
          if (deckIds.contains(id) && !used.contains(id)) id,
      ];
    }
    final String pick = candidates[rng.nextInt(candidates.length)];
    used.add(pick);
    hand.add(pick);
  }
  return hand;
}

/// One finished slot in a Daily Five hand.
@immutable
class DailySlotResult {
  const DailySlotResult({
    required this.gameId,
    required this.title,
    required this.elapsedMs,
    this.badge,
  });

  final String gameId;
  final String title;
  final int elapsedMs;

  /// Optional score summary such as `'3/6'` for Find Word.
  final String? badge;
}

/// Formats milliseconds as `M:SS` (`0:41`, `4:17`).
String formatDailyDuration(int milliseconds) {
  final int totalSeconds = max(1, (milliseconds / 1000).round());
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

const List<String> _shortMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats `2026-11-14` as `14 Nov`.
String formatDailyDateLabel(String dayKey) {
  final DateTime? parsed = DateTime.tryParse(dayKey);
  if (parsed == null) return dayKey;
  return '${parsed.day} ${_shortMonths[parsed.month - 1]}';
}

/// Plain-text share block (`docs/FEED.md` "Daily Five"):
/// ```
/// Puzzlestack 14 Nov
/// Sudoku 0:41 · Find Word 3/6 · Hitori 1:12 · Schulte 0:19 · 2048 1:03
/// Total 4:17
/// ```
String formatDailyFiveShare({
  required String dayKey,
  required List<DailySlotResult> results,
}) {
  final String header = 'Puzzlestack ${formatDailyDateLabel(dayKey)}';
  final String parts = results.map((DailySlotResult r) {
    final String stat = (r.badge != null && r.badge!.isNotEmpty)
        ? r.badge!
        : formatDailyDuration(r.elapsedMs);
    return '${r.title} $stat';
  }).join(' \u00b7 ');
  final int totalMs =
      results.fold<int>(0, (int sum, DailySlotResult r) => sum + r.elapsedMs);
  return '$header\n$parts\nTotal ${formatDailyDuration(totalMs)}';
}

/// Stored progress for one calendar date's Daily Five.
@immutable
class DailyFiveProgress {
  const DailyFiveProgress({
    required this.dayKey,
    this.timesMs = const <int, int>{},
    this.badges = const <int, String>{},
  });

  final String dayKey;
  final Map<int, int> timesMs;
  final Map<int, String> badges;

  bool get isComplete => timesMs.length >= 5;

  int get solvedCount => timesMs.length.clamp(0, 5);

  int get totalMs => timesMs.values.fold<int>(0, (int sum, int ms) => sum + ms);

  DailyFiveProgress recordSlot(
    int slot, {
    required int elapsedMs,
    String? badge,
  }) {
    final Map<int, int> nextTimes = Map<int, int>.from(timesMs)
      ..[slot] = max(1000, elapsedMs);
    final Map<int, String> nextBadges = Map<int, String>.from(badges);
    if (badge != null && badge.isNotEmpty) {
      nextBadges[slot] = badge;
    }
    return DailyFiveProgress(
      dayKey: dayKey,
      timesMs: nextTimes,
      badges: nextBadges,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'day': dayKey,
        'times': <String, int>{
          for (final entry in timesMs.entries) '${entry.key}': entry.value,
        },
        if (badges.isNotEmpty)
          'badges': <String, String>{
            for (final entry in badges.entries) '${entry.key}': entry.value,
          },
      };

  static DailyFiveProgress? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? day = raw['day'];
    if (day is! String || day.isEmpty) return null;
    final Map<int, int> times = <int, int>{};
    final Object? rawTimes = raw['times'];
    if (rawTimes is Map) {
      rawTimes.forEach((Object? k, Object? v) {
        final int? slot = int.tryParse('$k');
        if (slot != null && slot >= 0 && slot < 5 && v is int && v > 0) {
          times[slot] = v;
        }
      });
    }
    final Map<int, String> badges = <int, String>{};
    final Object? rawBadges = raw['badges'];
    if (rawBadges is Map) {
      rawBadges.forEach((Object? k, Object? v) {
        final int? slot = int.tryParse('$k');
        if (slot != null &&
            slot >= 0 &&
            slot < 5 &&
            v is String &&
            v.isNotEmpty) {
          badges[slot] = v;
        }
      });
    }
    return DailyFiveProgress(dayKey: day, timesMs: times, badges: badges);
  }
}

/// Persistence and streak calculation for Daily Five.
///
/// The streak counts days with a finished Daily Five and nothing else
/// (`docs/FEED.md` line 85).
class DailyFiveStore {
  DailyFiveStore(this._store);

  static const String storageKey = 'daily_five_days';

  final KeyValueStore _store;

  Map<String, DailyFiveProgress> readAll() {
    final Object? raw = _store.read(storageKey);
    if (raw is! Map) return <String, DailyFiveProgress>{};
    final Map<String, DailyFiveProgress> out = <String, DailyFiveProgress>{};
    raw.forEach((Object? k, Object? v) {
      if (k is! String) return;
      final DailyFiveProgress? parsed = DailyFiveProgress.fromJson(v);
      if (parsed != null) out[k] = parsed;
    });
    return out;
  }

  DailyFiveProgress progressFor(String dayKey) =>
      readAll()[dayKey] ?? DailyFiveProgress(dayKey: dayKey);

  Future<DailyFiveProgress> recordSlot({
    required String dayKey,
    required int slot,
    required int elapsedMs,
    String? badge,
  }) async {
    final Map<String, DailyFiveProgress> all = readAll();
    final DailyFiveProgress updated =
        (all[dayKey] ?? DailyFiveProgress(dayKey: dayKey))
            .recordSlot(slot, elapsedMs: elapsedMs, badge: badge);
    all[dayKey] = updated;
    await _store.write(storageKey, <String, dynamic>{
      for (final entry in all.entries) entry.key: entry.value.toJson(),
    });
    return updated;
  }

  /// Consecutive days with a finished Daily Five up to [today].
  ///
  /// If today is not finished yet, an unbroken chain ending yesterday still
  /// stands so the player sees the streak they are extending today; missing a
  /// full calendar day resets it to 0.
  int streakAt(DateTime today) => computeStreak(readAll(), today);

  static int computeStreak(
    Map<String, DailyFiveProgress> all,
    DateTime today,
  ) {
    DateTime cursor = DateTime(today.year, today.month, today.day);
    final String todayKey = pickDayKey(cursor);
    if (!(all[todayKey]?.isComplete ?? false)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    int count = 0;
    while (true) {
      final String key = pickDayKey(cursor);
      if (!(all[key]?.isComplete ?? false)) break;
      count += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }
}
