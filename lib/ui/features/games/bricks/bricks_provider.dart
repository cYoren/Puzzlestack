import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'bricks_engine.dart';

part 'bricks_provider.g.dart';

/// One tap on a cell flips it: unshaded becomes shaded, shaded becomes
/// unshaded.
///
/// Two states, not three. The C keeps an empty cell apart from a cell the
/// player has decided is white, and this port does not: the board starts with
/// every cell unshaded, and a tap is the decision. That is what "tap a cell to
/// toggle shaded/unshaded" buys — no third state to explain, and no way to
/// leave a cell undecided while the board claims to be finished.
int nextShading(int shading) =>
    shading == kBricksShaded ? kBricksUnshaded : kBricksShaded;

@immutable
class BricksState extends PuzzleState {
  const BricksState({
    required this.puzzle,
    required this.values,
    required this.size,
    this.isSolved = false,
    this.hintCell,
  });

  final BricksPuzzle puzzle;

  /// Per cell, [kBricksUnshaded] or [kBricksShaded].
  final List<int> values;

  final BricksSize size;
  final bool isSolved;
  final int? hintCell;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  int get cellCount => puzzle.cellCount;

  /// How many cells the player has shaded.
  int get shaded => puzzle.shadedIn(values);

  Set<int> get conflicts => puzzle.conflicts(values);

  BricksState copyWith({
    List<int>? values,
    bool? isSolved,
    int? hintCell,
    bool clearHint = false,
  }) {
    return BricksState(
      puzzle: puzzle,
      values: values ?? this.values,
      size: size,
      isSolved: isSolved ?? this.isSolved,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
    );
  }
}

@riverpod
class BricksNotifier extends _$BricksNotifier {
  final BricksEngine _engine = const BricksEngine();

  @override
  BricksState build() => _newPuzzle(BricksSize.small);

  BricksState _newPuzzle(BricksSize size) {
    final puzzle = _engine.generate(size);
    return BricksState(
      puzzle: puzzle,
      // Every cell starts unshaded: shading is the move, and the board is not
      // a puzzle until the player makes one.
      values: List<int>.filled(size.cellCount, kBricksUnshaded),
      size: size,
    );
  }

  void newGame() => state = _newPuzzle(state.size);

  void setSize(BricksSize size) {
    if (size == state.size) return;
    state = _newPuzzle(size);
  }

  /// A tap flips the cell. A numbered cell is fixed by rule 4, so it has no tap.
  void tap(int cell) {
    if (state.isSolved) return;
    if (state.puzzle.hasClue(cell)) return;
    final values = [...state.values];
    values[cell] = nextShading(values[cell]);
    final next = state.copyWith(values: values, clearHint: true);
    state = next.copyWith(isSolved: _engine.isSolved(next.puzzle, values));
  }

  /// Applies one shading the rules prove.
  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.values);
    if (found == null) return;
    final values = [...state.values];
    values[found.cell] = found.shading;
    final next = state.copyWith(values: values, hintCell: found.cell);
    state = next.copyWith(isSolved: _engine.isSolved(next.puzzle, values));
  }

  int? get level => _engine.levelOf(state.puzzle);

  /// Fills in the answer.
  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      values: List<int>.from(state.puzzle.solution),
      clearHint: true,
      isSolved: true,
    );
  }
}
