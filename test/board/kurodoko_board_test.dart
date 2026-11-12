import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_board.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_engine.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_provider.dart';

// Not const: the constructor asserts that the clue list matches the board, and
// a list's length is not a constant expression.
final _row = KurodokoPuzzle(
  rows: 1,
  cols: 3,
  clues: const [0, 3, 0],
  solution: const [
    KurodokoCell.white,
    KurodokoCell.white,
    KurodokoCell.white,
  ],
);

KurodokoState _state({List<KurodokoCell>? grid, KurodokoHint? hint}) =>
    KurodokoState(
      puzzle: _row,
      grid: grid ?? List<KurodokoCell>.filled(3, KurodokoCell.unknown),
      difficulty: KurodokoDifficulty.easy,
      hint: hint,
    );

void main() {
  group('tap', () {
    test('a tap blackens, then marks white, then clears', () {
      final board = KurodokoBoard(state: _state());
      var state = _state();

      final first = board.tapMove(board.cell(0, 0))!;
      expect(first.kind, MoveKind.place);
      state = first.apply(state);
      expect(state.grid[0], KurodokoCell.black);

      final second = KurodokoBoard(state: state).tapMove(board.cell(0, 0))!;
      state = second.apply(state);
      expect(state.grid[0], KurodokoCell.white);

      final third = KurodokoBoard(state: state).tapMove(board.cell(0, 0))!;
      expect(third.kind, MoveKind.clear);
      state = third.apply(state);
      expect(state.grid[0], KurodokoCell.unknown);
    });

    test('a clue offers no tap: it is white by the rules', () {
      final board = KurodokoBoard(state: _state());
      expect(board.tapMove(board.cell(0, 1)), isNull);
    });

    test('a solved board offers no tap', () {
      final board = KurodokoBoard(
        state: _state(grid: List<KurodokoCell>.filled(3, KurodokoCell.white))
            .copyWith(isSolved: true),
      );
      expect(board.tapMove(board.cell(0, 0)), isNull);
    });

    test('a tap clears the hint', () {
      final state = _state(hint: const KurodokoHint(0, KurodokoCell.black));
      final board = KurodokoBoard(state: state);
      final move = board.tapMove(board.cell(0, 0))!;
      expect(move.apply(state).hint, isNull);
    });
  });

  group('moves', () {
    test('nothing drags: the answer is a set of cells, not a path', () {
      final board = KurodokoBoard(state: _state());
      for (final element in board.elements) {
        expect(board.movesFor(element), isEmpty);
      }
    });
  });

  group('geometry', () {
    test('hit testing finds the cell under a point', () {
      final board = KurodokoBoard(state: _state());
      expect(board.hitTest(board.cellCenter(0, 2)), board.cell(0, 2));
    });

    test('every cell stays inside the board box', () {
      final puzzle = const KurodokoEngine().generate(
        difficulty: KurodokoDifficulty.easy,
        random: Random(3),
      );
      final board = KurodokoBoard(
        state: KurodokoState(
          puzzle: puzzle,
          grid: List<KurodokoCell>.filled(
            puzzle.cellCount,
            KurodokoCell.unknown,
          ),
          difficulty: KurodokoDifficulty.easy,
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

    test('cells do not overlap', () {
      final board = KurodokoBoard(state: _state());
      final a = board.cellRect(0, 0);
      final b = board.cellRect(0, 1);
      expect(a.right, lessThanOrEqualTo(b.left));
    });
  });

  group('paint', () {
    testWidgets('drawing a board raises nothing', (tester) async {
      final puzzle = const KurodokoEngine().generate(
        difficulty: KurodokoDifficulty.easy,
        random: Random(8),
      );
      // Every state in one board: black, white, undecided, clue, and a hint.
      final grid = [...puzzle.solution];
      for (var cell = 0; cell < puzzle.cellCount; cell += 3) {
        if (puzzle.clues[cell] == 0) grid[cell] = KurodokoCell.unknown;
      }
      final board = KurodokoBoard(
        state: KurodokoState(
          puzzle: puzzle,
          grid: grid,
          difficulty: KurodokoDifficulty.easy,
          hint: const KurodokoHint(0, KurodokoCell.black),
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
