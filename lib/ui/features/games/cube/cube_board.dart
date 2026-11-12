import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'cube_engine.dart';
import 'cube_provider.dart';

/// Cube on the board contract.
///
/// The grid is the table; the cube is one object on it. Drag the cube onto a
/// neighbouring square to roll it, or tap a neighbour: both are the same move,
/// so a tap-only player can finish a board.
class CubeBoard extends GridBoard<CubeState> {
  CubeBoard({required this.state});

  @override
  final CubeState state;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  @override
  bool get isSolved => state.isSolved;

  @override
  double get gapFraction => 0.1;

  int get _cubeCell => state.position.cell;

  CubeDirection? _directionTo(int from, int to) {
    if (to == from - cols) return CubeDirection.north;
    if (to == from + cols) return CubeDirection.south;
    if (to == from + 1 && to ~/ cols == from ~/ cols) return CubeDirection.east;
    if (to == from - 1 && to ~/ cols == from ~/ cols) return CubeDirection.west;
    return null;
  }

  PuzzleMove<CubeState> _rollMove(ElementRef from, int to, CubeDirection direction) {
    return PuzzleMove<CubeState>(
      kind: MoveKind.place,
      source: from,
      target: cell(to ~/ cols, to % cols),
      apply: (current) => current.copyWith(
        position: const CubeEngine().roll(current.puzzle, current.position, direction),
        moves: current.moves + 1,
        clearHint: true,
      ),
    );
  }

  @override
  List<PuzzleMove<CubeState>> movesFor(ElementRef element) {
    if (!isCell(element) || state.isSolved) return const [];
    final index = element.a * cols + element.b;
    if (index != _cubeCell) return const [];

    return [
      for (final direction in CubeDirection.values)
        if (_neighbour(_cubeCell, direction) case final to?)
          _rollMove(element, to, direction),
    ];
  }

  int? _neighbour(int cell, CubeDirection direction) {
    final row = cell ~/ cols;
    final col = cell % cols;
    final to = switch (direction) {
      CubeDirection.north => row > 0 ? cell - cols : -1,
      CubeDirection.south => row + 1 < rows ? cell + cols : -1,
      CubeDirection.east => col + 1 < cols ? cell + 1 : -1,
      CubeDirection.west => col > 0 ? cell - 1 : -1,
    };
    return to < 0 ? null : to;
  }

  @override
  PuzzleMove<CubeState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    final index = element.a * cols + element.b;
    if (index == _cubeCell) return null;
    final direction = _directionTo(_cubeCell, index);
    if (direction == null) return null;
    return _rollMove(cell(_cubeCell ~/ cols, _cubeCell % cols), index, direction);
  }

  @override
  void paintCell(PuzzleCanvas canvas, CubeState state, int row, int col) {
    final index = row * cols + col;
    final rect = cellRect(row, col);
    final palette = canvas.palette;

    final painted = state.position.squares[index] == 1;
    final target = state.puzzle.isTarget(index);

    // Three states, three shapes: a blue square is a target, a solid ink square
    // has been painted, empty is paper. A tint on a tint was why the board read
    // as one blue wash.
    canvas.cell(
      rect,
      fill: target ? palette.primary : palette.surface,
      stroke: painted ? palette.ink : palette.line,
      strokeWidth: painted ? 3 : 1.2,
    );
    if (target && !painted) {
      canvas.dot(rect.center, rect.width * 0.16, color: palette.surface);
    }
    if (painted) {
      canvas.cell(
        rect.deflate(rect.width * 0.18),
        stroke: palette.ink,
        strokeWidth: 2,
      );
    }
  }

  @override
  void paint(PuzzleCanvas canvas, CubeState state) {
    super.paint(canvas, state);
    final palette = canvas.palette;
    final row = _cubeCell ~/ cols;
    final col = _cubeCell % cols;
    final rect = cellRect(row, col).deflate(0.004);

    // An isometric cube: a top diamond and two side faces. The viewer is to the
    // south-west, so the visible sides are south and west.
    final centre = rect.center;
    final halfW = rect.width * 0.46;
    final halfH = rect.height * 0.26;
    final tall = rect.height * 0.30;

    final top = Path()
      ..moveTo(centre.dx, centre.dy - halfH - tall)
      ..lineTo(centre.dx + halfW, centre.dy - tall)
      ..lineTo(centre.dx, centre.dy + halfH - tall)
      ..lineTo(centre.dx - halfW, centre.dy - tall)
      ..close();

    final left = Path()
      ..moveTo(centre.dx - halfW, centre.dy - tall)
      ..lineTo(centre.dx, centre.dy + halfH - tall)
      ..lineTo(centre.dx, centre.dy + halfH)
      ..lineTo(centre.dx - halfW, centre.dy)
      ..close();

    final right = Path()
      ..moveTo(centre.dx + halfW, centre.dy - tall)
      ..lineTo(centre.dx, centre.dy + halfH - tall)
      ..lineTo(centre.dx, centre.dy + halfH)
      ..lineTo(centre.dx + halfW, centre.dy)
      ..close();

    Color shade(int face, double lit) {
      final blue = state.position.faces[face] == 1;
      return blue
          ? palette.primary.withValues(alpha: lit)
          : Color.lerp(palette.surface, palette.ink, 0.08)!
              .withValues(alpha: 1.0);
    }

    final edge = palette.ink.withValues(alpha: 0.75);
    canvas.path(left, fill: shade(CubeFace.south, 0.72), stroke: edge, width: 1.6);
    canvas.path(right, fill: shade(CubeFace.west, 0.85), stroke: edge, width: 1.6);
    canvas.path(top, fill: shade(CubeFace.top, 1.0), stroke: edge, width: 1.6);

    // The bottom face is the one a roll swaps and the answer hangs on, and it
    // is the face an isometric view cannot show. Paint it as the cube's shadow.
    final bottom = state.position.faces[CubeFace.bottom] == 1;
    canvas.cell(
      Rect.fromCenter(
        center: Offset(centre.dx, centre.dy + halfH),
        width: halfW * 0.5,
        height: halfH * 0.5,
      ),
      fill: bottom ? palette.primary : palette.surface,
      stroke: edge,
      strokeWidth: 1.4,
      radius: 4,
    );

    // How many faces are painted, on the cube itself: it belongs to the object,
    // not to a HUD chip.
    canvas.text(
      '${state.position.paintedFaces}/6',
      Rect.fromCenter(
        center: Offset(centre.dx, centre.dy + halfH + tall * 0.62),
        width: rect.width,
        height: rect.height * 0.3,
      ),
      color: palette.ink.withValues(alpha: 0.75),
      fontSize: canvas.size.height * cellHeight * 0.26,
      weight: FontWeight.w900,
    );
  }
}
