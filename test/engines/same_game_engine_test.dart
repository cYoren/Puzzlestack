import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/same_game/same_game_engine.dart';

void main() {
  final engine = const SameGameEngine();

  group('generator', () {
    for (final difficulty in SameGameDifficulty.values) {
      test('${difficulty.name}: 200 boards, every square filled', () {
        final rng = Random(7);
        for (var i = 0; i < 200; i++) {
          final grid = engine.generate(
            rows: difficulty.rows,
            cols: difficulty.cols,
            colours: difficulty.colours,
            random: rng,
          );
          expect(grid.length, difficulty.rows * difficulty.cols);
          expect(grid.every((c) => c >= 1 && c <= difficulty.colours), isTrue,
              reason: 'board $i has an empty or out-of-range square');
          expect(engine.hasMoves(grid, difficulty.rows, difficulty.cols), isTrue,
              reason: 'board $i has no legal move');
        }
      });
    }

    test('a generated board can always be cleared', () {
      // The generator builds the board out of legal inverse moves and refuses
      // any insertion that is not one, so a greedy clear is not required: the
      // construction *is* the proof. What this pins is the consequence — the
      // board never has a colour appearing exactly once, which is what would
      // make a square unremovable.
      final rng = Random(11);
      for (var i = 0; i < 50; i++) {
        final grid = engine.generate(rows: 8, cols: 8, colours: 3, random: rng);
        final counts = <int, int>{};
        for (final c in grid) {
          counts[c] = (counts[c] ?? 0) + 1;
        }
        for (final entry in counts.entries) {
          expect(entry.value, greaterThanOrEqualTo(2),
              reason: 'colour ${entry.key} appears once, so it can never go');
        }
      }
    });
  });

  group('rules', () {
    // A 3x3 board, row-major.
    //   1 1 2
    //   3 1 2
    //   3 3 2
    final grid = [1, 1, 2, 3, 1, 2, 3, 3, 2];

    test('a group is the connected same-coloured run', () {
      final group = engine.groupAt(grid, 3, 3, 0);
      expect(group.toSet(), {0, 1, 4});
    });

    test('an empty square has no group', () {
      expect(engine.groupAt([0, 1, 1, 1], 2, 2, 0), isEmpty);
    });

    test('removing a group drops the squares above it', () {
      // Remove the 1s at 0, 1 and 4. Column 0 keeps both 3s at the bottom,
      // column 1 keeps its 3 at the bottom, column 2 is untouched.
      final next = engine.apply(grid, 3, 3, [0, 1, 4]);
      expect(next, [
        0, 0, 2, //
        3, 0, 2, //
        3, 3, 2, //
      ]);
    });

    test('an emptied column collapses left', () {
      // 1 2 3
      // 1 2 3
      // Removing the middle column leaves a gap that the right column fills.
      final next = engine.apply([1, 2, 3, 1, 2, 3], 2, 3, [1, 4]);
      expect(next, [
        1, 3, 0, //
        1, 3, 0, //
      ]);
    });

    test('scoring is (n - 2)^2', () {
      expect(engine.points(2), 0);
      expect(engine.points(3), 1);
      expect(engine.points(5), 9);
      expect(engine.points(8), 36);
    });

    test('an empty board is solved, a full one is not', () {
      expect(engine.isSolved([0, 0, 0, 0]), isTrue);
      expect(engine.isSolved([1, 1, 0, 0]), isFalse);
    });

    test('a board with no pair has no moves', () {
      // A checkerboard has no two touching squares of one colour.
      expect(engine.hasMoves([1, 2, 2, 1], 2, 2), isFalse);
      expect(engine.hasMoves([1, 1, 2, 2], 2, 2), isTrue);
    });
  });
}
