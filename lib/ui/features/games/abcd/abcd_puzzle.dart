/// ABCD: a letter in every cell.
///
/// Rules are the classical ABC-Kombi rules (`abcd.c` in
/// `x-sheep/puzzles-unreleased`, MIT, pinned in REFERENCE.md):
///
///  * every cell holds one letter from a fixed alphabet;
///  * the numbers along an edge say how many of each letter that row or column
///    holds;
///  * two identical letters may not touch along an edge.
///
/// The clues are the counts, so whether they pin the grid down is a property of
/// the counts and has to be counted. That is what the deduction model in
/// `abcd_model.dart` does; this file holds the board and its sizes.
library;

/// The boards the game ships.
///
/// The feed size is 5x5 with four letters: it is the preset the original
/// author calls the smallest playable one, and it reads in five seconds because
/// a row's four numbers are its whole story.
enum AbcdSize {
  small(rows: 5, cols: 5, letters: 4),
  medium(rows: 6, cols: 6, letters: 3),
  large(rows: 7, cols: 7, letters: 3);

  const AbcdSize({
    required this.rows,
    required this.cols,
    required this.letters,
  });

  final int rows;
  final int cols;

  /// How many letters the alphabet has. A is 0.
  final int letters;

  String get alphabet =>
      String.fromCharCodes(List.generate(letters, (i) => 65 + i));
}

/// A board: the counts, and the grid that satisfies them.
class AbcdPuzzle {
  AbcdPuzzle({
    required this.size,
    required this.rowCounts,
    required this.colCounts,
    required this.solution,
  });

  final AbcdSize size;

  /// Per row, how many of each letter it holds. Letter index 0 is A.
  final List<List<int>> rowCounts;

  /// Per column, how many of each letter it holds.
  final List<List<int>> colCounts;

  /// Per cell, the letter index (0 = A).
  final List<int> solution;

  int get rows => size.rows;
  int get cols => size.cols;
  int get letters => size.letters;
  int get cellCount => rows * cols;

  int cell(int row, int col) => row * cols + col;

  String letterAt(int index) => String.fromCharCode(65 + index);

  /// True when a row's letters match its clues exactly.
  ///
  /// The board colours a clue when the line is *done*, so this has to be an
  /// equality test on every letter. The first version asked only whether a
  /// letter had overshot its target, which is true of an empty row: every row
  /// clue was green from the first frame while the column clues turned green
  /// only when they were really finished. One function for both directions now,
  /// so they cannot drift apart again.
  bool rowSatisfied(List<int> grid, int row) => _lineSatisfied(
        grid,
        [for (var col = 0; col < cols; col++) row * cols + col],
        rowCounts[row],
      );

  /// True when a column's letters match its clues exactly.
  bool colSatisfied(List<int> grid, int col) => _lineSatisfied(
        grid,
        [for (var row = 0; row < rows; row++) row * cols + col],
        colCounts[col],
      );

  bool _lineSatisfied(List<int> grid, List<int> cells, List<int> counts) {
    for (var letter = 0; letter < letters; letter++) {
      var seen = 0;
      for (final cell in cells) {
        if (grid[cell] == letter) seen++;
      }
      if (seen != counts[letter]) return false;
    }
    return true;
  }

  /// True when [grid] fits every clue and breaks no adjacency rule.
  bool isLegal(List<int> grid) {
    for (final value in grid) {
      if (value < 0 || value >= letters) return false;
    }
    for (var row = 0; row < rows; row++) {
      for (var letter = 0; letter < letters; letter++) {
        var count = 0;
        for (var col = 0; col < cols; col++) {
          if (grid[row * cols + col] == letter) count++;
        }
        if (count != rowCounts[row][letter]) return false;
      }
    }
    for (var col = 0; col < cols; col++) {
      for (var letter = 0; letter < letters; letter++) {
        var count = 0;
        for (var row = 0; row < rows; row++) {
          if (grid[row * cols + col] == letter) count++;
        }
        if (count != colCounts[col][letter]) return false;
      }
    }
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final value = grid[row * cols + col];
        if (col + 1 < cols && grid[row * cols + col + 1] == value) return false;
        if (row + 1 < rows && grid[(row + 1) * cols + col] == value) {
          return false;
        }
      }
    }
    return true;
  }
}
