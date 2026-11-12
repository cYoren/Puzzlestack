import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'pegs_engine.dart';
import 'pegs_provider.dart';

/// Peg solitaire on the board contract.
///
/// Drag a peg onto the square it should land on: the engine floats it, shows
/// every legal landing, and the jumped peg disappears on the drop. Tap works
/// too — pick a peg, then tap where it lands.
class PegsBoard extends GridBoard<PegsState> {
  PegsBoard({required this.state, this.engine = const PegsEngine()});

  @override
  final PegsState state;

  final PegsEngine engine;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  @override
  bool get isSolved => state.isSolved;

  PegCell _at(int row, int col) => state.grid[row * cols + col];

  ElementRef _cellOf(int index) => cell(index ~/ cols, index % cols);

  // ------------------------------------------------------------------- rules

  PegsState _jump(PegsState current, PegsJump jump) {
    final grid = engine.apply(current.grid, jump);
    return current.copyWith(
      grid: grid,
      clearSelection: true,
      clearHint: true,
      isSolved: engine.isSolved(grid),
    );
  }

  @override
  List<PuzzleMove<PegsState>> movesFor(ElementRef element) {
    if (!isCell(element)) return const [];
    if (_at(element.a, element.b) != PegCell.peg) return const [];
    final from = element.a * cols + element.b;

    return [
      for (final jump in engine.legalJumps(state.grid, rows, cols))
        if (jump.from == from)
          PuzzleMove<PegsState>(
            kind: MoveKind.place,
            source: element,
            target: _cellOf(jump.to),
            apply: (current) => _jump(current, jump),
          ),
    ];
  }

  @override
  PuzzleMove<PegsState>? tapMove(ElementRef element) {
    if (!isCell(element)) return null;
    final here = element.a * cols + element.b;

    switch (_at(element.a, element.b)) {
      case PegCell.peg:
        final alreadyPicked = state.selected == here;
        return PuzzleMove<PegsState>(
          kind: alreadyPicked ? MoveKind.clear : MoveKind.select,
          source: element,
          apply: (current) => alreadyPicked
              ? current.copyWith(clearSelection: true, clearHint: true)
              : current.copyWith(selected: here, clearHint: true),
        );
      case PegCell.hole:
        final from = state.selected;
        if (from == null) return null;
        for (final jump in engine.legalJumps(state.grid, rows, cols)) {
          if (jump.from == from && jump.to == here) {
            return PuzzleMove<PegsState>(
              kind: MoveKind.place,
              source: _cellOf(from),
              target: element,
              apply: (current) => _jump(current, jump),
            );
          }
        }
        return null;
      case PegCell.obstacle:
        return null;
    }
  }

  // ------------------------------------------------------------------- paint

  @override
  void paintCell(PuzzleCanvas canvas, PegsState state, int row, int col) {
    final palette = canvas.palette;
    final rect = cellRect(row, col);
    final index = row * cols + col;
    final content = _at(row, col);

    if (content == PegCell.obstacle) return;

    final centre = rect.center;
    final radius = rect.shortestSide * 0.30;
    final zone = canvas.highlight.targetAlpha(cell(row, col));
    final hint = state.hint;
    final selected = state.selected;
    final isHintTarget = hint != null && hint.to == index;
    final isHintSource = hint != null && hint.from == index;
    final isHintMid = hint != null && hint.mid == index;

    // A peg is a disc, a hole is a ring: the board says which is which before
    // the first tap, which a coloured square never did.
    if (content == PegCell.hole) {
      canvas.cell(rect, fill: palette.surface, stroke: palette.line);
      canvas.ring(
        centre,
        radius * 0.62,
        color: zone > 0
            ? palette.primary
            : palette.ink.withValues(alpha: 0.25),
        width: zone > 0 ? 2.5 : 1.5,
      );
      if (zone > 0 || isHintTarget) {
        canvas.ring(
          centre,
          radius * 0.95,
          color: palette.primary,
          width: 2,
        );
      }
      return;
    }

    canvas.cell(
      rect,
      fill: palette.surface,
      stroke: palette.line,
    );
    canvas.dot(centre, radius, color: palette.primary);
    canvas.dot(
      centre.translate(-radius * 0.28, -radius * 0.28),
      radius * 0.28,
      color: palette.surface.withValues(alpha: 0.55),
    );

    // What the selected peg would jump over and where it would land, painted
    // before the tap so the move is legible.
    if (selected != null && selected != index) {
      for (final jump in engine.legalJumps(state.grid, rows, cols)) {
        if (jump.from != selected) continue;
        if (jump.mid == index) {
          canvas.ring(centre, radius * 0.55, color: palette.error, width: 2);
        }
        if (jump.to == index) {
          canvas.ring(centre, radius * 1.05, color: palette.primary, width: 2);
        }
      }
    }

    if (selected == index) {
      canvas.ring(centre, radius * 1.18, color: palette.ink, width: 2.5);
    }
    if (isHintSource) {
      canvas.ring(centre, radius * 1.18, color: palette.success, width: 2.5);
    }
    if (isHintMid) {
      canvas.ring(centre, radius * 0.55, color: palette.error, width: 2);
    }
  }

  @override
  void paintElement(PuzzleCanvas canvas, PegsState state, ElementRef element) {
    if (!isCell(element)) return;
    final rect = cellRect(element.a, element.b);
    if (_at(element.a, element.b) == PegCell.peg) {
      canvas.dot(rect.center, rect.shortestSide * 0.30, color: canvas.palette.primary);
    }
  }
}
