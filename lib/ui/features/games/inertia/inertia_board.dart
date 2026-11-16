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
      canvas.dot(rect.center, canvas.radiusFor(rect, 0.24),
          color: palette.error);
      canvas.ring(rect.center, canvas.radiusFor(rect, 0.34),
          color: palette.error, width: 1.6);
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

    // Where this ball can go is the whole game, and it used to be invisible
    // until you dropped one. Two things make it readable without a legend:
    // the lane the ball travels in is washed in, and every square it would stop
    // on gets a hairline. The ball itself is drawn last and larger than before,
    // with a paper ring so it never disappears against a wall.
    if (!state.isSolved && !state.position.exploded) {
      _paintLane(canvas, state);
      _paintLandings(canvas, state);
    }

    _paintBall(canvas, state, state.position.cell);

    final hint = state.hint;
    if (hint == null) return;
    final landing =
        const InertiaEngine().landing(state.puzzle, state.position, hint);
    if (landing == null) return;
    canvas.cell(
      cellRect(landing ~/ cols, landing % cols).deflate(0.004),
      stroke: canvas.palette.success,
      strokeWidth: 2.5,
      radius: 4,
    );
  }

  /// The row and the column the ball can move along.
  void _paintLane(PuzzleCanvas canvas, InertiaState state) {
    final palette = canvas.palette;
    final int row = state.position.cell ~/ cols;
    final int col = state.position.cell % cols;
    final Color wash = palette.ink.withValues(alpha: 0.05);

    void washCell(int r, int c) {
      if (r == row && c == col) return;
      // Only the floor: a wall, a gem or a mine keeps its own colour.
      if (state.puzzle.kindAt(r * cols + c) != CellKind.floor) return;
      canvas.cell(cellRect(r, c), fill: wash, radius: 4);
    }

    for (int c = 0; c < cols; c++) {
      washCell(row, c);
    }
    for (int r = 0; r < rows; r++) {
      washCell(r, col);
    }
  }

  /// The four squares a swipe would stop on. Hollow, so a landing never reads
  /// as a wall or a collected gem.
  void _paintLandings(PuzzleCanvas canvas, InertiaState state) {
    final palette = canvas.palette;
    for (final direction in InertiaDirection.values) {
      final landing = const InertiaEngine()
          .landing(state.puzzle, state.position, direction);
      if (landing == null) continue;
      final rect = cellRect(landing ~/ cols, landing % cols);
      canvas.cell(
        rect.deflate(rect.width * 0.22),
        stroke: palette.primary.withValues(alpha: 0.45),
        strokeWidth: 1.2,
        radius: 3,
      );
    }
  }

  void _paintBall(PuzzleCanvas canvas, InertiaState state, int cell) {
    final palette = canvas.palette;
    final rect = cellRect(cell ~/ cols, cell % cols).deflate(0.006);
    final dead = state.position.exploded;
    final double radius = canvas.radiusFor(rect, 0.40);

    // A paper ring under the ball: on a wall cell the fill would otherwise be
    // the same near-black as the wall.
    canvas.ring(rect.center, radius + 1.6, color: palette.surface, width: 2.4);
    canvas.dot(
      rect.center,
      radius,
      color: dead ? palette.error : palette.primary,
    );
    if (dead) {
      canvas.ring(rect.center, radius + 2.6, color: palette.error, width: 2);
    }
  }

  @override
  void paintElement(
      PuzzleCanvas canvas, InertiaState state, ElementRef element) {
    // The engine lifts the element a drag started on, which for this game is a
    // *cell*. Drawing that cell would carry a square of the board around the
    // screen with the ball, which is exactly what a lifted copy must not do: the
    // thing being moved is the ball, so that is what follows the finger (and
    // what pops in the win cascade).
    if (isCell(element) &&
        element.a * cols + element.b == state.position.cell) {
      _paintBall(canvas, state, state.position.cell);
      return;
    }
    super.paintElement(canvas, state, element);
  }

  // -------------------------------------------------------------- transition

  @override
  Duration? transitionFor(InertiaState from, InertiaState to) {
    if (!identical(from.puzzle, to.puzzle)) return null;
    if (from.position.cell == to.position.cell &&
        from.position.exploded == to.position.exploded) {
      return null;
    }
    return const Duration(milliseconds: 280);
  }

  @override
  void paintTransition(
    PuzzleCanvas canvas,
    InertiaState from,
    InertiaState to,
    double t,
  ) {
    super.paint(canvas, to);

    final start =
        cellRect(from.position.cell ~/ cols, from.position.cell % cols).center;
    final end =
        cellRect(to.position.cell ~/ cols, to.position.cell % cols).center;
    final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final centre = Offset.lerp(start, end, eased)!;
    final palette = canvas.palette;
    final ball = cellRect(0, 0);
    final dead = to.position.exploded;

    canvas.ring(centre, canvas.radiusFor(ball, 0.40) + 1.6,
        color: palette.surface, width: 2.4);
    canvas.dot(
      centre,
      canvas.radiusFor(ball, 0.40),
      color: dead ? palette.error : palette.primary,
    );
    if (dead) {
      canvas.ring(centre, canvas.radiusFor(ball, 0.40) + 2.6,
          color: palette.error, width: 2);
    }
  }
}
