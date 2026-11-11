/// Tents & Trees: every tree has one tent beside it, orthogonally; every tent
/// belongs to exactly one tree; tents never touch, not even at a corner; and
/// the numbers along the edges say how many tents each row and column holds.
///
/// The old engine placed trees and tents without ever checking that the numbers
/// pin the tents down, so a board could accept a second arrangement. This one
/// hands the clues to the deduction harness and ships only a board with exactly
/// one answer that the rules can reach.
class TentsPuzzle {
  const TentsPuzzle({
    required this.rows,
    required this.cols,
    required this.trees,
    required this.solution,
    required this.rowCounts,
    required this.colCounts,
  });

  final int rows;
  final int cols;

  /// Cell indices holding a tree.
  final List<int> trees;

  /// Cell indices holding a tent in the answer.
  final List<int> solution;

  final List<int> rowCounts;
  final List<int> colCounts;

  int get cellCount => rows * cols;

  int get treeCount => trees.length;

  bool isTree(int cell) => trees.contains(cell);
}

enum TentsDifficulty {
  easy(5, 5, 1),
  medium(6, 6, 2),
  hard(7, 7, 3);

  const TentsDifficulty(this.rows, this.cols, this.level);

  final int rows;
  final int cols;

  /// The rule level the board must need — exactly, not at least. An "easy"
  /// board that needs the hard rule is not easy, and a "hard" board the easy
  /// rules walk through is not hard, however big it is.
  final int level;
}
