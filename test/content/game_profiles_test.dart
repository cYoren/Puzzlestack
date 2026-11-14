import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/data/game_registry.dart';

/// `lib/data/game_profiles.dart` is generated from `docs/CATALOG.md`. The tests here are
/// the contract between the two: the document is where a person edits a verdict, and the
/// table is what the app reads, so a disagreement has to fail the build rather than show
/// up as a game on the wrong surface.
///
/// They are also where gate G1 of the release (`ROADMAP.md`) is checked: at least a
/// hundred games in the deal, and no single room taking it over.
void main() {
  final String catalog = File('docs/CATALOG.md').readAsStringSync();
  final Map<String, String> docTiers = _parseTiers(catalog);
  final Map<String, String> docFamilies = _parseFamilies(catalog);

  final Set<String> registryIds = allGamesMetadata.map((g) => g.id).toSet();

  group('the catalog and the table agree', () {
    test('every game in the document is in the table, with the same tier', () {
      final mismatched = <String>[];
      for (final entry in docTiers.entries) {
        final tier = gameProfiles[entry.key]?.tier.name;
        if (tier != entry.value) {
          mismatched.add('${entry.key}: doc ${entry.value}, code $tier');
        }
      }
      expect(mismatched, isEmpty,
          reason: 'run tool/gen_game_profiles.py: ${mismatched.take(10).join('; ')}');
    });

    test('the table has no game the document does not', () {
      final extra = gameProfiles.keys.where((id) => !docTiers.containsKey(id));
      expect(extra, isEmpty);
    });

    test('merged twins point at their keeper, and the keeper is playable', () {
      for (final entry in docFamilies.entries) {
        final profile = gameProfiles[entry.key];
        expect(profile, isNotNull, reason: '${entry.key} is missing from the table');
        expect(profile!.tier, GameTier.archive,
            reason: '${entry.key} was absorbed by ${entry.value}');
        expect(profile.reason, ArchiveReason.twin);
        expect(profile.family, entry.value,
            reason: '${entry.key} should name ${entry.value} as its family');
        expect(visibleIds, contains(entry.value),
            reason: '${entry.value} absorbs ${entry.key} but is not playable itself');
      }
    });

    test('only archived games carry an archive reason', () {
      for (final entry in gameProfiles.entries) {
        final profile = entry.value;
        if (profile.tier == GameTier.archive) {
          expect(profile.reason, isNotNull, reason: entry.key);
        } else {
          expect(profile.reason, isNull,
              reason: '${entry.key} is ${profile.tier.name} and cannot be archived');
        }
      }
    });
  });

  group('every registry game has exactly one verdict', () {
    test('the table covers the registry and nothing else', () {
      expect(gameProfiles.keys.toSet(), registryIds);
    });

    test('nothing is both playable and archived', () {
      for (final id in deckIds) {
        expect(gameProfiles[id]!.tier, GameTier.deck);
        expect(visibleIds, contains(id));
      }
      for (final entry in gameProfiles.entries) {
        if (entry.value.tier == GameTier.archive) {
          expect(visibleIds, isNot(contains(entry.key)));
        }
      }
    });
  });

  group('G1: the deal is big enough to feed, and no room takes it over', () {
    test('at least a hundred games are in the deal', () {
      expect(deckIds.length, greaterThanOrEqualTo(100),
          reason: 'the deal cannot feed a session from ${deckIds.length} games');
    });

    test('no room is more than 40% of the deal', () {
      final deck = GameCategories.deck;
      expect(deck.length, deckIds.length);
      final perRoom = <String, int>{};
      for (final game in deck) {
        perRoom[game.category] = (perRoom[game.category] ?? 0) + 1;
      }
      final limit = (deck.length * 0.4).ceil();
      final over = perRoom.entries.where((e) => e.value > limit).toList();
      expect(over, isEmpty,
          reason: 'over $limit of ${deck.length} cards: '
              '${over.map((e) => '${e.key} ${e.value}').join(', ')}');
    });
  });

  group('a game carries its verdict', () {
    test('every registry game has one, reachable from the game itself', () {
      expect(gamesWithoutVerdict(allGamesMetadata), isEmpty);
      for (final game in GameCategories.deck.take(20)) {
        expect(game.tier, GameTier.deck);
        expect(game.profile, isNotNull);
      }
      final merged = gameProfiles.entries
          .firstWhere((e) => e.value.reason == ArchiveReason.twin);
      final twin = GameFeed.find(merged.key)!;
      expect(twin.tier, GameTier.archive);
      expect(twin.family, merged.value.family);
      expect(twin.archiveReason, ArchiveReason.twin);
    });

    test('a game with no verdict is not shown', () {
      // The extension's default is the safe one: an id the catalog has never ruled on is
      // archived, so a half-added game cannot reach a player.
      expect(gameProfiles.containsKey('not_a_game'), isFalse);
      expect(profileOf('not_a_game'), isNull);
    });
  });

  group('the app shows the visible games and only those', () {
    test('rooms, counts and search skip the archive', () {
      final visible = GameCategories.visible.map((g) => g.id).toSet();
      expect(visible, visibleIds);
      for (final category in GameCategories.all) {
        final room = GameCategories.inCategory(category.id);
        expect(room.where((g) => !visibleIds.contains(g.id)), isEmpty);
        expect(GameCategories.countIn(category.id), room.length);
      }
    });

    test('the deal is the deck', () {
      expect(GameCategories.deck.map((g) => g.id).toSet(), deckIds);
      expect(GameFeed.feedPool().map((g) => g.id).toSet(), deckIds);
    });

    test('a game a player hid leaves the deal but the deal survives', () {
      final hidden = deckIds.toSet();
      expect(GameFeed.feedPool(exclude: hidden), isNotEmpty);
      expect(GameFeed.randomGame(exclude: hidden), isNotNull);
      final one = deckIds.first;
      expect(GameFeed.feedPool(exclude: {one}).map((g) => g.id), isNot(contains(one)));
    });

    test('today\'s pick is a deck game', () {
      expect(deckIds, contains(GameFeed.dailyPick().id));
    });

    test('quick play skips the archive', () {
      expect(GameFeed.quickPlay.where((g) => !visibleIds.contains(g.id)), isEmpty);
    });
  });
}

/// The tier of each id, read from the room blocks. A merge block names the absorbed game,
/// which is archived, so it counts as `archive`.
Map<String, String> _parseTiers(String text) {
  final tiers = <String, String>{};
  String? room;
  String? block;
  for (final line in text.split('\n')) {
    if (RegExp(r'^## (Logic|Math|Memory|Attention|Word|Spatial) \(\d+\)')
        .hasMatch(line)) {
      room = line;
      block = null;
      continue;
    }
    if (room == null) continue;
    final fence = RegExp(r'^```(deck|library|merge|archive)$').firstMatch(line.trim());
    if (fence != null) {
      block = fence.group(1);
      continue;
    }
    if (line.trim() == '```') {
      block = null;
      continue;
    }
    if (block == null || line.trim().isEmpty || line.trim().startsWith('#')) continue;
    final current = block;
    for (final id in _idsIn(line, current)) {
      tiers[id] = current == 'merge' ? 'archive' : current;
    }
  }
  return tiers;
}

Map<String, String> _parseFamilies(String text) {
  final families = <String, String>{};
  String? room;
  String? block;
  for (final line in text.split('\n')) {
    if (RegExp(r'^## (Logic|Math|Memory|Attention|Word|Spatial) \(\d+\)')
        .hasMatch(line)) {
      room = line;
      block = null;
      continue;
    }
    if (room == null) continue;
    final fence = RegExp(r'^```(deck|library|merge|archive)$').firstMatch(line.trim());
    if (fence != null) {
      block = fence.group(1);
      continue;
    }
    if (line.trim() == '```') {
      block = null;
      continue;
    }
    if (block != 'merge' || line.trim().isEmpty) continue;
    final parts = line.split('<-');
    final keeper = parts.first.trim();
    for (final id in parts.last.trim().split(RegExp(r'\s+'))) {
      if (id.isNotEmpty) families[id] = keeper;
    }
  }
  return families;
}

Iterable<String> _idsIn(String line, String block) {
  if (block == 'merge') {
    return line.split('<-').last.trim().split(RegExp(r'\s+')).where((id) => id.isNotEmpty);
  }
  return line
      .trim()
      .split(RegExp(r'\s+'))
      .where((id) => RegExp(r'^[a-z0-9_]+$').hasMatch(id));
}
