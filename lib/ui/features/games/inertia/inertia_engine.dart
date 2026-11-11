/// Inertia: a ball on a grid of walls, gems and mines. Pick a direction and the
/// ball slides until a wall or a mine stops it — it cannot stop halfway. Collect
/// every gem without touching a mine.
///
/// Ported from Tatham's `inertia.c` (rules and generator idea by Ben Olmstead),
/// with one deliberate change: **this build is turn-based and four-directional.**
/// Tatham's is eight-directional and animates the slide; the physics is the same
/// puzzle, and removing the diagonals costs nothing but ambiguity about which
/// square the ball is heading for.
///
/// The bar is Pegs' bar, not a deduction puzzle's: a board ships only when a
/// breadth-first walk from the start finds a line that collects every gem
/// without touching a mine, so "solvable" is proved rather than hoped for.
library;

import 'dart:math';

enum CellKind { wall, floor, gem, mine }

class InertiaPuzzle {
  const InertiaPuzzle({
    required this.rows,
    required this.cols,
    required this.kinds,
    required this.start,
    required this.gemCells,
    required this.minMoves,
  });

  final int rows;
  final int cols;

  /// Row-major terrain. Gems here are the *initial* terrain; once collected a
  /// gem cell behaves as floor, which is why play tracks collected gems
  /// separately.
  final List<CellKind> kinds;

  final int start;

  /// Every gem cell, in a stable order — the index in this list is the bit that
  /// says whether it has been collected.
  final List<int> gemCells;

  /// The shortest line that collects every gem, measured at generation.
  final int minMoves;

  int get cellCount => rows * cols;

  int get gemCount => gemCells.length;

  CellKind kindAt(int cell) => kinds[cell];

  bool isWall(int cell) => kinds[cell] == CellKind.wall;

  bool isMine(int cell) => kinds[cell] == CellKind.mine;
}

enum InertiaDifficulty {
  easy(6, 6, 3, 3, 12),
  medium(7, 7, 4, 4, 16),
  hard(8, 8, 5, 5, 22);

  const InertiaDifficulty(
    this.rows,
    this.cols,
    this.gems,
    this.mines,
    this.maxMoves,
  );

  final int rows;
  final int cols;
  final int gems;
  final int mines;

  /// The longest shortest-line a board of this tier may need. Generation is a
  /// search: this bounds it.
  final int maxMoves;
}

/// Where the ball is and which gems are gone.
class InertiaPosition {
  const InertiaPosition({
    required this.cell,
    required this.collected,
    this.exploded = false,
  });

  final int cell;

  /// One bit per gem in [InertiaPuzzle.gemCells].
  final int collected;

  /// True when the last move ran into a mine.
  final bool exploded;

  InertiaPosition copyWith({int? cell, int? collected, bool? exploded}) =>
      InertiaPosition(
        cell: cell ?? this.cell,
        collected: collected ?? this.collected,
        exploded: exploded ?? this.exploded,
      );
}

/// The four directions, as row/column deltas.
enum InertiaDirection { north, south, east, west }

class InertiaEngine {
  const InertiaEngine();

  static int _delta(InertiaDirection direction, int cols) => switch (direction) {
        InertiaDirection.north => -cols,
        InertiaDirection.south => cols,
        InertiaDirection.east => 1,
        InertiaDirection.west => -1,
      };

  /// The cell the ball ends on, sliding [position] in [direction].
  ///
  /// Returns the landing cell and whether the ball met a mine on the way. The
  /// ball stops before a mine — a mine is not a wall you lean on, it is a thing
  /// you must not touch — so a slide that would reach one is a loss, not a stop.
  ({int cell, bool exploded}) slide(
    InertiaPuzzle puzzle,
    InertiaPosition position,
    InertiaDirection direction,
  ) {
    final step = _delta(direction, puzzle.cols);
    var cell = position.cell;
    var next = cell + step;

    while (true) {
      if (next < 0 || next >= puzzle.cellCount) break;
      // A horizontal move must not wrap.
      if (direction == InertiaDirection.east && next % puzzle.cols == 0) break;
      if (direction == InertiaDirection.west &&
          cell % puzzle.cols == 0) {
        break;
      }
      if (puzzle.isWall(next)) break;
      if (puzzle.isMine(next)) return (cell: cell, exploded: true);
      cell = next;
      next = cell + step;
    }
    return (cell: cell, exploded: false);
  }

  /// Applies one move: slides, explodes, and picks up the gem it lands on.
  InertiaPosition move(
    InertiaPuzzle puzzle,
    InertiaPosition position,
    InertiaDirection direction,
  ) {
    if (position.exploded) return position;
    final result = slide(puzzle, position, direction);
    if (result.exploded) {
      return position.copyWith(cell: result.cell, exploded: true);
    }
    var collected = position.collected;
    final gem = puzzle.gemCells.indexOf(result.cell);
    if (gem >= 0) collected |= 1 << gem;
    return InertiaPosition(cell: result.cell, collected: collected);
  }

  /// True when every gem is gone.
  bool isSolved(InertiaPuzzle puzzle, InertiaPosition position) =>
      position.collected == (1 << puzzle.gemCount) - 1;

  /// The cell a move in [direction] would land on, or null when it moves
  /// nowhere.
  int? landing(InertiaPuzzle puzzle, InertiaPosition position, InertiaDirection direction) {
    final result = slide(puzzle, position, direction);
    if (result.exploded) return null;
    if (result.cell == position.cell) return null;
    return result.cell;
  }

  // --------------------------------------------------------------- generator

  InertiaPuzzle generate(InertiaDifficulty difficulty, {Random? random}) {
    final rng = random ?? Random();
    final rows = difficulty.rows;
    final cols = difficulty.cols;

    for (var attempt = 0; attempt < 600; attempt++) {
      final kinds = _randomTerrain(rows, cols, difficulty.mines, rng);
      final floors = [
        for (var cell = 0; cell < kinds.length; cell++)
          if (kinds[cell] == CellKind.floor) cell,
      ];
      if (floors.length < difficulty.gems + 6) continue;
      final start = floors[rng.nextInt(floors.length)];

      // Gems can only sit where a slide can end. A ball never stops in the open
      // middle of a room — it stops against a wall — so a gem placed there is
      // unreachable and the board is dead. Asking the slide graph first is the
      // difference between a 0% and a 90% hit rate on small boards.
      final landings = _landings(kinds, rows, cols, start)..remove(start);
      if (landings.length < difficulty.gems) continue;
      final pool = [...landings]..shuffle(rng);

      for (var pick = 0; pick < 40; pick++) {
        final gemCells = pool.take(difficulty.gems).toList();
        // A fresh draw of gems on the same terrain is much cheaper than a fresh
        // terrain, and most failures are one badly placed gem.
        for (var i = 0; i < difficulty.gems && pool.length > difficulty.gems; i++) {
          if (pick == 0) break;
          gemCells[i] = pool[(i + pick) % pool.length];
        }
        if (gemCells.toSet().length < difficulty.gems) continue;

        final board = [...kinds];
        for (final cell in gemCells) {
          if (board[cell] != CellKind.floor) break;
          board[cell] = CellKind.gem;
        }
        if (board.where((k) => k == CellKind.gem).length != difficulty.gems) {
          continue;
        }

        final puzzle = InertiaPuzzle(
          rows: rows,
          cols: cols,
          kinds: board,
          start: start,
          gemCells: gemCells,
          minMoves: 0,
        );
        final line = solve(puzzle, maxMoves: difficulty.maxMoves);
        if (line == null || line.isEmpty) continue;
        return InertiaPuzzle(
          rows: rows,
          cols: cols,
          kinds: board,
          start: start,
          gemCells: gemCells,
          minMoves: line.length,
        );
      }
    }
    throw StateError('could not build a solvable $rows x $cols Inertia board');
  }

  /// Every cell a slide can end on, starting from [start].
  Set<int> _landings(List<CellKind> kinds, int rows, int cols, int start) {
    final seen = <int>{start};
    final queue = [start];
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      for (final direction in InertiaDirection.values) {
        var cursor = cell;
        var next = cursor + _delta(direction, cols);
        while (next >= 0 && next < kinds.length) {
          if (direction == InertiaDirection.east && next % cols == 0) break;
          if (direction == InertiaDirection.west && cursor % cols == 0) break;
          final kind = kinds[next];
          if (kind == CellKind.wall || kind == CellKind.mine) break;
          cursor = next;
          next = cursor + _delta(direction, cols);
        }
        if (cursor != cell && seen.add(cursor)) queue.add(cursor);
      }
    }
    return seen;
  }

  List<CellKind> _randomTerrain(int rows, int cols, int mines, Random rng) {
    final kinds = List<CellKind>.filled(rows * cols, CellKind.floor);
    // Walls around the inside: a border keeps the ball on the board without a
    // special case in the slide, and makes the play area read clearly.
    for (var cell = 0; cell < kinds.length; cell++) {
      final row = cell ~/ cols;
      final col = cell % cols;
      if (row == 0 || col == 0 || row == rows - 1 || col == cols - 1) {
        kinds[cell] = CellKind.wall;
      }
    }
    // A few walls inside, but not so many that the ball cannot move: every
    // floor cell must have at least one open direction from somewhere, and the
    // solver rejects boards it cannot solve anyway.
    final inner = [
      for (var cell = 0; cell < kinds.length; cell++)
        if (kinds[cell] == CellKind.floor) cell,
    ];
    final wallCount = (inner.length * 0.16).round();
    for (var i = 0; i < wallCount; i++) {
      kinds[inner[rng.nextInt(inner.length)]] = CellKind.wall;
    }
    final open = [
      for (var cell = 0; cell < kinds.length; cell++)
        if (kinds[cell] == CellKind.floor) cell,
    ]..shuffle(rng);
    for (var i = 0; i < mines && i < open.length; i++) {
      kinds[open[i]] = CellKind.mine;
    }
    return kinds;
  }

  InertiaPosition startOf(InertiaPuzzle puzzle) =>
      InertiaPosition(cell: puzzle.start, collected: 0);

  // ------------------------------------------------------------------ solver

  /// The shortest line that collects every gem, or null when there is none
  /// within [maxMoves].
  ///
  /// A breadth-first walk over (cell, collected), which is small: a 7x7 board
  /// with five gems is at most 49 x 32 states.
  List<InertiaDirection>? solve(InertiaPuzzle puzzle, {int? maxMoves}) {
    final from = startOf(puzzle);
    final seen = <int>{_key(puzzle, from)};
    final parents = <int, (int, InertiaDirection)>{};
    var frontier = [from];
    var depth = 0;

    while (frontier.isNotEmpty) {
      if (maxMoves != null && depth >= maxMoves) return null;
      final next = <InertiaPosition>[];
      for (final position in frontier) {
        for (final direction in InertiaDirection.values) {
          final moved = move(puzzle, position, direction);
          if (moved.exploded) continue;
          if (moved.cell == position.cell && moved.collected == position.collected) {
            continue;
          }
          final key = _key(puzzle, moved);
          if (!seen.add(key)) continue;
          parents[key] = (_key(puzzle, position), direction);
          if (isSolved(puzzle, moved)) {
            final line = <InertiaDirection>[];
            var cursor = key;
            final startKey = _key(puzzle, from);
            while (cursor != startKey) {
              final parent = parents[cursor]!;
              line.insert(0, parent.$2);
              cursor = parent.$1;
            }
            return line;
          }
          next.add(moved);
        }
      }
      frontier = next;
      depth++;
    }
    return null;
  }

  int _key(InertiaPuzzle puzzle, InertiaPosition position) =>
      position.cell | (position.collected << 7);

  /// The first move of a shortest line, for the hint.
  InertiaDirection? hint(InertiaPuzzle puzzle, InertiaPosition position) {
    final line = solveFrom(puzzle, position);
    return line == null || line.isEmpty ? null : line.first;
  }

  /// The shortest line from an arbitrary position — what the hint needs.
  List<InertiaDirection>? solveFrom(InertiaPuzzle puzzle, InertiaPosition from) {
    if (isSolved(puzzle, from)) return const [];
    final seen = <int>{_key(puzzle, from)};
    final parents = <int, (int, InertiaDirection)>{};
    var frontier = [from];

    while (frontier.isNotEmpty) {
      final next = <InertiaPosition>[];
      for (final position in frontier) {
        for (final direction in InertiaDirection.values) {
          final moved = move(puzzle, position, direction);
          if (moved.exploded) continue;
          if (moved.cell == position.cell && moved.collected == position.collected) {
            continue;
          }
          final key = _key(puzzle, moved);
          if (!seen.add(key)) continue;
          parents[key] = (_key(puzzle, position), direction);
          if (isSolved(puzzle, moved)) {
            final line = <InertiaDirection>[];
            var cursor = key;
            final startKey = _key(puzzle, from);
            while (cursor != startKey) {
              final parent = parents[cursor]!;
              line.insert(0, parent.$2);
              cursor = parent.$1;
            }
            return line;
          }
          next.add(moved);
        }
      }
      frontier = next;
    }
    return null;
  }
}
