import 'package:flutter/material.dart';

import '../../../core/board/puzzle_board.dart';
import 'slitherlink_provider.dart';

/// Slitherlink on the board contract.
///
/// Tap an edge to toggle it. Drag from one dot to its neighbour to draw the
/// edge between them — the loop is drawn by hand, one segment at a time, and
/// dragging over a drawn edge erases it.
class SlitherlinkBoard extends PuzzleBoard<SlitherlinkState> {
  SlitherlinkBoard({required this.state});

  /// Board margin, in normalised units, so the outer dots are not clipped.
  static const double margin = 0.06;

  /// The dots are the drag handles; the edges are the tap targets.
  static const double vertexHit = 0.07;
  static const double edgeHit = 0.055;

  @override
  final SlitherlinkState state;

  int get size => state.level.size;

  double get step => (1 - 2 * margin) / size;

  @override
  bool get isSolved => state.isSolved;

  // --------------------------------------------------------------- geometry

  Offset _vertex(int row, int col) =>
      Offset(margin + col * step, margin + row * step);

  static ElementRef vertex(int row, int col) => ElementRef('vertex', row, col);

  static ElementRef hEdge(int row, int col) => ElementRef('edgeH', row, col);

  static ElementRef vEdge(int row, int col) => ElementRef('edgeV', row, col);

  @override
  List<ElementRef> get elements => [
        for (var row = 0; row <= size; row++)
          for (var col = 0; col < size; col++) hEdge(row, col),
        for (var row = 0; row < size; row++)
          for (var col = 0; col <= size; col++) vEdge(row, col),
        for (var row = 0; row <= size; row++)
          for (var col = 0; col <= size; col++) vertex(row, col),
      ];

  @override
  Rect? boundsOf(ElementRef element) {
    switch (element.kind) {
      case 'vertex':
        return Rect.fromCenter(
          center: _vertex(element.a, element.b),
          width: vertexHit,
          height: vertexHit,
        );
      case 'edgeH':
        final from = _vertex(element.a, element.b);
        final to = _vertex(element.a, element.b + 1);
        return Rect.fromLTRB(
          from.dx,
          from.dy - edgeHit / 2,
          to.dx,
          to.dy + edgeHit / 2,
        );
      case 'edgeV':
        final from = _vertex(element.a, element.b);
        final to = _vertex(element.a + 1, element.b);
        return Rect.fromLTRB(
          from.dx - edgeHit / 2,
          from.dy,
          to.dx + edgeHit / 2,
          to.dy,
        );
    }
    return null;
  }

  bool _drawn(ElementRef edge) => edge.kind == 'edgeH'
      ? state.currentHEdges[edge.a][edge.b]
      : state.currentVEdges[edge.a][edge.b];

  /// The far end of an edge, which is where a drag has to land.
  ElementRef _farEnd(ElementRef edge) => edge.kind == 'edgeH'
      ? vertex(edge.a, edge.b + 1)
      : vertex(edge.a + 1, edge.b);

  // ------------------------------------------------------------------- rules

  SlitherlinkState _set(SlitherlinkState current, ElementRef edge, bool value) {
    final horizontal = [
      for (final line in current.currentHEdges) [...line],
    ];
    final vertical = [
      for (final line in current.currentVEdges) [...line],
    ];
    if (edge.kind == 'edgeH') {
      horizontal[edge.a][edge.b] = value;
    } else {
      vertical[edge.a][edge.b] = value;
    }
    return current.copyWith(
      currentHEdges: horizontal,
      currentVEdges: vertical,
    );
  }

  @override
  List<PuzzleMove<SlitherlinkState>> movesFor(ElementRef element) {
    if (element.kind != 'vertex') return const [];
    final row = element.a;
    final col = element.b;
    final moves = <PuzzleMove<SlitherlinkState>>[];

    void add(ElementRef edge) {
      final drawn = _drawn(edge);
      moves.add(
        PuzzleMove<SlitherlinkState>(
          kind: drawn ? MoveKind.clear : MoveKind.place,
          source: element,
          target: _farEnd(edge),
          apply: (current) => _set(current, edge, !drawn),
        ),
      );
    }

    if (row > 0) add(vEdge(row - 1, col));
    if (row < size) add(vEdge(row, col));
    if (col > 0) add(hEdge(row, col - 1));
    if (col < size) add(hEdge(row, col));
    return moves;
  }

  @override
  PuzzleMove<SlitherlinkState>? tapMove(ElementRef element) {
    if (element.kind == 'vertex') return null;
    final drawn = _drawn(element);
    return PuzzleMove<SlitherlinkState>(
      kind: drawn ? MoveKind.clear : MoveKind.place,
      source: element,
      apply: (current) => _set(current, element, !drawn),
    );
  }

  // ------------------------------------------------------------------- paint

  @override
  void paint(PuzzleCanvas canvas, SlitherlinkState state) {
    final palette = canvas.palette;
    canvas.bed();

    final cell = canvas.size.width * step;

    // Clues. A clue the loop has already broken turns red and gets a ring, so
    // "no mistakes are shown" is not a thing the board can do any more.
    final broken = {
      for (final conflict in state.conflicts) (conflict.row, conflict.col),
    };
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final clue = state.level.clues[row][col];
        if (clue == null) continue;
        final centre = _vertex(row, col) + Offset(step / 2, step / 2);
        final isBroken = broken.contains((row, col));
        if (isBroken) {
          canvas.ring(centre, step * 0.34, color: palette.error, width: 2);
        }
        canvas.text(
          '$clue',
          Rect.fromCenter(center: centre, width: step, height: step),
          fontSize: cell * 0.42,
          weight: FontWeight.w900,
          color: isBroken ? palette.error : palette.ink,
        );
      }
    }

    for (final edge in elements) {
      if (edge.kind == 'vertex' || canvas.isHidden(edge)) continue;
      _paintEdge(canvas, edge);
    }

    for (var row = 0; row <= size; row++) {
      for (var col = 0; col <= size; col++) {
        final dot = vertex(row, col);
        if (canvas.isHidden(dot)) continue;
        canvas.dot(_vertex(row, col), cell * 0.055, color: palette.ink);
      }
    }
  }

  bool _isHint(ElementRef edge) {
    final hint = state.hintEdge;
    if (hint == null) return false;
    if (hint.horizontal) {
      return edge.kind == 'edgeH' && edge.a == hint.row && edge.b == hint.col;
    }
    return edge.kind == 'edgeV' && edge.a == hint.row && edge.b == hint.col;
  }

  void _paintEdge(PuzzleCanvas canvas, ElementRef edge) {
    final palette = canvas.palette;
    final bounds = boundsOf(edge)!;
    final zone = canvas.highlight.targetAlpha(edge);
    final drawn = _drawn(edge);

    if (zone > 0) {
      canvas.cell(
        bounds,
        fill: palette.primary.withValues(alpha: 0.08 * zone * 2),
        radius: 4,
      );
    }

    final vertical = edge.kind == 'edgeV';
    final start = vertical ? bounds.topCenter : bounds.centerLeft;
    final end = vertical ? bounds.bottomCenter : bounds.centerRight;

    final hinted = _isHint(edge);
    if (drawn) {
      canvas.line(
        start,
        end,
        color: state.isSolved ? palette.success : palette.primary,
        width: 3,
      );
    } else {
      canvas.line(
        start,
        end,
        color: hinted
            ? palette.success
            : palette.line,
        width: hinted ? 3 : 1.5,
      );
    }
  }

  @override
  void paintElement(
    PuzzleCanvas canvas,
    SlitherlinkState state,
    ElementRef element,
  ) {
    if (element.kind == 'vertex') {
      canvas.dot(
        _vertex(element.a, element.b),
        canvas.size.width * step * 0.07,
        color: canvas.palette.primary,
      );
      return;
    }
    _paintEdge(canvas, element);
  }
}
