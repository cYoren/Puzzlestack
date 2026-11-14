import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_registry.dart';

/// "Quick play · under 2 min" is a promise about the catalogue. It used to be
/// kept for twelve games, which is 4% of 313, while 38 games end the run on a
/// single answer and fit the row perfectly.
void main() {
  final quick = GameFeed.quickPlay;
  final registryIds = allGamesMetadata.map((game) => game.id).toSet();

  /// Long sessions: a board you sit with. None of these belongs in a two-minute
  /// row, however short a lucky solve might be.
  const longForm = {
    'kakuro',
    'killer_sudoku',
    'sudoku',
    'norinori',
    'slitherlink',
    'heyawake',
    'tapa',
    'yajilin',
    'masyu',
    'shikaku',
    'nurikabe',
    'hitori',
    'fillomino',
    'nonogram',
    'minesweeper',
    'nurimaze',
    'akari',
    'kurodoko',
    'galaxies',
    'dominosa',
    'skyscrapers',
    'futoshiki',
    'tents_and_trees',
    'magnets',
    'pegs',
    'netslide',
    'inertia',
    'signpost',
    'map',
    'cube',
    'lights_out',
    'twiddle',
    'same_game',
  };

  test('every quick play id is a game', () {
    final unknown = quick.where((g) => !registryIds.contains(g.id)).toList();
    expect(unknown, isEmpty, reason: 'not in the registry: $unknown');
    expect(quick, isNotEmpty);
  });

  test('the list is big enough to mean "quick play"', () {
    expect(quick.length, greaterThanOrEqualTo(40),
        reason: '${quick.length} games promised under two minutes');
  });

  test('no long-session board is sold as a two-minute game', () {
    final wrong =
        quick.where((g) => longForm.contains(g.id)).map((g) => g.id).toList();
    expect(wrong, isEmpty, reason: 'long sessions in quick play: $wrong');
  });

  test('quick play is a subset of the catalogue, not a parallel list', () {
    expect(quick.length, lessThan(allGamesMetadata.length));
    expect(quick.map((g) => g.id).toSet(), hasLength(quick.length));
  });
}
