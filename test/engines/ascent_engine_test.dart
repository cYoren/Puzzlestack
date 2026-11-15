import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/ascent/ascent_engine.dart';
import 'package:puzzle/ui/features/games/ascent/ascent_model.dart';
import 'package:puzzle/ui/features/games/ascent/ascent_provider.dart';

const engine = AscentEngine();

void main() {
  group('AscentEngine', () {
    test('a dealt board is a legal path that agrees with its clues', () {
      final rng = Random(1);
      for (final size in AscentSize.values) {
        final puzzle = engine.generate(size, random: rng);
        expect(puzzle.isLegal(puzzle.solution), isTrue,
            reason: '${size.name} path breaks the rules');
        expect(puzzle.matchesGivens(puzzle.solution), isTrue,
            reason: '${size.name} clue disagrees with the path');
        expect(puzzle.isSolved(puzzle.solution), isTrue, reason: size.name);
      }
    });

    test('every number 1..cells appears exactly once', () {
      final puzzle = engine.generate(AscentSize.medium, random: Random(2));
      final numbers = [...puzzle.solution]..sort();
      expect(numbers, [for (var i = 1; i <= puzzle.maxNumber; i++) i]);
      // Consecutive numbers touch, which is the whole rule.
      for (var number = 1; number < puzzle.maxNumber; number++) {
        final a = puzzle.cellOf(puzzle.solution, number)!;
        final b = puzzle.cellOf(puzzle.solution, number + 1)!;
        expect(puzzle.neighbours(a, b), isTrue, reason: 'step $number');
      }
    });

    test('the clues pin down exactly one path, at every size', () {
      for (final size in AscentSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 5));
        final count = engine.count(puzzle, limit: 2);
        expect(count.truncated, isFalse, reason: size.name);
        expect(count.solutions, 1, reason: '${size.name} is ambiguous');
      }
    });

    test('the clues can be finished without a guess, at every size', () {
      for (final size in AscentSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 9));
        expect(engine.levelOf(puzzle), isNotNull,
            reason: '${size.name} needs a guess');
      }
    });

    test('with the clues gone, a board has many paths', () {
      final puzzle = engine.generate(AscentSize.small, random: Random(21));
      final bare = AscentPuzzle(
        size: puzzle.size,
        givens: List<int>.filled(puzzle.cellCount, kAscentNoClue),
        solution: puzzle.solution,
      );
      expect(engine.count(bare).solutions, greaterThan(1));
    });

    test('the hint writes a number the path agrees with, and advances', () {
      final puzzle = engine.generate(AscentSize.medium, random: Random(31));
      final values = List<int>.filled(puzzle.cellCount, kAscentBlank);
      final first = engine.hint(puzzle, values);
      expect(first, isNotNull);
      expect(first!.number, puzzle.solution[first.cell]);
      values[first.cell] = first.number;
      final second = engine.hint(puzzle, values);
      expect(second, isNotNull);
      expect(second!.cell, isNot(first.cell));
      expect(second.number, puzzle.solution[second.cell]);
    });

    test('two consecutive numbers out of reach are a conflict', () {
      final puzzle = engine.generate(AscentSize.small, random: Random(41));
      final values = List<int>.from(puzzle.solution);
      expect(puzzle.conflicts(values), isEmpty,
          reason: 'the answer cannot conflict with itself');

      // Put a second 2 in a cell that does not touch the 1: a duplicate, and a
      // step with no adjacency behind it.
      final one = puzzle.cellOf(values, 1)!;
      int? far;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (cell == one || cell == puzzle.cellOf(values, 2)) continue;
        if (puzzle.neighbours(one, cell)) continue;
        far = cell;
        break;
      }
      expect(far, isNotNull);
      values[far!] = 2;
      expect(puzzle.conflicts(values), isNotEmpty);
      expect(puzzle.isSolved(values), isFalse);
    });

    test('the solver agrees with the generator at cell level', () {
      final puzzle = engine.generate(AscentSize.medium, random: Random(51));
      final found = AscentSearch(
        puzzle: puzzle,
        domains: AscentModel.fresh(puzzle).domains,
        limit: 1,
        budget: 200000,
      ).run();
      expect(found.solutions, 1);
      expect(found.forced, puzzle.solution);
    });
    test('the clues are on the board, not hidden behind it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(ascentNotifierProvider);
      final shown = state.values.where((v) => v != kAscentBlank).length;
      expect(shown, state.puzzle.clueCount());
      expect(shown, greaterThan(0));
    });

    test('a board can be finished by playing it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(ascentNotifierProvider.notifier);
      final puzzle = container.read(ascentNotifierProvider).puzzle;
      // Numbers go on in order, so walk the answer in order and tap the cell
      // that holds each one the player has to write.
      for (var number = 1; number <= puzzle.maxNumber; number++) {
        final cell = puzzle.cellOf(puzzle.solution, number)!;
        if (puzzle.given(cell) != kAscentNoClue) continue;
        notifier.tap(cell);
      }
      expect(container.read(ascentNotifierProvider).isSolved, isTrue);
    });
  });
}
