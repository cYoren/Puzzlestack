/// Crossing's generator: cut a skeleton of runs, fill it with digits, and read
/// the number list off the runs.
///
/// The order is the source's, and it is the right order: the answer comes first,
/// then the list is *read off* the answer, so a number can never lie about a
/// board it was not taken from. Then the list is proved: exactly one filling, and
/// one a player can reach with the rules a player has. A board whose only way in
/// is the search is not dealt.
///
/// Two steps are tried independently, because they fail for different reasons
/// and one is much cheaper to retry than the other:
///
///  * the **skeleton** — where the runs go. A run is only cut where it can be
///    the whole run (nothing in its own direction touches either end), every run
///    after the first crosses the rest, and no two numbers of the list come out
///    the same.
///  * the **digits** — a random digit per cell, which is what decides whether the
///    crossings pin the answer down. A digit draw the crossings leave ambiguous
///    is thrown away, so one skeleton gets several before it is dropped: a board
///    is dealt in about a millisecond at every size.
library;

import 'dart:math';
import 'dart:math' as math;

import '../../../../core/deduction.dart';
import 'crossing_model.dart';
import 'crossing_puzzle.dart';

/// What a board is worth, so the generator never ships a shrug.
class CrossingEngine {
  const CrossingEngine();

  /// A board at [size]. Throws rather than ship one it could not prove: a wrong
  /// board is worse than a missing one.
  ///
  /// [attempts] is the skeleton budget and [digitTries] how many digitings each
  /// skeleton gets. Both are set from measurement, not from hope: a dealt board
  /// costs about one millisecond at every size.
  CrossingPuzzle generate(
    CrossingSize size, {
    Random? random,
    int attempts = 400,
    int digitTries = 30,
  }) {
    final rng = random ?? Random();
    for (var attempt = 0; attempt < attempts; attempt++) {
      final lengths = _lengths(size, rng);
      final runs = _skeleton(size, lengths, rng);
      if (runs == null) continue;
      for (var draw = 0; draw < digitTries; draw++) {
        final puzzle = _deal(size, runs, rng);
        if (puzzle == null) continue;
        if (!_proven(puzzle)) continue;
        return puzzle;
      }
    }
    throw StateError(
      'could not build a provable ${size.n}x${size.n} Crossing board '
      'in $attempts skeletons',
    );
  }

  /// How many numbers one skeleton is cut for, and how long each is.
  ///
  /// The list has to be long enough that the crossings constrain each other, and
  /// short enough that the chips still fit under the board on a phone. Lengths
  /// lean towards three digits: a two-digit number shares one digit at a
  /// crossing, which is barely a constraint.
  List<int> _lengths(CrossingSize size, Random rng) {
    final count =
        size.minNumbers + rng.nextInt(size.maxNumbers - size.minNumbers + 1);
    return [
      for (var i = 0; i < count; i++)
        rng.nextInt(3) == 0 ? kCrossingLengths[0] : kCrossingLengths[1],
    ];
  }

  /// A skeleton of [lengths.length] runs, each crossing the ones already there.
  ///
  /// A run is only cut where it can be the whole run: no other run in its own
  /// direction may touch or overlap it, or the two would read as one longer
  /// number, and every cell of it is checked. Runs in the two directions do
  /// share cells — that is a crossing, and it is the whole game.
  ///
  /// Null when this draw of lengths does not fit the grid, which is common and
  /// cheap: the caller rolls another.
  List<CrossingRun>? _skeleton(
    CrossingSize size,
    List<int> lengths,
    Random rng,
  ) {
    final n = size.n;
    final across = List<bool>.filled(size.cellCount, false);
    final down = List<bool>.filled(size.cellCount, false);
    final runs = <CrossingRun>[];

    for (var index = 0; index < lengths.length; index++) {
      final length = lengths[index];
      final candidates = <CrossingRun>[];
      for (final horizontal in [true, false]) {
        final own = horizontal ? across : down;
        final other = horizontal ? down : across;
        for (var start = 0; start < size.cellCount; start++) {
          final row = start ~/ n;
          final col = start % n;
          if (horizontal ? col + length > n : row + length > n) continue;
          final cells = [
            for (var i = 0; i < length; i++)
              horizontal ? start + i : start + i * n,
          ];
          final last = cells.last;
          var ok = true;
          for (final cell in cells) {
            // Two runs in the same direction never share a cell: one digit per
            // cell, one member.
            if (own[cell]) ok = false;
          }
          if (!ok) continue;
          // The run has to be the *whole* run: a cell of the same direction
          // touching either end would join it into one longer number.
          if (horizontal) {
            if (col > 0 && across[start - 1]) ok = false;
            if (col + length < n && across[last + 1]) ok = false;
          } else {
            if (row > 0 && down[start - n]) ok = false;
            if (row + length < n && down[last + n]) ok = false;
          }
          if (!ok) continue;
          // Every run after the first has to cross the skeleton, which is what
          // keeps it one number skeleton and not a scatter of numbers.
          if (index > 0 && !cells.any((cell) => other[cell])) continue;
          candidates.add(CrossingRun(
            start: start,
            length: length,
            horizontal: horizontal,
          ));
        }
      }
      if (candidates.isEmpty) return null;
      // The first run is anywhere; every one after it is pushed away from what
      // is already there, so the skeleton spreads across the grid instead of
      // bunching in a corner and leaving the rest of the board empty wall.
      final chosen = index == 0
          ? candidates[rng.nextInt(candidates.length)]
          : _spread(candidates, across, down, size, rng);
      for (final cell in chosen.cells(n)) {
        (chosen.horizontal ? across : down)[cell] = true;
      }
      runs.add(chosen);
    }

    // The runs that were cut have to be the runs the cells describe, or the
    // board would show two numbers that read as one longer number.
    return _maximalRuns(size, across, down).join(',') ==
            _signature(runs).join(',')
        ? runs
        : null;
  }

  /// One of [candidates], preferring the far ones: the top third by how far
  /// their furthest cell reaches from the middle of what is already covered.
  CrossingRun _spread(
    List<CrossingRun> candidates,
    List<bool> across,
    List<bool> down,
    CrossingSize size,
    Random rng,
  ) {
    final n = size.n;
    var rowSum = 0.0;
    var colSum = 0.0;
    var count = 0;
    for (var cell = 0; cell < size.cellCount; cell++) {
      if (!across[cell] && !down[cell]) continue;
      rowSum += cell ~/ n;
      colSum += cell % n;
      count++;
    }
    if (count == 0) return candidates[rng.nextInt(candidates.length)];
    final midRow = rowSum / count;
    final midCol = colSum / count;
    final scored = [
      for (final run in candidates)
        (
          run,
          run.cells(n).fold<double>(0, (far, cell) {
            final dr = (cell ~/ n) - midRow;
            final dc = (cell % n) - midCol;
            return math.max(far, dr * dr + dc * dc);
          }),
        )
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final pick =
        rng.nextInt((scored.length / 3).ceil().clamp(1, scored.length));
    return scored[pick].$1;
  }

  /// The maximal runs of each direction, as a comparable signature. Runs are
  /// read per direction: the cell where two of them cross belongs to both.
  List<String> _maximalRuns(
    CrossingSize size,
    List<bool> across,
    List<bool> down,
  ) {
    final n = size.n;
    final found = <String>[];
    for (var row = 0; row < n; row++) {
      var col = 0;
      while (col < n) {
        final cell = row * n + col;
        if (!across[cell]) {
          col++;
          continue;
        }
        var length = 1;
        while (col + length < n && across[cell + length]) {
          length++;
        }
        if (length > 1) found.add('h$cell/$length');
        col += length;
      }
    }
    for (var col = 0; col < n; col++) {
      var row = 0;
      while (row < n) {
        final cell = row * n + col;
        if (!down[cell]) {
          row++;
          continue;
        }
        var length = 1;
        while (row + length < n && down[cell + length * n]) {
          length++;
        }
        if (length > 1) found.add('v$cell/$length');
        row += length;
      }
    }
    return found..sort();
  }

  List<String> _signature(List<CrossingRun> runs) => [
        for (final run in runs)
          '${run.horizontal ? 'h' : 'v'}${run.start}/${run.length}',
      ]..sort();

  /// A random filling of [runs], and the list read off it. Null when two runs
  /// come out as the same number, which the list cannot hold twice.
  CrossingPuzzle? _deal(
    CrossingSize size,
    List<CrossingRun> runs,
    Random rng,
  ) {
    final solution = List<int>.filled(size.cellCount, kCrossingEmpty);
    for (final run in runs) {
      for (final cell in run.cells(size.n)) {
        // A crossing cell keeps the digit the first run gave it: that is the
        // whole point of a crossing.
        if (solution[cell] == kCrossingEmpty) {
          solution[cell] = 1 + rng.nextInt(9);
        }
      }
    }
    final texts = [
      for (final run in runs)
        [
          for (final cell in run.cells(size.n)) '${solution[cell]}',
        ].join(),
    ];
    if (texts.toSet().length != texts.length) return null;
    // Shortest first, then by digits, the way the source sorts its list: the
    // chips read as a set, not as the order the skeleton happened to be cut in.
    final numbers = [...texts]..sort((a, b) {
        if (a.length != b.length) return a.length - b.length;
        return a.compareTo(b);
      });
    return CrossingPuzzle(
      size: size,
      numbers: numbers,
      runs: runs,
      solution: solution,
    );
  }

  /// Exactly one filling, and reachable with the rules a player has.
  ///
  /// The exact rule is allowed to prove uniqueness — it is a search, and that is
  /// what a search is for — but it is not allowed to be the *only* way in, so
  /// [solvingLevel] is asked with the player rules only. A board whose crossings
  /// stop dead is not a puzzle, it is a lookup.
  bool _proven(CrossingPuzzle puzzle) {
    final count = countSolutions(
      CrossingModel.fresh(puzzle),
      crossingPlayerRules,
      limit: 2,
    );
    if (count.truncated || !count.isUnique) return false;
    return solvingLevel(CrossingModel.fresh(puzzle), crossingPlayerRules) !=
        null;
  }

  /// How many fillings [puzzle] has, at most two.
  int count(CrossingPuzzle puzzle) =>
      countSolutions(CrossingModel.fresh(puzzle), crossingPlayerRules).count;

  /// The lowest rule level that finishes [puzzle], or null when it needs a
  /// guess. Level 3 is the exact search, so the number the app reports is the
  /// depth a player actually has to reach.
  int? levelOf(CrossingPuzzle puzzle) =>
      solvingLevel(CrossingModel.fresh(puzzle), crossingPlayerRules);

  /// Something the rules prove and the player has not written, or null.
  ///
  /// A number the rules have placed is preferred over a single proved cell: the
  /// game's unit is the number, and being told "the 471 is here" is one step,
  /// where three cells would be three. Every digit returned is the one the rules
  /// proved, never a peek at the answer.
  CrossingHint? hint(CrossingPuzzle puzzle, List<int> values) {
    final model = CrossingModel.fresh(puzzle);
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final value = cell < values.length ? values[cell] : kCrossingEmpty;
      if (value == kCrossingEmpty) continue;
      if (model.restrict(cell, value) < 0) return null;
    }
    final outcome = deduce(model, crossingPlayerRules);
    if (!outcome.consistent) return null;

    for (var number = 0; number < model.numberCount; number++) {
      if (!model.isPlaced(number)) continue;
      final cells = puzzle.runCells(model.placementsOf(number).single);
      final write = <int>[];
      final digits = <int>[];
      for (final cell in cells) {
        if (cell < values.length && values[cell] != kCrossingEmpty) continue;
        final digit = model.digitAt(cell);
        if (digit == kCrossingEmpty) continue;
        write.add(cell);
        digits.add(digit);
      }
      // A placed number whose cells are all proved: write the lot at once, which
      // is one step of the game rather than three of the grid.
      if (write.isNotEmpty) return CrossingHint(write, digits);
    }

    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      if (cell < values.length && values[cell] != kCrossingEmpty) continue;
      final digit = model.digitAt(cell);
      if (digit == kCrossingEmpty) continue;
      return CrossingHint([cell], [digit]);
    }
    return null;
  }

  /// Whether [values] is the answer, on the board as the player sees it: every
  /// listed number once, and no digit outside a placement.
  bool isSolved(CrossingPuzzle puzzle, List<int> values) =>
      puzzle.isSolution(values);
}

/// A proved step: cells to write, and the digits to write in them.
class CrossingHint {
  const CrossingHint(this.cells, this.digits);

  final List<int> cells;
  final List<int> digits;
}
