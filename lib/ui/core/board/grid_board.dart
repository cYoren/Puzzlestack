import 'package:flutter/material.dart';

import 'puzzle_board.dart';

/// Shared geometry for puzzles that live on a rectangular grid.
///
/// Most of the puzzles in the app are a grid of cells with rules on top. The
/// arithmetic that turns a row and a column into a rectangle, and a touch into
/// a row and a column, is identical in all of them, so it lives here once.
/// A subclass supplies rules and paint; it never computes a rectangle by hand.
///
/// Everything is normalised, as the contract requires: [margin] and the cell
/// sizes are fractions of the board box, so the same board paints at 320dp and
/// on a tablet, and hit testing needs no layout pass.
abstract class GridBoard<S extends PuzzleState> extends PuzzleBoard<S> {
  int get rows;

  int get cols;

  /// Space kept clear around the grid, in normalised units. Puzzles with
  /// clues on the outer edge (edges, vertices) override this.
  double get margin => 0.02;

  /// Gap between neighbouring cells, as a fraction of one cell. Cells stay
  /// separate objects without the board reading as a tray of tiles.
  double get gapFraction => 0.06;

  static const String cellKind = 'cell';

  ElementRef cell(int row, int col) => ElementRef(cellKind, row, col);

  bool isCell(ElementRef element) => element.kind == cellKind;

  bool inBounds(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  /// Width and height of one cell, in normalised units.
  double get cellWidth => (1 - 2 * margin) / cols;

  double get cellHeight => (1 - 2 * margin) / rows;

  /// The full cell, gap included.
  Rect slotRect(int row, int col) => Rect.fromLTWH(
        margin + col * cellWidth,
        margin + row * cellHeight,
        cellWidth,
        cellHeight,
      );

  /// The drawable part of a cell, gap removed. This is what a puzzle paints
  /// and what the engine hit-tests.
  Rect cellRect(int row, int col) {
    final gapX = cellWidth * gapFraction / 2;
    final gapY = cellHeight * gapFraction / 2;
    return Rect.fromLTRB(
      margin + col * cellWidth + gapX,
      margin + row * cellHeight + gapY,
      margin + (col + 1) * cellWidth - gapX,
      margin + (row + 1) * cellHeight - gapY,
    );
  }

  Offset cellCenter(int row, int col) => cellRect(row, col).center;

  /// The cell a normalised point falls in, or null outside the grid.
  (int, int)? cellAt(Offset point) {
    final x = (point.dx - margin) / cellWidth;
    final y = (point.dy - margin) / cellHeight;
    if (x < 0 || y < 0 || x >= cols || y >= rows) return null;
    return (y.floor(), x.floor());
  }

  List<ElementRef> get cells => [
        for (var row = 0; row < rows; row++)
          for (var col = 0; col < cols; col++) cell(row, col),
      ];

  @override
  List<ElementRef> get elements => cells;

  @override
  Rect? boundsOf(ElementRef element) =>
      isCell(element) ? cellRect(element.a, element.b) : null;

  @override
  double get aspectRatio => rows / cols;

  /// Paints the board bed and every cell that [paintCell] does not handle.
  ///
  /// A puzzle that only draws inside cells can leave [paint] alone and
  /// implement [paintCell]; one that draws lines or vertices overrides
  /// [paint] instead.
  void paintCell(PuzzleCanvas canvas, S state, int row, int col) {}

  @override
  void paint(PuzzleCanvas canvas, S state) {
    canvas.bed();
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final element = cell(row, col);
        if (canvas.isHidden(element)) continue;
        paintCell(canvas, state, row, col);
      }
    }
  }

  @override
  void paintElement(PuzzleCanvas canvas, S state, ElementRef element) {
    if (isCell(element)) {
      paintCell(canvas, state, element.a, element.b);
    }
  }
}
