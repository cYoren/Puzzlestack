import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import '../../../core/board/puzzle_marks.dart';
import 'crossing_provider.dart';

/// Crossing on the board contract.
///
/// Two things on one canvas, because they are one object: the digit grid, and
/// under it the number list the player is placing.
///
/// The grid's shape *is* the puzzle — the runs are where numbers go — so a cell
/// is drawn as part of a strip rather than as a tile: cells touch, and each run
/// gets one outline around the whole of itself. A crossing cell belongs to two
/// runs, which is what the player needs to see there, and two numbers that end up
/// side by side in one row keep their own outlines so the pair never reads as one
/// longer number.
///
/// The list is under the grid, not in the chrome, because it is board: the chips
/// are struck through as their number appears, so the game's progress is the
/// list emptying rather than the grid filling.
class CrossingBoard extends GridBoard<CrossingState> {
  CrossingBoard({required this.state});

  @override
  final CrossingState state;

  @override
  int get rows => state.n;

  @override
  int get cols => state.n;

  @override
  bool get isSolved => state.isSolved;

  /// A cell is part of a strip, not a tile of its own.
  @override
  double get gapFraction => 0;

  @override
  double get margin => 0.02;

  /// Chips across the list. Five fits three digits at 320dp.
  static const int chipCols = 5;

  int get _chipRows => (state.puzzle.numbers.length / chipCols).ceil();

  /// How tall the list band is, in cell heights.
  ///
  /// It is measured in cells so the two parts of the board keep one scale: a
  /// chip row is most of a cell tall, so a three-digit number in a chip reads at
  /// nearly the size it will read in the grid.
  double get _band => 0.3 + _chipRows * 0.85;

  /// The box is the grid plus the list under it, so the cells stay square.
  @override
  double get aspectRatio => (rows + _band) / cols;

  @override
  double get cellWidth => (1 - 2 * margin) / cols;

  @override
  double get cellHeight => (1 - 2 * margin) / (rows + _band);

  late final Set<int> _conflicts = state.conflicts;

  /// Only real cells celebrate: a wall popping in the win cascade would say the
  /// player had filled something they cannot touch.
  @override
  List<ElementRef> get celebrationElements => [
        for (var row = 0; row < rows; row++)
          for (var col = 0; col < cols; col++)
            if (!state.puzzle.isWall(row * cols + col)) cell(row, col),
      ];

  @override
  List<PuzzleMove<CrossingState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<CrossingState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    if (state.puzzle.isWall(element.a * cols + element.b)) return null;
    return PuzzleMove<CrossingState>(
      kind: MoveKind.select,
      source: element,
      apply: (current) => current,
    );
  }

  /// The band under the grid, in normalised units.
  Rect get listRect => Rect.fromLTRB(
        margin,
        margin + rows * cellHeight + cellHeight * 0.18,
        1 - margin,
        1 - margin,
      );

  /// Where one chip sits.
  Rect chipRect(int index) {
    final band = listRect;
    final row = index ~/ chipCols;
    final col = index % chipCols;
    final rowHeight = band.height / _chipRows;
    final gap = cellWidth * 0.16;
    final width = (band.width - (chipCols - 1) * gap) / chipCols;
    return Rect.fromLTWH(
      band.left + col * (width + gap),
      band.top + row * rowHeight,
      width,
      rowHeight * 0.86,
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, CrossingState state, int row, int col) {
    final cell = row * cols + col;
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    if (state.puzzle.isWall(cell)) return;

    final conflict = _conflicts.contains(cell);
    canvas.cell(
      rect,
      fill: conflict ? palette.error.withValues(alpha: 0.14) : palette.surface,
      radius: 0,
    );

    final value = state.values[cell];
    if (value >= 1 && value <= 9) {
      PuzzleMarks(canvas).label(
        rect,
        '$value',
        role: conflict ? MarkRole.error : MarkRole.ink,
        fraction: 0.5,
        weight: FontWeight.w700,
      );
    }

    if (state.hintCells.contains(cell)) {
      canvas.cell(rect, stroke: palette.error, strokeWidth: 2.5, radius: 0);
    }
    if (state.selected == cell) {
      canvas.cell(rect, stroke: palette.primary, strokeWidth: 2.5, radius: 0);
    }
  }

  @override
  void paint(PuzzleCanvas canvas, CrossingState state) {
    super.paint(canvas, state);

    final palette = canvas.palette;
    final puzzle = state.puzzle;

    // One hairline between the digits of a strip, so a three-digit number reads
    // as three cells of one thing rather than one long word.
    for (var run = 0; run < puzzle.runCount; run++) {
      final cells = puzzle.runCells(run);
      for (var i = 0; i + 1 < cells.length; i++) {
        final a = cellRect(cells[i] ~/ cols, cells[i] % cols);
        if (puzzle.runs[run].horizontal) {
          canvas.line(
            Offset(a.right, a.top),
            Offset(a.right, a.bottom),
            color: palette.line,
            width: 1.0,
            cap: StrokeCap.butt,
          );
        } else {
          canvas.line(
            Offset(a.left, a.bottom),
            Offset(a.right, a.bottom),
            color: palette.line,
            width: 1.0,
            cap: StrokeCap.butt,
          );
        }
      }
    }

    // One outline per run: the object the number goes into. A run that already
    // spells a listed number turns to the success colour, so the eye can see
    // which parts of the skeleton are done.
    for (var run = 0; run < puzzle.runCount; run++) {
      final cells = puzzle.runCells(run);
      final first = cellRect(cells.first ~/ cols, cells.first % cols);
      final last = cellRect(cells.last ~/ cols, cells.last % cols);
      final strip =
          Rect.fromLTRB(first.left, first.top, last.right, last.bottom);
      final text = puzzle.runText(run, state.values);
      final placed = text.isNotEmpty && puzzle.numberIndex(text) >= 0;
      canvas.cell(
        strip,
        stroke: placed ? palette.success : palette.structure,
        strokeWidth: placed ? 2.0 : 1.4,
        radius: 2,
      );
    }

    _paintList(canvas, state);

    // The crossing under the finger is the one the player is working, so it
    // reads strongest.
    final selected = state.selected;
    if (selected != null && !puzzle.isWall(selected)) {
      for (final (run, _) in puzzle.runsAt(selected)) {
        final cells = puzzle.runCells(run);
        final first = cellRect(cells.first ~/ cols, cells.first % cols);
        final last = cellRect(cells.last ~/ cols, cells.last % cols);
        canvas.cell(
          Rect.fromLTRB(first.left, first.top, last.right, last.bottom),
          stroke: palette.primary,
          strokeWidth: 1.6,
          radius: 2,
        );
      }
    }
  }

  void _paintList(PuzzleCanvas canvas, CrossingState state) {
    final marks = PuzzleMarks(canvas);
    final numbers = state.puzzle.numbers;
    final shown = state.satisfied;
    for (var i = 0; i < numbers.length; i++) {
      final rect = chipRect(i);
      final done = shown.contains(i);
      canvas.cell(
        rect,
        fill: canvas.palette.surface,
        stroke: done ? canvas.palette.success : canvas.palette.line,
        strokeWidth: 1.2,
        radius: 6,
      );
      marks.label(
        rect,
        numbers[i],
        role: done ? MarkRole.muted : MarkRole.ink,
        fraction: 0.46,
        weight: FontWeight.w700,
      );
      if (!done) continue;
      // Struck through: this number is in the grid, and the list is what the
      // player is working down.
      final y = rect.center.dy;
      canvas.line(
        Offset(rect.left + rect.width * 0.12, y),
        Offset(rect.right - rect.width * 0.12, y),
        color: canvas.palette.success,
        width: 2.0,
      );
    }
  }
}
