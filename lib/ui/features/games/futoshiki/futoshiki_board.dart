import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'futoshiki_provider.dart';

/// Futoshiki on the board contract.
///
/// The inequalities live in the gaps between cells, which is why this board
/// asks for a wider gap than the default: a `<` needs room to be read at 320dp.
class FutoshikiBoard extends GridBoard<FutoshikiState> {
  FutoshikiBoard({required this.state});

  @override
  final FutoshikiState state;

  @override
  int get rows => state.n;

  @override
  int get cols => state.n;

  @override
  bool get isSolved => state.isSolved;

  @override
  double get gapFraction => 0.28;

  @override
  List<PuzzleMove<FutoshikiState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<FutoshikiState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    final index = element.a * cols + element.b;
    return PuzzleMove<FutoshikiState>(
      kind: MoveKind.select,
      source: element,
      apply: (current) => current.copyWith(selected: index, clearHint: true),
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, FutoshikiState state, int row, int col) {
    final index = row * cols + col;
    final value = state.values[index];
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final conflict = state.conflicts.contains(index);
    final selected = state.selected == index;
    final hint = state.hintCell == index;
    final given = state.isGiven(index);

    canvas.cell(
      rect,
      fill: conflict
          ? palette.error.withValues(alpha: 0.12)
          : given
              ? palette.ink.withValues(alpha: 0.06)
              : palette.surface,
      stroke: conflict
          ? palette.error
          : selected
              ? palette.primary
              : hint
                  ? palette.success
                  : palette.outline.withValues(alpha: 0.35),
      strokeWidth: conflict || selected || hint ? 2.5 : 1.5,
    );

    if (value != 0) {
      canvas.text(
        '$value',
        rect,
        color: conflict
            ? palette.error
            : given
                ? palette.ink
                : palette.primary,
        fontSize: canvas.fontSizeFor(rect, 0.5),
        weight: FontWeight.w900,
      );
    }
  }

  @override
  void paint(PuzzleCanvas canvas, FutoshikiState state) {
    super.paint(canvas, state);

    final n = state.n;
    final puzzle = state.puzzle;
    final palette = canvas.palette;
    final fontSize = canvas.size.height * cellHeight * 0.42;

    // Horizontal inequalities sit in the gap between two cells of a row.
    for (var row = 0; row < n; row++) {
      for (var col = 0; col + 1 < n; col++) {
        final edge = puzzle.horizontal[row * (n - 1) + col];
        if (edge == 0) continue;
        final left = cellRect(row, col);
        final right = cellRect(row, col + 1);
        final centre = Offset((left.right + right.left) / 2, left.center.dy);
        canvas.text(
          edge == 1 ? '<' : '>',
          Rect.fromCenter(
            center: centre,
            width: cellWidth * gapFraction,
            height: cellHeight,
          ),
          color: palette.ink.withValues(alpha: 0.8),
          fontSize: fontSize,
          weight: FontWeight.w900,
        );
      }
    }

    // Vertical inequalities sit in the gap between two rows.
    for (var row = 0; row + 1 < n; row++) {
      for (var col = 0; col < n; col++) {
        final edge = puzzle.vertical[row * n + col];
        if (edge == 0) continue;
        final top = cellRect(row, col);
        final bottom = cellRect(row + 1, col);
        final centre = Offset(top.center.dx, (top.bottom + bottom.top) / 2);
        canvas.text(
          edge == 1 ? '^' : 'v',
          Rect.fromCenter(
            center: centre,
            width: cellWidth,
            height: cellHeight * gapFraction,
          ),
          color: palette.ink.withValues(alpha: 0.8),
          fontSize: fontSize,
          weight: FontWeight.w900,
        );
      }
    }
  }
}
