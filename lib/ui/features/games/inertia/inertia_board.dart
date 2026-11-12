import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'inertia_engine.dart';
import 'inertia_provider.dart';

/// Inertia on the board contract.
///
/// Drag the ball onto the square it will land on and it slides there; or tap any
/// square in line with it, which is the whole input a tap-only player needs. The
/// landing squares are the drag targets, so the engine shows you where a swipe
/// would put you before you commit.
class InertiaBoard extends GridBoard<InertiaState> {
  InertiaBoard({required this.state});

  @override
  final InertiaState state;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  @override
  bool get isSolved => state.isSolved;

  @override
  double get gapFraction => 0.08;

  InertiaEngine get _engine => const InertiaEngine();

  PuzzleMove<InertiaState> _slideMove(
    ElementRef source,
    InertiaDirection direction,
    int landing,
  ) =>
      PuzzleMove<InertiaState>(
        kind: MoveKind.place,
        source: source,
        target: cell(landing ~/ cols, landing % cols),
        apply: (current) => current.copyWith(
          position: _engine.move(current.puzzle, current.position, direction),
          moves: current.moves + 1,
          clearHint: true,
        ),
      );

  @override
  List<PuzzleMove<InertiaState>> movesFor(ElementRef element) {
    if (!isCell(element) || state.isSolved || state.position.exploded) {
      return const [];
    }
    final index = element.a * cols + element.b;
    if (index != state.position.cell) return const [];

    return [
      for (final direction in InertiaDirection.values)
        if (_engine.landing(state.puzzle, state.position, direction)
            case final landing?)
          _slideMove(element, direction, landing),
    ];
  }

  InertiaDirection? _directionTowards(int cell) {
    final ball = state.position.cell;
    final ballRow = ball ~/ cols;
    final ballCol = ball % cols;
    final row = cell ~/ cols;
    final col = cell % cols;
    if (row == ballRow && col > ballCol) return InertiaDirection.east;
    if (row == ballRow && col < ballCol) return InertiaDirection.west;
    if (col == ballCol && row > ballRow) return InertiaDirection.south;
    if (col == ballCol && row < ballRow) return InertiaDirection.north;
    return null;
  }

  @override
  PuzzleMove<InertiaState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved || state.position.exploded) {
      return null;
    }
    final index = element.a * cols + element.b;
    if (index == state.position.cell) return null;
    final direction = _directionTowards(index);
    if (direction == null) return null;
    final landing = _engine.landing(state.puzzle, state.position, direction);
    if (landing == null) return null;
    return _slideMove(
      cell(state.position.cell ~/ cols, state.position.cell % cols),
      direction,
      landing,
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, InertiaState state, int row, int col) {
    final index = row * cols + col;
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final kind = state.puzzle.kindAt(index);

    if (kind == CellKind.wall) {
      canvas.cell(rect, fill: palette.structure, radius: 4);
      return;
    }

    canvas.cell(
      rect,
      fill: palette.surface,
      stroke: palette.line,
      strokeWidth: 1.2,
    );

    if (kind == CellKind.mine) {
      canvas.dot(rect.center, rect.width * 0.24, color: palette.error);
      canvas.ring(rect.center, rect.width * 0.34, color: palette.error, width: 1.6);
      return;
    }

    final collected = kind == CellKind.gem &&
        state.position.collected &
                (1 << state.puzzle.gemCells.indexOf(index)) !=
            0;
    if (kind == CellKind.gem && !collected) {
      final path = Path()
        ..moveTo(rect.center.dx, rect.center.dy - rect.height * 0.26)
        ..lineTo(rect.center.dx + rect.width * 0.22, rect.center.dy)
        ..lineTo(rect.center.dx, rect.center.dy + rect.height * 0.26)
        ..lineTo(rect.center.dx - rect.width * 0.22, rect.center.dy)
        ..close();
      canvas.path(path, fill: palette.success);
    }
  }

  @override
  void paint(PuzzleCanvas canvas, InertiaState state) {
    super.paint(canvas, state);
    final palette = canvas.palette;
    final ball = state.position.cell;
    final rect = cellRect(ball ~/ cols, ball % cols).deflate(0.006);
    final dead = state.position.exploded;

    canvas.dot(
      rect.center,
      rect.width * 0.34,
      color: dead ? palette.error : palette.primary,
    );
    if (dead) {
      canvas.ring(rect.center, rect.width * 0.44, color: palette.error, width: 2);
    }

    final hint = state.hint;
    if (hint == null) return;
    final landing = const InertiaEngine().landing(state.puzzle, state.position, hint);
    if (landing == null) return;
    canvas.cell(
      cellRect(landing ~/ cols, landing % cols).deflate(0.004),
      stroke: palette.success,
      strokeWidth: 2.5,
      radius: 4,
    );
  }
}
