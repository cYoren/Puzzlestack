import 'dart:math';

import '../../../../core/deduction.dart';
import 'seismic_model.dart';
import 'seismic_puzzle.dart';

export 'seismic_puzzle.dart';

/// Seismic: Ripple Effect.
///
/// The generator makes a legal answer first, cuts it into regions that hold
/// the digits they promise, and only then decides how much of it to print. A
/// board ships when the clues alone finish it: the rules in
/// [seismicDeductionRules] reach every cell without a guess. That is a stronger
/// promise than "unique", and it is the one the bar asks for.
class SeismicEngine {
  const SeismicEngine();

  // --------------------------------------------------------------- generator

  /// One board, or a throw.
  ///
  /// Retrying is the design: most random fills cannot be cut into regions that
  /// each hold exactly 1..size, and most clue sets are not minimal. A board
  /// that cannot be proved is thrown away, never patched with extra clues.
  SeismicPuzzle generate(
    SeismicSize size, {
    Random? random,
    int attempts = 120,
  }) {
    final rng = random ?? Random();
    for (var attempt = 0; attempt < attempts; attempt++) {
      final seed = _build(size, rng);
      if (seed == null) continue;
      final puzzle = _cutClues(seed, rng);
      if (puzzle.givenCount() == 0) continue;
      return puzzle;
    }
    throw StateError(
      'could not build a solvable ${size.n}x${size.n} Seismic board in '
      '$attempts attempts',
    );
  }

  /// Counts the answers the clues allow, by the complete search.
  SeismicCount count(SeismicPuzzle puzzle, {int limit = 2}) => SeismicSearch(
        puzzle: puzzle,
        masks: SeismicModel.fresh(puzzle).masks,
        limit: limit,
        budget: 2000000,
      ).run();

  /// True when the player's digits are a legal answer that agrees with every
  /// clue.
  bool isSolved(SeismicPuzzle puzzle, List<int> values) =>
      puzzle.isSolved(values);

  /// The rule level the clues need, or null when a guess is needed.
  int? levelOf(SeismicPuzzle puzzle) =>
      solvingLevel(SeismicModel.fresh(puzzle), seismicRules);

  /// A cell the rules can prove, and the digit it must hold.
  ///
  /// The value is what the player should write, so the caller can put it on
  /// the board: a hint that only outlines a cell tells the player nothing about
  /// which digit goes in it.
  ({int cell, int digit})? hint(SeismicPuzzle puzzle, List<int> values) {
    final model = SeismicModel.fresh(puzzle);
    final outcome = deduce(model, seismicDeductionRules);
    final proved = <int, int>{};
    if (outcome.consistent) {
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        final digit = model.digitAt(cell);
        if (digit != 0) proved[cell] = digit;
      }
    }
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final digit = proved[cell] ?? puzzle.solution[cell];
      if (values[cell] == digit) continue;
      return (cell: cell, digit: digit);
    }
    return null;
  }

  // ---------------------------------------------------------------- internals

  /// Cuts the grid into regions, then finds a legal answer for that cut.
  ///
  /// Cutting first is the difference between a generator that works and one
  /// that does not: the C collection merges digits into regions and rejects the
  /// whole board when a region comes out missing a digit, which at 6x6 is
  /// almost every time. A contiguous partition into regions of equal size is
  /// always legal shape-wise, and an answer for it is a search over digits
  /// rather than a lottery over layouts.
  SeismicPuzzle? _build(SeismicSize size, Random rng) {
    final n = size.n;
    final regionSizes = List<int>.filled(n, n);
    for (var attempt = 0; attempt < 40; attempt++) {
      final regions = _partition(size, rng);
      if (regions == null) continue;

      final blank = SeismicPuzzle(
        size: size,
        regions: regions,
        regionSizes: regionSizes,
        givens: List<int>.filled(size.cellCount, kSeismicNoClue),
        solution: List<int>.filled(size.cellCount, kSeismicBlank),
      );
      final found = SeismicSearch(
        puzzle: blank,
        masks: SeismicModel.fresh(blank).masks,
        limit: 1,
        budget: 2000,
      ).run();
      if (found.truncated || found.solutions == 0) continue;
      // One answer, read out of the search: `forced` is the *proof* cell and
      // needs an exhaustive enumeration, which a fill search deliberately does
      // not do.
      final digits = found.first;
      if (digits.isEmpty || digits.any((digit) => digit == 0)) continue;

      final seed = SeismicPuzzle(
        size: size,
        regions: regions,
        regionSizes: regionSizes,
        givens: List<int>.from(digits),
        solution: digits,
      );
      if (!seed.isLegal(digits)) continue;
      return seed;
    }
    return null;
  }

  /// Grows [SeismicSize.n] connected regions of that many cells each.
  ///
  /// Every region is grown from its own seed and takes the neighbour of a
  /// random cell it already owns, so connectivity is by construction. A region
  /// that runs out of neighbours while it still owes cells means the cut
  /// failed; the caller tries another one instead of bending the rule.
  List<int>? _partition(SeismicSize size, Random rng) {
    final n = size.n;
    final total = n * n;
    final region = List<int>.filled(total, -1);
    final owned = List<int>.filled(n, 0);
    final frontier = [for (var i = 0; i < n; i++) <int>{}];

    final seeds = <int>{};
    while (seeds.length < n) {
      seeds.add(rng.nextInt(total));
    }

    void grow(int index, int cell) {
      final row = cell ~/ n;
      final col = cell % n;
      for (final (r, c) in [
        (row - 1, col),
        (row + 1, col),
        (row, col - 1),
        (row, col + 1)
      ]) {
        if (r < 0 || r >= n || c < 0 || c >= n) continue;
        final other = r * n + c;
        if (region[other] == -1) frontier[index].add(other);
      }
    }

    var index = 0;
    for (final seed in seeds) {
      region[seed] = index;
      owned[index] = 1;
      grow(index, seed);
      index++;
    }

    var assigned = n;
    while (assigned < total) {
      // Grow the smallest region that can grow: it is the one most likely to
      // be walled in later, so it gets the room while it is still there.
      final open = [
        for (var r = 0; r < n; r++)
          if (owned[r] < n && frontier[r].isNotEmpty) r,
      ];
      if (open.isEmpty) return null;
      open.sort((a, b) => owned[a].compareTo(owned[b]));
      final smallest = owned[open.first];
      final tied = open.where((r) => owned[r] == smallest).toList();
      final which = tied[rng.nextInt(tied.length)];

      final choices = frontier[which].toList()..shuffle(rng);
      int? cell;
      for (final candidate in choices) {
        if (region[candidate] != -1) {
          frontier[which].remove(candidate);
          continue;
        }
        cell = candidate;
        break;
      }
      if (cell == null) {
        frontier[which].clear();
        continue;
      }
      frontier[which].remove(cell);
      region[cell] = which;
      owned[which]++;
      assigned++;
      grow(which, cell);
    }
    return region;
  }

  /// Removes clues while the board stays finishable by reasoning.
  ///
  /// Starting from every cell printed and taking clues away is the only way to
  /// know the set is tight without guessing at a clue count: a clue that the
  /// other clues make redundant is removed, and one that carries information
  /// stays.
  SeismicPuzzle _cutClues(SeismicPuzzle seed, Random rng) {
    final givens = List<int>.from(seed.solution);
    final order = List<int>.generate(seed.cellCount, (i) => i)..shuffle(rng);

    SeismicPuzzle withGivens() => SeismicPuzzle(
          size: seed.size,
          regions: seed.regions,
          regionSizes: seed.regionSizes,
          givens: givens,
          solution: seed.solution,
        );

    for (final cell in order) {
      final saved = givens[cell];
      givens[cell] = kSeismicNoClue;
      final outcome =
          deduce(SeismicModel.fresh(withGivens()), seismicDeductionRules);
      if (!outcome.consistent || !outcome.complete) givens[cell] = saved;
    }
    return withGivens();
  }
}
