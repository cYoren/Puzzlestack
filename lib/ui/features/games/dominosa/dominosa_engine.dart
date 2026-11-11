import 'dart:math';

/// Dominosa: a grid of digits that has to be covered with dominoes so that
/// every pair `0-0 .. n-n` appears exactly once.
///
/// The old generator laid a **fixed** tiling over the grid and filled it with
/// shuffled dominoes. Every board had the same arrangement, and nothing checked
/// that the numbers pinned that arrangement down — so a board could have two
/// valid tilings and accept the wrong one.
///
/// This one tiles at random and then **counts** the tilings. A board ships only
/// when exactly one covering exists.
class DominosaPuzzle {
  const DominosaPuzzle({
    required this.maxValue,
    required this.rows,
    required this.cols,
    required this.grid,
    required this.partner,
  });

  final int maxValue;
  final int rows;
  final int cols;

  /// Row-major digits, 0..maxValue.
  final List<int> grid;

  /// Row-major: the cell each cell is paired with in the answer.
  final List<int> partner;

  int get cellCount => rows * cols;

  int get dominoCount => cellCount ~/ 2;
}

enum DominosaDifficulty {
  easy(3),
  medium(4),
  hard(5);

  const DominosaDifficulty(this.maxValue);

  final int maxValue;
}

class DominosaEngine {
  const DominosaEngine();

  int rowsFor(int maxValue) => maxValue + 1;

  int colsFor(int maxValue) => maxValue + 2;

  /// Every domino type as `a * 16 + b` with `a <= b`.
  List<int> typesFor(int maxValue) => [
        for (var a = 0; a <= maxValue; a++)
          for (var b = a; b <= maxValue; b++) a * 16 + b,
      ];

  // --------------------------------------------------------------- generator

  DominosaPuzzle generate(DominosaDifficulty difficulty, {Random? random}) {
    final rng = random ?? Random();
    final maxValue = difficulty.maxValue;
    final rows = rowsFor(maxValue);
    final cols = colsFor(maxValue);
    final types = typesFor(maxValue);

    for (var attempt = 0; attempt < 4000; attempt++) {
      // Geometry first, values second. Tiling *and* choosing a domino type for
      // every placement in one search biases the result towards a handful of
      // shapes, and those shapes are the ambiguous ones.
      final partner = _randomMatching(rows, cols, rng);
      if (partner == null) continue;

      final grid = List<int>.filled(rows * cols, -1);
      final shuffled = [...types]..shuffle(rng);
      var next = 0;
      for (var cell = 0; cell < partner.length; cell++) {
        final other = partner[cell];
        if (other < cell) continue;
        final type = shuffled[next++];
        final a = type ~/ 16;
        final b = type % 16;
        if (rng.nextBool()) {
          grid[cell] = a;
          grid[other] = b;
        } else {
          grid[cell] = b;
          grid[other] = a;
        }
      }

      final puzzle = DominosaPuzzle(
        maxValue: maxValue,
        rows: rows,
        cols: cols,
        grid: grid,
        partner: partner,
      );
      if (countTilings(puzzle, limit: 2) == 1) return puzzle;
    }
    throw StateError('could not tile a $rows x $cols Dominosa board uniquely');
  }

  /// A random perfect matching of the grid, or null when the greedy walk
  /// painted itself into a corner.
  List<int>? _randomMatching(int rows, int cols, Random rng) {
    final partner = List<int>.filled(rows * cols, -1);

    bool fill() {
      var start = -1;
      for (var i = 0; i < partner.length; i++) {
        if (partner[i] == -1) {
          start = i;
          break;
        }
      }
      if (start == -1) return true;

      final row = start ~/ cols;
      final col = start % cols;
      final options = <int>[
        if (col + 1 < cols && partner[start + 1] == -1) start + 1,
        if (row + 1 < rows && partner[start + cols] == -1) start + cols,
      ]..shuffle(rng);

      for (final other in options) {
        partner[start] = other;
        partner[other] = start;
        if (fill()) return true;
        partner[start] = -1;
        partner[other] = -1;
      }
      return false;
    }

    return fill() ? partner : null;
  }

  // ------------------------------------------------------------------ solver

  /// How many coverings the numbers allow, capped at [limit].
  ///
  /// A covering may not use the same domino type twice, which is the rule the
  /// player is held to.
  int countTilings(DominosaPuzzle puzzle, {int limit = 2}) {
    final grid = puzzle.grid;
    final rows = puzzle.rows;
    final cols = puzzle.cols;
    final used = <int>{};
    final covered = <int>{};
    var found = 0;

    void walk() {
      if (found >= limit) return;
      var start = -1;
      for (var i = 0; i < grid.length; i++) {
        if (!covered.contains(i)) {
          start = i;
          break;
        }
      }
      if (start == -1) {
        found++;
        return;
      }
      final row = start ~/ cols;
      final col = start % cols;
      final neighbours = <int>[
        if (col + 1 < cols && !covered.contains(start + 1)) start + 1,
        if (row + 1 < rows && !covered.contains(start + cols)) start + cols,
      ];
      for (final other in neighbours) {
        final type = typeOf(grid[start], grid[other]);
        if (used.contains(type)) continue;
        used.add(type);
        covered.add(start);
        covered.add(other);
        walk();
        covered.remove(start);
        covered.remove(other);
        used.remove(type);
        if (found >= limit) return;
      }
    }

    walk();
    return found;
  }

  // ------------------------------------------------------------------- rules

  bool isAdjacent(int a, int b, int cols) {
    final ra = a ~/ cols;
    final ca = a % cols;
    final rb = b ~/ cols;
    final cb = b % cols;
    return (ra == rb && (ca - cb).abs() == 1) || (ca == cb && (ra - rb).abs() == 1);
  }

  int typeOf(int a, int b) => a <= b ? a * 16 + b : b * 16 + a;

  String typeName(int type) => '${type ~/ 16}-${type % 16}';
}
