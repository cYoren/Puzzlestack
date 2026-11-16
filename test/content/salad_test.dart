import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/salad/salad_engine.dart';
import 'package:puzzle/ui/features/games/salad/salad_puzzle.dart';

/// The content rule for Salad: every dealt board is a Latin square with the
/// right holes, and every clue on the border is true of the answer. A clue that
/// is false would make the board unsolvable while looking normal, which is the
/// failure no layout test can catch.
void main() {
  const engine = SaladEngine();

  test('every dealt board obeys the game rule, in every line', () {
    final rng = Random(21);
    for (final size in SaladSize.values) {
      for (var deal = 0; deal < 2; deal++) {
        final puzzle = engine.generate(size, random: rng);
        for (var line = 0; line < size.n; line++) {
          final row = [
            for (var i = 0; i < size.n; i++)
              puzzle.solution[puzzle.cell(line, i)]
          ];
          final col = [
            for (var i = 0; i < size.n; i++)
              puzzle.solution[puzzle.cell(i, line)]
          ];
          for (final cells in [row, col]) {
            final letters = cells.where((value) => value != kSaladHole);
            expect(letters.where((value) => value == kSaladBlank), isEmpty,
                reason: '${size.name} line $line has an unwritten cell');
            expect(letters.toSet(),
                {for (var letter = 1; letter <= size.nums; letter++) letter},
                reason: '${size.name} line $line is not one of each letter');
            expect(cells.length - letters.length, size.holes,
                reason: '${size.name} line $line has the wrong hole count');
          }
        }
      }
    }
  });

  test('every border clue is true of the answer it was read from', () {
    final rng = Random(22);
    for (final size in SaladSize.values) {
      final puzzle = engine.generate(size, random: rng);
      for (final dir in SaladClueDir.values) {
        for (var index = 0; index < size.n; index++) {
          final clue = puzzle.clue(dir, index);
          if (clue == kSaladNoClue) continue;
          final seen = puzzle
              .line(dir, index)
              .map((cell) => puzzle.solution[cell])
              .firstWhere((value) => value != kSaladHole);
          expect(seen, clue,
              reason: '${size.name} ${dir.name} $index says '
                  '$clue, the answer shows $seen');
        }
      }
    }
  });

  test('a clue is a letter or nothing: zero is the hole', () {
    final rng = Random(23);
    for (final size in SaladSize.values) {
      final puzzle = engine.generate(size, random: rng);
      for (final clue in puzzle.clues) {
        expect(clue, isNot(kSaladHole), reason: 'a clue of 0 reads as a hole');
        expect(clue, isNot(kSaladBlank), reason: 'a clue is never unwritten');
        expect(clue, anyOf(kSaladNoClue, inInclusiveRange(1, size.nums)));
      }
      // The board is a border, not a grid of givens: every cell starts blank.
      expect(puzzle.clues.length, size.clueCount);
    }
  });

  test('the border is a puzzle, not the answer printed around the edge', () {
    final rng = Random(24);
    for (final size in SaladSize.values) {
      final puzzle = engine.generate(size, random: rng);
      final shown = puzzle.clues.where((c) => c != kSaladNoClue).length;
      expect(shown, lessThan(size.clueCount),
          reason: '${size.name} prints every clue, which is not a puzzle');
      // Every one of the four directions still has something to read, or the
      // board is a riddle with a missing side.
      for (final dir in SaladClueDir.values) {
        final onEdge = [for (var i = 0; i < size.n; i++) puzzle.clue(dir, i)]
            .where((clue) => clue != kSaladNoClue);
        expect(onEdge, isNotEmpty, reason: '${size.name} ${dir.name} is bare');
      }
    }
  });
}
