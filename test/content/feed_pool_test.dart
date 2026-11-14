import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/data/game_registry.dart';

/// The deal's pool, and the two lists it is made of. The tier verdicts themselves are
/// `docs/CATALOG.md`'s business and are held by `test/content/game_profiles_test.dart`;
/// this file is about the pool never breaking: never handing the feed a game it may not
/// deal, and never handing it an empty stream.
void main() {
  final Set<String> registryIds = allGamesMetadata.map((g) => g.id).toSet();

  test('the pool is drawn from the deal, not from the registry', () {
    final pool = GameFeed.feedPool();
    expect(pool.length, lessThan(registryIds.length),
        reason: 'the deal should be smaller than the registry after the first pass');
    expect(pool.where((g) => !deckIds.contains(g.id)), isEmpty);
  });

  test('the reel never serves an archived game', () {
    final archived = registryIds.difference(visibleIds);
    expect(archived, isNotEmpty, reason: 'the first pass archived 89 games');
    expect(GameFeed.feedPool().where((g) => archived.contains(g.id)), isEmpty);
    expect(GameFeed.quickPlay.where((g) => archived.contains(g.id)), isEmpty);
    expect(archived.contains(GameFeed.dailyPick().id), isFalse);
  });

  test('the reel pool still yields games when the player hides everything', () {
    // A player who hid every game, including one whose deal is every id, must not be
    // handed an empty stream.
    expect(GameFeed.feedPool(exclude: registryIds), isNotEmpty);
    expect(GameFeed.randomGame(exclude: registryIds), isNotNull);
  });

  test('a shuffled order is the whole deal, once each', () {
    final order = GameFeed.shuffledOrder();
    expect(order.length, deckIds.length);
    expect(order.map((g) => g.id).toSet(), deckIds);
  });
}
