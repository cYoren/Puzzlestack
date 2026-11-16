import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/data/game_registry.dart';

/// The archive is material, not a shelf.
///
/// `docs/CATALOG.md` files 89 games as lab tasks, worksheets or absorbed twins.
/// They keep compiling, and every surface that offers a puzzle has to pretend
/// they are not there — including the "next game" after a solve, which used to
/// read the whole registry and hand a player `sternberg_task` after a win.
void main() {
  final Set<String> archived = archivedIds;
  final Set<String> visible = visibleIds;

  List<GameMetadata> browse({
    String query = '',
    String category = 'ALL',
    Set<String> hidden = const {},
    Set<String> favorites = const {},
    bool includeArchived = false,
  }) =>
      GameFeed.browse(
        searchQuery: query,
        selectedCategory: category,
        localizedTitles: const {},
        hiddenIds: hidden,
        favoriteIds: favorites,
        includeArchived: includeArchived,
      );

  test('the catalog archives something, and everything else is playable', () {
    expect(archived, isNotEmpty);
    expect(archived.intersection(visible), isEmpty);
    expect(archived.union(visible).length, allGamesMetadata.length);
  });

  test('the browse list skips the archive by default', () {
    final List<GameMetadata> list = browse();
    expect(list.length, visible.length);
    expect(list.where((g) => archived.contains(g.id)), isEmpty);
  });

  test('the browse list shows the archive only when asked', () {
    final List<GameMetadata> list = browse(includeArchived: true);
    expect(list.length, allGamesMetadata.length);
    expect(list.where((g) => archived.contains(g.id)), isNotEmpty);
  });

  test('hidden games stay out of the list even with the archive on', () {
    final String hiddenId = visible.first;
    final List<GameMetadata> list =
        browse(includeArchived: true, hidden: {hiddenId});
    expect(list.any((g) => g.id == hiddenId), isFalse);
  });

  test('a room counts what it shows', () {
    for (final CategoryInfo room in GameCategories.all) {
      final int playable = GameCategories.countIn(room.id);
      expect(GameCategories.inCategory(room.id).length, playable);
      final int withArchive =
          GameCategories.countIn(room.id, includeArchived: true);
      expect(withArchive, greaterThanOrEqualTo(playable));
      expect(GameCategories.inCategory(room.id, includeArchived: true).length,
          withArchive);
    }
  });

  test('favourites lead the list, archived games sort to the end', () {
    final String favourite = allGamesMetadata.last.id;
    final List<GameMetadata> list =
        browse(includeArchived: true, favorites: {favourite});
    expect(list.first.id, favourite);

    final int firstArchived = list.indexWhere((g) => archived.contains(g.id));
    final int lastPlayable = list.lastIndexWhere((g) => visible.contains(g.id));
    expect(firstArchived, greaterThan(lastPlayable),
        reason: 'a reference game must not sit above a real one');
  });

  test('search still finds an archived game when the switch is on', () {
    final String id = archived.first;
    final List<GameMetadata> off = browse(query: id);
    final List<GameMetadata> on = browse(query: id, includeArchived: true);
    expect(off.any((g) => g.id == id), isFalse);
    expect(on.any((g) => g.id == id), isTrue);
  });
}
