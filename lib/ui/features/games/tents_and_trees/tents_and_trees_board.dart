import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'tents_and_trees_provider.dart';

/// Tents & Trees on the board contract.
///
/// A tree is a filled wedge, a tent is the same wedge in the accent colour and
/// upside down, so the two read apart at 320dp without a legend.
class TentsBoard extends GridBoard<TentsState> {
  TentsBoard({required this.state});

  @override
  final TentsState state;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  @override
  bool get isSolved => state.isSolved;

  /// Room for the row and column counts.
  @override
  double get margin => 0.15;

  @override
  List<PuzzleMove<TentsState>> movesFor(ElementRef element) {
    if (!isCell(element) || state.isSolved) return const [];
    final cell = element.a * cols + element.b;
    if (state.puzzle.isTree(cell)) return const [];
    return [
      PuzzleMove<TentsState>(
        kind: MoveKind.place,
        source: element,
        apply: (current) {
          final tents = [...current.tents];
          if (!tents.remove(cell)) tents.add(cell);
          return current.copyWith(tents: tents, isSolved: false);
        },
      ),
    ];
  }

  @override
  PuzzleMove<TentsState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    final cell = element.a * cols + element.b;
    if (state.puzzle.isTree(cell)) return null;
    return PuzzleMove<TentsState>(
      kind: MoveKind.place,
      source: element,
      apply: (current) {
        final tents = [...current.tents];
        if (!tents.remove(cell)) tents.add(cell);
        return current.copyWith(tents: tents, isSolved: false);
      },
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, TentsState state, int row, int col) {
    final cell = row * cols + col;
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final isTree = state.puzzle.isTree(cell);
    final isTent = state.tents.contains(cell);
    final hinted = state.hintCell == cell;

    canvas.cell(
      rect,
      fill: isTree
          ? palette.success.withValues(alpha: 0.14)
          : isTent
              ? palette.primary.withValues(alpha: 0.16)
              : palette.surface,
      stroke: hinted
          ? palette.error
          : palette.outline.withValues(alpha: 0.22),
      strokeWidth: hinted ? 2.5 : 1,
    );

    if (!isTree && !isTent) return;

    // A wedge: point up for a tree, point down for a tent.
    final centre = rect.center;
    final half = rect.width * 0.3;
    final height = rect.height * 0.34;
    final path = Path();
    if (isTree) {
      path
        ..moveTo(centre.dx, centre.dy - height)
        ..lineTo(centre.dx - half, centre.dy + height)
        ..lineTo(centre.dx + half, centre.dy + height);
    } else {
      path
        ..moveTo(centre.dx, centre.dy + height)
        ..lineTo(centre.dx - half, centre.dy - height)
        ..lineTo(centre.dx + half, centre.dy - height);
    }
    path.close();
    // `rect` is already normalised, and so is `path`.
    canvas.path(path, fill: isTree ? palette.success : palette.primary);
  }

  @override
  void paint(PuzzleCanvas canvas, TentsState state) {
    super.paint(canvas, state);
    final palette = canvas.palette;
    final fontSize = canvas.size.height * cellHeight * 0.4;

    for (var r = 0; r < rows; r++) {
      final rect = cellRect(r, 0);
      canvas.text(
        '${state.puzzle.rowCounts[r]}',
        Rect.fromCenter(
          center: Offset(rect.left - rect.width * 0.55, rect.center.dy),
          width: rect.width,
          height: rect.height,
        ),
        color: palette.muted,
        fontSize: fontSize,
        weight: FontWeight.w900,
      );
    }

    for (var c = 0; c < cols; c++) {
      final rect = cellRect(0, c);
      canvas.text(
        '${state.puzzle.colCounts[c]}',
        Rect.fromCenter(
          center: Offset(rect.center.dx, rect.top - rect.height * 0.55),
          width: rect.width,
          height: rect.height,
        ),
        color: palette.muted,
        fontSize: fontSize,
        weight: FontWeight.w900,
      );
    }
  }
}
