import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/l10n/app_localizations.dart';

/// The registry is the source of truth: if a game is not in here with a
/// category, it does not exist, no matter how good the screen is.
void main() {
  group('registry integrity', () {
    test('has the full set of games with unique ids', () {
      expect(allGamesMetadata.length, greaterThanOrEqualTo(300));
      final ids = allGamesMetadata.map((game) => game.id).toSet();
      expect(ids.length, allGamesMetadata.length,
          reason: 'duplicate game ids in the registry');
    });

    test('every game belongs to one of the six rooms', () {
      final known = GameCategories.all.map((c) => c.id).toSet();
      for (final game in allGamesMetadata) {
        expect(known, contains(game.category),
            reason: '${game.id} has unknown category ${game.category}');
      }
    });

    test('every room has games, and the rooms add up to the registry', () {
      var total = 0;
      for (final category in GameCategories.all) {
        final count = GameCategories.countIn(category.id);
        expect(count, greaterThan(0), reason: '${category.id} is empty');
        total += count;
      }
      expect(total, allGamesMetadata.length);
    });

    test('every game builds a screen', () {
      for (final game in allGamesMetadata) {
        expect(game.builder, isNotNull, reason: '${game.id} has no builder');
      }
    });
  });

  group('titles', () {
    testWidgets('every game has a title and a subtitle in English',
        (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      await tester.pumpAndSettle();

      final missing = <String>[];
      for (final game in allGamesMetadata) {
        if (game.titleGetter(context).trim().isEmpty) missing.add(game.id);
      }
      expect(missing, isEmpty, reason: 'games with no title: $missing');
    });
  });

  group('feeds', () {
    test('quick play only resolves to real games', () {
      expect(GameFeed.quickPlay, isNotEmpty);
      for (final game in GameFeed.quickPlay) {
        expect(GameFeed.find(game.id), isNotNull);
      }
    });

    test('the daily pick is deterministic for a date', () {
      final date = DateTime(2026, 11, 10);
      expect(
          GameFeed.dailyPick(now: date).id, GameFeed.dailyPick(now: date).id);
    });

    test('the daily pick changes across days', () {
      final ids = {
        for (var day = 1; day <= 28; day++)
          GameFeed.dailyPick(now: DateTime(2026, 11, day)).id,
      };
      expect(ids.length, greaterThan(1));
    });

    test('randomGame respects exceptId', () {
      final random = Random(7);
      final first = allGamesMetadata.first;
      for (var i = 0; i < 50; i++) {
        final game = GameFeed.randomGame(exceptId: first.id, random: random);
        expect(game.id, isNot(first.id));
      }
    });

    test('shuffledOrder is a permutation of the registry', () {
      final order = GameFeed.shuffledOrder(random: Random(3));
      expect(order, hasLength(allGamesMetadata.length));
      expect(order.map((g) => g.id).toSet(),
          allGamesMetadata.map((g) => g.id).toSet());
    });

    test('inCategory returns only that category', () {
      for (final category in GameCategories.all) {
        final games = GameCategories.inCategory(category.id);
        expect(games, isNotEmpty);
        for (final game in games) {
          expect(game.category, category.id);
        }
      }
    });
  });
}
