import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/deduction.dart';
import 'package:puzzle/ui/features/games/skyscrapers/skyscrapers_engine.dart';

void main() {
  const engine = SkyscrapersEngine();

  test('visibility counts records from one end', () {
    expect(engine.visible([1, 2, 3, 4]), 4);
    expect(engine.visible([4, 3, 2, 1]), 1);
    expect(engine.visible([2, 1, 4, 3]), 2);
    expect(engine.visible([3, 1, 2, 4]), 2);
  });

  group('generator', () {
    for (final difficulty in SkyscrapersDifficulty.values) {
      test('${difficulty.name}: 40 boards, each unique and solvable by logic', () {
        final rng = Random(17);
        for (var i = 0; i < 40; i++) {
          final puzzle = engine.generate(difficulty, random: rng);
          final n = puzzle.n;

          // The solution is a Latin square.
          for (var row = 0; row < n; row++) {
            final line = [for (var col = 0; col < n; col++) puzzle.solution[row * n + col]];
            expect(line.toSet().length, n, reason: 'board $i row $row');
          }
          for (var col = 0; col < n; col++) {
            final line = [for (var row = 0; row < n; row++) puzzle.solution[row * n + col]];
            expect(line.toSet().length, n, reason: 'board $i col $col');
          }

          // The clues match the solution.
          for (var col = 0; col < n; col++) {
            final column = [for (var row = 0; row < n; row++) puzzle.solution[row * n + col]];
            if (puzzle.top[col] != 0) {
              expect(engine.visible(column), puzzle.top[col]);
            }
            if (puzzle.bottom[col] != 0) {
              expect(engine.visible(column.reversed.toList()), puzzle.bottom[col]);
            }
          }
          for (var row = 0; row < n; row++) {
            final line = [for (var col = 0; col < n; col++) puzzle.solution[row * n + col]];
            if (puzzle.left[row] != 0) {
              expect(engine.visible(line), puzzle.left[row]);
            }
            if (puzzle.right[row] != 0) {
              expect(engine.visible(line.reversed.toList()), puzzle.right[row]);
            }
          }

          // Exactly one answer, and the rules reach it.
          final rating = engine.rating(puzzle);
          expect(rating.verdict, PuzzleVerdict.solved,
              reason: 'board $i: $rating');
          expect(rating.solutions, 1);
          expect(rating.level, inInclusiveRange(1, 3));
        }
      });
    }

    test('clue removal stops at the tier floor', () {
      final rng = Random(23);
      for (final difficulty in SkyscrapersDifficulty.values) {
        final puzzle = engine.generate(difficulty, random: rng);
        expect(puzzle.clueCount, greaterThanOrEqualTo(difficulty.minClues));
        expect(puzzle.clueCount, lessThanOrEqualTo(4 * difficulty.n));
      }
    });
  });
}
