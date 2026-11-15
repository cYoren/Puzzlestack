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
/// which is the smallest mark that still says "decided" at 320dp.
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
      _value(row, col) == kBoatShip;

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
    final cell = element.a * cols + element.b;
    return PuzzleMove<BoatsState>(
      kind: MoveKind.toggle,
      source: element,
      apply: (current) => current.copyWith(
        marks: _cycle(current.marks, cell),
        isSolved: false,
      ),
    );
  }

  List<int> _cycle(List<int> marks, int cell) {
    final next = [...marks];
    next[cell] = switch (next[cell]) {
      0 => kBoatShip,
      kBoatShip => kBoatWater,
      _ => 0,
    };
    return next;
  }

  @override
  void paintCell(PuzzleCanvas canvas, BoatsState state, int row, int col) {
    final marks = PuzzleMarks(canvas, fraction: 0.92);
    final cell = row * cols + col;
    final rect = cellRect(row, col);
    final value = state.marks[cell];
    final hinted = state.hintCell == cell;

    if (value == kBoatShip) {
      final join = <MarkSide>{
        if (_isShip(row - 1, col)) MarkSide.up,
        if (_isShip(row + 1, col)) MarkSide.down,
        if (_isShip(row, col - 1)) MarkSide.left,
        if (_isShip(row, col + 1)) MarkSide.right,
      };
      marks.block(
        rect,
        role: MarkRole.structure,
        inset: 0.06,
        join: join,
      );
      if (hinted) marks.hint(rect);
      return;
    }

    marks.tile(
      rect,
      fill: canvas.palette.surface,
      stroke: canvas.palette.line.withValues(alpha: 0.6),
      radius: 6,
    );
    if (value == kBoatWater) {
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
      canvas.text(
        '${count - _rowShips(row)}',
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
        '${count - _colShips(col)}',
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
      if (_value(row, col) == kBoatShip) count++;
    }
    return count;
  }

  int _colShips(int col) {
    var count = 0;
    for (var row = 0; row < rows; row++) {
      if (_value(row, col) == kBoatShip) count++;
    }
    return count;
  }
}

/// The strip of boats still to find, under the board.
///
/// A found boat is crossed off, which is the only progress signal the puzzle
/// needs: the counts say the rest.
class BoatsFleetStrip extends StatelessWidget {
  const BoatsFleetStrip({super.key, required this.state});

  final BoatsState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final found = _foundBoats();
    final remaining = [...state.puzzle.fleet];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        for (final length in state.puzzle.fleet)
          _BoatChip(
            length: length,
            found: remaining.remove(length) && found.contains(length),
            scheme: scheme,
          ),
      ],
    );
  }

  /// The lengths of the complete boats the player has marked.
  List<int> _foundBoats() {
    final marks = state.marks;
    final seen = List<bool>.filled(marks.length, false);
    final lengths = <int>[];
    for (var cell = 0; cell < marks.length; cell++) {
      if (marks[cell] != kBoatShip || seen[cell]) continue;
      final row = cell ~/ cols;
      final col = cell % cols;
      final horizontal = (col + 1 < cols && marks[cell + 1] == kBoatShip) ||
          (col > 0 && marks[cell - 1] == kBoatShip);
      var length = 0;
      if (horizontal) {
        var start = col;
        while (start > 0 && marks[row * cols + start - 1] == kBoatShip) {
          start--;
        }
        for (var c = start; c < cols; c++) {
          final index = row * cols + c;
          if (marks[index] != kBoatShip) break;
          seen[index] = true;
          length++;
        }
      } else {
        var start = row;
        while (start > 0 && marks[(start - 1) * cols + col] == kBoatShip) {
          start--;
        }
        for (var r = start; r < rows; r++) {
          final index = r * cols + col;
          if (marks[index] != kBoatShip) break;
          seen[index] = true;
          length++;
        }
      }
      lengths.add(length);
    }
    return lengths;
  }

  int get cols => state.cols;
  int get rows => state.rows;
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
