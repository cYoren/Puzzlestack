import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/grid_board.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_board.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_provider.dart';

const PuzzlePalette _palette = PuzzlePalette(
  bed: Color(0xFFF8FAFC),
  surface: Color(0xFFFFFFFF),
  ink: Color(0xFF0F172A),
  muted: Color(0xFF64748B),
  primary: Color(0xFF4338CA),
  error: Color(0xFFEF4444),
  success: Color(0xFF10B981),
  outline: Color(0xFFCBD5E1),
  structure: Color(0xFF94A3B8),
  line: Color(0xFFE2E8F0),
);

/// Dragging the ball lifts it. What follows the finger has to be the ball, not
/// the square it sits in: a cell-sized block travelling with the ball is the
/// "the block moves too" bug, and it is a pixel, not an opinion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const double side = 240;

  Future<ui.Image> renderElement(InertiaBoard board, GridBoard<dynamic> _,
      void Function(PuzzleCanvas canvas) draw) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final PuzzleCanvas view = PuzzleCanvas(
      canvas: canvas,
      size: const Size(side, side),
      palette: _palette,
    );
    draw(view);
    return recorder.endRecording().toImage(side.toInt(), side.toInt());
  }

  Future<int> alphaAt(ui.Image image, Offset at) async {
    final ByteData data = (await image.toByteData())!;
    final int x = at.dx.round().clamp(0, side.toInt() - 1);
    final int y = at.dy.round().clamp(0, side.toInt() - 1);
    return data.getUint8((y * side.toInt() + x) * 4 + 3);
  }

  Future<int> colourAt(ui.Image image, Offset at, int channel) async {
    final ByteData data = (await image.toByteData())!;
    final int x = at.dx.round().clamp(0, side.toInt() - 1);
    final int y = at.dy.round().clamp(0, side.toInt() - 1);
    return data.getUint8((y * side.toInt() + x) * 4 + channel);
  }

  /// A normalised cell rectangle in pixels.
  Rect pixels(Rect normalized) => Rect.fromLTRB(
        normalized.left * side,
        normalized.top * side,
        normalized.right * side,
        normalized.bottom * side,
      );

  test('the lifted copy of the ball is the ball, not its cell', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(inertiaNotifierProvider);
    final board = InertiaBoard(state: state);
    final int ball = state.position.cell;
    final ElementRef ballCell =
        ElementRef(GridBoard.cellKind, ball ~/ state.cols, ball % state.cols);

    final ui.Image lifted = await renderElement(
        board, board, (canvas) => board.paintElement(canvas, state, ballCell));

    final Rect rect =
        pixels(board.cellRect(ball ~/ state.cols, ball % state.cols));

    // The centre is the ball: the live indigo.
    expect(await colourAt(lifted, rect.center, 2), greaterThan(200),
        reason: 'the ball is drawn at the cell centre');
    expect(await colourAt(lifted, rect.center, 0), lessThan(120),
        reason: 'indigo, not paper');

    // The corners of the cell are empty. A cell block would fill them with the
    // floor colour, which is the bug: the square travelled with the ball.
    expect(await alphaAt(lifted, rect.topLeft + const Offset(2, 2)), 0);
    expect(await alphaAt(lifted, rect.topRight + const Offset(-2, 2)), 0);
    expect(await alphaAt(lifted, rect.bottomLeft + const Offset(2, -2)), 0);
  });

  test('a floor cell still lifts as a cell', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(inertiaNotifierProvider);
    final board = InertiaBoard(state: state);

    // Some cell that is not the ball's.
    final int other =
        [for (var i = 0; i < state.puzzle.cellCount; i++) i].firstWhere(
      (cell) => cell != state.position.cell,
    );
    final ElementRef otherCell =
        ElementRef(GridBoard.cellKind, other ~/ state.cols, other % state.cols);

    final ui.Image lifted = await renderElement(
        board, board, (canvas) => board.paintElement(canvas, state, otherCell));
    final Rect rect =
        pixels(board.cellRect(other ~/ state.cols, other % state.cols));
    expect(await alphaAt(lifted, rect.topLeft + const Offset(3, 3)),
        greaterThan(0),
        reason: 'an ordinary cell keeps its square');
  });
}
