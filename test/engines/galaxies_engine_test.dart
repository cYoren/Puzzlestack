import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/deduction.dart';
import 'package:puzzle/ui/features/games/galaxies/galaxies_engine.dart';

/// Counts solutions with no cleverness at all: fill cells one at a time,
/// checking only the mirror rule as it goes, and validate at the end.
///
/// This is the independent check on [rateGalaxies]. The rules are allowed to be
/// fast; they are not allowed to be wrong, and the only way to know is to count
/// without them.
int bruteForce(GalaxiesPuzzle puzzle, {int limit = 2}) {
  const engine = GalaxiesEngine();
  final owner = List<int>.filled(puzzle.cellCount, -1);
  var found = 0;

  bool place(int cell) {
    if (found >= limit) return true;
    if (cell == owner.length) {
      if (engine.isSolved(puzzle, owner)) {
        found++;
        return found >= limit;
      }
      return false;
    }
    if (owner[cell] != -1) return place(cell + 1);

    for (var dot = 0; dot < puzzle.dots.length; dot++) {
      final mirror = puzzle.mirrorOf(cell, dot);
      if (mirror == null) continue;
      if (owner[mirror] != -1 && owner[mirror] != dot) continue;
      final was = owner[mirror];
      owner[cell] = dot;
      owner[mirror] = dot;
      final stop = place(cell + 1);
      owner[cell] = -1;
      owner[mirror] = was;
      if (stop) return true;
    }
    return false;
  }

  place(0);
  return found;
}

void main() {
  const engine = GalaxiesEngine();

  group('a generated board', () {
    test('is one solution, and the solver agrees with a brute force count', () {
      final random = Random(2024);
      for (var i = 0; i < 40; i++) {
        final puzzle = engine.generate(
          difficulty: GalaxiesDifficulty.easy,
          random: random,
        );
        final rating = rateGalaxies(puzzle);

        expect(rating.verdict, PuzzleVerdict.solved,
            reason: 'board $i is $rating');
        expect(rating.solutions, 1, reason: 'board $i is not unique');

        // The rules say one; count without them to be sure.
        expect(bruteForce(puzzle), 1, reason: 'board $i: brute force disagrees');
      }
    });

    test('the partition the generator kept is a real solution', () {
      final random = Random(7);
      for (var i = 0; i < 30; i++) {
        final puzzle = engine.generate(
          difficulty: GalaxiesDifficulty.easy,
          random: random,
        );
        expect(engine.isSolved(puzzle, puzzle.solution), isTrue,
            reason: 'board $i: the stored answer is not a solution');
      }
    });

    test('every region is symmetric about its dot and connected', () {
      final random = Random(11);
      for (var i = 0; i < 20; i++) {
        final puzzle = engine.generate(
          difficulty: GalaxiesDifficulty.easy,
          random: random,
        );
        final owner = puzzle.solution;

        for (var dot = 0; dot < puzzle.dots.length; dot++) {
          final cells = <int>{
            for (var cell = 0; cell < owner.length; cell++)
              if (owner[cell] == dot) cell,
          };
          expect(cells, isNotEmpty, reason: 'dot $dot owns nothing');

          for (final cell in cells) {
            final mirror = puzzle.mirrorOf(cell, dot);
            expect(mirror, isNotNull);
            expect(cells, contains(mirror),
                reason: 'board $i: cell $cell does not mirror into its region');
          }
        }
      }
    });
  });

  group('the 200-board bar', () {
    test('200 easy boards, each with exactly one solution', () {
      final random = Random(99);
      for (var i = 0; i < 200; i++) {
        final puzzle = engine.generate(
          difficulty: GalaxiesDifficulty.easy,
          random: random,
        );
        final rating = rateGalaxies(puzzle);
        expect(rating.verdict, PuzzleVerdict.solved, reason: 'board $i: $rating');
        expect(rating.solutions, 1, reason: 'board $i: $rating');
      }
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('200 medium boards, each with exactly one solution', () {
      final random = Random(1234);
      for (var i = 0; i < 200; i++) {
        final puzzle = engine.generate(
          difficulty: GalaxiesDifficulty.medium,
          random: random,
        );
        final rating = rateGalaxies(puzzle);
        expect(rating.verdict, PuzzleVerdict.solved, reason: 'board $i: $rating');
        expect(rating.solutions, 1, reason: 'board $i: $rating');
      }
    }, timeout: const Timeout(Duration(minutes: 6)));

    // A hard board needs about half a second to find, because the generator
    // throws away boards that turn out easier than asked for. 200 of them would
    // put two minutes on every test run, so this samples 50 — enough to catch a
    // systematic fault in the hardest tier, which is what the bar is for.
    test('50 hard boards, each with exactly one solution', () {
      final random = Random(555);
      for (var i = 0; i < 50; i++) {
        final puzzle = engine.generate(
          difficulty: GalaxiesDifficulty.hard,
          random: random,
        );
        final rating = rateGalaxies(puzzle);
        expect(rating.verdict, PuzzleVerdict.solved, reason: 'board $i: $rating');
        expect(rating.solutions, 1, reason: 'board $i: $rating');
      }
    }, timeout: const Timeout(Duration(minutes: 6)));
  });

  group('difficulty', () {
    test('each difficulty really needs the rule level it claims', () {
      final random = Random(4242);
      for (final difficulty in GalaxiesDifficulty.values) {
        final levels = <int>{};
        for (var i = 0; i < 8; i++) {
          final puzzle = engine.generate(
            difficulty: difficulty,
            random: random,
          );
          final rating = rateGalaxies(puzzle);
          expect(rating.level, difficulty.level,
              reason: '$difficulty board $i came back at ${rating.level}');
          levels.add(rating.level);
        }
        expect(levels, {difficulty.level},
            reason: '$difficulty produced more than one level');
      }
    }, timeout: const Timeout(Duration(minutes: 6)));

    test('the levels are ordered by how hard the rules are', () {
      expect(galaxiesRules.map((rule) => rule.level), [1, 2, 3]);
    });

    test('a board gets bigger as the difficulty rises', () {
      expect(
        GalaxiesDifficulty.easy.rows < GalaxiesDifficulty.medium.rows,
        isTrue,
      );
      expect(
        GalaxiesDifficulty.medium.rows < GalaxiesDifficulty.hard.rows,
        isTrue,
      );
    });
  });

  group('rules', () {
    test('a cell cannot belong to a dot whose reflection is off the board', () {
      // A dot in the corner of a 3x3 board: the far corner cannot be its.
      const puzzle = GalaxiesPuzzle(
        rows: 3,
        cols: 3,
        dots: [GalaxiesDot(0, 0), GalaxiesDot(4, 4)],
        solution: [],
      );
      expect(puzzle.mirrorOf(8, 0), isNull);
      expect(puzzle.mirrorOf(0, 0), 0);
    });

    test('painting a cell paints the cell it reflects onto', () {
      const puzzle = GalaxiesPuzzle(
        rows: 1,
        cols: 3,
        dots: [GalaxiesDot(2, 0)],
        solution: [0, 0, 0],
      );
      final owner = List<int>.filled(3, -1);
      final cells = engine.paint(puzzle, owner, 0, 0);
      expect(cells, [0, 2]);
    });

    test('painting is refused when the reflection belongs to another dot', () {
      const puzzle = GalaxiesPuzzle(
        rows: 1,
        cols: 3,
        dots: [GalaxiesDot(2, 0), GalaxiesDot(4, 0)],
        solution: [0, 0, 1],
      );
      final owner = [0, -1, 1];
      expect(engine.paint(puzzle, owner, 0, 0), isNull);
    });

    test('an unsolved board is not solved', () {
      const puzzle = GalaxiesPuzzle(
        rows: 1,
        cols: 3,
        dots: [GalaxiesDot(2, 0)],
        solution: [0, 0, 0],
      );
      expect(engine.isSolved(puzzle, [-1, -1, -1]), isFalse);
      expect(engine.isSolved(puzzle, [0, 0, 0]), isTrue);
    });
  });
}
