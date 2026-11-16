/// Mathrax: a Latin square whose only clues sit on the corners between four
/// cells.
///
/// The rules are the genre's (see `mathrax.c` in `x-sheep/puzzles-unreleased`,
/// MIT, pinned in `REFERENCE.md`), and they are the whole game:
///
///  * every row and every column holds 1..N, once each;
///  * a corner clue constrains the four cells around it, along **both**
///    diagonals: `E` all four are even, `O` all four are odd, `=` each diagonal
///    pair is equal, and a number is the result of its operation on each
///    diagonal pair — so `+7` means the two ends of one diagonal add to seven
///    *and* the two ends of the other do too.
///
/// Three vocabularies, kept apart on purpose:
///
///  * a cell of the answer holds a digit 1..N; there is no zero in an answer;
///  * a *clue* is a corner clue or nothing at all — a clue is never a digit, so
///    a missing clue cannot be read as "zero";
///  * a *player cell* is a digit, or [kMathraxBlank] when nothing is written.
library;

/// The three boards the game ships.
///
/// 5x5 is the feed size: four corners per cell block is enough to make the
/// arithmetic matter, and the board still fits a phone without a scroll.
enum MathraxSize {
  small(4),
  medium(5),
  large(6);

  const MathraxSize(this.n);

  /// Side of the square grid, and the largest digit on it.
  final int n;

  int get cellCount => n * n;

  /// Corners between cells: (n-1) squared of them.
  int get clueCount => (n - 1) * (n - 1);
}

/// Nothing written in this cell by the player.
const int kMathraxBlank = 0;

/// What a corner clue asks.
enum MathraxOp {
  even('E'),
  odd('O'),
  equal('='),
  add('+'),
  sub('\u2212'),
  mul('\u00d7'),
  div('\u00f7');

  const MathraxOp(this.sign);

  /// The character the clue prints in front of its number.
  final String sign;

  bool get takesValue =>
      this == MathraxOp.add ||
      this == MathraxOp.sub ||
      this == MathraxOp.mul ||
      this == MathraxOp.div;
}

/// One clue on the corner of four cells.
class MathraxClue {
  const MathraxClue(this.op, [this.value = 0]);

  final MathraxOp op;

  /// The result of the operation, for the four operations. Zero for `E`, `O`
  /// and `=`, because those carry no number.
  final int value;

  /// What the player reads, e.g. `E`, `=` or `+7`.
  String get label => op.takesValue ? '${op.sign}$value' : op.sign;

  @override
  bool operator ==(Object other) =>
      other is MathraxClue && other.op == op && other.value == value;

  @override
  int get hashCode => Object.hash(op, value);

  @override
  String toString() => 'MathraxClue($label)';
}

/// A Mathrax board: the corner clues and the one answer.
class MathraxPuzzle {
  MathraxPuzzle({
    required this.size,
    required this.clues,
    required this.solution,
  })  : assert(clues.length == size.clueCount),
        assert(solution.length == size.cellCount);

  final MathraxSize size;

  /// Row-major over the corners: index `row * (n-1) + col` is the corner shared
  /// by cells (row,col), (row,col+1), (row+1,col) and (row+1,col+1).
  final List<MathraxClue?> clues;

  final List<int> solution;

  int get n => size.n;

  int get cellCount => size.cellCount;

  int get clueCount => size.clueCount;

  int cell(int row, int col) => row * n + col;

  MathraxClue? clueAt(int row, int col) {
    if (row < 0 || col < 0 || row >= n - 1 || col >= n - 1) return null;
    return clues[row * (n - 1) + col];
  }

  /// The four cells around corner (row, col), clockwise from the top left.
  List<int> corner(int row, int col) => [
        cell(row, col),
        cell(row, col + 1),
        cell(row + 1, col),
        cell(row + 1, col + 1),
      ];

  /// Whether one diagonal pair satisfies [clue].
  ///
  /// This is the single place the arithmetic lives: a rule, the win test and
  /// the clue generator all ask this, so a clue can never mean one thing to the
  /// generator and another to the player.
  static bool pairHolds(int a, int b, MathraxClue clue) {
    switch (clue.op) {
      case MathraxOp.even:
        return a.isEven && b.isEven;
      case MathraxOp.odd:
        return a.isOdd && b.isOdd;
      case MathraxOp.equal:
        return a == b;
      case MathraxOp.add:
        return a + b == clue.value;
      case MathraxOp.sub:
        return (a - b).abs() == clue.value;
      case MathraxOp.mul:
        return a * b == clue.value;
      case MathraxOp.div:
        final high = a > b ? a : b;
        final low = a > b ? b : a;
        return low > 0 && high % low == 0 && high ~/ low == clue.value;
    }
  }

  /// Whether the four values around [row],[col] satisfy the clue line by line.
  bool cornerHolds(int row, int col, List<int> values) {
    final clue = clueAt(row, col);
    if (clue == null) return true;
    final cells = corner(row, col);
    return pairHolds(values[cells[0]], values[cells[3]], clue) &&
        pairHolds(values[cells[1]], values[cells[2]], clue);
  }

  /// Whether every clue is satisfied by [values]. A cell still blank is not a
  /// number, so a crammed board cannot pass by accident.
  bool cluesHold(List<int> values) {
    for (var row = 0; row < n - 1; row++) {
      for (var col = 0; col < n - 1; col++) {
        final clue = clueAt(row, col);
        if (clue == null) continue;
        final cells = corner(row, col);
        for (final cell in cells) {
          if (values[cell] == kMathraxBlank) return false;
        }
        if (!cornerHolds(row, col, values)) return false;
      }
    }
    return true;
  }

  /// Whether [values] is the one answer: a Latin square with every clue true.
  bool isSolution(List<int> values) {
    if (values.length != cellCount) return false;
    for (final value in values) {
      if (value < 1 || value > n) return false;
    }
    for (var row = 0; row < n; row++) {
      final seen = <int>{};
      for (var col = 0; col < n; col++) {
        if (!seen.add(values[cell(row, col)])) return false;
      }
    }
    for (var col = 0; col < n; col++) {
      final seen = <int>{};
      for (var row = 0; row < n; row++) {
        if (!seen.add(values[cell(row, col)])) return false;
      }
    }
    return cluesHold(values);
  }

  /// Whether a half-filled board has already gone wrong: a repeated digit in a
  /// row or column, or a corner whose four cells are known and do not satisfy
  /// the clue. A blank does not violate anything.
  bool isLegal(List<int> values) {
    for (var row = 0; row < n; row++) {
      final seen = <int>{};
      for (var col = 0; col < n; col++) {
        final value = values[cell(row, col)];
        if (value == kMathraxBlank) continue;
        if (!seen.add(value)) return false;
      }
    }
    for (var col = 0; col < n; col++) {
      final seen = <int>{};
      for (var row = 0; row < n; row++) {
        final value = values[cell(row, col)];
        if (value == kMathraxBlank) continue;
        if (!seen.add(value)) return false;
      }
    }
    for (var row = 0; row < n - 1; row++) {
      for (var col = 0; col < n - 1; col++) {
        if (clueAt(row, col) == null) continue;
        final cells = corner(row, col);
        if (cells.any((cell) => values[cell] == kMathraxBlank)) continue;
        if (!cornerHolds(row, col, values)) return false;
      }
    }
    return true;
  }

  /// The cells that break a rule on [values], for the board to paint red.
  Set<int> conflicts(List<int> values) {
    final bad = <int>{};
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final value = values[cell(row, col)];
        if (value == kMathraxBlank) continue;
        for (var other = 0; other < n; other++) {
          if (other != col && values[cell(row, other)] == value) {
            bad.add(cell(row, col));
          }
          if (other != row && values[cell(other, col)] == value) {
            bad.add(cell(row, col));
          }
        }
      }
    }
    for (var row = 0; row < n - 1; row++) {
      for (var col = 0; col < n - 1; col++) {
        if (clueAt(row, col) == null) continue;
        final cells = corner(row, col);
        if (cells.any((cell) => values[cell] == kMathraxBlank)) continue;
        if (!cornerHolds(row, col, values)) bad.addAll(cells);
      }
    }
    return bad;
  }
}
