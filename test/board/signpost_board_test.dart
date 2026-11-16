import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/core/board/puzzle_board_view.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_board.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_engine.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_provider.dart';

const _engine = SignpostEngine();

SignpostPuzzle _puzzle(int seed) =>
    _engine.generate(SignpostDifficulty.easy, random: Random(seed));

SignpostState _state(SignpostPuzzle puzzle, {List<int>? links}) =>
    SignpostState(
      puzzle: puzzle,
      links: links ?? List<int>.filled(puzzle.cellCount, -1),
      difficulty: SignpostDifficulty.easy,
    );

/// The board element holding the answer's number [number].
ElementRef _where(SignpostPuzzle puzzle, int number) {
  final cell = puzzle.cellOfNumber(number);
  return ElementRef('cell', puzzle.rowOf(cell), puzzle.colOf(cell));
}

void main() {
  group('tap', () {
    test('the first tap selects, the second lets go', () {
      final puzzle = _puzzle(1);
      final state = _state(puzzle);
      final start = _where(puzzle, puzzle.solution[0]);

      final select = SignpostBoard(state: state).tapMove(start)!;
      expect(select.kind, MoveKind.select);
      final selected = select.apply(state);
      expect(selected.selected, puzzle.cellOfNumber(1));

      final drop = SignpostBoard(state: selected).tapMove(start)!;
      expect(drop.kind, MoveKind.select);
      expect(drop.apply(selected).selected, isNull);
    });

    test('tap the cell, then the place it points at', () {
      final puzzle = _puzzle(2);
      final first = _where(puzzle, 1);
      final second = _where(puzzle, 2);

      var state = _state(puzzle);
      state = SignpostBoard(state: state).tapMove(first)!.apply(state);
      final link = SignpostBoard(state: state).tapMove(second)!;
      expect(link.kind, MoveKind.place);
      expect(link.target, second);

      state = link.apply(state);
      expect(state.links[puzzle.cellOfNumber(1)], puzzle.cellOfNumber(2));
      expect(state.moves, 1);
      expect(state.position.numbers[puzzle.cellOfNumber(2)], 2);
    });

    test('a cell that already points somewhere gives its link back', () {
      final puzzle = _puzzle(3);
      final head = puzzle.cellOfNumber(1);
      final links = List<int>.filled(puzzle.cellCount, -1)
        ..[head] = puzzle.cellOfNumber(2);
      final state = _state(puzzle, links: links);

      final clear = SignpostBoard(state: state).tapMove(_where(puzzle, 1))!;
      expect(clear.kind, MoveKind.clear);
      final after = clear.apply(state);
      expect(after.links[head], -1);
    });

    test('the last number has nowhere to point', () {
      final puzzle = _puzzle(4);
      final state = _state(puzzle);
      final last = _where(puzzle, puzzle.cellCount);
      expect(SignpostBoard(state: state).tapMove(last), isNull);
      expect(SignpostBoard(state: state).movesFor(last), isEmpty);
    });
  });

  group('drag', () {
    test('a cell offers the cells its arrow runs through', () {
      final puzzle = _puzzle(5);
      final state = _state(puzzle);
      final board = SignpostBoard(state: state);

      final moves = board.movesFor(_where(puzzle, 1));
      expect(moves, isNotEmpty);
      for (final move in moves) {
        expect(move.isDraggable, isTrue);
      }
      // The answer's successor is one of them, and taking it is legal.
      final next = _where(puzzle, 2);
      final taken = moves.firstWhere((move) => move.target == next);
      final after = taken.apply(state);
      expect(_engine.isSolved(after.puzzle, after.links), isFalse);
      expect(after.links[puzzle.cellOfNumber(1)], puzzle.cellOfNumber(2));
    });

    test('a linked cell can be dragged somewhere else', () {
      final puzzle = _puzzle(6);
      final links = List<int>.filled(puzzle.cellCount, -1)
        ..[puzzle.cellOfNumber(1)] = puzzle.cellOfNumber(2);
      final state = _state(puzzle, links: links);
      final board = SignpostBoard(state: state);
      final moves = board.movesFor(_where(puzzle, 1));

      // The drag means "point here instead": the candidates are worked out
      // with the old link lifted, so a wrong arrow is corrected in one gesture.
      expect(moves, isNotEmpty);
      expect(
        moves.any((move) => move.target == _where(puzzle, 2)),
        isTrue,
      );
    });
  });

  group('the whole board', () {
    test('every tier can be finished by tapping alone', () {
      for (final difficulty in SignpostDifficulty.values) {
        final puzzle =
            _engine.generate(difficulty, random: Random(difficulty.index + 3));
        var state = SignpostState(
          puzzle: puzzle,
          links: List<int>.filled(puzzle.cellCount, -1),
          difficulty: difficulty,
        );

        // The last link is often not needed: when N is one of the given
        // numbers, the chain of 1..N-1 already numbers every cell.
        for (var number = 1;
            number < puzzle.cellCount && !state.isSolved;
            number++) {
          final from = _where(puzzle, number);
          final to = _where(puzzle, number + 1);

          final select = SignpostBoard(state: state).tapMove(from);
          expect(select, isNotNull,
              reason: '${difficulty.name}: cannot start ${number + 1}');
          state = select!.apply(state);

          final link = SignpostBoard(state: state).tapMove(to);
          expect(link, isNotNull,
              reason:
                  '${difficulty.name}: cannot join $number to ${number + 1}');
          state = link!.apply(state);
        }

        expect(state.isSolved, isTrue,
            reason: '${difficulty.name}: tapping out the answer did not win');
      }
    });

    test('every tier can be finished backwards by tapping alone', () {
      // The owner's reference: "you can work backwards, 16 then 15 then 14".
      // Joining the answer's last link first has to be as legal as joining the
      // first one, so this is the same walk as above in the other direction —
      // through the same two taps, select then link.
      for (final difficulty in SignpostDifficulty.values) {
        final puzzle =
            _engine.generate(difficulty, random: Random(difficulty.index + 4));
        var state = SignpostState(
          puzzle: puzzle,
          links: List<int>.filled(puzzle.cellCount, -1),
          difficulty: difficulty,
        );

        var links = 0;
        for (var number = puzzle.cellCount;
            number > 1 && !state.isSolved;
            number--) {
          final from = _where(puzzle, number - 1);
          final to = _where(puzzle, number);

          final select = SignpostBoard(state: state).tapMove(from);
          expect(select, isNotNull,
              reason: '${difficulty.name}: cannot start from ${number - 1}');
          state = select!.apply(state);

          final link = SignpostBoard(state: state).tapMove(to);
          expect(link, isNotNull,
              reason: '${difficulty.name}: cannot join ${number - 1} to '
                  '$number from the far end');
          // The number is on the board the moment the link is, not after an
          // animation: the move is the whole state.
          expect(link!.target, to,
              reason: '${difficulty.name}: the link named no destination');
          state = link.apply(state);
          expect(state.links[puzzle.cellOfNumber(number - 1)],
              puzzle.cellOfNumber(number),
              reason: '${difficulty.name}: the link did not land');
          links++;
        }

        expect(links, greaterThan(0));
        expect(state.isSolved, isTrue,
            reason: '${difficulty.name}: tapping backwards did not win');
      }
    });
  });

  group('same frame', () {
    // "The arrow appears the moment you move." The board is the links, and the
    // numbers are read off them, so a tap that lands has already changed what
    // the cell shows. Anything that draws the arrow later — a controller, a
    // settle spring, a second pass — is the lag the owner is talking about.
    testWidgets('a tap shows the link and its number after one frame',
        (tester) async {
      final puzzle = _puzzle(21);
      var state = _state(puzzle);

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              child: StatefulBuilder(
                builder: (context, setState) => PuzzleBoardView<SignpostState>(
                  board: SignpostBoard(state: state),
                  onMove: (move) => setState(() => state = move.apply(state)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final rect = tester.getRect(
        find.byWidgetPredicate((widget) => widget is PuzzleBoardView),
      );
      Offset pointOf(int number) {
        final bounds =
            SignpostBoard(state: state).boundsOf(_where(puzzle, number))!;
        return Offset(
          rect.left + rect.width * bounds.center.dx,
          rect.top + rect.height * bounds.center.dy,
        );
      }

      // The two taps a link takes: select the cell, then the place the arrow
      // runs to. One frame each, no settle.
      await tester.tapAt(pointOf(1));
      await tester.pump();
      expect(state.selected, puzzle.cellOfNumber(1));

      await tester.tapAt(pointOf(2));
      await tester.pump();

      expect(state.links[puzzle.cellOfNumber(1)], puzzle.cellOfNumber(2),
          reason: 'the link did not land in the frame of the tap');
      expect(state.position.numbers[puzzle.cellOfNumber(1)], 1,
          reason: 'the number the link proves is not on the board yet');
      expect(state.position.numbers[puzzle.cellOfNumber(2)], 2,
          reason: 'the second number the link proves is not on the board yet');
    });
  });
}
