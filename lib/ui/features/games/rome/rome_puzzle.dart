/// Rome (Nikoli): an arrow in every cell, and every arrow chain ends at a goal.
///
/// The rules are the genre's (see `rome.c` in `x-sheep/puzzles-unreleased`,
/// MIT, pinned in `REFERENCE.md`):
///
///  * every cell holds one arrow, pointing up, down, left or right;
///  * an outlined area holds no repeated arrow;
///  * following the arrows from any cell arrives at a circled **goal**, never
///    loops, and never leaves the grid.
///
/// A goal is a sink, not an arrow: the chain stops the moment it enters one, so
/// a goal cell carries nothing to write. That is why a goal has a value of its
/// own ([kRomeGoal]) instead of being an arrow with a circle painted on it — the
/// search would otherwise be free to choose the goal's arrow, nothing would pin
/// it down, and every board would come out with dozens of answers.
///
/// Four vocabularies, kept apart on purpose. Two of them are small integers and
/// confusing them is the bug that costs review rounds:
///
///  * an **arrow** is `0..3`, in the order of [kRomeSteps]: up, right, down,
///    left. The same numbers are bits in a cell's mask (`1 << arrow`).
///  * a **goal** is [kRomeGoal], `4`. It is not an arrow and it is not blank.
///  * a **given** is an arrow, or [kRomeNoGiven] `-1` when that cell is not
///    printed. The answer is a given too: the generator prints nothing there.
///  * a cell **the player has not written** is [kRomeBlank] `-2`. It is not a
///    goal and it is not an absent given; it is "nothing here yet".
library;

/// The three boards the game ships.
///
/// Side only: Rome has no alphabet or fleet to configure, because the whole
/// board is one domain of four. The 5x5 is the feed size — the smallest board
/// where goals are still far apart and arrows still have room to loop — and the
/// two larger boards are for a player who wants the same rules with more of
/// them.
///
/// Dealt and proved 12 times per size (`tool/probe_rome.dart` was the
/// measurement and was deleted once these numbers were in), with a warm process
/// and three arrow fields per deal:
///
/// ```text
/// 5x5   9.1 ms median, 13.6 ms max, 4 goals, 12 of 21 arrows printed
/// 6x6  15.4 ms median, 25.5 ms max, 5 goals, 18 of 29 arrows printed
/// 7x7  29.4 ms median, 43.7 ms max, 8 goals, 25 of 40 arrows printed
/// ```
///
/// The share that has to be printed — a little over half — is what this game
/// costs. Rules 1-3 are local plus one reachability fixpoint, and a random arrow
/// field leaves very little for them to pin down: a drop that leaves the answer
/// unique still often cannot be reasoned to, so the generator keeps the arrow.
/// Printing more than half is the honest consequence of shipping no board that
/// needs a guess.
enum RomeSize {
  small(5),
  medium(6),
  large(7);

  const RomeSize(this.n);

  /// Side of the square grid.
  final int n;

  int get cellCount => n * n;

  /// The most cells an outlined area may hold. Four is the number of arrows, so
  /// a four-cell area is a Latin-square line: each of the four appears once.
  int get maxArea => 4;
}

/// The arrow that points up. Arrows are `0..3` and also bit positions.
const int kRomeUp = 0;

/// The arrow that points right.
const int kRomeRight = 1;

/// The arrow that points down.
const int kRomeDown = 2;

/// The arrow that points left.
const int kRomeLeft = 3;

/// A circled goal. A sink: a chain stops here, and nothing is written here.
const int kRomeGoal = 4;

/// How many arrows there are, which is also the most cells an area may hold.
const int kRomeArrowCount = 4;

/// A cell with no printed arrow.
const int kRomeNoGiven = -1;

/// Nothing written in a cell, and nothing decided about it.
///
/// Distinct from [kRomeNoGiven] on purpose: one is a fact about the puzzle,
/// the other is work the player has not done. A win test that treated them as
/// one would accept a board that was never played.
const int kRomeBlank = -2;

/// Row and column steps of the four arrows, in [kRomeUp]..[kRomeLeft] order.
const List<List<int>> kRomeSteps = [
  [0, -1],
  [1, 0],
  [0, 1],
  [-1, 0],
];

/// The name of an arrow, for tests and failure messages.
String romeArrowName(int arrow) => switch (arrow) {
      kRomeUp => 'up',
      kRomeRight => 'right',
      kRomeDown => 'down',
      kRomeLeft => 'left',
      kRomeGoal => 'goal',
      _ => 'blank($arrow)',
    };

/// A Rome board: the areas, the goals, the printed arrows, and the answer.
class RomePuzzle {
  RomePuzzle({
    required this.size,
    required this.areas,
    required this.goals,
    required this.givens,
    required this.solution,
  })  : assert(areas.length == size.cellCount),
        assert(givens.length == size.cellCount),
        assert(solution.length == size.cellCount),
        assert(areas.every((area) => area >= 0));

  final RomeSize size;

  /// The outlined area of each cell, row-major. Area ids are `0..areaCount-1`
  /// and each one is contiguous, because the generator grows them by flood
  /// fill.
  final List<int> areas;

  /// The circled cells, sorted. A goal holds no arrow.
  final List<int> goals;

  /// The printed arrow of each cell, or [kRomeNoGiven].
  final List<int> givens;

  /// The answer: an arrow `0..3` in every cell, and [kRomeGoal] in the goals.
  final List<int> solution;

  int get n => size.n;

  int get cellCount => size.cellCount;

  int get maxArea => size.maxArea;

  int cell(int row, int col) => row * n + col;

  /// True when [cell] is a circled goal.
  bool isGoal(int cell) => isGoalFlag[cell];

  /// The goal set as a flag per cell, because every rule asks this question
  /// about every cell on every pass.
  late final List<bool> isGoalFlag = [
    for (var cell = 0; cell < cellCount; cell++) goals.contains(cell),
  ];

  /// The arrow printed in [cell], or [kRomeNoGiven].
  int given(int cell) => givens[cell];

  /// The area of [cell].
  int areaOf(int cell) => areas[cell];

  /// How many areas the board is cut into.
  late final int areaCount = areas.reduce((a, b) => a > b ? a : b) + 1;

  /// The cells of area [area], row-major.
  List<int> areaCells(int area) => areaCellList[area];

  /// The cells of every area, grouped once.
  late final List<List<int>> areaCellList = () {
    final grouped = List.generate(areaCount, (_) => <int>[]);
    for (var cell = 0; cell < cellCount; cell++) {
      grouped[areas[cell]].add(cell);
    }
    return grouped;
  }();

  /// The cell one step from [cell] in [arrow], or null when that leaves the
  /// grid. Null is the whole of rule 2a: nothing points off the board.
  int? neighbour(int cell, int arrow) => neighbours[cell][arrow];

  /// Every cell's four targets, resolved once. The rules walk chains a few
  /// hundred thousand times while a board is proved, and this table is that
  /// arithmetic done once.
  late final List<List<int?>> neighbours = [
    for (var cell = 0; cell < cellCount; cell++)
      [
        for (var arrow = kRomeUp; arrow <= kRomeLeft; arrow++)
          _step(cell, arrow)
      ],
  ];

  int? _step(int cell, int arrow) {
    final step = kRomeSteps[arrow];
    final row = cell ~/ n + step[1];
    final col = cell % n + step[0];
    if (row < 0 || row >= n || col < 0 || col >= n) return null;
    return row * n + col;
  }

  /// Whether every chain in [values] ends at a goal.
  ///
  /// A chain is walked one arrow at a time. Any unfinished cell, any arrow
  /// leaving the grid and any step past the length of a chain are all failures,
  /// and the step bound is the loop test: a cycle that never reaches a goal
  /// would walk forever.
  bool chainsEnd(List<int> values) {
    for (var start = 0; start < cellCount; start++) {
      if (isGoal(start)) continue;
      var cell = start;
      var steps = 0;
      while (true) {
        if (isGoal(cell)) break;
        final arrow = values[cell];
        if (arrow < 0 || arrow > kRomeLeft) return false;
        final next = neighbour(cell, arrow);
        if (next == null) return false;
        cell = next;
        if (++steps > cellCount) return false;
      }
    }
    return true;
  }

  /// Whether [values] is the answer: an arrow everywhere, [kRomeGoal] in the
  /// goals, no arrow repeated in an area, and every chain ending at a goal.
  bool isSolution(List<int> values) {
    if (values.length != cellCount) return false;
    for (var cell = 0; cell < cellCount; cell++) {
      final value = values[cell];
      if (isGoal(cell)) {
        if (value != kRomeGoal) return false;
      } else if (value < 0 || value > kRomeLeft) {
        // [kRomeBlank] is negative and a goal is four: neither is an arrow.
        return false;
      }
    }
    for (var area = 0; area < areaCount; area++) {
      final seen = <int>{};
      for (final cell in areaCells(area)) {
        if (isGoal(cell)) continue;
        if (!seen.add(values[cell])) return false;
      }
    }
    return chainsEnd(values);
  }

  /// Whether a half-played board has not gone wrong yet.
  ///
  /// A blank cell ends a chain without violating anything, which is what lets
  /// the board accuse a cell the moment it is written and stay quiet before.
  bool isLegal(List<int> values) => conflicts(values).isEmpty;

  /// The cells that break a rule on [values], for the board to paint red.
  ///
  /// Three failures, and each one names the cells a player would reach for:
  /// the same arrow twice in an area, an arrow pointing off the board, and a
  /// chain that closes on itself without a goal in it.
  Set<int> conflicts(List<int> values) {
    final bad = <int>{};

    // Rule 1: an arrow appears once in its area.
    for (var area = 0; area < areaCount; area++) {
      final seen = <int, List<int>>{};
      for (final cell in areaCells(area)) {
        if (isGoal(cell)) continue;
        final value = values[cell];
        if (value < kRomeUp || value > kRomeLeft) continue;
        (seen[value] ??= []).add(cell);
      }
      seen.forEach((_, at) {
        if (at.length > 1) bad.addAll(at);
      });
    }

    // Rule 2: no arrow leaves the board, and no chain loops without a goal.
    for (var start = 0; start < cellCount; start++) {
      if (isGoal(start)) continue;
      final arrow = values[start];
      if (arrow < kRomeUp || arrow > kRomeLeft) continue;
      if (neighbour(start, arrow) == null) {
        bad.add(start);
        continue;
      }
      // Only the cells that are on the loop are at fault, and a chain that
      // runs into a blank is not a loop: it is work not done yet.
      final path = <int>[];
      var cell = start;
      while (true) {
        if (isGoal(cell)) break;
        final step = values[cell];
        if (step < kRomeUp || step > kRomeLeft) break;
        final at = path.indexOf(cell);
        if (at >= 0) {
          bad.addAll(path.sublist(at));
          break;
        }
        path.add(cell);
        final next = neighbour(cell, step);
        if (next == null) break;
        cell = next;
      }
    }
    return bad;
  }
}
