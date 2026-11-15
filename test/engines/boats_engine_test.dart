import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/boats/boats_engine.dart';
import 'package:puzzle/ui/features/games/boats/boats_model.dart';

const engine = BoatsEngine();

void main() {
  group('BoatsEngine', () {
    test('a generated board is a legal fleet', () {
      final rng = Random(1);
      for (final size in BoatsSize.values) {
        for (var i = 0; i < 4; i++) {
          final puzzle = engine.generate(size, random: rng);
          expect(puzzle.isLegal(puzzle.solution), isTrue,
              reason: '${size.name} #$i');
          expect(puzzle.runsOf(puzzle.solution), puzzle.fleet,
              reason: '${size.name} #$i');
        }
      }
    });

    test('the counts are read off the answer, not chosen', () {
      final puzzle = engine.generate(BoatsSize.small, random: Random(2));
      for (var row = 0; row < puzzle.rows; row++) {
        var ships = 0;
        for (var col = 0; col < puzzle.cols; col++) {
          if (puzzle.solution[row * puzzle.cols + col] == kBoatShip) ships++;
        }
        expect(puzzle.rowCounts[row], ships, reason: 'row $row');
      }
      for (var col = 0; col < puzzle.cols; col++) {
        var ships = 0;
        for (var row = 0; row < puzzle.rows; row++) {
          if (puzzle.solution[row * puzzle.cols + col] == kBoatShip) ships++;
        }
        expect(puzzle.colCounts[col], ships, reason: 'col $col');
      }
      expect(
        puzzle.rowCounts.fold(0, (a, b) => a + b),
        puzzle.colCounts.fold(0, (a, b) => a + b),
      );
      expect(
          puzzle.rowCounts.fold(0, (a, b) => a + b), BoatsSize.small.shipCells);
    });

    test('every generated board has exactly one fleet', () {
      final rng = Random(3);
      for (final size in BoatsSize.values) {
        for (var i = 0; i < 6; i++) {
          final puzzle = engine.generate(size, random: rng);
          final count = engine.count(puzzle, limit: 2);
          expect(count.truncated, isFalse, reason: '${size.name} #$i budget');
          expect(count.solutions, 1,
              reason: '${size.name} #$i must have one answer');
          // The unique fleet the search found is the one the generator holds.
          expect(puzzle.isLegal(puzzle.solution), isTrue);
        }
      }
    });

    test('the rules finish every board the generator ships', () {
      final rng = Random(4);
      for (final size in BoatsSize.values) {
        for (var i = 0; i < 4; i++) {
          final puzzle = engine.generate(size, random: rng);
          final level = engine.levelOf(puzzle);
          expect(level, isNotNull,
              reason: '${size.name} #$i needs a guess, so it cannot ship');
          expect(level, inInclusiveRange(1, 3));
          expect(engine.harnessSolutions(puzzle, limit: 2), 1);
        }
      }
    });

    test('an incomplete fleet is not an answer', () {
      final puzzle = engine.generate(BoatsSize.small, random: Random(5));
      final wrong = List<int>.filled(puzzle.cellCount, kBoatWater);
      expect(puzzle.isLegal(wrong), isFalse);
      // Every boat cell but one.
      final almost = [...puzzle.solution];
      final ship = almost.indexOf(kBoatShip);
      almost[ship] = kBoatWater;
      expect(puzzle.isLegal(almost), isFalse);
    });

    test('two boats touching at a corner are not an answer', () {
      // 2x3 with two single-cell boats side by side diagonally, and counts that
      // match: the runs have the right lengths but the boats touch.
      final puzzle = BoatsPuzzle(
        size: BoatsSize.small,
        rowCounts: const [1, 1, 0, 0, 0, 0],
        colCounts: const [1, 1, 0, 0, 0, 0],
        fleet: const [1, 1],
        solution: [
          kBoatShip, kBoatWater, kBoatWater, kBoatWater, kBoatWater,
          kBoatWater, //
          kBoatWater, kBoatShip, kBoatWater, kBoatWater, kBoatWater,
          kBoatWater, //
          ...List<int>.filled(24, kBoatWater),
        ],
      );
      expect(puzzle.matchesClues(puzzle.solution), isTrue);
      expect(puzzle.isLegal(puzzle.solution), isFalse);
    });

    test('a wrong row count is not an answer', () {
      final puzzle = engine.generate(BoatsSize.small, random: Random(6));
      final lying = BoatsPuzzle(
        size: puzzle.size,
        rowCounts: [
          (puzzle.rowCounts.first + 1) % (puzzle.cols + 1),
          ...puzzle.rowCounts.skip(1),
        ],
        colCounts: puzzle.colCounts,
        fleet: puzzle.fleet,
        solution: puzzle.solution,
      );
      expect(lying.isLegal(puzzle.solution), isFalse);
    });

    test('the hint never points at a cell that disagrees with the answer', () {
      final rng = Random(7);
      for (var i = 0; i < 5; i++) {
        final puzzle = engine.generate(BoatsSize.small, random: rng);
        final marks = List<int>.filled(puzzle.cellCount, 0);
        final found = engine.hint(puzzle, marks);
        expect(found, isNotNull, reason: 'a fair board always has a step');
        expect(found!.value, puzzle.solution[found.cell],
            reason: 'the hint must be true of the one answer');
      }
    });

    test('the model never reports progress it did not make', () {
      // The deduction loop hangs rather than fails when a rule claims news on
      // a board that already knows what it said.
      final puzzle = engine.generate(BoatsSize.small, random: Random(8));
      final model = BoatsModel.fresh(puzzle);
      for (final rule in boatsRules) {
        while (rule.apply(model) > 0) {}
        expect(rule.apply(model), 0, reason: '${rule.name} repeats');
      }
    });
  });
}
