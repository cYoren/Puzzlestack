import 'dart:math';

import '../../../../core/deduction.dart';
import '../../../../core/latin.dart';

/// Skyscrapers: fill an n x n grid with towers of heights 1..n so that every
/// row and column holds each height once, and the numbers around the edge say
/// how many towers are visible from that side.
///
/// The clues are the puzzle. A board with every clue is nearly trivial; a board
/// with the fewest clues that still pins one answer is the game. So the
/// generator starts from a full set and removes clues one at a time, keeping a
/// removal only while the board stays unique *and* the rules can still finish
/// it. That is the Phase 3 bar applied to a classic that was shipped without it.
class SkyscrapersPuzzle {
  const SkyscrapersPuzzle({
    required this.n,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.solution,
  });

  final int n;

  /// Clue per column, 0 when that side has no clue.
  final List<int> top;
  final List<int> bottom;

  /// Clue per row, 0 when that side has no clue.
  final List<int> left;
  final List<int> right;

  /// Row-major answer, values 1..n.
  final List<int> solution;

  int get clueCount =>
      top.where((c) => c != 0).length +
      bottom.where((c) => c != 0).length +
      left.where((c) => c != 0).length +
      right.where((c) => c != 0).length;
}

enum SkyscrapersDifficulty {
  easy(4, 8),
  medium(5, 10),
  hard(6, 12);

  const SkyscrapersDifficulty(this.n, this.minClues);

  final int n;

  /// Stop removing clues here. Fewer than this and the board stops being
  /// readable at phone size even when it is still unique.
  final int minClues;
}

class SkyscrapersEngine {
  const SkyscrapersEngine();

  /// How many towers a viewer sees from one end of [values].
  int visible(List<int> values) {
    var seen = 0;
    var tallest = 0;
    for (final value in values) {
      if (value > tallest) {
        tallest = value;
        seen++;
      }
    }
    return seen;
  }

  // ------------------------------------------------------------------- model

  LatinModel model(SkyscrapersPuzzle puzzle) {
    final n = puzzle.n;
    final lines = <LatinLine>[
      for (var row = 0; row < n; row++)
        LatinLine(
          cells: [for (var col = 0; col < n; col++) row * n + col],
          name: 'row $row',
          accept: (values) =>
              _accept(puzzle.left[row], puzzle.right[row], values),
        ),
      for (var col = 0; col < n; col++)
        LatinLine(
          cells: [for (var row = 0; row < n; row++) row * n + col],
          name: 'col $col',
          accept: (values) =>
              _accept(puzzle.top[col], puzzle.bottom[col], values),
        ),
    ];
    return latinModel(n: n, lines: lines);
  }

  bool _accept(int from, int to, List<int> values) {
    if (from != 0 && visible(values) != from) return false;
    if (to != 0 && visible(values.reversed.toList()) != to) return false;
    return true;
  }

  SolutionCount count(SkyscrapersPuzzle puzzle) =>
      countSolutions(model(puzzle), latinRules);

  PuzzleRating rating(SkyscrapersPuzzle puzzle) =>
      rate(model(puzzle), latinRules);

  // --------------------------------------------------------------- generator

  SkyscrapersPuzzle generate(SkyscrapersDifficulty difficulty, {Random? random}) {
    final rng = random ?? Random();
    final n = difficulty.n;

    while (true) {
      final solution = _randomLatin(n, rng);
      final top = <int>[];
      final bottom = <int>[];
      final left = <int>[];
      final right = <int>[];
      for (var col = 0; col < n; col++) {
        final column = [for (var row = 0; row < n; row++) solution[row * n + col]];
        top.add(visible(column));
        bottom.add(visible(column.reversed.toList()));
      }
      for (var row = 0; row < n; row++) {
        final line = [for (var col = 0; col < n; col++) solution[row * n + col]];
        left.add(visible(line));
        right.add(visible(line.reversed.toList()));
      }

      var puzzle = SkyscrapersPuzzle(
        n: n,
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        solution: solution,
      );
      if (puzzle.clueCount <= difficulty.minClues) continue;

      // A full set of clues is not automatically unique — two Latin squares can
      // show the same skyline from every side. If this one is already
      // ambiguous, no removal can rescue it.
      if (rating(puzzle).verdict != PuzzleVerdict.solved) continue;

      // Drop clues one at a time, keeping only the removals that leave one
      // answer that the rules can reach.
      final slots = <(String, int)>[
        for (var i = 0; i < n; i++) ...[('top', i), ('bottom', i), ('left', i), ('right', i)],
      ]..shuffle(rng);

      for (final (side, index) in slots) {
        if (puzzle.clueCount <= difficulty.minClues) break;
        final candidate = _without(puzzle, side, index);
        if (candidate.clueCount == puzzle.clueCount) continue;
        final verdict = rating(candidate);
        if (verdict.verdict != PuzzleVerdict.solved) continue;
        puzzle = candidate;
      }

      return puzzle;
    }
  }

  SkyscrapersPuzzle _without(SkyscrapersPuzzle puzzle, String side, int index) {
    List<int> cleared(List<int> list) => [
          for (var i = 0; i < list.length; i++) i == index ? 0 : list[i],
        ];
    return SkyscrapersPuzzle(
      n: puzzle.n,
      top: side == 'top' ? cleared(puzzle.top) : puzzle.top,
      bottom: side == 'bottom' ? cleared(puzzle.bottom) : puzzle.bottom,
      left: side == 'left' ? cleared(puzzle.left) : puzzle.left,
      right: side == 'right' ? cleared(puzzle.right) : puzzle.right,
      solution: puzzle.solution,
    );
  }

  /// A random Latin square, by backtracking with shuffled values.
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
