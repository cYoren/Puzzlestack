import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/data/game_registry.dart';

/// "Puzzle of the day" has to be the same puzzle for everyone, and it has to
/// feel like a daily rather than a month of one category. It was neither: the
/// draw indexed registry order, which is grouped by category (23 MATH days in a
/// row), and it was filtered by each player's hidden games.
void main() {
  test('the pick for a date does not depend on who asks', () {
    final date = DateTime(2026, 11, 20);
    final everyone = GameFeed.dailyPick(now: date).id;
    // Two players, one of whom has hidden half the catalogue.
    final playerA = {for (final g in allGamesMetadata.take(150)) g.id};
    final playerB = <String>{};
    expect(GameFeed.dailyPick(now: date).id, everyone);
    expect(
      GameFeed.dailyPickIsHidden(now: date, exclude: playerA),
      playerA.contains(everyone),
    );
    expect(
      GameFeed.dailyPickIsHidden(now: date, exclude: playerB),
      isFalse,
    );
  });

  test('no category runs for more than three days', () {
    final categories = <String>[];
    for (var day = 0; day < 120; day++) {
      final date = DateTime(2026, 11, 1).add(Duration(days: day));
      categories.add(GameFeed.dailyPick(now: date).category);
    }
    var run = 1;
    var worst = 1;
    var worstCategory = categories.first;
    for (var i = 1; i < categories.length; i++) {
      run = categories[i] == categories[i - 1] ? run + 1 : 1;
      if (run > worst) {
        worst = run;
        worstCategory = categories[i];
      }
    }
    expect(worst, lessThanOrEqualTo(3),
        reason: '$worstCategory appears $worst days in a row');
  });

  test('every game is reachable as a daily pick', () {
    final pool = allGamesMetadata.length;
    final seen = <String>{};
    // Two catalogue-lengths of days, because the draw is a fixed stride through
    // a fixed order: every id comes up exactly once per lap.
    for (var day = 0; day < pool * 2; day++) {
      seen.add(GameFeed.dailyPick(
              now: DateTime(2027, 3, 1).add(Duration(days: day)))
          .id);
    }
    expect(seen.length, pool,
        reason: 'never offered as a daily: ${pool - seen.length} games');
  });

  test('the pick changes with the date and repeats by the day', () {
    final a = GameFeed.dailyPick(now: DateTime(2026, 11, 10));
    final b = GameFeed.dailyPick(now: DateTime(2026, 11, 11));
    final again = GameFeed.dailyPick(now: DateTime(2026, 11, 10));
    expect(again.id, a.id);
    expect(b.id, isNot(a.id));
  });

  test('the order is stable across calls', () {
    final first = [
      for (var day = 0; day < 10; day++)
        GameFeed.dailyPick(now: DateTime(2027, 1, 1 + day)).id,
    ];
    final second = [
      for (var day = 0; day < 10; day++)
        GameFeed.dailyPick(now: DateTime(2027, 1, 1 + day)).id,
    ];
    expect(second, first);
  });

  test('the pick is a registry game', () {
    final game = GameFeed.dailyPick(now: DateTime(2026, 12, 25));
    expect(game, isA<GameMetadata>());
    expect(allGamesMetadata.any((g) => g.id == game.id), isTrue);
  });
}
