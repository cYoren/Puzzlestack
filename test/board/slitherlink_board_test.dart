import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_board.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_engine.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_provider.dart';

const int size = 2;

SlitherlinkState _state() => SlitherlinkState(
      level: SlitherlinkLevel(
        size: size,
        clues: List.generate(size, (_) => List<int?>.filled(size, null)),
        solutionHEdges:
            List.generate(size + 1, (_) => List.filled(size, false)),
        solutionVEdges:
            List.generate(size, (_) => List.filled(size + 1, false)),
      ),
      currentHEdges: List.generate(size + 1, (_) => List.filled(size, false)),
      currentVEdges: List.generate(size, (_) => List.filled(size + 1, false)),
    );

void main() {
  group('SlitherlinkBoard', () {
    test('every element sits inside the board box', () {
      final board = SlitherlinkBoard(state: _state());
      for (final element in board.elements) {
        final bounds = board.boundsOf(element)!;
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(1.0));
        expect(bounds.bottom, lessThanOrEqualTo(1.0));
      }
    });

    test('dots are the drag handles and sit above the edges', () {
      final board = SlitherlinkBoard(state: _state());
      final dot = board.boundsOf(SlitherlinkBoard.vertex(0, 0))!;
      expect(board.hitTest(dot.center), SlitherlinkBoard.vertex(0, 0));
    });

    test('dragging a dot offers the edges it can draw', () {
      final board = SlitherlinkBoard(state: _state());
      final moves = board.movesFor(SlitherlinkBoard.vertex(0, 0));

      expect(moves, hasLength(2), reason: 'a corner has two neighbours');
      expect(
        moves.map((m) => m.target),
        containsAll([
          SlitherlinkBoard.vertex(0, 1),
          SlitherlinkBoard.vertex(1, 0),
        ]),
      );
    });

    test('applying a drag draws the edge', () {
      final board = SlitherlinkBoard(state: _state());
      final move = board
          .movesFor(SlitherlinkBoard.vertex(0, 0))
          .firstWhere((m) => m.target == SlitherlinkBoard.vertex(0, 1));

      final next = board.apply(board.state, move);
      expect(next.currentHEdges[0][0], isTrue);
    });

    test('dragging over a drawn edge erases it', () {
      final drawn = _state();
      drawn.currentHEdges[0][0] = true;
      final board = SlitherlinkBoard(state: drawn);

      final move = board
          .movesFor(SlitherlinkBoard.vertex(0, 0))
          .firstWhere((m) => m.target == SlitherlinkBoard.vertex(0, 1));
      expect(move.kind, MoveKind.clear);

      final next = board.apply(drawn, move);
      expect(next.currentHEdges[0][0], isFalse);
    });

    test('tapping an edge toggles it', () {
      final board = SlitherlinkBoard(state: _state());
      final on = board.tapMove(SlitherlinkBoard.hEdge(0, 0))!;
      final drawn = board.apply(board.state, on);
      expect(drawn.currentHEdges[0][0], isTrue);

      final off = SlitherlinkBoard(state: drawn)
          .tapMove(SlitherlinkBoard.hEdge(0, 0))!;
      expect(off.kind, MoveKind.clear);
      expect(SlitherlinkBoard(state: drawn).apply(drawn, off).currentHEdges[0][0],
          isFalse);
    });

    test('a dot has no tap move of its own', () {
      final board = SlitherlinkBoard(state: _state());
      expect(board.tapMove(SlitherlinkBoard.vertex(0, 0)), isNull);
    });
  });
}
