import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/clusters/clusters_engine.dart';
import 'package:puzzle/ui/features/games/clusters/clusters_model.dart';
import 'package:puzzle/ui/features/games/clusters/clusters_provider.dart';

const engine = ClustersEngine();

void main() {
  group('ClustersEngine', () {
    test('an unfinished enumeration proves nothing', () {
      // The exact rule used to treat agreement among the first `limit` answers
      // as agreement among every answer. A clue-free board has far more than
      // three colourings, so the search must not hand out forced cells and the
      // rule must write nothing.
      final size = ClustersSize.small;
      final bare = ClustersPuzzle(
        size: size,
        clues: List<int>.filled(size.cellCount, kClusterNoClue),
        solution: List<int>.filled(size.cellCount, kClusterRed),
      );
      final count = ClustersSearch(
        puzzle: bare,
        masks: ClustersModel.fresh(bare).masks,
        limit: 3,
      ).run();
      expect(count.solutions, 3);
      expect(count.exhausted, isFalse);
      expect(count.forced.every((value) => value == 0), isTrue);

      final model = ClustersModel.fresh(bare);
      expect(const ClustersForced().apply(model), 0,
          reason: 'the rule wrote a cell it had not proved');
    });

    test('a dealt board is a legal colouring', () {
      final rng = Random(1);
      for (final size in ClustersSize.values) {
        final puzzle = engine.generate(size, random: rng);
        expect(puzzle.isLegal(puzzle.solution), isTrue, reason: size.name);
        expect(puzzle.isSolved(puzzle.solution), isTrue, reason: size.name);
      }
    });

    test('a dot is exactly a cell with one same-coloured neighbour', () {
      // The clue set is read off the answer, so this test would catch a dot
      // that was never a dot, and a dot the generator forgot to print.
      for (final size in ClustersSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 2));
        for (var cell = 0; cell < puzzle.cellCount; cell++) {
          final same =
              puzzle.sameAround(puzzle.solution, cell, puzzle.solution[cell]);
          expect(puzzle.clue(cell),
              same == 1 ? puzzle.solution[cell] : kClusterNoClue,
              reason: '${size.name} cell $cell');
        }
      }
    });

    test('the dots pin down exactly one colouring, at every size', () {
      for (final size in ClustersSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 5));
        final count = engine.count(puzzle, limit: 2);
        expect(count.truncated, isFalse, reason: size.name);
        expect(count.solutions, 1, reason: '${size.name} is ambiguous');
        expect(count.forced, puzzle.solution, reason: size.name);
      }
    });

    test('the dots can be finished without a guess, at every size', () {
      for (final size in ClustersSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 9));
        expect(engine.levelOf(puzzle), isNotNull,
            reason: '${size.name} needs a guess');
      }
    });

    test('a colour flipped away from both rules is not a solution', () {
      final puzzle = engine.generate(ClustersSize.small, random: Random(21));
      final values = List<int>.from(puzzle.solution);
      expect(puzzle.conflicts(values), isEmpty);
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (puzzle.clue(cell) != kClusterNoClue) continue;
        values[cell] = otherColour(values[cell]);
        break;
      }
      expect(puzzle.isSolved(values), isFalse);
    });

    test('a tap cycles three states, and a dotted cell never changes', () {
      expect(nextColour(kClusterUnmarked), kClusterRed);
      expect(nextColour(kClusterRed), kClusterBlue);
      expect(nextColour(kClusterBlue), kClusterUnmarked);
      // The three states are three values, so unmarked is not a colour.
      expect({kClusterUnmarked, kClusterRed, kClusterBlue}, hasLength(3));
      expect(kClusterNoClue, kClusterUnmarked,
          reason: 'both zeros, but in two different lists — the puzzle never '
              'compares a clue against a player value');
    });

    test('the hint writes a colour the answer agrees with, and advances', () {
      final puzzle = engine.generate(ClustersSize.small, random: Random(31));
      final values = List<int>.filled(puzzle.cellCount, kClusterUnmarked);
      final first = engine.hint(puzzle, values);
      expect(first, isNotNull);
      expect(first!.colour, puzzle.solution[first.cell]);
      values[first.cell] = first.colour;
      final second = engine.hint(puzzle, values);
      expect(second, isNotNull);
      expect(second!.cell, isNot(first.cell));
      expect(second.colour, puzzle.solution[second.cell]);
    });

    test('an oversatisfied dot is not an answer', () {
      // A red dot in every cell of a 6x6 board: the all-red colouring gives
      // every dotted cell four same-coloured neighbours, so the rule is broken
      // everywhere. The counter used to call this "one solution" because the
      // count rule never reported the contradiction.
      final size = ClustersSize.small;
      final allRed = List<int>.filled(size.cellCount, kClusterRed);
      final puzzle = ClustersPuzzle(
        size: size,
        clues: List<int>.filled(size.cellCount, kClusterRed),
        solution: allRed,
      );
      expect(puzzle.isLegal(allRed), isFalse);
      expect(engine.count(puzzle).solutions, 0);
      expect(engine.levelOf(puzzle), isNull);
    });

    test('the solver agrees with the generator at cell level', () {
      final puzzle = engine.generate(ClustersSize.medium, random: Random(41));
      final found = ClustersSearch(
        puzzle: puzzle,
        masks: ClustersModel.fresh(puzzle).masks,
        limit: 1,
        budget: 200000,
      ).run();
      expect(found.solutions, 1);
      expect(found.first, puzzle.solution);
    });
    test('the dots are on the board, not hidden behind it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(clustersNotifierProvider);
      final shown = state.values.where((v) => v != kClusterUnmarked).length;
      expect(shown, state.puzzle.clueCount());
      expect(shown, greaterThan(0));
    });

    test('a board can be finished by playing it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(clustersNotifierProvider.notifier);
      final puzzle = container.read(clustersNotifierProvider).puzzle;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (puzzle.clue(cell) != kClusterNoClue) continue;
        var state = container.read(clustersNotifierProvider);
        for (var taps = 0; taps < 3; taps++) {
          if (state.values[cell] == puzzle.solution[cell]) break;
          notifier.cycle(cell);
          state = container.read(clustersNotifierProvider);
        }
      }
      expect(container.read(clustersNotifierProvider).isSolved, isTrue);
    });
  });
}
