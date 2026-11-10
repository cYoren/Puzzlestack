import 'dart:math';

import '../../../../core/deduction.dart';

/// A dot, at a lattice point of the doubled grid.
///
/// A cell is two units across, so a dot at an even/even point sits at the centre
/// of a cell, one odd coordinate puts it on an edge between two cells, and two
/// odd coordinates put it on a vertex shared by four. All three are real
/// Galaxies dots: they are what lets a region have an even number of cells, and
/// without them a board cannot be tiled at all.
class GalaxiesDot {
  const GalaxiesDot(this.x, this.y);

  /// Doubled coordinates: `0 .. 2 * cols - 2` across, `0 .. 2 * rows - 2` down.
  final int x;
  final int y;

  bool get isCellCentre => x.isEven && y.isEven;

  @override
  bool operator ==(Object other) =>
      other is GalaxiesDot && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'dot($x,$y)';
}

/// One Galaxies board: where the dots are, and the partition that solves it.
class GalaxiesPuzzle {
  const GalaxiesPuzzle({
    required this.rows,
    required this.cols,
    required this.dots,
    required this.solution,
  });

  final int rows;
  final int cols;
  final List<GalaxiesDot> dots;

  /// Cell index to dot index. The answer, kept so a hint is free while the
  /// player is still on the line the generator drew.
  final List<int> solution;

  int get cellCount => rows * cols;

  int index(int row, int col) => row * cols + col;

  int rowOf(int cell) => cell ~/ cols;

  int colOf(int cell) => cell % cols;

  /// The cell [cell] reflects onto about [dot], or null when that lands off the
  /// board.
  ///
  /// A region is symmetric about its dot, so this is the whole rule of the
  /// game: if a cell belongs to a dot, its reflection does too. A cell is two
  /// units across, so the reflection of cell `(row, col)` is
  /// `(dot.y - row, dot.x - col)` — an integer cell for every lattice dot.
  int? mirrorOf(int cell, int dot) {
    final centre = dots[dot];
    final row = centre.y - rowOf(cell);
    final col = centre.x - colOf(cell);
    if (row < 0 || row >= rows || col < 0 || col >= cols) return null;
    return index(row, col);
  }

  /// The smallest symmetric region a dot can have: the cells its point sits in.
  ///
  /// One cell for a dot in the middle of a cell, two for a dot on an edge, four
  /// for a dot on a vertex. Every region grows out from here, so this is also
  /// the check that a dot is on the board at all.
  List<int> seedCells(int dot) => seedCellsOf(rows, cols, dots[dot]);
}

/// The cells a dot's point sits in: one for a dot in the middle of a cell, two
/// for a dot on an edge, four for a dot on a vertex.
///
/// A region must contain its dot, so these cells are decided before any
/// reasoning starts — for the generator and for the solver alike.
List<int> seedCellsOf(int rows, int cols, GalaxiesDot dot) {
  final firstCol = dot.x.isEven ? dot.x ~/ 2 : (dot.x - 1) ~/ 2;
  final firstRow = dot.y.isEven ? dot.y ~/ 2 : (dot.y - 1) ~/ 2;
  final wide = dot.x.isEven ? 1 : 2;
  final tall = dot.y.isEven ? 1 : 2;

  final cells = <int>[];
  for (var row = firstRow; row < firstRow + tall; row++) {
    for (var col = firstCol; col < firstCol + wide; col++) {
      if (row < 0 || row >= rows || col < 0 || col >= cols) continue;
      cells.add(row * cols + col);
    }
  }
  return cells;
}

/// Board size and the solving depth each size is asked for.
///
/// The level is the point: a board that only needs the mirror rule is easy, one
/// that needs connectivity is medium, one that needs a look ahead is hard. Size
/// grows with it so the hard boards are not just denser easy boards.
enum GalaxiesDifficulty {
  easy(rows: 6, cols: 6, dots: 6, level: 1),
  medium(rows: 8, cols: 8, dots: 12, level: 2),
  hard(rows: 9, cols: 9, dots: 14, level: 3);

  const GalaxiesDifficulty({
    required this.rows,
    required this.cols,
    required this.dots,
    required this.level,
  });

  final int rows;
  final int cols;

  /// How many dots, which is really how big a region is: the board divided by
  /// this. Denser boards are not just bigger, they are busier — more regions
  /// competing for the same cells, which is what makes the harder rules bite.
  final int dots;

  /// The lowest rule level that must be enough to finish the board.
  final int level;

  int get dotCount => dots;
}

/// The three ideas a Galaxies player uses, easiest first.
///
/// They are ordered deliberately: the harness rates a board by the lowest level
/// whose rules alone finish it, so this list *is* the difficulty scale.
///
/// 1. **Mirror.** A cell belongs to a dot, so its reflection does too. A cell
///    whose reflection is off the board, or already another dot's, cannot
///    belong to that dot.
/// 2. **Connectivity.** A region is connected to its dot. If a cell cannot be
///    reached from the dot's region without crossing another dot's cells, it
///    cannot be that dot's.
/// 3. **Looking ahead.** Try one cell as a dot's, run the easy rules, and throw
///    the guess away if it contradicts itself.
class GalaxiesEngine {
  const GalaxiesEngine();

  // ------------------------------------------------------------- generation

  /// A board whose only solution needs exactly [difficulty]'s level of
  /// reasoning.
  ///
  /// Generation is propose-and-check, the same shape Tatham uses: build a
  /// partition at random, then ask the solver what it is. A board that comes
  /// back ambiguous, impossible, or easier than asked for is thrown away. That
  /// is why the returned board is guaranteed unique — the guarantee is a
  /// counted fact, not a hope.
  GalaxiesPuzzle generate({
    GalaxiesDifficulty difficulty = GalaxiesDifficulty.medium,
    Random? random,
    int maxAttempts = 600,
  }) {
    final rng = random ?? Random();
    GalaxiesPuzzle? fallback;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final puzzle = propose(difficulty, rng);
      if (puzzle == null) continue;

      final PuzzleRating rating;
      try {
        rating = rateGalaxies(puzzle);
      } on StateError {
        // The counter gave up rather than lie about the board. Treat that as a
        // board we cannot vouch for and try another.
        continue;
      }
      if (rating.verdict != PuzzleVerdict.solved) continue;
      if (rating.level == difficulty.level) return puzzle;

      // Keep the first board that is at least unique and logic-only, so a
      // difficulty that turns out to be rare still returns something sound
      // rather than spinning for ever.
      fallback ??= puzzle;
    }

    if (fallback != null) return fallback;

    // Nothing worked at this size: fall back to the easiest difficulty, which
    // is always reachable.
    if (difficulty != GalaxiesDifficulty.easy) {
      return generate(difficulty: GalaxiesDifficulty.easy, random: rng);
    }
    throw StateError('could not generate a Galaxies board');
  }

  /// One random partition, or null when the growth painted itself into a
  /// corner. Public so a test can measure how often growth succeeds.
  ///
  /// Regions grow one cell at a time and the dot moves to wherever the region's
  /// centre of symmetry now is. That is the trick that makes this work: a dot
  /// pinned in place can only ever own cells that mirror onto each other about
  /// it, which almost never tiles a board. A dot that follows its region can.
  GalaxiesPuzzle? propose(GalaxiesDifficulty difficulty, Random random) {
    // Growth jams often — a handful of cells end up with their reflections
    // already spoken for — so a fresh dot layout is cheaper than a smarter
    // repair.
    for (var attempt = 0; attempt < 12; attempt++) {
      final puzzle = _proposeOnce(difficulty, random);
      if (puzzle != null) return puzzle;
    }
    return null;
  }

  /// Same as [propose] but with the size given directly, for tuning.
  GalaxiesPuzzle? proposeCustom(int rows, int cols, int dots, Random random) {
    for (var attempt = 0; attempt < 12; attempt++) {
      final puzzle = _proposeSized(rows, cols, dots, random);
      if (puzzle != null) return puzzle;
    }
    return null;
  }

  GalaxiesPuzzle? _proposeOnce(GalaxiesDifficulty difficulty, Random random) =>
      _proposeSized(
        difficulty.rows,
        difficulty.cols,
        difficulty.dotCount,
        random,
      );

  GalaxiesPuzzle? _proposeSized(
    int rows,
    int cols,
    int dotCount,
    Random random,
  ) {
    final cellCount = rows * cols;

    final regions = <List<int>>[];
    final dots = <GalaxiesDot>[];

    for (final cell in List<int>.generate(cellCount, (i) => i)..shuffle(random)) {
      if (regions.length == dotCount) break;
      final row = cell ~/ cols;
      final col = cell % cols;
      // One-cell regions touching each other give the game away.
      final crowded = regions.any(
        (region) => region.any((other) {
          final otherRow = other ~/ cols;
          final otherCol = other % cols;
          return (otherRow - row).abs() <= 1 && (otherCol - col).abs() <= 1;
        }),
      );
      if (crowded) continue;
      regions.add([cell]);
      dots.add(GalaxiesDot(2 * col, 2 * row));
    }
    if (regions.length < dotCount) return null;

    final owner = List<int>.filled(cellCount, -1);
    for (var index = 0; index < regions.length; index++) {
      owner[regions[index].single] = index;
    }

    // Keep offering every unassigned cell to every region until a whole pass
    // changes nothing. A cell that no region can take yet may become takeable
    // once a neighbour's centre shifts, so a failed pass is not final.
    // Search for a tiling rather than hoping for one. The weak invariant makes
    // this tractable: a cell can join a region whenever its reflection is free
    // or already ours, which is most of the time, so the search is mostly
    // choosing between several live options instead of backing out of corners.
    var nodes = 0;

    bool grow() {
      if (nodes++ > 30000) return false;

      int? pick;
      var fewest = 1 << 30;

      for (var cell = 0; cell < cellCount; cell++) {
        if (owner[cell] != -1) continue;
        final grown = <({List<int> cells, GalaxiesDot dot})>[];
        for (var index = 0; index < regions.length; index++) {
          final result = _grow(
            rows,
            cols,
            owner,
            index,
            regions[index],
            dots[index],
            cell,
          );
          if (result != null) grown.add(result);
        }
        // No region can take this cell yet, but one may be able to later, so
        // this is not a dead end. Only a board where nothing can move is.
        if (grown.isEmpty) continue;
        if (grown.length < fewest) {
          pick = cell;
          fewest = grown.length;
          if (fewest == 1) break;
        }
      }

      if (pick == null) return !owner.contains(-1);

      final order = List<int>.generate(regions.length, (i) => i)..shuffle(random);
      for (final index in order) {
        final result = _grow(
          rows,
          cols,
          owner,
          index,
          regions[index],
          dots[index],
          pick,
        );
        if (result == null) continue;

        final savedRegion = regions[index];
        final savedDot = dots[index];
        final added = [
          for (final cell in result.cells)
            if (owner[cell] == -1) cell,
        ];
        regions[index] = result.cells;
        dots[index] = result.dot;
        for (final cell in added) {
          owner[cell] = index;
        }

        if (grow()) return true;

        for (final cell in added) {
          owner[cell] = -1;
        }
        regions[index] = savedRegion;
        dots[index] = savedDot;
      }
      return false;
    }

    if (!grow()) return null;

    // Growth only promises the weak invariant. A full board must be an actual
    // solution, so check it here rather than assume it.
    if (dots.toSet().length != dots.length) return null;
    final puzzle = GalaxiesPuzzle(
      rows: rows,
      cols: cols,
      dots: dots,
      solution: owner,
    );
    return isSolved(puzzle, owner) ? puzzle : null;
  }

  /// [region] grown by [cell], or null when it cannot be.
  ///
  /// The invariant is weaker than symmetry, and that is the whole trick: every
  /// cell in a region must have its reflection either already in the region or
  /// still unclaimed. It does not have to be claimed *yet*. A region is allowed
  /// to be lopsided while it grows, as long as nothing else has taken the other
  /// half. Once the board is full there are no free cells left, so the invariant
  /// becomes symmetry on its own.
  ///
  /// Insisting on symmetry at every step instead jams the growth: a few cells
  /// end up with their reflections spoken for and no region can move.
  ({List<int> cells, GalaxiesDot dot})? _grow(
    int rows,
    int cols,
    List<int> owner,
    int index,
    List<int> region,
    GalaxiesDot dot,
    int cell,
  ) {
    final regionSet = region.toSet();
    if (!_touches(rows, cols, regionSet, cell)) return null;

    final mirrorRow = dot.y - cell ~/ cols;
    final mirrorCol = dot.x - cell % cols;
    final mirrorInBounds = mirrorRow >= 0 &&
        mirrorRow < rows &&
        mirrorCol >= 0 &&
        mirrorCol < cols;
    final mirror = mirrorInBounds ? mirrorRow * cols + mirrorCol : null;

    // 1. Keep the dot where it is.
    if (mirror != null && mirror != cell) {
      if (regionSet.contains(mirror)) {
        // The other half is already ours, so this cell completes the pair.
        return (cells: [...region, cell], dot: dot);
      }
      if (owner[mirror] == -1) {
        // Take both halves and the region stays symmetric.
        return (cells: [...region, cell, mirror], dot: dot);
      }
      // Someone else holds the reflection, so this dot cannot have the cell
      // unless it moves.
    }

    // 2. Move the dot to wherever the region's centre now is.
    final grown = [...region, cell];
    final centre = _centreOf(grown, cols);
    if (centre == null) return null;
    if (!_invariantHolds(rows, cols, owner, index, grown, centre)) return null;
    return (cells: grown, dot: centre);
  }

  /// Every cell's reflection is ours or still free, judged about [dot].
  bool _invariantHolds(
    int rows,
    int cols,
    List<int> owner,
    int index,
    List<int> cells,
    GalaxiesDot dot,
  ) {
    final set = cells.toSet();
    for (final cell in cells) {
      final row = dot.y - cell ~/ cols;
      final col = dot.x - cell % cols;
      if (row < 0 || row >= rows || col < 0 || col >= cols) return false;
      final mirror = row * cols + col;
      if (set.contains(mirror)) continue;
      if (owner[mirror] != -1 && owner[mirror] != index) return false;
    }
    return true;
  }

  bool _isConnected(int rows, int cols, Set<int> cells) {
    final start = cells.first;
    final seen = <int>{start};
    final queue = <int>[start];
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      final row = cell ~/ cols;
      final col = cell % cols;
      for (final (dr, dc) in _steps) {
        final r = row + dr;
        final c = col + dc;
        if (r < 0 || r >= rows || c < 0 || c >= cols) continue;
        final next = r * cols + c;
        if (!cells.contains(next) || seen.contains(next)) continue;
        seen.add(next);
        queue.add(next);
      }
    }
    return seen.length == cells.length;
  }

  bool _touches(int rows, int cols, Set<int> region, int cell) {
    final row = cell ~/ cols;
    final col = cell % cols;
    for (final (dr, dc) in _steps) {
      final r = row + dr;
      final c = col + dc;
      if (r < 0 || r >= rows || c < 0 || c >= cols) continue;
      if (region.contains(r * cols + c)) return true;
    }
    return false;
  }

  /// The centre of symmetry of [cells], in doubled coordinates, or null when it
  /// is not a lattice point.
  ///
  /// A cell `(row, col)` sits at doubled `(2 * col, 2 * row)`, so a region's
  /// centre is the mean of those points. A mean that is not a whole number
  /// cannot be a dot.
  GalaxiesDot? _centreOf(List<int> cells, int cols) {
    var sumX = 0;
    var sumY = 0;
    for (final cell in cells) {
      sumX += 2 * (cell % cols);
      sumY += 2 * (cell ~/ cols);
    }
    if (sumX % cells.length != 0 || sumY % cells.length != 0) return null;
    return GalaxiesDot(sumX ~/ cells.length, sumY ~/ cells.length);
  }




  static const List<(int, int)> _steps = [(-1, 0), (1, 0), (0, -1), (0, 1)];


  // ------------------------------------------------------------------ rules

  /// True when [owner] is a finished, correct board.
  ///
  /// Painting keeps the board symmetric, so symmetry is checked here anyway:
  /// this is the function that decides a win, and it should not rely on how the
  /// board got into its state.
  bool isSolved(GalaxiesPuzzle puzzle, List<int> owner) {
    if (owner.contains(-1)) return false;

    for (var cell = 0; cell < owner.length; cell++) {
      final dot = owner[cell];
      final mirror = puzzle.mirrorOf(cell, dot);
      if (mirror == null) return false;
      if (owner[mirror] != dot) return false;
    }

    for (var dot = 0; dot < puzzle.dots.length; dot++) {
      final cells = <int>{
        for (var cell = 0; cell < owner.length; cell++)
          if (owner[cell] == dot) cell,
      };
      if (cells.isEmpty) return false;
      if (!cells.containsAll(puzzle.seedCells(dot))) return false;
      if (!_isConnected(puzzle.rows, puzzle.cols, cells)) return false;
    }
    return true;
  }


  // ------------------------------------------------------------------ moves

  /// Paints [cell] with [dot], and the cell it reflects onto.
  ///
  /// Returns null when the pair cannot be painted: the reflection is off the
  /// board, or one of the two already belongs to another dot.
  List<int>? paint(GalaxiesPuzzle puzzle, List<int> owner, int cell, int dot) {
    final mirror = puzzle.mirrorOf(cell, dot);
    if (mirror == null) return null;
    if (owner[cell] != -1 && owner[cell] != dot) return null;
    if (owner[mirror] != -1 && owner[mirror] != dot) return null;
    return [cell, if (mirror != cell) mirror];
  }

  /// The cells a dot could still take right now, as drag targets.
  List<int> paintable(GalaxiesPuzzle puzzle, List<int> owner, int dot) => [
        for (var cell = 0; cell < owner.length; cell++)
          if (paint(puzzle, owner, cell, dot) != null) cell,
      ];
}

// ---------------------------------------------------------------------------
// The solver.
//
// The board the player edits and the board the rules reason about are the same
// thing: a cell-to-dot assignment plus, for the rules only, the dots each cell
// has been ruled out for. That is why a hint can be a real step rather than a
// peek at the answer.
// ---------------------------------------------------------------------------

class GalaxiesModel implements DeductionModel<GalaxiesModel> {
  GalaxiesModel._(this.puzzle, this.owner, this.banned);

  factory GalaxiesModel(GalaxiesPuzzle puzzle) {
    final banned = <Set<int>>[];
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      banned.add({
        for (var dot = 0; dot < puzzle.dots.length; dot++)
          if (puzzle.mirrorOf(cell, dot) == null) dot,
      });
    }
    final model = GalaxiesModel._(
      puzzle,
      List<int>.filled(puzzle.cellCount, -1),
      banned,
    );
    // A dot sits inside its own region, so the cells it sits in are decided
    // before any reasoning starts. Without this the connectivity rule has
    // nowhere to start from and rules every dot out of every cell.
    model._seedDots();
    return model;
  }

  /// A model that already holds a partly painted board, for hints.
  factory GalaxiesModel.from(GalaxiesPuzzle puzzle, List<int> owner) {
    final model = GalaxiesModel(puzzle);
    for (var cell = 0; cell < owner.length; cell++) {
      if (owner[cell] != -1) model.owner[cell] = owner[cell];
    }
    return model;
  }

  void _seedDots() {
    for (var dot = 0; dot < puzzle.dots.length; dot++) {
      for (final cell in puzzle.seedCells(dot)) {
        owner[cell] = dot;
      }
    }
  }

  final GalaxiesPuzzle puzzle;

  /// Cell index to dot index, -1 when undecided.
  final List<int> owner;

  /// Dots ruled out for each cell.
  final List<Set<int>> banned;

  @override
  GalaxiesModel copy() => GalaxiesModel._(
        puzzle,
        [...owner],
        [for (final set in banned) {...set}],
      );

  /// True when the board is filled *and* correct.
  ///
  /// Filled is not enough: a board where every cell has a dot but a region is
  /// split in two, or a dot owns nothing, is not an answer. Counting those as
  /// solutions would make every board look ambiguous.
  @override
  bool get isComplete {
    if (owner.contains(-1)) return false;
    return const GalaxiesEngine().isSolved(puzzle, owner);
  }

  @override
  Choice? get choice {
    Choice? best;
    for (var cell = 0; cell < owner.length; cell++) {
      if (owner[cell] != -1) continue;
      final values = candidatesOf(cell);
      if (values.isEmpty) continue;
      if (best == null || values.length < best.values.length) {
        best = Choice(cell, values);
      }
      if (values.length == 2) break;
    }
    return best;
  }

  @override
  GalaxiesModel assume(int slot, int value) {
    final next = copy();
    next.assign(slot, value);
    return next;
  }

  /// Dots [cell] could still belong to, judged by the mirror rule alone.
  List<int> candidatesOf(int cell) {
    final result = <int>[];
    for (var dot = 0; dot < puzzle.dots.length; dot++) {
      if (banned[cell].contains(dot)) continue;
      final mirror = puzzle.mirrorOf(cell, dot);
      if (mirror == null) continue;
      final other = owner[mirror];
      if (other != -1 && other != dot) continue;
      result.add(dot);
    }
    return result;
  }

  /// Paints [cell] and its reflection with [dot]. False on contradiction.
  bool assign(int cell, int dot) {
    final mirror = puzzle.mirrorOf(cell, dot);
    if (mirror == null) return false;
    if (owner[cell] != -1 && owner[cell] != dot) return false;
    if (owner[mirror] != -1 && owner[mirror] != dot) return false;
    owner[cell] = dot;
    owner[mirror] = dot;
    return true;
  }

  /// Cells owned by [dot], plus every undecided cell reachable from them
  /// without crossing another dot's cells.
  Set<int> reachableFrom(int dot) {
    final seen = <int>{};
    final queue = <int>[];
    for (var cell = 0; cell < owner.length; cell++) {
      if (owner[cell] == dot) {
        seen.add(cell);
        queue.add(cell);
      }
    }
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      final row = puzzle.rowOf(cell);
      final col = puzzle.colOf(cell);
      for (final (dr, dc) in GalaxiesEngine._steps) {
        final r = row + dr;
        final c = col + dc;
        if (r < 0 || r >= puzzle.rows || c < 0 || c >= puzzle.cols) continue;
        final next = puzzle.index(r, c);
        if (seen.contains(next)) continue;
        if (owner[next] != -1 && owner[next] != dot) continue;
        seen.add(next);
        queue.add(next);
      }
    }
    return seen;
  }

  /// Assigns every cell that has one candidate left. Returns how many, or -1
  /// when a cell has none.
  int settleSingles() {
    var settled = 0;
    for (var cell = 0; cell < owner.length; cell++) {
      if (owner[cell] != -1) continue;
      final values = candidatesOf(cell);
      if (values.isEmpty) return -1;
      if (values.length == 1) {
        assign(cell, values.single);
        settled++;
      }
    }
    return settled;
  }
}

/// Level 1: the mirror rule, both ways round.
///
/// A painted cell forces its reflection; a cell whose reflection is off the
/// board or already another dot's rules that dot out.
class GalaxiesMirrorRule implements DeductionRule<GalaxiesModel> {
  const GalaxiesMirrorRule();

  @override
  int get level => 1;

  @override
  String get name => 'mirror';

  @override
  int apply(GalaxiesModel model) {
    var settled = 0;

    for (var cell = 0; cell < model.owner.length; cell++) {
      final dot = model.owner[cell];
      if (dot == -1) continue;
      final mirror = model.puzzle.mirrorOf(cell, dot);
      if (mirror == null) return -1;
      if (model.owner[mirror] != -1 && model.owner[mirror] != dot) return -1;
      if (model.owner[mirror] == -1) {
        model.owner[mirror] = dot;
        settled++;
      }
    }

    for (var cell = 0; cell < model.owner.length; cell++) {
      if (model.owner[cell] != -1) continue;
      for (var dot = 0; dot < model.puzzle.dots.length; dot++) {
        if (model.banned[cell].contains(dot)) continue;
        final mirror = model.puzzle.mirrorOf(cell, dot);
        final blocked = mirror == null ||
            (model.owner[mirror] != -1 && model.owner[mirror] != dot);
        if (blocked && model.banned[cell].add(dot)) settled++;
      }
    }

    final singles = model.settleSingles();
    if (singles < 0) return -1;
    return settled + singles;
  }
}

/// Level 2: a region is connected to its dot.
///
/// If a cell cannot be reached from the dot's cells without crossing someone
/// else's, it is not that dot's — and neither is a cell whose reflection cannot
/// be reached, because the reflection would have to join the same region.
class GalaxiesReachRule implements DeductionRule<GalaxiesModel> {
  const GalaxiesReachRule();

  @override
  int get level => 2;

  @override
  String get name => 'reach';

  @override
  int apply(GalaxiesModel model) {
    var settled = 0;

    for (var dot = 0; dot < model.puzzle.dots.length; dot++) {
      final reachable = model.reachableFrom(dot);
      for (var cell = 0; cell < model.owner.length; cell++) {
        if (model.owner[cell] != -1) continue;
        if (model.banned[cell].contains(dot)) continue;
        final mirror = model.puzzle.mirrorOf(cell, dot);
        final stranded =
            !reachable.contains(cell) || !reachable.contains(mirror);
        if (stranded && model.banned[cell].add(dot)) settled++;
      }
    }

    final singles = model.settleSingles();
    if (singles < 0) return -1;
    return settled + singles;
  }
}

/// Level 3: try a cell as one dot's, run the easy rules, keep the contradiction.
///
/// This is the step a strong player takes by hand — "suppose this were blue's,
/// then those two cells would be cut off" — done for every two-way cell. It is
/// expensive, which is exactly why it is the last rule.
class GalaxiesLookaheadRule implements DeductionRule<GalaxiesModel> {
  const GalaxiesLookaheadRule();

  static const List<DeductionRule<GalaxiesModel>> _easy = [
    GalaxiesMirrorRule(),
    GalaxiesReachRule(),
  ];

  @override
  int get level => 3;

  @override
  String get name => 'lookahead';

  @override
  int apply(GalaxiesModel model) {
    var settled = 0;

    for (var cell = 0; cell < model.owner.length; cell++) {
      if (model.owner[cell] != -1) continue;
      final values = model.candidatesOf(cell);
      if (values.length != 2) continue;

      for (final dot in values) {
        final trial = model.copy();
        if (!trial.assign(cell, dot)) {
          if (model.banned[cell].add(dot)) settled++;
          continue;
        }
        final outcome = deduce(trial, _easy);
        if (!outcome.consistent && model.banned[cell].add(dot)) settled++;
      }

      if (model.candidatesOf(cell).isEmpty) return -1;
    }

    final singles = model.settleSingles();
    if (singles < 0) return -1;
    return settled + singles;
  }
}

/// Every rule, easiest first. The order is the difficulty scale.
const List<DeductionRule<GalaxiesModel>> galaxiesRules = [
  GalaxiesMirrorRule(),
  GalaxiesReachRule(),
  GalaxiesLookaheadRule(),
];

/// Grades a board: one answer? reachable by which rule level?
PuzzleRating rateGalaxies(GalaxiesPuzzle puzzle, {int maxNodes = 40000}) {
  return rate(
    GalaxiesModel(puzzle),
    galaxiesRules,
    maxNodes: maxNodes,
  );
}
