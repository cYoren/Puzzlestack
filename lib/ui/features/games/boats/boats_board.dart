import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import '../../../core/board/puzzle_marks.dart';
import 'boats_engine.dart';
import 'boats_provider.dart';

/// Boats on the board contract.
///
/// A boat cell is a solid block that joins the boat cells beside it, so a run
/// of four reads as one hull and not as four tiles. Water is the house dot,
/// which is the smallest mark that still says "decided" at 320dp. An untouched
/// cell draws nothing at all: it is a third state, not a paler water.
class BoatsBoard extends GridBoard<BoatsState> {
  BoatsBoard({required this.state});

  @override
  final BoatsState state;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  @override
  bool get isSolved => state.isSolved;

  /// Room for the row and column counts.
  @override
  double get margin => 0.13;

  @override
  double get gapFraction => 0.10;

  int _value(int row, int col) => state.marks[row * cols + col];

  bool _isShip(int row, int col) =>
      row >= 0 &&
      row < rows &&
      col >= 0 &&
      col < cols &&
      _value(row, col) == kMarkShip;

  @override
  List<PuzzleMove<BoatsState>> movesFor(ElementRef element) {
    if (!isCell(element) || state.isSolved) return const [];
    return [
      PuzzleMove<BoatsState>(
        kind: MoveKind.toggle,
        source: element,
        apply: (current) => current,
      ),
    ];
  }

  @override
  PuzzleMove<BoatsState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    return PuzzleMove<BoatsState>(
      kind: MoveKind.toggle,
      source: element,
      apply: (current) => current,
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, BoatsState state, int row, int col) {
    final marks = PuzzleMarks(canvas, fraction: 0.92);
    final cell = row * cols + col;
    final rect = cellRect(row, col);
    final value = state.marks[cell];
    final hinted = state.hintCell == cell;

    if (value == kMarkShip) {
      final join = <MarkSide>{
        if (_isShip(row - 1, col)) MarkSide.up,
        if (_isShip(row + 1, col)) MarkSide.down,
        if (_isShip(row, col - 1)) MarkSide.left,
        if (_isShip(row, col + 1)) MarkSide.right,
      };
      marks.block(rect, role: MarkRole.structure, inset: 0.06, join: join);
      if (hinted) marks.hint(rect);
      return;
    }

    marks.tile(
      rect,
      fill: canvas.palette.surface,
      stroke: canvas.palette.line.withValues(alpha: 0.6),
      radius: 6,
    );
    if (value == kMarkWater) {
      marks.dotMark(rect, role: MarkRole.muted, size: 0.14);
    }
    if (hinted) marks.hint(rect);
  }

  @override
  void paint(PuzzleCanvas canvas, BoatsState state) {
    super.paint(canvas, state);
    final palette = canvas.palette;
    final fontSize = canvas.fontSizeFor(cellRect(0, 0), 0.42);

    for (var row = 0; row < rows; row++) {
      final rect = cellRect(row, 0);
      final count = state.puzzle.rowCounts[row];
      final done = _rowShips(row) == count;
      // The clue itself, not a running total: the guide says these numbers are
      // the counts the row holds, and a number that changes under the finger
      // reads as a different puzzle.
      canvas.text(
        '$count',
        Rect.fromCenter(
          center: Offset(rect.left - rect.width * 0.62, rect.center.dy),
          width: rect.width,
          height: rect.height,
        ),
        color: done ? palette.success : palette.muted,
        fontSize: fontSize,
        weight: FontWeight.w900,
      );
    }

    for (var col = 0; col < cols; col++) {
      final rect = cellRect(0, col);
      final count = state.puzzle.colCounts[col];
      final done = _colShips(col) == count;
      canvas.text(
        '$count',
        Rect.fromCenter(
          center: Offset(rect.center.dx, rect.top - rect.height * 0.62),
          width: rect.width,
          height: rect.height,
        ),
        color: done ? palette.success : palette.muted,
        fontSize: fontSize,
        weight: FontWeight.w900,
      );
    }
  }

  int _rowShips(int row) {
    var count = 0;
    for (var col = 0; col < cols; col++) {
      if (_value(row, col) == kMarkShip) count++;
    }
    return count;
  }

  int _colShips(int col) {
    var count = 0;
    for (var row = 0; row < rows; row++) {
      if (_value(row, col) == kMarkShip) count++;
    }
    return count;
  }
}

/// The strip of boats still to find, under the board.
///
/// A found boat is crossed off, which is the only progress signal the puzzle
/// needs: the counts say the rest. One marked boat crosses off exactly one
/// required boat, even when the fleet holds two of the same length.
class BoatsFleetStrip extends StatelessWidget {
  const BoatsFleetStrip({super.key, required this.state});

  final BoatsState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final crossed = crossedOffFleet(
      state.marks,
      state.puzzle.fleet,
      rows: state.rows,
      cols: state.cols,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        for (var i = 0; i < state.puzzle.fleet.length; i++)
          _BoatChip(
            length: state.puzzle.fleet[i],
            found: crossed[i],
            scheme: scheme,
          ),
      ],
    );
  }
}

class _BoatChip extends StatelessWidget {
  const _BoatChip({
    required this.length,
    required this.found,
    required this.scheme,
  });

  final int length;
  final bool found;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++)
          Container(
            width: 9,
            height: 9,
            margin: EdgeInsets.only(right: i == length - 1 ? 0 : 2),
            decoration: BoxDecoration(
              color: found
                  ? scheme.onSurface.withValues(alpha: 0.18)
                  : scheme.onSurface,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
