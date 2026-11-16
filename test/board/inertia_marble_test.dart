/// Inertia must paint exactly one marble: the one the finger is holding.
///
/// The owner's report, verbatim: "Inertia still has the bug where the ball
/// duplicates instead of just moving". The engine hides the lifted *cell* while
/// a drag is in flight (`PuzzleCanvas.isHidden`) but Inertia draws the marble
/// outside the cell loop, so the board kept painting it parked at the origin
/// while the engine painted a second one under the finger. Two marbles, one
/// move. The fix is in the board's paint, and the assertion here is a pixel:
/// the origin has no indigo left, the lifted copy has.
///
/// `test/board/inertia_lift_test.dart` already proves the lifted copy is the
/// ball and not its square; this file proves it is the *only* copy.
library;

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

const double _side = 240;

Future<ui.Image> _render(void Function(Canvas canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  return recorder.endRecording().toImage(_side.toInt(), _side.toInt());
}

Future<int> _channelAt(ui.Image image, Offset at, int channel) async {
  final data = (await image.toByteData())!;
  final x = at.dx.round().clamp(0, _side.toInt() - 1);
  final y = at.dy.round().clamp(0, _side.toInt() - 1);
  return data.getUint8((y * _side.toInt() + x) * 4 + channel);
}

/// A normalised cell rectangle in pixels.
Rect _pixels(Rect normalized) => Rect.fromLTRB(
      normalized.left * _side,
      normalized.top * _side,
      normalized.right * _side,
      normalized.bottom * _side,
    );

/// Indigo `#4338CA` has a red channel of ~67; paper and the 5% lane wash are
/// above 240. This is the one bit that separates "a marble is here" from "a
/// floor cell is here".
Future<void> _expectMarble(ui.Image image, Offset centre) async {
  expect(await _channelAt(image, centre, 2), greaterThan(180),
      reason: 'a marble should be blue at $centre');
  expect(await _channelAt(image, centre, 0), lessThan(120),
      reason: 'a marble should be indigo at $centre');
}

Future<void> _expectNoMarble(ui.Image image, Offset centre) async {
  expect(await _channelAt(image, centre, 0), greaterThan(150),
      reason: 'the marble was left behind at $centre');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerForTest() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('mid-drag, the marble moves: none left at the old cell', () async {
    final container = containerForTest();
    final state = container.read(inertiaNotifierProvider);
    final board = InertiaBoard(state: state);
    final int ball = state.position.cell;
    final ElementRef ballCell =
        ElementRef(GridBoard.cellKind, ball ~/ state.cols, ball % state.cols);
    final Offset origin = _pixels(
      board.cellRect(ball ~/ state.cols, ball % state.cols),
    ).center;

    // The exact state the engine hands the board while a finger holds the
    // marble: that cell is lifted (hidden in place) and the floating copy is
    // painted 40px above where it was.
    const lift = Offset(0, -40);
    final highlight = BoardHighlight(
      lifted: ballCell,
      liftOffset: lift,
      liftScale: 1.0,
    );

    final image = await _render((canvas) {
      final view = PuzzleCanvas(
        canvas: canvas,
        size: const Size(_side, _side),
        palette: _palette,
        highlight: highlight,
      );
      // What the view paints: the board, then the floating copy, translated by
      // the engine's lift offset.
      board.paint(view, state);
      canvas.save();
      canvas.translate(lift.dx, lift.dy);
      board.paintElement(view, state, ballCell);
      canvas.restore();
    });

    await _expectNoMarble(image, origin);
    await _expectMarble(image, origin + lift);
  });

  test('after a drag lands, the marble is only at the new cell', () async {
    final container = containerForTest();
    final state = container.read(inertiaNotifierProvider);
    final board = InertiaBoard(state: state);
    final int ball = state.position.cell;
    final ElementRef ballCell =
        ElementRef(GridBoard.cellKind, ball ~/ state.cols, ball % state.cols);

    final move =
        board.movesFor(ballCell).firstWhere((move) => move.target != null);
    final next = board.apply(state, move);

    final image = await _render((canvas) {
      final view = PuzzleCanvas(
        canvas: canvas,
        size: const Size(_side, _side),
        palette: _palette,
      );
      InertiaBoard(state: next).paint(view, next);
    });

    final oldCentre = _pixels(
      board.cellRect(ball ~/ state.cols, ball % state.cols),
    ).center;
    final newCentre = _pixels(
      board.cellRect(
        next.position.cell ~/ state.cols,
        next.position.cell % state.cols,
      ),
    ).center;

    await _expectNoMarble(image, oldCentre);
    await _expectMarble(image, newCentre);
  });
}
