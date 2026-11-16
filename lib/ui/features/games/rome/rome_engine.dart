/// Rome's generator: a random arrow field, areas grown around it, goals where
/// the chains actually close, and the fewest printed arrows that still prove the
/// answer.
///
/// The order matters, and it is the order the C original uses:
///
///  1. an arrow in every cell, pointing somewhere on the board;
///  2. areas grown by flood fill, four cells at most, never repeating an arrow;
///  3. a **goal** on one cell of every cycle the arrows formed — with every
///     arrow pointing inwards, each chain must end in a cycle, so one goal per
///     cycle is exactly what makes rule 2 true of the answer;
///  4. printed arrows, dropped one at a time, each drop kept only while the
///     board still proves itself.
///
/// Step 4 starts from "every arrow is printed", which is true by construction,
/// so the generator can never hand out a board whose answer is not the one it
/// dealt: a drop is only made when the smaller board is proved to have one
/// answer and to be finishable with the rules a player has.
library;

import 'dart:math';

import '../../../../core/deduction.dart';
import 'rome_model.dart';
import 'rome_puzzle.dart';

/// What a board's arrows and goals are worth, so the generator never ships a
/// shrug.
class RomeEngine {
  const RomeEngine({this.deals = 3});

  /// How many arrow fields are built per board, keeping the one that leaves the
  /// player the most to do.
  ///
  /// This is the one place the generator spends time on purpose. Every field
  /// gives a provable board; what differs is how many arrows have to be printed
  /// for the rules to finish it, and that is the thing that decides whether the
  /// board is worth playing. Measured over 12 boards per size: one field leaves
  /// 13.0 of a 5x5's 21 arrows printed, the sparsest of three leaves 11.4 (19.7
  /// to 17.8 of 29 on a 6x6), for about 10 ms of generation instead of 4.
  final int deals;

  /// A board at [size], proved before it is returned.
  ///
  /// The arrow field, the areas and the goals are all built fresh per deal, so
  /// each deal is a different board of the same size. The sparsest is kept: a
  /// board with fewer printed arrows is the same puzzle with more of it left to
  /// the player.
  ///
  /// Throws rather than ship a board it could not prove. [attempts] is the
  /// budget for the whole deal rather than for one field, because a field that
  /// cannot be proved is not bad luck to retry forever: it is the shape of that
  /// random walk, and another walk is a different question.
  RomePuzzle generate(
    RomeSize size, {
    Random? random,
    int attempts = 40,
  }) {
    final rng = random ?? Random();
    RomePuzzle? best;
    var bestPrinted = 1 << 30;
    var remaining = deals;
    for (var attempt = 0; attempt < attempts; attempt++) {
      final arrows = _arrowField(size, rng);
      final puzzle = _build(size, arrows, rng);
      if (!_proven(puzzle)) continue;
      final printed =
          puzzle.givens.where((given) => given != kRomeNoGiven).length;
      if (printed < bestPrinted) {
        best = puzzle;
        bestPrinted = printed;
      }
      if (bestPrinted == 0) break;
      if (--remaining == 0) break;
    }
    if (best == null) {
      throw StateError(
        'could not build a provable ${size.n}x${size.n} Rome board '
        'in $attempts attempts',
      );
    }
    return best;
  }

  /// An arrow in every cell, pointing somewhere **on** the board.
  ///
  /// Choosing only from the directions that stay in the grid is what keeps the
  /// goal count down and the goal placement simple: with no arrow leaving the
  /// board, a chain can only ever end in a cycle, and one goal per cycle is
  /// enough. A field that allowed off-board arrows would need a goal on every
  /// cell that points off the edge, which on a 5x5 is most of the border.
  List<int> _arrowField(RomeSize size, Random rng) {
    final arrows = List<int>.filled(size.cellCount, kRomeUp);
    for (var cell = 0; cell < size.cellCount; cell++) {
      final row = cell ~/ size.n;
      final col = cell % size.n;
      final open = [
        for (var arrow = kRomeUp; arrow <= kRomeLeft; arrow++)
          if (_step(size, row, col, arrow) != null) arrow
      ];
      arrows[cell] = open[rng.nextInt(open.length)];
    }
    return arrows;
  }

  /// The cell one step from (row, col) in [arrow], or null off the board. The
  /// same arithmetic as [RomePuzzle.neighbour], before a puzzle exists to ask.
  int? _step(RomeSize size, int row, int col, int arrow) {
    final nextRow = row + kRomeSteps[arrow][1];
    final nextCol = col + kRomeSteps[arrow][0];
    if (nextRow < 0 || nextRow >= size.n) return null;
    if (nextCol < 0 || nextCol >= size.n) return null;
    return nextRow * size.n + nextCol;
  }

  /// The whole board: areas, goals, then the printed arrows.
  RomePuzzle _build(RomeSize size, List<int> arrows, Random rng) {
    final areas = _areas(size, arrows, rng);
    final goals = _goals(size, arrows, rng);
    // A goal is printed as a circle and holds no arrow, so nothing is printed
    // *in* it: a given arrow on a goal would contradict the board on the first
    // pass of the model.
    final givens = [
      for (var cell = 0; cell < size.cellCount; cell++)
        goals.contains(cell) ? kRomeNoGiven : arrows[cell],
    ];
    var puzzle = RomePuzzle(
      size: size,
      areas: areas,
      goals: goals,
      givens: givens,
      solution: [
        for (var cell = 0; cell < size.cellCount; cell++)
          goals.contains(cell) ? kRomeGoal : arrows[cell],
      ],
    );
    // Every arrow printed is a board that is already finished. Dropping them one
    // at a time is the only way the answer stays the one that was dealt.
    final order = [for (var cell = 0; cell < size.cellCount; cell++) cell]
      ..shuffle(rng);
    for (final cell in order) {
      if (goals.contains(cell)) continue;
      if (puzzle.givens[cell] == kRomeNoGiven) continue;
      final wouldBe = [...puzzle.givens]..[cell] = kRomeNoGiven;
      final candidate = RomePuzzle(
        size: size,
        areas: areas,
        goals: goals,
        givens: wouldBe,
        solution: puzzle.solution,
      );
      if (!_proven(candidate)) continue;
      puzzle = candidate;
    }
    return puzzle;
  }

  /// Areas grown by flood fill: a seed cell, then neighbours taken in random
  /// order while the area has room (four cells at most) and the arrow is not
  /// already in it.
  ///
  /// The generator never has to undo a merge, because a cell is only ever taken
  /// by the area that claims it first, and the rule it enforces — no repeated
  /// arrow — is exactly rule 1. Areas of one cell are common and are not a
  /// failure: they are the cells whose arrow was already used by every neighbour.
  List<int> _areas(RomeSize size, List<int> arrows, Random rng) {
    final areaOf = List<int>.filled(size.cellCount, -1);
    var next = 0;
    final seeds = [for (var cell = 0; cell < size.cellCount; cell++) cell]
      ..shuffle(rng);
    for (final seed in seeds) {
      if (areaOf[seed] != -1) continue;
      final id = next++;
      areaOf[seed] = id;
      var used = romeBit(arrows[seed]);
      var count = 1;
      final frontier = <int>[seed];
      while (count < size.maxArea && frontier.isNotEmpty) {
        // A random cell of the frontier, so an area wanders instead of running
        // in one direction: a row of four arrows reads as a list, a blob reads
        // as an outline. The cell is **taken off** the frontier whether or not
        // it grows the area; leaving a dead end on it would spin here forever.
        final from = frontier.removeAt(rng.nextInt(frontier.length));
        final row = from ~/ size.n;
        final col = from % size.n;
        final open = <int>[];
        for (var arrow = kRomeUp; arrow <= kRomeLeft; arrow++) {
          final next = _step(size, row, col, arrow);
          if (next == null || areaOf[next] != -1) continue;
          if (used & romeBit(arrows[next]) != 0) continue;
          open.add(next);
        }
        open.shuffle(rng);
        for (final cell in open) {
          if (count >= size.maxArea) break;
          if (areaOf[cell] != -1) continue;
          if (used & romeBit(arrows[cell]) != 0) continue;
          areaOf[cell] = id;
          used |= romeBit(arrows[cell]);
          count++;
          frontier.add(cell);
        }
      }
    }
    return areaOf;
  }

  /// One goal per cycle of the arrow field.
  ///
  /// With every arrow pointing inwards, each chain either closes on itself or
  /// drains into a cycle, so one goal inside each cycle is exactly what makes
  /// "following the arrows arrives at a goal" true of the answer: every chain
  /// arrives at the one goal of its cycle and stops. The goal is picked at
  /// random inside its cycle, so it is not always the same shape of cell, and
  /// the smallest cycle here is two cells — an arrow always moves, so no cell
  /// points at itself.
  List<int> _goals(RomeSize size, List<int> arrows, Random rng) {
    final state = List<int>.filled(size.cellCount, 0);
    final goals = <int>[];
    for (var start = 0; start < size.cellCount; start++) {
      if (state[start] != 0) continue;
      final path = <int>[];
      var cell = start;
      while (state[cell] == 0) {
        state[cell] = 1;
        path.add(cell);
        cell = _step(size, cell ~/ size.n, cell % size.n, arrows[cell])!;
      }
      if (state[cell] == 1) {
        final cycle = path.sublist(path.indexOf(cell));
        goals.add(cycle[rng.nextInt(cycle.length)]);
      }
      for (final walked in path) {
        state[walked] = 2;
      }
    }
    goals.sort();
    return goals;
  }

  /// Exactly one answer, and reachable with the rules a player has (level 1 or
  /// 2 — there is no level 3 here).
  ///
  /// The level is checked first because it is the cheap one: a board the rules
  /// cannot finish is rejected after one pass, without counting anything. A board
  /// that the rules *can* finish is counted in a single node, because the rules
  /// decide it before the search has to branch — so the count costs nothing on
  /// the boards that matter and proves uniqueness independently of the rules.
  bool _proven(RomePuzzle puzzle) {
    final level = solvingLevel(RomeModel.fresh(puzzle), romePlayerRules);
    if (level == null || level > 2) return false;
    final count = countSolutions(
      RomeModel.fresh(puzzle),
      romePlayerRules,
      limit: 2,
      maxNodes: 64,
    );
    if (count.truncated) return false;
    return count.isUnique;
  }

  /// How many answers [puzzle] has, at most two.
  int count(RomePuzzle puzzle) =>
      countSolutions(RomeModel.fresh(puzzle), romePlayerRules).count;

  /// The lowest rule level that finishes [puzzle], or null when it needs a
  /// guess. Levels 1 and 2 are the player's rules; there is no higher one, so a
  /// null here means the board must not be dealt.
  int? levelOf(RomePuzzle puzzle) =>
      solvingLevel(RomeModel.fresh(puzzle), romePlayerRules);

  /// A cell and arrow the rules prove, or null when the rules have run out.
  ///
  /// It returns a value to write; the board decides how to show it. A hint that
  /// only outlined a cell would leave the player exactly where they were.
  RomeHint? hint(RomePuzzle puzzle, List<int> values) {
    final model = RomeModel.fresh(puzzle);
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final value = values[cell];
      if (value == kRomeBlank) continue;
      if (puzzle.isGoal(cell)) continue;
      if (model.set(cell, value) < 0) return null;
    }
    final outcome = deduce(model, romePlayerRules);
    if (!outcome.consistent) return null;
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      if (puzzle.isGoal(cell)) continue;
      if (values[cell] != kRomeBlank) continue;
      final arrow = model.valueAt(cell);
      if (arrow != null) return RomeHint(cell, arrow);
    }
    return null;
  }

  /// Whether [values] is the answer, on the board as the player sees it.
  bool isSolved(RomePuzzle puzzle, List<int> values) =>
      puzzle.isSolution(values);
}

/// A proved cell.
class RomeHint {
  const RomeHint(this.cell, this.arrow);

  final int cell;

  /// An arrow `0..3`. A hint never points at a goal: a goal is printed, not
  /// written.
  final int arrow;
}
