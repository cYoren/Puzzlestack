/// Bricks (Tawamurenga): shade cells of a honeycomb so the pile stands up.
///
/// The rules are the genre's (see `bricks.c` in `x-sheep/puzzles-unreleased`,
/// MIT, pinned in `REFERENCE.md`):
///
///  1. every shaded cell has at least one shaded cell directly **below** it,
///     unless it is on the bottom row;
///  2. no three shaded cells in a horizontal run;
///  3. a number counts the shaded cells around it — all six neighbours;
///  4. a numbered cell is never shaded.
///
/// ## "Below" has a direction, and it is the C's table
///
/// In a honeycomb a cell does not have one cell under it, it has two: the two
/// in the next row that share a lower edge with it. Which two depends on which
/// way the rows are pushed. `bricks.c` pushes row `y` half a cell to the right
/// of row `y - 1` and then reads adjacency with
///
/// ```text
///   bricks_steps[6] = { {0,-1}, {1,-1}, {-1,0}, {1,0}, {-1,1}, {0,1} };
/// ```
///
/// which, on that lattice, is **up-left `(0,-1)`, up-right `(1,-1)`, left
/// `(-1,0)`, right `(1,0)`, down-left `(-1,1)`, down-right `(0,1)`**. Its
/// gravity rule is the same sentence: `bricks_validate_gravity` reads
/// `i2 = (y+1) * w + x-1` and `i3 = (y+1) * w + x`, the two cells in the next
/// row, one to the left and one straight on. So [BricksLattice.below] is the
/// bottom pair of that table and nothing else: a cell above and to the side of
/// a shaded cell does not hold it up.
///
/// ## The shape
///
/// The C builds its board from a rectangle of `pw` cells per row and `h` rows
/// on that sheared lattice, then blanks the corners
/// (`bricks_apply_bounds`) so the outline reads as a hexagon instead of a
/// parallelogram: `y ~/ 2` cells cut from the right end of row `y` and
/// `(h - y) ~/ 2` (less one, on the rows where the zigzag leaves a gap) from
/// the left. That is kept exactly — [BricksLattice] reproduces it — because the
/// cut is what makes every row carry the same number of cells, which is what
/// the generator's fill walks.
///
/// Three vocabularies, kept apart, because two of them are small integers and
/// confusing them is the bug that costs review rounds:
///
///  * a **clue** is a count `0..6`, or [kBricksNoClue] when the cell is blank;
///  * a **cell's value** is [kBricksUnshaded] or [kBricksShaded], and nothing
///    else — the game has two states, so there is no third "not yet";
///  * the **answer** is the shading the clues were read off, and it is only
///    consulted by a hint; a board is won by being legal, not by matching it.
library;

import 'dart:math' as math;

/// Nothing printed on this cell.
const int kBricksNoClue = -1;

/// A cell that is not shaded.
const int kBricksUnshaded = 0;

/// A cell that is shaded.
const int kBricksShaded = 1;

/// The three boards the game ships.
///
/// `rows` is the number of rows of the honeycomb and `cols` the number of cells
/// every row carries. The feed size is five rows: the rules are local, so a
/// board is read at a glance, and a sixth or seventh row adds width rather than
/// a new idea. Cells per board are 30, 42 and 56; the C's own default preset is
/// the middle one (7x6 = 42 cells).
enum BricksSize {
  small(5, 6),
  medium(6, 7),
  large(7, 8);

  const BricksSize(this.rows, this.cols);

  /// Rows of the honeycomb, top to bottom.
  final int rows;

  /// Cells in every row, cut corners included in neither count.
  final int cols;

  int get cellCount => rows * cols;

  /// Columns of the rectangle the honeycomb is cut out of: `bricks_grid_size`,
  /// `w = params->w + ((params->h + 1) / 2) - 1`.
  int get gridWidth => cols + (rows + 1) ~/ 2 - 1;
}

/// Where a Bricks board sits in the plane, before it is scaled to a box.
///
/// A honeycomb of pointy-top hexagons: pitch `√3 · r` across a row and
/// `1.5 · r` down a column, with each row pushed half a cell right. That is the
/// lattice the C's neighbour table describes, drawn as hexagons instead of as
/// squares — see the note at the top of this file.
///
/// The unit is one circumradius, so the numbers here are ratios and the board
/// normalises them once (this class has no idea how big a phone is).
class BricksLattice {
  BricksLattice(this.size) {
    for (var y = 0; y < size.rows; y++) {
      final last = size.gridWidth - 1 - y ~/ 2;
      for (var x = leftmost(y); x <= last; x++) {
        indexAt[y * size.gridWidth + x] = row.length;
        row.add(y);
        col.add(x);
      }
    }

    for (var cell = 0; cell < row.length; cell++) {
      _neighbours.add([
        for (final step in _steps)
          if (cellAt(row[cell] + step[1], col[cell] + step[0])
              case final found?)
            found,
      ]);
    }

    var minCx = double.infinity;
    var maxCx = -double.infinity;
    var maxCy = -double.infinity;
    for (var cell = 0; cell < cellCount; cell++) {
      minCx = math.min(minCx, centreX(cell));
      maxCx = math.max(maxCx, centreX(cell));
      maxCy = math.max(maxCy, centreY(cell));
    }
    left = minCx - pitchX / 2;
    top = -radius;
    width = maxCx + pitchX / 2 - left;
    height = maxCy + radius - top;
  }

  final BricksSize size;

  /// `bricks.c`'s neighbour table, in its own order and its own `(dx, dy)`.
  ///
  /// Kept as the C writes it — rather than as six named getters — so a reader
  /// can diff it against the source line by line. [around] walks all six; the
  /// rules read [leftOf], [rightOf] and [below], because nothing in this game
  /// ever looks up.
  static const List<List<int>> _steps = [
    [0, -1], [1, -1], // up-left, up-right
    [-1, 0], [1, 0], // left, right
    [-1, 1], [0, 1], // down-left, down-right
  ];

  /// Half a hexagon's width: the distance between two cells in one row.
  static const double pitchX = 1.7320508075688772; // √3 × circumradius

  /// The distance between two rows.
  static const double pitchY = 1.5; // 1.5 × circumradius

  /// Centre to point of a hexagon.
  static const double radius = 1.0;

  /// Row of each cell, in the rectangle the honeycomb is cut out of.
  final List<int> row = <int>[];

  /// Column of each cell, in the same rectangle. Rows are sheared, so column
  /// `x` of row `y` is not above column `x` of row `y + 1`.
  final List<int> col = <int>[];

  /// Grid position to cell index, or -1 where the corner was cut away.
  late final List<int> indexAt =
      List<int>.filled(size.rows * size.gridWidth, -1);

  /// The six neighbours of each cell, in the C's table order, off-board ones
  /// dropped. Read it through [around], which is the name the rules use.
  final List<List<int>> _neighbours = <List<int>>[];

  /// Left edge, top edge, width and height of the whole honeycomb, in the same
  /// units as [centreX] and [centreY].
  late final double left;
  late final double top;
  late final double width;
  late final double height;

  int get cellCount => row.length;

  /// The first column of [y] that was not cut away.
  ///
  /// `bricks_apply_bounds`: `(h - y) / 2` cells off the left end, one fewer on
  /// the rows where `(h | y)` is even — the half-cell the zigzag edge would
  /// otherwise leave hanging. Both are integer divisions in the C, and both are
  /// here.
  int leftmost(int y) {
    final extra = ((size.rows | y) & 1) == 0 ? 1 : 0;
    return math.max(0, (size.rows - y) ~/ 2 - extra);
  }

  /// The last column of [y] that was not cut away.
  int rightmost(int y) => size.gridWidth - 1 - y ~/ 2;

  /// The cell at a grid position, or null where the corner was cut away.
  int? cellAt(int y, int x) {
    if (y < 0 || y >= size.rows || x < 0 || x >= size.gridWidth) return null;
    final cell = indexAt[y * size.gridWidth + x];
    return cell < 0 ? null : cell;
  }

  int? leftOf(int cell) => cellAt(row[cell], col[cell] - 1);
  int? rightOf(int cell) => cellAt(row[cell], col[cell] + 1);
  int? downLeft(int cell) => cellAt(row[cell] + 1, col[cell] - 1);
  int? downRight(int cell) => cellAt(row[cell] + 1, col[cell]);

  /// The cells that hold [cell] up: down-left and down-right, and only those.
  ///
  /// Empty on the bottom row, where rule 1 asks nothing.
  List<int> below(int cell) => [
        if (downLeft(cell) case final found?) found,
        if (downRight(cell) case final found?) found,
      ];

  /// Every cell that touches [cell], in the C's order.
  List<int> around(int cell) => _neighbours[cell];

  bool isBottomRow(int cell) => row[cell] == size.rows - 1;

  /// Centre of [cell], in the lattice's own units.
  double centreX(int cell) => col[cell] * pitchX + row[cell] * pitchX / 2;

  double centreY(int cell) => row[cell] * pitchY;
}

/// A Bricks board: the numbers, and the shading they were read off.
class BricksPuzzle {
  BricksPuzzle({
    required this.size,
    required this.clues,
    required this.solution,
  })  : lattice = BricksLattice(size),
        assert(clues.length == size.cellCount),
        assert(solution.length == size.cellCount);

  final BricksSize size;

  /// The honeycomb these numbers sit on.
  final BricksLattice lattice;

  /// Per cell, the shaded count it prints, or [kBricksNoClue].
  final List<int> clues;

  /// The pattern the numbers were read off: [kBricksUnshaded] or
  /// [kBricksShaded] per cell.
  ///
  /// It is the answer, not the rule: a board is won by being legal, and the
  /// generator only ships boards where the two agree. A hint is allowed to read
  /// it — the rules may have run out.
  final List<int> solution;

  int get rows => size.rows;

  int get cols => size.cols;

  int get cellCount => size.cellCount;

  int clue(int cell) => clues[cell];

  bool hasClue(int cell) => clues[cell] != kBricksNoClue;

  int clueCount() => clues.where((clue) => clue != kBricksNoClue).length;

  int shadedIn(List<int> values) =>
      values.where((value) => value == kBricksShaded).length;

  /// How many cells around [cell] are shaded in [values].
  ///
  /// Off-board neighbours are not shaded and not counted, which is what the C
  /// does by treating its bound cells as unshaded (`bricks_build_numbers`).
  int shadedAround(List<int> values, int cell) {
    var count = 0;
    for (final other in lattice.around(cell)) {
      if (values[other] == kBricksShaded) count++;
    }
    return count;
  }

  /// True when [values] is a shading the four rules accept.
  ///
  /// This is the whole verdict, on a board the player has finished with: every
  /// cell decided, every number true, no tower standing on air, no run of
  /// three. A half-finished board is not asked this question — see
  /// [conflicts], which is what the board paints.
  bool isLegal(List<int> values) {
    if (values.length != cellCount) return false;
    for (final value in values) {
      // Not a clue sentinel, not a third state: a legal board is two-state.
      if (value != kBricksUnshaded && value != kBricksShaded) return false;
    }

    // Rules 3 and 4: a number is true, and the cell carrying it is unshaded.
    for (var cell = 0; cell < cellCount; cell++) {
      if (!hasClue(cell)) continue;
      if (values[cell] != kBricksUnshaded) return false;
      if (shadedAround(values, cell) != clues[cell]) return false;
    }

    // Rule 1: nothing floats. A shaded cell outside the bottom row needs a
    // shaded cell in the bottom pair of the neighbour table.
    for (var cell = 0; cell < cellCount; cell++) {
      if (values[cell] != kBricksShaded) continue;
      if (lattice.isBottomRow(cell)) continue;
      var held = false;
      for (final under in lattice.below(cell)) {
        if (values[under] == kBricksShaded) {
          held = true;
          break;
        }
      }
      if (!held) return false;
    }

    // Rule 2: no three in a horizontal run.
    for (var cell = 0; cell < cellCount; cell++) {
      final left = lattice.leftOf(cell);
      final right = lattice.rightOf(cell);
      if (left == null || right == null) continue;
      if (values[left] != kBricksShaded) continue;
      if (values[cell] != kBricksShaded) continue;
      if (values[right] != kBricksShaded) continue;
      return false;
    }

    return true;
  }

  /// The cells that break a rule on [values], for the board to paint red.
  ///
  /// Deliberately weaker than [isLegal]: a number with fewer shaded neighbours
  /// than it counts is not a mistake yet, it is work left to do, so only an
  /// over-count is accused. This is the C's split too — `shade > n` is
  /// `STATUS_INVALID`, `shade < n` is only `STATUS_UNFINISHED`.
  Set<int> conflicts(List<int> values) {
    final bad = <int>{};

    for (var cell = 0; cell < cellCount; cell++) {
      if (!hasClue(cell)) continue;
      if (values[cell] == kBricksShaded) {
        // Rule 4 is a promise about the cell itself, not a count.
        bad.add(cell);
        continue;
      }
      if (shadedAround(values, cell) > clues[cell]) bad.add(cell);
    }

    for (var cell = 0; cell < cellCount; cell++) {
      if (values[cell] != kBricksShaded) continue;
      if (lattice.isBottomRow(cell)) continue;
      final under = lattice.below(cell);
      // A shaded cell with nothing under it at all cannot be held up either;
      // that is the same accusation as having only unshaded cells under it.
      if (under.every((other) => values[other] != kBricksShaded)) bad.add(cell);
    }

    for (var cell = 0; cell < cellCount; cell++) {
      final left = lattice.leftOf(cell);
      final right = lattice.rightOf(cell);
      if (left == null || right == null) continue;
      if (values[left] != kBricksShaded) continue;
      if (values[cell] != kBricksShaded) continue;
      if (values[right] != kBricksShaded) continue;
      bad.addAll([left, cell, right]);
    }

    return bad;
  }
}
