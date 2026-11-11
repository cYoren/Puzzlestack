import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/deduction.dart';
import '../../../../core/latin.dart';
import '../../../core/board/puzzle_board.dart';
import 'skyscrapers_engine.dart';

part 'skyscrapers_provider.g.dart';

@immutable
class SkyscrapersState extends PuzzleState {
  const SkyscrapersState({
    required this.puzzle,
    required this.values,
    required this.difficulty,
    this.selected,
    this.isSolved = false,
    this.hintCell,
    this.hintValue,
  });

  final SkyscrapersPuzzle puzzle;

  /// Player entries, row-major, 0 for empty.
  final List<int> values;

  final SkyscrapersDifficulty difficulty;
  final int? selected;
  final bool isSolved;

  /// One cell the rules can prove, offered by the hint.
  final int? hintCell;
  final int? hintValue;

  int get n => puzzle.n;

  /// Cells that repeat a value in their row or column.
  Set<int> get conflicts {
    final out = <int>{};
    for (var row = 0; row < n; row++) {
      for (var a = 0; a < n; a++) {
        final value = values[row * n + a];
        if (value == 0) continue;
        for (var b = a + 1; b < n; b++) {
          if (values[row * n + b] == value) {
            out.add(row * n + a);
            out.add(row * n + b);
          }
        }
      }
    }
    for (var col = 0; col < n; col++) {
      for (var a = 0; a < n; a++) {
        final value = values[a * n + col];
        if (value == 0) continue;
        for (var b = a + 1; b < n; b++) {
          if (values[b * n + col] == value) {
            out.add(a * n + col);
            out.add(b * n + col);
          }
        }
      }
    }
    return out;
  }

  SkyscrapersState copyWith({
    List<int>? values,
    int? selected,
    bool clearSelection = false,
    bool? isSolved,
    int? hintCell,
    int? hintValue,
    bool clearHint = false,
  }) {
    return SkyscrapersState(
      puzzle: puzzle,
      values: values ?? this.values,
      difficulty: difficulty,
      selected: clearSelection ? null : (selected ?? this.selected),
      isSolved: isSolved ?? this.isSolved,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
      hintValue: clearHint ? null : (hintValue ?? this.hintValue),
    );
  }
}

@riverpod
class SkyscrapersNotifier extends _$SkyscrapersNotifier {
  final SkyscrapersEngine _engine = const SkyscrapersEngine();

  @override
  SkyscrapersState build() => _newPuzzle(SkyscrapersDifficulty.medium);

  SkyscrapersState _newPuzzle(SkyscrapersDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty);
    return SkyscrapersState(
      puzzle: puzzle,
      values: List<int>.filled(puzzle.n * puzzle.n, 0),
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(SkyscrapersDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  void select(int cell) {
    if (state.isSolved) return;
    state = state.copyWith(selected: cell, clearHint: true);
  }

  void enter(int value) {
    final cell = state.selected;
    if (cell == null || state.isSolved) return;
    final values = [...state.values];
    values[cell] = values[cell] == value ? 0 : value;
    final next = state.copyWith(values: values, clearHint: true);
    state = next.copyWith(isSolved: _isSolved(next));
  }

  void erase() {
    final cell = state.selected;
    if (cell == null) return;
    final values = [...state.values];
    values[cell] = 0;
    state = state.copyWith(values: values, clearHint: true, isSolved: false);
  }

  /// One cell the rules can settle from where the player is, not the answer.
  void hint() {
    if (state.isSolved) return;
    final model = _engine.model(state.puzzle);
    for (var i = 0; i < model.masks.length; i++) {
      if (state.values[i] != 0) model.masks[i] = model.bitFor(state.values[i]);
    }
    final board = model.copy();
    final outcome = deduce(board, latinRules);
    if (!outcome.consistent) return;
    for (var i = 0; i < board.masks.length; i++) {
      if (state.values[i] != 0) continue;
      if (!LatinModel.isDecided(board.masks[i])) continue;
      state = state.copyWith(
        hintCell: i,
        hintValue: LatinModel.valueOf(board.masks[i]),
      );
      return;
    }
  }

  /// The player's grid wins when it is a Latin square and every clue on the
  /// edge agrees with it. This is checked directly rather than by asking the
  /// solver: the solver answers "is this clue set unique", which is a different
  /// question from "is this grid right".
  bool _isSolved(SkyscrapersState state) {
    final n = state.n;
    final values = state.values;
    if (values.any((v) => v == 0)) return false;

    for (var row = 0; row < n; row++) {
      final seen = <int>{};
      for (var col = 0; col < n; col++) {
        if (!seen.add(values[row * n + col])) return false;
      }
    }
    for (var col = 0; col < n; col++) {
      final seen = <int>{};
      for (var row = 0; row < n; row++) {
        if (!seen.add(values[row * n + col])) return false;
      }
    }

    final puzzle = state.puzzle;
    for (var row = 0; row < n; row++) {
      final line = [for (var col = 0; col < n; col++) values[row * n + col]];
      if (puzzle.left[row] != 0 && _engine.visible(line) != puzzle.left[row]) {
        return false;
      }
      if (puzzle.right[row] != 0 &&
          _engine.visible(line.reversed.toList()) != puzzle.right[row]) {
        return false;
      }
    }
    for (var col = 0; col < n; col++) {
      final line = [for (var row = 0; row < n; row++) values[row * n + col]];
      if (puzzle.top[col] != 0 && _engine.visible(line) != puzzle.top[col]) {
        return false;
      }
      if (puzzle.bottom[col] != 0 &&
          _engine.visible(line.reversed.toList()) != puzzle.bottom[col]) {
        return false;
      }
    }
    return true;
  }
}
