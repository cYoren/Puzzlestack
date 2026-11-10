import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'galaxies_engine.dart';
import 'galaxies_provider.dart';

/// Galaxies on the board contract.
///
/// The board is played by painting cells rather than by drawing walls: tap a
/// dot to pick it up, then tap the cells that belong to it, or drag the dot
/// onto a cell. Painting a cell paints the cell it reflects onto as well, so a
/// region is always symmetric — the rule the game is about is done for the
/// player, and the puzzle left is deciding *which* dot owns what.
///
/// That is a deliberate difference from the desktop game, which asks you to
/// draw the boundaries. On a phone, one gesture that means "this cell is that
/// dot's" is worth more than a gesture that means "draw a line here", and it
/// leaves the reasoning untouched.
class GalaxiesBoard extends GridBoard<GalaxiesState> {
  GalaxiesBoard({required this.state});

  @override
  final GalaxiesState state;

  GalaxiesPuzzle get puzzle => state.puzzle;

  @override
  int get rows => puzzle.rows;

  @override
  int get cols => puzzle.cols;

  /// Room for a dot that sits on the outer edge of the board.
  @override
  double get margin => 0.05;

  @override
  double get gapFraction => 0.0;

  @override
  bool get isSolved => state.isSolved;

  // --------------------------------------------------------------- geometry

  /// Where a dot sits, in normalised coordinates.
  ///
  /// A dot's coordinates are doubled: the point `(x, y)` is `x / 2` cells from
  /// the left, and a cell's own centre is at an even coordinate. So the board
  /// is shifted half a cell and the mapping is a straight scale.
  Offset dotCentre(GalaxiesDot dot) => Offset(
        margin + (dot.x / 2 + 0.5) * cellWidth,
        margin + (dot.y / 2 + 0.5) * cellHeight,
      );

  /// Cell index to the dot that sits in it, for dots that sit in a cell.
  ///
  /// Built once: [paintCell] asks this for every cell on every frame, and
  /// rebuilding it there would allocate thousands of lists a second.
  late final List<int> _dotOfCell = () {
    final map = List<int>.filled(puzzle.cellCount, -1);
    for (var dot = 0; dot < puzzle.dots.length; dot++) {
      final seeds = puzzle.seedCells(dot);
      if (seeds.length == 1) map[seeds.single] = dot;
    }
    return map;
  }();

  /// The dot a cell holds, if any.
  int? dotAt(int row, int col) {
    final dot = _dotOfCell[puzzle.index(row, col)];
    return dot == -1 ? null : dot;
  }

  /// One colour per region, spread by the golden angle so neighbouring regions
  /// do not land on neighbouring colours.
  ///
  /// Cached because it is asked for once per cell per frame, and rebuilt only
  /// when the theme flips between light and dark.
  List<Color>? _regionColours;
  bool? _regionColoursDark;

  Color regionColour(int dot, PuzzlePalette palette) {
    final dark = palette.bed.computeLuminance() < 0.5;
    if (_regionColours == null || _regionColoursDark != dark) {
      _regionColoursDark = dark;
      _regionColours = [
        for (var index = 0; index < puzzle.dots.length; index++)
          HSLColor.fromAHSL(
            1,
            (index * 137.508) % 360,
            0.45,
            dark ? 0.40 : 0.68,
          ).toColor(),
      ];
    }
    return _regionColours![dot];
  }

  // ------------------------------------------------------------------- rules

  @override
  List<PuzzleMove<GalaxiesState>> movesFor(ElementRef element) {
    if (!isCell(element)) return const [];
    final dot = dotAt(element.a, element.b);
    if (dot == null) return const [];

    // Dragging a dot onto a cell paints that cell. Only the cells the pair
    // rule allows are offered, so a drop is never refused.
    return [
      for (var target = 0; target < state.owner.length; target++)
        if (target != puzzle.index(element.a, element.b) &&
            state.owner[target] == -1 &&
            _engine.paint(puzzle, state.owner, target, dot) != null)
          PuzzleMove<GalaxiesState>(
            kind: MoveKind.place,
            source: element,
            target: cell(target ~/ cols, target % cols),
            apply: (current) => _paint(current, target, dot),
          ),
    ];
  }

  static const GalaxiesEngine _engine = GalaxiesEngine();

  GalaxiesState _paint(GalaxiesState current, int cell, int dot) {
    final cells = _engine.paint(puzzle, current.owner, cell, dot);
    if (cells == null) return current;
    final owner = [...current.owner];
    for (final painted in cells) {
      owner[painted] = dot;
    }
    return current.copyWith(
      owner: owner,
      activeDot: dot,
      clearHint: true,
      isSolved: _engine.isSolved(puzzle, owner),
    );
  }

  @override
  PuzzleMove<GalaxiesState>? tapMove(ElementRef element) {
    if (!isCell(element)) return null;
    final row = element.a;
    final col = element.b;
    final cellIndex = puzzle.index(row, col);
    final dot = dotAt(row, col);

    if (dot != null) {
      return PuzzleMove<GalaxiesState>(
        kind: MoveKind.select,
        source: element,
        apply: (current) => current.copyWith(
          activeDot: current.activeDot == dot ? null : dot,
          clearActive: current.activeDot == dot,
          clearHint: true,
        ),
      );
    }

    final active = state.activeDot;
    if (active != null) {
      if (_engine.paint(puzzle, state.owner, cellIndex, active) == null) {
        return null;
      }
      return PuzzleMove<GalaxiesState>(
        kind: MoveKind.place,
        source: element,
        apply: (current) => _paint(current, cellIndex, active),
      );
    }

    if (state.owner[cellIndex] == -1) return null;
    if (puzzle.seedCells(state.owner[cellIndex]).contains(cellIndex)) return null;
    return PuzzleMove<GalaxiesState>(
      kind: MoveKind.clear,
      source: element,
      apply: (current) => _clear(current, cellIndex),
    );
  }

  GalaxiesState _clear(GalaxiesState current, int cell) {
    final dot = current.owner[cell];
    if (dot == -1) return current;
    if (puzzle.seedCells(dot).contains(cell)) return current;
    final owner = [...current.owner];
    owner[cell] = -1;
    final mirror = puzzle.mirrorOf(cell, dot);
    if (mirror != null && mirror != cell) owner[mirror] = -1;
    return current.copyWith(owner: owner, clearHint: true);
  }

  // ------------------------------------------------------------------- paint

  @override
  void paintCell(PuzzleCanvas canvas, GalaxiesState state, int row, int col) {
    final palette = canvas.palette;
    final element = cell(row, col);
    final rect = cellRect(row, col);
    final cellIndex = puzzle.index(row, col);
    final dot = state.owner[cellIndex];
    final hint = state.hint;

    if (dot == -1) {
      canvas.cell(rect, fill: palette.surface.withValues(alpha: 0.55));
    } else {
      canvas.cell(
        rect,
        fill: regionColour(dot, palette).withValues(alpha: 0.85),
      );
    }

    // The boundary between two regions, drawn on the side that changes owner.
    final stroke = palette.ink.withValues(alpha: 0.55);
    for (var side = 0; side < 4; side++) {
      final (dr, dc) = switch (side) {
        0 => (-1, 0),
        1 => (1, 0),
        2 => (0, -1),
        _ => (0, 1),
      };
      final otherRow = row + dr;
      final otherCol = col + dc;
      final other = inBounds(otherRow, otherCol)
          ? state.owner[puzzle.index(otherRow, otherCol)]
          : -2;
      if (other == dot) continue;
      final (from, to) = switch (side) {
        0 => (rect.topLeft, rect.topRight),
        1 => (rect.bottomLeft, rect.bottomRight),
        2 => (rect.topLeft, rect.bottomLeft),
        _ => (rect.topRight, rect.bottomRight),
      };
      canvas.line(from, to, color: stroke, width: 1.6);
    }

    // The hint ring, on the cell the rules can prove.
    if (hint != null && hint.cell == cellIndex) {
      canvas.cell(
        rect,
        stroke: palette.primary,
        strokeWidth: 3,
        radius: 6,
      );
    }

    if (dotAt(row, col) != null) {
      _paintDot(canvas, dotAt(row, col)!, dot, element);
    }
  }

  void _paintDot(
    PuzzleCanvas canvas,
    int dot,
    int owner,
    ElementRef element,
  ) {
    final palette = canvas.palette;
    final centre = dotCentre(puzzle.dots[dot]);
    final picked = state.activeDot == dot;
    final scale = canvas.size.shortestSide;
    final radius = math.min(cellWidth, cellHeight) * scale * 0.22;

    if (picked) {
      canvas.ring(
        centre,
        radius * 1.9,
        color: palette.primary.withValues(alpha: 0.55),
        width: 2.5,
      );
    }
    canvas.dot(centre, radius, color: picked ? palette.primary : palette.ink);
    canvas.dot(centre, radius * 0.42, color: palette.surface);
  }
}
