import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/mathrax/mathrax_engine.dart';
import 'package:puzzle/ui/features/games/mathrax/mathrax_puzzle.dart';

/// The content rule for Mathrax: every dealt board is a Latin square, and every
/// clue on it is true of the answer. A clue that is false would make the board
/// unsolvable while looking normal, which is the failure that no layout test can
/// catch.
void main() {
  const engine = MathraxEngine();

  test('every dealt board is a Latin square', () {
    final rng = Random(21);
    for (final size in MathraxSize.values) {
      for (var deal = 0; deal < 3; deal++) {
        final puzzle = engine.generate(size, random: rng);
        final n = size.n;
        for (var row = 0; row < n; row++) {
          final inRow = {
            for (var col = 0; col < n; col++)
              puzzle.solution[puzzle.cell(row, col)]
          };
          expect(inRow, {for (var digit = 1; digit <= n; digit++) digit},
              reason: '${size.name} row $row');
          final inCol = {
            for (var col = 0; col < n; col++)
              puzzle.solution[puzzle.cell(col, row)]
          };
          expect(inCol, {for (var digit = 1; digit <= n; digit++) digit},
              reason: '${size.name} column $row');
        }
      }
    }
  });

  test('every clue is true of the answer it was read from', () {
    final rng = Random(22);
    for (final size in MathraxSize.values) {
      final puzzle = engine.generate(size, random: rng);
      for (var row = 0; row < size.n - 1; row++) {
        for (var col = 0; col < size.n - 1; col++) {
          final clue = puzzle.clueAt(row, col);
          if (clue == null) continue;
          expect(puzzle.cornerHolds(row, col, puzzle.solution), isTrue,
              reason: '${size.name} clue ${clue.label} at $row,$col lies');
        }
      }
    }
  });

  test('a clue with a number carries the operation it prints', () {
    final rng = Random(23);
    final seen = <MathraxOp>{};
    for (final size in MathraxSize.values) {
      for (var deal = 0; deal < 2; deal++) {
        final puzzle = engine.generate(size, random: rng);
        for (final clue in puzzle.clues) {
          if (clue == null) continue;
          seen.add(clue.op);
          if (clue.op.takesValue) {
            expect(clue.label, '${clue.op.sign}${clue.value}');
            expect(clue.value, greaterThan(0));
          } else {
            expect(clue.value, 0, reason: 'E, O and = carry no number');
            expect(clue.label, clue.op.sign);
          }
        }
      }
    }
    // Every operation the game teaches has to turn up somewhere, or the guide
    // describes a clue the player will never meet.
    expect(
        seen,
        containsAll(<MathraxOp>[
          MathraxOp.add,
          MathraxOp.even,
        ]));
  });

  test('the board the player is given is not the answer', () {
    final rng = Random(24);
    for (final size in MathraxSize.values) {
      final puzzle = engine.generate(size, random: rng);
      expect(puzzle.clues.where((clue) => clue != null).length,
          lessThan(size.clueCount),
          reason: '${size.name} prints every corner, which is not a puzzle');
    }
  });
}
