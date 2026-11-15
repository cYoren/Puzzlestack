/// Seismic as a deduction board.
///
/// A cell's mask says which digits it can still hold. Placing a digit is the
/// whole propagation: the ripple rule removes it from the cells [digit] steps
/// away, and the region rule removes it from the rest of its region. Every
/// other rule in this file is a way of finding out that only one digit is left.
///
/// The rules are ordered by how hard the idea is, and the last is exact:
/// [SeismicForced] tries every digit in every open cell and searches for one
/// complete answer behind it. It only writes a cell when the search proves the
/// other digits impossible, which makes "one answer" and "finishable without a
/// guess" the same claim for this game.
library;

import '../../../../core/deduction.dart';
import 'seismic_puzzle.dart';

/// The bit for [digit] (1..9). Digits are 1-based; masks are bits, because a
/// cell's whole question is "which of these are still possible".
int seismicBit(int digit) => 1 << (digit - 1);

/// The digit of a single-bit mask.
int seismicDigit(int bit) => bit.bitLength;

int _popCount(int mask) {
  var count = 0;
  while (mask != 0) {
    mask &= mask - 1;
    count++;
  }
  return count;
}

class SeismicModel implements DeductionModel<SeismicModel> {
  SeismicModel({
    required this.puzzle,
    required this.masks,
    this.broken = false,
  });

  /// A fresh board: every cell allows 1..its region's size, then the printed
  /// numbers are applied with their full propagation.
  factory SeismicModel.fresh(SeismicPuzzle puzzle) {
    final model = SeismicModel(
      puzzle: puzzle,
      masks: [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          (1 << puzzle.regionSizeOf(cell)) - 1,
      ],
    );
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final clue = puzzle.given(cell);
      if (clue == kSeismicNoClue) continue;
      if (model.set(cell, clue) < 0) model.broken = true;
    }
    return model;
  }

  final SeismicPuzzle puzzle;

  /// Per cell, the digits it can still hold. A decided cell is a single bit.
  final List<int> masks;

  /// Set when the printed clues contradict each other. A rule reports it as a
  /// contradiction instead of pretending the board is still workable.
  bool broken;

  int get n => puzzle.n;

  int get cellCount => puzzle.cellCount;

  @override
  SeismicModel copy() =>
      SeismicModel(puzzle: puzzle, masks: [...masks], broken: broken);

  @override
  bool get isComplete => !broken && masks.every((mask) => _popCount(mask) == 1);

  /// The open cell with the fewest digits left, so a guess branches least.
  @override
  Choice? get choice {
    var best = -1;
    var bestCount = 99;
    for (var cell = 0; cell < masks.length; cell++) {
      final count = _popCount(masks[cell]);
      if (count <= 1 || count >= bestCount) continue;
      best = cell;
      bestCount = count;
    }
    if (best < 0) return null;
    return Choice(best, [
      for (var digit = 1; digit <= puzzle.maxDigit; digit++)
        if (masks[best] & seismicBit(digit) != 0) seismicBit(digit),
    ]);
  }

  @override
  SeismicModel assume(int slot, int value) {
    final next = copy();
    // Place it, do not just narrow the mask: a guess that does not propagate
    // makes the search enumerate boards the rules would have thrown out.
    if (next.set(slot, seismicDigit(value)) < 0) next.broken = true;
    return next;
  }

  /// The digit a decided cell holds, or 0 when it is still open.
  int digitAt(int cell) {
    final mask = masks[cell];
    return _popCount(mask) == 1 ? seismicDigit(mask) : 0;
  }

  /// 1 when this was news, 0 when it was already known, -1 on contradiction.
  ///
  /// Placing a digit is also the propagation step, so rule order cannot break
  /// the ripple rule: no caller can settle a cell without its neighbours
  /// hearing about it.
  int set(int cell, int digit) {
    final bit = seismicBit(digit);
    final mask = masks[cell];
    if (mask & bit == 0) return -1;

    // Propagate even when the cell is already down to this digit: a cell that
    // was narrowed to one digit by elimination has never had its digit sent to
    // its neighbours, and "already decided" is not the same as "already
    // propagated". Returning early here let two far-apart equal digits stand.
    masks[cell] = bit;
    var news = mask == bit ? 0 : 1;
    for (final other in puzzle.inRange(cell, digit)) {
      final changed = _remove(other, bit);
      if (changed < 0) return -1;
      news += changed;
    }
    for (final other in puzzle.cellsOfRegion(puzzle.regionOf(cell))) {
      if (other == cell) continue;
      final changed = _remove(other, bit);
      if (changed < 0) return -1;
      news += changed;
    }
    return news;
  }

  /// 1 when this ruled something out, 0 when it already was, -1 when the cell
  /// was already decided as that digit.
  int _remove(int cell, int bit) {
    final mask = masks[cell];
    if (mask & bit == 0) return 0;
    if (mask == bit) return -1;
    masks[cell] = mask & ~bit;
    return 1;
  }

  /// Removes a digit from a cell, for a rule that has proved it impossible.
  int eliminate(int cell, int digit) => _remove(cell, seismicBit(digit));

  /// The digits a cell can still hold, in order.
  List<int> candidates(int cell) => [
        for (var digit = 1; digit <= puzzle.maxDigit; digit++)
          if (masks[cell] & seismicBit(digit) != 0) digit,
      ];
}

/// A cell with one digit left takes it. This is where the ripple rule and the
/// region rule pay out, because [SeismicModel.set] propagates.
class SeismicSingles implements DeductionRule<SeismicModel> {
  const SeismicSingles();

  @override
  int get level => 1;

  @override
  String get name => 'a cell with one digit left';

  @override
  int apply(SeismicModel model) {
    if (model.broken) return -1;
    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      final mask = model.masks[cell];
      // No digit left is a contradiction, not an unfinished cell.
      if (mask == 0) return -1;
      if (_popCount(mask) != 1) continue;
      final settled = model.set(cell, seismicDigit(mask));
      if (settled < 0) return -1;
      news += settled;
    }
    return news;
  }
}

/// A digit that can only go in one cell of its region must go there. The
/// region's own set is 1..its size, every digit exactly once.
class SeismicRegionSingles implements DeductionRule<SeismicModel> {
  const SeismicRegionSingles();

  @override
  int get level => 1;

  @override
  String get name => 'one place left for this digit in its region';

  @override
  int apply(SeismicModel model) {
    if (model.broken) return -1;
    var news = 0;
    final puzzle = model.puzzle;
    for (var region = 0; region < puzzle.regionSizes.length; region++) {
      final cells = puzzle.cellsOfRegion(region);
      for (var digit = 1; digit <= puzzle.regionSizes[region]; digit++) {
        final bit = seismicBit(digit);
        int? only;
        var places = 0;
        for (final cell in cells) {
          if (model.masks[cell] & bit == 0) continue;
          places++;
          only = cell;
          if (places > 1) break;
        }
        if (places == 0) return -1;
        if (places > 1) continue;
        final settled = model.set(only!, digit);
        if (settled < 0) return -1;
        news += settled;
      }
    }
    return news;
  }
}

/// The result of counting the answers a set of masks allows.
class SeismicCount {
  const SeismicCount({
    required this.solutions,
    required this.truncated,
    required this.forced,
  });

  /// Answers found, capped at the limit asked for.
  final int solutions;

  /// True when the budget ran out. A truncated count proves nothing.
  final bool truncated;

  /// Per cell, the digit every answer found agrees on, or 0 when they differ.
  final List<int> forced;

  bool get isUnique => solutions == 1 && !truncated;
}

/// A complete search over whole answers, bounded by a node budget.
///
/// It is used three ways: as the uniqueness prover (`limit: 2`), as the hard
/// rule (only cells every answer agrees on are written), and by the tests that
/// have to state the game's own rule without trusting the generator.
class SeismicSearch {
  SeismicSearch({
    required this.puzzle,
    required List<int> masks,
    this.limit = 2,
    this.budget = 40000,
  }) : masks = List<int>.from(masks);

  final SeismicPuzzle puzzle;
  final List<int> masks;

  /// Stop after this many answers.
  final int limit;

  /// Nodes before giving up.
  final int budget;

  int _nodes = 0;
  int _solutions = 0;
  bool _truncated = false;
  late List<int> _seen;

  SeismicCount run() {
    _seen = List<int>.filled(puzzle.cellCount, 0);
    _search(SeismicModel(puzzle: puzzle, masks: masks));
    final forced = List<int>.filled(puzzle.cellCount, 0);
    if (!_truncated && _solutions > 0) {
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (_popCount(_seen[cell]) == 1) {
          forced[cell] = seismicDigit(_seen[cell]);
        }
      }
    }
    return SeismicCount(
      solutions: _solutions,
      truncated: _truncated,
      forced: forced,
    );
  }

  void _search(SeismicModel model) {
    if (_truncated || _solutions >= limit) return;
    if (_nodes++ > budget) {
      _truncated = true;
      return;
    }

    final outcome = deduce(model, seismicEasyRules);
    if (!outcome.consistent) return;
    if (model.isComplete) {
      _solutions++;
      for (var cell = 0; cell < model.cellCount; cell++) {
        _seen[cell] |= model.masks[cell];
      }
      return;
    }

    final choice = model.choice;
    if (choice == null) return;
    for (final value in choice.values) {
      _search(model.assume(choice.slot, value));
      if (_truncated || _solutions >= limit) return;
    }
  }
}

/// "Assume this digit and see": a contradiction a shorter search can see is
/// still a contradiction, so the digit goes.
///
/// It is one level harder than the singles because it asks a question about
/// the whole board instead of one cell.
class SeismicProbe implements DeductionRule<SeismicModel> {
  const SeismicProbe();

  @override
  int get level => 2;

  @override
  String get name => 'this digit leads to a dead board';

  @override
  int apply(SeismicModel model) {
    if (model.broken) return -1;
    var news = 0;
    var budget = 6000;
    for (var cell = 0; cell < model.cellCount; cell++) {
      final open = model.candidates(cell);
      if (open.length < 2) continue;
      for (final digit in open) {
        final seed = model.copy();
        if (seed.set(cell, digit) < 0) {
          // The cell could not take it in the first place, so it is gone.
          final changed = model.eliminate(cell, digit);
          if (changed < 0) return -1;
          news += changed;
          continue;
        }
        final count = SeismicSearch(
          puzzle: model.puzzle,
          masks: seed.masks,
          limit: 1,
          budget: budget,
        ).run();
        if (count.truncated) {
          // Not evidence either way, and the budget is spent.
          return news;
        }
        budget -= 400;
        if (count.solutions == 0) {
          final changed = model.eliminate(cell, digit);
          if (changed < 0) return -1;
          news += changed;
        }
        if (budget < 400) return news;
      }
    }
    return news;
  }
}

/// The exact rule: a digit is kept only when some complete answer still uses
/// it, and a cell is written only when every answer agrees.
///
/// This is the last rule for the same reason Boats' fleet search is: it is the
/// one idea that cannot be wrong about the answer, because it enumerates the
/// answers. A board that needs it is the hard tier.
class SeismicForced implements DeductionRule<SeismicModel> {
  const SeismicForced();

  @override
  int get level => 3;

  @override
  String get name => 'the only answer that fits';

  @override
  int apply(SeismicModel model) {
    if (model.broken) return -1;
    final count = SeismicSearch(
      puzzle: model.puzzle,
      masks: model.masks,
      limit: 4096,
      budget: 40000,
    ).run();
    if (count.truncated) return 0;
    if (count.solutions == 0) return -1;

    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      final digit = count.forced[cell];
      if (digit == 0) continue;
      if (_popCount(model.masks[cell]) == 1) continue;
      final settled = model.set(cell, digit);
      if (settled < 0) return -1;
      news += settled;
    }
    return news;
  }
}

/// What a player can do without thinking twice.
const List<DeductionRule<SeismicModel>> seismicEasyRules = [
  SeismicSingles(),
  SeismicRegionSingles(),
];

/// The generation ladder: a board ships only when these finish it, so every
/// dealt board is finishable without a guess. The exact rule is left out on
/// purpose — it is the uniqueness proof and the hard tier, not a way to make a
/// board look solvable when it is not.
const List<DeductionRule<SeismicModel>> seismicDeductionRules = [
  SeismicSingles(),
  SeismicRegionSingles(),
  SeismicProbe(),
];

/// Every rule, easiest idea first. The highest level a board needs is its
/// difficulty.
const List<DeductionRule<SeismicModel>> seismicRules = [
  SeismicSingles(),
  SeismicRegionSingles(),
  SeismicProbe(),
  SeismicForced(),
];
