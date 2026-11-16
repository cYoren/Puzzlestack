/// Salad (ABC End View): a Latin square with one hole per line, and letter
/// clues around the border.
///
/// The rules are the genre's (see `salad.c` in `x-sheep/puzzles-unreleased`,
/// MIT, pinned in `REFERENCE.md`):
///
///  * every row and every column holds each letter `A..nums` exactly once, and
///    `n - nums` holes;
///  * a clue on the border is the letter you meet **first** looking into that
///    line, skipping holes. There are four clues per line: top and bottom for a
///    column, left and right for a row.
///
/// The original C ships no in-grid clues at all for orders under 8 — the border
/// is the whole puzzle — and this port does the same.
///
/// Three vocabularies, kept apart on purpose, because two of them are small
/// integers and confusing them is the bug that costs review rounds:
///
///  * a **symbol** on the board is `0` for a hole, `1..nums` for a letter. Zero
///    means a hole and nothing else.
///  * a **clue** is a letter `1..nums`, or [kSaladNoClue] when that border
///    position is blank. A clue is never zero, because zero is the hole.
///  * a **cell the player has not written** is [kSaladBlank]. It is not a hole,
///    and it is not "no clue"; it is "nothing here yet".
library;

/// The three boards the game ships.
///
/// `nums` is the number of letters, `A..nums`; the rest of every line is holes.
/// Every size picks the letters it can: a board is only dealt if its border
/// clues alone pin the answer down and a player can reason to it, and the border
/// of an `o` board carries `4o` clues however big the interior gets. The numbers
/// below are the largest alphabet each side survives, measured over 200 random
/// Latin squares per size (`unique` = one answer, `pass` = one answer and
/// solvable with the player rules):
///
/// ```text
/// 5x5  1 hole   A~D   93/200 unique, 93/200 pass
/// 6x6  1 hole   A~E   31/200 unique, 29/200 pass
/// 7x7  1 hole   A~F    0/200 unique,  0/200 pass
/// 7x7  2 holes  A~E    1/200 unique,  1/200 pass
/// 8x8  2 holes  A~E    0/200 unique,  0/200 pass
/// ```
///
/// So 6x6 keeps the one hole per line the small board has, and the large board
/// keeps the medium board's alphabet and carries two holes per line. That is the
/// only reason `large` is `A~E` and not `A~F`: a 7x7 with one hole per line is
/// not a puzzle, it is a border with an answer that other boards fit just as
/// well, and the generator would have to throw every time.
///
/// 6x6 is the feed size: one hole per line is enough that the two ends of a
/// line disagree often, and the board still fits a phone.
enum SaladSize {
  small(5, 4),
  medium(6, 5),
  large(7, 5);

  const SaladSize(this.n, this.nums);

  /// Side of the square grid.
  final int n;

  /// Letters on the board, `A..nums`.
  final int nums;

  int get cellCount => n * n;

  /// Holes in every row and every column.
  int get holes => n - nums;

  /// Four clues per line: top and bottom for a column, left and right for a row.
  int get clueCount => 4 * n;
}

/// A cell that is a hole in the answer.
const int kSaladHole = 0;

/// A border position with no clue. Never zero: zero is the hole.
const int kSaladNoClue = -1;

/// Nothing written in a cell, and nothing decided about it.
///
/// Distinct from [kSaladHole] on purpose: a hole is a value the player can
/// write and the answer contains, while a blank is work not done yet. A win
/// test that treated them as one would accept an empty board.
const int kSaladBlank = -2;

/// Which edge a clue is read from.
enum SaladClueDir { top, left, bottom, right }

/// The character a symbol prints: `A..` for a letter, a middle dot for a hole.
String saladLetter(int symbol) =>
    symbol == kSaladHole ? '\u00b7' : String.fromCharCode(64 + symbol);

/// A Salad board: the border clues and the one answer.
class SaladPuzzle {
  SaladPuzzle({
    required this.size,
    required this.clues,
    required this.solution,
  })  : assert(clues.length == size.clueCount),
        assert(solution.length == size.cellCount);

  final SaladSize size;

  /// Four blocks of [n] clues, one block per [SaladClueDir] in declaration
  /// order: index `dir.index * n + i` is the clue read from that edge on line
  /// `i` (a column for top/bottom, a row for left/right). Each entry is a
  /// letter `1..nums` or [kSaladNoClue].
  final List<int> clues;

  /// The answer, row-major: [kSaladHole] or a letter `1..nums`.
  final List<int> solution;

  int get n => size.n;

  int get nums => size.nums;

  int get cellCount => size.cellCount;

  int get holes => size.holes;

  int get clueCount => size.clueCount;

  int cell(int row, int col) => row * n + col;

  /// The clue on line [index] read from [dir], or [kSaladNoClue].
  int clue(SaladClueDir dir, int index) => clues[dir.index * n + index];

  /// The cells of one line in the order a player reads it: starting at the edge
  /// the clue sits on, moving inwards.
  List<int> line(SaladClueDir dir, int index) {
    return switch (dir) {
      SaladClueDir.top => [for (var row = 0; row < n; row++) cell(row, index)],
      SaladClueDir.bottom => [
          for (var row = n - 1; row >= 0; row--) cell(row, index)
        ],
      SaladClueDir.left => [for (var col = 0; col < n; col++) cell(index, col)],
      SaladClueDir.right => [
          for (var col = n - 1; col >= 0; col--) cell(index, col)
        ],
    };
  }

  /// A cell's row, for [SaladClueDir.left] and [SaladClueDir.right].
  static bool isRow(SaladClueDir dir) =>
      dir == SaladClueDir.left || dir == SaladClueDir.right;

  /// Whether the clue on this line is true of [values].
  ///
  /// A [kSaladBlank] cell is "not known yet", so a half-filled board is never
  /// accused of breaking a clue it has not reached. A line that is fully
  /// decided and shows no letter at all does break every clue: every letter
  /// appears once in every line.
  bool clueHolds(SaladClueDir dir, int index, List<int> values) {
    final wanted = clue(dir, index);
    if (wanted == kSaladNoClue) return true;
    for (final cell in line(dir, index)) {
      final value = values[cell];
      if (value == kSaladBlank) return true;
      if (value == kSaladHole) continue;
      return value == wanted;
    }
    return false;
  }

  /// Whether [values] is the one answer: a Latin square with the right holes
  /// and every border clue true.
  bool isSolution(List<int> values) {
    if (values.length != cellCount) return false;
    for (final value in values) {
      // [kSaladBlank] is negative and a letter past [nums] is out of range, so
      // an unfinished or over-large board cannot pass here.
      if (value < kSaladHole || value > nums) return false;
    }
    for (var i = 0; i < n; i++) {
      final inRow = <int>{};
      final inCol = <int>{};
      for (var j = 0; j < n; j++) {
        final row = values[cell(i, j)];
        final col = values[cell(j, i)];
        if (row != kSaladHole && !inRow.add(row)) return false;
        if (col != kSaladHole && !inCol.add(col)) return false;
      }
      // Every letter once, in n cells, leaves exactly n - nums holes.
      if (inRow.length != nums || inCol.length != nums) return false;
    }
    for (final dir in SaladClueDir.values) {
      for (var i = 0; i < n; i++) {
        if (!clueHolds(dir, i, values)) return false;
      }
    }
    return true;
  }

  /// Whether a half-filled board has not gone wrong yet.
  ///
  /// Two letters repeated in a line, more holes than the line has room for, or a
  /// finished line whose first letter is not its clue. A blank violates nothing.
  bool isLegal(List<int> values) {
    for (var i = 0; i < n; i++) {
      for (final cells in [
        line(SaladClueDir.left, i),
        line(SaladClueDir.top, i)
      ]) {
        final letters = <int>{};
        var holes = 0;
        for (final cell in cells) {
          final value = values[cell];
          if (value == kSaladBlank) continue;
          if (value == kSaladHole) {
            holes++;
            continue;
          }
          if (!letters.add(value)) return false;
        }
        if (holes > this.holes) return false;
      }
    }
    for (final dir in SaladClueDir.values) {
      for (var i = 0; i < n; i++) {
        if (!clueHolds(dir, i, values)) return false;
      }
    }
    return true;
  }

  /// The cells that break a rule on [values], for the board to paint red.
  Set<int> conflicts(List<int> values) {
    final bad = <int>{};
    for (var i = 0; i < n; i++) {
      for (final cells in [
        line(SaladClueDir.left, i),
        line(SaladClueDir.top, i)
      ]) {
        final seen = <int, List<int>>{};
        final holes = <int>[];
        for (final cell in cells) {
          final value = values[cell];
          if (value == kSaladBlank) continue;
          if (value == kSaladHole) {
            holes.add(cell);
            continue;
          }
          (seen[value] ??= []).add(cell);
        }
        seen.forEach((_, at) {
          if (at.length > 1) bad.addAll(at);
        });
        // A line has room for exactly `holes` holes; a second one is a mistake,
        // and the cell that has to go is one the player wrote as a hole.
        if (holes.length > this.holes) bad.addAll(holes);
      }
    }
    // A clue is only accused once its line is decided: before that, the cell
    // that makes it wrong could still turn out to be a hole.
    for (final dir in SaladClueDir.values) {
      for (var i = 0; i < n; i++) {
        if (clue(dir, i) == kSaladNoClue) continue;
        if (clueHolds(dir, i, values)) continue;
        final cells = line(dir, i);
        if (cells.any((cell) => values[cell] == kSaladBlank)) continue;
        for (final cell in cells) {
          if (values[cell] != kSaladHole) {
            bad.add(cell);
            break;
          }
        }
      }
    }
    return bad;
  }
}
