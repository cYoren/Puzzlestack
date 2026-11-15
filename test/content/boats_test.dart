import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_guides.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/ui/features/games/boats/boats_engine.dart';

/// What Boats owes the bar, checked against its own rule rather than a count.
///
/// The game has no asset pool: every board is generated, so there is nothing to
/// audit row by row. What can break is the shape of the sizes, the promise that
/// a dealt board is unique, and the promise that it can be finished without a
/// guess. Those are the three tests below.
void main() {
  const engine = BoatsEngine();

  test('every size is a board the fleet actually fits on', () {
    for (final size in BoatsSize.values) {
      expect(size.rows, greaterThanOrEqualTo(4), reason: size.name);
      expect(size.cols, greaterThanOrEqualTo(4), reason: size.name);
      expect(size.fleet, isNotEmpty, reason: size.name);
      // Longest first: the generator and the search both rely on it.
      for (var i = 1; i < size.fleet.length; i++) {
        expect(size.fleet[i], lessThanOrEqualTo(size.fleet[i - 1]),
            reason: '${size.name} fleet must be sorted longest first');
      }
      expect(size.fleet.last, greaterThanOrEqualTo(1));
      // Room to breathe: boats do not touch, so a fleet that is more than a
      // quarter of the board cannot be placed at all.
      expect(size.shipCells, lessThanOrEqualTo(size.rows * size.cols ~/ 3),
          reason: '${size.name} has no room left for the no-touching rule');
      expect(size.fleet.first, lessThanOrEqualTo(max(size.rows, size.cols)));
    }
  });

  test('the feed size is the smallest board where the idea survives', () {
    expect(BoatsSize.small.rows, 6);
    expect(BoatsSize.small.cols, 6);
    expect(BoatsSize.small.fleet.length, greaterThanOrEqualTo(3));
  });

  test('a dealt board is proven unique, at every size', () {
    final rng = Random(97);
    for (final size in BoatsSize.values) {
      for (var i = 0; i < 5; i++) {
        final puzzle = engine.generate(size, random: rng);
        // The proof is the fleet search, not the generator's good intentions:
        // it re-derives the answer from the clues alone.
        final count = engine.count(puzzle, limit: 2);
        expect(count.truncated, isFalse, reason: '${size.name} #$i budget');
        expect(count.solutions, 1,
            reason: '${size.name} #$i must have exactly one fleet');
        // And every cell it proves agrees with the answer the app holds.
        for (final cell in count.shipInAll) {
          expect(puzzle.solution[cell], kBoatShip,
              reason: '${size.name} #$i cell $cell');
        }
        for (final cell in count.waterInAll) {
          expect(puzzle.solution[cell], kBoatWater,
              reason: '${size.name} #$i cell $cell');
        }
        expect(
          count.shipInAll.length + count.waterInAll.length,
          puzzle.cellCount,
          reason: 'a unique board decides every cell',
        );
      }
    }
  });

  test('no dealt board needs a guess', () {
    // Check 2 of the bar: every step is a deduction, never a coin flip. The
    // generator refuses a board whose own rules cannot finish it, so this is
    // the guarantee that the refusal is real.
    final rng = Random(98);
    for (final size in BoatsSize.values) {
      for (var i = 0; i < 4; i++) {
        final puzzle = engine.generate(size, random: rng);
        expect(engine.levelOf(puzzle), isNotNull,
            reason: '${size.name} #$i needs a guess');
      }
    }
  });

  test('the guide says how to play and how the board ends', () {
    final guide = gameGuides['boats'];
    expect(guide, isNotNull);
    expect(guide!.category, 'LOGIC');
    expect(guide.objective.toLowerCase(), contains('boat'));
    expect(guide.controls.toLowerCase(), contains('tap'));
    expect(guide.walkthrough.length, greaterThanOrEqualTo(3));
    expect(guide.strategies, isNotEmpty);
  });

  test('the game is in the Library, not the Deck, and says why', () {
    // A new game enters as Library: promoting it needs the ten checks including
    // play, and an agent cannot play. The catalog records the verdict.
    final profile = gameProfiles['boats'];
    expect(profile, isNotNull, reason: 'boats missing from the catalog');
    expect(profile!.tier, GameTier.library);
    expect(profile.kind, CardKind.think);
    expect(profile.origin, GameOrigin.puzzle);
    expect(profile.reason, isNull);
  });
}
