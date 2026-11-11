import 'dart:math';

/// Same Game: click a group of two or more touching squares of one colour and
/// they vanish, the squares above fall, and empty columns slide left.
///
/// The generator is Tatham's, ported from `samegame.c` at `616da16`. It builds
/// the board *backwards*: start from two or three squares, then repeatedly
/// insert a domino of a colour that touches none of its neighbours. Every
/// insertion is checked to be a legal inverse move, so the finished board can
/// always be cleared — which is what makes "empty board" a fair win condition
/// rather than a lucky one.
class SameGamePuzzle {
  const SameGamePuzzle({
    required this.rows,
    required this.cols,
    required this.colours,
    required this.start,
  });

  final int rows;
  final int cols;

  /// How many colours the board uses. More colours means fewer groups, which
  /// is the real difficulty knob.
  final int colours;

  /// Row-major, `0` empty, `1..colours` a colour.
  final List<int> start;
}

/// Difficulty is size *and* colour count. Size alone is not difficulty here:
/// a big board with three colours is easy because huge groups keep forming.
enum SameGameDifficulty {
  easy(8, 8, 3),
  medium(10, 10, 4),
  hard(12, 12, 5);

  const SameGameDifficulty(this.rows, this.cols, this.colours);

  final int rows;
  final int cols;
  final int colours;
}

class SameGameEngine {
  const SameGameEngine();

  /// Tatham's scoring: a group of `n` is worth `(n - 2)^2`, so clearing two
  /// squares scores nothing and a big group is worth chasing.
  int points(int groupSize) {
    final diff = groupSize - 2;
    return diff > 0 ? diff * diff : 0;
  }

  // ------------------------------------------------------------------ groups

  /// The connected group of same-coloured squares containing [index], or an
  /// empty list when that square is empty.
  List<int> groupAt(List<int> grid, int rows, int cols, int index) {
    final colour = grid[index];
    if (colour == 0) return const [];
    final seen = <int>{index};
    final group = <int>[index];
    for (var i = 0; i < group.length; i++) {
      final at = group[i];
      final row = at ~/ cols;
      final col = at % cols;
      for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final r = row + dr;
        final c = col + dc;
        if (r < 0 || r >= rows || c < 0 || c >= cols) continue;
        final next = r * cols + c;
        if (grid[next] != colour || !seen.add(next)) continue;
        group.add(next);
      }
    }
    return group;
  }

  /// Every group big enough to remove, largest first. Used by the hint and by
  /// the "no moves left" check.
  List<List<int>> removableGroups(List<int> grid, int rows, int cols) {
    final seen = <int>{};
    final groups = <List<int>>[];
    for (var i = 0; i < grid.length; i++) {
      if (grid[i] == 0 || seen.contains(i)) continue;
      final group = groupAt(grid, rows, cols, i);
      seen.addAll(group);
      if (group.length >= 2) groups.add(group);
    }
    groups.sort((a, b) => b.length.compareTo(a.length));
    return groups;
  }

  bool hasMoves(List<int> grid, int rows, int cols) =>
      removableGroups(grid, rows, cols).isNotEmpty;

  bool isSolved(List<int> grid) => grid.every((c) => c == 0);

  /// Remove [group], drop the squares above, and slide empty columns left.
  List<int> apply(List<int> grid, int rows, int cols, List<int> group) {
    final next = [...grid];
    for (final index in group) {
      next[index] = 0;
    }

    // Gravity: every column packs upwards.
    for (var col = 0; col < cols; col++) {
      var write = rows - 1;
      for (var row = rows - 1; row >= 0; row--) {
        final value = next[row * cols + col];
        if (value == 0) continue;
        next[write * cols + col] = value;
        if (write != row) next[row * cols + col] = 0;
        write--;
      }
      for (var row = write; row >= 0; row--) {
        next[row * cols + col] = 0;
      }
    }

    // Empty columns collapse to the left.
    final kept = <int>[];
    for (var col = 0; col < cols; col++) {
      var empty = true;
      for (var row = 0; row < rows; row++) {
        if (next[row * cols + col] != 0) {
          empty = false;
          break;
        }
      }
      if (!empty) kept.add(col);
    }
    if (kept.length != cols) {
      final packed = List<int>.filled(rows * cols, 0);
      for (var target = 0; target < kept.length; target++) {
        for (var row = 0; row < rows; row++) {
          packed[row * cols + target] = next[row * cols + kept[target]];
        }
      }
      return packed;
    }
    return next;
  }

  // --------------------------------------------------------------- generator

  /// A board that can be cleared completely.
  ///
  /// Faithful port of `gen_grid` from `samegame.c`. The `assert`s the C uses to
  /// prove each insertion is a legal inverse move are real checks here: a board
  /// that fails one is discarded rather than shipped.
  List<int> generate({
    required int rows,
    required int cols,
    required int colours,
    Random? random,
  }) {
    assert(rows >= 1 && cols >= 1);
    assert(colours >= 2 && colours <= 9);
    final rng = random ?? Random();
    final wh = rows * cols;
    final marker = colours + 1;
    var grid = List<int>.filled(wh, 0);
    final candidate = List<int>.filled(wh, 0);
    final points = List<int>.filled(wh + cols, 0);

    // The C loops until it happens to finish. A bound turns a porting mistake
    // into a failure instead of a hung test run.
    for (var attempt = 0; attempt < 10000; attempt++) {
      grid = List<int>.filled(wh, 0);

      // Start with two or three squares of one colour, on the bottom edge or
      // down the left edge, depending on which one is long enough.
      final startCount = 2 + (wh % 2);
      final startColour = 1 + rng.nextInt(colours);
      if (startCount <= cols) {
        for (var i = 0; i < startCount; i++) {
          grid[(rows - 1) * cols + i] = startColour;
        }
      } else {
        for (var i = 0; i < startCount; i++) {
          grid[(rows - 1 - i) * cols] = startColour;
        }
      }

      while (true) {
        // Every place a domino could go: inside a column, or a brand-new
        // column between two existing ones.
        var n = 0;
        if (grid[wh - 1] == 0) {
          for (var i = 0; i < cols; i++) {
            points[n++] = wh + i;
            if (grid[(rows - 1) * cols + i] == 0) break;
          }
        }
        for (var i = 0; i < cols; i++) {
          if (grid[(rows - 1) * cols + i] == 0) break;
          if (grid[i] != 0) continue;
          for (var j = rows - 1; j >= 0; j--) {
            points[n++] = j * cols + i;
            if (grid[j * cols + i] == 0) break;
          }
        }
        if (n == 0) break;

        var placed = false;
        while (n > 0) {
          n--;
          final pick = rng.nextInt(n + 1);
          final pos = points[pick];
          points[pick] = points[n];

          var x = pos % cols;
          var y = pos ~/ cols;
          candidate.setAll(0, grid);

          if (y == rows) {
            // A new column at x: shift everything right of it one across.
            for (var i = cols - 1; i > x; i--) {
              for (var j = 0; j < rows; j++) {
                candidate[j * cols + i] = candidate[j * cols + (i - 1)];
              }
            }
            for (var j = 0; j < rows; j++) {
              candidate[j * cols + x] = 0;
            }
            y--;
          }

          // Make room inside column x by shifting everything above y up one.
          for (var i = 0; i + 1 <= y; i++) {
            candidate[i * cols + x] = candidate[(i + 1) * cols + x];
          }

          // Pick a colour that none of the four neighbours already has.
          final wrong = <int>{};
          if (x > 0) wrong.add(candidate[y * cols + (x - 1)]);
          if (x + 1 < cols) wrong.add(candidate[y * cols + (x + 1)]);
          if (y > 0) wrong.add(candidate[(y - 1) * cols + x]);
          if (y + 1 < rows) wrong.add(candidate[(y + 1) * cols + x]);
          // The C's dedupe only keeps values greater than zero (its `min`
          // starts at 0), so an empty neighbour is not a taken colour.
          wrong.remove(0);
          if (wrong.length == colours) continue;

          // Ascending order matters: the skip loop below walks the taken
          // colours in order and shifts the pick past each one.
          final taken = wrong.toList()..sort();
          var colour = 1 + rng.nextInt(colours - taken.length);
          for (final value in taken) {
            if (colour >= value) {
              colour++;
            } else {
              break;
            }
          }

          candidate[y * cols + x] = marker;

          // Grow the domino left, right or up. Up is listed twice so a vertical
          // domino is as likely as a horizontal one (the C's note: less bias).
          final dirs = <int>[];
          if (x > 0 &&
              candidate[y * cols + (x - 1)] != colour &&
              candidate[x - 1] == 0 &&
              (y + 1 >= rows || candidate[(y + 1) * cols + (x - 1)] != colour) &&
              (y + 1 >= rows || candidate[(y + 1) * cols + (x - 1)] != 0) &&
              (x <= 1 || candidate[y * cols + (x - 2)] != colour)) {
            dirs.add(-1);
          }
          if (x + 1 < cols &&
              candidate[y * cols + (x + 1)] != colour &&
              candidate[x + 1] == 0 &&
              (y + 1 >= rows || candidate[(y + 1) * cols + (x + 1)] != colour) &&
              (y + 1 >= rows || candidate[(y + 1) * cols + (x + 1)] != 0) &&
              (x + 2 >= cols || candidate[y * cols + (x + 2)] != colour)) {
            dirs.add(1);
          }
          if (y > 0 &&
              candidate[x] == 0 &&
              (x <= 0 || candidate[(y - 1) * cols + (x - 1)] != colour) &&
              (x + 1 >= cols || candidate[(y - 1) * cols + (x + 1)] != colour)) {
            dirs.add(0);
            dirs.add(0);
          }
          if (dirs.isEmpty) continue;

          final dir = dirs[rng.nextInt(dirs.length)];
          for (var i = 0; i + 1 <= y; i++) {
            candidate[i * cols + x + dir] = candidate[(i + 1) * cols + x + dir];
          }
          candidate[y * cols + x + dir] = marker;

          // Splitting the free squares into odd-sized pieces would make the
          // rest impossible to fill. A spare column can absorb one odd piece
          // when the height is odd; otherwise any odd piece is fatal.
          var odd = 0;
          var fixable = 0;
          var run = 0;
          for (var i = 0; i < cols; i++) {
            if (candidate[(rows - 1) * cols + i] == 0) {
              if (rows.isOdd) fixable++;
              continue;
            }
            var j = 0;
            while (j < rows && candidate[j * cols + i] == 0) {
              j++;
            }
            if (j == 0) {
              if (run.isOdd) odd++;
              run = 0;
            } else {
              run += j;
            }
          }
          if (run.isOdd) odd++;
          if (odd > fixable) continue;

          // Prove the insertion is a legal inverse move: removing the marker
          // squares must give back exactly the previous grid, no marker square
          // may touch the new colour, and the markers must be one piece.
          final check = _verify(candidate, grid, rows, cols, marker, colour);
          if (check == null) continue;

          // The markers were only there to prove the shape; the squares are
          // colour `c` in the finished board. The C does this inside its BFS.
          for (var i = 0; i < candidate.length; i++) {
            if (candidate[i] == marker) candidate[i] = colour;
          }

          grid = [...candidate];
          placed = true;
          break;
        }

        if (!placed) break;
      }

      if (grid.every((c) => c != 0)) return grid;
    }
    throw StateError('could not generate a $rows x $cols board in $colours colours');
  }

  /// Returns the number of marker squares when the insertion is valid, or null
  /// when it is not. Mirrors the three checks in `samegame.c`; the C `assert`s
  /// them because it believes they cannot fail, and a port that quietly skips
  /// them would ship boards that cannot be cleared.
  int? _verify(
    List<int> candidate,
    List<int> previous,
    int rows,
    int cols,
    int marker,
    int colour,
  ) {
    var x1 = 0;
    var markers = 0;
    var fillStart = -1;

    for (var x2 = 0; x2 < cols; x2++) {
      var y1 = rows - 1;
      var usedColumn = false;
      for (var y2 = rows - 1; y2 >= 0; y2--) {
        final value = candidate[y2 * cols + x2];
        if (value == marker) {
          markers++;
          if (fillStart == -1) fillStart = y2 * cols + x2;
          final touches =
              (y2 + 1 < rows && candidate[(y2 + 1) * cols + x2] == colour) ||
                  (y2 - 1 >= 0 && candidate[(y2 - 1) * cols + x2] == colour) ||
                  (x2 + 1 < cols && candidate[y2 * cols + x2 + 1] == colour) ||
                  (x2 - 1 >= 0 && candidate[y2 * cols + x2 - 1] == colour);
          if (touches) return null;
          continue;
        }
        if (value == 0) break;
        usedColumn = true;
        if (value != previous[y1 * cols + x1]) return null;
        y1--;
      }
      if (usedColumn) {
        while (y1 >= 0) {
          if (previous[y1 * cols + x1] != 0) return null;
          y1--;
        }
        x1++;
      }
    }

    if (fillStart == -1) return null;

    // The markers must be one connected piece, or the "group" could not have
    // been removed in one click.
    final seen = <int>{fillStart};
    final queue = <int>[fillStart];
    for (var i = 0; i < queue.length; i++) {
      final at = queue[i];
      final row = at ~/ cols;
      final col = at % cols;
      for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final r = row + dr;
        final c = col + dc;
        if (r < 0 || r >= rows || c < 0 || c >= cols) continue;
        final next = r * cols + c;
        if (candidate[next] != marker || !seen.add(next)) continue;
        queue.add(next);
      }
    }
    if (queue.length != markers) return null;
    return markers;
  }
}
