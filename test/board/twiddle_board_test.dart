import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_board.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_engine.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_provider.dart';

TwiddleState _state(List<int> grid, {int size = 3, int block = 2}) {
  return TwiddleState(
    puzzle: TwiddlePuzzle(
      size: size,
      block: block,
      start: grid,
      solution: const [],
    ),
    grid: grid,
    difficulty: TwiddleDifficulty.easy,
  );
}

void main() {
  const engine = TwiddleEngine();

  group('moves', () {
    test('a tile offers a drag for each turn that moves it', () {
      final board = TwiddleBoard(state: _state(engine.solvedGrid(3)));

      final moves = board.movesFor(board.cell(0, 0));
      expect(moves, isNotEmpty);
      for (final move in moves) {
        expect(move.isDraggable, isTrue);
        expect(move.target, isNotNull);
        expect(move.target, isNot(board.cell(0, 0)));
      }
    });

    test('the destination of a drag is where the tile lands', () {
      final state = _state(engine.solvedGrid(3));
      final board = TwiddleBoard(state: state);

      for (final move in board.movesFor(board.cell(0, 0))) {
        final next = move.apply(state);
        final target = move.target!;
        // The tile that was at (0,0) is now at the target.
        expect(next.grid[target.a * 3 + target.b], state.grid[0]);
      }
    });

    test('a turn leaves the board a permutation', () {
      final state = _state(engine.solvedGrid(3));
      final board = TwiddleBoard(state: state);
      final next = board.movesFor(board.cell(0, 0)).first.apply(state);

      expect(next.grid.toSet(), state.grid.toSet());
      expect(next.grid, isNot(state.grid));
    });
  });

  group('tap', () {
    test('tapping a tile turns a block', () {
      final state = _state(engine.solvedGrid(3));
      final board = TwiddleBoard(state: state);

      final move = board.tapMove(board.cell(0, 0));
      expect(move, isNotNull);
      expect(move!.apply(state).grid, isNot(state.grid));
    });

    test('every tile can be tapped', () {
      final state = _state(engine.solvedGrid(4), size: 4);
      final board = TwiddleBoard(state: state);
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 4; col++) {
          expect(board.tapMove(board.cell(row, col)), isNotNull,
              reason: 'tile ($row,$col) cannot be tapped');
        }
      }
    });
  });

  group('solved', () {
    test('a solved board reports solved', () {
      final board = TwiddleBoard(state: _state(engine.solvedGrid(3)));
      expect(board.isSolved, isFalse); // the state flag is what counts
      final solved = TwiddleState(
        puzzle: TwiddlePuzzle(
          size: 3,
          block: 2,
          start: engine.solvedGrid(3),
          solution: const [],
        ),
        grid: engine.solvedGrid(3),
        difficulty: TwiddleDifficulty.easy,
        isSolved: true,
      );
      expect(TwiddleBoard(state: solved).isSolved, isTrue);
    });
  });

  group('geometry', () {
    test('hit testing finds the tile under a point', () {
      final board = TwiddleBoard(state: _state(engine.solvedGrid(3)));
      expect(board.hitTest(board.cellCenter(1, 2)), board.cell(1, 2));
    });

    test('every cell stays inside the board box', () {
      final board = TwiddleBoard(state: _state(engine.solvedGrid(5), size: 5));
      for (final element in board.elements) {
        final bounds = board.boundsOf(element)!;
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(1));
      }
      expect(board.aspectRatio, 1.0);
    });
  });

  group('paint', () {
    testWidgets('drawing a board raises nothing', (tester) async {
      final puzzle = engine.generate(random: Random(3));
      final board = TwiddleBoard(
        state: TwiddleState(
          puzzle: puzzle,
          grid: puzzle.start,
          difficulty: TwiddleDifficulty.medium,
          hint: engine.hint(puzzle.start, puzzle.size, puzzle.block),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: _BoardPainter(board),
              size: const Size(320, 320),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.board);

  final PuzzleBoard<PuzzleState> board;

  @override
  void paint(Canvas canvas, Size size) {
    final context = PuzzleCanvas(
      canvas: canvas,
      size: size,
      palette: const PuzzlePalette(
        bed: Color(0xFFF8FAFC),
        surface: Color(0xFFFFFFFF),
        ink: Color(0xFF0F172A),
        muted: Color(0xFF64748B),
        primary: Color(0xFF4338CA),
        error: Color(0xFFEF4444),
        success: Color(0xFF10B981),
        outline: Color(0xFFCBD5E1),
      ),
    );
    board.paint(context, board.state);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
