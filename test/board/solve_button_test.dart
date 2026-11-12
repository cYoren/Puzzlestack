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
import 'package:puzzle/ui/features/games/water_sort/water_sort_provider.dart';

/// The solve button is a promise: it fills in a board that the game then calls
/// solved. If a `solve()` drifts out of step with its own win check, this test
/// says so before a player does.
void main() {
  test('signpost solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(signpostNotifierProvider.notifier).solve();
    expect(container.read(signpostNotifierProvider).isSolved, isTrue);
  });

  test('futoshiki solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(futoshikiNotifierProvider.notifier).solve();
    expect(container.read(futoshikiNotifierProvider).isSolved, isTrue);
  });

  test('skyscrapers solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(skyscrapersNotifierProvider.notifier).solve();
    expect(container.read(skyscrapersNotifierProvider).isSolved, isTrue);
  });

  test('kurodoko solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(kurodokoNotifierProvider.notifier).solve();
    expect(container.read(kurodokoNotifierProvider).isSolved, isTrue);
  });

  test('slitherlink solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(slitherlinkNotifierProvider.notifier).solve();
    expect(container.read(slitherlinkNotifierProvider).isSolved, isTrue);
  });

  test('dominosa solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(dominosaNotifierProvider.notifier).solve();
    expect(container.read(dominosaNotifierProvider).isSolved, isTrue);
  });

  test('galaxies solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(galaxiesNotifierProvider.notifier).solve();
    expect(container.read(galaxiesNotifierProvider).isSolved, isTrue);
  });

  test('magnets solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(magnetsNotifierProvider.notifier).solve();
    expect(container.read(magnetsNotifierProvider).isSolved, isTrue);
  });

  test('tents solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tentsAndTreesNotifierProvider.notifier).solve();
    expect(container.read(tentsAndTreesNotifierProvider).isSolved, isTrue);
  });

  test('lights out solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(lightsOutNotifierProvider.notifier).solve();
    expect(container.read(lightsOutNotifierProvider).isSolved, isTrue);
  });

  test('netslide solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(netslideNotifierProvider.notifier).solve();
    expect(container.read(netslideNotifierProvider).isSolved, isTrue);
  });

  test('pegs solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(pegsNotifierProvider.notifier).solve();
    expect(container.read(pegsNotifierProvider).isSolved, isTrue);
  });

  test('twiddle solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(twiddleNotifierProvider.notifier).solve();
    expect(container.read(twiddleNotifierProvider).isSolved, isTrue);
  });

  test('water sort solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(waterSortNotifierProvider.notifier).solve();
    expect(container.read(waterSortNotifierProvider).isSolved, isTrue);
  });

  test('cube solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(cubeNotifierProvider.notifier).solve();
    expect(container.read(cubeNotifierProvider).isSolved, isTrue);
  });

  test('inertia solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(inertiaNotifierProvider.notifier).solve();
    expect(container.read(inertiaNotifierProvider).isSolved, isTrue);
  });

  test('map solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(mapNotifierProvider.notifier);
    notifier.solve();
    expect(notifier.isSolved, isTrue);
  });

  test('sudoku solve finishes the board', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(sudokuNotifierProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(sudokuNotifierProvider.future);
    container.read(sudokuNotifierProvider.notifier).solve();
    expect(container.read(sudokuNotifierProvider).value!.isSolved, isTrue);
  });

  test('same game solve finishes the board', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(sameGameNotifierProvider.notifier).solve();
    expect(container.read(sameGameNotifierProvider).isSolved, isTrue);
  });
}
