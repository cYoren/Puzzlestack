import 'dart:math';

import '../../../../core/deduction.dart';
import 'ascent_model.dart';
import 'ascent_puzzle.dart';

export 'ascent_puzzle.dart';

/// Number Path: one path from 1 to the last cell.
///
/// The generator lays a whole path on the grid first, then decides how much of
/// it to print. A board ships only when the printed numbers alone finish it:
/// the rules in [ascentDeductionRules] reach every cell without a guess.
class AscentEngine {
  const AscentEngine();

  // --------------------------------------------------------------- generator

  /// One board, or a throw.
  AscentPuzzle generate(
    AscentSize size, {
    Random? random,
    int attempts = 40,
  }) {
    final rng = random ?? Random();
    for (var attempt = 0; attempt < attempts; attempt++) {
      final path = _path(size, rng);
      if (path == null) continue;
      final seed = AscentPuzzle(
        size: size,
        givens: List<int>.from(path),
        solution: path,
      );
      final puzzle = _cutClues(seed, rng);
      if (puzzle.clueCount() == 0) continue;
      return puzzle;
    }
    throw StateError(
      'could not build a solvable ${size.n}x${size.n} Number Path board in '
      '$attempts attempts',
    );
  }

  /// Counts the paths the clues allow, by the complete search.
  AscentCount count(AscentPuzzle puzzle, {int limit = 2}) => AscentSearch(
        puzzle: puzzle,
        domains: AscentModel.fresh(puzzle).domains,
        limit: limit,
        budget: 2000000,
      ).run();

  /// The rule level the clues need, or null when a guess is needed.
  int? levelOf(AscentPuzzle puzzle) =>
      solvingLevel(AscentModel.fresh(puzzle), ascentRules);

  /// True when the player's numbers are a legal path that agrees with every
  /// printed number.
  bool isSolved(AscentPuzzle puzzle, List<int> values) =>
      puzzle.isSolved(values);

  /// A cell the rules can prove, and the number it must hold.
  ///
  /// A hint writes the number: a ring around a cell leaves the player to guess
  /// which of forty-nine numbers goes in it.
  ({int cell, int number})? hint(AscentPuzzle puzzle, List<int> values) {
    final model = AscentModel.fresh(puzzle);
    final outcome = deduce(model, ascentDeductionRules);
    final proved = <int, int>{};
    if (outcome.consistent) {
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        final number = model.numberAt(cell);
        if (number != 0) proved[cell] = number;
      }
    }
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final number = proved[cell] ?? puzzle.solution[cell];
      if (values[cell] == number) continue;
      return (cell: cell, number: number);
    }
    return null;
  }

  // ---------------------------------------------------------------- internals

  /// Lays a whole path over the grid.
  ///
  /// A king-move Hamiltonian path, found by depth-first search ordered by
  /// Warnsdorff's rule: the next cell is the one with the fewest onward moves.
  /// At 49 cells that finishes immediately; a plain random walk backtracks for
  /// a very long time near the end.
  List<int>? _path(AscentSize size, Random rng) {
    final n = size.n;
    final total = n * n;
    final step = List<int>.filled(total, 0);
    final visited = List<bool>.filled(total, false);

    int rowOf(int cell) => cell ~/ n;
    int colOf(int cell) => cell % n;
    List<int> around(int cell) => [
          for (var dr = -1; dr <= 1; dr++)
            for (var dc = -1; dc <= 1; dc++)
              if ((dr != 0 || dc != 0) &&
                  rowOf(cell) + dr >= 0 &&
                  rowOf(cell) + dr < n &&
                  colOf(cell) + dc >= 0 &&
                  colOf(cell) + dc < n)
                (rowOf(cell) + dr) * n + colOf(cell) + dc,
        ];

    bool walk(int cell, int number) {
      step[cell] = number;
      visited[cell] = true;
      if (number == total) return true;

      final options = [
        for (final other in around(cell))
          if (!visited[other]) other,
      ]..shuffle(rng);
      options.sort((a, b) {
        int room(int from) =>
            around(from).where((other) => !visited[other]).length;
        return room(a).compareTo(room(b));
      });

      for (final next in options) {
        if (walk(next, number + 1)) return true;
      }
      visited[cell] = false;
      return false;
    }

    final starts = List<int>.generate(total, (i) => i)..shuffle(rng);
    for (final start in starts) {
      if (walk(start, 1)) return step;
      // A failed start has to leave the grid clean for the next one.
      for (var cell = 0; cell < total; cell++) {
        visited[cell] = false;
      }
    }
    return null;
  }

  /// Removes printed numbers while the board stays finishable by reasoning.
  AscentPuzzle _cutClues(AscentPuzzle seed, Random rng) {
    final givens = List<int>.from(seed.solution);
    final order = List<int>.generate(seed.cellCount, (i) => i)..shuffle(rng);

    AscentPuzzle withGivens() => AscentPuzzle(
          size: seed.size,
          givens: givens,
          solution: seed.solution,
        );

    for (final cell in order) {
      final saved = givens[cell];
      givens[cell] = kAscentNoClue;
      final outcome =
          deduce(AscentModel.fresh(withGivens()), ascentDeductionRules);
      if (!outcome.consistent || !outcome.complete) givens[cell] = saved;
    }
    return withGivens();
  }
}
