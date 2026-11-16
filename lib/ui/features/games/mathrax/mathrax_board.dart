import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import '../../../core/board/puzzle_marks.dart';
import 'mathrax_provider.dart';
import 'mathrax_puzzle.dart';

/// Mathrax on the board contract.
///
/// The board is a Latin square with its clues on the corners, so the cells sit
/// flush, the lines are hairlines, and every corner clue is a small plate that
/// covers the crossing so the number reads over two lines at once. A clue is
/// never drawn inside a cell: where it sits *is* its meaning.
class MathraxBoard extends GridBoard<MathraxState> {
  MathraxBoard({required this.state});

  @override
  final MathraxState state;

  @override
  int get rows => state.n;

  @override
  int get cols => state.n;

  @override
  bool get isSolved => state.isSolved;

  /// The clue plates straddle the lines, so the cells must touch.
  @override
  double get gapFraction => 0;

  @override
  double get margin => 0.045;

  late final Set<int> _conflicts = state.conflicts;

  @override
  List<PuzzleMove<MathraxState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<MathraxState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    return PuzzleMove<MathraxState>(
      kind: MoveKind.select,
      source: element,
      apply: (current) => current,
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, MathraxState state, int row, int col) {
    final cell = row * cols + col;
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final conflict = _conflicts.contains(cell);

    canvas.cell(
      rect,
      fill: conflict ? palette.error.withValues(alpha: 0.12) : palette.surface,
      radius: 0,
    );

    final value = state.values[cell];
    if (value != kMathraxBlank) {
      PuzzleMarks(canvas).label(
        rect,
        '$value',
        role: conflict ? MarkRole.error : MarkRole.primary,
        fraction: 0.42,
        weight: FontWeight.w700,
      );
    }

    if (state.hintCell == cell) PuzzleMarks(canvas).hint(rect);
    if (state.selected == cell) {
      canvas.cell(rect, stroke: palette.primary, strokeWidth: 2.5, radius: 0);
    }
  }

  @override
  void paint(PuzzleCanvas canvas, MathraxState state) {
    super.paint(canvas, state);

    final palette = canvas.palette;
    // The frame first, then the plates on top of every line.
    final outer = Rect.fromLTWH(margin, margin, 1 - 2 * margin, 1 - 2 * margin);
    canvas.cell(outer, stroke: palette.structure, strokeWidth: 2.0, radius: 3);

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final rect = slotRect(row, col);
        if (col + 1 < cols) {
          canvas.line(
            Offset(rect.right, rect.top),
            Offset(rect.right, rect.bottom),
            color: palette.line,
            width: 1.0,
            cap: StrokeCap.butt,
          );
        }
        if (row + 1 < rows) {
          canvas.line(
            Offset(rect.left, rect.bottom),
            Offset(rect.right, rect.bottom),
            color: palette.line,
            width: 1.0,
            cap: StrokeCap.butt,
          );
        }
      }
    }

    // Every clue, on the corner it belongs to: the point shared by the four
    // cells it constrains.
    for (var row = 0; row < rows - 1; row++) {
      for (var col = 0; col < cols - 1; col++) {
        final clue = state.puzzle.clueAt(row, col);
        if (clue == null) continue;
        final corner = cellRect(row, col).bottomRight;
        final width = cellRect(0, 0).width * 0.46;
        final plate = Rect.fromCenter(
          center: corner,
          width: width,
          height: width * 0.82,
        );
        canvas.cell(
          plate,
          fill: palette.bed,
          stroke: palette.line,
          strokeWidth: 1.0,
          radius: width * 0.28,
        );
        PuzzleMarks(canvas).label(
          plate,
          clue.label,
          role: MarkRole.muted,
          fraction: 0.62,
          weight: FontWeight.w700,
        );
      }
    }
  }
}
