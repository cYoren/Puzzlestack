import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'skyscrapers_provider.dart';

/// Skyscrapers on the board contract.
///
/// Tap a cell to select it, then a height from the pad. The clues live in the
/// margin around the grid, which is why [margin] is wider here than in a puzzle
/// whose board fills its box.
class SkyscrapersBoard extends GridBoard<SkyscrapersState> {
  SkyscrapersBoard({required this.state});

  @override
  final SkyscrapersState state;

  @override
  int get rows => state.n;

  @override
  int get cols => state.n;

  @override
  bool get isSolved => state.isSolved;

  /// Room for the clue ring.
  @override
  double get margin => 0.13;

  @override
  List<PuzzleMove<SkyscrapersState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<SkyscrapersState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    final index = element.a * cols + element.b;
    return PuzzleMove<SkyscrapersState>(
      kind: MoveKind.select,
      source: element,
      apply: (current) => current.copyWith(selected: index, clearHint: true),
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, SkyscrapersState state, int row, int col) {
    final index = row * cols + col;
    final value = state.values[index];
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final conflict = state.conflicts.contains(index);
    final selected = state.selected == index;
    final hint = state.hintCell == index;

    canvas.cell(
      rect,
      fill: conflict
          ? palette.error.withValues(alpha: 0.12)
          : value == 0
              ? palette.surface
              : palette.primary.withValues(alpha: 0.10),
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
        color: conflict ? palette.error : palette.ink,
        fontSize: canvas.fontSizeFor(rect, 0.5),
        weight: FontWeight.w900,
      );
    }
  }

  @override
  void paint(PuzzleCanvas canvas, SkyscrapersState state) {
    super.paint(canvas, state);

    final n = state.n;
    final puzzle = state.puzzle;
    final size = math.min(cellWidth, cellHeight);
    final fontSize = canvas.size.height * size * 0.42;

    // Top and bottom clues, one per column.
    for (var col = 0; col < n; col++) {
      final x = margin + (col + 0.5) * cellWidth;
      if (puzzle.top[col] != 0) {
        canvas.text(
          '${puzzle.top[col]}',
          Rect.fromCenter(
            center: Offset(x, margin * 0.45),
            width: cellWidth,
            height: margin * 0.8,
          ),
          color: canvas.palette.muted,
          fontSize: fontSize,
          weight: FontWeight.w800,
        );
      }
      if (puzzle.bottom[col] != 0) {
        canvas.text(
          '${puzzle.bottom[col]}',
          Rect.fromCenter(
            center: Offset(x, 1 - margin * 0.45),
            width: cellWidth,
            height: margin * 0.8,
          ),
          color: canvas.palette.muted,
          fontSize: fontSize,
          weight: FontWeight.w800,
        );
      }
    }

    // Left and right clues, one per row.
    for (var row = 0; row < n; row++) {
      final y = margin + (row + 0.5) * cellHeight;
      if (puzzle.left[row] != 0) {
        canvas.text(
          '${puzzle.left[row]}',
          Rect.fromCenter(
            center: Offset(margin * 0.45, y),
            width: margin * 0.8,
            height: cellHeight,
          ),
          color: canvas.palette.muted,
          fontSize: fontSize,
          weight: FontWeight.w800,
        );
      }
      if (puzzle.right[row] != 0) {
        canvas.text(
          '${puzzle.right[row]}',
          Rect.fromCenter(
            center: Offset(1 - margin * 0.45, y),
            width: margin * 0.8,
            height: cellHeight,
          ),
          color: canvas.palette.muted,
          fontSize: fontSize,
          weight: FontWeight.w800,
        );
      }
    }
  }
}
