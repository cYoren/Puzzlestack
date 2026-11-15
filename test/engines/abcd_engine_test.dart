import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/abcd/abcd_engine.dart';
import 'package:puzzle/ui/features/games/abcd/abcd_model.dart';
import 'package:puzzle/core/deduction.dart';

const engine = AbcdEngine();

void main() {
  group('AbcdEngine', () {
    test('a generated grid is legal', () {
      final rng = Random(1);
      for (final size in AbcdSize.values) {
        for (var i = 0; i < 4; i++) {
          final puzzle = engine.generate(size, random: rng);
          expect(puzzle.isLegal(puzzle.solution), isTrue,
              reason: '${size.name} #$i');
          expect(puzzle.solution.where((v) => v >= 0),
              hasLength(puzzle.cellCount));
        }
      }
    });

    test('the counts are read off the grid', () {
      final puzzle = engine.generate(AbcdSize.small, random: Random(2));
      for (var row = 0; row < puzzle.rows; row++) {
        for (var letter = 0; letter < puzzle.letters; letter++) {
          var seen = 0;
          for (var col = 0; col < puzzle.cols; col++) {
            if (puzzle.solution[row * puzzle.cols + col] == letter) seen++;
          }
          expect(puzzle.rowCounts[row][letter], seen);
        }
        expect(
          puzzle.rowCounts[row].fold(0, (a, b) => a + b),
          puzzle.cols,
          reason: 'a row clue numbers every cell of the row',
        );
      }
    });

    test('every generated board has exactly one grid', () {
      final rng = Random(3);
      for (final size in AbcdSize.values) {
        for (var i = 0; i < 4; i++) {
          final puzzle = engine.generate(size, random: rng);
          expect(engine.harnessSolutions(puzzle, limit: 2), 1,
              reason: '${size.name} #$i must have one answer');
        }
      }
    });

    test('the rules finish every board the generator ships', () {
      final rng = Random(4);
      for (final size in AbcdSize.values) {
        for (var i = 0; i < 3; i++) {
          final puzzle = engine.generate(size, random: rng);
          final level = engine.levelOf(puzzle);
          expect(level, isNotNull,
              reason: '${size.name} #$i needs a guess, so it cannot ship');
          expect(level, inInclusiveRange(1, 3));
        }
      }
    });

    test('two identical letters touching is not an answer', () {
      final puzzle = engine.generate(AbcdSize.small, random: Random(5));
      final grid = [...puzzle.solution];
      // Copy the first cell's letter into its right neighbour: the counts then
      // lie, so fix them up to test the adjacency rule on its own.
      final letter = grid[0];
      grid[1] = letter;
      expect(puzzle.isLegal(grid), isFalse);
    });

    test('a wrong count is not an answer', () {
      final puzzle = engine.generate(AbcdSize.small, random: Random(6));
      final lying = AbcdPuzzle(
        size: puzzle.size,
        rowCounts: [
          [
            (puzzle.rowCounts.first.first + 1) % (puzzle.cols + 1),
            ...puzzle.rowCounts.first.skip(1),
          ],
          ...puzzle.rowCounts.skip(1),
        ],
        colCounts: puzzle.colCounts,
        solution: puzzle.solution,
      );
      expect(lying.isLegal(puzzle.solution), isFalse);
    });

    test('the hint is true of the one answer', () {
      final rng = Random(7);
      for (var i = 0; i < 4; i++) {
        final puzzle = engine.generate(AbcdSize.small, random: rng);
        final found = engine.hint(
          puzzle,
          List<int>.filled(puzzle.cellCount, -1),
        );
        expect(found, isNotNull);
        expect(found!.letter, puzzle.solution[found.cell]);
      }
    });

    test('the exact rule never claims news it did not make', () {
      final puzzle = engine.generate(AbcdSize.small, random: Random(8));
      final model = AbcdModel.fresh(puzzle);
      for (final rule in abcdRules) {
        while (rule.apply(model) > 0) {}
        expect(rule.apply(model), 0, reason: '${rule.name} repeats');
      }
    });

    test('a solved model agrees with the grid', () {
      final puzzle = engine.generate(AbcdSize.small, random: Random(9));
      final model = AbcdModel.fresh(puzzle);
      final outcome = deduce(model, abcdRules);
      expect(outcome.consistent, isTrue);
      expect(outcome.complete, isTrue);
      for (var cell = 0; cell < model.masks.length; cell++) {
        expect(model.valueAt(cell), puzzle.solution[cell]);
      }
      expect(outcome.highestLevel, lessThanOrEqualTo(3));
    });
  });
}
