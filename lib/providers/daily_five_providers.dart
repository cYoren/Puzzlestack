import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/posthog.dart';
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

/// Summary state for Daily Five.
///
/// Evaluates [todayKey], [today], and [streak] against [_clock] on every read
/// so an app left open across midnight never treats the new calendar day as a
/// Plus-only archive date or reports a stale streak.
class DailyFiveSummaryState {
  const DailyFiveSummaryState({
    required this.days,
    required DateTime Function() clock,
  }) : _clock = clock;

  final Map<String, DailyFiveProgress> days;
  final DateTime Function() _clock;

  String get todayKey => pickDayKey(_clock());

  int get streak => DailyFiveStore.computeStreak(days, _clock());

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
    return DailyFiveSummaryState(days: store.readAll(), clock: clock);
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
    final bool wasComplete = state.progressFor(dayKey).isComplete;
    if (!wasComplete && updated.isComplete) {
      postHog.capture('daily_completed');
    }
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
