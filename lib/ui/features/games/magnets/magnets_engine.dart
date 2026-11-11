import 'dart:math';

import '../../../../core/deduction.dart';
import 'magnets_model.dart';
import 'magnets_puzzle.dart';

export 'magnets_puzzle.dart';

class MagnetsEngine {
  const MagnetsEngine();

  /// A board with no uniqueness or level gate. The rule tests need boards that
  /// are not already filtered, so they can check the rules against a board the
  /// generator would have thrown away.
  MagnetsPuzzle generateUngated(MagnetsDifficulty difficulty, Random rng) {
    final rows = difficulty.rows;
    final cols = difficulty.cols;
    while (true) {
      final partner = _randomMatching(rows, cols, rng);
      if (partner == null) continue;
      final dominoA = <int>[];
      final dominoB = <int>[];
      final dominoOf = List<int>.filled(rows * cols, -1);
      for (var cell = 0; cell < partner.length; cell++) {
        final other = partner[cell];
        if (other < cell) continue;
        dominoOf[cell] = dominoA.length;
        dominoOf[other] = dominoA.length;
        dominoA.add(cell);
        dominoB.add(other);
      }
      final solution = _randomPoles(dominoA, dominoB, dominoOf, rows, cols, rng);
      if (solution == null || solution.every((s) => s == 0)) continue;
      return _build(
        rows: rows,
        cols: cols,
        dominoA: dominoA,
        dominoB: dominoB,
        dominoOf: dominoOf,
        solution: solution,
      );
    }
  }

  // --------------------------------------------------------------- generator

  MagnetsPuzzle generate(MagnetsDifficulty difficulty, {Random? random}) {
    final rng = random ?? Random();
    final rows = difficulty.rows;
    final cols = difficulty.cols;

    for (var attempt = 0; attempt < 4000; attempt++) {
      final partner = _randomMatching(rows, cols, rng);
      if (partner == null) continue;

      final dominoA = <int>[];
      final dominoB = <int>[];
      final dominoOf = List<int>.filled(rows * cols, -1);
      for (var cell = 0; cell < partner.length; cell++) {
        final other = partner[cell];
        if (other < cell) continue;
        dominoOf[cell] = dominoA.length;
        dominoOf[other] = dominoA.length;
        dominoA.add(cell);
        dominoB.add(other);
      }

      final solution = _randomPoles(dominoA, dominoB, dominoOf, rows, cols, rng);
      if (solution == null) continue;
      // An all-blank board is a legal assignment and a useless puzzle.
      if (solution.every((s) => s == 0)) continue;

      final puzzle = _build(
        rows: rows,
        cols: cols,
        dominoA: dominoA,
        dominoB: dominoB,
        dominoOf: dominoOf,
        solution: solution,
      );
      final rating = rate(MagnetsModel.fresh(puzzle), magnetsRules);
      if (rating.verdict != PuzzleVerdict.solved) continue;
      if (rating.level < difficulty.minLevel) continue;
      return puzzle;
    }
    throw StateError('could not build a unique $rows x $cols Magnets board');
  }

  MagnetsPuzzle _build({
    required int rows,
    required int cols,
    required List<int> dominoA,
    required List<int> dominoB,
    required List<int> dominoOf,
    required List<int> solution,
  }) {
    final rowPlus = List<int>.filled(rows, 0);
    final rowMinus = List<int>.filled(rows, 0);
    final colPlus = List<int>.filled(cols, 0);
    final colMinus = List<int>.filled(cols, 0);

    for (var d = 0; d < dominoA.length; d++) {
      final state = solution[d];
      if (state == 0) continue;
      final plusCell = state == 1 ? dominoA[d] : dominoB[d];
      final minusCell = state == 1 ? dominoB[d] : dominoA[d];
      rowPlus[plusCell ~/ cols]++;
      colPlus[plusCell % cols]++;
      rowMinus[minusCell ~/ cols]++;
      colMinus[minusCell % cols]++;
    }

    return MagnetsPuzzle(
      rows: rows,
      cols: cols,
      dominoA: dominoA,
      dominoB: dominoB,
      dominoOf: dominoOf,
      solution: solution,
      rowPlus: rowPlus,
      rowMinus: rowMinus,
      colPlus: colPlus,
      colMinus: colMinus,
    );
  }

  /// A random perfect matching of the grid, or null when the walk cornered
  /// itself.
  List<int>? _randomMatching(int rows, int cols, Random rng) {
    final partner = List<int>.filled(rows * cols, -1);

    bool fill() {
      var start = -1;
      for (var i = 0; i < partner.length; i++) {
        if (partner[i] == -1) {
          start = i;
          break;
        }
      }
      if (start == -1) return true;

      final row = start ~/ cols;
      final col = start % cols;
      final options = <int>[
        if (col + 1 < cols && partner[start + 1] == -1) start + 1,
        if (row + 1 < rows && partner[start + cols] == -1) start + cols,
      ]..shuffle(rng);

      for (final other in options) {
        partner[start] = other;
        partner[other] = start;
        if (fill()) return true;
        partner[start] = -1;
        partner[other] = -1;
      }
      return false;
    }

    return fill() ? partner : null;
  }

  /// Choose a pole (or blank) for every domino without ever putting two equal
  /// poles side by side.
  List<int>? _randomPoles(
    List<int> dominoA,
    List<int> dominoB,
    List<int> dominoOf,
    int rows,
    int cols,
    Random rng,
  ) {
    final poles = List<int>.filled(rows * cols, 0); // 0 blank, 1 plus, 2 minus
    final states = List<int>.filled(dominoA.length, 0);

    bool place(int d) {
      if (d == dominoA.length) return true;
      final options = [0, 1, 2]..shuffle(rng);
      for (final state in options) {
        if (state == 0) {
          states[d] = 0;
          if (place(d + 1)) return true;
          continue;
        }
        final plus = state == 1 ? dominoA[d] : dominoB[d];
        final minus = state == 1 ? dominoB[d] : dominoA[d];
        poles[plus] = 1;
        poles[minus] = 2;
        states[d] = state;
        if (_polesAgree(poles, plus, minus, rows, cols) && place(d + 1)) {
          return true;
        }
        poles[plus] = 0;
        poles[minus] = 0;
        states[d] = 0;
      }
      return false;
    }

    return place(0) ? states : null;
  }

  bool _polesAgree(List<int> poles, int a, int b, int rows, int cols) {
    for (final cell in [a, b]) {
      final pole = poles[cell];
      if (pole == 0) continue;
      final row = cell ~/ cols;
      final col = cell % cols;
      for (final other in [
        if (row > 0) cell - cols,
        if (row + 1 < rows) cell + cols,
        if (col > 0) cell - 1,
        if (col + 1 < cols) cell + 1,
      ]) {
        if (poles[other] == pole) return false;
      }
    }
    return true;
  }

  // ------------------------------------------------------------------ solver

  /// How many completions the clues allow, capped at [limit].
  int countSolutions(MagnetsPuzzle puzzle, {int limit = 2}) =>
      countSolutionsFrom(puzzle, List<int>.filled(puzzle.dominoCount, -1),
          limit: limit);

  /// Count completions of a partially filled board. `given[d]` is -1 for a
  /// domino the player has not decided, and 0/1/2 for a decided one.
  int countSolutionsFrom(
    MagnetsPuzzle puzzle,
    List<int> given, {
    int limit = 2,
  }) {
    final rows = puzzle.rows;
    final cols = puzzle.cols;
    final dominoA = puzzle.dominoA;
    final dominoB = puzzle.dominoB;
    final count = dominoA.length;

    final poles = List<int>.filled(rows * cols, 0);
    final plusRow = List<int>.filled(rows, 0);
    final minusRow = List<int>.filled(rows, 0);
    final plusCol = List<int>.filled(cols, 0);
    final minusCol = List<int>.filled(cols, 0);
    // Cells still undecided per row and per column, for the "can we still get
    // there" bound.
    final freeRow = List<int>.filled(rows, cols);
    final freeCol = List<int>.filled(cols, rows);

    var found = 0;

    void decide(int d) {
      if (found >= limit) return;
      if (d == count) {
        found++;
        return;
      }

      final a = dominoA[d];
      final b = dominoB[d];
      final aRow = a ~/ cols;
      final aCol = a % cols;
      final bRow = b ~/ cols;
      final bCol = b % cols;

      freeRow[aRow]--;
      freeRow[bRow]--;
      freeCol[aCol]--;
      freeCol[bCol]--;

      final allowed = given[d] == -1 ? const [0, 1, 2] : [given[d]];
      for (final state in allowed) {
        if (state == 0) {
          poles[a] = 0;
          poles[b] = 0;
        } else {
          final plus = state == 1 ? a : b;
          final minus = state == 1 ? b : a;
          poles[plus] = 1;
          poles[minus] = 2;
          plusRow[plus ~/ cols]++;
          plusCol[plus % cols]++;
          minusRow[minus ~/ cols]++;
          minusCol[minus % cols]++;
        }

        if (_fits(puzzle, poles, plusRow, minusRow, plusCol, minusCol, freeRow,
            freeCol, a, b)) {
          decide(d + 1);
        }

        if (state != 0) {
          final plus = state == 1 ? a : b;
          final minus = state == 1 ? b : a;
          plusRow[plus ~/ cols]--;
          plusCol[plus % cols]--;
          minusRow[minus ~/ cols]--;
          minusCol[minus % cols]--;
        }
        poles[a] = 0;
        poles[b] = 0;
        if (found >= limit) break;
      }

      freeRow[aRow]++;
      freeRow[bRow]++;
      freeCol[aCol]++;
      freeCol[bCol]++;
    }

    decide(0);
    return found;
  }

  /// The first cell the rules can prove that the player has wrong, with the
  /// value they should have. Null when the player has nothing wrong yet.
  ///
  /// This runs the real rules from the clues, so the cell it names is one the
  /// player could have worked out, not a peek at the stored answer.
  ({int cell, int value})? hint(MagnetsPuzzle puzzle, List<int> states) {
    final model = MagnetsModel.fresh(puzzle);
    for (final rule in magnetsRules) {
      final before = [...model.masks];
      if (rule.apply(model) < 0) return null;
      for (var cell = 0; cell < model.masks.length; cell++) {
        if (before[cell] == model.masks[cell]) continue;
        final value = model.valueAt(cell);
        if (value == 0) continue;
        if (poleAt(puzzle, states, cell) == value) continue;
        return (cell: cell, value: value);
      }
    }
    return null;
  }

  /// The rule level a board needs, for the difficulty table and the tests.
  int? levelOf(MagnetsPuzzle puzzle) =>
      solvingLevel(MagnetsModel.fresh(puzzle), magnetsRules);

  /// Solutions the clues allow, counted by the deduction harness.
  int harnessSolutions(MagnetsPuzzle puzzle, {int limit = 2}) =>
      rate(MagnetsModel.fresh(puzzle), magnetsRules, limit: limit).solutions;

  // ------------------------------------------------------------------- state

  bool isAdjacent(int a, int b, int cols) {
    final ra = a ~/ cols;
    final ca = a % cols;
    final rb = b ~/ cols;
    final cb = b % cols;
    return (ra == rb && (ca - cb).abs() == 1) ||
        (ca == cb && (ra - rb).abs() == 1);
  }

  /// The cell's pole as a mask value: [kNeutral], [kPositive] or [kNegative].
  int poleAt(MagnetsPuzzle puzzle, List<int> states, int cell) {
    final d = puzzle.dominoOf[cell];
    final state = states[d];
    final isFirst = puzzle.dominoA[d] == cell;
    if (state == 0) return kNeutral;
    if (state == 1) return isFirst ? kPositive : kNegative;
    return isFirst ? kNegative : kPositive;
  }

  bool isSolved(MagnetsPuzzle puzzle, List<int> states) {
    final rows = puzzle.rows;
    final cols = puzzle.cols;
    final plusRow = List<int>.filled(rows, 0);
    final minusRow = List<int>.filled(rows, 0);
    final plusCol = List<int>.filled(cols, 0);
    final minusCol = List<int>.filled(cols, 0);

    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final pole = poleAt(puzzle, states, cell);
      if (pole == kNeutral) continue;
      final row = cell ~/ cols;
      final col = cell % cols;
      if (pole == kPositive) {
        plusRow[row]++;
        plusCol[col]++;
      } else {
        minusRow[row]++;
        minusCol[col]++;
      }
      for (final other in [
        if (row > 0) cell - cols,
        if (row + 1 < rows) cell + cols,
        if (col > 0) cell - 1,
        if (col + 1 < cols) cell + 1,
      ]) {
        if (poleAt(puzzle, states, other) == pole) return false;
      }
    }

    for (var r = 0; r < rows; r++) {
      if (plusRow[r] != puzzle.rowPlus[r]) return false;
      if (minusRow[r] != puzzle.rowMinus[r]) return false;
    }
    for (var c = 0; c < cols; c++) {
      if (plusCol[c] != puzzle.colPlus[c]) return false;
      if (minusCol[c] != puzzle.colMinus[c]) return false;
    }
    return true;
  }
  bool _fits(
    MagnetsPuzzle puzzle,
    List<int> poles,
    List<int> plusRow,
    List<int> minusRow,
    List<int> plusCol,
    List<int> minusCol,
    List<int> freeRow,
    List<int> freeCol,
    int a,
    int b,
  ) {
    final rows = puzzle.rows;
    final cols = puzzle.cols;
    final dominoOf = puzzle.dominoOf;
    final placed = dominoOf[a];

    for (var r = 0; r < rows; r++) {
      if (plusRow[r] > puzzle.rowPlus[r]) return false;
      if (minusRow[r] > puzzle.rowMinus[r]) return false;
      if (plusRow[r] + freeRow[r] < puzzle.rowPlus[r]) return false;
      if (minusRow[r] + freeRow[r] < puzzle.rowMinus[r]) return false;
      if (plusRow[r] + minusRow[r] + freeRow[r] <
          puzzle.rowPlus[r] + puzzle.rowMinus[r]) {
        return false;
      }
    }
    for (var c = 0; c < cols; c++) {
      if (plusCol[c] > puzzle.colPlus[c]) return false;
      if (minusCol[c] > puzzle.colMinus[c]) return false;
      if (plusCol[c] + freeCol[c] < puzzle.colPlus[c]) return false;
      if (minusCol[c] + freeCol[c] < puzzle.colMinus[c]) return false;
      if (plusCol[c] + minusCol[c] + freeCol[c] <
          puzzle.colPlus[c] + puzzle.colMinus[c]) {
        return false;
      }
    }

    // Only the two cells just set can create a new clash.
    for (final cell in [a, b]) {
      final pole = poles[cell];
      if (pole == 0) continue;
      final row = cell ~/ cols;
      final col = cell % cols;
      for (final other in [
        if (row > 0) cell - cols,
        if (row + 1 < rows) cell + cols,
        if (col > 0) cell - 1,
        if (col + 1 < cols) cell + 1,
      ]) {
        if (dominoOf[other] > placed) continue;
        if (poles[other] == pole) return false;
      }
    }
    return true;
  }
}
