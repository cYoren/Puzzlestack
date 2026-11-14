import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/board/puzzle_board.dart';
import 'water_sort_engine.dart';
import 'water_sort_provider.dart';

/// Water Sort on the board contract.
///
/// Tap a tube to pick it up, tap another to pour. Drag a tube onto another and
/// the pour happens on release — same rules, same move, one gesture engine.
class WaterSortBoard extends PuzzleBoard<WaterSortState> {
  WaterSortBoard({required this.state});

  static const int columns = 4;
  static const double tubeWidth = 0.17;
  static const double tubeHeight = 0.42;
  static const double left = 0.06;
  static const double top = 0.04;
  static const double gapX = 0.235;
  static const double gapY = 0.52;

  @override
  final WaterSortState state;

  @override
  double get aspectRatio => 1.05;

  @override
  bool get isSolved => state.isSolved;

  static ElementRef tube(int index) => ElementRef('tube', index);

  @override
  List<ElementRef> get elements =>
      [for (var i = 0; i < state.tubes.length; i++) tube(i)];

  @override
  Rect? boundsOf(ElementRef element) {
    if (element.kind != 'tube') return null;
    final index = element.a;
    final column = index % columns;
    final row = index ~/ columns;
    return Rect.fromLTWH(
      left + column * gapX,
      top + row * gapY,
      tubeWidth,
      tubeHeight,
    );
  }

  // ------------------------------------------------------------------- rules

  WaterSortState _pour(WaterSortState current, int from, int to) {
    final engine = WaterSortEngine();
    final tubes = [
      for (final tube in current.tubes) [...tube],
    ];
    if (!engine.canPour(tubes[from], tubes[to])) {
      return current.copyWith(clearSelection: true);
    }
    engine.pour(tubes[from], tubes[to]);
    return current.copyWith(tubes: tubes, clearSelection: true);
  }

  bool _canPour(int from, int to) {
    if (from == to) return false;
    final engine = WaterSortEngine();
    return engine.canPour(state.tubes[from], state.tubes[to]);
  }

  @override
  List<PuzzleMove<WaterSortState>> movesFor(ElementRef element) {
    if (element.kind != 'tube') return const [];
    final from = element.a;
    return [
      for (var to = 0; to < state.tubes.length; to++)
        if (_canPour(from, to))
          PuzzleMove<WaterSortState>(
            kind: MoveKind.place,
            source: element,
            target: tube(to),
            apply: (current) => _pour(current, from, to),
          ),
    ];
  }

  @override
  PuzzleMove<WaterSortState>? tapMove(ElementRef element) {
    if (element.kind != 'tube' || state.isSolved) return null;
    final index = element.a;
    final selected = state.selectedTubeIndex;

    if (selected == null) {
      if (state.tubes[index].isEmpty) return null;
      return PuzzleMove<WaterSortState>(
        kind: MoveKind.select,
        source: element,
        apply: (current) => current.copyWith(selectedTubeIndex: index),
      );
    }

    if (selected == index) {
      return PuzzleMove<WaterSortState>(
        kind: MoveKind.select,
        source: element,
        apply: (current) => current.copyWith(clearSelection: true),
      );
    }

    if (!_canPour(selected, index)) {
      return PuzzleMove<WaterSortState>(
        kind: MoveKind.select,
        source: element,
        apply: (current) => current.copyWith(clearSelection: true),
      );
    }

    return PuzzleMove<WaterSortState>(
      kind: MoveKind.place,
      source: element,
      target: tube(index),
      apply: (current) => _pour(current, selected, index),
    );
  }

  // ------------------------------------------------------------------- paint

  @override
  void paint(PuzzleCanvas canvas, WaterSortState state) {
    canvas.bed();
    for (final element in elements) {
      if (canvas.isHidden(element)) continue;
      _paintTube(canvas, state, element.a);
    }
  }

  // -------------------------------------------------------------- transition

  /// The pour that turned [from] into [to], if there was one.
  ({int from, int to, Color colour, int count})? _pourBetween(
    WaterSortState from,
    WaterSortState to,
  ) {
    if (from.tubes.length != to.tubes.length) return null;
    var source = -1;
    var destination = -1;
    var count = 0;
    Color? colour;
    for (var i = 0; i < from.tubes.length; i++) {
      final before = from.tubes[i];
      final after = to.tubes[i];
      if (after.length < before.length) {
        source = i;
        count = before.length - after.length;
        colour = before.last;
      } else if (after.length > before.length) {
        destination = i;
      }
    }
    if (source < 0 || destination < 0 || count <= 0 || colour == null) {
      return null;
    }
    // The board only animates a real pour: the destination gained exactly what
    // the source lost, in the same colour. A reset or a new level is not a pour,
    // and a new level can lose and gain the same number of cells by accident.
    if (to.tubes[source].length + count != from.tubes[source].length) {
      return null;
    }
    if (to.tubes[destination].length !=
        from.tubes[destination].length + count) {
      return null;
    }
    final poured = from.tubes[source].sublist(from.tubes[source].length - count);
    final gained = to.tubes[destination].sublist(from.tubes[destination].length);
    if (poured.length != gained.length) return null;
    for (var i = 0; i < poured.length; i++) {
      if (poured[i] != gained[i]) return null;
    }
    return (from: source, to: destination, colour: colour, count: count);
  }

  @override
  Duration? transitionFor(WaterSortState from, WaterSortState to) {
    if (_pourBetween(from, to) == null) return null;
    return const Duration(milliseconds: 360);
  }

  @override
  void paintTransition(
    PuzzleCanvas canvas,
    WaterSortState from,
    WaterSortState to,
    double t,
  ) {
    final pour = _pourBetween(from, to);
    if (pour == null) {
      paint(canvas, to);
      return;
    }

    final eased = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
    canvas.bed();
    for (var index = 0; index < to.tubes.length; index++) {
      var colours = to.tubes[index];
      var partial = 0.0;
      Color? partialColour;

      if (index == pour.from) {
        // The liquid still leaving: the poured amount shrinks to nothing.
        partialColour = pour.colour;
        partial = (1 - eased) * pour.count;
      } else if (index == pour.to) {
        // The liquid arriving: the poured amount grows from nothing.
        partialColour = pour.colour;
        final kept = from.tubes[index].length;
        colours = to.tubes[index].sublist(0, kept);
        partial = eased * pour.count;
      }

      _paintTubeContents(
        canvas,
        index,
        colours,
        partialUnits: partial,
        partialColour: partialColour,
      );
    }

    _paintStream(canvas, from, pour.from, pour.to, pour.colour, eased);
  }

  void _paintStream(
    PuzzleCanvas canvas,
    WaterSortState state,
    int source,
    int destination,
    Color colour,
    double t,
  ) {
    final arc = math.sin(math.pi * t);
    if (arc <= 0.02) return;
    final from = boundsOf(tube(source))!;
    final to = boundsOf(tube(destination))!;
    final start = Offset(from.center.dx, from.top + 0.01);
    final end = Offset(to.center.dx, to.top + 0.01);
    final lift = math.max(0.06, (start.dx - end.dx).abs() * 0.12 + 0.08);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        (start.dx + end.dx) / 2,
        math.min(start.dy, end.dy) - lift,
        end.dx,
        end.dy,
      );

    canvas.path(
      path,
      stroke: colour.withValues(alpha: 0.9),
      width: from.width * canvas.size.width * 0.16,
    );
    canvas.dot(
      Offset((start.dx + end.dx) / 2,
          math.min(start.dy, end.dy) - lift * 0.55),
      from.width * canvas.size.width * 0.06,
      color: colour.withValues(alpha: 0.9),
    );
  }

  void _paintTube(
    PuzzleCanvas canvas,
    WaterSortState state,
    int index,
  ) {
    _paintTubeContents(
      canvas,
      index,
      state.tubes[index],
      selected: state.selectedTubeIndex == index,
      zone: canvas.highlight.targetAlpha(tube(index)),
    );
  }

  /// One tube, with an optional fractional layer on top: the pour animation
  /// needs a half-full segment, which a list of colours cannot express.
  void _paintTubeContents(
    PuzzleCanvas canvas,
    int index,
    List<Color> colors, {
    double partialUnits = 0,
    Color? partialColour,
    bool selected = false,
    double zone = 0,
  }) {
    final palette = canvas.palette;
    final bounds = boundsOf(tube(index))!;
    final widthPx = bounds.width * canvas.size.width;
    final radius = widthPx / 2;
    final body = selected ? bounds.translate(0, -0.02) : bounds;

    canvas.rrect(
      body,
      fill: palette.surface,
      stroke: zone > 0
          ? palette.primary.withValues(alpha: 0.35 + 0.65 * zone)
          : selected
              ? palette.primary
              : palette.line,
      strokeWidth: selected || zone > 0 ? 2.5 : 1.5,
      topRadius: 4,
      bottomRadius: radius,
    );

    final inner = body.deflate(0.006);
    final segment = inner.height / WaterSortEngine.tubeCapacity;
    for (var level = 0; level < colors.length; level++) {
      final bottom = inner.bottom - level * segment;
      final isBottom = level == 0;
      canvas.rrect(
        Rect.fromLTRB(inner.left, bottom - segment, inner.right, bottom),
        fill: colors[level],
        bottomRadius: isBottom ? radius - 2 : 0,
      );
    }

    if (partialColour != null && partialUnits > 0) {
      final top = inner.bottom - colors.length * segment;
      final height =
          math.min(segment * partialUnits, inner.height - colors.length * segment);
      if (height > 0) {
        canvas.rrect(
          Rect.fromLTRB(inner.left, top - height, inner.right, top),
          fill: partialColour,
          topRadius: 2,
        );
      }
    }

    if (colors.length == WaterSortEngine.tubeCapacity &&
        colors.every((color) => color == colors.first)) {
      canvas.rrect(
        body,
        stroke: palette.success,
        strokeWidth: 2.5,
        topRadius: 4,
        bottomRadius: radius,
      );
    }
  }

  @override
  void paintElement(
    PuzzleCanvas canvas,
    WaterSortState state,
    ElementRef element,
  ) {
    if (element.kind == 'tube') _paintTube(canvas, state, element.a);
  }
}
