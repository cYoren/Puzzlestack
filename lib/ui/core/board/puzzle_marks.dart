import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../utils/design_system.dart';
import 'puzzle_board.dart';

/// The house vocabulary for things drawn on a board.
///
/// Colours and geometry were already shared (`PuzzlePalette`, `PuzzleCanvas`,
/// `DesignSystem`), but the *shapes* were not: every board built its own paths
/// out of `Path`, `Rect` arithmetic and hard-coded fractions. That is fine for
/// nine boards and unmaintainable for forty, because a design rework means
/// editing every one of them and hoping they stay consistent.
///
/// A board now asks for a **named mark** — a filled cell, a wall, a crossed
/// cell, a hull, a ring, an arrow, a hatch, a number — and this file decides
/// what that mark looks like. Change `cross` here and every board that crosses
/// something changes with it. Boards keep only the *arrangement*: which cell
/// holds which mark, and how many pixels of the cell it takes.
///
/// Two rules keep this from becoming a second drawing API:
///
///  * a mark is a rectangle plus an optional role, never a path;
///  * anything that needs real geometry (a knight's move line, a region border)
///    is composed from marks, not added as a new primitive.
class PuzzleMarks {
  PuzzleMarks(this.canvas, {this.fraction = 1.0});

  final PuzzleCanvas canvas;

  /// How big the marks are inside a cell, 0..1. A board with tight cells asks
  /// for a smaller fraction instead of shrinking every mark by hand.
  final double fraction;

  PuzzlePalette get palette => canvas.palette;

  /// The resolved colour of a role. Every mark paints through this, so a theme
  /// change lands once.
  Color color(MarkRole role) {
    switch (role) {
      case MarkRole.ink:
        return palette.ink;
      case MarkRole.muted:
        return palette.muted;
      case MarkRole.primary:
        return palette.primary;
      case MarkRole.error:
        return palette.error;
      case MarkRole.success:
        return palette.success;
      case MarkRole.structure:
        return palette.structure;
      case MarkRole.line:
        return palette.line;
    }
  }

  /// A translucent version of a role, for washes and highlights.
  Color wash(MarkRole role, [double alpha = 0.14]) =>
      color(role).withValues(alpha: alpha);

  /// The cell rectangle shrunk to the mark fraction, centred.
  Rect inside(Rect cell) {
    final dx = cell.width * (1 - fraction) / 2;
    final dy = cell.height * (1 - fraction) / 2;
    return Rect.fromLTRB(
        cell.left + dx, cell.top + dy, cell.right - dx, cell.bottom - dy);
  }

  // ------------------------------------------------------------------ cells

  /// A cell of a grid: the thing a player taps. [fill] is a role or a raw
  /// colour, because a wash of a role is still a role but a highlight is not.
  void tile(
    Rect cell, {
    Color? fill,
    Color? stroke,
    double strokeWidth = 1.0,
    double radius = DesignSystem.radiusXS,
  }) {
    canvas.cell(
      cell,
      fill: fill ?? palette.surface,
      stroke: stroke ?? palette.line,
      strokeWidth: strokeWidth,
      radius: radius,
    );
  }

  /// A solid object: a ship segment, a filled cell, a block. [join] says which
  /// sides run into a neighbour so a run of them reads as one body instead of
  /// a row of tiles. [inset] is in cell fractions.
  void block(
    Rect cell, {
    required MarkRole role,
    double inset = 0.0,
    Set<MarkSide> join = const {},
    bool outline = false,
  }) {
    final rect = _inset(cell, inset);
    final radius = rect.width * 0.22;
    var r = 0.0;
    if (join.length == 4) {
      r = 0;
    } else if (join.length == 2 &&
        join.contains(MarkSide.up) == join.contains(MarkSide.down) &&
        join.contains(MarkSide.left) == join.contains(MarkSide.right)) {
      // A straight run: two opposite sides join, the other two stay round.
      r = radius;
    } else {
      r = radius;
    }
    final c = color(role);
    canvas.rrect(
      rect,
      fill: c,
      topRadius: join.contains(MarkSide.up) ? 0 : r,
      bottomRadius: join.contains(MarkSide.down) ? 0 : r,
      stroke: outline ? palette.line : null,
    );
    // Left and right joins need the middle of the rounded rect squared off;
    // `rrect` only takes top and bottom radii, so paint the seams with the
    // same fill to make the run continuous.
    if (join.contains(MarkSide.left)) {
      canvas.cell(
        Rect.fromLTRB(rect.left, rect.top + r, rect.left + r, rect.bottom - r),
        fill: c,
        radius: 0,
      );
    }
    if (join.contains(MarkSide.right)) {
      canvas.cell(
        Rect.fromLTRB(
            rect.right - r, rect.top + r, rect.right, rect.bottom - r),
        fill: c,
        radius: 0,
      );
    }
  }

  /// A water cell: a small centred dot. Reads as "nothing here" at 320dp
  /// without a wash that fights the ink.
  void dotMark(Rect cell,
      {MarkRole role = MarkRole.muted, double size = 0.16}) {
    final rect = inside(cell);
    canvas.dot(
      rect.center,
      canvas.radiusFor(rect, size / 2),
      color: color(role),
    );
  }

  /// A crossed cell: two diagonals. The house mark for "ruled out".
  void crossMark(
    Rect cell, {
    MarkRole role = MarkRole.muted,
    double size = 0.34,
    double weight = 2.0,
  }) {
    final rect = inside(cell);
    final half = math.min(rect.width, rect.height) * size / 2;
    final c = rect.center;
    canvas.line(
      Offset(c.dx - half, c.dy - half),
      Offset(c.dx + half, c.dy + half),
      color: color(role),
      width: weight,
    );
    canvas.line(
      Offset(c.dx + half, c.dy - half),
      Offset(c.dx - half, c.dy + half),
      color: color(role),
      width: weight,
    );
  }

  /// A ring. A dot that is not filled in: a pinch point, a hub, a pending cell.
  void ringMark(
    Rect cell, {
    MarkRole role = MarkRole.ink,
    double size = 0.3,
    double weight = 1.5,
  }) {
    final rect = inside(cell);
    canvas.ring(
      rect.center,
      canvas.radiusFor(rect, size / 2),
      color: color(role),
      width: weight,
    );
  }

  /// A diagonal hatch, clipped to the cell. The mark for "blocked" that still
  /// lets a clue underneath stay readable.
  void hatch(
    Rect cell, {
    MarkRole role = MarkRole.structure,
    double spacing = 0.22,
    double weight = 1.2,
  }) {
    final rect = inside(cell);
    final step = rect.width * spacing;
    canvas.pushClip(rect);
    for (var x = rect.left - rect.height; x < rect.right; x += step) {
      canvas.line(
        Offset(x, rect.bottom),
        Offset(x + rect.height, rect.top),
        color: color(role),
        width: weight,
        cap: StrokeCap.butt,
      );
    }
    canvas.pop();
  }

  /// A filled band across the middle of a cell: an orientation, a region tint,
  /// a "this belongs to that group" stripe.
  void band(
    Rect cell, {
    required MarkRole role,
    double thickness = 0.3,
    bool vertical = false,
    double offset = 0,
  }) {
    final rect = inside(cell);
    final t = (vertical ? rect.width : rect.height) * thickness;
    final c = rect.center + (vertical ? Offset(offset, 0) : Offset(0, offset));
    final bandRect = vertical
        ? Rect.fromCenter(center: c, width: t, height: rect.height)
        : Rect.fromCenter(center: c, width: rect.width, height: t);
    canvas.cell(bandRect, fill: color(role), radius: t * 0.5);
  }

  /// An arrow: direction of travel, an edge clue's meaning.
  void arrow(Rect cell, MarkDirection direction, {required MarkRole role}) {
    final rect = inside(cell);
    final half = math.min(rect.width, rect.height) * 0.28;
    final c = rect.center;
    // Points of a triangle facing up, rotated by the direction.
    final up = <Offset>[
      Offset(c.dx, c.dy - half),
      Offset(c.dx - half, c.dy + half),
      Offset(c.dx + half, c.dy + half),
    ];
    final turns = switch (direction) {
      MarkDirection.up => 0,
      MarkDirection.right => 1,
      MarkDirection.down => 2,
      MarkDirection.left => 3,
    };
    final points = <Offset>[];
    for (final p in up) {
      final rel = p - c;
      var dx = rel.dx;
      var dy = rel.dy;
      for (var i = 0; i < turns; i++) {
        final nx = -dy;
        final ny = dx;
        dx = nx;
        dy = ny;
      }
      points.add(c + Offset(dx, dy));
    }
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..close();
    canvas.path(path, fill: color(role));
  }

  /// A number or letter in a cell. [fraction] is of the cell's height, and goes
  /// through `PuzzleCanvas.fontSizeForSquare` so a sub-pixel font cannot ship.
  void label(
    Rect cell,
    String text, {
    MarkRole role = MarkRole.ink,
    double fraction = 0.46,
    FontWeight weight = FontWeight.w800,
  }) {
    if (text.isEmpty) return;
    canvas.text(
      text,
      cell,
      color: color(role),
      fontSize: canvas.fontSizeForSquare(cell, fraction),
      weight: weight,
    );
  }

  /// A hint ring around a cell: the one mark every board can use to point at a
  /// step without owning an error colour of its own.
  void hint(Rect cell, {double weight = 2.5}) {
    canvas.cell(
      cell,
      stroke: palette.error,
      strokeWidth: weight,
      radius: DesignSystem.radiusXS,
    );
  }

  Rect _inset(Rect cell, double inset) {
    if (inset == 0) return cell;
    final dx = cell.width * inset;
    final dy = cell.height * inset;
    return Rect.fromLTRB(
      cell.left + dx,
      cell.top + dy,
      cell.right - dx,
      cell.bottom - dy,
    );
  }
}

/// The roles a mark can take. One per colour a board is allowed to use, so a
/// rework of the palette does not require a rework of forty boards.
enum MarkRole { ink, muted, primary, error, success, structure, line }

/// Which side of a cell a [PuzzleMarks.block] joins to its neighbour.
enum MarkSide { up, down, left, right }

/// The four directions an [PuzzleMarks.arrow] can point.
enum MarkDirection { up, right, down, left }

extension MarkSideOf on MarkDirection {
  MarkSide get side => switch (this) {
        MarkDirection.up => MarkSide.up,
        MarkDirection.right => MarkSide.right,
        MarkDirection.down => MarkSide.down,
        MarkDirection.left => MarkSide.left,
      };

  MarkSide get opposite => switch (this) {
        MarkDirection.up => MarkSide.down,
        MarkDirection.right => MarkSide.left,
        MarkDirection.down => MarkSide.up,
        MarkDirection.left => MarkSide.right,
      };
}
