import 'package:flutter/material.dart';

import '../../../../utils/design_system.dart';
import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'same_game_engine.dart';
import 'same_game_provider.dart';

/// Same Game on the board contract.
///
/// Tap any square in a group of two or more and the group goes. There is no
/// drag: the move is "this group", not "this square to that square", so a
/// floating tile would promise a destination that does not exist.
class SameGameBoard extends GridBoard<SameGameState> {
  SameGameBoard({required this.state, this.engine = const SameGameEngine()});

  @override
  final SameGameState state;

  final SameGameEngine engine;

  @override
  int get rows => state.puzzle.rows;

  @override
  int get cols => state.puzzle.cols;

  @override
  bool get isSolved => state.isSolved;

  int _at(int row, int col) => state.grid[row * cols + col];

  /// The five colours a board can use, in the house palette. Index 0 is unused
  /// because 0 means empty in the grid.
  static const List<Color> colours = [
    DesignSystem.gameIndigo,
    DesignSystem.gameAmber,
    DesignSystem.gameTeal,
    DesignSystem.gameRose,
    DesignSystem.gameGreen,
  ];

  static Color colourOf(int value) => colours[(value - 1) % colours.length];

  // ------------------------------------------------------------------- rules

  @override
  List<PuzzleMove<SameGameState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<SameGameState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    final index = element.a * cols + element.b;
    final group = engine.groupAt(state.grid, rows, cols, index);
    if (group.length < 2) return null;

    return PuzzleMove<SameGameState>(
      kind: MoveKind.place,
      source: element,
      apply: (current) => current.copyWith(
        grid: engine.apply(current.grid, rows, cols, group),
        score: current.score + engine.points(group.length),
        clearHint: true,
      ),
    );
  }

  // ------------------------------------------------------------------- paint

  @override
  void paintCell(PuzzleCanvas canvas, SameGameState state, int row, int col) {
    final value = _at(row, col);
    final rect = cellRect(row, col);
    final palette = canvas.palette;

    if (value == 0) {
      // An empty square is a hole in the board, not a tile: draw nothing so
      // the bed shows through and cleared space reads as gone.
      return;
    }

    final hint = state.hint;
    final inHint = hint != null && hint.contains(row * cols + col);
    final colour = colourOf(value);

    canvas.cell(
      rect,
      fill: colour.withValues(alpha: inHint ? 1.0 : 0.9),
      stroke: inHint ? palette.ink : null,
      strokeWidth: inHint ? 2.5 : 0,
    );
  }
}
