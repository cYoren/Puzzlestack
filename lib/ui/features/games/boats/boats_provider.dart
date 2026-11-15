import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'boats_engine.dart';

part 'boats_provider.g.dart';

@immutable
class BoatsState extends PuzzleState {
  const BoatsState({
    required this.puzzle,
    required this.marks,
    required this.size,
    this.isSolved = false,
    this.hintCell,
  });

  final BoatsPuzzle puzzle;

  /// Per cell: [kMarkEmpty], [kMarkWater] or [kMarkShip]. Untouched is its own
  /// state, not water.
  final List<int> marks;

  final BoatsSize size;
  final bool isSolved;

  /// The cell the hint just proved and wrote.
  final int? hintCell;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  int get ships => marks.where((mark) => mark == kMarkShip).length;

  BoatsState copyWith({
    List<int>? marks,
    bool? isSolved,
    int? hintCell,
    bool clearHint = false,
  }) {
    return BoatsState(
      puzzle: puzzle,
      marks: marks ?? this.marks,
      size: size,
      isSolved: isSolved ?? this.isSolved,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
    );
  }
}

@riverpod
class BoatsNotifier extends _$BoatsNotifier {
  final BoatsEngine _engine = const BoatsEngine();

  @override
  BoatsState build() => _newPuzzle(BoatsSize.small);

  BoatsState _newPuzzle(BoatsSize size) => BoatsState(
        puzzle: _engine.generate(size),
        marks: List<int>.filled(size.rows * size.cols, kMarkEmpty),
        size: size,
      );

  void newGame() => state = _newPuzzle(state.size);

  void setSize(BoatsSize size) {
    if (size == state.size) return;
    state = _newPuzzle(size);
  }

  /// Tap cycles untouched → boat → water → untouched.
  ///
  /// The whole game is playable by tapping, which is what a card in the feed
  /// needs: no drag, no long press, no two-finger anything.
  void cycle(int cell) {
    if (state.isSolved) return;
    final marks = [...state.marks];
    marks[cell] = nextMark(marks[cell]);
    final next = state.copyWith(marks: marks, clearHint: true);
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, marks));
  }

  /// Writes one cell the rules have proved.
  ///
  /// It *applies* the mark rather than outlining the cell. The engine returns
  /// boat or water, and an outline cannot say which: a player who had marked a
  /// boat on open water pressed hint and saw the same outline again, learning
  /// nothing. Applying also means the next hint is about a different cell, so
  /// hinting makes progress instead of repeating itself.
  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.marks);
    if (found == null) return;
    final marks = [...state.marks];
    marks[found.cell] = found.value;
    final next = state.copyWith(marks: marks, hintCell: found.cell);
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, marks));
  }

  int? get level => _engine.levelOf(state.puzzle);

  /// Drops the answer.
  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      marks: [
        for (final value in state.puzzle.solution) markOfSolution(value),
      ],
      isSolved: true,
      clearHint: true,
    );
  }
}
