import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/deduction.dart';
import '../../../core/board/puzzle_board.dart';
import 'galaxies_engine.dart';

part 'galaxies_provider.g.dart';

/// One cell the rules can prove, and the dot it must belong to.
@immutable
class GalaxiesHint {
  const GalaxiesHint(this.cell, this.dot);

  final int cell;
  final int dot;

  @override
  bool operator ==(Object other) =>
      other is GalaxiesHint && other.cell == cell && other.dot == dot;

  @override
  int get hashCode => Object.hash(cell, dot);
}

@immutable
class GalaxiesState extends PuzzleState {
  const GalaxiesState({
    required this.puzzle,
    required this.owner,
    required this.difficulty,
    this.activeDot,
    this.hint,
    this.isSolved = false,
  });

  final GalaxiesPuzzle puzzle;

  /// Cell index to dot index, -1 when the cell is still free.
  final List<int> owner;

  final GalaxiesDifficulty difficulty;

  /// The dot the player is painting with, when one is picked.
  final int? activeDot;

  final GalaxiesHint? hint;

  final bool isSolved;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  int get painted => owner.where((dot) => dot != -1).length;

  int get free => owner.length - painted;

  GalaxiesState copyWith({
    List<int>? owner,
    int? activeDot,
    bool clearActive = false,
    GalaxiesHint? hint,
    bool clearHint = false,
    bool? isSolved,
  }) {
    return GalaxiesState(
      puzzle: puzzle,
      owner: owner ?? this.owner,
      difficulty: difficulty,
      activeDot: clearActive ? null : (activeDot ?? this.activeDot),
      hint: clearHint ? null : (hint ?? this.hint),
      isSolved: isSolved ?? this.isSolved,
    );
  }
}

@riverpod
class GalaxiesNotifier extends _$GalaxiesNotifier {
  final GalaxiesEngine _engine = const GalaxiesEngine();

  @override
  GalaxiesState build() => _newGame(GalaxiesDifficulty.easy);

  GalaxiesState _newGame(GalaxiesDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty: difficulty);
    return GalaxiesState(
      puzzle: puzzle,
      owner: List<int>.filled(puzzle.cellCount, -1),
      difficulty: difficulty,
    );
  }

  void newGame({GalaxiesDifficulty? difficulty}) {
    state = _newGame(difficulty ?? state.difficulty);
  }

  void applyMove(PuzzleMove<GalaxiesState> move) {
    if (state.isSolved) return;
    state = move.apply(state);
  }

  void setDifficulty(GalaxiesDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    newGame(difficulty: difficulty);
  }

  /// Picks the dot the player paints with, or puts it down.
  void select(int? dot) {
    if (dot == null || dot == state.activeDot) {
      state = state.copyWith(clearActive: true, clearHint: true);
      return;
    }
    state = state.copyWith(activeDot: dot, clearHint: true);
  }

  /// Paints [cell] with [dot], and the cell it reflects onto.
  ///
  /// Returns false when the pair cannot be painted — the reflection is off the
  /// board, or one of the two already belongs to another dot.
  bool paint(int cell, int dot) {
    if (state.isSolved) return false;
    final cells = _engine.paint(state.puzzle, state.owner, cell, dot);
    if (cells == null) return false;

    final owner = [...state.owner];
    for (final painted in cells) {
      owner[painted] = dot;
    }
    final solved = _engine.isSolved(state.puzzle, owner);
    state = state.copyWith(
      owner: owner,
      isSolved: solved,
      clearHint: true,
    );
    return true;
  }

  /// Clears [cell] and its reflection, so the board stays symmetric.
  bool clear(int cell) {
    if (state.isSolved) return false;
    final dot = state.owner[cell];
    if (dot == -1) return false;
    // The cells a dot sits in are forced by the rules, so clearing one only
    // makes the board unsolvable until it is painted back.
    if (state.puzzle.seedCells(dot).contains(cell)) return false;

    final owner = [...state.owner];
    owner[cell] = -1;
    final mirror = state.puzzle.mirrorOf(cell, dot);
    if (mirror != null && mirror != cell) owner[mirror] = -1;

    state = state.copyWith(owner: owner, clearHint: true);
    return true;
  }

  /// One cell the rules can prove, or null when they cannot move.
  ///
  /// The step comes from the solver, not from the stored answer, so a hint is
  /// something the player could have worked out. Only when no rule can advance
  /// does it fall back to the board's own solution, and that is rare — the
  /// generator only ships boards the rules can finish.
  GalaxiesHint? hint() {
    if (state.isSolved) return null;

    final model = GalaxiesModel.from(state.puzzle, state.owner);
    final before = [...model.owner];
    deduce(model, galaxiesRules);

    for (var cell = 0; cell < before.length; cell++) {
      if (before[cell] == -1 && model.owner[cell] != -1) {
        final hint = GalaxiesHint(cell, model.owner[cell]);
        state = state.copyWith(hint: hint);
        return hint;
      }
    }

    for (var cell = 0; cell < before.length; cell++) {
      if (before[cell] == -1) {
        final hint = GalaxiesHint(cell, state.puzzle.solution[cell]);
        state = state.copyWith(hint: hint);
        return hint;
      }
    }
    return null;
  }

  /// Paints the answer's partition.
  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      owner: List<int>.from(state.puzzle.solution),
      clearActive: true,
      clearHint: true,
      isSolved: true,
    );
  }
}
