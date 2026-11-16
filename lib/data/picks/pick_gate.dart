import 'package:flutter/foundation.dart';

import 'pick_ledger.dart';

/// Why a pick was allowed. The reason is kept because "free" and "spent a pick"
/// are different things to say, and because a test should be able to tell which
/// rule let the player in.
enum PickReason {
  /// The first time this game has ever been opened. Never counted.
  firstPlay,

  /// One of today's free picks.
  freeAllowance,

  /// Plus: there is no count.
  plus,
}

/// The answer to "may I open this game?".
///
/// A sealed pair rather than a bool, because a bool here would make "allowed"
/// and "out of picks" the same field with two meanings, and the sheet needs the
/// count to say something true.
@immutable
sealed class PickDecision {
  const PickDecision();
}

final class PickAllowed extends PickDecision {
  const PickAllowed(this.reason);

  final PickReason reason;

  @override
  bool operator ==(Object other) =>
      other is PickAllowed && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'PickAllowed(${reason.name})';
}

final class PickRefused extends PickDecision {
  const PickRefused({required this.usedToday, required this.freePerDay});

  /// Picks spent today. Always at least [freePerDay] here: a refusal cannot
  /// happen while the free allowance is left, which is the invariant the tests
  /// hold it to.
  final int usedToday;

  final int freePerDay;

  @override
  bool operator ==(Object other) =>
      other is PickRefused &&
      other.usedToday == usedToday &&
      other.freePerDay == freePerDay;

  @override
  int get hashCode => Object.hash(usedToday, freePerDay);

  @override
  String toString() => 'PickRefused($usedToday/$freePerDay)';
}

/// The rule, in one place.
///
/// Order matters and is the spec in docs/FEED.md: the first play of a game is
/// always free, Plus has no count, and only then does a pick cost one of three.
class PickGate {
  PickGate({
    required PickLedger ledger,
    required bool Function() hasPlus,
  })  : _ledger = ledger,
        _hasPlus = hasPlus;

  final PickLedger _ledger;
  final bool Function() _hasPlus;

  /// Asks to open [gameId]. Records what the answer used, so the caller must
  /// not call this twice for the same opening.
  Future<PickDecision> request(String gameId) async {
    if (!_ledger.hasOpened(gameId)) {
      await _ledger.markOpened(gameId);
      return const PickAllowed(PickReason.firstPlay);
    }
    if (_hasPlus()) {
      return const PickAllowed(PickReason.plus);
    }
    final PickDay day = await _ledger.today();
    if (!day.exhausted) {
      await _ledger.spend();
      return const PickAllowed(PickReason.freeAllowance);
    }
    return PickRefused(usedToday: day.used, freePerDay: freePicksPerDay);
  }
}
