import 'dart:math';

import '../../../../core/deduction.dart';
import 'clusters_model.dart';
import 'clusters_puzzle.dart';

export 'clusters_puzzle.dart';

/// Clusters: two colours, and the dots that give them away.
///
/// The generator colours the whole grid, fixes the cells that would have no
/// neighbour of their own colour (the rule forbids them), and then prints a dot
/// on every cell with exactly one. A board ships only when those dots alone
/// pin the colouring down.
class ClustersEngine {
  const ClustersEngine();

  // --------------------------------------------------------------- generator

  /// One board, or a throw.
  ///
  /// A random colouring is the whole input: the dots are read off it, never
  /// chosen. Retrying is what makes the puzzle fair — a board whose dots leave
  /// a second colouring is thrown away, not patched with an extra clue.
  ClustersPuzzle generate(
    ClustersSize size, {
    Random? random,
    int attempts = 400,
  }) {
    final rng = random ?? Random();
    for (var attempt = 0; attempt < attempts; attempt++) {
      final colours = _colouring(size, rng);
      if (colours == null) continue;
      final clues = List<int>.filled(size.cellCount, kClusterNoClue);
      for (var cell = 0; cell < size.cellCount; cell++) {
        final same = _sameAround(size, colours, cell, colours[cell]);
        if (same == 1) clues[cell] = colours[cell];
      }
      final puzzle = ClustersPuzzle(
        size: size,
        clues: clues,
        solution: colours,
      );
      if (puzzle.clueCount() == 0) continue;
      if (!puzzle.isLegal(colours)) continue;

      final outcome = deduce(ClustersModel.fresh(puzzle), clustersRules);
      if (!outcome.consistent || !outcome.complete) continue;
      return puzzle;
    }
    throw StateError(
      'could not build a solvable ${size.n}x${size.n} Clusters board in '
      '$attempts attempts',
    );
  }

  /// Counts the colourings the dots allow, by the complete search.
  ClustersCount count(ClustersPuzzle puzzle, {int limit = 2}) => ClustersSearch(
        puzzle: puzzle,
        masks: ClustersModel.fresh(puzzle).masks,
        limit: limit,
        budget: 2000000,
      ).run();

  /// The rule level the dots need, or null when a guess is needed.
  int? levelOf(ClustersPuzzle puzzle) =>
      solvingLevel(ClustersModel.fresh(puzzle), clustersRules);

  /// True when the player's colours are a legal colouring.
  bool isSolved(ClustersPuzzle puzzle, List<int> values) =>
      puzzle.isSolved(values);

  /// A cell the rules can prove, and the colour it must take.
  ({int cell, int colour})? hint(ClustersPuzzle puzzle, List<int> values) {
    final model = ClustersModel.fresh(puzzle);
    final outcome = deduce(model, clustersDeductionRules);
    final proved = <int, int>{};
    if (outcome.consistent) {
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        final colour = model.colourAt(cell);
        if (colour != 0) proved[cell] = colour;
      }
    }
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final colour = proved[cell] ?? puzzle.solution[cell];
      if (values[cell] == colour) continue;
      return (cell: cell, colour: colour);
    }
    return null;
  }

  // ---------------------------------------------------------------- internals

  /// A random two-colouring with no cell left without a neighbour of its own
  /// colour.
  ///
  /// Flipping a bad cell can make its neighbour bad, so this runs to a fixed
  /// point. It always terminates: every flip strictly reduces the number of
  /// cells that have no same-coloured neighbour... except in a corner case the
  /// iteration cap is there for.
  List<int>? _colouring(ClustersSize size, Random rng) {
    final n = size.n;
    final colours = [
      for (var cell = 0; cell < n * n; cell++)
        rng.nextBool() ? kClusterRed : kClusterBlue,
    ];

    for (var round = 0; round < n * n * 4; round++) {
      var fixed = true;
      for (var cell = 0; cell < n * n; cell++) {
        if (_sameAround(size, colours, cell, colours[cell]) == 0) {
          colours[cell] = otherColour(colours[cell]);
          fixed = false;
          break;
        }
      }
      if (fixed) return colours;
    }
    return null;
  }

  int _sameAround(ClustersSize size, List<int> colours, int cell, int colour) {
    final n = size.n;
    final r = cell ~/ n;
    final c = cell % n;
    var count = 0;
    if (r > 0 && colours[cell - n] == colour) count++;
    if (r + 1 < n && colours[cell + n] == colour) count++;
    if (c > 0 && colours[cell - 1] == colour) count++;
    if (c + 1 < n && colours[cell + 1] == colour) count++;
    return count;
  }
}
