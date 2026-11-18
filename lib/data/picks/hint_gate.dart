import 'package:flutter/foundation.dart';

import 'hint_ledger.dart';

/// Why a hint was allowed.
enum HintReason {
  /// One of today's three free hints.
  freeAllowance,

  /// Plus owns unlimited hints.
  plus,
}

/// The answer to "may I use a hint right now?".
@immutable
sealed class HintDecision {
  const HintDecision();
}

final class HintAllowed extends HintDecision {
  const HintAllowed(this.reason);

  final HintReason reason;

  @override
  bool operator ==(Object other) =>
      other is HintAllowed && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'HintAllowed(${reason.name})';
}

final class HintRefused extends HintDecision {
  const HintRefused({required this.usedToday, required this.freePerDay});

  final int usedToday;
  final int freePerDay;

  @override
  bool operator ==(Object other) =>
      other is HintRefused &&
      other.usedToday == usedToday &&
      other.freePerDay == freePerDay;

  @override
  int get hashCode => Object.hash(usedToday, freePerDay);

  @override
  String toString() => 'HintRefused($usedToday/$freePerDay)';
}

/// The hint allowance rule in one place: 3 hints a day free, unlimited with
/// Plus.
class HintGate {
  HintGate({
    required HintLedger ledger,
    required bool Function() hasPlus,
  })  : _ledger = ledger,
        _hasPlus = hasPlus;

  final HintLedger _ledger;
  final bool Function() _hasPlus;

  Future<HintDecision> request() async {
    final HintDecision decision = await preview();
    await commit(decision);
    return decision;
  }

  Future<HintDecision> preview() async {
    if (_hasPlus()) {
      return const HintAllowed(HintReason.plus);
    }
    final HintDay day = await _ledger.today();
    if (!day.exhausted) {
      return const HintAllowed(HintReason.freeAllowance);
    }
    return HintRefused(usedToday: day.used, freePerDay: freeHintsPerDay);
  }

  Future<void> commit(HintDecision decision) async {
    if (decision is! HintAllowed) return;
    switch (decision.reason) {
      case HintReason.freeAllowance:
        await _ledger.spend();
      case HintReason.plus:
        break;
    }
  }
}
