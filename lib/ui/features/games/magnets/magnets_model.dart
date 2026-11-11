import '../../../../core/deduction.dart';
import 'magnets_puzzle.dart';

/// Magnets as a deduction board: every cell knows which of `blank`, `+` and
/// `-` it can still be.
///
/// The rules are Tatham's, ported from `magnets.c` (`solve_state` and the
/// functions it calls). His flags map straight onto the masks here: a flag
/// saying "this cell is not `+`" is the `+` bit cleared.
const int kNeutral = 1;
const int kPositive = 2;
const int kNegative = 4;
const int kAllValues = kNeutral | kPositive | kNegative;

int partnerValue(int value) => switch (value) {
      kNeutral => kNeutral,
      kPositive => kNegative,
      _ => kPositive,
    };

class MagnetsModel implements DeductionModel<MagnetsModel> {
  MagnetsModel({required this.puzzle, required this.masks});

  factory MagnetsModel.fresh(MagnetsPuzzle puzzle) => MagnetsModel(
        puzzle: puzzle,
        masks: List<int>.filled(puzzle.cellCount, kAllValues),
      );

  final MagnetsPuzzle puzzle;

  /// One bitmask per cell: which values it can still take.
  final List<int> masks;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  @override
  MagnetsModel copy() => MagnetsModel(puzzle: puzzle, masks: [...masks]);

  @override
  bool get isComplete => masks.every((m) => m == kNeutral || m == kPositive || m == kNegative);

  @override
  Choice? get choice {
    for (var i = 0; i < masks.length; i++) {
      final mask = masks[i];
      if (mask == kNeutral || mask == kPositive || mask == kNegative) continue;
      return Choice(i, [
        if (mask & kNeutral != 0) kNeutral,
        if (mask & kPositive != 0) kPositive,
        if (mask & kNegative != 0) kNegative,
      ]);
    }
    return null;
  }

  @override
  MagnetsModel assume(int slot, int value) {
    final next = copy();
    next.masks[slot] = value;
    return next;
  }

  /// The value at a decided cell, or 0.
  int valueAt(int cell) {
    final mask = masks[cell];
    return mask == kNeutral || mask == kPositive || mask == kNegative ? mask : 0;
  }

  int _partnerOf(int cell) {
    final d = puzzle.dominoOf[cell];
    return puzzle.dominoA[d] == cell ? puzzle.dominoB[d] : puzzle.dominoA[d];
  }

  /// Removes [value] from a cell, and its partner value from the other half of
  /// the domino. 1 when that was news, -1 on contradiction.
  ///
  /// The domino half is done here rather than by a rule because it has to happen
  /// the moment a cell learns anything, exactly as Tatham's `solve_set` does.
  /// Left to a rule that runs later in the round, a line rule could act on a
  /// half-decided domino and draw a wrong conclusion from it.
  int unset(int cell, int value) {
    final mask = masks[cell];
    if (mask & value == 0) return 0;
    if (mask == value) return -1;
    masks[cell] = mask & ~value;

    final other = _partnerOf(cell);
    final gone = partnerValue(value);
    final otherMask = masks[other];
    if (otherMask & gone != 0) {
      if (otherMask == gone) return -1;
      masks[other] = otherMask & ~gone;
    }
    return 1;
  }

  /// Settles a cell on [value], and the other half of the domino on its partner
  /// value. 1 when that was news, -1 on contradiction.
  int set(int cell, int value) {
    final mask = masks[cell];
    if (mask == value) return 0;
    if (mask & value == 0) return -1;
    masks[cell] = value;

    final other = _partnerOf(cell);
    final want = partnerValue(value);
    final otherMask = masks[other];
    if (otherMask == want) return 1;
    if (otherMask & want == 0) return -1;
    masks[other] = want;
    return 1;
  }

  /// True when [cell] is the first half of a domino that lies along this line,
  /// so its partner is the next cell in the same line.
  bool inLineDomino(int cell, {required bool row}) {
    if (valueAt(cell) != 0) return false;
    if (puzzle.dominoA[puzzle.dominoOf[cell]] != cell) return false;
    final atEnd =
        row ? cell % cols == cols - 1 : cell ~/ cols == rows - 1;
    if (atEnd) return false;
    final step = row ? 1 : cols;
    return puzzle.dominoOf[cell + step] == puzzle.dominoOf[cell];
  }

  /// True when [cell] is the second half of a domino lying along this line, so
  /// it shares its slot with the cell before it.
  bool inLineDominoSecond(int cell, {required bool row}) {
    if (puzzle.dominoB[puzzle.dominoOf[cell]] != cell) return false;
    final atStart =
        row ? cell % cols == 0 : cell ~/ cols == 0;
    if (atStart) return false;
    final step = row ? 1 : cols;
    return puzzle.dominoOf[cell - step] == puzzle.dominoOf[cell];
  }

  /// The cells of a row (`row: true`) or a column, in order.
  List<int> line({required bool row, required int index}) => [
        for (var k = 0; k < (row ? cols : rows); k++)
          row ? index * cols + k : k * cols + index,
      ];

  /// How many of each value the line must hold.
  Map<int, int> targets({required bool row, required int index}) {
    final plus = row ? puzzle.rowPlus[index] : puzzle.colPlus[index];
    final minus = row ? puzzle.rowMinus[index] : puzzle.colMinus[index];
    final length = row ? cols : rows;
    return {kPositive: plus, kNegative: minus, kNeutral: length - plus - minus};
  }
}

/// A line that already holds its quota of a value cannot hold more of it, and a
/// line that needs every remaining cell for a value must take them all.
class MagnetsCounts implements DeductionRule<MagnetsModel> {
  const MagnetsCounts();

  @override
  int get level => 1;

  @override
  String get name => 'row and column counts';

  @override
  int apply(MagnetsModel model) {
    var news = 0;
    for (final row in [true, false]) {
      final count = row ? model.rows : model.cols;
      for (var index = 0; index < count; index++) {
        final n = _applyLine(model, row: row, index: index);
        if (n < 0) return -1;
        news += n;
      }
    }
    return news;
  }

  int _applyLine(MagnetsModel model, {required bool row, required int index}) {
    final cells = model.line(row: row, index: index);
    final targets = model.targets(row: row, index: index);

    final settled = {kNeutral: 0, kPositive: 0, kNegative: 0};
    final open = {kNeutral: 0, kPositive: 0, kNegative: 0};
    for (final cell in cells) {
      final mask = model.masks[cell];
      if (mask == kNeutral || mask == kPositive || mask == kNegative) {
        settled[mask] = settled[mask]! + 1;
      } else {
        for (final value in [kNeutral, kPositive, kNegative]) {
          if (mask & value != 0) open[value] = open[value]! + 1;
        }
      }
    }

    var news = 0;
    for (final value in [kNeutral, kPositive, kNegative]) {
      final target = targets[value]!;
      final have = settled[value]!;
      if (have > target) return -1;
      if (have == target) {
        for (final cell in cells) {
          if (model.valueAt(cell) != 0) continue;
          final n = model.unset(cell, value);
          if (n < 0) return -1;
          news += n;
        }
      } else if (target - have == open[value]) {
        for (final cell in cells) {
          if (model.masks[cell] & value == 0) continue;
          final n = model.set(cell, value);
          if (n < 0) return -1;
          news += n;
        }
      }
    }
    return news;
  }
}

/// With no blanks left in a line, the `+` and `-` counts differ by at most one,
/// and a single odd run of undecided cells must start with the majority value.
class MagnetsOddLength implements DeductionRule<MagnetsModel> {
  const MagnetsOddLength();

  @override
  int get level => 2;

  @override
  String get name => 'odd-length run';

  @override
  int apply(MagnetsModel model) {
    var news = 0;
    for (final row in [true, false]) {
      final count = row ? model.rows : model.cols;
      for (var index = 0; index < count; index++) {
        final n = _applyLine(model, row: row, index: index);
        if (n < 0) return -1;
        news += n;
      }
    }
    return news;
  }

  int _applyLine(MagnetsModel model, {required bool row, required int index}) {
    final cells = model.line(row: row, index: index);
    final targets = model.targets(row: row, index: index);

    var neutralSettled = 0;
    var plusSettled = 0;
    var minusSettled = 0;
    for (final cell in cells) {
      switch (model.valueAt(cell)) {
        case kNeutral:
          neutralSettled++;
        case kPositive:
          plusSettled++;
        case kNegative:
          minusSettled++;
      }
    }
    if (neutralSettled != targets[kNeutral]) return 0;

    final plusLeft = targets[kPositive]! - plusSettled;
    final minusLeft = targets[kNegative]! - minusSettled;
    final int extra;
    if (plusLeft == minusLeft + 1) {
      extra = kPositive;
    } else if (minusLeft == plusLeft + 1) {
      extra = kNegative;
    } else {
      return 0;
    }

    int? firstOdd;
    int? start;
    var length = 0;
    var inRun = false;

    void closeRun() {
      if (inRun && length.isOdd) {
        if (firstOdd != null) {
          firstOdd = -1; // two odd runs: the rule says nothing
        } else {
          firstOdd = start;
        }
      }
      inRun = false;
    }

    for (final cell in cells) {
      if (model.valueAt(cell) != 0) {
        closeRun();
      } else if (inRun) {
        length++;
      } else {
        start = cell;
        length = 1;
        inRun = true;
      }
    }
    closeRun();

    final odd = firstOdd;
    if (odd == null || odd == -1) return 0;
    return model.set(odd, extra);
  }
}

/// A domino lying inside the line whose halves can only be poles must be a
/// magnet, so it spends one `+` and one `-` before anything else does.
class MagnetsAdvancedFull implements DeductionRule<MagnetsModel> {
  const MagnetsAdvancedFull();

  @override
  int get level => 3;

  @override
  String get name => 'polarised domino fills the line';

  @override
  int apply(MagnetsModel model) {
    var news = 0;
    for (final row in [true, false]) {
      final count = row ? model.rows : model.cols;
      for (var index = 0; index < count; index++) {
        final n = _applyLine(model, row: row, index: index);
        if (n < 0) return -1;
        news += n;
      }
    }
    return news;
  }

  int _applyLine(MagnetsModel model, {required bool row, required int index}) {
    final cells = model.line(row: row, index: index);
    final targets = model.targets(row: row, index: index);
    final step = row ? 1 : model.cols;

    var plusSettled = 0;
    var minusSettled = 0;
    for (final cell in cells) {
      if (model.valueAt(cell) == kPositive) plusSettled++;
      if (model.valueAt(cell) == kNegative) minusSettled++;
    }
    if (plusSettled == targets[kPositive] && minusSettled == targets[kNegative]) {
      return 0;
    }

    final marked = <int>{};
    for (final cell in cells) {
      if (!model.inLineDomino(cell, row: row)) continue;
      final other = cell + step;
      // Both halves must be poles: no room for a blank.
      if (model.masks[cell] != (kPositive | kNegative)) continue;
      if (model.masks[other] != (kPositive | kNegative)) continue;
      marked.add(cell);
      marked.add(other);
    }
    if (marked.isEmpty) return 0;

    final filled = marked.length ~/ 2;
    plusSettled += filled;
    minusSettled += filled;

    final clearPlus = plusSettled == targets[kPositive];
    final clearMinus = minusSettled == targets[kNegative];
    if (!clearPlus && !clearMinus) return 0;

    var news = 0;
    for (final cell in cells) {
      if (model.valueAt(cell) != 0 || marked.contains(cell)) continue;
      if (clearPlus) {
        final n = model.unset(cell, kPositive);
        if (n < 0) return -1;
        news += n;
      }
      if (clearMinus) {
        final n = model.unset(cell, kNegative);
        if (n < 0) return -1;
        news += n;
      }
    }
    return news;
  }
}

/// With one blank still to place in a line, no domino lying inside that line can
/// be the blank.
class MagnetsNonNeutral implements DeductionRule<MagnetsModel> {
  const MagnetsNonNeutral();

  @override
  int get level => 3;

  @override
  String get name => 'last blank is not in a domino';

  @override
  int apply(MagnetsModel model) {
    var news = 0;
    for (final row in [true, false]) {
      final count = row ? model.rows : model.cols;
      for (var index = 0; index < count; index++) {
        final cells = model.line(row: row, index: index);
        final targets = model.targets(row: row, index: index);
        final blanks = cells.where((c) => model.valueAt(c) == kNeutral).length;
        if (targets[kNeutral] != blanks + 1) continue;

        for (final cell in cells) {
          if (!model.inLineDomino(cell, row: row)) continue;
          final n = model.unset(cell, kNeutral);
          if (n < 0) return -1;
          news += n;
        }
      }
    }
    return news;
  }
}

/// Every empty domino in a line needs a pole, so no cell of one can be blank.
class MagnetsCountDominoes implements DeductionRule<MagnetsModel> {
  const MagnetsCountDominoes();

  @override
  int get level => 3;

  @override
  String get name => 'empty dominoes need poles';

  @override
  int apply(MagnetsModel model) {
    var news = 0;
    for (final row in [true, false]) {
      final count = row ? model.rows : model.cols;
      for (var index = 0; index < count; index++) {
        final n = _applyLine(model, row: row, index: index);
        if (n < 0) return -1;
        news += n;
      }
    }
    return news;
  }

  int _applyLine(MagnetsModel model, {required bool row, required int index}) {
    final cells = model.line(row: row, index: index);
    final targets = model.targets(row: row, index: index);

    var plusSettled = 0;
    var minusSettled = 0;
    var emptyDominoes = 0;
    for (final cell in cells) {
      if (model.valueAt(cell) == kPositive) plusSettled++;
      if (model.valueAt(cell) == kNegative) minusSettled++;
      // A slot is one cell, or one domino lying along the line: either way it
      // can hold at most one pole of the colour we are short of.
      if (!model.inLineDominoSecond(cell, row: row)) emptyDominoes++;
    }

    final needsAllPlus = targets[kPositive]! - plusSettled == emptyDominoes;
    final needsAllMinus = targets[kNegative]! - minusSettled == emptyDominoes;
    if (!needsAllPlus && !needsAllMinus) return 0;

    var news = 0;
    for (final cell in cells) {
      if (model.valueAt(cell) != 0) continue;
      final n = model.unset(cell, kNeutral);
      if (n < 0) return -1;
      news += n;
    }
    return news;
  }
}

/// The rules, easiest idea first. The level a board needs is its difficulty.
const List<DeductionRule<MagnetsModel>> magnetsRules = [
  MagnetsCounts(),
  MagnetsOddLength(),
  MagnetsAdvancedFull(),
  MagnetsNonNeutral(),
  MagnetsCountDominoes(),
];
