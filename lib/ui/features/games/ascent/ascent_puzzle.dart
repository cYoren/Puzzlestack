/// Ascent: one path, numbered 1 to the last cell.
///
/// The rules are Hidato's (see `ascent.c` in `x-sheep/puzzles-unreleased`, MIT,
/// pinned in `REFERENCE.md`):
///
///  * every cell holds one number, and the numbers are exactly 1..cells;
///  * consecutive numbers sit in cells that touch, along an edge or a corner;
///  * every printed number is true of the answer.
///
/// We ship the plain board: no walls and no edge-clue mode. Those are two extra
/// modes of the same puzzle, and a card in the feed needs one idea, not three.
///
/// Two vocabularies, spelled separately because a zero that means two things is
/// the bug this project keeps paying for: a *clue* is a number or
/// [kAscentNoClue]; a *player cell* is a number or [kAscentBlank]. Numbers
/// start at 1, so neither zero can be mistaken for one.
library;

/// The three boards the game ships.
///
/// The feed size is 5x5: 25 numbers is the largest path a first-timer finishes
/// in about a minute, and it is the smallest board where the given numbers
/// still leave real work to do.
enum AscentSize {
  small(5),
  medium(6),
  large(7);

  const AscentSize(this.n);

  /// Side of the square grid. The path is 1..n*n.
  final int n;

  int get cellCount => n * n;
}

/// Nothing printed in this cell.
const int kAscentNoClue = 0;

/// Nothing written in this cell by the player.
const int kAscentBlank = 0;

/// An Ascent board: the printed numbers and the one path.
class AscentPuzzle {
  AscentPuzzle({
    required this.size,
    required this.givens,
    required this.solution,
  })  : assert(givens.length == size.cellCount),
        assert(solution.length == size.cellCount);

  final AscentSize size;

  /// Per cell, the printed number, or [kAscentNoClue].
  final List<int> givens;

  /// Per cell, the number the path puts there.
  final List<int> solution;

  int get n => size.n;

  int get cellCount => size.cellCount;

  /// The last number of the path.
  int get maxNumber => cellCount;

  int cell(int row, int col) => row * n + col;

  int row(int cell) => cell ~/ n;

  int col(int cell) => cell % n;

  int given(int cell) => givens[cell];

  int clueCount() => givens.where((value) => value != kAscentNoClue).length;

  /// True when two cells touch, along an edge or a corner.
  bool neighbours(int a, int b) {
    if (a == b) return false;
    final dr = (row(a) - row(b)).abs();
    final dc = (col(a) - col(b)).abs();
    return dr <= 1 && dc <= 1;
  }

  /// Every cell that touches [cell], in row-major order.
  List<int> neighboursOf(int cell) {
    final r = row(cell);
    final c = col(cell);
    return [
      for (var dr = -1; dr <= 1; dr++)
        for (var dc = -1; dc <= 1; dc++)
          if ((dr != 0 || dc != 0) &&
              r + dr >= 0 &&
              r + dr < n &&
              c + dc >= 0 &&
              c + dc < n)
            this.cell(r + dr, c + dc),
    ];
  }

  /// The cell that holds [number] in [values], or null.
  int? cellOf(List<int> values, int number) {
    for (var cell = 0; cell < cellCount; cell++) {
      if (values[cell] == number) return cell;
    }
    return null;
  }

  /// True when [values] is a legal path: every number 1..maxNumber once, and
  /// each one touching the next.
  bool isLegal(List<int> values) {
    if (values.length != cellCount) return false;
    final seen = List<bool>.filled(maxNumber + 1, false);
    for (final value in values) {
      if (value < 1 || value > maxNumber) return false;
      if (seen[value]) return false;
      seen[value] = true;
    }
    for (var number = 1; number < maxNumber; number++) {
      final a = cellOf(values, number)!;
      final b = cellOf(values, number + 1)!;
      if (!neighbours(a, b)) return false;
    }
    return true;
  }

  /// True when [values] fits every printed number.
  bool matchesGivens(List<int> values) {
    for (var cell = 0; cell < cellCount; cell++) {
      final clue = givens[cell];
      if (clue != kAscentNoClue && values[cell] != clue) return false;
    }
    return true;
  }

  /// True when the player is finished: a legal path that agrees with the
  /// printed numbers, with no blank cell left.
  bool isSolved(List<int> values) {
    if (values.any((value) => value == kAscentBlank)) return false;
    return matchesGivens(values) && isLegal(values);
  }

  /// The cells the player has made impossible, so the board can say so.
  ///
  /// A number repeated, or two consecutive numbers that do not touch, are both
  /// visible mistakes. It lives in the puzzle so a test can ask without pumping
  /// a screen.
  Set<int> conflicts(List<int> values) {
    final bad = <int>{};
    final firstCellOf = <int, int>{};
    for (var cell = 0; cell < cellCount; cell++) {
      final value = values[cell];
      if (value == kAscentBlank) continue;
      final previous = firstCellOf[value];
      if (previous != null) {
        bad.add(previous);
        bad.add(cell);
      } else {
        firstCellOf[value] = cell;
      }
    }
    for (var number = 1; number < maxNumber; number++) {
      final a = firstCellOf[number];
      final b = firstCellOf[number + 1];
      if (a == null || b == null) continue;
      if (!neighbours(a, b)) {
        bad.add(a);
        bad.add(b);
      }
    }
    return bad;
  }
}
