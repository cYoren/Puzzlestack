import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'cube_engine.dart';

part 'cube_provider.g.dart';

@immutable
class CubeState extends PuzzleState {
  const CubeState({
    required this.puzzle,
    required this.position,
    required this.difficulty,
    this.hint,
    this.moves = 0,
  });

  final CubePuzzle puzzle;
  final CubePosition position;
  final CubeDifficulty difficulty;

  /// The direction the hint is pointing at, cleared by the next roll.
  final CubeDirection? hint;

  final int moves;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  bool get isSolved => position.isSolved;

  CubeState copyWith({
    CubePosition? position,
    CubeDirection? hint,
    bool clearHint = false,
    int? moves,
  }) =>
      CubeState(
        puzzle: puzzle,
        position: position ?? this.position,
        difficulty: difficulty,
        hint: clearHint ? null : (hint ?? this.hint),
        moves: moves ?? this.moves,
      );
}

@riverpod
class CubeNotifier extends _$CubeNotifier {
  final CubeEngine _engine = const CubeEngine();

  @override
  CubeState build() => _newPuzzle(CubeDifficulty.medium);

  CubeState _newPuzzle(CubeDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty);
    return CubeState(
      puzzle: puzzle,
      position: _engine.startOf(puzzle),
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(CubeDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  /// Rolls one square. Returns false when the move would leave the grid, so the
  /// screen can refuse it without the board flickering.
  bool roll(CubeDirection direction) {
    if (state.isSolved) return false;
    final next = _engine.roll(state.puzzle, state.position, direction);
    if (identical(next, state.position) || next.cell == state.position.cell) {
      return false;
    }
    state = state.copyWith(
      position: next,
      moves: state.moves + 1,
      clearHint: true,
    );
    return true;
  }

  void hint() {
    if (state.isSolved) return;
    final direction = _engine.hint(state.puzzle, state.position);
    if (direction == null) return;
    state = state.copyWith(hint: direction);
  }

  /// Rolls the engine's own line to the end of the board.
  void solve() {
    if (state.isSolved) return;
    final line = _engine.solve(state.puzzle, state.position);
    if (line == null) return;
    var position = state.position;
    for (final direction in line) {
      position = _engine.roll(state.puzzle, position, direction);
    }
    state = state.copyWith(
      position: position,
      moves: state.moves + line.length,
      clearHint: true,
    );
  }
}
