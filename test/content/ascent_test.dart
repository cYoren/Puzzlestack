import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_guides.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/ui/features/games/ascent/ascent_engine.dart';

/// What Number Path owes the bar, checked against its own rule.
void main() {
  const engine = AscentEngine();

  test('every size is a board the path can fill', () {
    for (final size in AscentSize.values) {
      expect(size.n, greaterThanOrEqualTo(5), reason: size.name);
      expect(size.cellCount, size.n * size.n, reason: size.name);
    }
  });

  test('a dealt board has exactly one path', () {
    final rng = Random(7);
    for (var i = 0; i < 3; i++) {
      final puzzle = engine.generate(AscentSize.small, random: rng);
      final count = engine.count(puzzle, limit: 2);
      expect(count.truncated, isFalse, reason: 'budget #$i');
      expect(count.solutions, 1, reason: 'ambiguous #$i');
      expect(count.forced, puzzle.solution, reason: '#$i');
    }
  });

  test('no dealt board needs a guess', () {
    final rng = Random(8);
    for (var i = 0; i < 3; i++) {
      final puzzle = engine.generate(AscentSize.small, random: rng);
      expect(engine.levelOf(puzzle), isNotNull, reason: 'needs a guess #$i');
    }
  });

  test('the guide says how to play and how the board ends', () {
    final guide = gameGuides['ascent'];
    expect(guide, isNotNull);
    expect(guide!.category, 'LOGIC');
    expect(guide.objective.toLowerCase(), contains('touch'));
    expect(guide.controls.toLowerCase(), contains('tap'));
    expect(guide.walkthrough.length, greaterThanOrEqualTo(3));
    expect(guide.strategies, isNotEmpty);
  });

  test('the game is in the Library, not the Deck, and says why', () {
    final profile = gameProfiles['ascent'];
    expect(profile, isNotNull, reason: 'ascent missing from the catalog');
    expect(profile!.tier, GameTier.library);
    expect(profile.kind, CardKind.think);
    expect(profile.origin, GameOrigin.puzzle);
    expect(profile.reason, isNull);
  });
}
