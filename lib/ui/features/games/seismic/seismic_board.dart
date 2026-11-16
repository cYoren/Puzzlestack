import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import '../../../core/board/puzzle_marks.dart';
import 'seismic_engine.dart';
import 'seismic_provider.dart';

/// Seismic on the board contract.
///
/// The region borders are the puzzle's other half: a player has to see which
/// cells share a set of digits before a single clue means anything. So the
/// cells sit flush (no gap between them), every border is a hairline, and a
/// border between two regions is drawn heavy in the structure colour. Nothing
/// here invents a mark: the digits go through `PuzzleMarks.label`.
class SeismicBoard extends GridBoard<SeismicState> {
  SeismicBoard({required this.state});

  @override
  final SeismicState state;

  @override
  int get rows => state.n;

  @override
  int get cols => state.n;

  @override
  bool get isSolved => state.isSolved;

  /// The digit a player has written, or a given's number; a blank says nothing.
  @override
  String? valueOf(ElementRef element) {
    if (!isCell(element)) return null;
    final cell = element.a * cols + element.b;
    final value = state.values[cell];
    if (value != kSeismicBlank) return '$value';
    final given = state.puzzle.given(cell);
    return given == kSeismicNoClue ? null : '$given';
  }

  @override
  bool isFixed(ElementRef element) {
    if (!isCell(element)) return false;
    return state.puzzle.given(element.a * cols + element.b) != kSeismicNoClue;
  }

  /// The regions are the board, so the cells must touch.
  @override
  double get gapFraction => 0;

  @override
  double get margin => 0.03;

  late final Set<int> _conflicts = state.conflicts;

  int _region(int row, int col) => state.puzzle.regionOf(row * cols + col);

  @override
  List<PuzzleMove<SeismicState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<SeismicState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    return PuzzleMove<SeismicState>(
      kind: MoveKind.select,
      source: element,
      apply: (current) => current,
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, SeismicState state, int row, int col) {
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
    if (value != kSeismicBlank) {
      final given = state.puzzle.given(cell) != kSeismicNoClue;
      PuzzleMarks(canvas).label(
        rect,
        '$value',
        role: conflict
            ? MarkRole.error
            : given
                ? MarkRole.ink
                : MarkRole.primary,
        fraction: given ? 0.48 : 0.42,
        weight: given ? FontWeight.w900 : FontWeight.w700,
      );
    }

    if (state.hintCell == cell) PuzzleMarks(canvas).hint(rect);
    if (state.selected == cell) {
      canvas.cell(rect, stroke: palette.primary, strokeWidth: 2.5, radius: 0);
    }
  }

  @override
  void paint(PuzzleCanvas canvas, SeismicState state) {
    super.paint(canvas, state);

    final palette = canvas.palette;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final rect = slotRect(row, col);
        // The right and bottom edges, so a shared edge is drawn once.
        if (col + 1 < cols) {
          final same = _region(row, col) == _region(row, col + 1);
          canvas.line(
            Offset(rect.right, rect.top),
            Offset(rect.right, rect.bottom),
            color:
                same ? palette.line.withValues(alpha: 0.6) : palette.structure,
            width: same ? 1.0 : 3.0,
            cap: StrokeCap.butt,
          );
        }
        if (row + 1 < rows) {
          final same = _region(row, col) == _region(row + 1, col);
          canvas.line(
            Offset(rect.left, rect.bottom),
            Offset(rect.right, rect.bottom),
            color:
                same ? palette.line.withValues(alpha: 0.6) : palette.structure,
            width: same ? 1.0 : 3.0,
            cap: StrokeCap.butt,
          );
        }
      }
    }

    // The frame, so the board reads as one object and not as an open grid.
    final outer = Rect.fromLTWH(margin, margin, 1 - 2 * margin, 1 - 2 * margin);
    canvas.cell(outer, stroke: palette.structure, strokeWidth: 3.0, radius: 4);
  }
}
