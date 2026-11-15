/// Boats: the fleet is hidden, the row and column counts are given.
///
/// Rules are the classical Battleships rules (see `boats.c` in
/// `x-sheep/puzzles-unreleased`, MIT, pinned in REFERENCE.md):
///
///  * every boat is a straight run of cells, horizontal or vertical;
///  * boats never touch, not even at a corner;
///  * the numbers outside the grid count the boat cells in that row or column;
///  * the fleet is a fixed multiset of lengths, so the total is known.
///
/// The board is a set of clues, so whether the clues pin down one fleet is a
/// property of the clues and has to be counted. [BoatsFleetSearch] is that
/// count: it enumerates every fleet placement consistent with what is known,
/// which makes it both the uniqueness proof and the strongest deduction rule.
library;

/// The three boards the game ships.
///
/// Feed size is 6x6: it is the smallest grid where a counts-only board is
/// pinned down often enough to deal quickly, and it is the size a first-timer
/// finishes in about a minute. The bigger boards live in the Stack.
enum BoatsSize {
  small(rows: 6, cols: 6, fleet: [3, 3, 2]),
  medium(rows: 8, cols: 8, fleet: [4, 3, 3, 2, 2]),
  large(rows: 10, cols: 10, fleet: [4, 4, 3, 3, 2, 2, 2]);

  const BoatsSize({
    required this.rows,
    required this.cols,
    required this.fleet,
  });

  final int rows;
  final int cols;

  /// Boat lengths, longest first. How often a length appears is the fleet.
  final List<int> fleet;

  int get shipCells => fleet.fold(0, (sum, length) => sum + length);
}

/// What a cell is, in a solved or a partly solved board.
const int kBoatWater = 0;
const int kBoatShip = 1;

/// What a *clue* says about a cell, which is a different question from what the
/// answer is: a clue may say nothing at all, and "nothing" must not be spelled
/// the same way as "water". Sharing `0` between them silently made every cell
/// a given water cell and no board could be solved.
const int kKnownAny = 0;
const int kKnownWater = 1;
const int kKnownShip = 2;

/// Maps a puzzle answer cell to the clue vocabulary.
int knownOfSolution(int value) => value == kBoatShip ? kKnownShip : kKnownWater;

/// A Boats board: the clues, and the fleet that satisfies them.
class BoatsPuzzle {
  BoatsPuzzle({
    required this.size,
    required this.rowCounts,
    required this.colCounts,
    required this.fleet,
    required this.solution,
    this.givens = const [],
  });

  final BoatsSize size;
  final List<int> rowCounts;
  final List<int> colCounts;

  /// Boat lengths, longest first.
  final List<int> fleet;

  /// Per cell, [kBoatShip] or [kBoatWater]; the unique answer.
  final List<int> solution;

  /// Per cell: 0 when nothing is given, [kBoatShip] or [kBoatWater] when the
  /// clue is printed on the board.
  final List<int> givens;

  int get rows => size.rows;
  int get cols => size.cols;
  int get cellCount => rows * cols;

  int cell(int row, int col) => row * cols + col;

  bool get hasGivens => givens.any((value) => value != 0);

  int given(int cell) => givens.isEmpty ? 0 : givens[cell];

  /// The largest boat in the fleet.
  int get longestBoat => fleet.first;

  int get boatCount => fleet.length;

  /// True when [solve] fits every clue printed on the board.
  bool matchesClues(List<int> solve) {
    for (var cell = 0; cell < cellCount; cell++) {
      final known = given(cell);
      if (known != 0 && solve[cell] != known) return false;
    }
    for (var row = 0; row < rows; row++) {
      var count = 0;
      for (var col = 0; col < cols; col++) {
        if (solve[row * cols + col] == kBoatShip) count++;
      }
      if (count != rowCounts[row]) return false;
    }
    for (var col = 0; col < cols; col++) {
      var count = 0;
      for (var row = 0; row < rows; row++) {
        if (solve[row * cols + col] == kBoatShip) count++;
      }
      if (count != colCounts[col]) return false;
    }
    return true;
  }

  /// The lengths of the boats in [solve], longest first.
  ///
  /// A boat is a maximal run of ship cells. The rules forbid two boats from
  /// touching even at a corner, so runs never merge diagonally and this does
  /// not have to.
  List<int> runsOf(List<int> solve) {
    final seen = List<bool>.filled(cellCount, false);
    final lengths = <int>[];
    for (var cell = 0; cell < cellCount; cell++) {
      if (solve[cell] != kBoatShip || seen[cell]) continue;
      final row = cell ~/ cols;
      final col = cell % cols;
      final horizontal =
          (col + 1 < cols && solve[row * cols + col + 1] == kBoatShip) ||
              (col > 0 && solve[row * cols + col - 1] == kBoatShip);
      var length = 0;
      if (horizontal) {
        var start = col;
        while (start > 0 && solve[row * cols + start - 1] == kBoatShip) {
          start--;
        }
        for (var c = start; c < cols; c++) {
          final index = row * cols + c;
          if (solve[index] != kBoatShip) break;
          seen[index] = true;
          length++;
        }
      } else {
        var start = row;
        while (start > 0 && solve[(start - 1) * cols + col] == kBoatShip) {
          start--;
        }
        for (var r = start; r < rows; r++) {
          final index = r * cols + col;
          if (solve[index] != kBoatShip) break;
          seen[index] = true;
          length++;
        }
      }
      lengths.add(length);
    }
    lengths.sort((a, b) => b.compareTo(a));
    return lengths;
  }

  /// True when [solve] is a legal answer: the clues hold, the fleet matches and
  /// no two boats touch.
  bool isLegal(List<int> solve) {
    if (!matchesClues(solve)) return false;
    final runs = runsOf(solve);
    if (runs.length != fleet.length) return false;
    for (var i = 0; i < runs.length; i++) {
      if (runs[i] != fleet[i]) return false;
    }
    // Touching at a corner is illegal, so no ship cell may have a diagonal
    // ship neighbour.
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if (solve[row * cols + col] != kBoatShip) continue;
        for (var dr = -1; dr <= 1; dr += 2) {
          for (var dc = -1; dc <= 1; dc += 2) {
            final r = row + dr;
            final c = col + dc;
            if (r < 0 || r >= rows || c < 0 || c >= cols) continue;
            if (solve[r * cols + c] == kBoatShip) return false;
          }
        }
      }
    }
    return true;
  }
}

/// The result of counting the fleets that fit a set of clues.
class BoatsCount {
  const BoatsCount({
    required this.solutions,
    required this.shipInAll,
    required this.waterInAll,
    required this.truncated,
  });

  /// Fleets found, capped at the limit asked for.
  final int solutions;

  /// Cells that hold a boat cell in every fleet found.
  final List<int> shipInAll;

  /// Cells that are water in every fleet found.
  final List<int> waterInAll;

  /// True when the budget or the limit ran out. A truncated count proves
  /// nothing, so it is never read as unique and never used as a deduction.
  final bool truncated;

  bool get isUnique => solutions == 1 && !truncated;
}

/// One candidate placement of a boat: the top-left cell, a direction and a
/// position in the fixed enumeration order.
class _Placement {
  const _Placement(this.row, this.col, this.horizontal, this.position);

  final int row;
  final int col;
  final bool horizontal;
  final int position;
}

/// Enumerates every placement of [fleet] that fits the counts, the given cells
/// and whatever the player has already decided.
///
/// Placement, not cell-by-cell guessing: a boat is one decision with a length
/// and a direction, so the search space is the fleets that could fit, not the
/// 2^(rows*cols) ways to colour cells. Boats are tried longest first, which
/// prunes hardest; boats of the same length are required to appear in
/// increasing enumeration order, so a fleet is never counted twice for swapping
/// two identical boats.
///
/// [known] is per cell: [kKnownAny] for "not decided", [kKnownWater] or
/// [kKnownShip]. That is what turns the enumerator into a deduction rule: a cell
/// that is a boat cell in every fleet consistent with [known] is forced, and
/// forcing it is sound.
class BoatsFleetSearch {
  BoatsFleetSearch({
    required this.rows,
    required this.cols,
    required this.rowCounts,
    required this.colCounts,
    required this.fleet,
    required List<int> known,
    this.limit = 2,
    this.budget = 200000,
  })  : known = List<int>.from(known),
        assert(known.length == rows * cols);

  final int rows;
  final int cols;
  final List<int> rowCounts;
  final List<int> colCounts;
  final List<int> fleet;

  /// Per cell: [kKnownAny], [kKnownWater] or [kKnownShip].
  final List<int> known;

  /// Stop after this many fleets. 2 proves a board ambiguous; the deduction
  /// rule asks for every fleet it can get inside [budget].
  final int limit;

  /// Placement attempts before giving up.
  final int budget;

  int get _cellCount => rows * cols;

  late List<int> _owner; // 0 free, otherwise boat index + 1
  late List<int> _rowUsed;
  late List<int> _colUsed;
  int _nodes = 0;
  int _solutions = 0;
  bool _truncated = false;
  late List<int> _shipHits;
  late List<int> _waterHits;

  BoatsCount run() {
    _owner = List<int>.filled(_cellCount, 0);
    _rowUsed = List<int>.filled(rows, 0);
    _colUsed = List<int>.filled(cols, 0);
    _shipHits = List<int>.filled(_cellCount, 0);
    _waterHits = List<int>.filled(_cellCount, 0);

    _place(0, 0);

    final shipInAll = <int>[];
    final waterInAll = <int>[];
    if (!_truncated && _solutions > 0) {
      for (var cell = 0; cell < _cellCount; cell++) {
        if (_shipHits[cell] == _solutions) shipInAll.add(cell);
        if (_waterHits[cell] == _solutions) waterInAll.add(cell);
      }
    }
    return BoatsCount(
      solutions: _solutions,
      shipInAll: shipInAll,
      waterInAll: waterInAll,
      truncated: _truncated,
    );
  }

  /// Places boat [index]. [minPosition] is the lower bound on the enumeration
  /// position, which is how two boats of the same length are kept in order.
  void _place(int index, int minPosition) {
    if (_truncated || _solutions >= limit) return;
    if (index == fleet.length) {
      _record();
      return;
    }

    final length = fleet[index];
    final sameAsPrevious = index > 0 && fleet[index - 1] == length;
    final lower = sameAsPrevious ? minPosition : 0;

    for (final candidate in _placements(length)) {
      if (candidate.position < lower) continue;
      if (!_canPlace(candidate, length)) continue;
      if (++_nodes > budget) {
        _truncated = true;
        return;
      }
      _occupy(index, candidate, length, true);
      _place(index + 1, candidate.position + 1);
      _occupy(index, candidate, length, false);
      if (_truncated || _solutions >= limit) return;
    }
  }

  /// Every position a boat of [length] could sit at, in a fixed order:
  /// row-major for horizontal, then row-major for vertical.
  ///
  /// A one-cell boat has no direction, so it is enumerated once. Enumerating it
  /// twice would let a fleet of two single-cell boats be counted twice for the
  /// same pair of cells, which reads as an ambiguous board that is not.
  Iterable<_Placement> _placements(int length) sync* {
    var position = 0;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col + length <= cols; col++) {
        yield _Placement(row, col, true, position++);
      }
    }
    if (length == 1) return;
    for (var row = 0; row + length <= rows; row++) {
      for (var col = 0; col < cols; col++) {
        yield _Placement(row, col, false, position++);
      }
    }
  }

  bool _canPlace(_Placement p, int length) {
    for (var step = 0; step < length; step++) {
      final r = p.horizontal ? p.row : p.row + step;
      final c = p.horizontal ? p.col + step : p.col;
      final cell = r * cols + c;
      if (_owner[cell] != 0) return false;
      if (known[cell] == kKnownWater) return false;
    }
    if (p.horizontal) {
      if (_rowUsed[p.row] + length > rowCounts[p.row]) return false;
      for (var step = 0; step < length; step++) {
        if (_colUsed[p.col + step] + 1 > colCounts[p.col + step]) return false;
      }
    } else {
      if (_colUsed[p.col] + length > colCounts[p.col]) return false;
      for (var step = 0; step < length; step++) {
        if (_rowUsed[p.row + step] + 1 > rowCounts[p.row + step]) return false;
      }
    }
    for (var step = 0; step < length; step++) {
      final r = p.horizontal ? p.row : p.row + step;
      final c = p.horizontal ? p.col + step : p.col;
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = r + dr;
          final nc = c + dc;
          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
          if (p.horizontal && dr == 0 && nc >= p.col && nc < p.col + length) {
            continue;
          }
          if (!p.horizontal && dc == 0 && nr >= p.row && nr < p.row + length) {
            continue;
          }
          if (_owner[nr * cols + nc] != 0) return false;
        }
      }
    }
    return true;
  }

  void _occupy(int index, _Placement p, int length, bool on) {
    final delta = on ? 1 : -1;
    for (var step = 0; step < length; step++) {
      final r = p.horizontal ? p.row : p.row + step;
      final c = p.horizontal ? p.col + step : p.col;
      _owner[r * cols + c] = on ? index + 1 : 0;
      _rowUsed[r] += delta;
      _colUsed[c] += delta;
    }
  }

  void _record() {
    if (_truncated || _solutions >= limit) return;
    for (var row = 0; row < rows; row++) {
      if (_rowUsed[row] != rowCounts[row]) return;
    }
    for (var col = 0; col < cols; col++) {
      if (_colUsed[col] != colCounts[col]) return;
    }
    for (var cell = 0; cell < _cellCount; cell++) {
      if (known[cell] == kKnownShip && _owner[cell] == 0) return;
    }
    _solutions++;
    for (var cell = 0; cell < _cellCount; cell++) {
      if (_owner[cell] != 0) {
        _shipHits[cell]++;
      } else {
        _waterHits[cell]++;
      }
    }
  }
}
