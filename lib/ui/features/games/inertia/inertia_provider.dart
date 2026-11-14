import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'inertia_engine.dart';

part 'inertia_provider.g.dart';

@immutable
class InertiaState extends PuzzleState {
  const InertiaState({
    required this.puzzle,
    required this.position,
    required this.difficulty,
    this.moves = 0,
    this.hint,
  });

  final InertiaPuzzle puzzle;
  final InertiaPosition position;
  final InertiaDifficulty difficulty;
  final int moves;
  final InertiaDirection? hint;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  bool get isSolved => const InertiaEngine().isSolved(puzzle, position);

  int get gemsLeft => puzzle.gemCount -
      List.generate(puzzle.gemCount, (i) => position.collected & (1 << i) != 0)
          .where((taken) => taken)
          .length;

  InertiaState copyWith({
    InertiaPosition? position,
    int? moves,
    InertiaDirection? hint,
    bool clearHint = false,
  }) =>
      InertiaState(
        puzzle: puzzle,
        position: position ?? this.position,
        difficulty: difficulty,
        moves: moves ?? this.moves,
        hint: clearHint ? null : (hint ?? this.hint),
      );
}

@riverpod
class InertiaNotifier extends _$InertiaNotifier {
  final InertiaEngine _engine = const InertiaEngine();

  @override
  InertiaState build() => _newPuzzle(InertiaDifficulty.medium);

  InertiaState _newPuzzle(InertiaDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty);
    return InertiaState(
      puzzle: puzzle,
      position: _engine.startOf(puzzle),
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(InertiaDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  /// Slide in a direction. Returns false when the ball would not move.
  bool slide(InertiaDirection direction) {
    if (state.isSolved || state.position.exploded) return false;
    final next = _engine.move(state.puzzle, state.position, direction);
    if (next.cell == state.position.cell && !next.exploded) return false;
    state = state.copyWith(
      position: next,
      moves: state.moves + 1,
      clearHint: true,
    );
    return true;
  }

  /// Put the ball back on the start square with the gems restored, after a mine.
  void retry() {
    state = state.copyWith(
      position: _engine.startOf(state.puzzle),
      moves: 0,
      clearHint: true,
    );
  }

  void hint() {
    if (state.isSolved) return;
    final direction = _engine.hint(state.puzzle, state.position);
    if (direction == null) return;
    state = state.copyWith(hint: direction);
  }

  /// Slides along the engine's own line from where the ball is now.
  void solve() {
    if (state.isSolved) return;
    final line = _engine.solve(state.puzzle);
    if (line == null) return;
    var position = state.position;
    for (final direction in line) {
      position = _engine.move(state.puzzle, position, direction);
    }
    state = state.copyWith(
      position: position,
      moves: state.moves + line.length,
      clearHint: true,
    );
  }
}
