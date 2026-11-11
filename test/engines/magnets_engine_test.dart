import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/deduction.dart';
import 'package:puzzle/ui/features/games/magnets/magnets_engine.dart';
import 'package:puzzle/ui/features/games/magnets/magnets_model.dart';

void main() {
  const engine = MagnetsEngine();

  group('generator', () {
    for (final difficulty in MagnetsDifficulty.values) {
      test('${difficulty.name}: 20 boards, one answer, rules finish it', () {
        final rng = Random(difficulty.index + 71);
        for (var i = 0; i < 20; i++) {
          final puzzle = engine.generate(difficulty, random: rng);
          final where = '${difficulty.name} board $i';

          // The tiling covers every cell exactly once, with adjacent halves.
          final seen = <int>{};
          for (var d = 0; d < puzzle.dominoCount; d++) {
            final a = puzzle.dominoA[d];
            final b = puzzle.dominoB[d];
            expect(seen.add(a), isTrue, reason: '$where: cell $a twice');
            expect(seen.add(b), isTrue, reason: '$where: cell $b twice');
            expect(engine.isAdjacent(a, b, puzzle.cols), isTrue,
                reason: '$where: domino $d is not adjacent');
            expect(puzzle.dominoOf[a], d);
            expect(puzzle.dominoOf[b], d);
          }
          expect(seen.length, puzzle.cellCount, reason: '$where: not covered');

          // The stored answer obeys the clues and the adjacency rule.
          expect(engine.isSolved(puzzle, puzzle.solution), isTrue,
              reason: '$where: the answer does not fit its own clues');

          // Exactly one answer, and the rules reach it at the tier's level.
          final rating = rate(MagnetsModel.fresh(puzzle), magnetsRules);
          expect(rating.verdict, PuzzleVerdict.solved, reason: '$where: $rating');
          expect(rating.solutions, 1, reason: '$where: $rating');
          expect(rating.level, greaterThanOrEqualTo(difficulty.minLevel),
              reason: '$where: too easy for the tier');

          // The rule-free counter is a second opinion on the count.
          expect(engine.countSolutions(puzzle, limit: 2), 1,
              reason: '$where: the rule-free counter disagrees');
        }
      });
    }
  });

  group('rules', () {
    test('never contradict a board that has an answer', () {
      final rng = Random(9);
      for (final difficulty in MagnetsDifficulty.values) {
        for (var i = 0; i < 25; i++) {
          final puzzle = engine.generateUngated(difficulty, rng);
          final model = MagnetsModel.fresh(puzzle);
          final outcome = deduce(model, magnetsRules);
          expect(outcome.consistent, isTrue,
              reason: '${difficulty.name} $i: rules called a real board impossible');
          for (var cell = 0; cell < puzzle.cellCount; cell++) {
            final truth = engine.poleAt(puzzle, puzzle.solution, cell);
            expect(model.masks[cell] & truth, isNot(0),
                reason: '${difficulty.name} $i: rules ruled out the answer at '
                    'cell $cell');
          }
        }
      }
    });

    test('a domino is blank or a magnet, never half of each', () {
      final puzzle = engine.generateUngated(MagnetsDifficulty.easy, Random(4));
      final model = MagnetsModel.fresh(puzzle);
      final a = puzzle.dominoA[0];
      final b = puzzle.dominoB[0];

      expect(model.set(a, kPositive), 1);
      expect(model.masks[b], kNegative, reason: 'partner of + must be -');

      final second = MagnetsModel.fresh(puzzle);
      expect(second.set(a, kNeutral), 1);
      expect(second.masks[b], kNeutral, reason: 'partner of blank must be blank');
    });

    test('a line that is full of one value cannot take another', () {
      final puzzle = engine.generateUngated(MagnetsDifficulty.easy, Random(6));
      final model = MagnetsModel.fresh(puzzle);
      // Row 0 needs rowPlus[0] pluses; if that is 0, no cell in it can be +.
      if (puzzle.rowPlus[0] == 0) {
        expect(MagnetsCounts().apply(model), greaterThan(0));
        for (var c = 0; c < puzzle.cols; c++) {
          expect(model.masks[c] & kPositive, 0,
              reason: 'row 0 needs no + but cell $c could still be one');
        }
      }
    });
  });

  group('hint', () {
    test('names a cell the rules prove, and the player has wrong', () {
      final rng = Random(13);
      for (var i = 0; i < 10; i++) {
        final puzzle = engine.generate(MagnetsDifficulty.easy, random: rng);
        final wrong = [...puzzle.solution];
        // Turn one domino into a different state.
        final d = i % puzzle.dominoCount;
        wrong[d] = (wrong[d] + 1) % 3;

        final hint = engine.hint(puzzle, wrong);
        expect(hint, isNotNull, reason: 'board $i: no hint for a wrong board');
        expect(engine.poleAt(puzzle, wrong, hint!.cell), isNot(hint.value),
            reason: 'board $i: hint points at a cell that is already right');
        expect(hint.value, engine.poleAt(puzzle, puzzle.solution, hint.cell),
            reason: 'board $i: hint disagrees with the answer');
      }
    });

    test('says nothing when the board is right', () {
      final puzzle =
          engine.generate(MagnetsDifficulty.easy, random: Random(17));
      expect(engine.hint(puzzle, puzzle.solution), isNull);
    });
  });
}
