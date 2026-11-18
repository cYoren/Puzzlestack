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

  /// Asks to open [gameId] and records what the answer used.
  ///
  /// For a caller that opens the board straight away. A surface that asks the
  /// player something before the board exists — the size chooser, the rules
  /// page — uses [preview] and [commit] instead, so walking away costs nothing.
  Future<PickDecision> request(String gameId) async {
    final PickDecision decision = await preview(gameId);
    await commit(gameId, decision);
    return decision;
  }

  /// Asks whether [gameId] may open, and writes nothing down.
  ///
  /// The answer is only good until [commit]: nothing has been spent yet, so
  /// the same opening can be asked about again, and a player who dismisses the
  /// sheet in front of the board keeps their pick and keeps the first play.
  Future<PickDecision> preview(String gameId) async {
    if (!_ledger.hasOpened(gameId)) {
      return const PickAllowed(PickReason.firstPlay);
    }
    if (_hasPlus()) {
      return const PickAllowed(PickReason.plus);
    }
    final PickDay day = await _ledger.today();
    if (!day.exhausted) {
      return const PickAllowed(PickReason.freeAllowance);
    }
    return PickRefused(usedToday: day.used, freePerDay: freePicksPerDay);
  }

  /// Writes down what [decision] used, once the opening is actually happening.
  ///
  /// A refusal and a Plus opening write nothing. A first play is remembered so
  /// the second opening of that game is not free; a free pick is spent. Calling
  /// this twice for one opening would charge twice, so it is called at the one
  /// point where the board is about to be built.
  Future<void> commit(String gameId, PickDecision decision) async {
    if (decision is! PickAllowed) return;
    switch (decision.reason) {
      case PickReason.firstPlay:
        await _ledger.markOpened(gameId);
      case PickReason.freeAllowance:
        await _ledger.spend();
      case PickReason.plus:
        break;
    }
  }
}
