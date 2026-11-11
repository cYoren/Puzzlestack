import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'kurodoko_engine.dart';
import 'kurodoko_provider.dart';

/// Kurodoko on the board contract.
///
/// Play is tap-only: a tap cycles a cell blank, black, white, blank. There is
/// nothing to drag — the answer is a set of cells, not a path — and a drag
/// gesture would only add a way to get it wrong. Black comes first in the cycle
/// because blackening is the answer; white is a note to yourself.
class KurodokoBoard extends GridBoard<KurodokoState> {
  KurodokoBoard({required this.state});

  @override
  final KurodokoState state;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  /// A hair more room than the default: the numbers need it, and Kurodoko has
  /// no lines between cells that a gap would break up.
  @override
  double get margin => 0.03;

  @override
  double get gapFraction => 0.08;

  KurodokoCell colourOf(int row, int col) =>
      state.grid[state.puzzle.index(row, col)];

  /// Tapping never drags: every move resolves where the finger lands.
  @override
  List<PuzzleMove<KurodokoState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<KurodokoState>? tapMove(ElementRef element) {
    if (!isCell(element)) return null;
    final row = element.a;
    final col = element.b;
    if (!inBounds(row, col)) return null;
    if (state.isSolved) return null;

    final cell = state.puzzle.index(row, col);
    // A clue is white by the rules, so there is nothing to decide about it.
    if (state.puzzle.clues[cell] > 0) return null;

    final next = switch (state.grid[cell]) {
      KurodokoCell.unknown => KurodokoCell.black,
      KurodokoCell.black => KurodokoCell.white,
      KurodokoCell.white => KurodokoCell.unknown,
    };

    return PuzzleMove<KurodokoState>(
      kind: next == KurodokoCell.unknown ? MoveKind.clear : MoveKind.place,
      source: element,
      apply: (current) {
        final grid = [...current.grid];
        grid[cell] = next;
        return current.copyWith(grid: grid, clearHint: true);
      },
    );
  }

  @override
  bool get isSolved => state.isSolved;

  @override
  void paintCell(PuzzleCanvas canvas, KurodokoState state, int row, int col) {
    final cell = state.puzzle.index(row, col);
    final colour = state.grid[cell];
    final clue = state.puzzle.clues[cell];
    final rect = cellRect(row, col);
    final palette = canvas.palette;

    final (fill, stroke) = switch (colour) {
      KurodokoCell.black => (palette.ink, null),
      KurodokoCell.white => (palette.surface, palette.outline),
      KurodokoCell.unknown => (palette.bed, null),
    };

    canvas.cell(rect, fill: fill, stroke: stroke);

    // A cell marked white gets a small dot rather than a number: it is the
    // player's note, and it should not compete with the clues.
    if (colour == KurodokoCell.white && clue == 0) {
      canvas.dot(
        rect.center,
        rect.shortestSide * 0.09,
        color: palette.muted,
      );
    }

    if (clue > 0) {
      canvas.text(
        '$clue',
        rect,
        color: colour == KurodokoCell.black ? palette.surface : palette.ink,
        fontSize: rect.shortestSide * 0.62,
      );
    }

    // The hint ring sits on top of everything, so it reads on a black cell as
    // well as an empty one.
    if (state.hint?.cell == cell) {
      canvas.cell(
        rect,
        stroke: palette.primary,
        strokeWidth: 2.5,
      );
    }
  }
}
