import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'clusters_engine.dart';

part 'clusters_provider.g.dart';

/// One tap on [colour] produces the next one: unmarked, red, blue, unmarked.
///
/// It lives here, not in the notifier, so the three-state cycle can be tested
/// without pumping a screen. Three states, three values; the unmarked cell is
/// not "blue by default".
int nextColour(int colour) => switch (colour) {
      kClusterRed => kClusterBlue,
      kClusterBlue => kClusterUnmarked,
      _ => kClusterRed,
    };

@immutable
class ClustersState extends PuzzleState {
  const ClustersState({
    required this.puzzle,
    required this.values,
    required this.size,
    this.isSolved = false,
    this.hintCell,
  });

  final ClustersPuzzle puzzle;

  /// Per cell, [kClusterUnmarked] or a colour.
  final List<int> values;

  final ClustersSize size;
  final bool isSolved;
  final int? hintCell;

  int get n => puzzle.n;

  int get coloured => values.where((value) => value != kClusterUnmarked).length;

  Set<int> get conflicts => puzzle.conflicts(values);

  ClustersState copyWith({
    List<int>? values,
    bool? isSolved,
    int? hintCell,
    bool clearHint = false,
  }) {
    return ClustersState(
      puzzle: puzzle,
      values: values ?? this.values,
      size: size,
      isSolved: isSolved ?? this.isSolved,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
    );
  }
}

@riverpod
class ClustersNotifier extends _$ClustersNotifier {
  final ClustersEngine _engine = const ClustersEngine();

  @override
  ClustersState build() => _newPuzzle(ClustersSize.small);

  /// A dotted cell is a cell the player can already read, so its colour is
  /// seeded into the values. A clue kept only in the puzzle renders, but the
  /// win test would still call that cell unmarked, and no board could ever be
  /// finished.
  ClustersState _newPuzzle(ClustersSize size) {
    final puzzle = _engine.generate(size);
    return ClustersState(
      puzzle: puzzle,
      values: [
        for (var cell = 0; cell < size.cellCount; cell++)
          puzzle.clue(cell) == kClusterNoClue
              ? kClusterUnmarked
              : puzzle.clue(cell),
      ],
      size: size,
    );
  }

  void newGame() => state = _newPuzzle(state.size);

  void setSize(ClustersSize size) {
    if (size == state.size) return;
    state = _newPuzzle(size);
  }

  /// A tap cycles the cell. A dotted cell is fixed by its dot.
  void cycle(int cell) {
    if (state.isSolved) return;
    if (state.puzzle.clue(cell) != kClusterNoClue) return;
    final values = [...state.values];
    values[cell] = nextColour(values[cell]);
    final next = state.copyWith(values: values, clearHint: true);
    state = next.copyWith(isSolved: _engine.isSolved(next.puzzle, values));
  }

  /// Applies one colour the rules prove.
  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.values);
    if (found == null) return;
    final values = [...state.values];
    values[found.cell] = found.colour;
    final next = state.copyWith(values: values, hintCell: found.cell);
    state = next.copyWith(isSolved: _engine.isSolved(next.puzzle, values));
  }

  int? get level => _engine.levelOf(state.puzzle);

  /// Fills in the answer.
  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      values: List<int>.from(state.puzzle.solution),
      clearHint: true,
      isSolved: true,
    );
  }
}
