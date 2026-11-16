/// Crossing as a deduction board.
///
/// **The objects are the numbers, not the cells.** That is the whole shape of
/// this port: a cell-domain model (what digit may this cell hold?) cannot see the
/// one thing the player sees, which is that a *number* is in one place and only
/// one, so two cells of it are decided together. So the board is:
///
///  * per number, the set of runs it can still occupy, as a bitmask over runs —
///    and a run already *is* a top-left cell plus a direction, with the number's
///    length deciding where it ends;
///  * a grid of digit domains, one 9-bit mask per cell, which is the only thing
///    the runs share: a run says which digits it would put in its cells, and a
///    cell takes the digits every run through it agrees on.
///
/// Everything follows from those two. A number with one run left is placed; a
/// cell whose domain is down to one digit has that digit; a run with one number
/// left takes it; a number with no run left, or a run with no number left, is a
/// contradiction. The last rule is the exact search over placements, so
/// "exactly one filling" and "finishable without a guess" are both statements
/// this file can make.
///
/// Masks are `int` bits and the largest board has ten numbers over at most
/// sixteen runs, with nine digits: well inside 32-bit integer semantics, which
/// the web build truncates to. Nothing here shifts by more than 31.
library;

import '../../../../core/deduction.dart';
import 'crossing_puzzle.dart';

/// The bit for [digit]: bits 1..9, so digit `d` is `1 << d` and no bit means
/// "this cell cannot be a digit at all".
int crossingDigitBit(int digit) => 1 << digit;

/// Every digit a cell can hold, `1..9`.
const int kCrossingFullDomain = 0x3FE;

int _popCount(int mask) {
  var count = 0;
  while (mask != 0) {
    mask &= mask - 1;
    count++;
  }
  return count;
}

/// The index of the lowest set bit of [mask].
///
/// Not `mask.bitLength - 1`, which is the *highest* bit: a mask of two runs
/// walked that way visits its top run twice and never its bottom one, which is a
/// model that silently decides the wrong things.
int _lowestBit(int mask) => (mask & -mask).bitLength - 1;

/// Every run whose length is [length], as a bitmask.
int _runsOfLength(CrossingPuzzle puzzle, int length) {
  var mask = 0;
  for (var run = 0; run < puzzle.runCount; run++) {
    if (puzzle.runs[run].length == length) mask |= 1 << run;
  }
  return mask;
}

class CrossingModel implements DeductionModel<CrossingModel> {
  CrossingModel({
    required this.puzzle,
    required this.placements,
    required this.domains,
    this.broken = false,
  });

  /// A fresh board: every number may take every run of its own length, and
  /// every cell may hold any digit.
  factory CrossingModel.fresh(CrossingPuzzle puzzle) => CrossingModel(
        puzzle: puzzle,
        placements: [
          for (final number in puzzle.numbers)
            _runsOfLength(puzzle, number.length),
        ],
        domains: [
          for (var cell = 0; cell < puzzle.cellCount; cell++)
            puzzle.isWall(cell) ? 0 : kCrossingFullDomain,
        ],
      );

  final CrossingPuzzle puzzle;

  /// Per number, the runs it can still occupy: bit `r` is run `r`.
  final List<int> placements;

  /// Per cell, the digits it can still hold: bit `d` is the digit `d`. A wall
  /// holds zero, which is how "no digit" is spelled everywhere in this game.
  final List<int> domains;

  bool broken;

  int get n => puzzle.n;

  int get cellCount => puzzle.cellCount;

  int get runCount => puzzle.runCount;

  int get numberCount => placements.length;

  @override
  CrossingModel copy() => CrossingModel(
        puzzle: puzzle,
        placements: List<int>.from(placements),
        domains: List<int>.from(domains),
        broken: broken,
      );

  /// Runs a number can still take, in run order.
  List<int> placementsOf(int number) {
    final runs = <int>[];
    var mask = placements[number];
    while (mask != 0) {
      runs.add(_lowestBit(mask));
      mask &= mask - 1;
    }
    return runs;
  }

  /// How many runs a number can still take.
  int placementCount(int number) => _popCount(placements[number]);

  /// True when the rules have put this number in exactly one run.
  bool isPlaced(int number) =>
      placements[number].bitLength > 0 && _popCount(placements[number]) == 1;

  /// The digit of a cell that is down to one, or [kCrossingEmpty].
  int digitAt(int cell) => _popCount(domains[cell]) == 1
      ? _lowestBit(domains[cell])
      : kCrossingEmpty;

  bool isDecided(int cell) => _popCount(domains[cell]) == 1;

  /// The board as the player would see it: a digit where one is proved, and
  /// nothing anywhere else. A wall is nothing in both senses.
  List<int> get values =>
      [for (var cell = 0; cell < cellCount; cell++) digitAt(cell)];

  @override
  bool get isComplete {
    if (broken) return false;
    for (var cell = 0; cell < cellCount; cell++) {
      if (puzzle.isWall(cell)) continue;
      if (!isDecided(cell)) return false;
    }
    // Decided and correct are two questions, and the counter trusts this one.
    return puzzle.isSolution(values);
  }

  @override
  Choice? get choice {
    // The cheapest number to guess, in the number's own vocabulary: which run
    // does it go in. Guessing over cells would be guessing the answer twice
    // removed from the object the player is actually moving.
    var best = -1;
    var bestCount = 99;
    for (var number = 0; number < numberCount; number++) {
      final count = _popCount(placements[number]);
      if (count < 2 || count >= bestCount) continue;
      best = number;
      bestCount = count;
    }
    if (best < 0) return null;
    return Choice(best, placementsOf(best));
  }

  @override
  CrossingModel assume(int slot, int value) {
    final next = copy();
    if (next.place(slot, value) < 0) next.broken = true;
    return next;
  }

  /// Takes run [run] away from [number]. 1 when that was news, 0 when it was
  /// already gone, -1 when the number would be left with nowhere to go.
  int _kill(int number, int run) {
    final bit = 1 << run;
    final mask = placements[number];
    if (mask & bit == 0) return 0;
    if (mask == bit) {
      // A number with no run left cannot be in the answer, so this branch is a
      // contradiction, not a dead end to work around.
      broken = true;
      return -1;
    }
    placements[number] = mask & ~bit;
    return 1;
  }

  /// Puts [number] in [run]: every other run it could have taken is gone, and so
  /// is every other number from that run.
  int place(int number, int run) {
    final bit = 1 << run;
    if (placements[number] & bit == 0) {
      broken = true;
      return -1;
    }
    var news = 0;
    if (placements[number] != bit) {
      placements[number] = bit;
      news++;
    }
    for (var other = 0; other < numberCount; other++) {
      if (other == number) continue;
      final killed = _kill(other, run);
      if (killed < 0) return -1;
      news += killed;
    }
    return news;
  }

  /// Narrows one cell to [digit]. Used by the exact rule and by the hint, both
  /// of which have already proved the digit; it is not a rule of its own.
  int restrict(int cell, int digit) {
    if (puzzle.isWall(cell)) {
      broken = true;
      return -1;
    }
    final bit = crossingDigitBit(digit);
    if (domains[cell] & bit == 0) {
      broken = true;
      return -1;
    }
    if (domains[cell] == bit) return 0;
    domains[cell] = bit;
    return 1;
  }

  /// **The crossings.** Each run says which digits its live numbers would put in
  /// each of its cells; a cell takes the digits that every run through it
  /// allows. That intersection is the whole shared constraint, and it is why a
  /// crossing is worth drawing: two runs that agree on one digit decide it, and a
  /// decided digit then rules out every number that would have written something
  /// else there.
  ///
  /// Level 1: it is the first thing anyone does with a number skeleton.
  int sweepDigits() {
    if (broken) return -1;
    var news = 0;
    var moved = true;
    while (moved) {
      moved = false;

      // Which numbers can still be in each run, and the digits they allow at
      // every position of it.
      final live = List<int>.filled(runCount, 0);
      final allowed = [
        for (final run in puzzle.runs) List<int>.filled(run.length, 0),
      ];
      for (var number = 0; number < numberCount; number++) {
        final mask = placements[number];
        if (mask == 0) {
          broken = true;
          return -1;
        }
        final text = puzzle.numbers[number];
        var left = mask;
        while (left != 0) {
          final run = _lowestBit(left);
          live[run] |= 1 << number;
          for (var pos = 0; pos < text.length; pos++) {
            allowed[run][pos] |= crossingDigitBit(text.codeUnitAt(pos) - 48);
          }
          left &= left - 1;
        }
      }

      for (var run = 0; run < runCount; run++) {
        if (live[run] != 0) continue;
        // Every run holds a number, so a run no number can fill is a dead end.
        broken = true;
        return -1;
      }

      for (var cell = 0; cell < cellCount; cell++) {
        if (puzzle.isWall(cell)) continue;
        var domain = kCrossingFullDomain;
        for (final (run, pos) in puzzle.runsAt(cell)) {
          domain &= allowed[run][pos];
        }
        if (domain == 0) {
          // Nothing the runs allow in common: the crossings contradict.
          broken = true;
          return -1;
        }
        final narrowed = domains[cell] & domain;
        if (narrowed != domains[cell]) {
          domains[cell] = narrowed;
          news++;
          moved = true;
        }
      }

      // A cell down to one digit rules out every number that would write a
      // different one there.
      for (var cell = 0; cell < cellCount; cell++) {
        final domain = domains[cell];
        if (_popCount(domain) != 1) continue;
        final digit = _lowestBit(domain);
        for (final (run, pos) in puzzle.runsAt(cell)) {
          var left = live[run];
          while (left != 0) {
            final number = _lowestBit(left);
            left &= left - 1;
            if (puzzle.numbers[number].codeUnitAt(pos) - 48 == digit) continue;
            final killed = _kill(number, run);
            if (killed < 0) return -1;
            if (killed > 0) {
              news++;
              moved = true;
            }
          }
        }
      }
    }
    return news;
  }

  /// **A number with one run left is placed.** Level 1: it is the move a player
  /// makes the moment they see it.
  int sweepPlaced() {
    if (broken) return -1;
    var news = 0;
    for (var number = 0; number < numberCount; number++) {
      final mask = placements[number];
      if (mask == 0) {
        broken = true;
        return -1;
      }
      if (_popCount(mask) != 1) continue;
      final placed = place(number, _lowestBit(mask));
      if (placed < 0) return -1;
      news += placed;
    }
    return news;
  }

  /// **A run with one number left takes it.** Level 2: sound because the list
  /// and the runs are the same length — one number per run and one run per
  /// number — so a run that could only take one number has taken it, whether or
  /// not that number still had somewhere else to go.
  int sweepOneHome() {
    if (broken) return -1;
    var news = 0;
    for (var run = 0; run < runCount; run++) {
      final bit = 1 << run;
      var only = -1;
      var count = 0;
      for (var number = 0; number < numberCount; number++) {
        if (placements[number] & bit == 0) continue;
        only = number;
        if (++count > 1) break;
      }
      if (count == 0) {
        broken = true;
        return -1;
      }
      if (count > 1) continue;
      final placed = place(only, run);
      if (placed < 0) return -1;
      news += placed;
    }
    return news;
  }
}

/// What a search over [CrossingModel] found.
class CrossingCount {
  const CrossingCount({
    required this.solutions,
    required this.truncated,
    required this.exhausted,
    required this.first,
    required this.forced,
    required this.forcedRuns,
  });

  /// Fillings found, capped at the limit asked for. A filling here is a way to
  /// place the whole list, so two fillings are two different grids.
  final int solutions;

  /// True when the budget ran out. A truncated count proves nothing.
  final bool truncated;

  /// True when the search finished: the limit was not reached and the budget was
  /// not spent. Only then are [forced] and [forcedRuns] a proof.
  final bool exhausted;

  /// The first filling, per cell, or empty.
  final List<int> first;

  /// Per cell, the digit every filling agrees on, or null. All null unless
  /// [exhausted].
  final List<int?> forced;

  /// Per number, the run every filling agrees on, or null. This is the object
  /// the search is over, so it is the stronger of the two proofs: "the 47 is
  /// here" decides two cells at once.
  final List<int?> forcedRuns;

  bool get isUnique => solutions == 1 && !truncated;
}

/// The search behind [CrossingForced]: place the list, count the grids.
class CrossingSearch {
  CrossingSearch(
    this.start, {
    this.limit = 2,
    this.budget = 40000,
  });

  final CrossingModel start;
  final int limit;
  final int budget;

  int _nodes = 0;
  int _solutions = 0;
  bool _truncated = false;
  List<int>? _first;
  late final List<int> _seen = [
    for (var cell = 0; cell < start.cellCount; cell++)
      start.puzzle.isWall(cell) ? 0 : kCrossingFullDomain,
  ];
  late final List<int> _seenRun =
      List<int>.filled(start.numberCount, (1 << start.runCount) - 1);

  CrossingPuzzle get puzzle => start.puzzle;

  CrossingCount run() {
    _search(start.copy());
    // Reaching the limit is not finishing: the fillings beyond it were never
    // looked at, so nothing is proved about them.
    final exhausted = !_truncated && _solutions < limit;
    final forced = List<int?>.filled(start.cellCount, null);
    final forcedRuns = List<int?>.filled(start.numberCount, null);
    if (exhausted && _solutions > 0) {
      for (var cell = 0; cell < start.cellCount; cell++) {
        if (puzzle.isWall(cell)) continue;
        if (_popCount(_seen[cell]) == 1) forced[cell] = _lowestBit(_seen[cell]);
      }
      for (var number = 0; number < start.numberCount; number++) {
        if (_popCount(_seenRun[number]) == 1) {
          forcedRuns[number] = _lowestBit(_seenRun[number]);
        }
      }
    }
    return CrossingCount(
      solutions: _solutions,
      truncated: _truncated,
      exhausted: exhausted,
      first: _first ?? const [],
      forced: forced,
      forcedRuns: forcedRuns,
    );
  }

  int _search(CrossingModel model) {
    if (_truncated) return 0;
    if (_nodes++ > budget) {
      _truncated = true;
      return 0;
    }
    final outcome = deduce(model, crossingPlayerRules);
    if (!outcome.consistent) return 0;
    if (model.isComplete) {
      final values = model.values;
      _first ??= List<int>.from(values);
      for (var cell = 0; cell < start.cellCount; cell++) {
        if (puzzle.isWall(cell)) continue;
        _seen[cell] &= crossingDigitBit(values[cell]);
      }
      for (var number = 0; number < start.numberCount; number++) {
        _seenRun[number] &= model.placements[number];
      }
      _solutions++;
      return 1;
    }
    final choice = model.choice;
    // Neither complete nor guessable: the rules cannot see the freedom that is
    // left, so this branch proves nothing.
    if (choice == null) return 0;
    var found = 0;
    for (final value in choice.values) {
      found += _search(model.assume(choice.slot, value));
      // The limit is global, so a deep branch that reached it must stop the
      // whole walk, not just its own loop.
      if (_solutions >= limit || _truncated) break;
    }
    return found;
  }
}

/// The crossings: a digit every run through a cell agrees on. Level 1.
class CrossingDigits implements DeductionRule<CrossingModel> {
  const CrossingDigits();

  @override
  int get level => 1;

  @override
  String get name => 'the digit a crossing allows';

  @override
  int apply(CrossingModel model) => model.sweepDigits();
}

/// A number with one run left. Level 1.
class CrossingPlaced implements DeductionRule<CrossingModel> {
  const CrossingPlaced();

  @override
  int get level => 1;

  @override
  String get name => 'a number with one run left';

  @override
  int apply(CrossingModel model) => model.sweepPlaced();
}

/// A run with one number left. Level 2: it needs the fact that the list and the
/// runs are the same length, which is one step further from the grid.
class CrossingOneHome implements DeductionRule<CrossingModel> {
  const CrossingOneHome();

  @override
  int get level => 2;

  @override
  String get name => 'the only number that fits a run';

  @override
  int apply(CrossingModel model) => model.sweepOneHome();
}

/// The exact rule: a digit or a number is only written when a search proves
/// every other choice impossible. Level 3, so a board finished by it alone is
/// not "solvable by logic" — and because it also counts, it is what makes the
/// generator's promise ("exactly one filling") true.
class CrossingForced implements DeductionRule<CrossingModel> {
  const CrossingForced({this.limit = 1024, this.budget = 20000});

  final int limit;
  final int budget;

  @override
  int get level => 3;

  @override
  String get name => 'searching every other placement';

  @override
  int apply(CrossingModel model) {
    if (model.broken) return -1;
    final found = CrossingSearch(model, limit: limit, budget: budget).run();
    if (found.truncated || !found.exhausted) return 0;
    if (found.solutions == 0) return -1;
    var news = 0;
    for (var number = 0; number < model.numberCount; number++) {
      final run = found.forcedRuns[number];
      if (run == null) continue;
      if (_popCount(model.placements[number]) == 1) continue;
      final placed = model.place(number, run);
      if (placed < 0) return -1;
      news += placed;
    }
    for (var cell = 0; cell < model.cellCount; cell++) {
      final digit = found.forced[cell];
      if (digit == null) continue;
      if (model.isDecided(cell)) continue;
      final written = model.restrict(cell, digit);
      if (written < 0) return -1;
      news += written;
    }
    return news;
  }
}

/// Every rule, easiest first, ending with the exact one.
const List<DeductionRule<CrossingModel>> crossingRules = [
  CrossingDigits(),
  CrossingPlaced(),
  CrossingOneHome(),
  CrossingForced(),
];

/// The rules a player can be expected to use, without the search.
const List<DeductionRule<CrossingModel>> crossingPlayerRules = [
  CrossingDigits(),
  CrossingPlaced(),
  CrossingOneHome(),
];
