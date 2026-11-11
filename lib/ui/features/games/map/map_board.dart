import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import '../../../../utils/design_system.dart';
import 'map_engine.dart';
import 'map_provider.dart';

/// The four map colours, in the order the board cycles them.
const List<Color> mapColours = [
  DesignSystem.gameBlue,
  DesignSystem.gameAmber,
  DesignSystem.gameGreen,
  DesignSystem.gamePink,
];

/// Map on the board contract.
///
/// Every cell belongs to a region, and a tap cycles that region's colour. Region
/// borders are drawn where two cells belong to different regions, which is what
/// turns a grid into a map.
class MapBoard extends GridBoard<MapState> {
  MapBoard({required this.state});

  @override
  final MapState state;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  @override
  bool get isSolved => const MapEngine().isSolved(state.puzzle, state.colours);

  @override
  double get margin => 0.02;

  @override
  double get gapFraction => 0.0;

  int _regionAt(int row, int col) => state.puzzle.regionOf[row * cols + col];

  Set<int> get _conflicts =>
      const MapEngine().conflicts(state.puzzle, state.colours);

  PuzzleMove<MapState> _cycleMove(ElementRef element, int region) =>
      PuzzleMove<MapState>(
        kind: MoveKind.place,
        source: element,
        apply: (current) {
          final colours = [...current.colours];
          colours[region] =
              colours[region] >= mapColourCount - 1 ? -1 : colours[region] + 1;
          return current.copyWith(colours: colours, clearHint: true);
        },
      );

  @override
  List<PuzzleMove<MapState>> movesFor(ElementRef element) {
    if (!isCell(element)) return const [];
    return [_cycleMove(element, _regionAt(element.a, element.b))];
  }

  @override
  PuzzleMove<MapState>? tapMove(ElementRef element) {
    if (!isCell(element)) return null;
    return _cycleMove(element, _regionAt(element.a, element.b));
  }

  @override
  void paintCell(PuzzleCanvas canvas, MapState state, int row, int col) {
    final region = _regionAt(row, col);
    final colour = state.colours[region];
    final rect = cellRect(row, col);
    final palette = canvas.palette;

    final fill = colour < 0
        ? palette.surface
        : mapColours[colour].withValues(alpha: 0.55);
    canvas.cell(rect, fill: fill);

    // A hairline wherever the region changes: that is the border of the map.
    final border = palette.ink.withValues(alpha: 0.32);
    if (col + 1 < cols && _regionAt(row, col + 1) != region) {
      canvas.line(rect.topRight, rect.bottomRight, color: border, width: 1.8);
    }
    if (row + 1 < rows && _regionAt(row + 1, col) != region) {
      canvas.line(rect.bottomLeft, rect.bottomRight, color: border, width: 1.8);
    }
    if (col == 0) {
      canvas.line(rect.topLeft, rect.bottomLeft, color: border, width: 1.8);
    }
    if (row == 0) {
      canvas.line(rect.topLeft, rect.topRight, color: border, width: 1.8);
    }

    if (state.hintRegion == region) {
      canvas.cell(
        rect.deflate(0.004),
        stroke: palette.success,
        strokeWidth: 2.5,
        radius: 3,
      );
    }
  }

  @override
  void paint(PuzzleCanvas canvas, MapState state) {
    super.paint(canvas, state);

    // Clashing regions get a red wash over their colour, so the mistake is
    // visible without reading a legend.
    final conflicts = _conflicts;
    if (conflicts.isEmpty) return;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final region = _regionAt(row, col);
        if (!conflicts.contains(region)) continue;
        canvas.cell(
          cellRect(row, col),
          fill: canvas.palette.error.withValues(alpha: 0.28),
        );
      }
    }
  }
}
