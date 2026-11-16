import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'rome_engine.dart';
import 'rome_puzzle.dart';

part 'rome_provider.g.dart';

@immutable
class RomeState extends PuzzleState {
  const RomeState({
    required this.puzzle,
    required this.values,
    required this.size,
    this.selected,
    this.isSolved = false,
    this.hintCell,
  });

  final RomePuzzle puzzle;

  /// Per cell, what is on the board: an arrow `0..3`, [kRomeGoal] in a goal, or
  /// [kRomeBlank] where nothing is written yet.
  final List<int> values;

  final RomeSize size;
  final int? selected;
  final bool isSolved;

  /// The cell the last hint wrote, so the board can ring it.
  final int? hintCell;

  int get n => puzzle.n;

  int get cellCount => puzzle.cellCount;

  /// How many arrows the player has to write: every cell that is not a goal and
  /// not already printed.
  int get arrowCells {
    var count = 0;
    for (var cell = 0; cell < cellCount; cell++) {
      if (puzzle.isGoal(cell)) continue;
      if (puzzle.given(cell) != kRomeNoGiven) continue;
      count++;
    }
    return count;
  }

  /// Arrows the player has written.
  ///
  /// A goal holds no arrow and a printed arrow is not the player's, so neither
  /// counts: the card's number is how much of the board is left to do, not how
  /// full it looks.
  int get written {
    var count = 0;
    for (var cell = 0; cell < cellCount; cell++) {
      if (puzzle.isGoal(cell)) continue;
      if (puzzle.given(cell) != kRomeNoGiven) continue;
      if (values[cell] == kRomeBlank) continue;
      count++;
    }
    return count;
  }

  /// Cells the player has made impossible, so the board can paint them.
  Set<int> get conflicts => puzzle.conflicts(values);

  RomeState copyWith({
    List<int>? values,
    int? selected,
    bool clearSelection = false,
    bool? isSolved,
    int? hintCell,
    bool clearHint = false,
  }) {
    return RomeState(
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
class RomeNotifier extends _$RomeNotifier {
  final RomeEngine _engine = const RomeEngine();

  @override
  RomeState build() => _newPuzzle(RomeSize.small);

  /// A fresh board: the printed arrows go in as givens, a goal carries
  /// [kRomeGoal] so the board has one value per cell, and everything else starts
  /// blank.
  RomeState _newPuzzle(RomeSize size) {
    final puzzle = _engine.generate(size);
    return RomeState(
      puzzle: puzzle,
      values: [
        for (var cell = 0; cell < size.cellCount; cell++)
          puzzle.isGoal(cell)
              ? kRomeGoal
              : puzzle.given(cell) == kRomeNoGiven
                  ? kRomeBlank
                  : puzzle.given(cell),
      ],
      size: size,
    );
  }

  void newGame() => state = _newPuzzle(state.size);

  void setSize(RomeSize size) {
    if (size == state.size) return;
    state = _newPuzzle(size);
  }

  /// The value one tap writes in a cell: the four arrows in order, then back to
  /// blank.
  ///
  /// A cycle rather than a keypad, because there are only four arrows and a tap
  /// is the whole input surface. Blank is in the cycle so a player who taps past
  /// the arrow they wanted can get back to an empty cell instead of having to
  /// guess their way around.
  static int nextValue(int current) {
    if (current == kRomeBlank) return kRomeUp;
    if (current >= kRomeLeft) return kRomeBlank;
    return current + 1;
  }

  /// Cycles one cell. This is the only way a value reaches the board, and it
  /// refuses the two kinds of cell the player does not own: a goal holds no
  /// arrow, and a printed arrow is a given.
  void tap(int cell) {
    if (state.isSolved) return;
    if (cell < 0 || cell >= state.cellCount) return;
    if (state.puzzle.isGoal(cell)) return;
    if (state.puzzle.given(cell) != kRomeNoGiven) return;
    final values = [...state.values];
    values[cell] = nextValue(values[cell]);
    final next =
        state.copyWith(values: values, selected: cell, clearHint: true);
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, values));
  }

  /// Applies one arrow the rules prove.
  ///
  /// It writes the arrow rather than outlining the cell: a ring says "something
  /// is here" and the player still has to work out which of the four it is, or
  /// whether it is anything at all.
  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.values);
    if (found == null) return;
    final values = [...state.values];
    values[found.cell] = found.arrow;
    final next = state.copyWith(values: values, hintCell: found.cell);
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, values));
  }

  /// The lowest rule level that finishes the board, or null when the rules run
  /// out. Not shown on the card: the number is a fact about the deal, not a
  /// thing the player can act on.
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
