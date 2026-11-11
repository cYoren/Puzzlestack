import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/deduction.dart';
import '../../../../core/latin.dart';
import '../../../core/board/puzzle_board.dart';
import 'futoshiki_engine.dart';

part 'futoshiki_provider.g.dart';

@immutable
class FutoshikiState extends PuzzleState {
  const FutoshikiState({
    required this.puzzle,
    required this.values,
    required this.difficulty,
    this.selected,
    this.isSolved = false,
    this.hintCell,
    this.hintValue,
  });

  final FutoshikiPuzzle puzzle;

  /// Player entries, row-major, 0 for empty.
  final List<int> values;

  final FutoshikiDifficulty difficulty;
  final int? selected;
  final bool isSolved;
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

  bool isGiven(int cell) => puzzle.givens.containsKey(cell);

  FutoshikiState copyWith({
    List<int>? values,
    int? selected,
    bool clearSelection = false,
    bool? isSolved,
    int? hintCell,
    int? hintValue,
    bool clearHint = false,
  }) {
    return FutoshikiState(
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
class FutoshikiNotifier extends _$FutoshikiNotifier {
  final FutoshikiEngine _engine = const FutoshikiEngine();

  @override
  FutoshikiState build() => _newPuzzle(FutoshikiDifficulty.medium);

  FutoshikiState _newPuzzle(FutoshikiDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty);
    final values = List<int>.filled(puzzle.n * puzzle.n, 0);
    puzzle.givens.forEach((cell, value) => values[cell] = value);
    return FutoshikiState(
      puzzle: puzzle,
      values: values,
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(FutoshikiDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  void select(int cell) {
    if (state.isSolved) return;
    state = state.copyWith(selected: cell, clearHint: true);
  }

  void enter(int value) {
    final cell = state.selected;
    if (cell == null || state.isSolved || state.isGiven(cell)) return;
    final values = [...state.values];
    values[cell] = values[cell] == value ? 0 : value;
    final next = state.copyWith(values: values, clearHint: true);
    state = next.copyWith(isSolved: _isSolved(next));
  }

  void erase() {
    final cell = state.selected;
    if (cell == null || state.isGiven(cell)) return;
    final values = [...state.values];
    values[cell] = 0;
    state = state.copyWith(values: values, clearHint: true, isSolved: false);
  }

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

  /// The player's grid wins when it is a Latin square and every inequality on
  /// the board agrees with it.
  bool _isSolved(FutoshikiState state) {
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
      for (var col = 0; col + 1 < n; col++) {
        final edge = puzzle.horizontal[row * (n - 1) + col];
        if (edge == 0) continue;
        final a = values[row * n + col];
        final b = values[row * n + col + 1];
        if (edge == 1 ? a >= b : a <= b) return false;
      }
    }
    for (var row = 0; row + 1 < n; row++) {
      for (var col = 0; col < n; col++) {
        final edge = puzzle.vertical[row * n + col];
        if (edge == 0) continue;
        final a = values[row * n + col];
        final b = values[(row + 1) * n + col];
        if (edge == 1 ? a >= b : a <= b) return false;
      }
    }
    return true;
  }
}
