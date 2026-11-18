import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/tenner_grid/tenner_grid_engine.dart';

void main() {
  group('TennerGridEngine', () {
    test('generatePuzzle yields varied unique-solution 3x10 boards', () {
      final rng = Random(42);
      final signatures = <String>{};
      for (int i = 0; i < 15; i++) {
        final puzzle = TennerGridEngine.generatePuzzle(random: rng);
        expect(puzzle.rows, 3);
        expect(puzzle.cols, 10);
        expect(
          TennerGridEngine.isSolved(puzzle.solution, puzzle.colSums),
          isTrue,
        );
        final grid = [
          for (int r = 0; r < puzzle.rows; r++)
            [
              for (int c = 0; c < puzzle.cols; c++)
                puzzle.fixed[r][c] ? puzzle.solution[r][c] : -1,
            ],
        ];
        expect(
          TennerGridEngine.countSolutions(grid, puzzle.colSums),
          1,
          reason: 'Board $i must have a unique solution',
        );
        signatures.add(puzzle.colSums.join(','));
      }
      expect(signatures.length, greaterThan(5));
    });

    test('isSolved enforces row uniqueness, column sums, and diagonal distinctness', () {
      final puzzle = TennerGridEngine.generatePuzzle(random: Random(7));
      expect(TennerGridEngine.isSolved(puzzle.solution, puzzle.colSums), isTrue);

      final badSum = List<int>.from(puzzle.colSums);
      badSum[0] += 1;
      expect(TennerGridEngine.isSolved(puzzle.solution, badSum), isFalse);

      // Swap two cells in row 0 to keep row uniqueness while creating diagonal/column error.
      final swapped = [for (final r in puzzle.solution) List<int>.from(r)];
      final tmp = swapped[0][0];
      swapped[0][0] = swapped[0][1];
      swapped[0][1] = tmp;
      expect(TennerGridEngine.isSolved(swapped, puzzle.colSums), isFalse);
    });
  });
}
