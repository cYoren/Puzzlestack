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

  void _paintTube(PuzzleCanvas canvas, WaterSortState state, int index) {
    final palette = canvas.palette;
    final bounds = boundsOf(tube(index))!;
    final selected = state.selectedTubeIndex == index;
    final zone = canvas.highlight.targetAlpha(tube(index));
    final colors = state.tubes[index];

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
              : palette.outline,
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
