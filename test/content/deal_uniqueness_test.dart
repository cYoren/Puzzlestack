// G4: "No game can be dealt unwinnable, or with two answers where one is
// implied."
//
// One case per Deck family, never per game, and never a second solver. A
// family either drives the game's own generator and prover, or it carries a
// finding and is skipped with that id. A green family means the property was
// checked for every id it lists; a skipped family means it was not, and the
// finding says why.
//
// FINDINGS (the families that are not proved, with the reason)
//
//   G4-F1  Logic, 24 ids: no uniqueness counter or solver is reachable from
//          outside the engine; some guards are private to the generator.
//   G4-F2  Math, 19 ids: the answer is computed at deal time and no prover is
//          exported.
//   G4-F3  Memory, 1 id: hidden-state sequence; fairness is judged by play.
//   G4-F4  Attention, 5 ids: hidden/timed targets; fairness is judged by play.
//   G4-F5  Word, 24 ids: fixed pools with no exported whole-pool accessor.
//   G4-F6  Spatial, 22 ids: generators expose no finishability or uniqueness
//          prover.
//
// No family produced a counterexample with a failing seed. The skipped families
// are missing proof, not observed failures: that distinction is the reason they
// are `skip`, not `fail`.
//
// Mutation that proves this file can fail: in a scratch copy of
// `lib/ui/features/games/norinori/norinori_engine.dart`, change
// `if (candidates.length != 1) continue;` to `if (candidates.isEmpty)
// continue;`. The `G4-deduction` case fails on the norinori count (seed 0 is
// enough) and its message names the game and seed. Reverted before commit.

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_profiles.dart';

import 'deal_families.dart';

void main() {
  final deck = deckIds;

  for (final family in dealFamilies) {
    test(
      'G4 ${family.label} (${family.games.length} games)',
      () {
        final failures = family.run();
        expect(
          failures,
          isEmpty,
          reason: 'G4 violations:\n${failures.join('\n')}',
        );
      },
      skip: family.finding == null ? false : '${family.id}: ${family.finding}',
    );
  }

  test('every Deck id is in exactly one G4 family', () {
    final seen = <String, String>{};
    final overlaps = <String>[];
    final unknown = <String>[];
    for (final family in dealFamilies) {
      for (final game in family.games) {
        final previous = seen[game];
        if (previous != null) {
          overlaps.add('$game: $previous and ${family.id}');
        } else {
          seen[game] = family.id;
        }
        if (!deck.contains(game)) unknown.add('$game (${family.id})');
      }
    }

    final uncovered = deck.difference(seen.keys.toSet()).toList()..sort();

    expect(
      overlaps,
      isEmpty,
      reason: 'overlapping families:\n${overlaps.join('\n')}',
    );
    expect(unknown, isEmpty, reason: 'not Deck ids:\n${unknown.join('\n')}');
    expect(
      uncovered,
      isEmpty,
      reason: 'Deck ids with no G4 family:\n${uncovered.join('\n')}',
    );
  });

  test(
    'a family either has a probe or a finding, never both, never neither',
    () {
      final bad = <String>[];
      for (final family in dealFamilies) {
        final hasProbe = family.probe != null;
        final hasFinding = family.finding != null;
        if (hasProbe == hasFinding) {
          bad.add('${family.id}: probe=$hasProbe finding=$hasFinding');
        }
      }
      expect(bad, isEmpty, reason: bad.join('\n'));
    },
  );

  test('a skipped family never runs its probe', () {
    for (final family in dealFamilies) {
      if (family.finding == null) continue;
      expect(
        family.run(),
        isEmpty,
        reason: '${family.id} is skipped but returned a verdict',
      );
    }
  });
}
