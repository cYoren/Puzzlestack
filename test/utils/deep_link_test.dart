import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/utils/deep_link.dart';

/// Every page of the website names one puzzle, and the day the web build is
/// hosted that page's Play button carries `?game=<slug>`. Getting this wrong is
/// invisible on a phone and a dead end in a browser, so it is tested against the
/// registry rather than against a sample.
void main() {
  final Iterable<String> ids = allGamesMetadata.map((game) => game.id);

  test('a plain launch opens the deal', () {
    expect(gameIdFromUri(Uri.parse('https://example.test/')), isNull);
    expect(gameIdFromUri(Uri.parse('https://example.test/?game=')), isNull);
    expect(gameIdFromUri(Uri.parse('https://example.test/#rooms')), isNull);
  });

  test('an id resolves to itself', () {
    expect(
        gameIdFromUri(Uri.parse('?game=nonogram'), knownIds: ids), 'nonogram');
    expect(gameIdFromUri(Uri.parse('?game=tents_and_trees'), knownIds: ids),
        'tents_and_trees');
  });

  test('a page slug resolves back to its id', () {
    expect(gameIdFromUri(Uri.parse('?game=tents-and-trees'), knownIds: ids),
        'tents_and_trees');
    expect(gameIdFromUri(Uri.parse('?game=lights-out'), knownIds: ids),
        'lights_out');
    expect(gameIdFromUri(Uri.parse('?game=2048'), knownIds: ids), 'game_2048');
  });

  test('every id has a slug that resolves back to it', () {
    for (final String id in ids) {
      expect(
          gameIdFromUri(Uri.parse('?game=${slugFor(id)}'), knownIds: ids), id,
          reason: 'the site links to ${slugFor(id)}');
    }
  });

  test('slugs are unique, so no page opens the wrong game', () {
    final Set<String> slugs = ids.map(slugFor).toSet();
    expect(slugs.length, ids.length);
  });

  test('an unknown or hostile value is ignored, not obeyed', () {
    expect(gameIdFromUri(Uri.parse('?game=not_a_game'), knownIds: ids), isNull);
    expect(gameIdFromUri(Uri.parse('?game=<script>'), knownIds: ids), isNull);
    expect(gameIdFromUri(Uri.parse('?other=nonogram'), knownIds: ids), isNull);
  });

  test('the case of the URL does not matter', () {
    expect(
        gameIdFromUri(Uri.parse('?game=NONOGRAM'), knownIds: ids), 'nonogram');
  });
}
