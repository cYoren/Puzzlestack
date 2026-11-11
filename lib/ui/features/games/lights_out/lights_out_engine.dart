import 'dart:math';

/// Lights Out: every press flips its own cell and its four orthogonal
/// neighbours. The board is won when every light is off.
///
/// Uniqueness here is not a search result, it is linear algebra. A board is a
/// vector over GF(2) and a press is a column of the toggle matrix, so the
/// solution set is the affine space of solutions to `A x = b`. When `A` is
/// invertible there is exactly one solution, and the sizes below are the ones
/// where it is:
///
/// | size | rank | solutions per solvable board |
/// | --- | --- | --- |
/// | 3x3 | 9/9 | 1 |
/// | 4x4 | 12/16 | 16 |
/// | 5x5 | 23/25 | 4 |
/// | 6x6 | 36/36 | 1 |
/// | 7x7 | 49/49 | 1 |
/// | 8x8 | 64/64 | 1 |
///
/// That table is why the tiers are 3, 6 and 8 rather than 4, 5 and 6: the old
/// game used 5x5, where every board has four solutions and "solved" was
/// whichever one the player stumbled into.
class LightsOutPuzzle {
  const LightsOutPuzzle({
    required this.size,
    required this.start,
    required this.solution,
  });

  final int size;

  /// Row-major, `true` = lit.
  final List<bool> start;

  /// The press set that clears the board, as flat indices. Unique for every
  /// size this engine generates.
  final List<int> solution;
}

/// Size and how many presses the solution needs. Size is the board, presses
/// are the depth: a 6x6 that needs two presses is a warm-up, an 8x8 that needs
/// eighteen is not.
enum LightsOutDifficulty {
  easy(3, 2, 4),
  medium(6, 8, 12),
  hard(8, 14, 20);

  const LightsOutDifficulty(this.size, this.minPresses, this.maxPresses);

  final int size;
  final int minPresses;
  final int maxPresses;
}

class LightsOutEngine {
  const LightsOutEngine();

  static const List<(int, int)> _neighbours = [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)];

  /// Every cell a press at [index] flips, including itself.
  List<int> affected(int size, int index) {
    final row = index ~/ size;
    final col = index % size;
    final out = <int>[];
    for (final (dr, dc) in _neighbours) {
      final r = row + dr;
      final c = col + dc;
      if (r < 0 || r >= size || c < 0 || c >= size) continue;
      out.add(r * size + c);
    }
    return out;
  }

  List<bool> press(List<bool> grid, int size, int index) {
    final next = [...grid];
    for (final at in affected(size, index)) {
      next[at] = !next[at];
    }
    return next;
  }

  bool isSolved(List<bool> grid) => grid.every((lit) => !lit);

  int litCount(List<bool> grid) => grid.where((lit) => lit).length;

  // --------------------------------------------------------------- generator

  /// A board whose solution is exactly [LightsOutPuzzle.solution].
  ///
  /// Built forwards: choose the presses, apply them to a dark board. Because
  /// the toggle matrix is invertible at every size this engine generates, the
  /// presses that produced the board are the only presses that clear it.
  LightsOutPuzzle generate(LightsOutDifficulty difficulty, {Random? random}) {
    final rng = random ?? Random();
    final size = difficulty.size;
    final cells = size * size;

    while (true) {
      final want = difficulty.minPresses +
          rng.nextInt(difficulty.maxPresses - difficulty.minPresses + 1);
      final indices = List<int>.generate(cells, (i) => i)..shuffle(rng);
      final presses = indices.take(want).toList()..sort();

      var grid = List<bool>.filled(cells, false);
      for (final index in presses) {
        grid = press(grid, size, index);
      }
      if (isSolved(grid)) continue;

      return LightsOutPuzzle(size: size, start: grid, solution: presses);
    }
  }

  // ------------------------------------------------------------------ solver

  /// How many press sets clear [grid], counted rather than assumed.
  ///
  /// Gaussian elimination over GF(2): a consistent system with rank `r` over
  /// `n` variables has `2^(n-r)` solutions. Returns 0 when the board cannot be
  /// cleared at all.
  int countSolutions(List<bool> grid, int size) {
    final n = size * size;
    // One equation per cell, one variable per press, plus the right-hand side
    // in the top bit.
    final rows = <int>[];
    for (var cell = 0; cell < n; cell++) {
      var mask = 0;
      for (final at in affected(size, cell)) {
        mask |= 1 << at;
      }
      if (grid[cell]) mask |= 1 << n;
      rows.add(mask);
    }

    var rank = 0;
    for (var col = 0; col < n; col++) {
      var pivot = -1;
      for (var i = rank; i < rows.length; i++) {
        if ((rows[i] >> col) & 1 == 1) {
          pivot = i;
          break;
        }
      }
      if (pivot == -1) continue;
      final tmp = rows[rank];
      rows[rank] = rows[pivot];
      rows[pivot] = tmp;
      for (var i = 0; i < rows.length; i++) {
        if (i != rank && (rows[i] >> col) & 1 == 1) {
          rows[i] ^= rows[rank];
        }
      }
      rank++;
    }

    // Any row that is all-zero on the left but set on the right is 0 = 1.
    for (final row in rows) {
      if ((row & ((1 << n) - 1)) == 0 && ((row >> n) & 1) == 1) return 0;
    }
    return 1 << (n - rank);
  }
}
