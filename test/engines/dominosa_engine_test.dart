import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/dominosa/dominosa_engine.dart';

void main() {
  const engine = DominosaEngine();

  group('generator', () {
    for (final difficulty in DominosaDifficulty.values) {
      test('${difficulty.name}: 20 boards, each with exactly one tiling', () {
        final rng = Random(41);
        for (var i = 0; i < 20; i++) {
          final puzzle = engine.generate(difficulty, random: rng);
          final n = puzzle.maxValue;

          expect(puzzle.rows, engine.rowsFor(n));
          expect(puzzle.cols, engine.colsFor(n));
          expect(puzzle.grid.every((v) => v >= 0 && v <= n), isTrue,
              reason: 'board $i has a value out of range');

          // The recorded tiling is a valid covering: every cell paired once,
          // every domino type used once.
          final seen = <int>{};
          final types = <int>{};
          for (var cell = 0; cell < puzzle.cellCount; cell++) {
            final other = puzzle.partner[cell];
            expect(other, isNot(-1), reason: 'board $i cell $cell unpaired');
            expect(puzzle.partner[other], cell);
            expect(engine.isAdjacent(cell, other, puzzle.cols), isTrue,
                reason: 'board $i pair $cell-$other is not adjacent');
            if (seen.add(cell)) {
              seen.add(other);
              types.add(engine.typeOf(puzzle.grid[cell], puzzle.grid[other]));
            }
          }
          expect(types.length, puzzle.dominoCount,
              reason: 'board $i repeats a domino type');

          // And nothing else covers it.
          expect(engine.countTilings(puzzle, limit: 2), 1,
              reason: 'board $i is not unique');
        }
      });
    }
  });

  group('rules', () {
    test('adjacency is orthogonal only', () {
      expect(engine.isAdjacent(0, 1, 5), isTrue);
      expect(engine.isAdjacent(0, 5, 5), isTrue);
      expect(engine.isAdjacent(0, 6, 5), isFalse);
      expect(engine.isAdjacent(1, 5, 5), isFalse);
    });

    test('a domino type is unordered', () {
      expect(engine.typeOf(2, 5), engine.typeOf(5, 2));
      expect(engine.typeName(engine.typeOf(2, 5)), '2-5');
    });

    test('the type set covers every pair once', () {
      final types = engine.typesFor(3);
      expect(types.length, 10);
      expect(types.toSet().length, 10);
    });
  });
}
