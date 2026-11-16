/// Salad's generator: a random Latin square, its border clues, then the fewest
/// clues that still prove it.
///
/// The order matters. The answer comes first — a random Latin square of order
/// `n`, with every value above `nums` turned into a hole — and the clues are
/// read off that answer, so a clue cannot lie about a board it was not made
/// from. Then clues are dropped one at a time, in random order, and a drop is
/// kept only while the board still proves itself: exactly one answer, and
/// finishable with the rules a player has. A board whose only way in is the
/// search is not dealt.
library;

import 'dart:math';

import '../../../../core/deduction.dart';
import 'salad_model.dart';
import 'salad_puzzle.dart';

/// What a board's clues are worth, so the generator never ships a shrug.
class SaladEngine {
  const SaladEngine();

  /// A board at [size]. Throws rather than ship one it could not prove: a wrong
  /// board is worse than a missing one.
  ///
  /// An attempt is only worth making if the **full** border proves the answer,
  /// because dropping a clue can only make a board harder. A Latin square whose
  /// whole border needs a guess is abandoned and another one is rolled, rather
  /// than mined for clues that were never going to be enough.
  ///
  /// That is why [attempts] is large: on the 7x7 about one random Latin square
  /// in 250 has a border that proves itself, so the budget is set where that
  /// tail lands (`~200` attempts median, measured). The loop returns on its
  /// first success, so a size that is easy to deal never pays for the budget.
  SaladPuzzle generate(
    SaladSize size, {
    Random? random,
    int attempts = 4000,
  }) {
    final rng = random ?? Random();
    for (var attempt = 0; attempt < attempts; attempt++) {
      final answer = _latinSquare(size, rng);
      final full = SaladPuzzle(
        size: size,
        clues: _cluesFor(size, answer),
        solution: answer,
      );
      if (!_proven(full)) continue;
      final puzzle = _strip(full, rng);
      if (_proven(puzzle)) return puzzle;
    }
    throw StateError(
      'could not build a provable ${size.n}x${size.n} Salad board '
      'in $attempts attempts',
    );
  }

  /// A random Latin square of order [size.n], with every value above
  /// [SaladSize.nums] turned into a hole.
  ///
  /// Backtracking rather than a cyclic square: the clues are read off this
  /// answer, and a cyclic answer puts every letter in the same place in every
  /// row, so the borders would all describe the same board.
  List<int> _latinSquare(SaladSize size, Random rng) {
    final n = size.n;
    final grid = List<int>.filled(n * n, 0);

    bool fill(int cell) {
      if (cell == n * n) return true;
      final row = cell ~/ n;
      final col = cell % n;
      final order = [for (var value = 1; value <= n; value++) value]
        ..shuffle(rng);
      for (final value in order) {
        var ok = true;
        for (var i = 0; i < n && ok; i++) {
          if (grid[row * n + i] == value) ok = false;
          if (grid[i * n + col] == value) ok = false;
        }
        if (!ok) continue;
        grid[cell] = value;
        if (fill(cell + 1)) return true;
        grid[cell] = 0;
      }
      return false;
    }

    if (!fill(0)) throw StateError('no Latin square of order $n');
    // The hole is the value nothing else can be: with `nums = n - 1`, the one
    // symbol left over is a hole, exactly once per row and column.
    for (var cell = 0; cell < grid.length; cell++) {
      if (grid[cell] > size.nums) grid[cell] = kSaladHole;
    }
    return grid;
  }

  /// The four border clues per line that are true of [answer].
  List<int> _cluesFor(SaladSize size, List<int> answer) {
    final puzzle = SaladPuzzle(
      size: size,
      clues: List<int>.filled(size.clueCount, kSaladNoClue),
      solution: answer,
    );
    final clues = List<int>.filled(size.clueCount, kSaladNoClue);
    for (final dir in SaladClueDir.values) {
      for (var index = 0; index < size.n; index++) {
        for (final cell in puzzle.line(dir, index)) {
          // A line always holds at least one letter, so the scan always lands.
          if (answer[cell] != kSaladHole) {
            clues[dir.index * size.n + index] = answer[cell];
            break;
          }
        }
      }
    }
    return clues;
  }

  /// [puzzle] with as many clues dropped as still prove it.
  ///
  /// Random order, so two boards of the same size do not keep the same border
  /// positions. A drop is kept only if the board that is left still has one
  /// answer and can still be reasoned to.
  SaladPuzzle _strip(SaladPuzzle puzzle, Random rng) {
    final order = [for (var i = 0; i < puzzle.clues.length; i++) i]
      ..shuffle(rng);
    var current = puzzle;
    for (final index in order) {
      if (current.clues[index] == kSaladNoClue) continue;
      final clues = [...current.clues]..[index] = kSaladNoClue;
      final candidate = SaladPuzzle(
        size: current.size,
        clues: clues,
        solution: current.solution,
      );
      if (!_proven(candidate)) continue;
      current = candidate;
    }
    return current;
  }

  /// Exactly one answer, and reachable with the rules a player has.
  ///
  /// The exact rule is allowed to prove uniqueness — it is a search, and that is
  /// what a search is for — but it is not allowed to be the *only* way in. A
  /// board whose player rules stop dead and whose answer needs a machine to find
  /// is not a puzzle, it is a lookup, so [solvingLevel] ignores level 3.
  bool _proven(SaladPuzzle puzzle) {
    final count = countSolutions(
      SaladModel.fresh(puzzle),
      saladPlayerRules,
      limit: 2,
    );
    if (count.truncated || !count.isUnique) return false;
    return solvingLevel(SaladModel.fresh(puzzle), saladPlayerRules) != null;
  }

  /// How many answers [puzzle] has, at most two.
  int count(SaladPuzzle puzzle) =>
      countSolutions(SaladModel.fresh(puzzle), saladPlayerRules).count;

  /// The lowest rule level that finishes [puzzle], or null when it needs a
  /// guess. Level 3 is the exact search, so the number the app reports is the
  /// depth a player actually has to reach.
  int? levelOf(SaladPuzzle puzzle) =>
      solvingLevel(SaladModel.fresh(puzzle), saladPlayerRules);

  /// A cell and symbol the rules prove, or null when the rules have run out.
  ///
  /// It returns a value to write; the board decides how to show it. A hint that
  /// only outlined a cell would leave the player exactly where they were.
  SaladHint? hint(SaladPuzzle puzzle, List<int> values) {
    final model = SaladModel.fresh(puzzle);
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      if (values[cell] == kSaladBlank) continue;
      if (model.set(cell, values[cell]) < 0) return null;
    }
    final outcome = deduce(model, saladPlayerRules);
    if (!outcome.consistent) return null;
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      if (values[cell] != kSaladBlank) continue;
      // `symbolAt` answers null unless the cell is down to one symbol. A hole is
      // zero, so a sentinel here would be a fourth way to say "nothing".
      final symbol = model.symbolAt(cell);
      if (symbol != null) return SaladHint(cell, symbol);
    }
    return null;
  }

  /// Whether [values] is the answer, on the board as the player sees it.
  bool isSolved(SaladPuzzle puzzle, List<int> values) =>
      puzzle.isSolution(values);
}

/// A proved cell.
class SaladHint {
  const SaladHint(this.cell, this.symbol);

  final int cell;

  /// A letter `1..nums`, or [kSaladHole] when the rules prove the cell is a
  /// hole.
  final int symbol;
}
