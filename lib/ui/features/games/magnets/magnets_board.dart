import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'magnets_model.dart';
import 'magnets_provider.dart';

/// Magnets on the board contract.
///
/// The domino outlines are the puzzle: without them a tap toggles a pair the
/// player cannot see, which is what the old screen did. Tapping either half
/// cycles the whole domino.
class MagnetsBoard extends GridBoard<MagnetsState> {
  MagnetsBoard({required this.state});

  @override
  final MagnetsState state;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  @override
  bool get isSolved => state.isSolved;

  /// Room for the row and column counts around the grid.
  @override
  double get margin => 0.18;

  @override
  List<PuzzleMove<MagnetsState>> movesFor(ElementRef element) {
    if (!isCell(element) || state.isSolved) return const [];
    final cell = element.a * cols + element.b;
    final domino = state.puzzle.dominoOf[cell];
    return [
      PuzzleMove<MagnetsState>(
        kind: MoveKind.place,
        source: element,
        apply: (current) {
          final states = [...current.states];
          states[domino] = (states[domino] + 1) % 3;
          return current.copyWith(states: states, isSolved: false);
        },
      ),
    ];
  }

  @override
  PuzzleMove<MagnetsState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    final cell = element.a * cols + element.b;
    final domino = state.puzzle.dominoOf[cell];
    return PuzzleMove<MagnetsState>(
      kind: MoveKind.place,
      source: element,
      apply: (current) {
        final states = [...current.states];
        states[domino] = (states[domino] + 1) % 3;
        return current.copyWith(states: states, isSolved: false);
      },
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, MagnetsState state, int row, int col) {
    final cell = row * cols + col;
    final pole = state.poleAt(cell);
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final hinted = state.hintCell == cell;

    final fill = switch (pole) {
      kPositive => palette.primary.withValues(alpha: 0.16),
      kNegative => palette.error.withValues(alpha: 0.16),
      _ => palette.surface,
    };

    canvas.cell(
      rect,
      fill: fill,
      stroke: hinted
          ? palette.success
          : palette.outline.withValues(alpha: 0.25),
      strokeWidth: hinted ? 2.5 : 1,
    );

    if (pole == kNeutral) return;
    canvas.text(
      pole == kPositive ? '+' : '−',
      rect,
      color: pole == kPositive ? palette.primary : palette.error,
      fontSize: rect.height * canvas.size.height * 0.5,
      weight: FontWeight.w900,
    );
  }

  @override
  void paint(PuzzleCanvas canvas, MagnetsState state) {
    super.paint(canvas, state);
    final palette = canvas.palette;

    // Domino outlines, and the counts around the edge.
    for (var d = 0; d < state.puzzle.dominoCount; d++) {
      final a = state.puzzle.dominoA[d];
      final b = state.puzzle.dominoB[d];
      final ra = a ~/ cols;
      final ca = a % cols;
      final rb = b ~/ cols;
      final cb = b % cols;
      final rect = cellRect(ra, ca).expandToInclude(cellRect(rb, cb));
      canvas.rrect(
        rect,
        stroke: palette.ink.withValues(alpha: 0.45),
        strokeWidth: 1.6,
        topRadius: 5,
        bottomRadius: 5,
      );
    }

    for (var r = 0; r < rows; r++) {
      final rect = cellRect(r, 0);
      final label = '${state.puzzle.rowPlus[r]}/${state.puzzle.rowMinus[r]}';
      canvas.text(
        label,
        Rect.fromCenter(
          center: Offset(rect.left - rect.width * 0.62, rect.center.dy),
          width: rect.width * 1.2,
          height: rect.height,
        ),
        color: palette.muted,
        fontSize: canvas.size.height * cellHeight * 0.34,
        weight: FontWeight.w800,
      );
    }

    for (var c = 0; c < cols; c++) {
      final rect = cellRect(0, c);
      final label = '${state.puzzle.colPlus[c]}/${state.puzzle.colMinus[c]}';
      canvas.text(
        label,
        Rect.fromCenter(
          center: Offset(rect.center.dx, rect.top - rect.height * 0.62),
          width: rect.width,
          height: rect.height * 1.2,
        ),
        color: palette.muted,
        fontSize: canvas.size.height * cellHeight * 0.34,
        weight: FontWeight.w800,
      );
    }
  }
}
