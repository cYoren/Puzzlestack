import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import '../../../core/board/puzzle_marks.dart';
import 'clusters_engine.dart';
import 'clusters_provider.dart';

/// Clusters on the board contract.
///
/// Two fills and one knockout dot. The dot is the clue and it carries its own
/// colour, so it is drawn as a hole in the tile: light on the dark colour, and
/// on the light one the same hole punched out of the grey. A player who cannot
/// tell the two colours apart at 320dp has the wrong mark, not the wrong idea.
class ClustersBoard extends GridBoard<ClustersState> {
  ClustersBoard({required this.state});

  @override
  final ClustersState state;

  @override
  int get rows => state.n;

  @override
  int get cols => state.n;

  @override
  bool get isSolved => state.isSolved;

  @override
  double get gapFraction => 0.06;

  @override
  double get margin => 0.03;

  late final Set<int> _conflicts = state.conflicts;

  @override
  List<PuzzleMove<ClustersState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<ClustersState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    return PuzzleMove<ClustersState>(
      kind: MoveKind.toggle,
      source: element,
      apply: (current) => current,
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, ClustersState state, int row, int col) {
    final cell = row * cols + col;
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final marks = PuzzleMarks(canvas, fraction: 0.9);
    final clue = state.puzzle.clue(cell);
    final colour = clue != kClusterNoClue ? clue : state.values[cell];
    final conflict = _conflicts.contains(cell);

    final role = switch (colour) {
      kClusterRed => MarkRole.primary,
      kClusterBlue => MarkRole.structure,
      _ => null,
    };

    if (role == null) {
      marks.tile(rect, fill: palette.surface);
    } else {
      marks.block(rect, role: role, inset: 0.04);
      // The dot is the clue: a hole in the tile, so it reads as part of the
      // colour rather than as a third mark.
      if (clue != kClusterNoClue) {
        // A hole in the tile, not a mark on top of it: the dot belongs to the
        // colour, and two marks would read as a third colour.
        canvas.dot(
          rect.center,
          canvas.radiusFor(rect, 0.17),
          color: palette.surface,
        );
      }
    }

    if (conflict) {
      canvas.cell(rect, stroke: palette.error, strokeWidth: 2.5, radius: 6);
    }
    if (state.hintCell == cell) marks.hint(rect);
  }
}
