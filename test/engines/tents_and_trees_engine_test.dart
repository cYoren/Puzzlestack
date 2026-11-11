import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/deduction.dart';
import 'package:puzzle/ui/features/games/tents_and_trees/tents_and_trees_engine.dart';
import 'package:puzzle/ui/features/games/tents_and_trees/tents_model.dart';

void main() {
  const engine = TentsEngine();

  group('generator', () {
    for (final difficulty in TentsDifficulty.values) {
      test('${difficulty.name}: 20 boards, one answer, rules finish it', () {
        final rng = Random(difficulty.index + 91);
        for (var i = 0; i < 20; i++) {
          final puzzle = engine.generate(difficulty, random: rng);
          final where = '${difficulty.name} board $i';

          expect(puzzle.rows, difficulty.rows);
          expect(puzzle.cols, difficulty.cols);
          expect(puzzle.trees.length, puzzle.cellCount ~/ 5,
              reason: '$where: wrong number of trees');

          // The stored answer obeys every rule of the puzzle.
          expect(engine.isSolved(puzzle, puzzle.solution), isTrue,
              reason: '$where: the answer does not fit its own clues');

          // Every tent belongs to exactly one tree.
          for (final tent in puzzle.solution) {
            final trees = puzzle.trees.where((tree) {
              final dr = (tree ~/ puzzle.cols) - (tent ~/ puzzle.cols);
              final dc = (tree % puzzle.cols) - (tent % puzzle.cols);
              return dr.abs() + dc.abs() == 1;
            }).length;
            expect(trees, 1, reason: '$where: tent $tent touches $trees trees');
          }

          // Exactly one answer, reached by the rules at the tier's level.
          final rating = rate(TentsModel.fresh(puzzle), tentsRules);
          expect(rating.verdict, PuzzleVerdict.solved, reason: '$where: $rating');
          expect(rating.solutions, 1, reason: '$where: $rating');
          expect(rating.level, difficulty.level,
              reason: '$where: the board does not need the tier\'s depth');
        }
      });
    }
  });

  group('rules', () {
    test('never contradict a board that has an answer', () {
      final rng = Random(23);
      for (final difficulty in TentsDifficulty.values) {
        for (var i = 0; i < 25; i++) {
          final puzzle = engine.generateUngated(difficulty, rng);
          final model = TentsModel.fresh(puzzle);
          final outcome = deduce(model, tentsRules);
          expect(outcome.consistent, isTrue,
              reason: '${difficulty.name} $i: rules called a real board impossible');
          for (var cell = 0; cell < puzzle.cellCount; cell++) {
            if (puzzle.isTree(cell)) continue;
            final truth = puzzle.solution.contains(cell) ? kTent : kGrass;
            expect(model.masks[cell] & truth, isNot(0),
                reason: '${difficulty.name} $i: rules ruled out the answer at '
                    'cell $cell');
          }
        }
      }
    });

    test('a cell with no tree beside it can never hold a tent', () {
      final puzzle = engine.generateUngated(TentsDifficulty.easy, Random(3));
      final model = TentsModel.fresh(puzzle);
      TentsReach().apply(model);
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (puzzle.isTree(cell)) continue;
        final trees = model.orthogonal(cell).where(puzzle.isTree).length;
        if (trees == 1) continue;
        expect(model.valueAt(cell), kGrass,
            reason: 'cell $cell touches $trees trees but could still be a tent');
      }
    });
  });

  group('hint', () {
    test('names a cell the rules prove, and the player has wrong', () {
      final rng = Random(29);
      for (var i = 0; i < 10; i++) {
        final puzzle = engine.generate(TentsDifficulty.easy, random: rng);
        // Take one tent away; the rules must be able to put it back.
        final missing = [...puzzle.solution]..removeAt(i % puzzle.treeCount);
        final hint = engine.hint(puzzle, missing);
        expect(hint, isNotNull, reason: 'board $i: no hint for a wrong board');
        expect(hint!.value, kTent,
            reason: 'board $i: the missing tent is not the hint');
        expect(puzzle.solution.contains(hint.cell), isTrue,
            reason: 'board $i: hint names a cell that is not a tent');
        expect(missing.contains(hint.cell), isFalse,
            reason: 'board $i: hint names a cell the player already has');
      }
    });

    test('says nothing when the board is right', () {
      final puzzle = engine.generate(TentsDifficulty.easy, random: Random(31));
      expect(engine.hint(puzzle, puzzle.solution), isNull);
    });
  });
}
