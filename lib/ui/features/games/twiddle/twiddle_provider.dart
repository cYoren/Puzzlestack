import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'twiddle_engine.dart';

part 'twiddle_provider.g.dart';

@immutable
class TwiddleState extends PuzzleState {
  const TwiddleState({
    required this.puzzle,
    required this.grid,
    required this.difficulty,
    this.isSolved = false,
    this.hint,
    this.lastMove,
  });

  final TwiddlePuzzle puzzle;
  final List<int> grid;
  final TwiddleDifficulty difficulty;
  final bool isSolved;

  /// The turn the hint button is offering, cleared on the next move.
  final TwiddleMove? hint;

  /// The turn that produced this grid, if the change was a turn. The board
  /// reads it to animate the rotation instead of swapping the numbers.
  final TwiddleMove? lastMove;

  int get size => puzzle.size;

  int get block => puzzle.block;

  TwiddleState copyWith({
    List<int>? grid,
    bool? isSolved,
    TwiddleMove? hint,
    bool clearHint = false,
    TwiddleMove? lastMove,
    bool clearLastMove = false,
  }) {
    return TwiddleState(
      puzzle: puzzle,
      grid: grid ?? this.grid,
      difficulty: difficulty,
      isSolved: isSolved ?? this.isSolved,
      hint: clearHint ? null : (hint ?? this.hint),
      lastMove: clearLastMove ? null : (lastMove ?? this.lastMove),
    );
  }
}

@riverpod
class TwiddleNotifier extends _$TwiddleNotifier {
  final TwiddleEngine _engine = const TwiddleEngine();

  @override
  TwiddleState build() => _newPuzzle(TwiddleDifficulty.medium);

  TwiddleState _newPuzzle(TwiddleDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty: difficulty);
    return TwiddleState(
      puzzle: puzzle,
      grid: puzzle.start,
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(TwiddleDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  void applyMove(PuzzleMove<TwiddleState> move) {
    if (state.isSolved) return;
    final next = move.apply(state);
    state = next.copyWith(isSolved: _engine.isSolved(next.grid));
  }

  /// One turn worth making. While the player is still on the line the board
  /// was scrambled along, the hint is exact and free; once they leave it, the
  /// engine picks the turn that looks best two moves ahead.
  TwiddleMove? hint() {
    if (state.isSolved) return null;
    final move = _nextOnKnownLine() ??
        _engine.hint(state.grid, state.size, state.block);
    if (move == null) return null;
    state = state.copyWith(hint: move);
    return move;
  }

  TwiddleMove? _nextOnKnownLine() {
    final puzzle = state.puzzle;
    var grid = [...puzzle.start];
    for (final move in puzzle.solution) {
      if (_sameGrid(grid, state.grid)) return move;
      grid = _engine.apply(grid, puzzle.size, move, puzzle.block);
    }
    return null;
  }

  bool _sameGrid(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Walks the scramble back, which is the answer by construction.
  void solve() {
    if (state.isSolved) return;
    var grid = List<int>.from(state.grid);
    for (final move in state.puzzle.solution) {
      grid = _engine.apply(grid, state.size, move, state.block);
      if (_engine.isSolved(grid)) break;
    }
    state = state.copyWith(grid: grid, isSolved: _engine.isSolved(grid));
  }
}
