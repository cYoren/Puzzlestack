import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'lights_out_engine.dart';

part 'lights_out_provider.g.dart';

@immutable
class LightsOutState extends PuzzleState {
  const LightsOutState({
    required this.puzzle,
    required this.grid,
    required this.pressed,
    required this.difficulty,
    this.presses = 0,
    this.isSolved = false,
    this.hint,
  });

  final LightsOutPuzzle puzzle;
  final List<bool> grid;

  /// Which cells have been pressed an odd number of times. The remaining
  /// solution is `puzzle.solution XOR pressed`, which is what makes the hint
  /// exact and free.
  final List<bool> pressed;

  final LightsOutDifficulty difficulty;
  final int presses;
  final bool isSolved;
  final int? hint;

  int get size => puzzle.size;

  LightsOutState copyWith({
    List<bool>? grid,
    List<bool>? pressed,
    int? presses,
    bool? isSolved,
    int? hint,
    bool clearHint = false,
  }) {
    return LightsOutState(
      puzzle: puzzle,
      grid: grid ?? this.grid,
      pressed: pressed ?? this.pressed,
      difficulty: difficulty,
      presses: presses ?? this.presses,
      isSolved: isSolved ?? this.isSolved,
      hint: clearHint ? null : (hint ?? this.hint),
    );
  }
}

@riverpod
class LightsOutNotifier extends _$LightsOutNotifier {
  final LightsOutEngine _engine = const LightsOutEngine();

  @override
  LightsOutState build() => _newPuzzle(LightsOutDifficulty.medium);

  LightsOutState _newPuzzle(LightsOutDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty);
    return LightsOutState(
      puzzle: puzzle,
      grid: puzzle.start,
      pressed: List<bool>.filled(puzzle.start.length, false),
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(LightsOutDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  void applyMove(PuzzleMove<LightsOutState> move) {
    if (state.isSolved) return;
    final next = move.apply(state);
    state = next.copyWith(isSolved: _engine.isSolved(next.grid));
  }

  /// One press that is still needed. Because the press set is unique, the
  /// presses still to make are exactly `solution XOR pressed`, so the hint is
  /// the first of them — not a guess.
  int? hint() {
    if (state.isSolved) return null;
    final puzzle = state.puzzle;
    for (final index in puzzle.solution) {
      if (!state.pressed[index]) {
        state = state.copyWith(hint: index);
        return index;
      }
    }
    return null;
  }

  /// Presses the answer's set, in one go.
  void solve() {
    if (state.isSolved) return;
    var grid = [...state.grid];
    for (final index in state.puzzle.solution) {
      grid = _engine.press(grid, state.puzzle.size, index);
    }
    state = state.copyWith(
      grid: grid,
      presses: state.presses + state.puzzle.solution.length,
      isSolved: true,
      clearHint: true,
    );
  }
}
