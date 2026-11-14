import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'twiddle_engine.dart';
import 'twiddle_provider.dart';

/// Twiddle on the board contract.
///
/// A turn is expressed as a drag: pick up a tile and drop it where the turn
/// would put it, and the block turns. Dragging a tile onto its neighbour is a
/// quarter turn of the block they share, which is the gesture the puzzle
/// wants. Tap turns the block around the tile clockwise.
class TwiddleBoard extends GridBoard<TwiddleState> {
  TwiddleBoard({required this.state, this.engine = const TwiddleEngine()});

  @override
  final TwiddleState state;

  final TwiddleEngine engine;

  @override
  int get rows => state.size;

  @override
  int get cols => state.size;

  @override
  bool get isSolved => state.isSolved;

  @override
  double get gapFraction => 0.08;

  int _tileAt(int row, int col) => state.grid[row * cols + col];

  bool _isCorrect(int row, int col) => _tileAt(row, col) == row * cols + col + 1;

  // ------------------------------------------------------------------- rules

  TwiddleState _turn(TwiddleState current, TwiddleMove move) {
    final grid = engine.apply(current.grid, cols, move, state.block);
    return current.copyWith(
      grid: grid,
      clearHint: true,
      isSolved: engine.isSolved(grid),
      lastMove: move,
    );
  }

  @override
  List<PuzzleMove<TwiddleState>> movesFor(ElementRef element) {
    if (!isCell(element)) return const [];
    final row = element.a;
    final col = element.b;

    final moves = <PuzzleMove<TwiddleState>>[];
    for (final move in engine.turnsForTile(cols, state.block, row, col)) {
      final (toRow, toCol) = engine.destinationOf(row, col, move, state.block);
      moves.add(
        PuzzleMove<TwiddleState>(
          kind: MoveKind.place,
          source: element,
          target: cell(toRow, toCol),
          apply: (current) => _turn(current, move),
        ),
      );
    }
    return moves;
  }

  @override
  PuzzleMove<TwiddleState>? tapMove(ElementRef element) {
    if (!isCell(element)) return null;
    final move = engine.tapTurn(cols, state.block, element.a, element.b);
    if (move == null) return null;
    return PuzzleMove<TwiddleState>(
      kind: MoveKind.place,
      source: element,
      apply: (current) => _turn(current, move),
    );
  }

  // ------------------------------------------------------------------- paint

  @override
  void paint(PuzzleCanvas canvas, TwiddleState state) {
    canvas.bed();

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final element = cell(row, col);
        if (canvas.isHidden(element)) continue;
        paintCell(canvas, state, row, col);
      }
    }

    final hint = state.hint;
    if (hint != null) {
      _paintBlockOutline(canvas, hint.row, hint.col, canvas.palette.success);
    }

    // While a tile is being dragged, outline the block that would turn, so the
    // gesture is "this block rotates" rather than a mystery about which of the
    // four blocks containing the tile is live.
    final hover = canvas.highlight.hover;
    if (hover != null) {
      final (row, col) = engine
          .blocksContaining(rows, state.block, hover.a, hover.b)
          .reduce((a, b) {
        final da = _centreDistance(a, hover.a, hover.b);
        final db = _centreDistance(b, hover.a, hover.b);
        return da <= db ? a : b;
      });
      _paintBlockOutline(
        canvas,
        row,
        col,
        canvas.palette.primary.withValues(alpha: 0.55),
      );
    }
  }

  double _centreDistance((int, int) corner, int row, int col) {
    final centreRow = corner.$1 + (state.block - 1) / 2;
    final centreCol = corner.$2 + (state.block - 1) / 2;
    return (centreRow - row).abs() + (centreCol - col).abs();
  }

  // -------------------------------------------------------------- transition

  @override
  Duration? transitionFor(TwiddleState from, TwiddleState to) {
    final move = to.lastMove;
    if (move == null) return null;
    if (!identical(from.puzzle, to.puzzle)) return null;
    // A hint or a selection keeps `lastMove`; only a changed grid is a turn.
    if (listEquals(from.grid, to.grid)) return null;
    if (move.row < 0 ||
        move.col < 0 ||
        move.row + state.block > state.size ||
        move.col + state.block > state.size) {
      return null;
    }
    return const Duration(milliseconds: 240);
  }

  @override
  void paintTransition(
    PuzzleCanvas canvas,
    TwiddleState from,
    TwiddleState to,
    double t,
  ) {
    final move = to.lastMove;
    if (move == null) {
      paint(canvas, to);
      return;
    }

    final eased = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
    // In canvas coordinates (y down) the engine's clockwise turn is a negative
    // angle. Rotating the old block by this much lands exactly on the new grid.
    final angle = (move.clockwise ? -1 : 1) * (math.pi / 2) * eased;

    canvas.bed();
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final inBlock = row >= move.row &&
            row < move.row + state.block &&
            col >= move.col &&
            col < move.col + state.block;
        if (inBlock) continue;
        paintCell(canvas, to, row, col);
      }
    }

    final topLeft = cellRect(move.row, move.col);
    final bottomRight = cellRect(
      move.row + state.block - 1,
      move.col + state.block - 1,
    );
    final centre = Rect.fromPoints(topLeft.topLeft, bottomRight.bottomRight).center;

    canvas.pushRotation(centre, angle);
    for (var row = move.row; row < move.row + state.block; row++) {
      for (var col = move.col; col < move.col + state.block; col++) {
        paintCell(canvas, from, row, col);
      }
    }
    canvas.pop();
  }

  @override
  void paintCell(PuzzleCanvas canvas, TwiddleState state, int row, int col) {
    final palette = canvas.palette;
    final rect = cellRect(row, col);
    final correct = _isCorrect(row, col);
    final zone = canvas.highlight.targetAlpha(cell(row, col));

    canvas.cell(
      rect,
      fill: zone > 0
          ? palette.primary.withValues(alpha: 0.08 * zone * 2)
          : correct
              ? palette.primary.withValues(alpha: 0.10)
              : palette.surface,
      stroke: zone > 0
          ? palette.primary
          : palette.outline.withValues(alpha: 0.35),
      strokeWidth: zone > 0 ? 2.5 : 1.5,
    );

    canvas.text(
      '${_tileAt(row, col)}',
      rect,
      fontSize: canvas.fontSizeFor(rect, 0.42),
      weight: FontWeight.w800,
      color: correct ? palette.primary : palette.ink,
    );
  }

  @override
  void paintElement(
    PuzzleCanvas canvas,
    TwiddleState state,
    ElementRef element,
  ) {
    if (!isCell(element)) return;
    final rect = cellRect(element.a, element.b);
    canvas.cell(
      rect,
      fill: canvas.palette.surface,
      stroke: canvas.palette.primary,
      strokeWidth: 2.5,
    );
    canvas.text(
      '${_tileAt(element.a, element.b)}',
      rect,
      fontSize: canvas.fontSizeFor(rect, 0.42),
      weight: FontWeight.w800,
      color: canvas.palette.primary,
    );
  }

  void _paintBlockOutline(PuzzleCanvas canvas, int row, int col, Color color) {
    final topLeft = cellRect(row, col).topLeft;
    final bottomRight = cellRect(row + state.block - 1, col + state.block - 1)
        .bottomRight;
    final rect = Rect.fromPoints(topLeft, bottomRight).inflate(0.008);
    canvas.cell(rect, stroke: color, strokeWidth: 2.5, radius: 12);
  }
}
