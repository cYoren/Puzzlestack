/// Magnets: the board is tiled with dominoes; each domino is either a magnet
/// (one `+` end and one `-` end) or blank. Every row and column shows how many
/// `+` and how many `-` cells it holds, and two equal poles may never touch
/// orthogonally.
///
/// The old engine did check uniqueness, but it had a **hardcoded 4x4 board** as
/// its fallback, one fixed size, no hint, and — the part a player notices — the
/// domino tiling was never drawn. Tapping a cell toggled a pair the player could
/// not see.
///
/// This one tiles at random, assigns poles without breaking the adjacency rule,
/// and then hands the clues to the deduction harness in `lib/core/deduction.dart`:
/// a board ships only when exactly one completion exists *and* the rules can
/// reach it. The rule level it needs is the difficulty.
class MagnetsPuzzle {
  const MagnetsPuzzle({
    required this.rows,
    required this.cols,
    required this.dominoA,
    required this.dominoB,
    required this.dominoOf,
    required this.solution,
    required this.rowPlus,
    required this.rowMinus,
    required this.colPlus,
    required this.colMinus,
  });

  final int rows;
  final int cols;

  /// The two cells of each domino, as row-major indices.
  final List<int> dominoA;
  final List<int> dominoB;

  /// Cell -> its domino.
  final List<int> dominoOf;

  /// Per domino: 0 blank, 1 = `a` is `+` and `b` is `-`, 2 = the reverse.
  final List<int> solution;

  final List<int> rowPlus;
  final List<int> rowMinus;
  final List<int> colPlus;
  final List<int> colMinus;

  int get cellCount => rows * cols;

  int get dominoCount => dominoA.length;

  /// How many magnets (not blanks) the answer holds.
  int get magnetCount => solution.where((s) => s != 0).length;
}

enum MagnetsDifficulty {
  easy(4, 4, 1),
  medium(5, 6, 2),
  hard(6, 6, 3);

  const MagnetsDifficulty(this.rows, this.cols, this.minLevel);

  final int rows;
  final int cols;

  /// The lowest rule level the board must need. A board the easy rules finish
  /// is not a hard board, however big it looks.
  final int minLevel;
}
