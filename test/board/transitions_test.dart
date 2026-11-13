import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/features/games/cube/cube_board.dart';
import 'package:puzzle/ui/features/games/cube/cube_provider.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_board.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_provider.dart';
import 'package:puzzle/ui/features/games/netslide/netslide_board.dart';
import 'package:puzzle/ui/features/games/netslide/netslide_provider.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_board.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_provider.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_board.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_engine.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_provider.dart';

const _palette = PuzzlePalette(
  bed: Color(0xFFF8FAFC),
  surface: Color(0xFFFFFFFF),
  ink: Color(0xFF0F172A),
  muted: Color(0xFF64748B),
  primary: Color(0xFF4338CA),
  error: Color(0xFFEF4444),
  success: Color(0xFF10B981),
  outline: Color(0xFFCBD5E1),
  structure: Color(0xFF2A2A33),
  line: Color(0xFFC3C8D2),
);

/// Paints the whole transition, frame by frame, and fails on any exception.
void _paintAll<S extends PuzzleState>(PuzzleBoard<S> board, S from, S to) {
  final recorder = PictureRecorder();
  final view = PuzzleCanvas(
    canvas: Canvas(recorder),
    size: const Size(360, 360),
    palette: _palette,
  );
  for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
    board.paintTransition(view, from, to, t);
  }
  recorder.endRecording();
}

void main() {
  test('a water sort pour animates and paints every frame', () {
    final engine = WaterSortEngine();
    final from = WaterSortState(tubes: engine.generateLevel());
    List<List<Color>>? poured;
    for (var i = 0; i < from.tubes.length && poured == null; i++) {
      for (var j = 0; j < from.tubes.length; j++) {
        if (i == j) continue;
        final tubes = [for (final tube in from.tubes) [...tube]];
        if (!engine.canPour(tubes[i], tubes[j])) continue;
        engine.pour(tubes[i], tubes[j]);
        poured = tubes;
        break;
      }
    }
    expect(poured, isNotNull);
    final to = from.copyWith(tubes: poured!, isSolved: engine.isSolved(poured));

    final board = WaterSortBoard(state: to);
    expect(board.transitionFor(from, to), isNotNull);
    _paintAll(board, from, to);
  });

  test('a water sort reset is not disguised as a pour', () {
    final engine = WaterSortEngine();
    final from = WaterSortState(tubes: engine.generateLevel());
    final to = WaterSortState(tubes: engine.generateLevel());
    expect(WaterSortBoard(state: to).transitionFor(from, to), isNull);
  });

  test('a twiddle turn animates and paints every frame', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(twiddleNotifierProvider);
    final board = TwiddleBoard(state: state);

    for (final cell in board.cells) {
      final moves = board.movesFor(cell);
      if (moves.isEmpty) continue;
      final next = board.apply(state, moves.first);
      expect(board.transitionFor(state, next), isNotNull);
      _paintAll(board, state, next);
      return;
    }
    fail('no twiddle move was offered');
  });

  test('a netslide slide animates and paints every frame', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(netslideNotifierProvider);
    final board = NetslideBoard(state: state);

    for (final cell in board.cells) {
      final moves = board.movesFor(cell);
      if (moves.isEmpty) continue;
      final next = board.apply(state, moves.first);
      expect(board.transitionFor(state, next), isNotNull);
      _paintAll(board, state, next);
      return;
    }
    fail('no netslide move was offered');
  });

  test('a cube roll animates and paints every frame', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(cubeNotifierProvider);
    final board = CubeBoard(state: state);
    final cell = state.position.cell;
    final moves = board.movesFor(
      ElementRef('cell', cell ~/ state.cols, cell % state.cols),
    );
    expect(moves, isNotEmpty);
    final next = board.apply(state, moves.first);
    expect(board.transitionFor(state, next), isNotNull);
    _paintAll(board, state, next);
  });

  test('an inertia slide animates and paints every frame', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(inertiaNotifierProvider);
    final board = InertiaBoard(state: state);
    final ball = state.position.cell;
    final moves = board.movesFor(
      ElementRef('cell', ball ~/ state.cols, ball % state.cols),
    );
    expect(moves, isNotEmpty);
    final next = board.apply(state, moves.first);
    expect(board.transitionFor(state, next), isNotNull);
    _paintAll(board, state, next);
  });
}
