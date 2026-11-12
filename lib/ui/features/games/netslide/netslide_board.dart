import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'netslide_engine.dart';
import 'netslide_provider.dart';

/// Netslide on the board contract.
///
/// A cell is drawn as the pipes it holds, so the board reads as a net rather than
/// a grid of symbols. The tap controls are the point: each row has a ⏴ and a ⏵
/// in the gutter and each column has a ⏶ and a ⏷, so "tap a cell and hope" is
/// gone. A control that cannot move — a wall blocks the line — is drawn faint
/// and does nothing. Dragging a cell along its row still works.
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

  /// Room for the tap controls around the grid.
  @override
  double get margin => 0.13;

  static const String rowKind = 'rowSlide';
  static const String colKind = 'colSlide';

  /// `b` is 1 for the positive direction (east/south) and 0 for the negative.
  ElementRef rowSlide(int row, bool east) => ElementRef(rowKind, row, east ? 1 : 0);

  ElementRef colSlide(int col, bool south) =>
      ElementRef(colKind, col, south ? 1 : 0);

  @override
  List<ElementRef> get elements => [
        ...cells,
        for (var row = 0; row < rows; row++) ...[
          rowSlide(row, false),
          rowSlide(row, true),
        ],
        for (var col = 0; col < cols; col++) ...[
          colSlide(col, false),
          colSlide(col, true),
        ],
      ];

  bool _canSlide({required bool row, required int index, required bool forward}) =>
      const NetEngine().slide(
        state.puzzle,
        state.masks,
        row: row,
        index: index,
        forward: forward,
      ) !=
      null;

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
  Rect? boundsOf(ElementRef element) {
    if (isCell(element)) return cellRect(element.a, element.b);
    if (element.kind == rowKind) {
      final east = element.b == 1;
      final width = margin * 0.72;
      return Rect.fromLTWH(
        east ? 1 - margin * 0.86 : margin * 0.14,
        margin + element.a * cellHeight + cellHeight * 0.22,
        width,
        cellHeight * 0.56,
      );
    }
    if (element.kind == colKind) {
      final south = element.b == 1;
      final height = margin * 0.72;
      return Rect.fromLTWH(
        margin + element.a * cellWidth + cellWidth * 0.22,
        south ? 1 - margin * 0.86 : margin * 0.14,
        cellWidth * 0.56,
        height,
      );
    }
    return null;
  }

  @override
  List<PuzzleMove<NetState>> movesFor(ElementRef element) {
    if (!isCell(element)) return const [];
    final row = element.a;
    final col = element.b;
    final moves = <PuzzleMove<NetState>>[];
    for (final forward in [true, false]) {
      final target = forward ? col + 1 : col - 1;
      if (target < 0 || target >= cols) continue;
      if (!_canSlide(row: true, index: row, forward: forward)) continue;
      moves.add(_slideMove(element, row: true, index: row, forward: forward));
    }
    for (final forward in [true, false]) {
      final target = forward ? row + 1 : row - 1;
      if (target < 0 || target >= rows) continue;
      if (!_canSlide(row: false, index: col, forward: forward)) continue;
      moves.add(_slideMove(element, row: false, index: col, forward: forward));
    }
    return moves;
  }

  /// Taps belong to the controls. A cell tap used to push its row east, which
  /// was not a thing the player could see or predict.
  @override
  PuzzleMove<NetState>? tapMove(ElementRef element) {
    if (element.kind == rowKind) {
      if (!_canSlide(row: true, index: element.a, forward: element.b == 1)) {
        return null;
      }
      return _slideMove(
        element,
        row: true,
        index: element.a,
        forward: element.b == 1,
      );
    }
    if (element.kind == colKind) {
      if (!_canSlide(row: false, index: element.a, forward: element.b == 1)) {
        return null;
      }
      return _slideMove(
        element,
        row: false,
        index: element.a,
        forward: element.b == 1,
      );
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
      stroke: palette.line,
      strokeWidth: 1,
    );

    final wire = palette.structure;
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
    canvas.dot(centre, rect.width * 0.08, color: wire);
  }

  @override
  void paint(PuzzleCanvas canvas, NetState state) {
    super.paint(canvas, state);
    final palette = canvas.palette;

    // Walls between cells: they are the reason a line cannot slide, so they
    // have to be visible.
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final rect = cellRect(row, col);
        if (state.puzzle.hasWall(row * cols + col, NetDirection.east)) {
          canvas.line(
            rect.topRight,
            rect.bottomRight,
            color: palette.ink,
            width: 2.5,
          );
        }
        if (state.puzzle.hasWall(row * cols + col, NetDirection.south)) {
          canvas.line(
            rect.bottomLeft,
            rect.bottomRight,
            color: palette.ink,
            width: 2.5,
          );
        }
      }
    }

    for (var row = 0; row < rows; row++) {
      _paintControl(
        canvas,
        rowSlide(row, false),
        east: false,
        enabled: _canSlide(row: true, index: row, forward: false),
      );
      _paintControl(
        canvas,
        rowSlide(row, true),
        east: true,
        enabled: _canSlide(row: true, index: row, forward: true),
      );
    }
    for (var col = 0; col < cols; col++) {
      _paintControl(
        canvas,
        colSlide(col, false),
        south: false,
        enabled: _canSlide(row: false, index: col, forward: false),
      );
      _paintControl(
        canvas,
        colSlide(col, true),
        south: true,
        enabled: _canSlide(row: false, index: col, forward: true),
      );
    }
  }

  void _paintControl(
    PuzzleCanvas canvas,
    ElementRef element, {
    bool east = false,
    bool south = false,
    required bool enabled,
  }) {
    final bounds = boundsOf(element);
    if (bounds == null) return;
    final palette = canvas.palette;
    final colour = enabled
        ? palette.ink.withValues(alpha: 0.75)
        : palette.ink.withValues(alpha: 0.16);
    final centre = bounds.center;
    final w = bounds.width * 0.35;
    final h = bounds.height * 0.35;

    final path = Path();
    if (element.kind == rowKind) {
      final sign = east ? 1.0 : -1.0;
      path
        ..moveTo(centre.dx + sign * w, centre.dy)
        ..lineTo(centre.dx - sign * w, centre.dy - h * 1.4)
        ..lineTo(centre.dx - sign * w, centre.dy + h * 1.4)
        ..close();
    } else {
      final sign = south ? 1.0 : -1.0;
      path
        ..moveTo(centre.dx, centre.dy + sign * h)
        ..lineTo(centre.dx - w * 1.4, centre.dy - sign * h)
        ..lineTo(centre.dx + w * 1.4, centre.dy - sign * h)
        ..close();
    }
    canvas.path(path, fill: colour);
  }

  @override
  void paintElement(
    PuzzleCanvas canvas,
    NetState state,
    ElementRef element,
  ) {
    if (isCell(element)) {
      paintCell(canvas, state, element.a, element.b);
      return;
    }
    if (element.kind == rowKind) {
      _paintControl(
        canvas,
        element,
        east: element.b == 1,
        enabled: _canSlide(row: true, index: element.a, forward: element.b == 1),
      );
      return;
    }
    if (element.kind == colKind) {
      _paintControl(
        canvas,
        element,
        south: element.b == 1,
        enabled:
            _canSlide(row: false, index: element.a, forward: element.b == 1),
      );
    }
  }
}
