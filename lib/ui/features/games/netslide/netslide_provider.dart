import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'netslide_engine.dart';

part 'netslide_provider.g.dart';

@immutable
class NetState extends PuzzleState {
  const NetState({
    required this.puzzle,
    required this.masks,
    required this.difficulty,
    this.moves = 0,
    this.hint,
  });

  final NetPuzzle puzzle;

  /// The board as it stands, one connection mask per cell.
  final List<int> masks;

  final NetDifficulty difficulty;
  final int moves;
  final ({bool row, int index, bool forward})? hint;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  bool get isSolved => const NetEngine().isSolved(puzzle, masks);

  NetState copyWith({
    List<int>? masks,
    int? moves,
    ({bool row, int index, bool forward})? hint,
    bool clearHint = false,
  }) =>
      NetState(
        puzzle: puzzle,
        masks: masks ?? this.masks,
        difficulty: difficulty,
        moves: moves ?? this.moves,
        hint: clearHint ? null : (hint ?? this.hint),
      );
}

@riverpod
class NetslideNotifier extends _$NetslideNotifier {
  final NetEngine _engine = const NetEngine();

  @override
  NetState build() => _newPuzzle(NetDifficulty.medium);

  NetState _newPuzzle(NetDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty);
    return NetState(
      puzzle: puzzle,
      masks: puzzle.masks,
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(NetDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  /// Slides a row or a column. Returns false when a barrier stops it.
  bool slide({required bool row, required int index, required bool forward}) {
    if (state.isSolved) return false;
    final next = _engine.slide(
      state.puzzle,
      state.masks,
      row: row,
      index: index,
      forward: forward,
    );
    if (next == null) return false;
    state = state.copyWith(masks: next, moves: state.moves + 1, clearHint: true);
    return true;
  }

  /// Applies a move the board built, which already knows which line slides and
  /// which way. The board and the notifier must not disagree about that, so there
  /// is one implementation and the board owns it.
  void applyBoardMove(PuzzleMove<NetState> move) {
    if (state.isSolved) return;
    final next = move.apply(state);
    if (identical(next, state) || next.masks == state.masks) return;
    state = next.copyWith(
      moves: state.moves + 1,
      clearHint: true,
    );
  }

  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.masks);
    if (found == null) return;
    state = state.copyWith(hint: found);
  }

  /// Puts the net back together.
  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      masks: List<int>.from(state.puzzle.solvedMasks),
      clearHint: true,
    );
  }
}
