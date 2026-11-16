/// Bricks' generator: a random legal pile, its numbers, then the fewest numbers
/// that still prove it.
///
/// The order is the same one Salad uses, and for the same reason. The shading
/// comes first — a random pattern that already obeys rules 1 and 2, built from
/// the bottom row up so a shaded cell can only be added where something below
/// it holds it up. The numbers are then **read off** that shading, so a number
/// cannot lie about a board it was not made from. Then numbers are dropped one
/// at a time, in random order, and a drop is kept only while the board still
/// proves itself: exactly one answer, and finishable with the rules a player
/// has (levels 1 and 2, never the exact search).
///
/// A board whose only way in is the search is not dealt, and a board that
/// cannot be proved at all is not patched with an extra clue: the attempt is
/// thrown away and another pattern is rolled.
library;

import 'dart:math';

import '../../../../core/deduction.dart';
import 'bricks_model.dart';
import 'bricks_puzzle.dart';

export 'bricks_puzzle.dart';

/// What a board is worth, so the generator never ships a shrug.
class BricksEngine {
  const BricksEngine();

  /// The least share of the board that must be shaded.
  ///
  /// Not a rule, a judgement: a pattern with one shaded corner makes a legal
  /// board and a dull card, because the numbers then repeat the same small
  /// count everywhere. The C enforces the same thing (`MINIMUM_SHADED 0.4`).
  static const double minimumShaded = 0.4;

  /// A board at [size]. Throws rather than ship one it could not prove: a wrong
  /// board is worse than a missing one.
  ///
  /// [attempts] is a budget, not a target — the loop returns on its first
  /// success, so a size that deals easily never pays for it.
  BricksPuzzle generate(
    BricksSize size, {
    Random? random,
    int attempts = 400,
  }) {
    final rng = random ?? Random();
    for (var attempt = 0; attempt < attempts; attempt++) {
      final pattern = _pattern(size, rng);

      final shaded = pattern.where((value) => value == kBricksShaded).length;
      if (shaded / size.cellCount < minimumShaded) continue;

      final full = _numbered(size, pattern);
      if (!_proven(full)) continue;

      final puzzle = _strip(full, rng);
      if (_proven(puzzle)) return puzzle;
    }
    throw StateError(
      'could not build a provable ${size.rows}x${size.cols} Bricks board '
      'in $attempts attempts',
    );
  }

  /// A random pattern that already obeys rules 1 and 2, from the bottom up.
  ///
  /// `bricks_fill_grid`: walk each row left to right, and shade a cell only when
  /// the run of shaded cells so far is shorter than two and (outside the bottom
  /// row) one of the two cells under it is already shaded. Both rules are
  /// therefore true of the pattern by construction, so what is left to prove is
  /// only that the numbers pin it down.
  List<int> _pattern(BricksSize size, Random rng) {
    final lattice = BricksLattice(size);
    final grid = List<int>.filled(size.cellCount, kBricksUnshaded);

    for (var y = size.rows - 1; y >= 0; y--) {
      var run = 0;
      for (var x = lattice.leftmost(y); x <= lattice.rightmost(y); x++) {
        final cell = lattice.cellAt(y, x)!;
        // The cells below are already decided: the walk is bottom-up, so the
        // question "is there support" always has an answer.
        var held = y == size.rows - 1;
        for (final under in lattice.below(cell)) {
          if (grid[under] == kBricksShaded) held = true;
        }
        // Not shading is the default (1 in 3 even when shading is allowed),
        // which is what keeps runs broken up and the pile readable.
        if (!held || run == 2 || rng.nextInt(3) == 0) {
          grid[cell] = kBricksUnshaded;
          run = 0;
        } else {
          grid[cell] = kBricksShaded;
          run++;
        }
      }
    }
    return grid;
  }

  /// [pattern] with a number on every cell that is not shaded.
  ///
  /// `bricks_build_numbers`: the count is over the six neighbours that exist,
  /// so a cell on the edge of the honeycomb prints a smaller number than one in
  /// the middle, and off-board neighbours count as unshaded.
  BricksPuzzle _numbered(BricksSize size, List<int> pattern) {
    final bare = BricksPuzzle(
      size: size,
      clues: List<int>.filled(size.cellCount, kBricksNoClue),
      solution: pattern,
    );
    return BricksPuzzle(
      size: size,
      clues: [
        for (var cell = 0; cell < size.cellCount; cell++)
          pattern[cell] == kBricksShaded
              ? kBricksNoClue
              : bare.shadedAround(pattern, cell),
      ],
      solution: pattern,
    );
  }

  /// [puzzle] with as many numbers dropped as still prove it.
  ///
  /// Random order, so two boards of the same size do not keep the same numbers.
  BricksPuzzle _strip(BricksPuzzle puzzle, Random rng) {
    final order = [for (var cell = 0; cell < puzzle.cellCount; cell++) cell]
      ..shuffle(rng);
    var current = puzzle;
    for (final cell in order) {
      if (!current.hasClue(cell)) continue;
      final clues = [...current.clues]..[cell] = kBricksNoClue;
      final candidate = BricksPuzzle(
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
  /// The player rules stop at level 2, so a board that passes this is solvable
  /// without a guess and without the exact search — both halves of the bar in
  /// one check. The answer itself must also be legal, which is where a rule the
  /// generator got wrong would surface.
  bool _proven(BricksPuzzle puzzle) {
    if (!puzzle.isLegal(puzzle.solution)) return false;
    final count = countSolutions(
      BricksModel.fresh(puzzle),
      bricksPlayerRules,
      limit: 2,
    );
    if (count.truncated || !count.isUnique) return false;
    return solvingLevel(BricksModel.fresh(puzzle), bricksPlayerRules) != null;
  }

  /// How many answers [puzzle] has, at most two, counted by the complete search.
  BricksCount count(BricksPuzzle puzzle, {int limit = 2}) => BricksSearch(
        puzzle: puzzle,
        masks: BricksModel.fresh(puzzle).masks,
        limit: limit,
        budget: 2000000,
      ).run();

  /// The lowest rule level that finishes [puzzle], or null when it needs a
  /// guess. Level 3 is the exact search, so the number the app reports is the
  /// depth a player actually has to reach.
  int? levelOf(BricksPuzzle puzzle) =>
      solvingLevel(BricksModel.fresh(puzzle), bricksPlayerRules);

  /// A cell and shading the rules prove, or null when the rules have run out.
  ///
  /// It returns a value to write, not a cell to look at: a hint that only
  /// outlined a cell would leave the player exactly where they were. The proof
  /// is read from the clues; the answer is the fallback for a cell the rules
  /// cannot reach, which a dealt board never has.
  BricksHint? hint(BricksPuzzle puzzle, List<int> values) {
    final model = BricksModel.fresh(puzzle);
    final outcome = deduce(model, bricksPlayerRules);
    final proved = <int, int>{};
    if (outcome.consistent) {
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        final shading = model.shadingAt(cell);
        if (shading != null) proved[cell] = shading;
      }
    }
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final shading = proved[cell] ?? puzzle.solution[cell];
      if (values[cell] == shading) continue;
      return BricksHint(cell, shading);
    }
    return null;
  }

  /// Whether [values] is a legal shading: every number true, nothing floating,
  /// no run of three.
  bool isSolved(BricksPuzzle puzzle, List<int> values) =>
      puzzle.isLegal(values);
}

/// A proved cell.
class BricksHint {
  const BricksHint(this.cell, this.shading);

  final int cell;

  /// [kBricksShaded] or [kBricksUnshaded].
  final int shading;
}
