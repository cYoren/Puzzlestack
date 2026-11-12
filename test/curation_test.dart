import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/curation.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_registry.dart';

/// The curation list is hand-written, so the tests here are about typos and
/// about the reel staying alive when the list grows, not about taste.
void main() {
  final registryIds = allGamesMetadata.map((g) => g.id).toSet();

  test('every blocked id exists in the registry', () {
    final unknown = feedBlocklist.where((id) => !registryIds.contains(id));
    expect(
      unknown,
      isEmpty,
      reason: 'these ids are not games in the registry: ${unknown.join(', ')}',
    );
  });

  test('the reel pool never contains a blocked puzzle', () {
    final pool = GameFeed.feedPool();
    expect(pool.where((g) => feedBlocklist.contains(g.id)), isEmpty);
  });

  test('the reel pool still yields games when the player hides everything', () {
    // A blocklist that covers the whole registry, or a player who hid all 313,
    // must not hand the feed an empty stream.
    final all = registryIds;
    expect(GameFeed.feedPool(exclude: all), isNotEmpty);
    expect(GameFeed.randomGame(exclude: all), isNotNull);
  });

  test('today\'s pick is drawn from the reel pool', () {
    final pool = GameFeed.feedPool().map((g) => g.id).toSet();
    expect(pool.contains(GameFeed.dailyPick().id), isTrue);
  });

  test('quick play respects the blocklist', () {
    expect(
        GameFeed.quickPlay.where((g) => feedBlocklist.contains(g.id)), isEmpty);
  });
}
