import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'map_engine.dart';

part 'map_provider.g.dart';

@immutable
class MapState extends PuzzleState {
  const MapState({
    required this.puzzle,
    required this.colours,
    required this.difficulty,
    this.hintRegion,
    this.hintColour,
  });

  final MapPuzzle puzzle;

  /// One colour 0..3 per region, -1 for a region the player has not coloured.
  final List<int> colours;

  final MapDifficulty difficulty;
  final int? hintRegion;
  final int? hintColour;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  int get coloured => colours.where((c) => c >= 0).length;

  MapState copyWith({
    List<int>? colours,
    int? hintRegion,
    int? hintColour,
    bool clearHint = false,
  }) =>
      MapState(
        puzzle: puzzle,
        colours: colours ?? this.colours,
        difficulty: difficulty,
        hintRegion: clearHint ? null : (hintRegion ?? this.hintRegion),
        hintColour: clearHint ? null : (hintColour ?? this.hintColour),
      );
}

@riverpod
class MapNotifier extends _$MapNotifier {
  final MapEngine _engine = const MapEngine();

  @override
  MapState build() => _newPuzzle(MapDifficulty.medium);

  MapState _newPuzzle(MapDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty);
    return MapState(
      puzzle: puzzle,
      colours: List<int>.filled(puzzle.regionCount, -1),
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(MapDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  /// Paint a region the current colour. Tapping a region cycles its colour, so
  /// no palette is needed and a tap-only player can finish a board.
  void cycle(int region) {
    final colours = [...state.colours];
    colours[region] = colours[region] >= mapColourCount - 1
        ? -1
        : colours[region] + 1;
    state = state.copyWith(colours: colours, clearHint: true);
  }

  /// Fill every region the rules can prove, in one go, as a hint.
  void hint() {
    if (isSolved) return;
    final found = _engine.hint(state.puzzle, state.colours);
    if (found == null) return;
    state = state.copyWith(hintRegion: found.region, hintColour: found.colour);
  }

  bool get isSolved => _engine.isSolved(state.puzzle, state.colours);

  /// Paints the stored four-colouring.
  void solve() {
    state = state.copyWith(
      colours: List<int>.from(state.puzzle.solution),
      clearHint: true,
    );
  }
}
