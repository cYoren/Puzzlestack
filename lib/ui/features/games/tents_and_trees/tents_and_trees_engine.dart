import 'dart:math';

import '../../../../core/deduction.dart';
import 'tents_model.dart';
import 'tents_puzzle.dart';

export 'tents_puzzle.dart';

/// Tents & Trees.
///
/// The old engine placed trees and tents and never asked whether the numbers
/// pinned the tents down, so a board could accept a second arrangement. This
/// one builds a legal arrangement, reads the numbers off it, and then hands the
/// clues to the deduction harness: a board ships only when exactly one
/// arrangement fits and the rules can reach it.
class TentsEngine {
  const TentsEngine();

  // --------------------------------------------------------------- generator

  TentsPuzzle generate(TentsDifficulty difficulty, {Random? random}) {
    final rng = random ?? Random();
    final rows = difficulty.rows;
    final cols = difficulty.cols;

    for (var attempt = 0; attempt < 4000; attempt++) {
      final trees = _randomTrees(rows, cols, rng);
      if (trees == null) continue;

      final tents = _randomTents(rows, cols, trees, rng);
      if (tents == null) continue;

      final rowCounts = List<int>.filled(rows, 0);
      final colCounts = List<int>.filled(cols, 0);
      for (final tent in tents) {
        rowCounts[tent ~/ cols]++;
        colCounts[tent % cols]++;
      }

      final puzzle = TentsPuzzle(
        rows: rows,
        cols: cols,
        trees: trees,
        solution: tents,
        rowCounts: rowCounts,
        colCounts: colCounts,
      );

      final rating = rate(TentsModel.fresh(puzzle), tentsRules);
      if (rating.verdict != PuzzleVerdict.solved) continue;
      if (rating.level != difficulty.level) continue;
      return puzzle;
    }
    throw StateError('could not build a unique $rows x $cols Tents board');
  }

  /// A board with no uniqueness or level gate, for testing the rules.
  TentsPuzzle generateUngated(TentsDifficulty difficulty, Random rng) {
    final rows = difficulty.rows;
    final cols = difficulty.cols;
    while (true) {
      final trees = _randomTrees(rows, cols, rng);
      if (trees == null) continue;
      final tents = _randomTents(rows, cols, trees, rng);
      if (tents == null) continue;
      final rowCounts = List<int>.filled(rows, 0);
      final colCounts = List<int>.filled(cols, 0);
      for (final tent in tents) {
        rowCounts[tent ~/ cols]++;
        colCounts[tent % cols]++;
      }
      return TentsPuzzle(
        rows: rows,
        cols: cols,
        trees: trees,
        solution: tents,
        rowCounts: rowCounts,
        colCounts: colCounts,
      );
    }
  }

  List<int>? _randomTrees(int rows, int cols, Random rng) {
    final count = rows * cols ~/ 5;
    final cells = List<int>.generate(rows * cols, (i) => i)..shuffle(rng);
    final trees = <int>[];
    for (final cell in cells) {
      if (trees.length == count) break;
      trees.add(cell);
    }
    if (trees.length < count) return null;

    // Every tree needs somewhere for its tent to go.
    for (final tree in trees) {
      final free = _orthogonal(tree, rows, cols)
          .where((c) => !trees.contains(c))
          .length;
      if (free == 0) return null;
    }
    return trees;
  }

  List<int>? _randomTents(int rows, int cols, List<int> trees, Random rng) {
    final treeSet = trees.toSet();
    final tents = <int>[];
    final order = [...trees]..shuffle(rng);

    bool place(int index) {
      if (index == order.length) return true;
      final tree = order[index];
      final options = _orthogonal(tree, rows, cols)
        ..shuffle(rng);
      for (final cell in options) {
        if (treeSet.contains(cell)) continue;
        if (tents.contains(cell)) continue;
        // A tent belongs to exactly one tree.
        if (_orthogonal(cell, rows, cols).where(treeSet.contains).length != 1) {
          continue;
        }
        // Tents never touch, corners included.
        if (_around(cell, rows, cols).any(tents.contains)) continue;
        tents.add(cell);
        if (place(index + 1)) return true;
        tents.removeLast();
      }
      return false;
    }

    return place(0) ? tents : null;
  }

  List<int> _orthogonal(int cell, int rows, int cols) {
    final row = cell ~/ cols;
    final col = cell % cols;
    return [
      if (row > 0) cell - cols,
      if (row + 1 < rows) cell + cols,
      if (col > 0) cell - 1,
      if (col + 1 < cols) cell + 1,
    ];
  }

  List<int> _around(int cell, int rows, int cols) {
    final row = cell ~/ cols;
    final col = cell % cols;
    return [
      for (var dr = -1; dr <= 1; dr++)
        for (var dc = -1; dc <= 1; dc++)
          if ((dr != 0 || dc != 0) &&
              row + dr >= 0 &&
              row + dr < rows &&
              col + dc >= 0 &&
              col + dc < cols)
            (row + dr) * cols + col + dc,
    ];
  }

  // ------------------------------------------------------------------- rules

  /// True when the player's board is a valid answer.
  bool isSolved(TentsPuzzle puzzle, List<int> tents) {
    final tentSet = tents.toSet();
    if (tentSet.length != puzzle.treeCount) return false;

    for (final tent in tentSet) {
      if (puzzle.isTree(tent)) return false;
      final adjacentTrees =
          _orthogonal(tent, puzzle.rows, puzzle.cols).where(puzzle.isTree);
      if (adjacentTrees.length != 1) return false;
      for (final other in _around(tent, puzzle.rows, puzzle.cols)) {
        if (tentSet.contains(other)) return false;
      }
    }
    for (final tree in puzzle.trees) {
      final beside = _orthogonal(tree, puzzle.rows, puzzle.cols)
          .where(tentSet.contains)
          .length;
      if (beside != 1) return false;
    }
    for (var r = 0; r < puzzle.rows; r++) {
      final row = tentSet.where((c) => c ~/ puzzle.cols == r).length;
      if (row != puzzle.rowCounts[r]) return false;
    }
    for (var c = 0; c < puzzle.cols; c++) {
      final col = tentSet.where((cell) => cell % puzzle.cols == c).length;
      if (col != puzzle.colCounts[c]) return false;
    }
    return true;
  }

  /// The rule level a board needs.
  int? levelOf(TentsPuzzle puzzle) =>
      solvingLevel(TentsModel.fresh(puzzle), tentsRules);

  /// Solutions the clues allow, counted by the deduction harness.
  int harnessSolutions(TentsPuzzle puzzle, {int limit = 2}) =>
      rate(TentsModel.fresh(puzzle), tentsRules, limit: limit).solutions;

  /// A cell the rules can prove, for the hint.
  ///
  /// The rules are run to a fixed point first. Stopping at the first rule that
  /// settles anything is not enough: it may settle cells the player already has
  /// right, and the cell they got wrong may only fall out two rules later.
  ({int cell, int value})? hint(TentsPuzzle puzzle, List<int> tents) {
    final model = TentsModel.fresh(puzzle);
    if (!deduce(model, tentsRules).consistent) return null;
    for (var cell = 0; cell < model.masks.length; cell++) {
      if (puzzle.isTree(cell)) continue;
      final value = model.valueAt(cell);
      if (value == 0) continue;
      if ((value == kTent) == tents.contains(cell)) continue;
      return (cell: cell, value: value);
    }
    return null;
  }
}
