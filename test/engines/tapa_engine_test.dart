import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/tapa/tapa_engine.dart';

void main() {
  group('TapaEngine', () {
    test('generatePuzzle creates uniquely solvable 5x5 boards', () {
      final rng = Random(42);
      for (int i = 0; i < 15; i++) {
        final puzzle = TapaEngine.generatePuzzle(size: 5, random: rng);
        expect(puzzle.size, 5);
        expect(
          TapaEngine.countSolutions(puzzle.grid, puzzle.size, limit: 2),
          1,
          reason: 'Board $i must have a unique solution',
        );

        final solvedGrid = [
          for (int r = 0; r < puzzle.size; r++)
            [
              for (int c = 0; c < puzzle.size; c++)
                TapaCell(
                  row: r,
                  col: c,
                  clues: puzzle.grid[r][c].clues,
                  state: puzzle.solutionBlack[r][c]
                      ? TapaCellState.black
                      : TapaCellState.white,
                ),
            ],
        ];
        expect(TapaEngine.isSolved(solvedGrid, puzzle.size), isTrue);
      }
    });

    test('isSolved rejects 2x2 black blocks and disconnected walls', () {
      final grid2x2 = List.generate(
        4,
        (r) => List.generate(
          4,
          (c) => TapaCell(
            row: r,
            col: c,
            state: (r < 2 && c < 2) ? TapaCellState.black : TapaCellState.white,
          ),
        ),
      );
      expect(TapaEngine.isSolved(grid2x2, 4), isFalse);

      final disconnected = List.generate(
        4,
        (r) => List.generate(
          4,
          (c) => TapaCell(
            row: r,
            col: c,
            state: ((r == 0 && c == 0) || (r == 3 && c == 3))
                ? TapaCellState.black
                : TapaCellState.white,
          ),
        ),
      );
      expect(TapaEngine.isSolved(disconnected, 4), isFalse);
    });
  });
}
