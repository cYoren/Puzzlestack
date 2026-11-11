import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'signpost_engine.dart';
import 'signpost_provider.dart';

/// Signpost on the board contract.
///
/// The board is the links, not the numbers: a cell shows a number only when its
/// chain has met one of the given numbers, so a chain that is still floating
/// shows its arrows and nothing else. That is the honest reading — those cells
/// have no number yet, and guessing one would be the app solving it for you.
///
/// Drag a cell onto the cell it should point at, or tap the cell and then the
/// place it points to. Tapping a cell that already points somewhere takes the
/// link back, which is how a wrong turn is undone without losing the rest.
class SignpostBoard extends GridBoard<SignpostState> {
  SignpostBoard({required this.state});

  @override
  final SignpostState state;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  /// Room for the arrow heads, which sit against the cell edge.
  @override
  double get margin => 0.03;

  @override
  double get gapFraction => 0.07;

  @override
  bool get isSolved => state.isSolved;

  static const SignpostEngine _engine = SignpostEngine();

  int _index(ElementRef element) => state.puzzle.index(element.a, element.b);

  ElementRef _cellOf(int index) =>
      cell(state.puzzle.rowOf(index), state.puzzle.colOf(index));

  bool _isTarget(int cell) {
    final selected = state.selected;
    if (selected == null || selected == cell) return false;
    return _engine.legal(state.position, state.puzzle, selected, cell);
  }

  PuzzleMove<SignpostState> _linkMove(ElementRef source, int from, int to) =>
      PuzzleMove<SignpostState>(
        kind: MoveKind.place,
        source: source,
        target: _cellOf(to),
        apply: (current) => current.copyWith(
          links: [...current.links]..[from] = to,
          moves: current.moves + 1,
          clearSelected: true,
          clearHint: true,
        ),
      );

  PuzzleMove<SignpostState> _selectMove(ElementRef source, int cell) =>
      PuzzleMove<SignpostState>(
        kind: MoveKind.select,
        source: source,
        apply: (current) => current.copyWith(
          selected: cell,
          clearHint: true,
        ),
      );

  PuzzleMove<SignpostState> _unlinkMove(ElementRef source, int cell) =>
      PuzzleMove<SignpostState>(
        kind: MoveKind.clear,
        source: source,
        apply: (current) => current.copyWith(
          links: [...current.links]..[cell] = -1,
          moves: current.moves + 1,
          clearSelected: true,
          clearHint: true,
        ),
      );

  /// Every cell this one can join itself to, as a drag target.
  @override
  List<PuzzleMove<SignpostState>> movesFor(ElementRef element) {
    if (!isCell(element) || state.isSolved) return const [];
    final from = _index(element);
    return [
      for (final to in _engine.candidatesFor(state.puzzle, state.links, from))
        _linkMove(element, from, to),
    ];
  }

  /// Tap only: the same moves, one at a time.
  ///
  /// A tap on a cell that already points somewhere takes that link back.
  /// Otherwise it selects the cell, and a second tap on a highlighted cell
  /// joins them — so a player who never drags can still finish any board.
  @override
  PuzzleMove<SignpostState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    final cell = _index(element);

    final selected = state.selected;
    if (selected != null && selected != cell) {
      if (_engine.legal(state.position, state.puzzle, selected, cell)) {
        return _linkMove(element, selected, cell);
      }
    }

    if (selected == cell) {
      return PuzzleMove<SignpostState>(
        kind: MoveKind.select,
        source: element,
        apply: (current) => current.copyWith(clearSelected: true),
      );
    }

    if (state.links[cell] >= 0) return _unlinkMove(element, cell);

    // The last number points nowhere, so there is nothing to start from it.
    if (state.position.numbers[cell] == state.puzzle.cellCount) return null;
    return _selectMove(element, cell);
  }

  @override
  void paintCell(PuzzleCanvas canvas, SignpostState state, int row, int col) {
    final puzzle = state.puzzle;
    final index = puzzle.index(row, col);
    final rect = cellRect(row, col);
    final palette = canvas.palette;

    final number = state.position.numbers[index];
    final given = puzzle.isClue(index);
    final linked = state.links[index] >= 0;
    final selected = state.selected == index;
    final target = _isTarget(index);
    final hinted = state.hint?.from == index || state.hint?.to == index;

    final lit = selected || target || hinted;
    final fill = target
        ? palette.primary.withValues(alpha: 0.12)
        : selected
            ? palette.primary.withValues(alpha: 0.08)
            : given
                ? palette.ink.withValues(alpha: 0.05)
                : palette.surface;

    canvas.cell(
      rect,
      fill: fill,
      stroke: lit ? palette.primary : palette.outline.withValues(alpha: 0.28),
      strokeWidth: lit ? 2.5 : 1.5,
    );

    _paintArrow(
      canvas,
      rect,
      puzzle.dirs[index],
      linked ? palette.primary : palette.muted,
      linked ? 3 : 2,
    );

    if (number > 0) {
      canvas.text(
        '$number',
        rect,
        color: given ? palette.ink : palette.primary,
        fontSize: canvas.size.width * cellWidth * (number >= 10 ? 0.38 : 0.46),
        weight: given ? FontWeight.w900 : FontWeight.w700,
      );
    }
  }

  /// The arrow: a short shaft out of the number, ending in a solid head against
  /// the cell edge, so the eye reads the direction before the digit.
  void _paintArrow(
    PuzzleCanvas canvas,
    Rect rect,
    int direction,
    Color color,
    double width,
  ) {
    final (stepX, stepY) = signpostStep(direction);
    final x = stepX.toDouble();
    final y = stepY.toDouble();
    final halfWidth = rect.width / 2;
    final halfHeight = rect.height / 2;
    final centre = rect.center;

    final tip = Offset(
      centre.dx + x * halfWidth * 0.90,
      centre.dy + y * halfHeight * 0.90,
    );
    final shaft = Offset(
      centre.dx + x * halfWidth * 0.50,
      centre.dy + y * halfHeight * 0.50,
    );
    canvas.line(shaft, tip, color: color, width: width);

    // The head is a triangle centred on the tip, squared to the arrow.
    final base = Offset(
      tip.dx - x * halfWidth * 0.24,
      tip.dy - y * halfHeight * 0.24,
    );
    final barbX = -y * halfWidth * 0.17;
    final barbY = x * halfHeight * 0.17;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + barbX, base.dy + barbY)
      ..lineTo(base.dx - barbX, base.dy - barbY)
      ..close();
    canvas.path(path, fill: color);
  }
}
