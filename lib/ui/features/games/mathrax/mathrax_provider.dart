import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'mathrax_engine.dart';
import 'mathrax_puzzle.dart';

part 'mathrax_provider.g.dart';

@immutable
class MathraxState extends PuzzleState {
  const MathraxState({
    required this.puzzle,
    required this.values,
    required this.size,
    this.selected,
    this.isSolved = false,
    this.hintCell,
  });

  final MathraxPuzzle puzzle;

  /// Per cell, the digit the player wrote, or [kMathraxBlank].
  final List<int> values;

  final MathraxSize size;
  final int? selected;
  final bool isSolved;

  /// The cell the last hint wrote, so the board can ring it.
  final int? hintCell;

  int get n => puzzle.n;

  int get written => values.where((value) => value != kMathraxBlank).length;

  /// Cells the player has made impossible, so the board can paint them.
  Set<int> get conflicts => puzzle.conflicts(values);

  MathraxState copyWith({
    List<int>? values,
    int? selected,
    bool clearSelection = false,
    bool? isSolved,
    int? hintCell,
    bool clearHint = false,
  }) {
    return MathraxState(
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
class MathraxNotifier extends _$MathraxNotifier {
  final MathraxEngine _engine = const MathraxEngine();

  @override
  MathraxState build() => _newPuzzle(MathraxSize.medium);

  /// Every cell starts blank: Mathrax has no printed cells, only printed
  /// corners. The clue set lives in the puzzle and never in the values, so the
  /// win test ("every cell holds its digit") and the player's board cannot drift
  /// apart.
  MathraxState _newPuzzle(MathraxSize size) {
    final puzzle = _engine.generate(size);
    return MathraxState(
      puzzle: puzzle,
      values: List<int>.filled(size.cellCount, kMathraxBlank),
      size: size,
    );
  }

  void newGame() => state = _newPuzzle(state.size);

  void setSize(MathraxSize size) {
    if (size == state.size) return;
    state = _newPuzzle(size);
  }

  void select(int cell) {
    if (state.isSolved) return;
    state = state.copyWith(selected: cell, clearHint: true);
  }

  /// Cycles the selected cell through 1..N and back to blank.
  ///
  /// A cycle rather than a keypad: the digits are 1..6, the board is small, and
  /// one target per cell is what keeps a Mathrax card playable with a thumb.
  void cycle(int cell) {
    if (state.isSolved) return;
    if (cell < 0 || cell >= state.values.length) return;
    final next = state.values[cell] == kMathraxBlank
        ? 1
        : state.values[cell] >= state.n
            ? kMathraxBlank
            : state.values[cell] + 1;
    final values = [...state.values];
    values[cell] = next;
    final updated = state.copyWith(values: values, selected: cell, clearHint: true);
    state = updated.copyWith(isSolved: _engine.isSolved(state.puzzle, values));
  }

  void erase() {
    final cell = state.selected;
    if (cell == null || state.isSolved) return;
    final values = [...state.values];
    values[cell] = kMathraxBlank;
    state = state.copyWith(values: values, clearHint: true, isSolved: false);
  }

  /// Applies one digit the rules prove.
  ///
  /// It writes the digit rather than outlining the cell: a ring says "something
  /// is here" and the player still has to work out which of the digits it is.
  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.values);
    if (found == null) return;
    final values = [...state.values];
    values[found.cell] = found.digit;
    final next = state.copyWith(values: values, hintCell: found.cell);
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, values));
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
