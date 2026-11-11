import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/deduction.dart';
import 'package:puzzle/ui/features/games/futoshiki/futoshiki_engine.dart';

void main() {
  const engine = FutoshikiEngine();

  group('generator', () {
    for (final difficulty in FutoshikiDifficulty.values) {
      test('${difficulty.name}: 30 boards, each unique and solvable by logic', () {
        final rng = Random(29);
        for (var i = 0; i < 30; i++) {
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

          // Every inequality agrees with the solution.
          for (var row = 0; row < n; row++) {
            for (var col = 0; col + 1 < n; col++) {
              final edge = puzzle.horizontal[row * (n - 1) + col];
              if (edge == 0) continue;
              final a = puzzle.solution[row * n + col];
              final b = puzzle.solution[row * n + col + 1];
              expect(edge == 1 ? a < b : a > b, isTrue,
                  reason: 'board $i horizontal $row,$col');
            }
          }
          for (var row = 0; row + 1 < n; row++) {
            for (var col = 0; col < n; col++) {
              final edge = puzzle.vertical[row * n + col];
              if (edge == 0) continue;
              final a = puzzle.solution[row * n + col];
              final b = puzzle.solution[(row + 1) * n + col];
              expect(edge == 1 ? a < b : a > b, isTrue,
                  reason: 'board $i vertical $row,$col');
            }
          }

          // Givens agree with the solution.
          puzzle.givens.forEach((cell, value) {
            expect(puzzle.solution[cell], value, reason: 'board $i given $cell');
          });

          final rating = engine.rating(puzzle);
          expect(rating.verdict, PuzzleVerdict.solved, reason: 'board $i: $rating');
          expect(rating.solutions, 1);
        }
      });
    }

    test('hard boards keep few inequalities', () {
      final rng = Random(31);
      final puzzle = engine.generate(FutoshikiDifficulty.hard, random: rng);
      final total = puzzle.n * (puzzle.n - 1) * 2;
      expect(puzzle.inequalityCount, lessThan(total));
    });
  });
}
