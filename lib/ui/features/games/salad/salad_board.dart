import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import '../../../core/board/puzzle_marks.dart';
import 'salad_provider.dart';
import 'salad_puzzle.dart';

/// Salad on the board contract.
///
/// The grid is a Latin square with holes in it, so the cells sit flush and the
/// lines are hairlines. A letter is a letter; a hole is a small solid square,
/// because a hole is a *value* the player writes and the answer contains, not a
/// cell waiting to be filled — and the house cross would say "ruled out", which
/// is the opposite. A cell with nothing written stays empty.
///
/// The four clues of each line live in the margin strip, where they belong: a
/// clue outside the grid is what makes it a border clue, and drawing one inside
/// a cell would mean something else entirely.
class SaladBoard extends GridBoard<SaladState> {
  SaladBoard({required this.state});

  @override
  final SaladState state;

  @override
  int get rows => state.n;

  @override
  int get cols => state.n;

  @override
  bool get isSolved => state.isSolved;

  /// The clues straddle the grid's edge, so the cells must touch.
  @override
  double get gapFraction => 0;

  /// Room for one clue band on each side.
  @override
  double get margin => 0.11;

  late final Set<int> _conflicts = state.conflicts;

  @override
  List<PuzzleMove<SaladState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<SaladState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    return PuzzleMove<SaladState>(
      kind: MoveKind.select,
      source: element,
      apply: (current) => current,
    );
  }

  /// Where one clue sits: a band in the margin, centred on its line.
  Rect clueRect(SaladClueDir dir, int index) {
    final across = margin +
        (index + 0.5) * (SaladPuzzle.isRow(dir) ? cellHeight : cellWidth);
    final band = margin * 0.92;
    return switch (dir) {
      SaladClueDir.top => Rect.fromCenter(
          center: Offset(across, margin * 0.5),
          width: cellWidth,
          height: band,
        ),
      SaladClueDir.bottom => Rect.fromCenter(
          center: Offset(across, 1 - margin * 0.5),
          width: cellWidth,
          height: band,
        ),
      SaladClueDir.left => Rect.fromCenter(
          center: Offset(margin * 0.5, across),
          width: band,
          height: cellHeight,
        ),
      SaladClueDir.right => Rect.fromCenter(
          center: Offset(1 - margin * 0.5, across),
          width: band,
          height: cellHeight,
        ),
    };
  }

  @override
  void paintCell(PuzzleCanvas canvas, SaladState state, int row, int col) {
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
    if (value == kSaladHole) {
      // A hole is an answer, not a blank: it gets a mark of its own.
      PuzzleMarks(canvas).block(
        rect,
        role: conflict ? MarkRole.error : MarkRole.structure,
        inset: 0.36,
      );
    } else if (value > kSaladHole) {
      PuzzleMarks(canvas).label(
        rect,
        saladLetter(value),
        role: conflict ? MarkRole.error : MarkRole.primary,
        fraction: 0.42,
        weight: FontWeight.w800,
      );
    }

    if (state.hintCell == cell) PuzzleMarks(canvas).hint(rect);
    if (state.selected == cell) {
      canvas.cell(rect, stroke: palette.primary, strokeWidth: 2.5, radius: 0);
    }
  }

  @override
  void paint(PuzzleCanvas canvas, SaladState state) {
    super.paint(canvas, state);

    final palette = canvas.palette;
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

    final outer = Rect.fromLTWH(margin, margin, 1 - 2 * margin, 1 - 2 * margin);
    canvas.cell(outer, stroke: palette.structure, strokeWidth: 2.0, radius: 3);

    // The four clues of the line under the finger read as the live ones, so the
    // player can see which of the border letters belong to the cell they are
    // working.
    final selected = state.selected;
    final live = <int>{};
    if (selected != null) {
      final row = selected ~/ cols;
      final col = selected % cols;
      live.addAll([
        SaladClueDir.top.index * rows + col,
        SaladClueDir.bottom.index * rows + col,
        SaladClueDir.left.index * cols + row,
        SaladClueDir.right.index * cols + row,
      ]);
    }

    for (final dir in SaladClueDir.values) {
      for (var index = 0; index < rows; index++) {
        final clue = state.puzzle.clue(dir, index);
        if (clue == kSaladNoClue) continue;
        PuzzleMarks(canvas).label(
          clueRect(dir, index),
          saladLetter(clue),
          role: live.contains(dir.index * rows + index)
              ? MarkRole.primary
              : MarkRole.muted,
          fraction: 0.52,
          weight: FontWeight.w800,
        );
      }
    }
  }
}
