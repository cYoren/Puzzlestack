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
    this.hintValue,
  });

  final BoatsPuzzle puzzle;

  /// Per cell: 0 untouched, [kBoatShip] or [kBoatWater].
  final List<int> marks;

  final BoatsSize size;
  final bool isSolved;

  /// A cell the hint has proved, and what it should be.
  final int? hintCell;
  final int? hintValue;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  int get ships => marks.where((mark) => mark == kBoatShip).length;

  BoatsState copyWith({
    List<int>? marks,
    bool? isSolved,
    int? hintCell,
    int? hintValue,
    bool clearHint = false,
  }) {
    return BoatsState(
      puzzle: puzzle,
      marks: marks ?? this.marks,
      size: size,
      isSolved: isSolved ?? this.isSolved,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
      hintValue: clearHint ? null : (hintValue ?? this.hintValue),
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
        marks: List<int>.filled(size.rows * size.cols, 0),
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
    marks[cell] = switch (marks[cell]) {
      0 => kBoatShip,
      kBoatShip => kBoatWater,
      _ => 0,
    };
    final next = state.copyWith(marks: marks, clearHint: true);
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, marks));
  }

  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.marks);
    if (found == null) return;
    state = state.copyWith(hintCell: found.cell, hintValue: found.value);
  }

  int? get level => _engine.levelOf(state.puzzle);

  /// Drops the answer.
  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      marks: List<int>.from(state.puzzle.solution),
      isSolved: true,
      clearHint: true,
    );
  }
}
