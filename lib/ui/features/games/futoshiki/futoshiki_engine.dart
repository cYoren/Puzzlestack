import 'dart:math';

import '../../../../core/deduction.dart';
import '../../../../core/latin.dart';

/// Futoshiki: a Latin square with `<` and `>` between some neighbours.
///
/// The old generator sprinkled inequalities at a fixed 30% chance and then
/// added givens until a brute-force count said "one solution". That is a
/// uniqueness check, but it is not a *reasoning* check: a board can be unique
/// and still need a guess, and the givens were never minimised.
///
/// This one starts from every inequality and removes them one at a time,
/// keeping a removal only while the board stays unique and the line filter can
/// still finish it. Most boards end up with no givens at all — the inequalities
/// alone pin the square down, which is what a good Futoshiki looks like.
class FutoshikiPuzzle {
  const FutoshikiPuzzle({
    required this.n,
    required this.givens,
    required this.horizontal,
    required this.vertical,
    required this.solution,
  });

  final int n;

  /// Cell index -> value. Usually empty.
  final Map<int, int> givens;

  /// One entry per horizontal edge, `row * (n - 1) + col`: 1 means the left
  /// cell is smaller, -1 the right, 0 no inequality.
  final List<int> horizontal;

  /// One entry per vertical edge, `row * n + col` for the edge between
  /// (row, col) and (row + 1, col): 1 means the top is smaller, -1 the bottom.
  final List<int> vertical;

  /// Row-major answer.
  final List<int> solution;

  int get inequalityCount =>
      horizontal.where((e) => e != 0).length + vertical.where((e) => e != 0).length;
}

enum FutoshikiDifficulty {
  easy(4, 0.60),
  medium(5, 0.45),
  hard(6, 0.0);

  const FutoshikiDifficulty(this.n, this.keepFraction);

  final int n;

  /// Stop removing inequalities when this share of the edges is left. Hard
  /// removes everything it can.
  final double keepFraction;
}

class FutoshikiEngine {
  const FutoshikiEngine();

  // ------------------------------------------------------------------- model

  LatinModel model(FutoshikiPuzzle puzzle) {
    final n = puzzle.n;
    final lines = <LatinLine>[
      for (var row = 0; row < n; row++)
        LatinLine(
          cells: [for (var col = 0; col < n; col++) row * n + col],
          name: 'row $row',
          accept: (values) {
            for (var col = 0; col + 1 < n; col++) {
              final edge = puzzle.horizontal[row * (n - 1) + col];
              if (edge == 1 && values[col] >= values[col + 1]) return false;
              if (edge == -1 && values[col] <= values[col + 1]) return false;
            }
            return true;
          },
        ),
      for (var col = 0; col < n; col++)
        LatinLine(
          cells: [for (var row = 0; row < n; row++) row * n + col],
          name: 'col $col',
          accept: (values) {
            for (var row = 0; row + 1 < n; row++) {
              final edge = puzzle.vertical[row * n + col];
              if (edge == 1 && values[row] >= values[row + 1]) return false;
              if (edge == -1 && values[row] <= values[row + 1]) return false;
            }
            return true;
          },
        ),
    ];
    return latinModel(n: n, lines: lines, givens: puzzle.givens);
  }

  SolutionCount count(FutoshikiPuzzle puzzle) =>
      countSolutions(model(puzzle), latinRules);

  PuzzleRating rating(FutoshikiPuzzle puzzle) =>
      rate(model(puzzle), latinRules);

  // --------------------------------------------------------------- generator

  FutoshikiPuzzle generate(FutoshikiDifficulty difficulty, {Random? random}) {
    final rng = random ?? Random();
    final n = difficulty.n;
    final horizontalEdges = n * (n - 1);
    final verticalEdges = (n - 1) * n;
    final totalEdges = horizontalEdges + verticalEdges;
    final floor = (totalEdges * difficulty.keepFraction).floor();

    while (true) {
      final solution = _randomLatin(n, rng);
      final horizontal = List<int>.filled(horizontalEdges, 0);
      final vertical = List<int>.filled(verticalEdges, 0);
      for (var row = 0; row < n; row++) {
        for (var col = 0; col + 1 < n; col++) {
          final a = solution[row * n + col];
          final b = solution[row * n + col + 1];
          horizontal[row * (n - 1) + col] = a < b ? 1 : -1;
        }
      }
      for (var row = 0; row + 1 < n; row++) {
        for (var col = 0; col < n; col++) {
          final a = solution[row * n + col];
          final b = solution[(row + 1) * n + col];
          vertical[row * n + col] = a < b ? 1 : -1;
        }
      }

      var puzzle = FutoshikiPuzzle(
        n: n,
        givens: const {},
        horizontal: horizontal,
        vertical: vertical,
        solution: solution,
      );

      // Every inequality is not always enough; a given or two fixes that.
      if (rating(puzzle).verdict != PuzzleVerdict.solved) {
        final cells = List<int>.generate(n * n, (i) => i)..shuffle(rng);
        var added = 0;
        for (final cell in cells) {
          if (rating(puzzle).verdict == PuzzleVerdict.solved) break;
          puzzle = _withGiven(puzzle, cell, solution[cell]);
          added++;
          if (added > n * n) break;
        }
        if (rating(puzzle).verdict != PuzzleVerdict.solved) continue;
      }

      final edges = <(bool, int)>[
        for (var i = 0; i < horizontalEdges; i++) (true, i),
        for (var i = 0; i < verticalEdges; i++) (false, i),
      ]..shuffle(rng);

      for (final (isHorizontal, index) in edges) {
        if (puzzle.inequalityCount <= floor) break;
        final candidate = _without(puzzle, isHorizontal, index);
        if (rating(candidate).verdict != PuzzleVerdict.solved) continue;
        puzzle = candidate;
      }

      return puzzle;
    }
  }

  FutoshikiPuzzle _withGiven(FutoshikiPuzzle puzzle, int cell, int value) {
    return FutoshikiPuzzle(
      n: puzzle.n,
      givens: {...puzzle.givens, cell: value},
      horizontal: puzzle.horizontal,
      vertical: puzzle.vertical,
      solution: puzzle.solution,
    );
  }

  FutoshikiPuzzle _without(FutoshikiPuzzle puzzle, bool isHorizontal, int index) {
    final horizontal = [...puzzle.horizontal];
    final vertical = [...puzzle.vertical];
    if (isHorizontal) {
      horizontal[index] = 0;
    } else {
      vertical[index] = 0;
    }
    return FutoshikiPuzzle(
      n: puzzle.n,
      givens: puzzle.givens,
      horizontal: horizontal,
      vertical: vertical,
      solution: puzzle.solution,
    );
  }

  List<int> _randomLatin(int n, Random rng) {
    final grid = List<int>.filled(n * n, 0);

    bool fits(int cell, int value) {
      final row = cell ~/ n;
      final col = cell % n;
      for (var i = 0; i < n; i++) {
        if (grid[row * n + i] == value) return false;
        if (grid[i * n + col] == value) return false;
      }
      return true;
    }

    bool fill(int cell) {
      if (cell == n * n) return true;
      final values = List<int>.generate(n, (i) => i + 1)..shuffle(rng);
      for (final value in values) {
        if (!fits(cell, value)) continue;
        grid[cell] = value;
        if (fill(cell + 1)) return true;
        grid[cell] = 0;
      }
      return false;
    }

    fill(0);
    return grid;
  }
}
