/// Mathrax as a deduction board.
///
/// A cell's mask says which digits it can still hold. Two ideas do all the work
/// a player does with a pencil: a digit cannot repeat in its row or column, and
/// a corner clue rules out digits that have no partner across the corner. The
/// last rule is exact — [MathraxForced] searches for a complete answer behind
/// each candidate, so "one answer" and "finishable without a guess" are the same
/// claim for this game.
///
/// Masks are `int` bits and the largest board is 6x6, so the widest mask is six
/// bits: safe on every target, including the web build that truncates bitwise
/// integers to 32 bits.
library;

import '../../../../core/deduction.dart';
import 'mathrax_puzzle.dart';

/// The bit for [digit] (1..9).
int mathraxBit(int digit) => 1 << (digit - 1);

/// The digit of a single-bit mask.
int mathraxDigit(int mask) => mask.bitLength;

int _popCount(int mask) {
  var count = 0;
  while (mask != 0) {
    mask &= mask - 1;
    count++;
  }
  return count;
}

class MathraxModel implements DeductionModel<MathraxModel> {
  MathraxModel({
    required this.puzzle,
    required this.masks,
    this.broken = false,
  });

  /// A fresh board: every cell allows 1..N.
  factory MathraxModel.fresh(MathraxPuzzle puzzle) => MathraxModel(
        puzzle: puzzle,
        masks: List<int>.filled(
            puzzle.cellCount, (1 << puzzle.n) - 1),
      );

  final MathraxPuzzle puzzle;

  /// Per cell, the digits it can still hold. A single bit is a decided cell.
  final List<int> masks;

  bool broken;

  int get n => puzzle.n;

  int get cellCount => puzzle.cellCount;

  @override
  MathraxModel copy() =>
      MathraxModel(puzzle: puzzle, masks: List<int>.from(masks), broken: broken);

  @override
  bool get isComplete {
    if (broken) return false;
    for (final mask in masks) {
      if (_popCount(mask) != 1) return false;
    }
    // Decided and legal are two different questions, and the counter trusts
    // this one: a board can be complete and wrong.
    return puzzle.isSolution(values);
  }

  @override
  Choice? get choice {
    var best = -1;
    var bestCount = 99;
    for (var cell = 0; cell < cellCount; cell++) {
      final count = _popCount(masks[cell]);
      if (count < 2 || count >= bestCount) continue;
      best = cell;
      bestCount = count;
    }
    if (best < 0) return null;
    final values = <int>[];
    for (var digit = 1; digit <= n; digit++) {
      if (masks[best] & mathraxBit(digit) != 0) values.add(digit);
    }
    return Choice(best, values);
  }

  @override
  MathraxModel assume(int slot, int value) {
    final next = copy();
    if (next.set(slot, value) < 0) next.broken = true;
    return next;
  }

  /// The board as digits, with a decided cell's digit and 0 for an open cell.
  List<int> get values => [
        for (final mask in masks)
          _popCount(mask) == 1 ? mathraxDigit(mask) : kMathraxBlank,
      ];

  int digitAt(int cell) =>
      _popCount(masks[cell]) == 1 ? mathraxDigit(masks[cell]) : kMathraxBlank;

  List<int> candidates(int cell) => [
        for (var digit = 1; digit <= n; digit++)
          if (masks[cell] & mathraxBit(digit) != 0) digit,
      ];

  /// Writes [digit] in [cell] and propagates. -1 on a contradiction, otherwise
  /// the number of cells this settled.
  int set(int cell, int digit) {
    final bit = mathraxBit(digit);
    if (masks[cell] & bit == 0) {
      broken = true;
      return -1;
    }
    var news = 0;
    if (masks[cell] != bit) {
      masks[cell] = bit;
      news++;
    }
    final pushed = _propagate();
    if (pushed < 0) return -1;
    return news + pushed;
  }

  /// Removes [digits] from [cell]. Does not propagate; [set] does.
  int eliminate(int cell, int digits) {
    if (masks[cell] & digits == 0) return 0;
    final left = masks[cell] & ~digits;
    if (left == 0) {
      broken = true;
      return -1;
    }
    masks[cell] = left;
    return 1;
  }

  /// Every decided cell takes its digit away from the rest of its row and
  /// column, until nothing moves. This is the one place that propagation lives,
  /// so [MathraxPeers] and [set] cannot disagree about it.
  int _propagate() {
    var news = 0;
    var moved = true;
    while (moved) {
      moved = false;
      for (var cell = 0; cell < cellCount; cell++) {
        if (_popCount(masks[cell]) != 1) continue;
        final bit = masks[cell];
        final row = cell ~/ n;
        final col = cell % n;
        for (var i = 0; i < n; i++) {
          for (final peer in [row * n + i, i * n + col]) {
            if (peer == cell) continue;
            if (masks[peer] & bit == 0) continue;
            if (masks[peer] == bit) {
              broken = true;
              return -1;
            }
            final changed = eliminate(peer, bit);
            if (changed < 0) return -1;
            news += changed;
            moved = true;
          }
        }
      }
    }
    return news;
  }

}

/// A digit cannot repeat in its row or its column. Level 1: it is the first
/// thing anyone learns about a Latin square.
class MathraxPeers implements DeductionRule<MathraxModel> {
  const MathraxPeers();

  @override
  int get level => 1;

  @override
  String get name => 'a digit once in its row and column';

  @override
  int apply(MathraxModel model) {
    if (model.broken) return -1;
    final news = model._propagate();
    if (news < 0) return -1;
    return model.broken ? -1 : news;
  }
}

/// A corner clue rules out digits that have no partner across the corner.
///
/// Level 2: it needs the player to hold four cells in mind at once, which is
/// why Mathrax is a harder game than Sudoku with the same board.
class MathraxCorners implements DeductionRule<MathraxModel> {
  const MathraxCorners();

  @override
  int get level => 2;

  @override
  String get name => 'what the corner clue leaves';

  @override
  int apply(MathraxModel model) {
    if (model.broken) return -1;
    var news = 0;
    final n = model.n;
    for (var row = 0; row < n - 1; row++) {
      for (var col = 0; col < n - 1; col++) {
        final clue = model.puzzle.clueAt(row, col);
        if (clue == null) continue;
        // Two diagonals, each an independent pair under the same clue.
        final pairs = [
          [model.puzzle.cell(row, col), model.puzzle.cell(row + 1, col + 1)],
          [model.puzzle.cell(row, col + 1), model.puzzle.cell(row + 1, col)],
        ];
        for (final pair in pairs) {
          final a = pair[0];
          final b = pair[1];
          // For each cell: the digits that have *some* partner on the other
          // end. Asking `_compatible(mask, other)` with the arguments the other
          // way round is the bug this comment exists to prevent - it intersects
          // one cell's candidates with the other cell's.
          final keepA = _compatible(model, clue, model.masks[a], model.masks[b]);
          final keepB = _compatible(model, clue, model.masks[b], model.masks[a]);
          final cutA = model.masks[a] & ~keepA;
          final cutB = model.masks[b] & ~keepB;
          if (cutA != 0) {
            final changed = model.eliminate(a, cutA);
            if (changed < 0) return -1;
            news += changed;
          }
          if (cutB != 0) {
            final changed = model.eliminate(b, cutB);
            if (changed < 0) return -1;
            news += changed;
          }
        }
      }
    }
    return news;
  }

  /// Digits in [mask] that have at least one partner in [other] under [clue].
  int _compatible(
    MathraxModel model,
    MathraxClue clue,
    int mask,
    int other,
  ) {
    var out = 0;
    for (var mine = 1; mine <= model.n; mine++) {
      if (mask & mathraxBit(mine) == 0) continue;
      for (var theirs = 1; theirs <= model.n; theirs++) {
        if (other & mathraxBit(theirs) == 0) continue;
        if (MathraxPuzzle.pairHolds(mine, theirs, clue)) {
          out |= mathraxBit(mine);
          break;
        }
      }
    }
    return out;
  }
}

/// A digit with only one home left in its row or column. Level 2: same idea as
/// Sudoku's hidden single, and the same reward.
class MathraxHidden implements DeductionRule<MathraxModel> {
  const MathraxHidden();

  @override
  int get level => 2;

  @override
  String get name => 'the only home left in a row';

  @override
  int apply(MathraxModel model) {
    if (model.broken) return -1;
    var news = 0;
    final n = model.n;
    for (var line = 0; line < n; line++) {
      for (var digit = 1; digit <= n; digit++) {
        final bit = mathraxBit(digit);
        var rowHome = -1;
        var rowCount = 0;
        var colHome = -1;
        var colCount = 0;
        for (var i = 0; i < n; i++) {
          if (model.masks[line * n + i] & bit != 0) {
            rowHome = line * n + i;
            rowCount++;
          }
          if (model.masks[i * n + line] & bit != 0) {
            colHome = i * n + line;
            colCount++;
          }
        }
        if (rowCount == 0 || colCount == 0) return -1;
        if (rowCount == 1 && _popCount(model.masks[rowHome]) > 1) {
          final changed = model.set(rowHome, digit);
          if (changed < 0) return -1;
          news += changed;
        }
        if (colCount == 1 && _popCount(model.masks[colHome]) > 1) {
          final changed = model.set(colHome, digit);
          if (changed < 0) return -1;
          news += changed;
        }
      }
    }
    return news;
  }
}

/// The exact rule: a cell is only written when a search proves every other
/// digit impossible. Level 3, so a board finished by it is not "solvable by
/// logic" — and because it also counts, it is what makes the generator's
/// promise ("exactly one answer") true.
class MathraxForced implements DeductionRule<MathraxModel> {
  const MathraxForced({this.limit = 4096, this.budget = 40000});

  final int limit;
  final int budget;

  @override
  int get level => 3;

  @override
  String get name => 'searching every other digit';

  @override
  int apply(MathraxModel model) {
    if (model.broken) return -1;
    final found = MathraxSearch(
      puzzle: model.puzzle,
      masks: List<int>.from(model.masks),
      limit: limit,
      budget: budget,
    ).run();
    if (found.truncated) return 0;
    // Never write a cell the search did not finish proving: agreement among the
    // first few answers says nothing about the rest.
    if (!found.exhausted) return 0;
    if (found.solutions == 0) return -1;
    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      final digit = found.forced[cell];
      if (digit == 0) continue;
      if (_popCount(model.masks[cell]) == 1) continue;
      final changed = model.set(cell, digit);
      if (changed < 0) return -1;
      news += changed;
    }
    return news;
  }
}

/// Every rule, easiest first, ending with the exact one.
const List<DeductionRule<MathraxModel>> mathraxRules = [
  MathraxPeers(),
  MathraxCorners(),
  MathraxHidden(),
  MathraxForced(),
];

/// The rules a player can be expected to use, without the search.
const List<DeductionRule<MathraxModel>> mathraxPlayerRules = [
  MathraxPeers(),
  MathraxCorners(),
  MathraxHidden(),
];

/// What a search over [MathraxModel] found.
class MathraxCount {
  const MathraxCount({
    required this.solutions,
    required this.truncated,
    required this.exhausted,
    required this.first,
    required this.forced,
  });

  /// Answers found, capped at the limit asked for.
  final int solutions;

  /// True when the budget ran out. A truncated count proves nothing.
  final bool truncated;

  /// True when the search finished: no budget ran out and the limit was not
  /// reached. Only then is [forced] a proof.
  final bool exhausted;

  /// The first answer the search completed, per cell, or empty.
  final List<int> first;

  /// Per cell, the digit every answer agrees on, or 0. Empty unless
  /// [exhausted].
  final List<int> forced;

  bool get isUnique => solutions == 1 && !truncated;
}

/// The search behind [MathraxForced]: fill the board, counting answers.
class MathraxSearch {
  MathraxSearch({
    required this.puzzle,
    required this.masks,
    this.limit = 2,
    this.budget = 40000,
  });

  final MathraxPuzzle puzzle;
  final List<int> masks;
  final int limit;
  final int budget;

  int _nodes = 0;
  int _solutions = 0;
  List<int>? _first;
  late final List<int> _seen =
      List<int>.filled(puzzle.cellCount, (1 << puzzle.n) - 1);

  MathraxCount run() {
    _search(MathraxModel(puzzle: puzzle, masks: List<int>.from(masks)));
    // Stopping at the limit is not finishing: the answers beyond it were never
    // looked at, so nothing is proved about them.
    final exhausted = !_truncated && _solutions < limit;
    final forced = List<int>.filled(puzzle.cellCount, 0);
    if (exhausted && _solutions > 0) {
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        forced[cell] = _popCount(_seen[cell]) == 1
            ? mathraxDigit(_seen[cell])
            : 0;
      }
    }
    return MathraxCount(
      solutions: _solutions,
      truncated: _truncated,
      exhausted: exhausted,
      first: _first ?? const [],
      forced: forced,
    );
  }

  bool _truncated = false;

  int _search(MathraxModel model) {
    if (_truncated) return 0;
    if (_nodes++ > budget) {
      _truncated = true;
      return 0;
    }
    final outcome = deduce(model, mathraxPlayerRules);
    if (!outcome.consistent) return 0;
    if (model.isComplete) {
      final values = model.values;
      _first ??= values;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        _seen[cell] &= mathraxBit(values[cell]);
      }
      _solutions++;
      return 1;
    }
    final choice = model.choice;
    if (choice == null) return 0;
    var found = 0;
    for (final value in choice.values) {
      found += _search(model.assume(choice.slot, value));
      // The limit is global: `found` is this node's subtotal, so a deep branch
      // that already reached the limit must stop the whole walk, not just this
      // loop.
      if (_solutions >= limit || _truncated) break;
    }
    return found;
  }

}
