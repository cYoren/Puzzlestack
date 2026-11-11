/// Netslide: a net of pipes on a grid. Slide a whole row or column one square and
/// the tiles shuffle round; the pipes never rotate, so position is the only thing
/// you can change. Get every pipe to meet its neighbour.
///
/// Ported from Tatham's `netslide.c` (a cross between Net and Sixteen, courtesy
/// of Richard Boulton). The rule that makes it a puzzle is the barrier: a row or
/// column with a wall crossing it cannot slide, so the grid is not one big
/// puzzle but a set of shuttles.
///
/// **Generation is by construction, not by search.** A solved board is built
/// first — a single loop through every cell, with walls on the edges the loop
/// does not use — and then scrambled by legal slides. The scramble is exactly
/// invertible, so the board is solvable by the reverse of the move that made it,
/// and the test proves it by replaying that reverse.
///
/// The solved loop always exists because a Hamiltonian **cycle** needs an even
/// number of cells on a bipartite grid, and every tier here has one. The random
/// attempt is only a nicety: if it does not land, the serpentine fallback cannot
/// fail.
library;

import 'dart:math';

/// Connection bits, in the order [NetDirection] declares them.
abstract final class NetBits {
  static const int east = 1;
  static const int south = 2;
  static const int west = 4;
  static const int north = 8;
}

enum NetDirection { east, south, west, north }

int _bit(NetDirection direction) => switch (direction) {
      NetDirection.east => NetBits.east,
      NetDirection.south => NetBits.south,
      NetDirection.west => NetBits.west,
      NetDirection.north => NetBits.north,
    };

int _opposite(NetDirection direction) => switch (direction) {
      NetDirection.east => NetBits.west,
      NetDirection.south => NetBits.north,
      NetDirection.west => NetBits.east,
      NetDirection.north => NetBits.south,
    };

class NetPuzzle {
  const NetPuzzle({
    required this.rows,
    required this.cols,
    required this.masks,
    required this.solvedMasks,
    required this.walls,
    required this.scrambles,
    this.scrambleMoves = const [],
  });

  final int rows;
  final int cols;

  /// The board the player starts on, one connection mask per cell.
  final List<int> masks;

  /// The board they are aiming at. Kept so the end of the game can be named and
  /// so a test can prove the scramble is invertible.
  final List<int> solvedMasks;

  /// Walls, as `row * cols + col -> bits`, where the bit is the side of the cell
  /// the wall is on.
  final Map<int, int> walls;

  /// How many slides the generator used. Not the shortest solution — a sliding
  /// puzzle does not work that way — but a floor on how scrambled it is.
  final int scrambles;

  /// The slides that scrambled the board, in order. Kept so a test can undo them
  /// and prove the board is solvable, rather than trusting the construction.
  final List<({bool row, int index, bool forward})> scrambleMoves;

  int get cellCount => rows * cols;

  bool hasWall(int cell, NetDirection direction) =>
      (walls[cell] ?? 0) & _bit(direction) != 0;
}

enum NetDifficulty {
  easy(4, 4, 8),
  medium(5, 6, 14),
  hard(6, 6, 20);

  const NetDifficulty(this.rows, this.cols, this.scrambles);

  final int rows;
  final int cols;

  /// Slides applied to the solved board. More slides means more work to undo,
  /// though slides can cancel each other out.
  final int scrambles;

  /// A Hamiltonian cycle needs an even cell count on a bipartite grid, and so
  /// does every board here.
  bool get isEvenAsExpected => (rows * cols).isEven;
}

class NetEngine {
  const NetEngine();

  int _index(int row, int col, int cols) => row * cols + col;

  /// Slides a row one square east, or a column one square south.
  ///
  /// A slide is a **cyclic shift**: the tile that falls off one end comes back on
  /// the other, which is why the move is exactly invertible. A row or column with
  /// a wall across it cannot slide at all.
  List<int>? slide(
    NetPuzzle puzzle,
    List<int> masks, {
    required bool row,
    required int index,
    required bool forward,
  }) {
    if (!_canSlide(puzzle, row: row, index: index, forward: forward)) return null;
    final out = [...masks];

    if (row) {
      final start = _index(index, 0, puzzle.cols);
      final line = [for (var c = 0; c < puzzle.cols; c++) out[start + c]];
      final shifted = forward
          ? [line.last, ...line.sublist(0, line.length - 1)]
          : [...line.sublist(1), line.first];
      for (var c = 0; c < puzzle.cols; c++) {
        out[start + c] = shifted[c];
      }
    } else {
      final line = [for (var r = 0; r < puzzle.rows; r++) out[_index(r, index, puzzle.cols)]];
      final shifted = forward
          ? [line.last, ...line.sublist(0, line.length - 1)]
          : [...line.sublist(1), line.first];
      for (var r = 0; r < puzzle.rows; r++) {
        out[_index(r, index, puzzle.cols)] = shifted[r];
      }
    }
    return out;
  }

  /// A row can slide when no wall crosses it; a column likewise.
  bool _canSlide(
    NetPuzzle puzzle, {
    required bool row,
    required int index,
    required bool forward,
  }) {
    if (row) {
      for (var c = 0; c + 1 < puzzle.cols; c++) {
        if (puzzle.hasWall(_index(index, c, puzzle.cols), NetDirection.east)) {
          return false;
        }
      }
      return true;
    }
    for (var r = 0; r + 1 < puzzle.rows; r++) {
      if (puzzle.hasWall(_index(r, index, puzzle.cols), NetDirection.south)) {
        return false;
      }
    }
    return true;
  }

  /// True when every pipe meets a pipe: no half-edge faces a wall or the edge of
  /// the board.
  bool isSolved(NetPuzzle puzzle, List<int> masks) {
    for (var row = 0; row < puzzle.rows; row++) {
      for (var col = 0; col < puzzle.cols; col++) {
        final cell = _index(row, col, puzzle.cols);
        for (final direction in NetDirection.values) {
          if (masks[cell] & _bit(direction) == 0) continue;
          final (dr, dc) = switch (direction) {
            NetDirection.east => (0, 1),
            NetDirection.south => (1, 0),
            NetDirection.west => (0, -1),
            NetDirection.north => (-1, 0),
          };
          final nextRow = row + dr;
          final nextCol = col + dc;
          if (nextRow < 0 || nextRow >= puzzle.rows) return false;
          if (nextCol < 0 || nextCol >= puzzle.cols) return false;
          if (puzzle.hasWall(cell, direction)) return false;
          final other = _index(nextRow, nextCol, puzzle.cols);
          if (masks[other] & _opposite(direction) == 0) return false;
        }
      }
    }
    return true;
  }

  // --------------------------------------------------------------- generator

  NetPuzzle generate(NetDifficulty difficulty, {Random? random}) {
    final rng = random ?? Random();
    final rows = difficulty.rows;
    final cols = difficulty.cols;
    assert(difficulty.isEvenAsExpected);

    final loops = _randomCycle(rows, cols, rng) ?? _ladderLoops(rows, cols);
    final solved = List<int>.filled(rows * cols, 0);
    // Each loop closes on itself, so the wrap is per loop and not per board.
    for (final loop in loops) {
      for (var i = 0; i < loop.length; i++) {
        final cell = loop[i];
        final previous = loop[(i - 1 + loop.length) % loop.length];
        final next = loop[(i + 1) % loop.length];
        solved[cell] = _bitsTowards(cell, previous, cols) |
            _bitsTowards(cell, next, cols);
      }
    }

    // Walls only where the loop does not already cross: a wall through a pipe
    // would make the solved board unsolvable.
    final walls = <int, int>{};
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final cell = _index(row, col, cols);
        if (col + 1 < cols &&
            solved[cell] & NetBits.east == 0 &&
            solved[cell + 1] & NetBits.west == 0 &&
            rng.nextBool()) {
          walls[cell] = (walls[cell] ?? 0) | NetBits.east;
          walls[cell + 1] = (walls[cell + 1] ?? 0) | NetBits.west;
        }
        if (row + 1 < rows &&
            solved[cell] & NetBits.south == 0 &&
            solved[cell + cols] & NetBits.north == 0 &&
            rng.nextBool()) {
          walls[cell] = (walls[cell] ?? 0) | NetBits.south;
          walls[cell + cols] = (walls[cell + cols] ?? 0) | NetBits.north;
        }
      }
    }

    final empty = NetPuzzle(
      rows: rows,
      cols: cols,
      masks: solved,
      solvedMasks: solved,
      walls: walls,
      scrambles: 0,
    );


    // Scramble. A slide that undoes the previous one would waste a move, so the
    // generator refuses to reverse itself.
    var masks = [...solved];
    final appliedMoves = <({bool row, int index, bool forward})>[];
    var applied = 0;
    ({bool row, int index, bool forward})? last;
    var guard = 0;
    while (applied < difficulty.scrambles && guard++ < difficulty.scrambles * 20) {
      final isRow = rng.nextBool();
      final index = rng.nextInt(isRow ? rows : cols);
      final forward = rng.nextBool();
      if (last != null &&
          last.row == isRow &&
          last.index == index &&
          last.forward != forward) {
        continue;
      }
      final next = slide(empty, masks,
          row: isRow, index: index, forward: forward);
      if (next == null) continue;
      masks = next;
      last = (row: isRow, index: index, forward: forward);
      appliedMoves.add(last);
      applied++;
    }

    final puzzle = NetPuzzle(
      rows: rows,
      cols: cols,
      masks: masks,
      solvedMasks: solved,
      walls: walls,
      scrambles: applied,
      scrambleMoves: appliedMoves,
    );
    // A scramble that happens to land solved is not a puzzle.
    if (isSolved(puzzle, masks)) return generate(difficulty, random: rng);
    return puzzle;
  }

  /// A random Hamiltonian cycle, or null when the walk got stuck.
  List<List<int>>? _randomCycle(int rows, int cols, Random rng) {
    final total = rows * cols;
    final path = <int>[0];
    final seen = <int>{0};
    var steps = 0;

    bool walk() {
      if (++steps > 200000) return false;
      if (path.length == total) {
        return _adjacent(path.last, path.first, cols);
      }
      final options = [
        for (final next in _neighbours(path.last, rows, cols))
          if (!seen.contains(next)) next,
      ]..shuffle(rng);
      for (final next in options) {
        // Do not close the loop early: the last cell must be the one that can
        // reach the start.
        if (seen.length == total - 1 && !_adjacent(next, 0, cols)) continue;
        path.add(next);
        seen.add(next);
        if (walk()) return true;
        path.removeLast();
        seen.remove(next);
      }
      return false;
    }

    return walk() ? [path] : null;
  }

  /// The fallback: ladders, a construction that cannot fail.
  ///
  /// Two adjacent columns form a loop — down the left, across the bottom, up the
  /// right, across the top — so a board with an even number of columns is always
  /// covered and every cell has exactly two pipes. It is several loops rather
  /// than one, which the win condition does not mind: what matters is that every
  /// pipe meets a pipe.
  ///
  /// A serpentine was the first fallback and it was wrong: its two ends are
  /// diagonally opposite, so it does not close and the cell at the join came out
  /// with one pipe. The test caught it on 5x6.
  List<List<int>> _ladderLoops(int rows, int cols) {
    final loops = <List<int>>[];
    for (var pair = 0; pair * 2 + 1 < cols; pair++) {
      final left = pair * 2;
      final right = left + 1;
      final loop = <int>[
        for (var row = 0; row < rows; row++) _index(row, left, cols),
        for (var row = rows - 1; row >= 0; row--) _index(row, right, cols),
      ];
      loops.add(loop);
    }
    return loops;
  }

  List<int> _neighbours(int cell, int rows, int cols) {
    final row = cell ~/ cols;
    final col = cell % cols;
    return [
      if (row > 0) cell - cols,
      if (row + 1 < rows) cell + cols,
      if (col > 0) cell - 1,
      if (col + 1 < cols) cell + 1,
    ];
  }

  bool _adjacent(int a, int b, int cols) {
    final rowA = a ~/ cols;
    final colA = a % cols;
    final rowB = b ~/ cols;
    final colB = b % cols;
    return (rowA == rowB && (colA - colB).abs() == 1) ||
        (colA == colB && (rowA - rowB).abs() == 1);
  }

  int _bitsTowards(int from, int to, int cols) {
    final rowFrom = from ~/ cols;
    final colFrom = from % cols;
    final rowTo = to ~/ cols;
    final colTo = to % cols;
    if (rowTo == rowFrom && colTo == colFrom + 1) return NetBits.east;
    if (rowTo == rowFrom && colTo == colFrom - 1) return NetBits.west;
    if (colTo == colFrom && rowTo == rowFrom + 1) return NetBits.south;
    if (colTo == colFrom && rowTo == rowFrom - 1) return NetBits.north;
    return 0;
  }

  /// A row, a column, or a cell the player could slide next, for the hint.
  ({bool row, int index, bool forward})? hint(NetPuzzle puzzle, List<int> masks) {
    // The hint is a slide that makes a pipe meet another pipe: a step the player
    // can see the point of without being told the answer.
    for (var row = 0; row < puzzle.rows; row++) {
      for (final forward in [true, false]) {
        final next = slide(puzzle, masks, row: true, index: row, forward: forward);
        if (next == null) continue;
        if (_matches(puzzle, next) > _matches(puzzle, masks)) {
          return (row: true, index: row, forward: forward);
        }
      }
    }
    for (var col = 0; col < puzzle.cols; col++) {
      for (final forward in [true, false]) {
        final next = slide(puzzle, masks, row: false, index: col, forward: forward);
        if (next == null) continue;
        if (_matches(puzzle, next) > _matches(puzzle, masks)) {
          return (row: false, index: col, forward: forward);
        }
      }
    }
    return null;
  }

  /// How many half-edges currently meet a neighbour's half-edge.
  int _matches(NetPuzzle puzzle, List<int> masks) {
    var count = 0;
    for (var row = 0; row < puzzle.rows; row++) {
      for (var col = 0; col < puzzle.cols; col++) {
        final cell = _index(row, col, puzzle.cols);
        for (final direction in NetDirection.values) {
          if (masks[cell] & _bit(direction) == 0) continue;
          final (dr, dc) = switch (direction) {
            NetDirection.east => (0, 1),
            NetDirection.south => (1, 0),
            NetDirection.west => (0, -1),
            NetDirection.north => (-1, 0),
          };
          final nextRow = row + dr;
          final nextCol = col + dc;
          if (nextRow < 0 || nextRow >= puzzle.rows) continue;
          if (nextCol < 0 || nextCol >= puzzle.cols) continue;
          if (puzzle.hasWall(cell, direction)) continue;
          final other = _index(nextRow, nextCol, puzzle.cols);
          if (masks[other] & _opposite(direction) != 0) count++;
        }
      }
    }
    return count;
  }
}
