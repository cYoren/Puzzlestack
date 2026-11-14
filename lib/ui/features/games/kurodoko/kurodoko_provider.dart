import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/deduction.dart';
import '../../../core/board/puzzle_board.dart';
import 'kurodoko_engine.dart';

part 'kurodoko_provider.g.dart';

/// A cell the rules can settle, and what they settle it to.
@immutable
class KurodokoHint {
  const KurodokoHint(this.cell, this.colour);

  final int cell;
  final KurodokoCell colour;

  @override
  String toString() => 'KurodokoHint($cell, ${colour.name})';
}

@immutable
class KurodokoState extends PuzzleState {
  const KurodokoState({
    required this.puzzle,
    required this.grid,
    required this.difficulty,
    this.isSolved = false,
    this.hint,
  });

  final KurodokoPuzzle puzzle;
  final List<KurodokoCell> grid;
  final KurodokoDifficulty difficulty;
  final bool isSolved;

  /// The cell the hint button is offering, cleared on the next move.
  final KurodokoHint? hint;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  int get clueCount => puzzle.clues.where((clue) => clue > 0).length;

  int get blackCount =>
      grid.where((cell) => cell == KurodokoCell.black).length;

  KurodokoState copyWith({
    List<KurodokoCell>? grid,
    bool? isSolved,
    KurodokoHint? hint,
    bool clearHint = false,
  }) {
    return KurodokoState(
      puzzle: puzzle,
      grid: grid ?? this.grid,
      difficulty: difficulty,
      isSolved: isSolved ?? this.isSolved,
      hint: clearHint ? null : (hint ?? this.hint),
    );
  }
}

@riverpod
class KurodokoNotifier extends _$KurodokoNotifier {
  final KurodokoEngine _engine = const KurodokoEngine();

  @override
  KurodokoState build() => _newPuzzle(KurodokoDifficulty.easy);

  KurodokoState _newPuzzle(KurodokoDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty: difficulty);
    return KurodokoState(
      puzzle: puzzle,
      grid: List<KurodokoCell>.filled(puzzle.cellCount, KurodokoCell.unknown),
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(KurodokoDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  /// Cycles a cell: blank, then black, then white, then blank again.
  ///
  /// Black comes first because blackening is the answer; marking a cell white
  /// is a note to yourself and comes second.
  void cycle(int cell) {
    if (state.isSolved) return;
    if (state.puzzle.clues[cell] > 0) return;

    final next = [...state.grid];
    next[cell] = switch (state.grid[cell]) {
      KurodokoCell.unknown => KurodokoCell.black,
      KurodokoCell.black => KurodokoCell.white,
      KurodokoCell.white => KurodokoCell.unknown,
    };
    _commit(next);
  }

  void setCell(int cell, KurodokoCell colour) {
    if (state.isSolved) return;
    final next = [...state.grid];
    next[cell] = colour;
    _commit(next);
  }

  void clearCell(int cell) {
    if (state.isSolved) return;
    final next = [...state.grid];
    next[cell] = KurodokoCell.unknown;
    _commit(next);
  }

  void applyMove(PuzzleMove<KurodokoState> move) {
    if (state.isSolved) return;
    final next = move.apply(state);
    state = next.copyWith(
      isSolved: _engine.isSolved(next.puzzle, next.grid),
      clearHint: true,
    );
  }

  /// One cell the rules can prove, worked out from the board as it stands.
  ///
  /// The hint runs the solver on the player's own grid, so it names a step they
  /// could have reasoned out — not a peek at the stored answer. Only when the
  /// rules have nothing to say does it fall back to the answer.
  KurodokoHint? hint() {
    if (state.isSolved) return null;

    final model = KurodokoModel(state.puzzle, [...state.grid]);
    final before = [...model.grid];
    final outcome = deduce(model, kurodokoRules);

    if (outcome.consistent) {
      for (var cell = 0; cell < model.grid.length; cell++) {
        if (before[cell] != KurodokoCell.unknown) continue;
        if (model.grid[cell] == KurodokoCell.unknown) continue;
        final found = KurodokoHint(cell, model.grid[cell]);
        state = state.copyWith(hint: found);
        return found;
      }
    }

    for (var cell = 0; cell < state.grid.length; cell++) {
      if (state.grid[cell] != KurodokoCell.unknown) continue;
      if (state.puzzle.clues[cell] > 0) continue;
      final found = KurodokoHint(cell, state.puzzle.solution[cell]);
      state = state.copyWith(hint: found);
      return found;
    }
    return null;
  }

  void _commit(List<KurodokoCell> next) {
    state = state.copyWith(
      grid: next,
      isSolved: _engine.isSolved(state.puzzle, next),
      clearHint: true,
    );
  }

  /// Blackens the answer's set.
  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      grid: List<KurodokoCell>.from(state.puzzle.solution),
      isSolved: true,
      clearHint: true,
    );
  }
}
