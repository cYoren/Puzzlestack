import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'magnets_engine.dart';

part 'magnets_provider.g.dart';

@immutable
class MagnetsState extends PuzzleState {
  const MagnetsState({
    required this.puzzle,
    required this.states,
    required this.difficulty,
    this.isSolved = false,
    this.hintCell,
    this.hintValue,
  });

  final MagnetsPuzzle puzzle;

  /// One entry per domino: 0 blank, 1 `a` is `+`, 2 `a` is `-`.
  final List<int> states;

  final MagnetsDifficulty difficulty;
  final bool isSolved;

  /// A cell the hint has proved, and the pole it must take.
  final int? hintCell;
  final int? hintValue;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  /// The pole at a cell, as a mask value.
  int poleAt(int cell) => const MagnetsEngine().poleAt(puzzle, states, cell);

  int magnetsPlaced() => states.where((s) => s != 0).length;

  MagnetsState copyWith({
    List<int>? states,
    bool? isSolved,
    int? hintCell,
    int? hintValue,
    bool clearHint = false,
  }) {
    return MagnetsState(
      puzzle: puzzle,
      states: states ?? this.states,
      difficulty: difficulty,
      isSolved: isSolved ?? this.isSolved,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
      hintValue: clearHint ? null : (hintValue ?? this.hintValue),
    );
  }
}

@riverpod
class MagnetsNotifier extends _$MagnetsNotifier {
  final MagnetsEngine _engine = const MagnetsEngine();

  @override
  MagnetsState build() => _newPuzzle(MagnetsDifficulty.medium);

  MagnetsState _newPuzzle(MagnetsDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty);
    return MagnetsState(
      puzzle: puzzle,
      states: List<int>.filled(puzzle.dominoCount, 0),
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(MagnetsDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  /// Blank -> `+` -> `-` -> blank, for the whole domino.
  void cycle(int domino) {
    if (state.isSolved) return;
    final states = [...state.states];
    states[domino] = (states[domino] + 1) % 3;
    final next = state.copyWith(states: states, clearHint: true);
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, states));
  }

  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.states);
    if (found == null) return;
    state = state.copyWith(hintCell: found.cell, hintValue: found.value);
  }

  /// The level this board needs, for the HUD.
  int? get level => _engine.levelOf(state.puzzle);
}
