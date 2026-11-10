import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/pegs/pegs_engine.dart';

void main() {
  const engine = PegsEngine();

  group('generator', () {
    test('200 boards are solvable by replaying the line they were built from',
        () {
      final random = Random(20261110);

      for (var i = 0; i < 200; i++) {
        final difficulty = PegsDifficulty.values[i % PegsDifficulty.values.length];
        final puzzle = engine.generate(difficulty: difficulty, random: random);

        expect(
          puzzle.solution,
          isNotEmpty,
          reason: 'board $i has no solution line',
        );

        // Replay the generator's reverse play forwards. If the generator is
        // right, this must end on exactly one peg.
        var grid = [...puzzle.start];
        for (final jump in puzzle.solution) {
          final legal = engine.legalJumps(grid, puzzle.rows, puzzle.cols);
          expect(
            legal,
            contains(jump),
            reason: 'board $i: jump $jump is not legal at step '
                '${puzzle.solution.indexOf(jump)}',
          );
          grid = engine.apply(grid, jump);
        }

        expect(
          engine.countPegs(grid),
          1,
          reason: 'board $i did not finish on a single peg',
        );
        expect(engine.isSolved(grid), isTrue);
      }
    });

    test('a generated board is never already solved', () {
      final random = Random(7);
      for (var i = 0; i < 40; i++) {
        final puzzle = engine.generate(random: random);
        expect(puzzle.pegs, greaterThan(1));
      }
    });

    test('the board reaches all four edges', () {
      final random = Random(99);
      for (var i = 0; i < 40; i++) {
        final puzzle = engine.generate(random: random);
        final grid = puzzle.start;
        final rows = puzzle.rows;
        final cols = puzzle.cols;

        bool anyOn(bool Function(int row, int col) test) {
          for (var row = 0; row < rows; row++) {
            for (var col = 0; col < cols; col++) {
              if (test(row, col) &&
                  grid[row * cols + col] != PegCell.obstacle) {
                return true;
              }
            }
          }
          return false;
        }

        expect(anyOn((r, c) => c == 0), isTrue, reason: 'board $i: left edge');
        expect(anyOn((r, c) => c == cols - 1), isTrue,
            reason: 'board $i: right edge');
        expect(anyOn((r, c) => r == 0), isTrue, reason: 'board $i: top edge');
        expect(anyOn((r, c) => r == rows - 1), isTrue,
            reason: 'board $i: bottom edge');
      }
    });

    test('difficulty changes the size of the board', () {
      expect(PegsDifficulty.easy.rows, lessThan(PegsDifficulty.medium.rows));
      expect(PegsDifficulty.medium.rows, lessThan(PegsDifficulty.hard.rows));

      final random = Random(3);
      final easy = engine.generate(difficulty: PegsDifficulty.easy, random: random);
      final hard = engine.generate(difficulty: PegsDifficulty.hard, random: random);
      expect(easy.rows * easy.cols, lessThan(hard.rows * hard.cols));
      // A bigger board carries more pegs, which is what makes it deeper.
      expect(hard.playable, greaterThan(easy.playable));
    });
  });

  group('rules', () {
    // A one-dimensional board is enough to pin the jump rules down.
    //   . P P .   ->   . . . P
    List<PegCell> row(List<String> cells) => [
          for (final cell in cells)
            switch (cell) {
              'P' => PegCell.peg,
              '.' => PegCell.hole,
              _ => PegCell.obstacle,
            },
        ];

    test('a peg jumps over its neighbour into an empty square', () {
      final grid = row(['P', 'P', '.']);
      final jumps = engine.legalJumps(grid, 1, 3);
      expect(jumps, [const PegsJump(0, 1, 2)]);

      final after = engine.apply(grid, const PegsJump(0, 1, 2));
      expect(after, row(['.', '.', 'P']));
    });

    test('a peg cannot jump over a hole', () {
      expect(engine.legalJumps(row(['P', '.', '.']), 1, 3), isEmpty);
    });

    test('a peg cannot land on another peg', () {
      expect(engine.legalJumps(row(['P', 'P', 'P']), 1, 3), isEmpty);
    });

    test('a jump cannot leave the board', () {
      expect(engine.legalJumps(row(['P', 'P']), 1, 2), isEmpty);
    });

    test('obstacles are never jumped into', () {
      expect(engine.legalJumps(row(['P', 'P', 'O']), 1, 3), isEmpty);
    });

    test('solved means exactly one peg', () {
      expect(engine.isSolved(row(['P', '.', 'O'])), isTrue);
      expect(engine.isSolved(row(['P', 'P', '.'])), isFalse);
      expect(engine.isSolved(row(['.', '.', '.'])), isFalse);
    });
  });

  group('solver', () {
    test('any line it returns is legal and finishes on one peg', () {
      final random = Random(11);
      var solved = 0;

      for (var i = 0; i < 20; i++) {
        final puzzle = engine.generate(
          difficulty: PegsDifficulty.easy,
          random: random,
        );
        final line = engine.solve(puzzle.start, puzzle.rows, puzzle.cols);
        if (line == null) continue;
        solved++;

        var grid = [...puzzle.start];
        for (final jump in line) {
          expect(
            engine.legalJumps(grid, puzzle.rows, puzzle.cols),
            contains(jump),
            reason: 'board $i produced an illegal jump',
          );
          grid = engine.apply(grid, jump);
        }
        expect(engine.countPegs(grid), 1, reason: 'board $i did not finish');
      }

      // The search is bounded, not exhaustive: on a hard instance it gives up
      // and the hint falls back to the board's own line. It still has to
      // finish most boards, which is what this pins down.
      expect(solved, greaterThanOrEqualTo(15));
    });

    test('returns null when no line exists', () {
      // Two pegs side by side with nowhere to land can never be finished.
      final grid = [
        PegCell.peg,
        PegCell.peg,
        PegCell.obstacle,
      ];
      expect(engine.solve(grid, 1, 3), isNull);
    });

    test('a solved board has an empty line', () {
      final grid = [PegCell.peg, PegCell.obstacle, PegCell.obstacle];
      expect(engine.solve(grid, 1, 3), isEmpty);
    });
  });
}
