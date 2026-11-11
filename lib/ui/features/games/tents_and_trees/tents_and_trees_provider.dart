import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'tents_and_trees_engine.dart';
import 'tents_model.dart';

part 'tents_and_trees_provider.g.dart';

@immutable
class TentsState extends PuzzleState {
  const TentsState({
    required this.puzzle,
    required this.tents,
    required this.difficulty,
    this.isSolved = false,
    this.hintCell,
    this.hintIsTent,
  });

  final TentsPuzzle puzzle;

  /// Cell indices the player has put a tent on.
  final List<int> tents;

  final TentsDifficulty difficulty;
  final bool isSolved;

  /// A cell the hint has proved, and whether it should hold a tent.
  final int? hintCell;
  final bool? hintIsTent;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  TentsState copyWith({
    List<int>? tents,
    bool? isSolved,
    int? hintCell,
    bool? hintIsTent,
    bool clearHint = false,
  }) {
    return TentsState(
      puzzle: puzzle,
      tents: tents ?? this.tents,
      difficulty: difficulty,
      isSolved: isSolved ?? this.isSolved,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
      hintIsTent: clearHint ? null : (hintIsTent ?? this.hintIsTent),
    );
  }
}

@riverpod
class TentsAndTreesNotifier extends _$TentsAndTreesNotifier {
  final TentsEngine _engine = const TentsEngine();

  @override
  TentsState build() => _newPuzzle(TentsDifficulty.medium);

  TentsState _newPuzzle(TentsDifficulty difficulty) => TentsState(
        puzzle: _engine.generate(difficulty),
        tents: const [],
        difficulty: difficulty,
      );

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(TentsDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  void toggle(int cell) {
    if (state.isSolved || state.puzzle.isTree(cell)) return;
    final tents = [...state.tents];
    if (!tents.remove(cell)) tents.add(cell);
    final next = state.copyWith(tents: tents, clearHint: true);
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, tents));
  }

  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.tents);
    if (found == null) return;
    state = state.copyWith(
      hintCell: found.cell,
      hintIsTent: found.value == kTent,
    );
  }

  int? get level => _engine.levelOf(state.puzzle);
}
