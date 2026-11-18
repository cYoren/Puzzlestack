import 'package:flutter/foundation.dart';

import '../key_value_store.dart';
import 'pick_ledger.dart';

/// How many hints a day the free product allows across the whole app.
const int freeHintsPerDay = 3;

/// One day's hints, rolled over at local midnight.
@immutable
class HintDay {
  const HintDay({required this.day, this.used = 0});

  final String day;
  final int used;

  int get remaining => (freeHintsPerDay - used).clamp(0, freeHintsPerDay);

  bool get exhausted => used >= freeHintsPerDay;

  HintDay spend() => HintDay(day: day, used: used + 1);

  Map<String, dynamic> toJson() => {'day': day, 'used': used};

  static HintDay? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? day = raw['day'];
    if (day is! String || day.isEmpty) return null;
    final Object? used = raw['used'];
    if (used is! int || used < 0) return null;
    return HintDay(day: day, used: used);
  }

  @override
  bool operator ==(Object other) =>
      other is HintDay && other.day == day && other.used == used;

  @override
  int get hashCode => Object.hash(day, used);
}

/// Tracks hints used today on this device.
///
/// Shares the `picks` box with [PickLedger] under a distinct key so startup
/// opens no extra Hive box before the first frame.
class HintLedger {
  HintLedger(this._store, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static const String dayKey = 'hints_day';

  final KeyValueStore _store;
  final DateTime Function() _now;

  Future<HintDay> today() async {
    final String key = pickDayKey(_now());
    final HintDay? stored = HintDay.fromJson(_store.read(dayKey));
    if (stored != null && stored.day == key) return stored;
    final HintDay fresh = HintDay(day: key);
    await _store.write(dayKey, fresh.toJson());
    return fresh;
  }

  Future<HintDay> spend() async {
    final HintDay spent = (await today()).spend();
    await _store.write(dayKey, spent.toJson());
    return spent;
  }
}
