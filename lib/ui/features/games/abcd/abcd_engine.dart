import 'dart:math';

import '../../../../core/deduction.dart';
import 'abcd_model.dart';
import 'abcd_puzzle.dart';

export 'abcd_puzzle.dart';

/// ABCD: a letter in every cell.
///
/// The generator fills a legal grid first and reads the edge counts off it, then
/// asks the deduction harness whether those counts are enough. A board ships only
/// when exactly one grid fits and the rules reach it by reasoning, never by
/// guessing, which is what makes the numbers a puzzle instead of a hint.
class AbcdEngine {
  const AbcdEngine();

  // --------------------------------------------------------------- generator

  AbcdPuzzle generate(AbcdSize size, {Random? random, int attempts = 300}) {
    final rng = random ?? Random();
    for (var attempt = 0; attempt < attempts; attempt++) {
      final filled = _randomGrid(size, rng);
      if (filled == null) continue;
      final puzzle = _fromGrid(size, filled);
      final rating = rate(AbcdModel.fresh(puzzle), abcdRules);
      if (rating.verdict != PuzzleVerdict.solved) continue;
      return puzzle;
    }
    throw StateError(
      'could not build a unique ${size.rows}x${size.cols} ABCD board in '
      '$attempts attempts',
    );
  }

  /// A legal grid with no uniqueness gate, for testing the rules themselves.
  AbcdPuzzle generateUngated(AbcdSize size, Random rng) {
    while (true) {
      final filled = _randomGrid(size, rng);
      if (filled == null) continue;
      return _fromGrid(size, filled);
    }
  }

  AbcdPuzzle _fromGrid(AbcdSize size, List<int> grid) {
    final rowCounts = [
      for (var row = 0; row < size.rows; row++)
        [
          for (var letter = 0; letter < size.letters; letter++)
            _countIn(
              grid,
              [for (var col = 0; col < size.cols; col++) row * size.cols + col],
              letter,
            ),
        ],
    ];
    final colCounts = [
      for (var col = 0; col < size.cols; col++)
        [
          for (var letter = 0; letter < size.letters; letter++)
            _countIn(
              grid,
              [for (var row = 0; row < size.rows; row++) row * size.cols + col],
              letter,
            ),
        ],
    ];
    return AbcdPuzzle(
      size: size,
      rowCounts: rowCounts,
      colCounts: colCounts,
      solution: grid,
    );
  }

  int _countIn(List<int> grid, List<int> cells, int letter) {
    var count = 0;
    for (final cell in cells) {
      if (grid[cell] == letter) count++;
    }
    return count;
  }

  /// A random legal grid: no two identical letters touching along an edge.
  ///
  /// The counts are read off this grid afterwards, so the shape of the grid is
  /// what decides whether the clues pin it down. Filling each row with a fixed
  /// multiset (the obvious first attempt) gives every row the same profile, and
  /// a board whose rows and columns all read the same is a permutation puzzle
  /// with hundreds of answers. Picking each cell freely from the letters that do
  /// not touch its neighbours gives the varied profiles the counts can pin down.
  List<int>? _randomGrid(AbcdSize size, Random rng) {
    final rows = size.rows;
    final cols = size.cols;
    final letters = size.letters;
    final grid = List<int>.filled(rows * cols, -1);

    bool fits(int row, int col, int letter) {
      if (col > 0 && grid[row * cols + col - 1] == letter) return false;
      if (row > 0 && grid[(row - 1) * cols + col] == letter) return false;
      return true;
    }

    bool fillCell(int row, int col) {
      if (row == rows) return true;
      if (col == cols) return fillCell(row + 1, 0);

      final order = List<int>.generate(letters, (i) => i)..shuffle(rng);
      for (final letter in order) {
        if (!fits(row, col, letter)) continue;
        final index = row * cols + col;
        grid[index] = letter;
        if (fillCell(row, col + 1)) return true;
        grid[index] = -1;
      }
      return false;
    }

    return fillCell(0, 0) ? grid : null;
  }

  // ------------------------------------------------------------------- rules

  bool isSolved(AbcdPuzzle puzzle, List<int> grid) => puzzle.isLegal(grid);

  int? levelOf(AbcdPuzzle puzzle) =>
      solvingLevel(AbcdModel.fresh(puzzle), abcdRules);

  int harnessSolutions(AbcdPuzzle puzzle, {int limit = 2}) =>
      rate(AbcdModel.fresh(puzzle), abcdRules, limit: limit).solutions;

  /// A cell the rules can prove, for the hint.
  ({int cell, int letter})? hint(AbcdPuzzle puzzle, List<int> grid) {
    final model = AbcdModel.fresh(puzzle);
    if (!deduce(model, abcdRules).consistent) return null;
    for (var cell = 0; cell < model.masks.length; cell++) {
      final value = model.valueAt(cell);
      if (value < 0) continue;
      if (grid[cell] == value) continue;
      return (cell: cell, letter: value);
    }
    return null;
  }
}
