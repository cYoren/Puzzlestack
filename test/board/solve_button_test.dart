import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/cube/cube_provider.dart';
import 'package:puzzle/ui/features/games/dominosa/dominosa_provider.dart';
import 'package:puzzle/ui/features/games/futoshiki/futoshiki_provider.dart';
import 'package:puzzle/ui/features/games/galaxies/galaxies_provider.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_provider.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_provider.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_provider.dart';
import 'package:puzzle/ui/features/games/magnets/magnets_provider.dart';
import 'package:puzzle/ui/features/games/map/map_provider.dart';
import 'package:puzzle/ui/features/games/netslide/netslide_provider.dart';
import 'package:puzzle/ui/features/games/pegs/pegs_provider.dart';
import 'package:puzzle/ui/features/games/same_game/same_game_provider.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_provider.dart';
import 'package:puzzle/ui/features/games/skyscrapers/skyscrapers_provider.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_provider.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_provider.dart';
import 'package:puzzle/ui/features/games/tents_and_trees/tents_and_trees_provider.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_provider.dart';
import 'package:puzzle/ui/features/games/ascent/ascent_provider.dart';
import 'package:puzzle/ui/features/games/clusters/clusters_provider.dart';
import 'package:puzzle/ui/features/games/seismic/seismic_provider.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_provider.dart';

/// The solve button is a promise: it fills in a board that the game then calls
/// solved. If a `solve()` drifts out of step with its own win check, this test
/// says so before a player does.
void main() {
  test('seismic solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(seismicProvider.notifier).solve();
    expect(container.read(seismicProvider).isSolved, isTrue);
  });

  test('ascent solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(ascentProvider.notifier).solve();
    expect(container.read(ascentProvider).isSolved, isTrue);
  });

  test('clusters solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(clustersProvider.notifier).solve();
    expect(container.read(clustersProvider).isSolved, isTrue);
  });

  test('signpost solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(signpostProvider.notifier).solve();
    expect(container.read(signpostProvider).isSolved, isTrue);
  });

  test('futoshiki solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(futoshikiProvider.notifier).solve();
    expect(container.read(futoshikiProvider).isSolved, isTrue);
  });

  test('skyscrapers solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(skyscrapersProvider.notifier).solve();
    expect(container.read(skyscrapersProvider).isSolved, isTrue);
  });

  test('kurodoko solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(kurodokoProvider.notifier).solve();
    expect(container.read(kurodokoProvider).isSolved, isTrue);
  });

  test('slitherlink solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(slitherlinkProvider.notifier).solve();
    expect(container.read(slitherlinkProvider).isSolved, isTrue);
  });

  test('dominosa solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(dominosaProvider.notifier).solve();
    expect(container.read(dominosaProvider).isSolved, isTrue);
  });

  test('galaxies solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(galaxiesProvider.notifier).solve();
    expect(container.read(galaxiesProvider).isSolved, isTrue);
  });

  test('magnets solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(magnetsProvider.notifier).solve();
    expect(container.read(magnetsProvider).isSolved, isTrue);
  });

  test('tents solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tentsAndTreesProvider.notifier).solve();
    expect(container.read(tentsAndTreesProvider).isSolved, isTrue);
  });

  test('lights out solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(lightsOutProvider.notifier).solve();
    expect(container.read(lightsOutProvider).isSolved, isTrue);
  });

  test('netslide solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(netslideProvider.notifier).solve();
    expect(container.read(netslideProvider).isSolved, isTrue);
  });

  test('pegs solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(pegsProvider.notifier).solve();
    expect(container.read(pegsProvider).isSolved, isTrue);
  });

  test('twiddle solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(twiddleProvider.notifier).solve();
    expect(container.read(twiddleProvider).isSolved, isTrue);
  });

  test('water sort solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(waterSortProvider.notifier).solve();
    expect(container.read(waterSortProvider).isSolved, isTrue);
  });

  test('cube solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(cubeProvider.notifier).solve();
    expect(container.read(cubeProvider).isSolved, isTrue);
  });

  test('inertia solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(inertiaProvider.notifier).solve();
    expect(container.read(inertiaProvider).isSolved, isTrue);
  });

  test('map solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(mapProvider.notifier);
    notifier.solve();
    expect(notifier.isSolved, isTrue);
  });

  test('sudoku solve finishes the board', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(sudokuProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(sudokuProvider.future);
    container.read(sudokuProvider.notifier).solve();
    expect(container.read(sudokuProvider).value!.isSolved, isTrue);
  });

  test('same game solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(sameGameProvider.notifier).solve();
    expect(container.read(sameGameProvider).isSolved, isTrue);
  });
}
