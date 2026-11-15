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
