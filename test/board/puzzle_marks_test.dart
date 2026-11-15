import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/core/board/puzzle_marks.dart';

/// The marks are drawn through `PuzzleCanvas`, which works in normalised
/// coordinates except for a stroke width, which is dp. A radius is neither, and
/// passing a normalised number to `dot`/`ring` draws a fraction of a pixel: six
/// boards shipped invisible marks that way, and no test that measures layout can
/// see it. These tests look at the pixels.
const _bed = Color(0xFFF8FAFC);
const _ink = Color(0xFF14130E);

const _palette = PuzzlePalette(
  bed: _bed,
  surface: Color(0xFFFFFFFF),
  ink: _ink,
  muted: Color(0xFF5B6472),
  primary: Color(0xFF4338CA),
  error: Color(0xFFEF4444),
  success: Color(0xFF10B981),
  outline: Color(0xFFC3C8D2),
  structure: Color(0xFF2A2A33),
  line: Color(0xFFC3C8D2),
);

const _board = 400.0;
const _cell = Rect.fromLTWH(0.4, 0.4, 0.2, 0.2);

/// Renders one mark onto a 400px board and returns a pixel reader.
Future<Color Function(Offset normalized)> _render(
  void Function(PuzzleMarks marks, Rect cell) paint,
) async {
  final recorder = ui.PictureRecorder();
  final surface = PuzzleCanvas(
    canvas: Canvas(recorder),
    size: const Size(_board, _board),
    palette: _palette,
  );
  surface.bed();
  paint(PuzzleMarks(surface), _cell);
  final image =
      await recorder.endRecording().toImage(_board.toInt(), _board.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!;
  return (Offset normalized) {
    final x = (normalized.dx * _board).round().clamp(0, _board.toInt() - 1);
    final y = (normalized.dy * _board).round().clamp(0, _board.toInt() - 1);
    final index = (y * _board.toInt() + x) * 4;
    return Color.fromARGB(
      bytes.getUint8(index + 3),
      bytes.getUint8(index),
      bytes.getUint8(index + 1),
      bytes.getUint8(index + 2),
    );
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a dot mark paints a dot, not a sub-pixel nothing', () async {
    final at = await _render(
      (marks, cell) => marks.dotMark(cell, role: MarkRole.ink, size: 0.3),
    );
    expect(at(_cell.center), _ink, reason: 'the centre of the cell is blank');
  });

  test('a ring mark paints a ring, and leaves its middle empty', () async {
    final at = await _render(
      (marks, cell) => marks.ringMark(cell, role: MarkRole.ink, size: 0.4),
    );
    expect(at(_cell.center), _bed, reason: 'a ring must not fill its middle');
    // The ring's own radius: a fifth of a 0.2-wide cell on a 400px board is
    // 16px, which is 0.04 of the board, so sample just inside the stroke.
    final onRing = at(_cell.center + const Offset(0.04, 0));
    expect(onRing, isNot(_bed), reason: 'no stroke where the ring should be');
  });

  test('radiusFor turns a cell fraction into pixels', () {
    final surface = PuzzleCanvas(
      canvas: Canvas(ui.PictureRecorder()),
      size: const Size(400, 400),
      palette: _palette,
    );
    // A fifth of the board on each side is 80px; a quarter of that is 20px.
    expect(surface.radiusFor(_cell, 0.25), closeTo(20, 0.001));
  });
}
