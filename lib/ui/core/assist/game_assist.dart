import 'package:flutter_riverpod/flutter_riverpod.dart';

export '../../../utils/game_assist_state.dart';

import '../../features/games/akari/akari_provider.dart';
import '../../features/games/cube/cube_provider.dart';
import '../../features/games/dominosa/dominosa_provider.dart';
import '../../features/games/futoshiki/futoshiki_provider.dart';
import '../../features/games/galaxies/galaxies_provider.dart';
import '../../features/games/inertia/inertia_provider.dart';
import '../../features/games/kurodoko/kurodoko_provider.dart';
import '../../features/games/lights_out/lights_out_provider.dart';
import '../../features/games/magnets/magnets_provider.dart';
import '../../features/games/map/map_provider.dart';
import '../../features/games/netslide/netslide_provider.dart';
import '../../features/games/pegs/pegs_provider.dart';
import '../../features/games/same_game/same_game_provider.dart';
import '../../features/games/signpost/signpost_provider.dart';
import '../../features/games/skyscrapers/skyscrapers_provider.dart';
import '../../features/games/slitherlink/slitherlink_provider.dart';
import '../../features/games/sudoku/sudoku_provider.dart';
import '../../features/games/tents_and_trees/tents_and_trees_provider.dart';
import '../../features/games/twiddle/twiddle_provider.dart';
import '../../features/games/water_sort/water_sort_provider.dart';

/// What the shell can offer for one game.
///
/// Hint is a provable next step; solve is the answer. Both are optional, and a
/// game with neither simply has no buttons — that is the honest state for a
/// timed reaction test, where "the answer" is not a thing.
class GameAssistActions {
  const GameAssistActions({this.onHint, this.onSolve});

  final void Function()? onHint;
  final void Function()? onSolve;

  bool get isEmpty => onHint == null && onSolve == null;
}

/// One place that knows how to ask each puzzle for help.
///
/// The alternative is a hint and solve button written into 313 screens. This
/// keeps the affordance identical everywhere and makes the list of games that
/// support it readable in one file.
GameAssistActions? gameAssistFor(String gameId, WidgetRef ref) {
  switch (gameId) {
    case 'signpost':
      final notifier = ref.read(signpostProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'kurodoko':
      final notifier = ref.read(kurodokoProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'slitherlink':
      final notifier = ref.read(slitherlinkProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'futoshiki':
      final notifier = ref.read(futoshikiProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'skyscrapers':
      final notifier = ref.read(skyscrapersProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'dominosa':
      final notifier = ref.read(dominosaProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'galaxies':
      final notifier = ref.read(galaxiesProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'tents_and_trees':
      final notifier = ref.read(tentsAndTreesProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'magnets':
      final notifier = ref.read(magnetsProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'lights_out':
      final notifier = ref.read(lightsOutProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'sudoku':
      final notifier = ref.read(sudokuProvider.notifier);
      return GameAssistActions(onSolve: notifier.solve);
    case 'map':
      final notifier = ref.read(mapProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'inertia':
      final notifier = ref.read(inertiaProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'netslide':
      final notifier = ref.read(netslideProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'pegs':
      final notifier = ref.read(pegsProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'same_game':
      final notifier = ref.read(sameGameProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'twiddle':
      final notifier = ref.read(twiddleProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'cube':
      final notifier = ref.read(cubeProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'akari':
      final notifier = ref.read(akariProvider.notifier);
      return GameAssistActions(onHint: notifier.hint, onSolve: notifier.solve);
    case 'water_sort':
      final notifier = ref.read(waterSortProvider.notifier);
      return GameAssistActions(onSolve: notifier.solve);
    default:
      return null;
  }
}
