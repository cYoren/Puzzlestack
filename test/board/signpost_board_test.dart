import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
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
  });
}
