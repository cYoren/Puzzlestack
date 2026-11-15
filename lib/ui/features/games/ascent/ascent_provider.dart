import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'ascent_engine.dart';

part 'ascent_provider.g.dart';

@immutable
class AscentState extends PuzzleState {
  const AscentState({
    required this.puzzle,
    required this.values,
    required this.size,
    this.selected,
    this.isSolved = false,
    this.hintCell,
  });

  final AscentPuzzle puzzle;

  /// Per cell, the number the player wrote, or [kAscentBlank].
  final List<int> values;

  final AscentSize size;
  final int? selected;
  final bool isSolved;
  final int? hintCell;

  int get n => puzzle.n;

  /// The lowest number not on the board yet: the one the next tap writes.
  ///
  /// Numbers are entered in order rather than through a tray of forty-nine
  /// buttons, because forty-nine buttons do not fit a phone and a scrolling
  /// tray fights the card. The order costs nothing: every number goes on the
  /// board exactly once, so anything the player can deduce can wait its turn.
  int get nextNumber {
    final placed = values.toSet();
    for (var number = 1; number <= puzzle.maxNumber; number++) {
      if (!placed.contains(number)) return number;
    }
    return puzzle.maxNumber;
  }

  bool isGiven(int cell) => puzzle.given(cell) != kAscentNoClue;

  Set<int> get conflicts => puzzle.conflicts(values);

  AscentState copyWith({
    List<int>? values,
    int? selected,
    bool clearSelection = false,
    bool? isSolved,
    int? hintCell,
    bool clearHint = false,
  }) {
    return AscentState(
      puzzle: puzzle,
      values: values ?? this.values,
      size: size,
      selected: clearSelection ? null : (selected ?? this.selected),
      isSolved: isSolved ?? this.isSolved,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
    );
  }
}

@riverpod
class AscentNotifier extends _$AscentNotifier {
  final AscentEngine _engine = const AscentEngine();

  @override
  AscentState build() => _newPuzzle(AscentSize.small);

  AscentState _newPuzzle(AscentSize size) => AscentState(
        puzzle: _engine.generate(size),
        values: List<int>.filled(size.cellCount, kAscentBlank),
        size: size,
      );

  void newGame() => state = _newPuzzle(state.size);

  void setSize(AscentSize size) {
    if (size == state.size) return;
    state = _newPuzzle(size);
  }

  /// Writes the next number in an empty cell, and clears a cell the player
  /// filled. A printed number is never touched.
  void tap(int cell) {
    if (state.isSolved || state.isGiven(cell)) return;
    final values = [...state.values];
    if (values[cell] != kAscentBlank) {
      values[cell] = kAscentBlank;
      state = state.copyWith(values: values, clearHint: true, isSolved: false);
      return;
    }
    values[cell] = state.nextNumber;
    final next = state.copyWith(values: values, clearHint: true);
    state = next.copyWith(isSolved: _engine.isSolved(next.puzzle, values));
  }

  /// Applies one number the rules prove.
  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.values);
    if (found == null) return;
    final values = [...state.values];
    values[found.cell] = found.number;
    final next = state.copyWith(values: values, hintCell: found.cell);
    state = next.copyWith(isSolved: _engine.isSolved(next.puzzle, values));
  }

  int? get level => _engine.levelOf(state.puzzle);

  /// Writes the answer.
  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      values: List<int>.from(state.puzzle.solution),
      clearSelection: true,
      clearHint: true,
      isSolved: true,
    );
  }
}
