import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/features/games/galaxies/galaxies_board.dart';
import 'package:puzzle/ui/features/games/galaxies/galaxies_engine.dart';
import 'package:puzzle/ui/features/games/galaxies/galaxies_provider.dart';

/// A one-row board with a dot in the middle, so a cell and its reflection are
/// easy to reason about by hand.
const _row = GalaxiesPuzzle(
  rows: 1,
  cols: 3,
  dots: [GalaxiesDot(2, 0)],
  solution: [0, 0, 0],
);

GalaxiesState _state({List<int>? owner, int? activeDot}) => GalaxiesState(
      puzzle: _row,
      owner: owner ?? List<int>.filled(3, -1),
      difficulty: GalaxiesDifficulty.easy,
      activeDot: activeDot,
    );

void main() {
  group('moves', () {
    test('a dot offers a drag onto every cell it can still take', () {
      final board = GalaxiesBoard(state: _state());
      final moves = board.movesFor(board.cell(0, 1));

      // The dot sits in the middle cell, so the two outer cells are free.
      expect(moves, hasLength(2));
      expect(moves.every((move) => move.isDraggable), isTrue);
      expect(
        moves.map((move) => move.target).toSet(),
        {board.cell(0, 0), board.cell(0, 2)},
      );
    });

    test('a plain cell offers no drag', () {
      final board = GalaxiesBoard(state: _state());
      expect(board.movesFor(board.cell(0, 0)), isEmpty);
    });

    test('a drag paints the cell and the cell it reflects onto', () {
      final state = _state();
      final board = GalaxiesBoard(state: state);
      final move = board
          .movesFor(board.cell(0, 1))
          .firstWhere((move) => move.target == board.cell(0, 0));

      final next = move.apply(state);
      expect(next.owner, [0, -1, 0]);
    });
  });

  group('tap', () {
    test('tapping a dot picks it up, tapping it again puts it down', () {
      final state = _state();
      final board = GalaxiesBoard(state: state);

      final picked = board.tapMove(board.cell(0, 1))!.apply(state);
      expect(picked.activeDot, 0);

      final again = GalaxiesBoard(state: picked).tapMove(board.cell(0, 1))!;
      expect(again.apply(picked).activeDot, isNull);
    });

    test('tapping a cell with a dot picked paints it', () {
      final state = _state(activeDot: 0);
      final board = GalaxiesBoard(state: state);

      final move = board.tapMove(board.cell(0, 0));
      expect(move, isNotNull);
      expect(move!.apply(state).owner, [0, -1, 0]);
    });

    test('tapping a painted cell with nothing picked clears it', () {
      final state = _state(owner: [0, -1, 0]);
      final board = GalaxiesBoard(state: state);

      final move = board.tapMove(board.cell(0, 0));
      expect(move, isNotNull);
      expect(move!.apply(state).owner, [-1, -1, -1]);
    });

    test('tapping a free cell with nothing picked does nothing', () {
      final board = GalaxiesBoard(state: _state());
      expect(board.tapMove(board.cell(0, 0)), isNull);
    });
  });

  group('solved', () {
    test('a full symmetric board reports solved', () {
      const engine = GalaxiesEngine();
      final state = _state(owner: [0, 0, 0]);
      expect(engine.isSolved(_row, state.owner), isTrue);
    });

    test('a board with a gap is not solved', () {
      const engine = GalaxiesEngine();
      expect(engine.isSolved(_row, [0, 0, -1]), isFalse);
    });
  });

  group('geometry', () {
    test('hit testing finds the cell under a point', () {
      final board = GalaxiesBoard(state: _state());
      expect(board.hitTest(board.cellCenter(0, 2)), board.cell(0, 2));
    });

    test('every cell stays inside the board box', () {
      final puzzle = const GalaxiesEngine().generate(
        difficulty: GalaxiesDifficulty.easy,
        random: Random(3),
      );
      final board = GalaxiesBoard(
        state: GalaxiesState(
          puzzle: puzzle,
          owner: List<int>.filled(puzzle.cellCount, -1),
          difficulty: GalaxiesDifficulty.easy,
        ),
      );

      for (final element in board.elements) {
        final bounds = board.boundsOf(element)!;
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(1));
        expect(bounds.bottom, lessThanOrEqualTo(1));
      }
    });

    test('a dot in the middle of a cell is drawn at that cell\'s centre', () {
      final board = GalaxiesBoard(state: _state());
      final centre = board.dotCentre(_row.dots.single);
      expect(centre.dx, closeTo(board.cellCenter(0, 1).dx, 1e-9));
      expect(centre.dy, closeTo(board.cellCenter(0, 1).dy, 1e-9));
    });
  });

  group('paint', () {
    testWidgets('drawing a board raises nothing', (tester) async {
      final puzzle = const GalaxiesEngine().generate(
        difficulty: GalaxiesDifficulty.easy,
        random: Random(8),
      );
      final board = GalaxiesBoard(
        state: GalaxiesState(
          puzzle: puzzle,
          owner: [...puzzle.solution],
          difficulty: GalaxiesDifficulty.easy,
          activeDot: 0,
          hint: const GalaxiesHint(0, 0),
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
        structure: Color(0xFF2A2A33),
        line: Color(0xFFC3C8D2),
      ),
    );
    board.paint(context, board.state);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
