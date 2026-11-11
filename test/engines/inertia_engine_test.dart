import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_engine.dart';

void main() {
  const engine = InertiaEngine();

  group('generator', () {
    for (final difficulty in InertiaDifficulty.values) {
      test('${difficulty.name}: 20 boards, each solved by its own line', () {
        final rng = Random(difficulty.index + 61);
        for (var i = 0; i < 20; i++) {
          final puzzle = engine.generate(difficulty, random: rng);
          final where = '${difficulty.name} board $i';

          expect(puzzle.rows, difficulty.rows);
          expect(puzzle.cols, difficulty.cols);
          expect(puzzle.gemCells.length, difficulty.gems);
          expect(puzzle.gemCells.toSet().length, difficulty.gems,
              reason: '$where: a gem is placed twice');
          expect(puzzle.kindAt(puzzle.start), CellKind.floor,
              reason: '$where: the ball starts on something else');
          for (final cell in puzzle.gemCells) {
            expect(puzzle.kindAt(cell), CellKind.gem,
                reason: '$where: gem cell $cell is not a gem');
          }

          final line = engine.solve(puzzle);
          expect(line, isNotNull, reason: '$where: no line collects the gems');
          expect(line!.length, puzzle.minMoves,
              reason: '$where: minMoves is not the shortest line');

          // Replay: this is the proof the board can be finished, and it is what
          // catches rules that disagree with the solver.
          var position = engine.startOf(puzzle);
          for (final direction in line) {
            position = engine.move(puzzle, position, direction);
            expect(position.exploded, isFalse,
                reason: '$where: the line runs into a mine');
          }
          expect(engine.isSolved(puzzle, position), isTrue,
              reason: '$where: the line does not collect every gem');
        }
      });
    }
  });

  group('rules', () {
    test('the ball slides until a wall stops it, and cannot stop early', () {
      // A corridor: the ball must cross it in one move.
      final puzzle = InertiaPuzzle(
        rows: 3,
        cols: 6,
        kinds: [
          CellKind.wall, CellKind.wall, CellKind.wall, CellKind.wall,
          CellKind.wall, CellKind.wall, //
          CellKind.wall, CellKind.floor, CellKind.floor, CellKind.floor,
          CellKind.floor, CellKind.wall, //
          CellKind.wall, CellKind.wall, CellKind.wall, CellKind.wall,
          CellKind.wall, CellKind.wall,
        ],
        start: 7,
        gemCells: const [],
        minMoves: 0,
      );
      final start = engine.startOf(puzzle);
      expect(engine.landing(puzzle, start, InertiaDirection.east), 10);
      expect(engine.landing(puzzle, start, InertiaDirection.west), isNull,
          reason: 'the wall is right there, so the ball cannot move');
      expect(engine.landing(puzzle, start, InertiaDirection.north), isNull);
    });

    test('a mine is a loss, not a stop', () {
      final puzzle = InertiaPuzzle(
        rows: 1,
        cols: 4,
        kinds: [
          CellKind.floor,
          CellKind.floor,
          CellKind.mine,
          CellKind.floor,
        ],
        start: 0,
        gemCells: const [],
        minMoves: 0,
      );
      final start = engine.startOf(puzzle);
      final result = engine.move(puzzle, start, InertiaDirection.east);
      expect(result.exploded, isTrue, reason: 'the ball passed a mine');
      expect(result.cell, 1, reason: 'the ball stops just before the mine');
      expect(engine.landing(puzzle, start, InertiaDirection.east), isNull,
          reason: 'a losing move is not offered as a landing');
    });

    test('every gem is collected once, and only once', () {
      final puzzle = engine.generate(InertiaDifficulty.easy, random: Random(3));
      var position = engine.startOf(puzzle);
      final line = engine.solve(puzzle)!;
      var lastCount = -1;
      for (final direction in line) {
        position = engine.move(puzzle, position, direction);
        final count = position.collected;
        expect(count, isNot(lastCount),
            reason: 'a move in the shortest line collects nothing');
        lastCount = count;
      }
      expect(engine.isSolved(puzzle, position), isTrue);
    });

    test('retrying a board starts from scratch', () {
      final puzzle = engine.generate(InertiaDifficulty.easy, random: Random(5));
      final start = engine.startOf(puzzle);
      expect(start.collected, 0);
      expect(start.exploded, isFalse);
      expect(start.cell, puzzle.start);
    });
  });

  group('hint', () {
    test('names a move that still finishes the board', () {
      final rng = Random(7);
      for (var i = 0; i < 5; i++) {
        final puzzle = engine.generate(InertiaDifficulty.easy, random: rng);
        final position = engine.startOf(puzzle);
        final hint = engine.hint(puzzle, position);
        expect(hint, isNotNull);
        final after = engine.move(puzzle, position, hint!);
        expect(after.exploded, isFalse);
        expect(engine.solveFrom(puzzle, after), isNotNull,
            reason: 'board $i: the hinted move leads nowhere');
      }
    });
  });
}
