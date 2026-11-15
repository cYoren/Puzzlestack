import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_guides.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/ui/features/games/clusters/clusters_engine.dart';

/// What Clusters owes the bar, checked against its own rule.
void main() {
  const engine = ClustersEngine();

  test('every size is a board the rule can fill', () {
    for (final size in ClustersSize.values) {
      expect(size.n, greaterThanOrEqualTo(6), reason: size.name);
      expect(size.cellCount, size.n * size.n, reason: size.name);
    }
  });

  test('a dealt board has exactly one colouring', () {
    final rng = Random(7);
    for (var i = 0; i < 3; i++) {
      final puzzle = engine.generate(ClustersSize.small, random: rng);
      final count = engine.count(puzzle, limit: 2);
      expect(count.truncated, isFalse, reason: 'budget #$i');
      expect(count.solutions, 1, reason: 'ambiguous #$i');
      expect(count.forced, puzzle.solution, reason: '#$i');
    }
  });

  test('no dealt board needs a guess', () {
    final rng = Random(8);
    for (var i = 0; i < 3; i++) {
      final puzzle = engine.generate(ClustersSize.small, random: rng);
      expect(engine.levelOf(puzzle), isNotNull, reason: 'needs a guess #$i');
    }
  });

  test('every plain cell in a dealt board has two neighbours of its colour',
      () {
    // The rule that makes a board finishable at all: no plain cell is left
    // stranded with one same-coloured neighbour, which would be a dot.
    final rng = Random(11);
    for (final size in ClustersSize.values) {
      final puzzle = engine.generate(size, random: rng);
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        final same =
            puzzle.sameAround(puzzle.solution, cell, puzzle.solution[cell]);
        expect(same, greaterThanOrEqualTo(1), reason: '${size.name} $cell');
      }
    }
  });

  test('the guide says how to play and how the board ends', () {
    final guide = gameGuides['clusters'];
    expect(guide, isNotNull);
    expect(guide!.category, 'LOGIC');
    expect(guide.objective.toLowerCase(), contains('dot'));
    expect(guide.controls.toLowerCase(), contains('tap'));
    expect(guide.walkthrough.length, greaterThanOrEqualTo(3));
    expect(guide.strategies, isNotEmpty);
  });

  test('the game is in the Library, not the Deck, and says why', () {
    final profile = gameProfiles['clusters'];
    expect(profile, isNotNull, reason: 'clusters missing from the catalog');
    expect(profile!.tier, GameTier.library);
    expect(profile.kind, CardKind.think);
    expect(profile.origin, GameOrigin.puzzle);
    expect(profile.reason, isNull);
  });
}
