/// Mathrax's generator: a Latin square, then the fewest corner clues that still
/// prove it.
///
/// The order matters. The answer comes first — a random Latin square with no
/// arithmetic in it — and the clues are read off that answer, so a clue cannot
/// lie about a board it was not made from. Then clues are dropped one at a time
/// and kept dropped only while the board still rates `solved`: exactly one
/// answer, and reachable by reasoning. A clue survives because it is needed, not
/// because it was printed.
library;

import 'dart:math';

import '../../../../core/deduction.dart';
import 'mathrax_model.dart';
import 'mathrax_puzzle.dart';

/// What a board's clues are worth, so the generator never ships a shrug.
class MathraxEngine {
  const MathraxEngine();

  /// A board at [size]. Throws rather than ship one it could not prove: a wrong
  /// board is worse than a missing one.
  MathraxPuzzle generate(
    MathraxSize size, {
    Random? random,
    int attempts = 120,
  }) {
    final rng = random ?? Random();
    for (var attempt = 0; attempt < attempts; attempt++) {
      final answer = _latinSquare(size.n, rng);
      final puzzle = _withClues(size, answer, rng);
      if (_proven(puzzle)) return puzzle;
    }
    throw StateError(
        'could not build a provable ${size.n}x${size.n} Mathrax board '
        'in $attempts attempts');
  }

  /// A random Latin square: fill cell by cell, trying digits in random order.
  ///
  /// Backtracking rather than a cyclic square, because the clues are read off
  /// this answer and a cyclic square has a repeating arithmetic signature at
  /// every corner: the boards would all feel the same.
  List<int> _latinSquare(int n, Random rng) {
    final grid = List<int>.filled(n * n, 0);

    bool fill(int cell) {
      if (cell == n * n) return true;
      final row = cell ~/ n;
      final col = cell % n;
      final order = [for (var digit = 1; digit <= n; digit++) digit]
        ..shuffle(rng);
      for (final digit in order) {
        var ok = true;
        for (var i = 0; i < n && ok; i++) {
          if (grid[row * n + i] == digit) ok = false;
          if (grid[i * n + col] == digit) ok = false;
        }
        if (!ok) continue;
        grid[cell] = digit;
        if (fill(cell + 1)) return true;
        grid[cell] = 0;
      }
      return false;
    }

    // A uniform random Latin square always exists; the loop is here so a bug in
    // the backtracking cannot become a crash.
    if (!fill(0)) throw StateError('no Latin square of order $n');
    return grid;
  }

  /// The clues that are true of [answer], then the fewest of them that still
  /// prove the answer.
  MathraxPuzzle _withClues(MathraxSize size, List<int> answer, Random rng) {
    final n = size.n;
    final clues = List<MathraxClue?>.filled(size.clueCount, null);
    for (var row = 0; row < n - 1; row++) {
      for (var col = 0; col < n - 1; col++) {
        clues[row * (n - 1) + col] = _clueFor(size, answer, row, col, rng);
      }
    }

    var puzzle = MathraxPuzzle(size: size, clues: clues, solution: answer);
    // Drop clues while the board survives on its own. Random order, so two
    // boards of the same size do not keep the same corners.
    //
    // A floor stops the prune at `clueCount * 2 / 5` clues. Uniqueness does not
    // need them — a 4x4 is often pinned by three corners — but a card with three
    // marks on it does not look like Mathrax and gives the player nothing to
    // start from. The floor is a design value, measured: 40% keeps the boards
    // solvable at level 2 rather than turning them into Sudoku with arithmetic.
    final floor = (clues.length * 2 / 5).round();
    var remaining = clues.where((clue) => clue != null).length;
    final order = [for (var i = 0; i < clues.length; i++) i]..shuffle(rng);
    for (final index in order) {
      if (puzzle.clues[index] == null) continue;
      if (remaining <= floor) break;
      final without = [...puzzle.clues]..[index] = null;
      final candidate =
          MathraxPuzzle(size: size, clues: without, solution: answer);
      if (!_proven(candidate)) continue;
      puzzle = candidate;
      remaining--;
    }
    return puzzle;
  }

  /// Exactly one answer, and reachable with the rules a player has.
  ///
  /// The exact rule is allowed to prove uniqueness — it is a search, and that is
  /// what a search is for — but it is not allowed to be the *only* way in. A
  /// board whose player rules stop dead and whose answer needs a machine to
  /// find is not a puzzle, it is a lookup, so [solvingLevel] ignores level 3.
  bool _proven(MathraxPuzzle puzzle) {
    final count = countSolutions(
      MathraxModel.fresh(puzzle),
      mathraxPlayerRules,
      limit: 2,
    );
    if (!count.isUnique) return false;
    return solvingLevel(MathraxModel.fresh(puzzle), mathraxPlayerRules) != null;
  }

  /// The most restrictive clue that is true at one corner.
  ///
  /// `E` and `O` beat any arithmetic because they say one thing about four
  /// cells; `=` is the rarest and the strongest; the operations come last, and
  /// among them the one that reads most naturally from the four digits is
  /// picked at random so the boards do not all show additions.
  MathraxClue? _clueFor(
    MathraxSize size,
    List<int> answer,
    int row,
    int col,
    Random rng,
  ) {
    final n = size.n;
    final cells = [
      answer[row * n + col],
      answer[row * n + col + 1],
      answer[(row + 1) * n + col],
      answer[(row + 1) * n + col + 1],
    ];
    final a = cells[0], b = cells[1], c = cells[2], d = cells[3];
    if (cells.every((digit) => digit.isEven)) {
      return const MathraxClue(MathraxOp.even);
    }
    if (cells.every((digit) => digit.isOdd)) {
      return const MathraxClue(MathraxOp.odd);
    }
    if (a == d && b == c) return const MathraxClue(MathraxOp.equal);

    final options = <MathraxClue>[];
    if (a + d == b + c) options.add(MathraxClue(MathraxOp.add, a + d));
    if ((a - d).abs() == (b - c).abs()) {
      options.add(MathraxClue(MathraxOp.sub, (a - d).abs()));
    }
    if (a * d == b * c) options.add(MathraxClue(MathraxOp.mul, a * d));
    final dl = a > d ? a : d, ds = a > d ? d : a;
    final cl = b > c ? b : c, cs = b > c ? c : b;
    if (ds > 0 && cs > 0 && dl % ds == 0 && cl % cs == 0 &&
        dl ~/ ds == cl ~/ cs) {
      options.add(MathraxClue(MathraxOp.div, dl ~/ ds));
    }
    if (options.isEmpty) return null;
    options.shuffle(rng);
    return options.first;
  }

  /// How many answers [puzzle] has, at most two.
  int count(MathraxPuzzle puzzle) =>
      countSolutions(MathraxModel.fresh(puzzle), mathraxPlayerRules).count;

  /// The lowest rule level that finishes [puzzle], or null when it needs a
  /// guess. Level 3 is the exact search, so the board the app reports is the
  /// depth a player actually has to reach.
  int? levelOf(MathraxPuzzle puzzle) =>
      solvingLevel(MathraxModel.fresh(puzzle), mathraxPlayerRules);

  /// A cell and digit the rules prove.
  ///
  /// It returns a value to write; the board decides how to show it. A hint that
  /// only outlined a cell would leave the player exactly where they were.
  MathraxHint? hint(MathraxPuzzle puzzle, List<int> values) {
    final model = MathraxModel.fresh(puzzle);
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      if (values[cell] == kMathraxBlank) continue;
      if (model.set(cell, values[cell]) < 0) return null;
    }
    final outcome = deduce(model, mathraxPlayerRules);
    if (!outcome.consistent) return null;
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      if (values[cell] != kMathraxBlank) continue;
      // `digitAt` answers 0 unless the cell is down to one digit. Asking a mask
      // for `bitLength == 1` looks the same and is not: that matches digit 1 and
      // nothing else, which made every hint a 1.
      final digit = model.digitAt(cell);
      if (digit != kMathraxBlank) return MathraxHint(cell, digit);
    }
    return null;
  }

  /// Whether [values] is the answer, on the board as the player sees it.
  bool isSolved(MathraxPuzzle puzzle, List<int> values) =>
      puzzle.isSolution(values);
}

/// A proved cell.
class MathraxHint {
  const MathraxHint(this.cell, this.digit);

  final int cell;
  final int digit;
}
