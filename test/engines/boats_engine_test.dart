import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/boats/boats_engine.dart';
import 'package:puzzle/ui/features/games/boats/boats_model.dart';
import 'package:puzzle/ui/features/games/boats/boats_provider.dart';

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
        // The hint speaks the player's vocabulary, so the answer has to be
        // translated before it can be compared.
        expect(found!.value, markOfSolution(puzzle.solution[found.cell]),
            reason: 'the hint must be true of the one answer');
      }
    });

    test('untouched is its own state, not water', () {
      // The bug this pins: `kBoatWater` was 0, the player's untouched mark was
      // 0, so tapping cycled 0 -> 1 -> 0, the board drew a water dot on every
      // cell and a dealt board looked finished. Three states need three values.
      expect(kMarkEmpty, isNot(kMarkWater));
      expect(kMarkEmpty, isNot(kMarkShip));
      expect(kMarkWater, isNot(kMarkShip));
    });

    test('a tap cycles untouched, boat, water and back', () {
      var mark = kMarkEmpty;
      mark = nextMark(mark);
      expect(mark, kMarkShip);
      mark = nextMark(mark);
      expect(mark, kMarkWater);
      mark = nextMark(mark);
      expect(mark, kMarkEmpty);
    });

    test('a dealt board with nothing marked is not solved', () {
      // With untouched == water this was true only by accident; with the two
      // separate it is the check that the board does not ship pre-solved.
      final puzzle = engine.generate(BoatsSize.small, random: Random(10));
      expect(
        puzzle.isSolvedMarks(List<int>.filled(puzzle.cellCount, kMarkEmpty)),
        isFalse,
      );
      expect(
        puzzle.isSolvedMarks(List<int>.filled(puzzle.cellCount, kMarkWater)),
        isFalse,
      );
    });

    test('one marked boat crosses off one required boat', () {
      // The fleet has two boats of length 3, so the strip used to cross both
      // chips off the moment the player marked one of them.
      final rows = BoatsSize.small.rows;
      final cols = BoatsSize.small.cols;
      final marks = List<int>.filled(rows * cols, kMarkEmpty);
      // One length-3 boat across the top-left corner.
      marks[0] = kMarkShip;
      marks[1] = kMarkShip;
      marks[2] = kMarkShip;

      expect(markedBoatLengths(marks, rows: rows, cols: cols), [3]);
      expect(
        crossedOffFleet(marks, BoatsSize.small.fleet, rows: rows, cols: cols),
        [true, false, false],
        reason: 'one 3-boat crosses off one of the two length-3 chips',
      );

      // A second marked 3-boat crosses off the second chip, and only it.
      marks[rows] = kMarkShip;
      marks[rows + 1] = kMarkShip;
      marks[rows + 2] = kMarkShip;
      expect(
        crossedOffFleet(marks, BoatsSize.small.fleet, rows: rows, cols: cols),
        [true, true, false],
      );
    });

    test('a marked run of the wrong length crosses nothing off', () {
      final rows = BoatsSize.small.rows;
      final cols = BoatsSize.small.cols;
      final marks = List<int>.filled(rows * cols, kMarkEmpty);
      // Four cells is not a boat in a 3-3-2 fleet.
      for (var col = 0; col < 4; col++) {
        marks[col] = kMarkShip;
      }
      expect(markedBoatLengths(marks, rows: rows, cols: cols), [4]);
      expect(
        crossedOffFleet(marks, BoatsSize.small.fleet, rows: rows, cols: cols),
        [false, false, false],
      );
    });

    test('the hint is applied, not merely outlined', () {
      // The bug this pins: the notifier stored the proved value and the board
      // read only the cell, so the hint outlined whatever the player had put
      // there. A player with a boat marked on open water was told nothing.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(boatsNotifierProvider.notifier);
      final start = container.read(boatsNotifierProvider);
      final answer = start.puzzle.solution;

      // Fill the board from the answer, then put one wrong boat on water.
      final water = [
        for (var cell = 0; cell < answer.length; cell++)
          if (answer[cell] == kBoatWater) cell,
      ].first;
      notifier.state = start.copyWith(
        marks: [for (final value in answer) markOfSolution(value)],
      );
      final wrong = [...notifier.state.marks];
      wrong[water] = kMarkShip;
      notifier.state = notifier.state.copyWith(marks: wrong);

      notifier.hint();

      final after = container.read(boatsNotifierProvider);
      expect(after.hintCell, water,
          reason: 'the only disagreeing cell is the wrong boat');
      expect(after.marks[water], kMarkWater,
          reason:
              'the hint must write the proved mark, not outline the old one');
      expect(after.isSolved, isTrue,
          reason: 'the board is complete once fixed');
    });

    test('the hint writes into an untouched board and moves on', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(boatsNotifierProvider.notifier);

      notifier.hint();
      final first = container.read(boatsNotifierProvider);
      final cell = first.hintCell;
      expect(cell, isNotNull);
      // The written mark is the answer's mark for that cell.
      expect(
        first.marks[cell!],
        markOfSolution(first.puzzle.solution[cell]),
      );

      notifier.hint();
      final second = container.read(boatsNotifierProvider);
      expect(second.hintCell, isNot(cell),
          reason: 'a second hint is about a different cell, not the same one');
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
