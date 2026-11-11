import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/deduction.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_engine.dart';

void main() {
  const engine = SignpostEngine();

  group('generator', () {
    // The bar is two hundred boards a tier. The hard tier is the exception it
    // has to be: a board that needs the lookahead costs a few hundred
    // milliseconds to build, so twenty-five of them is already a test run's
    // worth of waiting, and the twenty-five are counted exactly like the rest.
    const counts = {'easy': 200, 'medium': 200, 'hard': 25};

    for (final difficulty in SignpostDifficulty.values) {
      final boards = counts[difficulty.name]!;
      test('${difficulty.name}: $boards boards, one answer each', () {
        final rng = Random(difficulty.index + 91);
        for (var i = 0; i < boards; i++) {
          // A generous budget: the tier claims the exact rule level, so the
          // test refuses the easier fallback the app is allowed to take.
          final puzzle = engine.generate(
            difficulty,
            random: rng,
            budget: const Duration(seconds: 20),
          );
          final where = '${difficulty.name} board $i';

          expect(puzzle.rows, difficulty.rows, reason: where);
          expect(puzzle.cols, difficulty.cols, reason: where);

          // The harness counts the answers and grades the reasoning. One
          // answer, reached at the tier's own rule level.
          final rating = engine.rateBoard(puzzle);
          expect(rating.verdict, PuzzleVerdict.solved,
              reason: '$where: $rating');
          expect(rating.solutions, 1, reason: '$where: $rating');
          expect(rating.level, difficulty.level, reason: '$where: $rating');

          // The stored answer is a win, checked against the arrows rather than
          // against itself.
          expect(engine.isSolved(puzzle, engine.answerLinks(puzzle)), isTrue,
              reason: '$where: the stored answer does not win');

          // 1 and N are always given, and the corners hold them unless the
          // tier lets the ends float.
          final total = puzzle.cellCount;
          expect(puzzle.solution[puzzle.clues.indexOf(1)], 1, reason: where);
          expect(puzzle.solution[puzzle.clues.indexOf(total)], total,
              reason: where);
          if (!difficulty.freeEnds) {
            expect(puzzle.clues[0], 1,
                reason: '$where: 1 is not in the corner');
            expect(puzzle.clues[total - 1], total,
                reason: '$where: N is not in the corner');
          }

          // Fewer given numbers than the board has cells, or there would be
          // nothing to work out.
          expect(puzzle.clueCount, lessThan(total), reason: where);
        }
      });
    }
  });

  group('rules', () {
    test('every forced link is a link the answer has', () {
      final rng = Random(5);
      for (final difficulty in SignpostDifficulty.values) {
        for (var i = 0; i < 10; i++) {
          final puzzle = engine.generate(difficulty, random: rng);
          final truth = engine.answerLinks(puzzle);
          final model = SignpostModel.blank(puzzle);
          final outcome = deduce(model, signpostRules);

          expect(outcome.consistent, isTrue);
          expect(outcome.complete, isTrue,
              reason: 'the generator ships boards the rules cannot finish');
          for (var cell = 0; cell < puzzle.cellCount; cell++) {
            expect(model.links[cell], truth[cell],
                reason: '${difficulty.name} board $i: cell $cell');
          }
        }
      }
    });

    test('a cell cannot point at a cell its arrow misses', () {
      final puzzle =
          engine.generate(SignpostDifficulty.easy, random: Random(2));
      final position = SignpostPosition.of(
        puzzle,
        List<int>.filled(puzzle.cellCount, -1),
      );
      var refused = 0;
      for (var from = 0; from < puzzle.cellCount; from++) {
        for (var to = 0; to < puzzle.cellCount; to++) {
          if (to == from) continue;
          // Off the ray entirely: the step is neither straight nor diagonal.
          final stepY = puzzle.rowOf(to) - puzzle.rowOf(from);
          final stepX = puzzle.colOf(to) - puzzle.colOf(from);
          if (stepX == 0 || stepY == 0 || stepX.abs() == stepY.abs()) continue;
          expect(engine.legal(position, puzzle, from, to), isFalse,
              reason: 'cell $from accepted $to, which is off its ray');
          refused++;
        }
      }
      expect(refused, greaterThan(0));
    });

    test('a cell has one predecessor', () {
      final puzzle =
          engine.generate(SignpostDifficulty.easy, random: Random(3));
      final blank = List<int>.filled(puzzle.cellCount, -1);
      final position = SignpostPosition.of(puzzle, blank);

      ({int from, int to})? link;
      for (var from = 0; from < puzzle.cellCount && link == null; from++) {
        for (var to = 0; to < puzzle.cellCount; to++) {
          if (!engine.legal(position, puzzle, from, to)) continue;
          link = (from: from, to: to);
          break;
        }
      }
      expect(link, isNotNull, reason: 'no legal link on a fresh board');

      final links = [...blank];
      links[link!.from] = link.to;
      final after = SignpostPosition.of(puzzle, links);
      for (var from = 0; from < puzzle.cellCount; from++) {
        if (from == link.from) continue;
        expect(engine.legal(after, puzzle, from, link.to), isFalse,
            reason: 'cell $from would give ${link.to} a second predecessor');
      }
    });

    test('a link that closes a loop is refused', () {
      // A 2x2 ring of arrows: 0 east, 1 south, 3 north-west, 2 north.
      final puzzle = SignpostPuzzle(
        rows: 2,
        cols: 2,
        dirs: const [2, 4, 0, 7],
        clues: const [0, 0, 0, 0],
        solution: const [1, 2, 4, 3],
      );
      // 0 -> 1 -> 3: 3 is the tail and its arrow runs back through 0, which is
      // the head of its own chain.
      final position = SignpostPosition.of(puzzle, [1, 3, -1, -1]);
      expect(position.impossible, isFalse);
      expect(position.chainOf, [0, 0, 1, 0]);
      expect(engine.legal(position, puzzle, 3, 0), isFalse);

      // Close the ring and the board is dead: no move out of it at all, and
      // nothing to ask a half-defined chain about.
      final looped = SignpostPosition.of(puzzle, [1, 3, 0, 2]);
      expect(looped.impossible, isTrue);
      expect(engine.legal(looped, puzzle, 2, 1), isFalse);
    });

    test('two known numbers have to be consecutive', () {
      final puzzle = SignpostPuzzle(
        rows: 1,
        cols: 3,
        dirs: const [2, 2, 2],
        clues: const [1, 0, 3],
        solution: const [1, 2, 3],
      );
      final position = SignpostPosition.of(
        puzzle,
        List<int>.filled(3, -1),
      );
      // 0 holds 1 and its ray runs through both 1 and 2.
      expect(engine.legal(position, puzzle, 0, 1), isTrue);
      expect(engine.legal(position, puzzle, 0, 2), isFalse,
          reason: 'the numbers would land on 3, not 2');
    });

    test('two chains that number every cell between them are not an answer',
        () {
      // 0 -> 1 holds 1 and 2, 2 -> 3 holds 3 and 4, and 1's arrow really does
      // run through 2. The board is full of numbers and still not finished,
      // because 2 never points at 3.
      final puzzle = SignpostPuzzle(
        rows: 1,
        cols: 4,
        dirs: const [2, 2, 2, 2],
        clues: const [1, 0, 3, 0],
        solution: const [1, 2, 3, 4],
      );
      final split = [1, -1, 3, -1];
      final position = SignpostPosition.of(puzzle, split);
      expect(position.impossible, isFalse);
      expect(position.numbers, [1, 2, 3, 4]);
      expect(engine.isSolved(puzzle, split), isFalse);
      expect(SignpostModel(puzzle, split).isComplete, isFalse);
      expect(SignpostModel(puzzle, [1, 2, 3, -1]).isComplete, isTrue);
    });

    test('the last number points nowhere and nothing precedes the first', () {
      final puzzle =
          engine.generate(SignpostDifficulty.easy, random: Random(8));
      final position = SignpostPosition.of(
        puzzle,
        List<int>.filled(puzzle.cellCount, -1),
      );
      final last = puzzle.clues.indexOf(puzzle.cellCount);
      final first = puzzle.clues.indexOf(1);

      for (var to = 0; to < puzzle.cellCount; to++) {
        if (to == last) continue;
        expect(engine.legal(position, puzzle, last, to), isFalse,
            reason: 'the last number pointed at $to');
      }
      for (var from = 0; from < puzzle.cellCount; from++) {
        if (from == first) continue;
        expect(engine.legal(position, puzzle, from, first), isFalse,
            reason: 'cell $from claimed to come before the first number');
      }
    });
  });

  group('hint', () {
    test('names one link the answer has, from the board as it stands', () {
      final rng = Random(13);
      for (final difficulty in SignpostDifficulty.values) {
        final puzzle = engine.generate(difficulty, random: rng);
        final truth = engine.answerLinks(puzzle);
        final found = engine.hint(
          puzzle,
          List<int>.filled(puzzle.cellCount, -1),
        );
        expect(found, isNotNull, reason: '${difficulty.name}: no hint');
        expect(truth[found!.from], found.to,
            reason: '${difficulty.name}: the hint is not in the answer');
      }
    });

    test('has nothing to say on a finished board', () {
      final puzzle =
          engine.generate(SignpostDifficulty.medium, random: Random(4));
      expect(engine.hint(puzzle, engine.answerLinks(puzzle)), isNull);
    });
  });
}
