import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import '../../../core/board/puzzle_marks.dart';
import 'ascent_engine.dart';
import 'ascent_provider.dart';

/// Number Path on the board contract.
///
/// A path is the whole point, so the cells sit flush and the numbers are the
/// only marks: a printed number is ink, one the player wrote is the live
/// colour, and a number that breaks the path turns red. The board draws no
/// connecting lines of its own — the path is in the numbers, and drawing it
/// for the player is the game playing itself.
class AscentBoard extends GridBoard<AscentState> {
  AscentBoard({required this.state});

  @override
  final AscentState state;

  @override
  int get rows => state.n;

  @override
  int get cols => state.n;

  @override
  bool get isSolved => state.isSolved;

  @override
  double get gapFraction => 0;

  @override
  double get margin => 0.03;

  late final Set<int> _conflicts = state.conflicts;

  @override
  List<PuzzleMove<AscentState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<AscentState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    return PuzzleMove<AscentState>(
      kind: MoveKind.place,
      source: element,
      apply: (current) => current,
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, AscentState state, int row, int col) {
    final cell = row * cols + col;
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final conflict = _conflicts.contains(cell);
    final given = state.isGiven(cell);

    canvas.cell(
      rect,
      fill: conflict
          ? palette.error.withValues(alpha: 0.12)
          : given
              ? palette.ink.withValues(alpha: 0.06)
              : palette.surface,
      radius: 0,
    );

    final value = state.values[cell];
    if (value != kAscentBlank) {
      PuzzleMarks(canvas).label(
        rect,
        '$value',
        role: conflict
            ? MarkRole.error
            : given
                ? MarkRole.ink
                : MarkRole.primary,
        // Two-digit numbers need to be a little smaller to fit the cell.
        fraction: value > 9 ? (given ? 0.42 : 0.38) : (given ? 0.5 : 0.44),
        weight: given ? FontWeight.w900 : FontWeight.w700,
      );
    }

    if (state.hintCell == cell) PuzzleMarks(canvas).hint(rect);
  }

  @override
  void paint(PuzzleCanvas canvas, AscentState state) {
    super.paint(canvas, state);
    final palette = canvas.palette;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final rect = slotRect(row, col);
        if (col + 1 < cols) {
          canvas.line(
            Offset(rect.right, rect.top),
            Offset(rect.right, rect.bottom),
            color: palette.line.withValues(alpha: 0.6),
            width: 1.0,
            cap: StrokeCap.butt,
          );
        }
        if (row + 1 < rows) {
          canvas.line(
            Offset(rect.left, rect.bottom),
            Offset(rect.right, rect.bottom),
            color: palette.line.withValues(alpha: 0.6),
            width: 1.0,
            cap: StrokeCap.butt,
          );
        }
      }
    }
    final outer = Rect.fromLTWH(margin, margin, 1 - 2 * margin, 1 - 2 * margin);
    canvas.cell(outer, stroke: palette.structure, strokeWidth: 3.0, radius: 4);
  }
}
