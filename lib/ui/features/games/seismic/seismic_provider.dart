import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'seismic_engine.dart';

part 'seismic_provider.g.dart';

@immutable
class SeismicState extends PuzzleState {
  const SeismicState({
    required this.puzzle,
    required this.values,
    required this.size,
    this.selected,
    this.isSolved = false,
    this.hintCell,
  });

  final SeismicPuzzle puzzle;

  /// Per cell, the digit the player wrote, or [kSeismicBlank].
  final List<int> values;

  final SeismicSize size;
  final int? selected;
  final bool isSolved;

  /// The cell the last hint wrote, so the board can ring it.
  final int? hintCell;

  int get n => puzzle.n;

  /// The largest digit the board can hold, which is the size of its biggest
  /// region.
  int get maxDigit => puzzle.maxDigit;

  int get written => values.where((value) => value != kSeismicBlank).length;

  /// Cells the player has made impossible, so the board can paint them.
  Set<int> get conflicts => puzzle.conflicts(values);

  SeismicState copyWith({
    List<int>? values,
    int? selected,
    bool clearSelection = false,
    bool? isSolved,
    int? hintCell,
    bool clearHint = false,
  }) {
    return SeismicState(
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
class SeismicNotifier extends _$SeismicNotifier {
  final SeismicEngine _engine = const SeismicEngine();

  @override
  SeismicState build() => _newPuzzle(SeismicSize.medium);

  SeismicState _newPuzzle(SeismicSize size) => SeismicState(
        puzzle: _engine.generate(size),
        values: List<int>.filled(size.cellCount, kSeismicBlank),
        size: size,
      );

  void newGame() => state = _newPuzzle(state.size);

  void setSize(SeismicSize size) {
    if (size == state.size) return;
    state = _newPuzzle(size);
  }

  void select(int cell) {
    if (state.isSolved) return;
    state = state.copyWith(selected: cell, clearHint: true);
  }

  /// Writes [digit] in the selected cell, or clears it when it is already
  /// there. A printed number is never overwritten.
  void enter(int digit) {
    final cell = state.selected;
    if (cell == null || state.isSolved) return;
    if (state.puzzle.given(cell) != kSeismicNoClue) return;
    final values = [...state.values];
    values[cell] = values[cell] == digit ? kSeismicBlank : digit;
    final next = state.copyWith(values: values, clearHint: true);
    state = next.copyWith(isSolved: _engine.isSolved(next.puzzle, values));
  }

  void erase() {
    final cell = state.selected;
    if (cell == null || state.isSolved) return;
    if (state.puzzle.given(cell) != kSeismicNoClue) return;
    final values = [...state.values];
    values[cell] = kSeismicBlank;
    state = state.copyWith(values: values, clearHint: true, isSolved: false);
  }

  /// Applies one digit the rules prove.
  ///
  /// It writes the digit rather than outlining the cell: a ring says "something
  /// is here" and the player still has to guess which of the digits it is.
  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.values);
    if (found == null) return;
    final values = [...state.values];
    values[found.cell] = found.digit;
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
