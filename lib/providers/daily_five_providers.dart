import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daily/daily_five.dart';
import '../data/picks/pick_ledger.dart';
import 'pick_providers.dart';

/// Clock used by Daily Five, overridable in tests.
final Provider<DateTime Function()> dailyFiveClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

final Provider<DailyFiveStore> dailyFiveStoreProvider =
    Provider<DailyFiveStore>(
  (ref) => DailyFiveStore(ref.watch(pickStoreProvider)),
);

class DailyFiveSummaryState {
  const DailyFiveSummaryState({
    required this.todayKey,
    required this.days,
    required this.streak,
  });

  final String todayKey;
  final Map<String, DailyFiveProgress> days;
  final int streak;

  DailyFiveProgress progressFor(String dayKey) =>
      days[dayKey] ?? DailyFiveProgress(dayKey: dayKey);

  DailyFiveProgress get today => progressFor(todayKey);
}

class DailyFiveController extends StateNotifier<DailyFiveSummaryState> {
  DailyFiveController(this._store, this._clock) : super(_load(_store, _clock));

  final DailyFiveStore _store;
  final DateTime Function() _clock;

  static DailyFiveSummaryState _load(
    DailyFiveStore store,
    DateTime Function() clock,
  ) {
    final DateTime now = clock();
    return DailyFiveSummaryState(
      todayKey: pickDayKey(now),
      days: store.readAll(),
      streak: store.streakAt(now),
    );
  }

  void refresh() {
    state = _load(_store, _clock);
  }

  Future<DailyFiveProgress> recordSlot({
    required String dayKey,
    required int slot,
    required int elapsedMs,
    String? badge,
  }) async {
    final DailyFiveProgress updated = await _store.recordSlot(
      dayKey: dayKey,
      slot: slot,
      elapsedMs: elapsedMs,
      badge: badge,
    );
    state = _load(_store, _clock);
    return updated;
  }
}

final StateNotifierProvider<DailyFiveController, DailyFiveSummaryState>
    dailyFiveProvider =
    StateNotifierProvider<DailyFiveController, DailyFiveSummaryState>(
  (ref) => DailyFiveController(
    ref.watch(dailyFiveStoreProvider),
    ref.watch(dailyFiveClockProvider),
  ),
);
