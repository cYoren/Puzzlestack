import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/features/games/pegs/pegs_board.dart';
import 'package:puzzle/ui/features/games/pegs/pegs_engine.dart';
import 'package:puzzle/ui/features/games/pegs/pegs_provider.dart';

/// A three-cell row: peg, peg, hole. Exactly one jump exists.
PegsState _rowState(List<PegCell> cells, {int? selected}) {
  final puzzle = PegsPuzzle(
    rows: 1,
    cols: cells.length,
    start: cells,
    solution: const [],
  );
  return PegsState(
    puzzle: puzzle,
    grid: cells,
    difficulty: PegsDifficulty.easy,
    selected: selected,
  );
}

void main() {
  const engine = PegsEngine();

  group('moves', () {
    test('a peg offers one move per legal jump, aimed at the landing square',
        () {
      final board = PegsBoard(state: _rowState([
        PegCell.peg,
        PegCell.peg,
        PegCell.hole,
      ]));

      final moves = board.movesFor(board.cell(0, 0));
      expect(moves, hasLength(1));
      expect(moves.single.target, board.cell(0, 2));
      expect(moves.single.isDraggable, isTrue);
    });

    test('a hole offers no drag', () {
      final board = PegsBoard(state: _rowState([
        PegCell.peg,
        PegCell.peg,
        PegCell.hole,
      ]));
      expect(board.movesFor(board.cell(0, 2)), isEmpty);
    });

    test('applying a jump removes the peg it hopped over', () {
      final state = _rowState([PegCell.peg, PegCell.peg, PegCell.hole]);
      final board = PegsBoard(state: state);
      final move = board.movesFor(board.cell(0, 0)).single;

      final next = move.apply(state);
      expect(next.grid, [PegCell.hole, PegCell.hole, PegCell.peg]);
      expect(next.isSolved, isTrue);
    });
  });

  group('tap', () {
    test('tapping a peg picks it up, tapping it again puts it down', () {
      final state = _rowState([PegCell.peg, PegCell.peg, PegCell.hole]);
      final board = PegsBoard(state: state);

      final pick = board.tapMove(board.cell(0, 0))!;
      final picked = pick.apply(state);
      expect(picked.selected, 0);

      final again = PegsBoard(state: picked).tapMove(board.cell(0, 0))!;
      expect(again.apply(picked).selected, isNull);
    });

    test('tapping a landing square with a peg picked up makes the jump', () {
      final picked = _rowState(
        [PegCell.peg, PegCell.peg, PegCell.hole],
        selected: 0,
      );
      final board = PegsBoard(state: picked);

      final move = board.tapMove(board.cell(0, 2));
      expect(move, isNotNull);
      final next = move!.apply(picked);
      expect(next.grid, [PegCell.hole, PegCell.hole, PegCell.peg]);
    });

    test('tapping a landing square with nothing picked up does nothing', () {
      final board = PegsBoard(state: _rowState([
        PegCell.peg,
        PegCell.peg,
        PegCell.hole,
      ]));
      expect(board.tapMove(board.cell(0, 2)), isNull);
    });

    test('tapping an obstacle does nothing', () {
      final board = PegsBoard(state: _rowState([
        PegCell.peg,
        PegCell.peg,
        PegCell.obstacle,
      ]));
      expect(board.tapMove(board.cell(0, 2)), isNull);
    });
  });

  group('geometry', () {
    test('hit testing finds the cell under a point', () {
      final board = PegsBoard(state: _rowState([
        PegCell.peg,
        PegCell.peg,
        PegCell.hole,
      ]));
      expect(board.hitTest(board.cellCenter(0, 1)), board.cell(0, 1));
    });

    test('a real board keeps every cell inside the box', () {
      final puzzle = const PegsEngine().generate(random: Random(4));
      final board = PegsBoard(
        state: PegsState(
          puzzle: puzzle,
          grid: puzzle.start,
          difficulty: PegsDifficulty.medium,
        ),
      );

      for (final element in board.elements) {
        final bounds = board.boundsOf(element)!;
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(1));
        expect(bounds.bottom, lessThanOrEqualTo(1));
      }
      expect(board.aspectRatio, closeTo(puzzle.rows / puzzle.cols, 1e-9));
    });

    test('cells do not overlap', () {
      final board = PegsBoard(state: _rowState([
        PegCell.peg,
        PegCell.peg,
        PegCell.hole,
      ]));
      final first = board.cellRect(0, 0);
      final second = board.cellRect(0, 1);
      expect(first.right, lessThan(second.left));
    });
  });

  group('paint', () {
    testWidgets('drawing a board raises nothing', (tester) async {
      final puzzle = engine.generate(random: Random(8));
      final board = PegsBoard(
        state: PegsState(
          puzzle: puzzle,
          grid: puzzle.start,
          difficulty: PegsDifficulty.medium,
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
