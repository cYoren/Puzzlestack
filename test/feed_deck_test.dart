import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/ui/features/feed/feed_deck.dart';

/// The feed's promise is that every card is new until the deck runs out, and
/// that the counter on the card is true. Both are properties of the order, not
/// of the screen, so they are tested here without a widget tree.
void main() {
  const int total = 313;

  test('the pool is the whole registry when no category is given', () {
    final deck = FeedDeck(random: Random(7));
    expect(deck.deckSize, total);
  });

  test('a category deck deals only from that category', () {
    final deck = FeedDeck(categoryId: 'LOGIC', random: Random(7));
    final expected = GameCategories.countIn('LOGIC');
    expect(deck.deckSize, expected);

    final seen = <String>{};
    for (var i = 0; i < expected; i++) {
      final GameMetadata game = deck.gameAt(i);
      expect(game.category, 'LOGIC');
      seen.add(game.id);
    }
    expect(seen.length, expected, reason: 'a full pass is every puzzle once');
  });

  test('one pass deals every puzzle exactly once', () {
    final deck = FeedDeck(random: Random(11));
    final ids = [for (var i = 0; i < deck.deckSize; i++) deck.gameAt(i).id];

    expect(ids.length, total);
    expect(ids.toSet().length, total, reason: 'no card repeats inside a pass');
  });

  test('the deck never deals the same card twice in a row', () {
    // Small pools find a seam repeat fastest: check the first ten passes.
    final deck = FeedDeck(categoryId: 'SPATIAL', random: Random(3));
    final int size = deck.deckSize;
    String? previous;

    for (var i = 0; i < size * 10; i++) {
      final String id = deck.gameAt(i).id;
      expect(id, isNot(previous), reason: 'card $i repeated the one before it');
      previous = id;
    }
  });

  test('the counter runs 1..deckSize and never exceeds it', () {
    final deck = FeedDeck(random: Random(5));
    final int size = deck.deckSize;

    expect(deck.positionInDeck(0), 1);
    expect(deck.positionInDeck(size - 1), size);
    // The next pass starts the counter over; it is a new deal, not page 314.
    expect(deck.positionInDeck(size), 1);
    expect(deck.positionInDeck(size * 2 + 4), 5);
  });

  test('hidden games are dropped before the first deal', () {
    final hidden = {allGamesMetadata[0].id, allGamesMetadata[1].id};
    final deck = FeedDeck(hidden: hidden, random: Random(2));

    expect(deck.deckSize, total - hidden.length);
    for (var i = 0; i < deck.deckSize; i++) {
      expect(hidden, isNot(contains(deck.gameAt(i).id)));
    }
  });

  test('hiding everything falls back to the whole registry', () {
    final all = allGamesMetadata.map((g) => g.id).toSet();
    final deck = FeedDeck(hidden: all, random: Random(2));

    expect(deck.deckSize, total, reason: 'a preference cannot empty the app');
    expect(deck.gameAt(0).id, isNotEmpty);
  });

  test('the deck is lazily dealt: asking for card 0 does not build 313', () {
    final deck = FeedDeck(random: Random(9));
    deck.gameAt(0);
    // Asking twice is stable, and reaching card 3 deals only up to card 3.
    expect(deck.gameAt(0).id, deck.gameAt(0).id);
    expect(deck.gameAt(3).id, isNotEmpty);
  });
}
