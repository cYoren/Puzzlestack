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
      fontSize: rect.height * 0.42,
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
      fontSize: rect.height * 0.42,
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
