import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'lights_out_engine.dart';
import 'lights_out_provider.dart';

/// Lights Out on the board contract.
///
/// Tap a cell and it flips with its neighbours. There is no drag: the move is
/// a press on one square, not a square moving somewhere.
class LightsOutBoard extends GridBoard<LightsOutState> {
  LightsOutBoard({required this.state, this.engine = const LightsOutEngine()});

  @override
  final LightsOutState state;

  final LightsOutEngine engine;

  @override
  int get rows => state.puzzle.size;

  @override
  int get cols => state.puzzle.size;

  @override
  bool get isSolved => state.isSolved;

  @override
  List<PuzzleMove<LightsOutState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<LightsOutState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    final index = element.a * cols + element.b;

    return PuzzleMove<LightsOutState>(
      kind: MoveKind.toggle,
      source: element,
      apply: (current) {
        final pressed = [...current.pressed];
        pressed[index] = !pressed[index];
        return current.copyWith(
          grid: engine.press(current.grid, cols, index),
          pressed: pressed,
          presses: current.presses + 1,
          clearHint: true,
        );
      },
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, LightsOutState state, int row, int col) {
    final lit = state.grid[row * cols + col];
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final hint = state.hint;
    final isHint = hint != null && hint == row * cols + col;

    canvas.cell(
      rect,
      fill: lit ? palette.primary : palette.surface,
      stroke: isHint
          ? palette.success
          : palette.outline.withValues(alpha: lit ? 0.0 : 0.35),
      strokeWidth: isHint ? 2.5 : 1.5,
    );
  }
}
