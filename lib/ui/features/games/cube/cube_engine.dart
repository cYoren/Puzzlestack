/// Cube: roll a cube over a grid. Landing on a square **swaps** the cube's
/// bottom face with that square's colour. Collect every blue square, and finish
/// with all six faces blue.
///
/// Ported from Tatham's `cube.c` for the cube on a square grid. Two
/// simplifications, both deliberate:
///
///  * no tetrahedron, octahedron or icosahedron — the triangular grids would be
///    a second renderer for the same idea;
///  * Tatham places six blue squares and trusts that a cube can always collect
///    them. This generator **searches** instead: a board ships only when a
///    breadth-first walk finds a line that clears it, so "solvable" is a fact
///    about the board rather than a hope about the geometry.
///
/// One invariant does the heavy lifting. A swap moves a colour between a face
/// and a square and never creates or destroys one, and the board starts with six
/// blues, so **a position is solved exactly when all six faces are blue**.
library;

import 'dart:math';

/// Face indices, in the order the engine stores them.
abstract final class CubeFace {
  static const int bottom = 0;
  static const int top = 1;
  static const int north = 2;
  static const int south = 3;
  static const int east = 4;
  static const int west = 5;

  static const int count = 6;

  /// All six faces blue: the win.
  static const int solvedMask = 0x3F;
}

enum CubeDirection { north, south, east, west }

class CubePuzzle {
  const CubePuzzle({
    required this.rows,
    required this.cols,
    required this.targets,
    required this.start,
    required this.minMoves,
  });

  final int rows;
  final int cols;

  /// The six cells that start blue.
  final List<int> targets;

  /// Where the cube starts — always a square that is not blue.
  final int start;

  /// The length of the shortest line that clears the board.
  final int minMoves;

  int get cellCount => rows * cols;

  bool isTarget(int cell) => targets.contains(cell);
}

enum CubeDifficulty {
  easy(4, 4, 1, 9),
  medium(5, 5, 10, 13),
  hard(5, 5, 14, 18);

  const CubeDifficulty(this.rows, this.cols, this.minMoves, this.maxMoves);

  final int rows;
  final int cols;

  /// The band of optimal line lengths this tier means. Two tiers share a grid
  /// size on purpose: the size is not the difficulty, the length of the best
  /// line is.
  final int minMoves;
  final int maxMoves;
}

/// A board during play.
class CubePosition {
  const CubePosition({
    required this.cell,
    required this.faces,
    required this.squares,
  });

  final int cell;

  /// Six 0/1 values, indexed by [CubeFace].
  final List<int> faces;

  /// One 0/1 value per cell: 1 means the square is painted.
  final List<int> squares;

  int get paintedFaces => faces.where((f) => f == 1).length;

  /// Six blues on the board and six places to put them: all six faces blue.
  bool get isSolved => faces.every((f) => f == 1);

  CubePosition copyWith({int? cell, List<int>? faces, List<int>? squares}) =>
      CubePosition(
        cell: cell ?? this.cell,
        faces: faces ?? this.faces,
        squares: squares ?? this.squares,
      );
}

class CubeEngine {
  const CubeEngine();

  /// The roll permutations, as bit positions: output face `i` comes from input
  /// face `out[i]`.
  ///
  /// Rolling north tips the cube over its north-bottom edge, so the bottom face
  /// swings up to face north, north goes to the top, the top faces south and the
  /// south face lands on the bottom. East and west do not move.
  static const Map<CubeDirection, List<int>> _permutation = {
    CubeDirection.north: [
      CubeFace.south, // bottom from south
      CubeFace.north, // top from north
      CubeFace.bottom, // north from bottom
      CubeFace.top, // south from top
      CubeFace.east,
      CubeFace.west,
    ],
    CubeDirection.south: [
      CubeFace.north,
      CubeFace.south,
      CubeFace.top,
      CubeFace.bottom,
      CubeFace.east,
      CubeFace.west,
    ],
    CubeDirection.east: [
      CubeFace.west,
      CubeFace.east,
      CubeFace.north,
      CubeFace.south,
      CubeFace.bottom,
      CubeFace.top,
    ],
    CubeDirection.west: [
      CubeFace.east,
      CubeFace.west,
      CubeFace.north,
      CubeFace.south,
      CubeFace.top,
      CubeFace.bottom,
    ],
  };

  // ------------------------------------------------------------- packed state

  /// The state as one int: `squares | faces << cells | cell << (cells + 6)`.
  ///
  /// Packed because the solver builds a visited set of up to 25 x 64 x 64
  /// entries, and hashing a list per state cost seconds a board.
  int encode(CubePosition position) {
    final cells = position.squares.length;
    var squares = 0;
    for (var i = 0; i < cells; i++) {
      if (position.squares[i] == 1) squares |= 1 << i;
    }
    var faces = 0;
    for (var i = 0; i < CubeFace.count; i++) {
      if (position.faces[i] == 1) faces |= 1 << i;
    }
    return squares | (faces << cells) | (position.cell << (cells + CubeFace.count));
  }

  CubePosition decode(int code, int cells) {
    final squares = List<int>.filled(cells, 0);
    for (var i = 0; i < cells; i++) {
      if (code & (1 << i) != 0) squares[i] = 1;
    }
    final faces = List<int>.filled(CubeFace.count, 0);
    for (var i = 0; i < CubeFace.count; i++) {
      if ((code >> cells) & (1 << i) != 0) faces[i] = 1;
    }
    return CubePosition(
      cell: code >> (cells + CubeFace.count),
      faces: faces,
      squares: squares,
    );
  }

  /// One roll on the packed state. -1 when the move would leave the grid.
  int _advance(int code, CubeDirection direction, int rows, int cols) {
    final cells = rows * cols;
    final cell = code >> (cells + CubeFace.count);
    final row = cell ~/ cols;
    final col = cell % cols;
    final next = switch (direction) {
      CubeDirection.north => row > 0 ? cell - cols : -1,
      CubeDirection.south => row + 1 < rows ? cell + cols : -1,
      CubeDirection.east => col + 1 < cols ? cell + 1 : -1,
      CubeDirection.west => col > 0 ? cell - 1 : -1,
    };
    if (next < 0) return -1;

    final faces = (code >> cells) & CubeFace.solvedMask;
    final squares = code & ((1 << cells) - 1);

    final order = _permutation[direction]!;
    var rolled = 0;
    for (var i = 0; i < CubeFace.count; i++) {
      if (faces & (1 << order[i]) != 0) rolled |= 1 << i;
    }

    // Land: swap the bottom face with the square under the cube.
    final bottom = rolled & 1;
    final landed = (squares >> next) & 1;
    final newFaces = (rolled & ~1) | landed;
    final newSquares = (squares & ~(1 << next)) | bottom;

    return newSquares | (newFaces << cells) | (next << (cells + CubeFace.count));
  }

  /// The position after rolling one square.
  ///
  /// This and the solver share **one** implementation of a roll, the packed one.
  /// Written twice — once on lists, once on bits — the two drifted: five of
  /// fifteen replayed boards ended a move short, which reads as "the board
  /// cannot be solved" and is really "the two rolls disagree".
  CubePosition roll(
    CubePuzzle puzzle,
    CubePosition position,
    CubeDirection direction,
  ) {
    final cells = puzzle.cellCount;
    final code = _advance(encode(position), direction, puzzle.rows, puzzle.cols);
    if (code < 0) return position;

    final moved = decode(code, cells);
    // A finished cube keeps rolling, but stops swapping: every face is blue by
    // then, so a swap could only take the win back.
    if (position.isSolved) return moved.copyWith(faces: position.faces);
    return moved;
  }

  // --------------------------------------------------------------- generator

  CubePuzzle generate(CubeDifficulty difficulty, {Random? random}) {
    final rng = random ?? Random();
    final rows = difficulty.rows;
    final cols = difficulty.cols;
    final cells = List<int>.generate(rows * cols, (i) => i);

    for (var attempt = 0; attempt < 4000; attempt++) {
      final shuffled = [...cells]..shuffle(rng);
      final start = shuffled.first;
      final targets = shuffled.skip(1).take(CubeFace.count).toList();

      final candidate = CubePuzzle(
        rows: rows,
        cols: cols,
        targets: targets,
        start: start,
        minMoves: 0,
      );
      final line = solve(
        candidate,
        startOf(candidate),
        maxMoves: difficulty.maxMoves,
      );
      if (line == null) continue;
      if (line.length < difficulty.minMoves) continue;
      return CubePuzzle(
        rows: rows,
        cols: cols,
        targets: targets,
        start: start,
        minMoves: line.length,
      );
    }
    throw StateError('could not build a $rows x $cols Cube board in the band');
  }

  /// The board before the first move: six blue squares, a clean cube.
  CubePosition startOf(CubePuzzle puzzle) {
    final squares = List<int>.filled(puzzle.cellCount, 0);
    for (final cell in puzzle.targets) {
      squares[cell] = 1;
    }
    return CubePosition(
      cell: puzzle.start,
      faces: List<int>.filled(CubeFace.count, 0),
      squares: squares,
    );
  }

  // ------------------------------------------------------------------ solver

  /// The shortest line that clears the board, or null when no line does it in
  /// [maxMoves] moves.
  List<CubeDirection>? solve(
    CubePuzzle puzzle,
    CubePosition from, {
    int? maxMoves,
  }) {
    if (from.isSolved) return const [];

    final cells = puzzle.cellCount;
    final startCode = encode(from);
    final seen = <int>{startCode};
    final parents = <int, (int, CubeDirection)>{};
    var frontier = <int>[startCode];
    var depth = 0;

    while (frontier.isNotEmpty) {
      if (maxMoves != null && depth >= maxMoves) return null;
      final next = <int>[];
      for (final code in frontier) {
        for (final direction in CubeDirection.values) {
          final moved = _advance(code, direction, puzzle.rows, puzzle.cols);
          if (moved < 0) continue;
          if (!seen.add(moved)) continue;
          parents[moved] = (code, direction);
          if ((moved >> cells) & CubeFace.solvedMask == CubeFace.solvedMask) {
            final line = <CubeDirection>[];
            var cursor = moved;
            while (cursor != startCode) {
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

  /// The first move of a shortest line, for the hint.
  ///
  /// A Cube board is not unique — many lines clear it — so the hint shows a
  /// move that leads to a win, without pretending it is the only one.
  CubeDirection? hint(CubePuzzle puzzle, CubePosition position) {
    final line = solve(puzzle, position);
    return line == null || line.isEmpty ? null : line.first;
  }
}
