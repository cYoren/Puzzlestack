import 'package:flutter/material.dart';

import '../../../core/board/puzzle_board.dart';
import '../../../core/board/puzzle_marks.dart';
import 'bricks_provider.dart';
import 'bricks_puzzle.dart';

/// Bricks on the board contract.
///
/// A honeycomb, drawn as honeycomb: rows of pointy-top hexagons, each row half a
/// cell further right than the one above it, touching along their edges. The
/// board is a `PuzzleBoard` and not a [GridBoard] because a `GridBoard`'s cell
/// is a rectangle, and a rectangle is the one shape this puzzle is not — slanting
/// squares would put the neighbours a rule talks about somewhere else on the
/// screen than the rules mean. The lattice itself lives in
/// [BricksLattice] (pure Dart, next to the rules), so the six neighbours the
/// solver sees and the six hexagons a player sees are the same six.
///
/// What the board paints:
///
///  * a shaded cell is a **filled hexagon** ([MarkRole.structure], the house
///    colour for a solid object);
///  * a numbered cell prints its count and is never shaded, so the number and
///    the shade can never be two marks fighting in one cell;
///  * a cell that breaks a rule is outlined in the error colour, and the hinted
///    cell wears the same ring, heavier — one colour, one meaning: look here.
class BricksBoard extends PuzzleBoard<BricksState> {
  BricksBoard({required this.state});

  @override
  final BricksState state;

  BricksLattice get lattice => state.puzzle.lattice;

  @override
  bool get isSolved => state.isSolved;

  static const String cellKind = 'cell';

  /// The board box is as tall, relative to its width, as the honeycomb is.
  @override
  double get aspectRatio => lattice.height / lattice.width;

  late final Set<int> _conflicts = state.conflicts;

  ElementRef cellRef(int cell) => ElementRef(cellKind, cell);

  bool isCell(ElementRef element) => element.kind == cellKind;

  @override
  List<ElementRef> get elements => [
        for (var cell = 0; cell < state.cellCount; cell++) cellRef(cell),
      ];

  // --------------------------------------------------------------- geometry

  /// Where a cell's centre sits in the board box, 0..1 across each axis.
  ///
  /// Width and height are normalised separately, which is only safe because
  /// [aspectRatio] gives the box the honeycomb's own proportions: one unit of
  /// `x` and one unit of `y` are then the same number of pixels.
  Offset centreOf(int cell) => Offset(
        (lattice.centreX(cell) - lattice.left) / lattice.width,
        (lattice.centreY(cell) - lattice.top) / lattice.height,
      );

  /// Half a hexagon's width, across the board box.
  double get _halfWidth => BricksLattice.pitchX / 2 / lattice.width;

  /// Half a hexagon's height, down the board box.
  double get _halfHeight => BricksLattice.radius / lattice.height;

  /// The hexagon of [cell]: point at the top and bottom, flat sides left and
  /// right, which is the shape whose neighbours are the C's six.
  Path hexagon(int cell) {
    final centre = centreOf(cell);
    final dx = _halfWidth;
    final dy = _halfHeight;
    return Path()
      ..moveTo(centre.dx, centre.dy - dy)
      ..lineTo(centre.dx + dx, centre.dy - dy / 2)
      ..lineTo(centre.dx + dx, centre.dy + dy / 2)
      ..lineTo(centre.dx, centre.dy + dy)
      ..lineTo(centre.dx - dx, centre.dy + dy / 2)
      ..lineTo(centre.dx - dx, centre.dy - dy / 2)
      ..close();
  }

  @override
  Rect? boundsOf(ElementRef element) {
    if (!isCell(element)) return null;
    final centre = centreOf(element.a);
    return Rect.fromLTRB(
      centre.dx - _halfWidth,
      centre.dy - _halfHeight,
      centre.dx + _halfWidth,
      centre.dy + _halfHeight,
    );
  }

  /// The cell under a point, by the hexagon and not by its box.
  ///
  /// The default hit test inflates a rectangle, and rectangles of neighbouring
  /// hexagons overlap in the corners of the honeycomb: on a slanted lattice that
  /// would let a tap on one cell select the cell above and to the side of it.
  @override
  ElementRef? hitTest(Offset point) {
    final x = lattice.left + point.dx * lattice.width;
    final y = lattice.top + point.dy * lattice.height;
    for (var cell = 0; cell < state.cellCount; cell++) {
      final dx = (x - lattice.centreX(cell)).abs();
      final dy = (y - lattice.centreY(cell)).abs();
      if (dy > BricksLattice.radius) continue;
      // Pointy-top hexagon: full half-width along the middle band, tapering to
      // the top and bottom points.
      final limit = dy <= BricksLattice.radius / 2
          ? BricksLattice.pitchX / 2
          : BricksLattice.pitchX /
              2 *
              2 *
              (BricksLattice.radius - dy) /
              BricksLattice.radius;
      if (dx <= limit) return cellRef(cell);
    }
    return null;
  }

  // ------------------------------------------------------------------- moves

  @override
  List<PuzzleMove<BricksState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<BricksState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    // A numbered cell is unshaded by rule 4; a tap on it is a no-op rather than
    // an error, so the board does not tell the player off for reading a clue.
    if (state.puzzle.hasClue(element.a)) return null;
    return PuzzleMove<BricksState>(
      kind: MoveKind.toggle,
      source: element,
      apply: (current) => current,
    );
  }

  // ------------------------------------------------------------------- paint

  @override
  void paint(PuzzleCanvas canvas, BricksState state) {
    canvas.bed();
    for (var cell = 0; cell < state.cellCount; cell++) {
      final element = cellRef(cell);
      if (canvas.isHidden(element)) continue;
      paintCell(canvas, state, cell);
    }
  }

  @override
  void paintElement(
      PuzzleCanvas canvas, BricksState state, ElementRef element) {
    if (isCell(element)) paintCell(canvas, state, element.a);
  }

  void paintCell(PuzzleCanvas canvas, BricksState state, int cell) {
    final palette = canvas.palette;
    final marks = PuzzleMarks(canvas);
    final path = hexagon(cell);
    final shaded = state.values[cell] == kBricksShaded;
    final clue = state.puzzle.clue(cell);

    canvas.path(
      path,
      fill: shaded ? marks.color(MarkRole.structure) : palette.surface,
      // A hairline, not a gap: hexagons tile, so the edge is shared and a gap
      // would read as a second, smaller shape inside every cell.
      stroke: palette.line,
      width: 1.0,
    );

    if (clue != kBricksNoClue) {
      // The number is the whole clue, and a number is only known by counting,
      // so it is printed in ink whatever the theme.
      marks.label(
        boundsOf(cellRef(cell))!,
        '$clue',
        role: MarkRole.ink,
        fraction: 0.44,
      );
    }

    if (_conflicts.contains(cell)) {
      canvas.path(path, stroke: palette.error, width: 2.5);
    }
    if (state.hintCell == cell) {
      canvas.path(path, stroke: palette.error, width: 3.5);
    }
  }
}
