import 'package:flutter/foundation.dart';

import '../key_value_store.dart';

/// How many picks a day the free product allows. Written once, read by the
/// gate, the sheet and settings, so the three can never disagree.
const int freePicksPerDay = 3;

/// One day's picks.
///
/// Separate from the "ever opened" list on purpose: this row rolls over at
/// midnight and the memory of which games have been opened never does. A
/// counter of 0 here means nothing has been picked today, and nothing else.
@immutable
class PickDay {
  const PickDay({required this.day, this.used = 0});

  /// The local date, `2026-11-16`. A string, because that is what is stored and
  /// comparing two strings cannot drift with a timezone.
  final String day;

  final int used;

  int get remaining => (freePicksPerDay - used).clamp(0, freePicksPerDay);

  bool get exhausted => used >= freePicksPerDay;

  PickDay spend() => PickDay(day: day, used: used + 1);

  Map<String, dynamic> toJson() => {'day': day, 'used': used};

  /// Reads a stored row, or null when it is not a clean one. The caller
  /// compares [day] with today: a row from yesterday is not an error, it is a
  /// day that ended.
  static PickDay? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? day = raw['day'];
    if (day is! String || day.isEmpty) return null;
    final Object? used = raw['used'];
    if (used is! int || used < 0) return null;
    return PickDay(day: day, used: used);
  }

  @override
  bool operator ==(Object other) =>
      other is PickDay && other.day == day && other.used == used;

  @override
  int get hashCode => Object.hash(day, used);
}

/// The local date as a key, `2026-11-16`.
String pickDayKey(DateTime at) {
  final String month = at.month.toString().padLeft(2, '0');
  final String day = at.day.toString().padLeft(2, '0');
  return '${at.year}-$month-$day';
}

/// What this device has picked, and which games it has ever opened.
///
/// Local only. There is no account and no server, so a pick cannot follow the
/// player to another phone — which is the honest limit of a one-time purchase
/// with no accounts, and the same limit the store receipt has.
class PickLedger {
  PickLedger(this._store, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static const String boxName = 'picks';
  static const String dayKey = 'day';
  static const String openedKey = 'opened';

  final KeyValueStore _store;
  final DateTime Function() _now;

  /// Today's row, rolled over if the stored row belongs to another day.
  ///
  /// The rollover is written immediately: a device that is opened once at 23:59
  /// and again at 00:01 must not carry yesterday's count into today.
  Future<PickDay> today() async {
    final String key = pickDayKey(_now());
    final PickDay? stored = PickDay.fromJson(_store.read(dayKey));
    if (stored != null && stored.day == key) return stored;
    final PickDay fresh = PickDay(day: key);
    await _store.write(dayKey, fresh.toJson());
    return fresh;
  }

  /// One more pick today.
  Future<PickDay> spend() async {
    final PickDay spent = (await today()).spend();
    await _store.write(dayKey, spent.toJson());
    return spent;
  }

  /// Has this game ever been opened from the Stack? The first play of any game
  /// is free, which is what this remembers.
  bool hasOpened(String gameId) => _opened().contains(gameId);

  Future<void> markOpened(String gameId) async {
    final Set<String> opened = _opened();
    if (!opened.add(gameId)) return;
    await _store.write(openedKey, opened.toList());
  }

  Set<String> _opened() {
    final Object? raw = _store.read(openedKey);
    if (raw is! List) return <String>{};
    return {
      for (final Object? id in raw)
        if (id is String && id.isNotEmpty) id,
    };
  }
}
