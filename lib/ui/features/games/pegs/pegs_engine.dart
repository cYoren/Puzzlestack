import 'dart:math';

/// What sits on one square of a peg solitaire board.
enum PegCell {
  /// Off the board. Never playable, never drawn.
  obstacle,

  /// A peg that has not been captured yet.
  peg,

  /// An empty square a peg can jump into.
  hole,
}

/// One jump: the peg at [from] hops over [mid] and lands on [to].
class PegsJump {
  const PegsJump(this.from, this.mid, this.to);

  final int from;
  final int mid;
  final int to;

  @override
  bool operator ==(Object other) =>
      other is PegsJump &&
      other.from == from &&
      other.mid == mid &&
      other.to == to;

  @override
  int get hashCode => Object.hash(from, mid, to);

  @override
  String toString() => 'PegsJump($from>$mid>$to)';
}

/// A generated board plus the sequence that solves it.
///
/// [solution] is the generator's own reverse play, flipped. It is a proof of
/// solvability rather than a search result: the board was built by running the
/// moves backwards from a single peg, so replaying them forwards must return
/// to a single peg.
class PegsPuzzle {
  const PegsPuzzle({
    required this.rows,
    required this.cols,
    required this.start,
    required this.solution,
  });

  final int rows;
  final int cols;
  final List<PegCell> start;
  final List<PegsJump> solution;

  int get pegs => start.where((c) => c == PegCell.peg).length;

  int get playable => start.where((c) => c != PegCell.obstacle).length;
}

/// Difficulty is board size, because that is what actually changes the work:
/// a wider board holds more pegs, and every extra peg is one more jump the
/// player has to find.
enum PegsDifficulty {
  easy(7, 7),
  medium(9, 9),
  hard(11, 11);

  const PegsDifficulty(this.rows, this.cols);

  final int rows;
  final int cols;
}

class PegsEngine {
  const PegsEngine();

  static const List<List<int>> _directions = [
    [-1, 0],
    [1, 0],
    [0, -1],
    [0, 1],
  ];

  int index(int rows, int cols, int row, int col) => row * cols + col;

  /// Builds a board by reverse play from a single peg in the middle.
  ///
  /// Every reverse jump adds two pegs, so the finished board is solvable by
  /// construction and [PegsPuzzle.solution] is the exact line back.
  PegsPuzzle generate({
    PegsDifficulty difficulty = PegsDifficulty.medium,
    Random? random,
  }) {
    final rng = random ?? Random();
    final rows = difficulty.rows;
    final cols = difficulty.cols;

    // A board that does not reach all four edges looks like a blob, so try
    // again until the reverse play spreads out.
    for (var attempt = 0; attempt < 60; attempt++) {
      final puzzle = _attempt(rows, cols, rng);
      if (puzzle != null) return puzzle;
    }
    // Reverse play from the centre always reaches the edges on these sizes;
    // the fallback only exists so a bad draw cannot hang the app.
    return _attempt(rows, cols, rng, requireExtent: false)!;
  }

  PegsPuzzle? _attempt(int rows, int cols, Random rng, {bool requireExtent = true}) {
    final grid = List<PegCell>.filled(rows * cols, PegCell.obstacle);
    final centre = index(rows, cols, rows ~/ 2, cols ~/ 2);
    grid[centre] = PegCell.peg;

    final reverse = <PegsJump>[];
    var jumps = 0;

    while (true) {
      final candidates = _reverseMoves(grid, rows, cols);
      if (candidates.isEmpty) break;

      // Prefer jumps that stay on the board: a zero-cost jump keeps the shape
      // solid instead of spraying pegs into empty space.
      final maxCost = jumps < rows * cols ~/ 2 ? 2 : 1;
      List<_Candidate> best = const [];
      for (var cost = 0; cost <= maxCost; cost++) {
        best = candidates.where((c) => c.cost == cost).toList();
        if (best.isNotEmpty) break;
      }
      if (best.isEmpty) break;

      final pick = best[rng.nextInt(best.length)];
      // Undo a forward jump: the peg on the landing square comes back over the
      // jumped square and lands two squares further out, leaving a hole where
      // it started.
      grid[pick.jump.from] = PegCell.hole;
      grid[pick.jump.mid] = PegCell.peg;
      grid[pick.jump.to] = PegCell.peg;
      // Recorded the way it will be played: far square over the middle into
      // the square that is now a hole.
      reverse.add(PegsJump(pick.jump.to, pick.jump.mid, pick.jump.from));
      jumps++;
    }

    if (requireExtent && !_reachesEveryEdge(grid, rows, cols)) return null;

    // The board is the end state of the reverse play; the start is what the
    // player sees, and the solution is the reverse list flipped.
    return PegsPuzzle(
      rows: rows,
      cols: cols,
      start: grid,
      solution: reverse.reversed.toList(),
    );
  }

  /// Jumps that are legal to run *backwards* from the current grid.
  List<_Candidate> _reverseMoves(List<PegCell> grid, int rows, int cols) {
    final out = <_Candidate>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final from = index(rows, cols, row, col);
        if (grid[from] != PegCell.peg) continue;
        for (final dir in _directions) {
          final midRow = row - dir[0];
          final midCol = col - dir[1];
          final farRow = row - 2 * dir[0];
          final farCol = col - 2 * dir[1];
          if (midRow < 0 || midRow >= rows || midCol < 0 || midCol >= cols) {
            continue;
          }
          if (farRow < 0 || farRow >= rows || farCol < 0 || farCol >= cols) {
            continue;
          }
          final mid = index(rows, cols, midRow, midCol);
          final far = index(rows, cols, farRow, farCol);
          if (grid[mid] == PegCell.peg || grid[far] == PegCell.peg) continue;
          final cost = (grid[mid] == PegCell.obstacle ? 1 : 0) +
              (grid[far] == PegCell.obstacle ? 1 : 0);
          out.add(_Candidate(PegsJump(from, mid, far), cost));
        }
      }
    }
    return out;
  }

  bool _reachesEveryEdge(List<PegCell> grid, int rows, int cols) {
    var edges = 0;
    for (var row = 0; row < rows; row++) {
      if (grid[index(rows, cols, row, 0)] != PegCell.obstacle) edges |= 1;
      if (grid[index(rows, cols, row, cols - 1)] != PegCell.obstacle) edges |= 2;
    }
    for (var col = 0; col < cols; col++) {
      if (grid[index(rows, cols, 0, col)] != PegCell.obstacle) edges |= 4;
      if (grid[index(rows, cols, rows - 1, col)] != PegCell.obstacle) edges |= 8;
    }
    return edges == 15;
  }

  // ------------------------------------------------------------------ rules

  /// Every jump available from the current grid.
  List<PegsJump> legalJumps(List<PegCell> grid, int rows, int cols) {
    final out = <PegsJump>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final from = index(rows, cols, row, col);
        if (grid[from] != PegCell.peg) continue;
        for (final dir in _directions) {
          final midRow = row + dir[0];
          final midCol = col + dir[1];
          final toRow = row + 2 * dir[0];
          final toCol = col + 2 * dir[1];
          if (toRow < 0 || toRow >= rows || toCol < 0 || toCol >= cols) continue;
          final mid = index(rows, cols, midRow, midCol);
          final to = index(rows, cols, toRow, toCol);
          if (grid[mid] != PegCell.peg) continue;
          if (grid[to] != PegCell.hole) continue;
          out.add(PegsJump(from, mid, to));
        }
      }
    }
    return out;
  }

  List<PegCell> apply(List<PegCell> grid, PegsJump jump) {
    final next = [...grid];
    next[jump.from] = PegCell.hole;
    next[jump.mid] = PegCell.hole;
    next[jump.to] = PegCell.peg;
    return next;
  }

  int countPegs(List<PegCell> grid) =>
      grid.where((c) => c == PegCell.peg).length;

  bool isSolved(List<PegCell> grid) => countPegs(grid) == 1;

  // ----------------------------------------------------------------- solver

  /// A line of jumps that takes [grid] down to one peg, or null if there is
  /// none within [maxNodes].
  ///
  /// Used for hints. The generator already knows one solution for the board it
  /// produced; this is for the position the player is actually in, which may
  /// have left the generated line behind.
  List<PegsJump>? solve(
    List<PegCell> grid,
    int rows,
    int cols, {
    int maxNodes = 400000,
  }) {
    // States proven to lead nowhere. Only a state whose every child failed is
    // added, so a search that runs out of budget never poisons the memo.
    final dead = <String>{};
    var nodes = 0;
    var exhausted = false;
    final path = <PegsJump>[];

    bool search(List<PegCell> current) {
      if (exhausted) return false;
      if (countPegs(current) == 1) return true;
      if (nodes++ > maxNodes) {
        exhausted = true;
        return false;
      }

      // A peg that can never be jumped over can never be removed, so it has
      // to be the survivor. Two of them cannot both survive, which is the
      // prune that makes the search finish.
      if (_strandedPegs(current, rows, cols) > 1) return false;

      final key = _key(current);
      if (dead.contains(key)) return false;

      final jumps = legalJumps(current, rows, cols);
      if (jumps.isEmpty) return false;

      // Try first the jumps that leave the most follow-up moves and strand
      // nothing; that ordering is the difference between a fast search and a
      // hopeless one.
      final scored = jumps
          .map((j) {
            final after = apply(current, j);
            return (
              j,
              legalJumps(after, rows, cols).length,
              _strandedPegs(after, rows, cols),
              _isolatedPegs(after, rows, cols),
            );
          })
          .toList()
        ..sort((a, b) {
          if (a.$3 != b.$3) return a.$3.compareTo(b.$3);
          if (a.$4 != b.$4) return a.$4.compareTo(b.$4);
          return b.$2.compareTo(a.$2);
        });

      for (final (jump, _, _, _) in scored) {
        path.add(jump);
        if (search(apply(current, jump))) return true;
        path.removeLast();
        if (exhausted) return false;
      }
      dead.add(key);
      return false;
    }

    return search([...grid]) ? path : null;
  }

  /// How many pegs are walled in: they can never be jumped over and can never
  /// jump, judged by the shape of the board alone.
  ///
  /// Such a peg is there for the rest of the game, which is fine if it is the
  /// one that survives and fatal if there are two of them. The test is
  /// deliberately geometric — a peg that merely has no partner right now can
  /// still get one — so the prune never throws away a live line.
  int _strandedPegs(List<PegCell> grid, int rows, int cols) {
    var stranded = 0;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if (grid[index(rows, cols, row, col)] != PegCell.peg) continue;
        if (_canBeJumpedOver(row, col, rows, cols)) continue;
        if (_canJump(row, col, rows, cols)) continue;
        stranded++;
      }
    }
    return stranded;
  }

  /// Pegs with no peg beside them. They are not dead yet, but a board that
  /// keeps its pegs touching is the one that finishes.
  int _isolatedPegs(List<PegCell> grid, int rows, int cols) {
    var isolated = 0;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if (grid[index(rows, cols, row, col)] != PegCell.peg) continue;
        var touching = false;
        for (final dir in _directions) {
          final r = row + dir[0];
          final c = col + dir[1];
          if (!_inside(r, c, rows, cols)) continue;
          if (grid[index(rows, cols, r, c)] == PegCell.peg) {
            touching = true;
            break;
          }
        }
        if (!touching) isolated++;
      }
    }
    return isolated;
  }

  bool _inside(int row, int col, int rows, int cols) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  bool _canBeJumpedOver(int row, int col, int rows, int cols) {
    for (final dir in _directions) {
      if (_inside(row - dir[0], col - dir[1], rows, cols) &&
          _inside(row + dir[0], col + dir[1], rows, cols)) {
        return true;
      }
    }
    return false;
  }

  bool _canJump(int row, int col, int rows, int cols) {
    for (final dir in _directions) {
      if (_inside(row + dir[0], col + dir[1], rows, cols) &&
          _inside(row + 2 * dir[0], col + 2 * dir[1], rows, cols)) {
        return true;
      }
    }
    return false;
  }

  /// An exact key for a position, so the dead-state memo can never confuse two
  /// different boards.
  String _key(List<PegCell> grid) =>
      String.fromCharCodes(grid.map((c) => c.index + 48));
}

class _Candidate {
  const _Candidate(this.jump, this.cost);

  final PegsJump jump;
  final int cost;
}
