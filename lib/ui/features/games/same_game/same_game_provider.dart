import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'same_game_engine.dart';

part 'same_game_provider.g.dart';

@immutable
class SameGameState extends PuzzleState {
  const SameGameState({
    required this.puzzle,
    required this.grid,
    required this.difficulty,
    this.score = 0,
    this.isSolved = false,
    this.isStuck = false,
    this.hint,
  });

  final SameGamePuzzle puzzle;
  final List<int> grid;
  final SameGameDifficulty difficulty;
  final int score;
  final bool isSolved;

  /// No group of two is left, so the board cannot be finished. Not a loss in
  /// the scoring sense — the player keeps the points they earned — but the
  /// game is over and the board should say so instead of waiting for a tap
  /// that can never work.
  final bool isStuck;

  /// The group the hint is offering, cleared on the next move.
  final List<int>? hint;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  int get squaresLeft => grid.where((c) => c != 0).length;

  SameGameState copyWith({
    List<int>? grid,
    int? score,
    bool? isSolved,
    bool? isStuck,
    List<int>? hint,
    bool clearHint = false,
  }) {
    return SameGameState(
      puzzle: puzzle,
      grid: grid ?? this.grid,
      difficulty: difficulty,
      score: score ?? this.score,
      isSolved: isSolved ?? this.isSolved,
      isStuck: isStuck ?? this.isStuck,
      hint: clearHint ? null : (hint ?? this.hint),
    );
  }
}

@riverpod
class SameGameNotifier extends _$SameGameNotifier {
  final SameGameEngine _engine = const SameGameEngine();

  @override
  SameGameState build() => _newPuzzle(SameGameDifficulty.medium);

  SameGameState _newPuzzle(SameGameDifficulty difficulty) {
    final puzzle = SameGamePuzzle(
      rows: difficulty.rows,
      cols: difficulty.cols,
      colours: difficulty.colours,
      start: _engine.generate(
        rows: difficulty.rows,
        cols: difficulty.cols,
        colours: difficulty.colours,
      ),
    );
    return SameGameState(
      puzzle: puzzle,
      grid: puzzle.start,
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(SameGameDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  void applyMove(PuzzleMove<SameGameState> move) {
    if (state.isSolved || state.isStuck) return;
    final next = move.apply(state);
    final solved = _engine.isSolved(next.grid);
    state = next.copyWith(
      isSolved: solved,
      isStuck: !solved && !_engine.hasMoves(next.grid, next.rows, next.cols),
    );
  }

  /// The biggest group on the board. Same Game has no logical deduction to
  /// reveal — the interesting decision is which group to take and in what
  /// order — so the honest hint is the one a good player would look at first,
  /// not a solution.
  List<int>? hint() {
    if (state.isSolved || state.isStuck) return null;
    final groups = _engine.removableGroups(state.grid, state.rows, state.cols);
    if (groups.isEmpty) return null;
    state = state.copyWith(hint: groups.first);
    return groups.first;
  }

  /// Clears the board by removing every group that is left.
  void solve() {
    if (state.isSolved) return;
    final grid = List<int>.filled(state.grid.length, 0);
    state = state.copyWith(
      grid: grid,
      isSolved: true,
      isStuck: false,
      clearHint: true,
    );
  }
}
