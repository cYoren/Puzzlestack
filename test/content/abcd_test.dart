import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_guides.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/ui/features/games/abcd/abcd_engine.dart';

/// What ABCD owes the bar, checked against its own rule.
void main() {
  const engine = AbcdEngine();

  test('every size has room for its alphabet', () {
    for (final size in AbcdSize.values) {
      expect(size.letters, greaterThanOrEqualTo(2), reason: size.name);
      expect(size.letters, lessThanOrEqualTo(size.cols), reason: size.name);
      expect(size.rows, greaterThanOrEqualTo(4));
      expect(size.alphabet.length, size.letters);
      expect(size.alphabet[0], 'A');
    }
  });

  test('the feed size is the smallest preset the puzzle still works at', () {
    expect(AbcdSize.small.rows, 5);
    expect(AbcdSize.small.cols, 5);
    expect(AbcdSize.small.letters, 4);
  });

  test('a dealt board is proven unique and finishable at every size', () {
    final rng = Random(41);
    for (final size in AbcdSize.values) {
      for (var i = 0; i < 3; i++) {
        final puzzle = engine.generate(size, random: rng);
        // The proof is the harness, not the generator: it re-derives the answer
        // from the clues and counts it.
        expect(engine.harnessSolutions(puzzle, limit: 2), 1,
            reason: '${size.name} #$i must have exactly one grid');
        expect(engine.levelOf(puzzle), isNotNull,
            reason: '${size.name} #$i must not need a guess');
        expect(puzzle.isLegal(puzzle.solution), isTrue);
      }
    }
  });

  test('no line clue is marked done until its counts are met exactly', () {
    // The bug this pins: the board's row test asked only whether a letter had
    // overshot its target, which is true of an empty row, so every row clue was
    // green from the first frame while the column clues were honest. Both
    // directions are one function now, and it is an equality test.
    final puzzle = engine.generate(AbcdSize.small, random: Random(11));
    final empty = List<int>.filled(puzzle.cellCount, -1);

    for (var row = 0; row < puzzle.rows; row++) {
      expect(puzzle.rowSatisfied(empty, row), isFalse, reason: 'row $row');
    }
    for (var col = 0; col < puzzle.cols; col++) {
      expect(puzzle.colSatisfied(empty, col), isFalse, reason: 'col $col');
    }

    for (var row = 0; row < puzzle.rows; row++) {
      expect(puzzle.rowSatisfied(puzzle.solution, row), isTrue,
          reason: 'row $row of the answer');
    }
    for (var col = 0; col < puzzle.cols; col++) {
      expect(puzzle.colSatisfied(puzzle.solution, col), isTrue,
          reason: 'col $col of the answer');
    }

    // One cell changed and both of its lines stop being done.
    final edited = [...puzzle.solution];
    edited[0] = (edited[0] + 1) % puzzle.letters;
    expect(puzzle.rowSatisfied(edited, 0), isFalse);
    expect(puzzle.colSatisfied(edited, 0), isFalse);
  });

  test('the guide teaches the digit clue and the ending', () {
    final guide = gameGuides['abcd'];
    expect(guide, isNotNull);
    expect(guide!.category, 'LOGIC');
    expect(guide.objective.toLowerCase(), contains('letter'));
    expect(guide.controls.toLowerCase(), contains('tap'));
    expect(guide.walkthrough.length, greaterThanOrEqualTo(3));
    expect(guide.strategies, isNotEmpty);
  });

  test('the game is in the Library with an honest verdict', () {
    final profile = gameProfiles['abcd'];
    expect(profile, isNotNull, reason: 'abcd missing from the catalog');
    expect(profile!.tier, GameTier.library);
    expect(profile.kind, CardKind.think);
    expect(profile.origin, GameOrigin.puzzle);
    expect(profile.reason, isNull);
  });
}
