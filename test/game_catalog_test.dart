import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_catalog.dart';

void main() {
  group('GameCatalog integrity', () {
    test('has the full registry with unique ids', () {
      expect(GameCatalog.all.length, greaterThanOrEqualTo(150));
      final ids = GameCatalog.all.map((g) => g.id).toSet();
      expect(ids.length, GameCatalog.all.length,
          reason: 'duplicate game ids in registry');
    });

    test('every game belongs to a known category', () {
      final known = GameCatalog.categories.map((c) => c.id).toSet();
      for (final game in GameCatalog.all) {
        expect(known, contains(game.category),
            reason: '${game.id} has unknown category ${game.category}');
      }
    });

    test('every category has at least one game', () {
      for (final category in GameCatalog.categories) {
        expect(GameCatalog.countInCategory(category.id), greaterThan(0));
      }
    });

    test('find returns the right game and null for unknown ids', () {
      final first = GameCatalog.all.first;
      expect(GameCatalog.find(first.id)?.title, first.title);
      expect(GameCatalog.find('definitely_not_a_game'), isNull);
    });
  });

  group('quickPlay', () {
    test('resolves to real games only', () {
      expect(GameCatalog.quickPlay, isNotEmpty);
      for (final game in GameCatalog.quickPlay) {
        expect(GameCatalog.find(game.id), isNotNull);
      }
    });
  });

  group('dailyPick', () {
    test('is deterministic for a given date', () {
      final a = GameCatalog.dailyPick(DateTime(2026, 7, 10, 8));
      final b = GameCatalog.dailyPick(DateTime(2026, 7, 10, 23));
      expect(a.id, b.id);
    });

    test('changes across days (spot check over a month)', () {
      final picks = <String>{
        for (var day = 1; day <= 30; day++)
          GameCatalog.dailyPick(DateTime(2026, 7, day)).id,
      };
      expect(picks.length, greaterThan(1));
    });
  });

  group('randomGame / shuffledOrder', () {
    test('randomGame respects exceptId', () {
      final except = GameCatalog.all.first.id;
      final rng = Random(7);
      for (var i = 0; i < 50; i++) {
        expect(GameCatalog.randomGame(exceptId: except, random: rng).id,
            isNot(except));
      }
    });

    test('shuffledOrder is a permutation of the catalog', () {
      final order = GameCatalog.shuffledOrder(random: Random(1));
      expect(order.length, GameCatalog.all.length);
      expect(order.map((g) => g.id).toSet(),
          GameCatalog.all.map((g) => g.id).toSet());
    });
  });
}
