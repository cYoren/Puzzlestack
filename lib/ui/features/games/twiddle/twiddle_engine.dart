import 'dart:math';

/// One quarter turn of a square block, named by the block's top-left corner.
class TwiddleMove {
  const TwiddleMove(this.row, this.col, this.clockwise);

  final int row;
  final int col;
  final bool clockwise;

  TwiddleMove get inverse => TwiddleMove(row, col, !clockwise);

  @override
  bool operator ==(Object other) =>
      other is TwiddleMove &&
      other.row == row &&
      other.col == col &&
      other.clockwise == clockwise;

  @override
  int get hashCode => Object.hash(row, col, clockwise);

  @override
  String toString() => 'TwiddleMove($row,$col,${clockwise ? 'cw' : 'ccw'})';
}

/// A scrambled board plus the turns that unscramble it.
///
/// The board is made by turning a solved grid, so the solution is the scramble
/// played backwards. Nothing has to be searched to know it can be finished.
class TwiddlePuzzle {
  const TwiddlePuzzle({
    required this.size,
    required this.block,
    required this.start,
    required this.solution,
  });

  /// The grid is [size] x [size].
  final int size;

  /// Turns rotate a [block] x [block] square.
  final int block;

  final List<int> start;
  final List<TwiddleMove> solution;

  int get tiles => size * size;
}

/// Difficulty is how much work the board holds: more tiles, bigger blocks and
/// a longer scramble all make the same puzzle deeper.
enum TwiddleDifficulty {
  easy(3, 2, 14),
  medium(4, 2, 34),
  hard(5, 3, 70);

  const TwiddleDifficulty(this.size, this.block, this.scrambles);

  final int size;
  final int block;
  final int scrambles;
}

class TwiddleEngine {
  const TwiddleEngine();

  List<int> solvedGrid(int size) =>
      [for (var i = 0; i < size * size; i++) i + 1];

  bool isSolved(List<int> grid) {
    for (var i = 0; i < grid.length; i++) {
      if (grid[i] != i + 1) return false;
    }
    return true;
  }

  int correctCount(List<int> grid) {
    var correct = 0;
    for (var i = 0; i < grid.length; i++) {
      if (grid[i] == i + 1) correct++;
    }
    return correct;
  }

  /// Where the tile at ([row], [col]) ends up after [move].
  (int, int) destinationOf(int row, int col, TwiddleMove move, int block) {
    final localRow = row - move.row;
    final localCol = col - move.col;
    if (localRow < 0 ||
        localCol < 0 ||
        localRow >= block ||
        localCol >= block) {
      return (row, col);
    }
    if (move.clockwise) {
      return (move.row + localCol, move.col + block - 1 - localRow);
    }
    return (move.row + block - 1 - localCol, move.col + localRow);
  }

  List<int> apply(List<int> grid, int size, TwiddleMove move, int block) {
    final next = [...grid];
    for (var row = move.row; row < move.row + block; row++) {
      for (var col = move.col; col < move.col + block; col++) {
        final (toRow, toCol) = destinationOf(row, col, move, block);
        next[toRow * size + toCol] = grid[row * size + col];
      }
    }
    return next;
  }

  /// Every block that contains ([row], [col]), as top-left corners.
  List<(int, int)> blocksContaining(int size, int block, int row, int col) {
    final out = <(int, int)>[];
    final firstRow = max(0, row - block + 1);
    final lastRow = min(row, size - block);
    final firstCol = max(0, col - block + 1);
    final lastCol = min(col, size - block);
    for (var r = firstRow; r <= lastRow; r++) {
      for (var c = firstCol; c <= lastCol; c++) {
        out.add((r, c));
      }
    }
    return out;
  }

  /// The turns a drag of the tile at ([row], [col]) can mean.
  ///
  /// Each turn is offered as a move whose destination is where that tile would
  /// land, so dragging a tile onto its neighbour is a quarter turn — the
  /// gesture the player expects.
  List<TwiddleMove> turnsForTile(
    int size,
    int block,
    int row,
    int col,
  ) {
    final out = <TwiddleMove>[];
    for (final (r, c) in blocksContaining(size, block, row, col)) {
      for (final clockwise in [true, false]) {
        final move = TwiddleMove(r, c, clockwise);
        final (toRow, toCol) = destinationOf(row, col, move, block);
        if (toRow == row && toCol == col) continue;
        out.add(move);
      }
    }
    return out;
  }

  /// The turn a tap on ([row], [col]) performs: clockwise, around the block
  /// whose centre is nearest the tile. Deterministic, so tapping the same tile
  /// twice turns the same block twice.
  TwiddleMove? tapTurn(int size, int block, int row, int col) {
    final options = blocksContaining(size, block, row, col);
    if (options.isEmpty) return null;
    final (bestRow, bestCol) = options.reduce((a, b) {
      final da = _centreDistance(a, block, row, col);
      final db = _centreDistance(b, block, row, col);
      if (da != db) return da < db ? a : b;
      // Top-left first, so the choice never depends on list order.
      if (a.$1 != b.$1) return a.$1 < b.$1 ? a : b;
      return a.$2 <= b.$2 ? a : b;
    });
    final move = TwiddleMove(bestRow, bestCol, true);
    final (toRow, toCol) = destinationOf(row, col, move, block);
    if (toRow == row && toCol == col) return null;
    return move;
  }

  double _centreDistance((int, int) corner, int block, int row, int col) {
    final centreRow = corner.$1 + (block - 1) / 2;
    final centreCol = corner.$2 + (block - 1) / 2;
    return (centreRow - row).abs() + (centreCol - col).abs();
  }

  // -------------------------------------------------------------- generator

  TwiddlePuzzle generate({
    TwiddleDifficulty difficulty = TwiddleDifficulty.medium,
    Random? random,
  }) {
    final rng = random ?? Random();
    final size = difficulty.size;
    final block = difficulty.block;

    for (var attempt = 0; attempt < 40; attempt++) {
      final grid = solvedGrid(size);
      final scramble = <TwiddleMove>[];
      TwiddleMove? last;

      for (var i = 0; i < difficulty.scrambles; i++) {
        final options = <TwiddleMove>[
          for (var r = 0; r <= size - block; r++)
            for (var c = 0; c <= size - block; c++)
              for (final clockwise in [true, false])
                TwiddleMove(r, c, clockwise),
        ]..removeWhere((move) => last != null && move == last.inverse);

        final move = options[rng.nextInt(options.length)];
        final next = apply(grid, size, move, block);
        grid
          ..clear()
          ..addAll(next);
        scramble.add(move);
        last = move;
      }

      // A scramble that happens to land back on the solved grid is not a
      // puzzle; try again rather than hand the player a finished board.
      if (isSolved(grid)) continue;

      return TwiddlePuzzle(
        size: size,
        block: block,
        start: grid,
        solution: scramble.reversed.map((m) => m.inverse).toList(),
      );
    }

    // Unreachable in practice: a 40-move random walk on these sizes always
    // leaves the solved state. Keep a defined answer anyway.
    final grid = solvedGrid(size);
    final move = TwiddleMove(0, 0, true);
    return TwiddlePuzzle(
      size: size,
      block: block,
      start: apply(grid, size, move, block),
      solution: [move.inverse],
    );
  }

  // ------------------------------------------------------------------- hint

  /// The turn that looks best two moves ahead.
  ///
  /// It prefers a turn that puts tiles in place right away, and among those
  /// the one whose follow-up puts the most in place. When no single turn helps
  /// it still returns the least bad one: a hint that says "nothing helps" is
  /// useless, and every turn is reversible.
  TwiddleMove? hint(List<int> grid, int size, int block) {
    if (isSolved(grid)) return null;

    TwiddleMove? pick;
    var pickScore = -1;
    var pickImmediate = -1;

    for (var r = 0; r <= size - block; r++) {
      for (var c = 0; c <= size - block; c++) {
        for (final clockwise in [true, false]) {
          final move = TwiddleMove(r, c, clockwise);
          final after = apply(grid, size, move, block);
          final immediate = correctCount(after);

          // One more turn, to prefer the line that keeps improving.
          var lookahead = immediate;
          for (var r2 = 0; r2 <= size - block; r2++) {
            for (var c2 = 0; c2 <= size - block; c2++) {
              for (final cw2 in [true, false]) {
                final score = correctCount(
                  apply(after, size, TwiddleMove(r2, c2, cw2), block),
                );
                if (score > lookahead) lookahead = score;
              }
            }
          }

          if (lookahead > pickScore ||
              (lookahead == pickScore && immediate > pickImmediate)) {
            pickScore = lookahead;
            pickImmediate = immediate;
            pick = move;
          }
        }
      }
    }

    return pick;
  }
}
