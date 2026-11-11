
import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'netslide_engine.dart';
import 'netslide_provider.dart';

/// Netslide on the board contract.
///
/// A cell is drawn as the pipes it holds, so the board reads as a net rather than
/// a grid of symbols. Drag a cell one square along a row or column and that line
/// slides; tap a cell to push its row east, or its column south when a wall stops
/// the row — a tap-only player can still finish any board, just with more taps.
class NetslideBoard extends GridBoard<NetState> {
  NetslideBoard({required this.state});

  @override
  final NetState state;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  @override
  bool get isSolved => const NetEngine().isSolved(state.puzzle, state.masks);

  @override
  double get gapFraction => 0.02;

  @override
  double get margin => 0.04;

  PuzzleMove<NetState> _slideMove(
    ElementRef source, {
    required bool row,
    required int index,
    required bool forward,
  }) =>
      PuzzleMove<NetState>(
        kind: MoveKind.place,
        source: source,
        apply: (current) {
          final next = const NetEngine().slide(
            current.puzzle,
            current.masks,
            row: row,
            index: index,
            forward: forward,
          );
          if (next == null) return current;
          return current.copyWith(
            masks: next,
            moves: current.moves + 1,
            clearHint: true,
          );
        },
      );

  @override
  List<PuzzleMove<NetState>> movesFor(ElementRef element) {
    if (!isCell(element)) return const [];
    final row = element.a;
    final col = element.b;
    final moves = <PuzzleMove<NetState>>[];

    // Slide this row east or west, landing the neighbour in this cell.
    for (final forward in [true, false]) {
      final target = forward ? col + 1 : col - 1;
      if (target < 0 || target >= cols) continue;
      if (const NetEngine().slide(state.puzzle, state.masks,
              row: true, index: row, forward: forward) ==
          null) {
        continue;
      }
      moves.add(_slideMove(element, row: true, index: row, forward: forward));
    }
    for (final forward in [true, false]) {
      final target = forward ? row + 1 : row - 1;
      if (target < 0 || target >= rows) continue;
      if (const NetEngine().slide(state.puzzle, state.masks,
              row: false, index: col, forward: forward) ==
          null) {
        continue;
      }
      moves.add(_slideMove(element, row: false, index: col, forward: forward));
    }
    return moves;
  }

  @override
  PuzzleMove<NetState>? tapMove(ElementRef element) {
    if (!isCell(element)) return null;
    final row = element.a;
    final col = element.b;
    if (const NetEngine().slide(state.puzzle, state.masks,
            row: true, index: row, forward: true) !=
        null) {
      return _slideMove(element, row: true, index: row, forward: true);
    }
    if (const NetEngine().slide(state.puzzle, state.masks,
            row: false, index: col, forward: true) !=
        null) {
      return _slideMove(element, row: false, index: col, forward: true);
    }
    return null;
  }

  @override
  void paintCell(PuzzleCanvas canvas, NetState state, int row, int col) {
    final index = row * cols + col;
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final mask = state.masks[index];
    final hinted = state.hint != null &&
        ((state.hint!.row && state.hint!.index == row) ||
            (!state.hint!.row && state.hint!.index == col));

    canvas.cell(
      rect,
      fill: hinted ? palette.success.withValues(alpha: 0.12) : palette.surface,
      stroke: palette.outline.withValues(alpha: 0.18),
      strokeWidth: 1,
    );

    final wire = palette.ink.withValues(alpha: 0.75);
    final centre = rect.center;
    if (mask & NetBits.east != 0) {
      canvas.line(centre, rect.centerRight, color: wire, width: 3);
    }
    if (mask & NetBits.west != 0) {
      canvas.line(centre, rect.centerLeft, color: wire, width: 3);
    }
    if (mask & NetBits.north != 0) {
      canvas.line(centre, rect.topCenter, color: wire, width: 3);
    }
    if (mask & NetBits.south != 0) {
      canvas.line(centre, rect.bottomCenter, color: wire, width: 3);
    }
    // A joint at the centre, so a straight run reads as pipe rather than line.
    canvas.dot(centre, rect.width * 0.08, color: wire);
  }

  @override
  void paint(PuzzleCanvas canvas, NetState state) {
    super.paint(canvas, state);
    final palette = canvas.palette;

    // Walls between cells: they are the reason a row cannot slide, so they have
    // to be visible.
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final rect = cellRect(row, col);
        if (state.puzzle.hasWall(row * cols + col, NetDirection.east)) {
          canvas.line(
            rect.topRight,
            rect.bottomRight,
            color: palette.ink.withValues(alpha: 0.55),
            width: 2.5,
          );
        }
        if (state.puzzle.hasWall(row * cols + col, NetDirection.south)) {
          canvas.line(
            rect.bottomLeft,
            rect.bottomRight,
            color: palette.ink.withValues(alpha: 0.55),
            width: 2.5,
          );
        }
      }
    }
  }
}
