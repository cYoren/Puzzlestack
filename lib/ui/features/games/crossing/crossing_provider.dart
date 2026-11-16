import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'crossing_engine.dart';
import 'crossing_puzzle.dart';

part 'crossing_provider.g.dart';

@immutable
class CrossingState extends PuzzleState {
  const CrossingState({
    required this.puzzle,
    required this.values,
    required this.size,
    this.selected,
    this.isSolved = false,
    this.hintCells = const {},
  });

  final CrossingPuzzle puzzle;

  /// Per cell, what the player wrote: a digit `1..9`, or [kCrossingEmpty] for
  /// nothing yet. A wall is nothing in both senses, so it never changes.
  final List<int> values;

  final CrossingSize size;
  final int? selected;
  final bool isSolved;

  /// The cells the last hint wrote, so the board can ring them.
  final Set<int> hintCells;

  int get n => puzzle.n;

  /// Numbers the player has already written somewhere. The list under the board
  /// strikes them through: the game's progress is the list emptying, not the
  /// grid filling.
  Set<int> get satisfied => puzzle.satisfied(values);

  /// Cells the player has made impossible, for the board to paint.
  Set<int> get conflicts => puzzle.conflicts(values);

  /// Cells that hold a digit.
  int get written => values.where((value) => value != kCrossingEmpty).length;

  CrossingState copyWith({
    List<int>? values,
    int? selected,
    bool clearSelection = false,
    bool? isSolved,
    Set<int>? hintCells,
  }) {
    return CrossingState(
      puzzle: puzzle,
      values: values ?? this.values,
      size: size,
      selected: clearSelection ? null : (selected ?? this.selected),
      isSolved: isSolved ?? this.isSolved,
      hintCells: hintCells ?? this.hintCells,
    );
  }
}

@riverpod
class CrossingNotifier extends _$CrossingNotifier {
  final CrossingEngine _engine = const CrossingEngine();

  @override
  CrossingState build() => _newPuzzle(CrossingSize.small);

  /// Every cell starts empty. The board prints its list *under* the grid, so
  /// nothing in the grid is given.
  CrossingState _newPuzzle(CrossingSize size) {
    final puzzle = _engine.generate(size);
    return CrossingState(
      puzzle: puzzle,
      values: List<int>.filled(size.cellCount, kCrossingEmpty),
      size: size,
    );
  }

  void newGame() => state = _newPuzzle(state.size);

  void setSize(CrossingSize size) {
    if (size == state.size) return;
    state = _newPuzzle(size);
  }

  /// The digit one tap writes in a cell: nothing, 1, 2, ... 9, nothing.
  ///
  /// A cycle rather than a keypad, and it starts by writing a digit: the cell is
  /// empty on purpose, so tapping it to "clear" it again would look broken. Zero
  /// is the empty value here, which is why it is also where the cycle wraps.
  static int nextValue(int current) {
    if (current >= 9) return kCrossingEmpty;
    if (current < 1) return 1;
    return current + 1;
  }

  /// Cycles one cell. This is the only way a digit reaches the board.
  void tap(int cell) {
    if (state.isSolved) return;
    if (cell < 0 || cell >= state.values.length) return;
    // A wall takes no digit, so tapping one does nothing at all: the grid is the
    // runs, and the cells between them are not cells.
    if (state.puzzle.isWall(cell)) return;
    final values = [...state.values];
    values[cell] = nextValue(values[cell]);
    final next = state.copyWith(
      values: values,
      selected: cell,
      hintCells: const {},
    );
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, values));
  }

  /// Writes what the rules prove, and nothing else.
  ///
  /// The hint applies its digits rather than ringing a cell: a ring says
  /// "something is here" and the player still has to work out what, and a number
  /// the rules have placed is one step of this game, not three.
  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.values);
    if (found == null) return;
    final values = [...state.values];
    final cells = <int>{};
    for (var i = 0; i < found.cells.length; i++) {
      values[found.cells[i]] = found.digits[i];
      cells.add(found.cells[i]);
    }
    final next = state.copyWith(values: values, hintCells: cells);
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
      hintCells: const {},
      isSolved: true,
    );
  }
}
