import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'abcd_engine.dart';

part 'abcd_provider.g.dart';

@immutable
class AbcdState extends PuzzleState {
  const AbcdState({
    required this.puzzle,
    required this.grid,
    required this.size,
    this.isSolved = false,
    this.hintCell,
  });

  final AbcdPuzzle puzzle;

  /// Per cell: the letter index, or -1 when the player has not filled it.
  final List<int> grid;

  final AbcdSize size;
  final bool isSolved;
  final int? hintCell;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  int get letters => puzzle.letters;

  int get filled => grid.where((value) => value >= 0).length;

  AbcdState copyWith({
    List<int>? grid,
    bool? isSolved,
    int? hintCell,
    bool clearHint = false,
  }) {
    return AbcdState(
      puzzle: puzzle,
      grid: grid ?? this.grid,
      size: size,
      isSolved: isSolved ?? this.isSolved,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
    );
  }
}

@riverpod
class AbcdNotifier extends _$AbcdNotifier {
  final AbcdEngine _engine = const AbcdEngine();

  @override
  AbcdState build() => _newPuzzle(AbcdSize.small);

  AbcdState _newPuzzle(AbcdSize size) => AbcdState(
        puzzle: _engine.generate(size),
        grid: List<int>.filled(size.rows * size.cols, -1),
        size: size,
      );

  void newGame() => state = _newPuzzle(state.size);

  void setSize(AbcdSize size) {
    if (size == state.size) return;
    state = _newPuzzle(size);
  }

  /// Tap cycles empty → A → B → … → empty, so the game is playable by tapping
  /// alone with no letter picker taking up the board.
  void cycle(int cell) {
    if (state.isSolved) return;
    final grid = [...state.grid];
    grid[cell] = grid[cell] + 1 >= state.letters ? -1 : grid[cell] + 1;
    final next = state.copyWith(grid: grid, clearHint: true);
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, grid));
  }

  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.grid);
    if (found == null) return;
    final grid = [...state.grid];
    grid[found.cell] = found.letter;
    state = state.copyWith(
      grid: grid,
      hintCell: found.cell,
      isSolved: _engine.isSolved(state.puzzle, grid),
    );
  }

  int? get level => _engine.levelOf(state.puzzle);

  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      grid: List<int>.from(state.puzzle.solution),
      isSolved: true,
      clearHint: true,
    );
  }
}
