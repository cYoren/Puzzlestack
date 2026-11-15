import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/seismic/seismic_engine.dart';
import 'package:puzzle/ui/features/games/seismic/seismic_model.dart';

const engine = SeismicEngine();

void main() {
  group('SeismicEngine', () {
    test('a dealt board is a legal answer with clues that agree with it', () {
      final rng = Random(1);
      for (final size in SeismicSize.values) {
        final puzzle = engine.generate(size, random: rng);
        expect(puzzle.isLegal(puzzle.solution), isTrue,
            reason: '${size.name} answer breaks the rules');
        expect(puzzle.matchesGivens(puzzle.solution), isTrue,
            reason: '${size.name} clue disagrees with the answer');
        expect(puzzle.isSolved(puzzle.solution), isTrue, reason: size.name);
      }
    });

    test('every region is the right shape to hold 1..its size', () {
      for (final size in SeismicSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 2));
        expect(puzzle.regionSizes.length, size.n);
        expect(puzzle.regionSizes.fold(0, (a, b) => a + b), size.cellCount);
        expect(puzzle.maxDigit, size.n);
        for (var region = 0; region < puzzle.regionSizes.length; region++) {
          final cells = puzzle.cellsOfRegion(region);
          expect(cells.length, puzzle.regionSizes[region], reason: 'region');
          // The digits in a region are exactly 1..its size.
          final digits = {for (final cell in cells) puzzle.solution[cell]};
          expect(digits.length, cells.length, reason: 'repeat in a region');
          expect(digits, {for (var d = 1; d <= cells.length; d++) d});
        }
      }
    });

    test('the clues pin down exactly one answer, at every size', () {
      for (final size in SeismicSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 5));
        final count = engine.count(puzzle, limit: 2);
        expect(count.truncated, isFalse, reason: size.name);
        expect(count.solutions, 1, reason: '${size.name} is ambiguous');
      }
    });

    test('the clues can be finished without a guess, at every size', () {
      for (final size in SeismicSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 9));
        expect(engine.levelOf(puzzle), isNotNull,
            reason: '${size.name} needs a guess');
      }
    });

    test('a board with the clues removed is not unique any more', () {
      // This is the rule the generator relies on: the printed numbers are what
      // makes the answer the only one. Without them the shapes alone allow a
      // ripple of alternatives.
      final puzzle = engine.generate(SeismicSize.small, random: Random(21));
      final bare = SeismicPuzzle(
        size: puzzle.size,
        regions: puzzle.regions,
        regionSizes: puzzle.regionSizes,
        givens: List<int>.filled(puzzle.cellCount, kSeismicNoClue),
        solution: puzzle.solution,
      );
      expect(engine.count(bare).solutions, greaterThan(1));
    });

    test('the hint writes a digit the answer agrees with, and advances', () {
      final puzzle = engine.generate(SeismicSize.medium, random: Random(31));
      final values = List<int>.filled(puzzle.cellCount, kSeismicBlank);
      final first = engine.hint(puzzle, values);
      expect(first, isNotNull);
      expect(first!.digit, puzzle.solution[first.cell]);
      values[first.cell] = first.digit;
      final second = engine.hint(puzzle, values);
      expect(second, isNotNull);
      expect(second!.cell, isNot(first.cell));
      expect(second.digit, puzzle.solution[second.cell]);
    });

    test('a hint is applied, never merely outlined', () {
      // The Boats lesson: a hint that stores a value and paints a ring teaches
      // nothing. The engine returns a digit for a cell the player left blank.
      final puzzle = engine.generate(SeismicSize.small, random: Random(41));
      final values = List<int>.filled(puzzle.cellCount, kSeismicBlank);
      final hint = engine.hint(puzzle, values);
      expect(hint, isNotNull);
      expect(hint!.digit, inInclusiveRange(1, puzzle.maxDigit));
    });

    test('two equal digits too close are a conflict, on the board too', () {
      final puzzle = engine.generate(SeismicSize.small, random: Random(51));
      final values = List<int>.from(puzzle.solution);
      expect(puzzle.conflicts(values), isEmpty,
          reason: 'the answer cannot conflict with itself');

      // Copy a digit into a cell inside its own ripple range: exactly the
      // mistake the player makes, and the board has to show it.
      var planted = false;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        final digit = values[cell];
        final range = puzzle.inRange(cell, digit);
        if (range.isEmpty) continue;
        values[range.first] = digit;
        planted = true;
        break;
      }
      expect(planted, isTrue);
      expect(puzzle.conflicts(values), isNotEmpty);
      expect(puzzle.isSolved(values), isFalse);
    });

    test('the solver agrees with the generator at cell level', () {
      // The search's own answer, not the generator's field, must reproduce the
      // board: that is what makes it a prover.
      final puzzle = engine.generate(SeismicSize.medium, random: Random(61));
      final model = SeismicModel.fresh(puzzle);
      final found = SeismicSearch(
        puzzle: puzzle,
        masks: model.masks,
        limit: 1,
        budget: 200000,
      ).run();
      expect(found.solutions, 1);
      expect(found.forced, puzzle.solution);
    });
  });
}
