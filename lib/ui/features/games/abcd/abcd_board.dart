import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import '../../../core/board/puzzle_marks.dart';
import 'abcd_provider.dart';

/// ABCD on the board contract, with the counts in the margin.
///
/// The clue for a line is one digit per letter in alphabet order, so a column
/// that holds A twice, B once, C once and D once reads `2111`. The letters
/// themselves are in a legend under the board, which keeps the margin narrow
/// enough to fit at 320dp with four counts in it.
class AbcdBoard extends GridBoard<AbcdState> {
  AbcdBoard({required this.state});

  @override
  final AbcdState state;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  @override
  bool get isSolved => state.isSolved;

  /// Room for one line of count digits above and to the left.
  @override
  double get margin => 0.16;

  @override
  double get gapFraction => 0.08;

  @override
  List<PuzzleMove<AbcdState>> movesFor(ElementRef element) {
    if (!isCell(element) || state.isSolved) return const [];
    return [
      PuzzleMove<AbcdState>(
        kind: MoveKind.place,
        source: element,
        apply: (current) => current,
      ),
    ];
  }

  @override
  PuzzleMove<AbcdState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    return PuzzleMove<AbcdState>(
      kind: MoveKind.place,
      source: element,
      apply: (current) => current,
    );
  }

  /// True when this cell holds the same letter as a cell beside it.
  bool _conflicts(int row, int col) {
    final value = state.grid[row * cols + col];
    if (value < 0) return false;
    bool same(int r, int c) =>
        r >= 0 &&
        r < rows &&
        c >= 0 &&
        c < cols &&
        state.grid[r * cols + c] == value;
    return same(row, col - 1) ||
        same(row, col + 1) ||
        same(row - 1, col) ||
        same(row + 1, col);
  }

  /// True when this letter has all the cells its line clue asks for.
  bool _rowSettled(int row) {
    final counts = state.puzzle.rowCounts[row];
    for (var letter = 0; letter < state.letters; letter++) {
      var seen = 0;
      for (var col = 0; col < cols; col++) {
        if (state.grid[row * cols + col] == letter) seen++;
      }
      if (seen > counts[letter]) return false;
    }
    return true;
  }

  @override
  void paintCell(PuzzleCanvas canvas, AbcdState state, int row, int col) {
    final marks = PuzzleMarks(canvas, fraction: 0.92);
    final rect = cellRect(row, col);
    final cell = row * cols + col;
    final value = state.grid[cell];
    final hinted = state.hintCell == cell;

    marks.tile(
      rect,
      fill: canvas.palette.surface,
      stroke: canvas.palette.line.withValues(alpha: 0.7),
      radius: 8,
    );
    if (value >= 0) {
      marks.label(
        rect,
        state.puzzle.letterAt(value),
        role: _conflicts(row, col) ? MarkRole.error : MarkRole.ink,
        fraction: 0.5,
        weight: FontWeight.w800,
      );
    }
    if (hinted) marks.hint(rect);
  }

  @override
  void paint(PuzzleCanvas canvas, AbcdState state) {
    super.paint(canvas, state);
    final palette = canvas.palette;
    final fontSize = canvas.fontSizeFor(cellRect(0, 0), 0.26);

    // Column clues, one digit per letter, in alphabet order.
    for (var col = 0; col < cols; col++) {
      final rect = cellRect(0, col);
      final counts = state.puzzle.colCounts[col];
      final satisfied = _columnSatisfied(col);
      canvas.text(
        counts.join(),
        Rect.fromCenter(
          center: Offset(rect.center.dx, rect.top - rect.height * 0.62),
          width: rect.width,
          height: rect.height,
        ),
        color: satisfied ? palette.success : palette.muted,
        fontSize: fontSize,
        weight: FontWeight.w700,
      );
    }

    for (var row = 0; row < rows; row++) {
      final rect = cellRect(row, 0);
      final counts = state.puzzle.rowCounts[row];
      canvas.text(
        counts.join(),
        Rect.fromCenter(
          center: Offset(rect.left - rect.width * 0.62, rect.center.dy),
          width: rect.width,
          height: rect.height,
        ),
        color: _rowSettled(row) ? palette.success : palette.muted,
        fontSize: fontSize,
        weight: FontWeight.w700,
      );
    }
  }

  bool _columnSatisfied(int col) {
    for (var letter = 0; letter < state.letters; letter++) {
      var seen = 0;
      for (var row = 0; row < rows; row++) {
        if (state.grid[row * cols + col] == letter) seen++;
      }
      if (seen != state.puzzle.colCounts[col][letter]) return false;
    }
    return true;
  }
}

/// The alphabet, in order, so a player can read `2111` off the margin.
class AbcdLegend extends StatelessWidget {
  const AbcdLegend({super.key, required this.letters});

  final int letters;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return Text(
      [for (var i = 0; i < letters; i++) String.fromCharCode(65 + i)]
          .map((letter) => '$letter ')
          .join()
          .trim(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
        color: muted,
      ),
    );
  }
}
