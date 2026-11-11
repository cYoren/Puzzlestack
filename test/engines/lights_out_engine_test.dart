import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_engine.dart';

void main() {
  const engine = LightsOutEngine();

  group('generator', () {
    for (final difficulty in LightsOutDifficulty.values) {
      test('${difficulty.name}: 200 boards, each with exactly one solution', () {
        final rng = Random(3);
        for (var i = 0; i < 200; i++) {
          final puzzle = engine.generate(difficulty, random: rng);
          expect(puzzle.start.length, difficulty.size * difficulty.size);
          expect(engine.isSolved(puzzle.start), isFalse,
              reason: 'board $i starts solved');

          // The recorded presses really do clear it.
          var grid = puzzle.start;
          for (final index in puzzle.solution) {
            grid = engine.press(grid, difficulty.size, index);
          }
          expect(engine.isSolved(grid), isTrue,
              reason: 'board $i: the recorded solution does not clear it');

          // And nothing else does.
          expect(engine.countSolutions(puzzle.start, difficulty.size), 1,
              reason: 'board $i is not unique');
        }
      });
    }

    test('the solution weight lands inside the tier', () {
      final rng = Random(5);
      for (final difficulty in LightsOutDifficulty.values) {
        for (var i = 0; i < 50; i++) {
          final puzzle = engine.generate(difficulty, random: rng);
          expect(puzzle.solution.length,
              inInclusiveRange(difficulty.minPresses, difficulty.maxPresses));
        }
      }
    });
  });

  group('the matrix', () {
    test('3x3, 6x6 and 8x8 are invertible; 4x4 and 5x5 are not', () {
      // The table in the engine is a claim, so it is checked rather than
      // trusted: a full-rank matrix means one solution per solvable board.
      expect(engine.countSolutions(List<bool>.filled(9, false), 3), 1);
      expect(engine.countSolutions(List<bool>.filled(36, false), 6), 1);
      expect(engine.countSolutions(List<bool>.filled(64, false), 8), 1);
      expect(engine.countSolutions(List<bool>.filled(16, false), 4), 16);
      expect(engine.countSolutions(List<bool>.filled(25, false), 5), 4);
    });
  });

  group('rules', () {
    test('a press flips the cell and its orthogonal neighbours', () {
      final grid = List<bool>.filled(9, false);
      final after = engine.press(grid, 3, 4); // centre
      expect(after, [false, true, false, true, true, true, false, true, false]);
    });

    test('a corner press flips three cells', () {
      final after = engine.press(List<bool>.filled(9, false), 3, 0);
      expect(after.where((lit) => lit).length, 3);
    });

    test('pressing the same cell twice is the identity', () {
      final grid = [true, false, true, false, false, false, true, false, true];
      final twice = engine.press(engine.press(grid, 3, 4), 3, 4);
      expect(twice, grid);
    });

    test('a dark board is solved', () {
      expect(engine.isSolved(List<bool>.filled(9, false)), isTrue);
      expect(engine.isSolved([true, ...List<bool>.filled(8, false)]), isFalse);
    });
  });
}
