import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_guides.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/ui/features/games/seismic/seismic_engine.dart';

/// What Seismic owes the bar, checked against its own rule.
///
/// The game has no asset pool: every board is generated and proved, so there
/// is nothing to audit row by row. What can break is the ripple rule itself,
/// the promise that a dealt board has one answer, and the promise that it can
/// be finished without guessing. Those are the tests below.
void main() {
  const engine = SeismicEngine();

  test('every size is a board its own rule can live on', () {
    for (final size in SeismicSize.values) {
      expect(size.n, greaterThanOrEqualTo(4), reason: size.name);
      expect(size.cellCount, size.n * size.n, reason: size.name);
    }
  });

  test('the feed size is the C collection default, and it is the middle size',
      () {
    expect(SeismicSize.medium.n, 6);
  });

  test('a dealt board has exactly one answer', () {
    final rng = Random(7);
    for (var i = 0; i < 3; i++) {
      final puzzle = engine.generate(SeismicSize.medium, random: rng);
      final count = engine.count(puzzle, limit: 2);
      expect(count.truncated, isFalse, reason: 'budget #$i');
      expect(count.solutions, 1, reason: 'ambiguous #$i');
      // The answer the search keeps is the answer the app holds.
      expect(count.forced, puzzle.solution, reason: '#$i');
    }
  });

  test('no dealt board needs a guess', () {
    final rng = Random(8);
    for (var i = 0; i < 3; i++) {
      final puzzle = engine.generate(SeismicSize.medium, random: rng);
      expect(engine.levelOf(puzzle), isNotNull, reason: 'needs a guess #$i');
    }
  });

  test('the guide says how to play and how the board ends', () {
    final guide = gameGuides['seismic'];
    expect(guide, isNotNull);
    expect(guide!.category, 'LOGIC');
    expect(guide.objective.toLowerCase(), contains('shape'));
    expect(guide.controls.toLowerCase(), contains('tap'));
    expect(guide.walkthrough.length, greaterThanOrEqualTo(3));
    expect(guide.strategies, isNotEmpty);
  });

  test('the game is in the Library, not the Deck, and says why', () {
    // A new game enters as Library: promotion needs the ten checks including
    // play, and an agent cannot play. The catalog records the verdict.
    final profile = gameProfiles['seismic'];
    expect(profile, isNotNull, reason: 'seismic missing from the catalog');
    expect(profile!.tier, GameTier.library);
    expect(profile.kind, CardKind.think);
    expect(profile.origin, GameOrigin.puzzle);
    expect(profile.reason, isNull);
  });
}
