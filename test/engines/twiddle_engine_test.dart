import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_engine.dart';

void main() {
  const engine = TwiddleEngine();

  group('generator', () {
    test('200 boards are solvable by replaying the scramble backwards', () {
      final random = Random(20261110);

      for (var i = 0; i < 200; i++) {
        final difficulty =
            TwiddleDifficulty.values[i % TwiddleDifficulty.values.length];
        final puzzle = engine.generate(difficulty: difficulty, random: random);

        expect(puzzle.start.length, puzzle.tiles);
        expect(
          engine.isSolved(puzzle.start),
          isFalse,
          reason: 'board $i was handed out already solved',
        );
        expect(
          puzzle.start.toSet().length,
          puzzle.tiles,
          reason: 'board $i has a duplicate or missing tile',
        );

        var grid = [...puzzle.start];
        for (final move in puzzle.solution) {
          grid = engine.apply(grid, puzzle.size, move, puzzle.block);
        }
        expect(
          engine.isSolved(grid),
          isTrue,
          reason: 'board $i did not finish solved',
        );
      }
    });

    test('a scramble never undoes itself immediately', () {
      // A single move followed by its inverse would hand back the solved
      // board; the generator rejects that, so no board comes out solved.
      final random = Random(5);
      for (var i = 0; i < 50; i++) {
        final puzzle = engine.generate(random: random);
        expect(engine.isSolved(puzzle.start), isFalse);
      }
    });

    test('difficulty changes size, block and scramble length', () {
      expect(TwiddleDifficulty.easy.size, lessThan(TwiddleDifficulty.medium.size));
      expect(TwiddleDifficulty.medium.size, lessThan(TwiddleDifficulty.hard.size));
      expect(
        TwiddleDifficulty.easy.scrambles,
        lessThan(TwiddleDifficulty.hard.scrambles),
      );
      expect(TwiddleDifficulty.hard.block, greaterThan(TwiddleDifficulty.easy.block));
    });
  });

  group('turns', () {
    test('a clockwise turn rotates the block', () {
      // 2x2 block, clockwise: top-left goes to top-right.
      final grid = [1, 2, 3, 4];
      final after = engine.apply(grid, 2, const TwiddleMove(0, 0, true), 2);
      expect(after, [3, 1, 4, 2]);
    });

    test('an anticlockwise turn is the inverse', () {
      final grid = [1, 2, 3, 4];
      final cw = engine.apply(grid, 2, const TwiddleMove(0, 0, true), 2);
      final back = engine.apply(cw, 2, const TwiddleMove(0, 0, false), 2);
      expect(back, grid);
    });

    test('four quarter turns return the board', () {
      final grid = engine.solvedGrid(4);
      var current = grid;
      for (var i = 0; i < 4; i++) {
        current = engine.apply(current, 4, const TwiddleMove(1, 1, true), 2);
      }
      expect(current, grid);
    });

    test('a turn leaves cells outside the block alone', () {
      final grid = engine.solvedGrid(3);
      final after = engine.apply(grid, 3, const TwiddleMove(0, 0, true), 2);
      // (2,2) and (2,0) sit outside the 2x2 block at the top left.
      expect(after[8], grid[8]);
      expect(after[6], grid[6]);
    });

    test('the centre of an odd block never moves', () {
      final puzzle = engine.generate(
        difficulty: TwiddleDifficulty.hard,
        random: Random(1),
      );
      final move = const TwiddleMove(0, 0, true);
      final (row, col) = engine.destinationOf(1, 1, move, 3);
      expect((row, col), (1, 1));
      expect(puzzle.block, 3);
    });

    test('destinationOf agrees with apply for every cell of a block', () {
      final grid = engine.solvedGrid(4);
      const move = TwiddleMove(1, 1, false);
      final after = engine.apply(grid, 4, move, 2);

      for (var row = 1; row < 3; row++) {
        for (var col = 1; col < 3; col++) {
          final (toRow, toCol) = engine.destinationOf(row, col, move, 2);
          expect(after[toRow * 4 + toCol], grid[row * 4 + col]);
        }
      }
    });
  });

  group('moves offered to the player', () {
    test('every turn of a tile actually moves that tile', () {
      const size = 5;
      const block = 3;
      for (var row = 0; row < size; row++) {
        for (var col = 0; col < size; col++) {
          for (final move in engine.turnsForTile(size, block, row, col)) {
            final (toRow, toCol) = engine.destinationOf(row, col, move, block);
            expect(
              (toRow, toCol),
              isNot((row, col)),
              reason: 'tile ($row,$col) was offered a turn that does nothing',
            );
          }
        }
      }
    });

    test('a tap always turns something', () {
      const size = 4;
      const block = 2;
      for (var row = 0; row < size; row++) {
        for (var col = 0; col < size; col++) {
          final move = engine.tapTurn(size, block, row, col);
          expect(move, isNotNull, reason: 'tile ($row,$col) cannot be tapped');
          final (toRow, toCol) = engine.destinationOf(row, col, move!, block);
          expect((toRow, toCol), isNot((row, col)));
        }
      }
    });

    test('tapTurn is deterministic', () {
      final a = engine.tapTurn(5, 3, 2, 2);
      final b = engine.tapTurn(5, 3, 2, 2);
      expect(a, b);
    });
  });

  group('hint', () {
    test('a hint is always a real turn', () {
      final random = Random(42);
      for (var i = 0; i < 30; i++) {
        final puzzle = engine.generate(
          difficulty: TwiddleDifficulty.values[i % 3],
          random: random,
        );
        final move = engine.hint(puzzle.start, puzzle.size, puzzle.block);

        expect(move, isNotNull, reason: 'board $i has no hint');
        final after = engine.apply(
          puzzle.start,
          puzzle.size,
          move!,
          puzzle.block,
        );
        expect(
          after,
          isNot(puzzle.start),
          reason: 'board $i: the hint was a no-op',
        );
      }
    });

    test('a hint never makes the board worse', () {
      final random = Random(7);
      for (var i = 0; i < 30; i++) {
        final puzzle = engine.generate(
          difficulty: TwiddleDifficulty.values[i % 3],
          random: random,
        );
        final before = engine.correctCount(puzzle.start);
        final move = engine.hint(puzzle.start, puzzle.size, puzzle.block)!;
        final after = engine.apply(
          puzzle.start,
          puzzle.size,
          move,
          puzzle.block,
        );
        expect(
          engine.correctCount(after),
          greaterThanOrEqualTo(before),
          reason: 'board $i: the hint made things worse',
        );
      }
    });

    test('a solved board has no hint', () {
      expect(engine.hint(engine.solvedGrid(3), 3, 2), isNull);
    });
  });
}
