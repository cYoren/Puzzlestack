import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../utils/design_system.dart';

/// Immutable state of one puzzle.
///
/// A puzzle is rules plus a generator. Its state is a value: applying a move
/// returns a new state, and nothing in here knows about widgets, providers or
/// gestures.
abstract class PuzzleState {
  const PuzzleState();
}

/// A named, hit-testable thing on a board.
///
/// [kind] says what it is (`cell`, `digit`, `edge`, `vertex`, `tube`); [a] and
/// [b] are the puzzle's own coordinates. Two refs are equal when all three
/// match, so a move can name its destination without carrying geometry around.
@immutable
class ElementRef {
  const ElementRef(this.kind, this.a, [this.b = -1]);

  final String kind;
  final int a;
  final int b;

  @override
  bool operator ==(Object other) =>
      other is ElementRef && other.kind == kind && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(kind, a, b);

  @override
  String toString() => '$kind($a,$b)';
}

/// What a move does. Chooses the verb it emits and the colour it paints with.
enum MoveKind { select, place, clear, toggle }

/// One legal transition, optionally to a spatial destination.
///
/// A move with a [target] can be dragged: the engine floats the source element,
/// reveals the target as a drop zone and snaps into it. A move without a target
/// resolves on tap. That is the whole input surface of a puzzle.
@immutable
class PuzzleMove<S extends PuzzleState> {
  const PuzzleMove({
    required this.kind,
    required this.source,
    required this.apply,
    this.target,
  });

  final MoveKind kind;
  final ElementRef source;
  final ElementRef? target;
  final S Function(S state) apply;

  bool get isDraggable => target != null;

  @override
  String toString() => '${kind.name} $source->${target ?? '-'}';
}

/// What the engine is doing right now, handed to the puzzle so it can paint it.
@immutable
class BoardHighlight {
  const BoardHighlight({
    this.pressed,
    this.pressScale = 1.0,
    this.lifted,
    this.liftOffset = Offset.zero,
    this.liftScale = 1.0,
    this.targets = const <ElementRef>{},
    this.targetOpacity = 0.0,
    this.hover,
    this.invalidOpacity = 0.0,
    this.pops = const <ElementRef, double>{},
  });

  /// The element being pressed, drawn a hair smaller.
  final ElementRef? pressed;
  final double pressScale;

  /// The element under the finger, drawn floating instead of in place.
  final ElementRef? lifted;
  final Offset liftOffset;
  final double liftScale;

  /// Every legal destination of the current drag.
  final Set<ElementRef> targets;

  /// 0..1 fade for the drop zones.
  final double targetOpacity;

  /// The destination the finger is over.
  final ElementRef? hover;

  /// 0..1 recoil pulse after an illegal drop.
  final double invalidOpacity;

  /// Win cascade progress per element, 0..1.
  final Map<ElementRef, double> pops;

  bool get isDragging => lifted != null;
  bool get isCelebrating => pops.isNotEmpty;

  /// How strongly a drop zone should be tinted. Legal targets sit at half
  /// strength so the one under the finger reads as the choice.
  double targetAlpha(ElementRef element) {
    if (!targets.contains(element)) return 0.0;
    final strength = hover == element ? 1.0 : 0.5;
    return (targetOpacity * strength).clamp(0.0, 1.0).toDouble();
  }

  double popOf(ElementRef element) => pops[element] ?? 0.0;

  static const BoardHighlight none = BoardHighlight();
}

/// The house colours, resolved once per frame.
///
/// Three of these exist so a board has something to paint *structure* with: a
/// wall, a blackened cell, a wire, a grid line. Painting those with [ink] is
/// what made boards either glaring (near-white ink on a dark surface) or
/// invisible (near-black ink on a dark surface), depending on the theme. The
/// structure colours are mid-tones in both themes: dark enough on paper, light
/// enough on a dark surface, and never pure black or pure white.
class PuzzlePalette {
  const PuzzlePalette({
    required this.bed,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.primary,
    required this.error,
    required this.success,
    required this.outline,
    required this.structure,
    required this.line,
  });

  final Color bed;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color primary;
  final Color error;
  final Color success;
  final Color outline;

  /// Walls, filled cells, pipes: anything that is a solid object on the board.
  final Color structure;

  /// Cell borders and hairlines. Visible in both themes without shouting.
  final Color line;

  factory PuzzlePalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return PuzzlePalette(
      bed: dark ? DesignSystem.darkBackground : DesignSystem.background,
      surface: scheme.surface,
      ink: scheme.onSurface,
      muted: scheme.onSurface.withValues(alpha: 0.55),
      primary: DesignSystem.primary,
      error: DesignSystem.error,
      success: DesignSystem.success,
      outline: scheme.outline,
      structure: dark
          ? const Color(0xFF7C7C8A)
          : const Color(0xFF2A2A33),
      line: dark ? const Color(0xFF3E3E4A) : const Color(0xFFC3C8D2),
    );
  }
}

/// The only drawing surface a puzzle gets.
///
/// Geometry is expressed in **normalised** coordinates (0..1 across the board
/// box) so a puzzle never needs to know its pixel size, and so the same board
/// paints correctly at 320dp and on a tablet. Everything else — radii, stroke
/// weights, colours — comes from here, which is what keeps 200 puzzles looking
/// like one app.
class PuzzleCanvas {
  PuzzleCanvas({
    required this.canvas,
    required this.size,
    required this.palette,
    this.highlight = BoardHighlight.none,
  });

  final Canvas canvas;
  final Size size;
  final PuzzlePalette palette;
  final BoardHighlight highlight;

  Rect get boardRect => Offset.zero & size;

  Rect toPixels(Rect normalized) => Rect.fromLTRB(
        normalized.left * size.width,
        normalized.top * size.height,
        normalized.right * size.width,
        normalized.bottom * size.height,
      );

  Offset toPixelOffset(Offset normalized) =>
      Offset(normalized.dx * size.width, normalized.dy * size.height);

  /// A font size that fits a normalised cell: [fraction] of its height, in dp.
  ///
  /// Boards work in normalised coordinates, so a cell's `rect.height` is a
  /// fraction of the board (0.15, not 40). Using it directly as a font size
  /// draws a number less than one pixel tall, which is how Futoshiki, Kurodoko,
  /// Dominosa, Skyscrapers and Twiddle came to look blank.
  double fontSizeFor(Rect normalized, double fraction) {
    final px = normalized.height * size.height * fraction;
    assert(
      px >= 4.0,
      'A board font of ${px.toStringAsFixed(2)}dp is too small to read. '
      'Scale the fraction by the board size (PuzzleCanvas.fontSizeFor).',
    );
    return px;
  }

  /// The same, but bounded by the cell's shorter side, for square-ish text.
  double fontSizeForSquare(Rect normalized, double fraction) {
    final px = math.min(
          normalized.width * size.width,
          normalized.height * size.height,
        ) *
        fraction;
    assert(
      px >= 4.0,
      'A board font of ${px.toStringAsFixed(2)}dp is too small to read. '
      'Scale the fraction by the board size (PuzzleCanvas.fontSizeForSquare).',
    );
    return px;
  }

  bool isLifted(ElementRef element) => highlight.lifted == element;

  bool isPopping(ElementRef element) => highlight.pops.containsKey(element);

  /// True when the engine is drawing this element itself.
  bool isHidden(ElementRef element) =>
      isLifted(element) || isPopping(element) || highlight.pressed == element;

  /// The board bed: one object, not a tray of tiles.
  void bed({Color? color}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        boardRect,
        const Radius.circular(DesignSystem.radiusMD),
      ),
      Paint()..color = color ?? palette.bed,
    );
  }

  void cell(
    Rect normalized, {
    Color? fill,
    Color? stroke,
    double strokeWidth = 1.5,
    double radius = DesignSystem.radiusXS,
  }) {
    final rect = toPixels(normalized);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    if (fill != null) {
      canvas.drawRRect(rrect, Paint()..color = fill);
    }
    if (stroke != null && strokeWidth > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = stroke,
      );
    }
  }

  /// A rounded rectangle with independent top and bottom radii, for elements
  /// that are objects rather than cells (a tube, a tile).
  void rrect(
    Rect normalized, {
    Color? fill,
    Color? stroke,
    double strokeWidth = 1.5,
    double topRadius = 0,
    double bottomRadius = 0,
  }) {
    final rect = toPixels(normalized);
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(topRadius),
      topRight: Radius.circular(topRadius),
      bottomLeft: Radius.circular(bottomRadius),
      bottomRight: Radius.circular(bottomRadius),
    );
    if (fill != null) {
      canvas.drawRRect(rrect, Paint()..color = fill);
    }
    if (stroke != null && strokeWidth > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = stroke,
      );
    }
  }

  void line(
    Offset from,
    Offset to, {
    Color? color,
    double width = 1.5,
    StrokeCap cap = StrokeCap.round,
  }) {
    canvas.drawLine(
      toPixelOffset(from),
      toPixelOffset(to),
      Paint()
        ..color = color ?? palette.ink
        ..strokeWidth = width
        ..strokeCap = cap,
    );
  }

  void dot(Offset center, double radius, {Color? color}) {
    canvas.drawCircle(
      toPixelOffset(center),
      radius,
      Paint()..color = color ?? palette.ink,
    );
  }

  void ring(Offset center, double radius, {Color? color, double width = 1.5}) {
    canvas.drawCircle(
      toPixelOffset(center),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color ?? palette.ink,
    );
  }

  /// Draws a path built in normalised coordinates. Stroke widths are given in
  /// dp and converted, so a 1.5dp line stays 1.5dp on every screen.
  void path(Path normalized, {Color? fill, Color? stroke, double width = 1.5}) {
    canvas.save();
    canvas.scale(size.width, size.height);
    if (fill != null) {
      canvas.drawPath(normalized, Paint()..color = fill);
    }
    if (stroke != null) {
      canvas.drawPath(
        normalized,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width / size.width
          ..color = stroke,
      );
    }
    canvas.restore();
  }

  void text(
    String value,
    Rect normalized, {
    Color? color,
    double fontSize = 20,
    FontWeight weight = FontWeight.w700,
    String family = 'Geist',
  }) {
    if (value.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: family,
          fontSize: fontSize,
          fontWeight: weight,
          color: color ?? palette.ink,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    final rect = toPixels(normalized);
    painter.paint(
      canvas,
      rect.center - Offset(painter.width / 2, painter.height / 2),
    );
  }
}

/// One puzzle's rules, geometry and paint, and nothing else.
///
/// A board does not own gestures, does not own chrome and does not know about
/// Riverpod. It answers four questions — what can this element become, what
/// does that make the state, is it solved, how does it look — and the engine in
/// `puzzle_board_view.dart` turns the answers into touch.
abstract class PuzzleBoard<S extends PuzzleState> {
  S get state;

  /// Height divided by width of the board box. `1.0` is square.
  double get aspectRatio => 1.0;

  /// Every hit-testable element, in paint order.
  List<ElementRef> get elements;

  /// Where an element sits, in normalised coordinates.
  Rect? boundsOf(ElementRef element);

  /// Every legal move out of an element. This is the puzzle's whole input
  /// surface: the engine derives taps, drags and drop zones from it.
  List<PuzzleMove<S>> movesFor(ElementRef element);

  /// What a tap on this element does, or `null` when it does nothing.
  PuzzleMove<S>? tapMove(ElementRef element);

  S apply(S state, PuzzleMove<S> move) => move.apply(state);

  bool get isSolved;

  /// Elements that pop in the win cascade, in order.
  List<ElementRef> get celebrationElements => elements;

  void paint(PuzzleCanvas canvas, S state);

  /// Draw a single element. Used for the floating copy during a drag and for
  /// the win cascade, so a puzzle never has to duplicate its own drawing code.
  void paintElement(PuzzleCanvas canvas, S state, ElementRef element);

  /// Topmost element under a normalised point.
  ElementRef? hitTest(Offset point) {
    for (final element in elements.reversed) {
      final bounds = boundsOf(element);
      if (bounds != null && bounds.inflate(0.004).contains(point)) {
        return element;
      }
    }
    return null;
  }
}
