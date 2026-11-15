import 'dart:math';

import '../../../../core/deduction.dart';
import 'boats_model.dart';
import 'boats_puzzle.dart';

export 'boats_puzzle.dart';

/// Boats: find the fleet.
///
/// The generator makes a legal fleet first and reads the row and column counts
/// off it, then hands those clues to the deduction harness. A board ships only
/// when exactly one fleet fits and the rules can reach it, so the numbers on the
/// grid are always enough and never merely suggestive.
class BoatsEngine {
  const BoatsEngine();

  // --------------------------------------------------------------- generator

  /// One board, or a throw.
  ///
  /// Retrying is the whole design: most random fleets do not produce clues that
  /// pin themselves down, so the loop throws the board away instead of adding
  /// clues until it looks fair.
  BoatsPuzzle generate(BoatsSize size, {Random? random, int attempts = 400}) {
    final rng = random ?? Random();
    for (var attempt = 0; attempt < attempts; attempt++) {
      final solution = _randomFleet(size, rng);
      if (solution == null) continue;
      final puzzle = _fromSolution(size, solution);
      final rating = rate(BoatsModel.fresh(puzzle), boatsRules);
      if (rating.verdict != PuzzleVerdict.solved) continue;
      return puzzle;
    }
    throw StateError(
      'could not build a unique ${size.rows}x${size.cols} Boats board in '
      '$attempts attempts',
    );
  }

  /// A legal fleet with no uniqueness gate, for testing the rules themselves.
  BoatsPuzzle generateUngated(BoatsSize size, Random rng) {
    while (true) {
      final solution = _randomFleet(size, rng);
      if (solution == null) continue;
      return _fromSolution(size, solution);
    }
  }

  /// Counts the fleets that fit a set of clues.
  ///
  /// Used by the tests to state the game's own rule: the board a player gets has
  /// exactly one answer, and a board with a clue removed has more.
  BoatsCount count(BoatsPuzzle puzzle, {List<int>? known, int limit = 2}) =>
      BoatsFleetSearch(
        rows: puzzle.rows,
        cols: puzzle.cols,
        rowCounts: puzzle.rowCounts,
        colCounts: puzzle.colCounts,
        fleet: puzzle.fleet,
        known: known ?? List<int>.filled(puzzle.cellCount, kKnownAny),
        limit: limit,
        budget: 2000000,
      ).run();

  BoatsPuzzle _fromSolution(BoatsSize size, List<int> solution) {
    final rowCounts = List<int>.filled(size.rows, 0);
    final colCounts = List<int>.filled(size.cols, 0);
    for (var cell = 0; cell < solution.length; cell++) {
      if (solution[cell] != kBoatShip) continue;
      rowCounts[cell ~/ size.cols]++;
      colCounts[cell % size.cols]++;
    }
    return BoatsPuzzle(
      size: size,
      rowCounts: rowCounts,
      colCounts: colCounts,
      fleet: size.fleet,
      solution: solution,
    );
  }

  /// Places the fleet at random, respecting every rule.
  ///
  /// Backtracking rather than blind retries: a short boat has few free cells by
  /// the time the long ones are down, and a version that restarted from scratch
  /// spent nearly all its time on the last boat.
  List<int>? _randomFleet(BoatsSize size, Random rng) {
    final rows = size.rows;
    final cols = size.cols;
    final grid = List<int>.filled(rows * cols, kBoatWater);

    bool touches(int row, int col) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final r = row + dr;
          final c = col + dc;
          if (r < 0 || r >= rows || c < 0 || c >= cols) continue;
          if (grid[r * cols + c] == kBoatShip) return true;
        }
      }
      return false;
    }

    bool free(int row, int col, int length, bool horizontal) {
      for (var step = 0; step < length; step++) {
        final r = horizontal ? row : row + step;
        final c = horizontal ? col + step : col;
        if (r >= rows || c >= cols) return false;
        if (grid[r * cols + c] != kBoatWater) return false;
      }
      for (var step = 0; step < length; step++) {
        final r = horizontal ? row : row + step;
        final c = horizontal ? col + step : col;
        if (touches(r, c)) return false;
      }
      return true;
    }

    bool place(int index) {
      if (index == size.fleet.length) return true;
      final length = size.fleet[index];
      final options = <({int row, int col, bool horizontal})>[];
      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < cols; col++) {
          for (final horizontal in const [true, false]) {
            if (length == 1 && !horizontal) continue;
            if (free(row, col, length, horizontal)) {
              options.add((row: row, col: col, horizontal: horizontal));
            }
          }
        }
      }
      options.shuffle(rng);
      for (final option in options) {
        for (var step = 0; step < length; step++) {
          final r = option.horizontal ? option.row : option.row + step;
          final c = option.horizontal ? option.col + step : option.col;
          grid[r * cols + c] = kBoatShip;
        }
        if (place(index + 1)) return true;
        for (var step = 0; step < length; step++) {
          final r = option.horizontal ? option.row : option.row + step;
          final c = option.horizontal ? option.col + step : option.col;
          grid[r * cols + c] = kBoatWater;
        }
      }
      return false;
    }

    if (!place(0)) return null;

    // Every boat cell needs water around it for the corner rule to be provable
    // from the counts; a fleet packed into a corner is legal but usually not
    // uniquely solvable, so it is left to the caller's retry.
    return grid;
  }

  // ------------------------------------------------------------------- rules

  /// True when the player's marks are a legal fleet.
  bool isSolved(BoatsPuzzle puzzle, List<int> marks) =>
      puzzle.isSolvedMarks(marks);

  /// The rule level the clues need, or null when a guess is needed.
  int? levelOf(BoatsPuzzle puzzle) =>
      solvingLevel(BoatsModel.fresh(puzzle), boatsRules);

  /// Answers the clues allow, counted by the deduction harness.
  int harnessSolutions(BoatsPuzzle puzzle, {int limit = 2}) =>
      rate(BoatsModel.fresh(puzzle), boatsRules, limit: limit).solutions;

  /// A cell the rules can prove, for the hint.
  ///
  /// The value is in the *player's* vocabulary ([kMarkShip]/[kMarkWater]), so
  /// the caller can drop it straight into its marks. Comparing a proof in the
  /// answer vocabulary against marks in the player vocabulary is exactly the
  /// `0`-means-two-things mistake this file keeps a comment about.
  ({int cell, int value})? hint(BoatsPuzzle puzzle, List<int> marks) {
    final model = BoatsModel.fresh(puzzle);
    if (!deduce(model, boatsRules).consistent) return null;
    for (var cell = 0; cell < model.masks.length; cell++) {
      final value = model.valueAt(cell);
      if (value == 0) continue;
      final shouldBeShip = value == kRegularShip;
      final isShip = marks[cell] == kMarkShip;
      if (shouldBeShip == isShip && marks[cell] != kMarkEmpty) continue;
      if (shouldBeShip != isShip) {
        return (cell: cell, value: shouldBeShip ? kMarkShip : kMarkWater);
      }
    }
    return null;
  }
}
