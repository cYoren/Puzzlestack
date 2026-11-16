import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import '../../../core/board/puzzle_marks.dart';
import 'rome_provider.dart';
import 'rome_puzzle.dart';

/// Rome on the board contract.
///
/// Two things carry the rules, so both get drawn and nothing else does:
///
///  * the **areas** — cells sit flush, a border inside an area is a hairline and
///    a border between two areas is heavy, because "no repeated arrow" is a
///    statement about an outline the player has to be able to see;
///  * the **goal** — a ring, the one shape on the board that is not an arrow.
///
/// A printed arrow is ink and an arrow the player wrote is the primary colour,
/// which is how the player tells what is theirs. An arrow that breaks a rule
/// turns red where it stands, so the mistake is on the cell that made it.
class RomeBoard extends GridBoard<RomeState> {
  RomeBoard({required this.state});

  @override
  final RomeState state;

  @override
  int get rows => state.n;

  @override
  int get cols => state.n;

  @override
  bool get isSolved => state.isSolved;

  /// The area borders are the outline, so the cells must touch.
  @override
  double get gapFraction => 0;

  @override
  double get margin => 0.03;

  late final Set<int> _conflicts = state.conflicts;

  /// The direction an arrow value points.
  ///
  /// Written out rather than `MarkDirection.values[arrow]`: the two orders only
  /// agree by luck, and a reorder of the enum would silently turn every arrow on
  /// the board ninety degrees.
  static MarkDirection directionOf(int arrow) => switch (arrow) {
        kRomeUp => MarkDirection.up,
        kRomeRight => MarkDirection.right,
        kRomeDown => MarkDirection.down,
        kRomeLeft => MarkDirection.left,
        _ => MarkDirection.up,
      };

  @override
  List<PuzzleMove<RomeState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<RomeState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    return PuzzleMove<RomeState>(
      kind: MoveKind.select,
      source: element,
      apply: (current) => current,
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, RomeState state, int row, int col) {
    final cell = row * cols + col;
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final marks = PuzzleMarks(canvas);
    final conflict = _conflicts.contains(cell);

    canvas.cell(
      rect,
      fill: conflict ? palette.error.withValues(alpha: 0.12) : palette.surface,
      radius: 0,
    );

    if (state.puzzle.isGoal(cell)) {
      // A goal is a sink: a circle and nothing inside it. It is not a cell the
      // player can write, so it has to read as a different kind of thing from
      // every arrow around it.
      marks.ringMark(
        rect,
        role: MarkRole.structure,
        size: 0.62,
        weight: 2.0,
      );
    } else {
      final value = state.values[cell];
      if (value >= kRomeUp && value <= kRomeLeft) {
        final given = state.puzzle.given(cell) != kRomeNoGiven;
        marks.arrow(
          rect,
          directionOf(value),
          role: conflict
              ? MarkRole.error
              : given
                  ? MarkRole.ink
                  : MarkRole.primary,
        );
      }
    }

    if (state.hintCell == cell) marks.hint(rect);
    if (state.selected == cell) {
      canvas.cell(rect, stroke: palette.primary, strokeWidth: 2.5, radius: 0);
    }
  }

  @override
  void paint(PuzzleCanvas canvas, RomeState state) {
    super.paint(canvas, state);

    final palette = canvas.palette;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final rect = slotRect(row, col);
        final cell = row * cols + col;
        // The right and bottom edges, so a shared edge is drawn once.
        if (col + 1 < cols) {
          final same =
              state.puzzle.areaOf(cell) == state.puzzle.areaOf(cell + 1);
          canvas.line(
            Offset(rect.right, rect.top),
            Offset(rect.right, rect.bottom),
            color: same ? palette.line : palette.structure,
            width: same ? 1.0 : 3.0,
            cap: StrokeCap.butt,
          );
        }
        if (row + 1 < rows) {
          final same =
              state.puzzle.areaOf(cell) == state.puzzle.areaOf(cell + cols);
          canvas.line(
            Offset(rect.left, rect.bottom),
            Offset(rect.right, rect.bottom),
            color: same ? palette.line : palette.structure,
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
