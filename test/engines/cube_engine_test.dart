import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/cube/cube_engine.dart';

void main() {
  const engine = CubeEngine();

  group('generator', () {
    for (final difficulty in CubeDifficulty.values) {
      test('${difficulty.name}: 20 boards, each cleared by its own line', () {
        final rng = Random(difficulty.index + 17);
        for (var i = 0; i < 20; i++) {
          final puzzle = engine.generate(difficulty, random: rng);
          final where = '${difficulty.name} board $i';

          expect(puzzle.rows, difficulty.rows);
          expect(puzzle.cols, difficulty.cols);
          expect(puzzle.targets.length, CubeFace.count,
              reason: '$where: six blue squares, no more');
          expect(puzzle.targets.toSet().length, CubeFace.count,
              reason: '$where: a square is blue twice');
          expect(puzzle.isTarget(puzzle.start), isFalse,
              reason: '$where: the cube starts on a blue square');

          // The shortest line clears the board, and it is the length the board
          // advertises.
          final line = engine.solve(puzzle, engine.startOf(puzzle));
          expect(line, isNotNull, reason: '$where: no line clears the board');
          expect(line!.length, puzzle.minMoves,
              reason: '$where: minMoves is not the shortest line');
          expect(line.length, greaterThanOrEqualTo(difficulty.minMoves),
              reason: '$where: too short for the tier');
          expect(line.length, lessThanOrEqualTo(difficulty.maxMoves),
              reason: '$where: too long for the tier');

          // Replay it: this is the proof the board can actually be finished, and
          // it is what catches a solver that disagrees with the rules.
          var position = engine.startOf(puzzle);
          for (final direction in line) {
            position = engine.roll(puzzle, position, direction);
          }
          expect(position.isSolved, isTrue, reason: '$where: the line does not finish');
          expect(position.paintedFaces, CubeFace.count);
        }
      });
    }
  });

  group('rules', () {
    test('a roll off the grid does nothing', () {
      final puzzle = engine.generate(CubeDifficulty.easy, random: Random(3));
      var position = engine.startOf(puzzle);
      // Walk into the north-west corner, then try to keep going.
      position = position.copyWith(cell: 0);
      final rolled = engine.roll(puzzle, position, CubeDirection.north);
      expect(rolled.cell, 0);
      expect(rolled.faces, position.faces);
      expect(rolled.squares, position.squares);
    });

    test('landing on a square swaps one colour, never creates one', () {
      final puzzle = engine.generate(CubeDifficulty.easy, random: Random(5));
      var position = engine.startOf(puzzle);
      var ones = position.faces.where((f) => f == 1).length +
          position.squares.where((s) => s == 1).length;

      for (final direction in CubeDirection.values) {
        final moved = engine.roll(puzzle, position, direction);
        final after = moved.faces.where((f) => f == 1).length +
            moved.squares.where((s) => s == 1).length;
        expect(after, ones, reason: 'rolling ${direction.name} changed the count');
      }
      ones = position.faces.where((f) => f == 1).length +
          position.squares.where((s) => s == 1).length;
      expect(ones, CubeFace.count, reason: 'a board starts with six blues');
    });

    test('rolling north then south puts the cube back', () {
      final puzzle = engine.generate(CubeDifficulty.easy, random: Random(9));
      final position = engine.startOf(puzzle);
      // A clean cube and a clean grid: no swap can muddle the comparison.
      final clean = position.copyWith(
        faces: List<int>.filled(CubeFace.count, 0),
        squares: List<int>.filled(position.squares.length, 0),
        cell: 5,
      );
      for (final pair in [
        (CubeDirection.north, CubeDirection.south),
        (CubeDirection.south, CubeDirection.north),
        (CubeDirection.east, CubeDirection.west),
        (CubeDirection.west, CubeDirection.east),
      ]) {
        final once = engine.roll(puzzle, clean, pair.$1);
        final back = engine.roll(puzzle, once, pair.$2);
        expect(back.cell, clean.cell, reason: '${pair.$1.name} then ${pair.$2.name}');
        expect(back.faces, clean.faces, reason: '${pair.$1.name} then ${pair.$2.name}');
      }
    });

    test('a solved cube keeps rolling without taking the win back', () {
      final puzzle = engine.generate(CubeDifficulty.easy, random: Random(11));
      var position = engine.startOf(puzzle);
      final line = engine.solve(puzzle, position)!;
      for (final direction in line) {
        position = engine.roll(puzzle, position, direction);
      }
      expect(position.isSolved, isTrue);
      final after = engine.roll(puzzle, position, CubeDirection.east);
      expect(after.isSolved, isTrue, reason: 'the reward roll un-solved the cube');
    });
  });

  group('hint', () {
    test('names a move that still reaches a win', () {
      final rng = Random(13);
      for (var i = 0; i < 5; i++) {
        final puzzle = engine.generate(CubeDifficulty.easy, random: rng);
        final position = engine.startOf(puzzle);
        final hint = engine.hint(puzzle, position);
        expect(hint, isNotNull);
        final after = engine.roll(puzzle, position, hint!);
        expect(engine.solve(puzzle, after), isNotNull,
            reason: 'board $i: the hinted move leads nowhere');
      }
    });
  });
}
