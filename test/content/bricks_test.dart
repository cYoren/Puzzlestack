import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/ui/features/games/bricks/bricks_engine.dart';
import 'package:puzzle/ui/features/games/bricks/bricks_provider.dart';

/// What Bricks owes the bar, checked against its own rules.
void main() {
  const engine = BricksEngine();

  test('every size is a honeycomb the rules can walk', () {
    for (final size in BricksSize.values) {
      expect(size.rows, greaterThanOrEqualTo(5), reason: size.name);
      expect(size.cellCount, size.rows * size.cols, reason: size.name);
      final lattice = BricksLattice(size);
      expect(lattice.cellCount, size.cellCount, reason: size.name);
      for (var y = 0; y < size.rows; y++) {
        final inRow = lattice.row.where((row) => row == y).length;
        expect(inRow, size.cols, reason: '${size.name} row $y');
      }
    }
  });

  test('a dealt board has exactly one shading', () {
    final rng = Random(7);
    for (var i = 0; i < 3; i++) {
      final puzzle = engine.generate(BricksSize.small, random: rng);
      final found = engine.count(puzzle, limit: 2);
      expect(found.truncated, isFalse, reason: 'budget #$i');
      expect(found.solutions, 1, reason: 'ambiguous #$i');
      expect(found.forced, puzzle.solution, reason: '#$i');
    }
  });

  test('no dealt board needs a guess', () {
    final rng = Random(8);
    for (var i = 0; i < 3; i++) {
      final puzzle = engine.generate(BricksSize.small, random: rng);
      final level = engine.levelOf(puzzle);
      expect(level, isNotNull, reason: 'needs a guess #$i');
      // The exact search is level 3; a board that needs it is a lookup.
      expect(level, lessThanOrEqualTo(2), reason: 'needs the search #$i');
    }
  });

  test('every shaded cell in a dealt board is held up', () {
    // Rule 1, read from the answer and not through the solver: a shaded cell
    // outside the bottom row has a shaded cell in the bottom pair of the
    // neighbour table. This is the rule that a wrong neighbour table would
    // break while every count still added up.
    final rng = Random(11);
    for (final size in BricksSize.values) {
      final puzzle = engine.generate(size, random: rng);
      final lattice = puzzle.lattice;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (puzzle.solution[cell] != kBricksShaded) continue;
        if (lattice.isBottomRow(cell)) continue;
        expect(
          lattice
              .below(cell)
              .any((other) => puzzle.solution[other] == kBricksShaded),
          isTrue,
          reason: '${size.name} cell $cell floats',
        );
      }
    }
  });

  test('no dealt board has three shaded cells in a row', () {
    final rng = Random(13);
    for (final size in BricksSize.values) {
      final puzzle = engine.generate(size, random: rng);
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        final left = puzzle.lattice.leftOf(cell);
        final right = puzzle.lattice.rightOf(cell);
        if (left == null || right == null) continue;
        final shaded = [left, cell, right]
            .where((other) => puzzle.solution[other] == kBricksShaded)
            .length;
        expect(shaded, lessThan(3), reason: '${size.name} run at $cell');
      }
    }
  });

  test('a dealt board is a pile, not a corner', () {
    // A legal board with two shaded cells is a legal board and a bad card. The
    // floor is the generator's judgement, so it is checked rather than assumed.
    final rng = Random(19);
    for (final size in BricksSize.values) {
      final puzzle = engine.generate(size, random: rng);
      final shaded = puzzle.shadedIn(puzzle.solution) / puzzle.cellCount;
      expect(shaded, greaterThanOrEqualTo(BricksEngine.minimumShaded),
          reason: size.name);
    }
  });

  test('the clue vocabulary is three values that cannot be confused', () {
    // -1 is "nothing printed", 0..6 is a count, and a cell is unshaded or
    // shaded. A clue of 0 is a real clue (a cell with no shaded neighbours), so
    // "no clue" cannot also be 0.
    expect(kBricksNoClue, isNot(kBricksUnshaded));
    expect(kBricksNoClue, isNot(kBricksShaded));
    // One tap flips a cell and only a cell; the clue vocabulary never moves.
    expect(nextShading(kBricksUnshaded), kBricksShaded);
    expect(nextShading(kBricksShaded), kBricksUnshaded);

    final rng = Random(23);
    for (final size in BricksSize.values) {
      final puzzle = engine.generate(size, random: rng);
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        final clue = puzzle.clue(cell);
        if (clue == kBricksNoClue) continue;
        expect(clue, inInclusiveRange(0, 6), reason: '${size.name} $cell');
      }
      // A number of zero has to survive: it means "nothing around me is
      // shaded", which is a clue and not a blank.
      expect(puzzle.clues.where((clue) => clue == 0), isNotEmpty,
          reason: '${size.name} printed no zero, or treats zero as blank');
    }
  });

  test('the game is in the registry, once', () {
    final matches = allGamesMetadata.where((game) => game.id == 'bricks');
    expect(matches, hasLength(1));
    expect(matches.single.category, 'LOGIC');
  });
}
