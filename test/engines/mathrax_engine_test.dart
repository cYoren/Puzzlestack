import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/mathrax/mathrax_engine.dart';
import 'package:puzzle/ui/features/games/mathrax/mathrax_model.dart';
import 'package:puzzle/ui/features/games/mathrax/mathrax_provider.dart';
import 'package:puzzle/ui/features/games/mathrax/mathrax_puzzle.dart';

const engine = MathraxEngine();

void main() {
  group('MathraxEngine', () {
    test('a dealt board is a Latin square whose clues are all true', () {
      final rng = Random(1);
      for (final size in MathraxSize.values) {
        final puzzle = engine.generate(size, random: rng);
        expect(puzzle.isSolution(puzzle.solution), isTrue, reason: size.name);
        expect(puzzle.cluesHold(puzzle.solution), isTrue, reason: size.name);
        for (var row = 0; row < size.n; row++) {
          final digits = {
            for (var col = 0; col < size.n; col++)
              puzzle.solution[puzzle.cell(row, col)]
          };
          expect(digits, {for (var d = 1; d <= size.n; d++) d},
              reason: '${size.name} row $row');
        }
      }
    });

    test('the clues pin down exactly one answer, at every size', () {
      for (final size in MathraxSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 5));
        expect(engine.count(puzzle), 1, reason: '${size.name} is ambiguous');
      }
    });

    test('the clues can be finished without a guess, at every size', () {
      for (final size in MathraxSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 9));
        expect(engine.levelOf(puzzle), isNotNull,
            reason: '${size.name} needs a guess');
      }
    });

    test('a board with no clues at all is ambiguous', () {
      // The other side of the generator's claim: the clues are what make the
      // answer unique. Without them, every Latin square of the order fits.
      final puzzle = engine.generate(MathraxSize.small, random: Random(31));
      final bare = MathraxPuzzle(
        size: puzzle.size,
        clues: List<MathraxClue?>.filled(puzzle.clueCount, null),
        solution: puzzle.solution,
      );
      expect(engine.count(bare), greaterThan(1));
      expect(bare.isSolution(puzzle.solution), isTrue);
    });

    test('the corners agree with the answer, both diagonals each', () {
      final puzzle = engine.generate(MathraxSize.large, random: Random(12));
      for (var row = 0; row < puzzle.n - 1; row++) {
        for (var col = 0; col < puzzle.n - 1; col++) {
          final clue = puzzle.clueAt(row, col);
          if (clue == null) continue;
          final cells = puzzle.corner(row, col);
          final values = [for (final cell in cells) puzzle.solution[cell]];
          expect(
            MathraxPuzzle.pairHolds(values[0], values[3], clue),
            isTrue,
            reason: 'clue at $row,$col is false on the main diagonal',
          );
          expect(
            MathraxPuzzle.pairHolds(values[1], values[2], clue),
            isTrue,
            reason: 'clue at $row,$col is false on the other diagonal',
          );
        }
      }
    });

    test('the hint writes a digit the answer agrees with, and advances', () {
      final puzzle = engine.generate(MathraxSize.medium, random: Random(4));
      final values = List<int>.filled(puzzle.cellCount, kMathraxBlank);
      var taken = 0;
      while (true) {
        final found = engine.hint(puzzle, values);
        if (found == null) break;
        expect(values[found.cell], kMathraxBlank,
            reason: 'the hint picked a cell that is already written');
        expect(found.digit, puzzle.solution[found.cell],
            reason: 'the hint contradicts the answer');
        values[found.cell] = found.digit;
        taken++;
        if (taken > puzzle.cellCount) fail('the hint never runs out');
      }
      expect(taken, greaterThan(0));
      expect(puzzle.isSolution(values), isTrue);
    });

    test('a wrong digit is a conflict, an unfinished board is not solved', () {
      final puzzle = engine.generate(MathraxSize.small, random: Random(8));
      final values = List<int>.filled(puzzle.cellCount, kMathraxBlank);
      values[0] = puzzle.solution[0];
      values[1] = puzzle.solution[0];
      expect(puzzle.conflicts(values), contains(0));
      expect(puzzle.conflicts(values), contains(1));
      expect(engine.isSolved(puzzle, values), isFalse);
    });

    test('an unfinished enumeration proves nothing', () {
      // The exact rule treats agreement among the first `limit` answers as
      // agreement among every answer unless the search knows it finished.
      final size = MathraxSize.medium;
      final bare = MathraxPuzzle(
        size: size,
        clues: List<MathraxClue?>.filled(size.clueCount, null),
        solution: engine.generate(size, random: Random(2)).solution,
      );
      final count = MathraxSearch(
        puzzle: bare,
        masks: MathraxModel.fresh(bare).masks,
        limit: 3,
      ).run();
      expect(count.solutions, 3);
      expect(count.exhausted, isFalse);
      expect(count.forced.every((digit) => digit == 0), isTrue);
      final model = MathraxModel.fresh(bare);
      expect(const MathraxForced().apply(model), 0,
          reason: 'the rule wrote a cell it had not proved');
    });

    test('the board starts blank, with the clues in the puzzle', () {
      // Mathrax prints corners, not cells: every value starts blank and the
      // clue set is what the player reads. A game that seeded cells here would
      // be printing a different puzzle.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(mathraxProvider);
      expect(state.values.every((value) => value == kMathraxBlank), isTrue);
      expect(state.puzzle.clues.where((clue) => clue != null), isNotEmpty);
    });

    test('a board can be finished by playing it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mathraxProvider.notifier);
      final puzzle = container.read(mathraxProvider).puzzle;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        // The only input is the tap cycle, so write the answer the way a
        // player does: cycle until the digit is there.
        while (container.read(mathraxProvider).values[cell] !=
            puzzle.solution[cell]) {
          notifier.cycle(cell);
        }
      }
      expect(container.read(mathraxProvider).isSolved, isTrue);
      expect(container.read(mathraxProvider).values, puzzle.solution);
    });
  });
}
