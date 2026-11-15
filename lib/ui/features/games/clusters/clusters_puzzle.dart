/// Clusters: two colours, and the dots that give them away.
///
/// The rules are Clusters' (see `clusters.c` in `x-sheep/puzzles-unreleased`,
/// MIT, pinned in `REFERENCE.md`):
///
///  * every cell is one of two colours;
///  * a dotted cell has exactly one neighbour of its own colour, and the dot
///    is drawn in that colour, so the dot also fixes the cell;
///  * every cell without a dot has at least two neighbours of its own colour.
///
/// The three vocabularies are separate on purpose. A *clue* is
/// [kClusterNoClue] or a colour. A *player cell* is [kClusterUnmarked] or a
/// colour. An *answer* cell is always a colour: a zero in an answer is a bug,
/// not a third colour.
library;

/// The tiles, in the clue vocabulary and in the answer vocabulary.
const int kClusterRed = 1;
const int kClusterBlue = 2;

/// Nothing printed on this cell.
const int kClusterNoClue = 0;

/// Nothing written in this cell by the player.
const int kClusterUnmarked = 0;

/// The other colour, for the two rules that talk about "not mine".
int otherColour(int colour) =>
    colour == kClusterRed ? kClusterBlue : kClusterRed;

/// The three boards the game ships.
///
/// The feed size is 6x6. Clusters gets harder with area rather than with
/// trickier deductions, so a smaller board is a shorter card, not a simpler
/// idea.
enum ClustersSize {
  small(6),
  medium(7),
  large(8);

  const ClustersSize(this.n);

  final int n;

  int get cellCount => n * n;
}

/// A Clusters board: the dots, and the one colouring that makes them true.
class ClustersPuzzle {
  ClustersPuzzle({
    required this.size,
    required this.clues,
    required this.solution,
  })  : assert(clues.length == size.cellCount),
        assert(solution.length == size.cellCount);

  final ClustersSize size;

  /// Per cell, the colour a dot prints, or [kClusterNoClue].
  final List<int> clues;

  /// Per cell, the answer colour. Never zero.
  final List<int> solution;

  int get n => size.n;

  int get cellCount => size.cellCount;

  int cell(int row, int col) => row * n + col;

  int row(int cell) => cell ~/ n;

  int col(int cell) => cell % n;

  int clue(int cell) => clues[cell];

  int clueCount() => clues.where((clue) => clue != kClusterNoClue).length;

  /// The cells that touch [cell], along an edge.
  List<int> neighboursOf(int cell) {
    final r = row(cell);
    final c = col(cell);
    return [
      if (r > 0) cell - n,
      if (r + 1 < n) cell + n,
      if (c > 0) cell - 1,
      if (c + 1 < n) cell + 1,
    ];
  }

  /// How many cells around [cell] hold the same colour as [colour].
  int sameAround(List<int> values, int cell, int colour) {
    var count = 0;
    for (final other in neighboursOf(cell)) {
      final value = values[other];
      if (value == kClusterUnmarked) continue;
      if (value == colour) count++;
    }
    return count;
  }

  /// True when [values] is a legal colouring of the clues: a dot is a cell with
  /// exactly one same-coloured neighbour, and a cell without a dot has two or
  /// more.
  bool isLegal(List<int> values) {
    if (values.length != cellCount) return false;
    for (final value in values) {
      if (value != kClusterRed && value != kClusterBlue) return false;
    }
    for (var cell = 0; cell < cellCount; cell++) {
      final colour = values[cell];
      final same = sameAround(values, cell, colour);
      final clue = clues[cell];
      if (clue != kClusterNoClue) {
        if (colour != clue) return false;
        if (same != 1) return false;
      } else if (same < 2) {
        return false;
      }
    }
    return true;
  }

  /// True when the player is finished.
  bool isSolved(List<int> values) {
    if (values.any((value) => value == kClusterUnmarked)) return false;
    return isLegal(values);
  }

  /// The cells the player has made impossible.
  ///
  /// Same test as [isLegal], per cell, so the board can paint the mistake
  /// without the widget deciding anything about the game.
  Set<int> conflicts(List<int> values) {
    final bad = <int>{};
    for (var cell = 0; cell < cellCount; cell++) {
      final clue = clues[cell];
      if (clue != kClusterNoClue && values[cell] != kClusterUnmarked) {
        if (values[cell] != clue) bad.add(cell);
      }
    }
    for (var cell = 0; cell < cellCount; cell++) {
      final colour = values[cell];
      if (colour == kClusterUnmarked) continue;
      final same = sameAround(values, cell, colour);
      final open = neighboursOf(cell)
          .where((other) => values[other] == kClusterUnmarked)
          .length;
      if (clues[cell] != kClusterNoClue) {
        if (same > 1 || same + open < 1) bad.add(cell);
      } else {
        if (same + open < 2) bad.add(cell);
      }
    }
    return bad;
  }
}
