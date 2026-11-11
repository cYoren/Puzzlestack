import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'dominosa_engine.dart';

part 'dominosa_provider.g.dart';

@immutable
class DominosaState extends PuzzleState {
  const DominosaState({
    required this.puzzle,
    required this.placed,
    required this.difficulty,
    this.selected,
    this.isSolved = false,
    this.hintCell,
    this.hintPartner,
  });

  final DominosaPuzzle puzzle;

  /// Cell -> the cell it is paired with, both directions. Empty when nothing
  /// is placed.
  final Map<int, int> placed;

  final DominosaDifficulty difficulty;
  final int? selected;
  final bool isSolved;

  /// A domino the hint is pointing at, and whether it is one the player got
  /// wrong (`hintPartner` set and `hintWrong` true) or one from the answer.
  final int? hintCell;
  final int? hintPartner;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  Set<int> get usedTypes {
    final out = <int>{};
    placed.forEach((cell, other) {
      if (cell < other) {
        out.add(puzzleType(cell, other));
      }
    });
    return out;
  }

  int puzzleType(int a, int b) {
    final va = puzzle.grid[a];
    final vb = puzzle.grid[b];
    return va <= vb ? va * 16 + vb : vb * 16 + va;
  }

  DominosaState copyWith({
    Map<int, int>? placed,
    int? selected,
    bool clearSelection = false,
    bool? isSolved,
    int? hintCell,
    int? hintPartner,
    bool clearHint = false,
  }) {
    return DominosaState(
      puzzle: puzzle,
      placed: placed ?? this.placed,
      difficulty: difficulty,
      selected: clearSelection ? null : (selected ?? this.selected),
      isSolved: isSolved ?? this.isSolved,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
      hintPartner: clearHint ? null : (hintPartner ?? this.hintPartner),
    );
  }
}

@riverpod
class DominosaNotifier extends _$DominosaNotifier {
  final DominosaEngine _engine = const DominosaEngine();

  @override
  DominosaState build() => _newPuzzle(DominosaDifficulty.medium);

  DominosaState _newPuzzle(DominosaDifficulty difficulty) {
    return DominosaState(
      puzzle: _engine.generate(difficulty),
      placed: const {},
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(DominosaDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  void select(int cell) {
    if (state.isSolved) return;
    state = state.copyWith(selected: cell, clearHint: true);
  }

  /// Place the domino between two adjacent free cells, or clear a placed one.
  void place(int a, int b) {
    if (state.isSolved) return;
    final placed = {...state.placed};

    if (placed[a] == b) {
      placed.remove(a);
      placed.remove(b);
      state = state.copyWith(placed: placed, clearSelection: true, clearHint: true);
      return;
    }
    if (placed.containsKey(a) || placed.containsKey(b)) return;
    if (!_engine.isAdjacent(a, b, state.cols)) return;

    final type = state.puzzleType(a, b);
    if (state.usedTypes.contains(type)) return;

    placed[a] = b;
    placed[b] = a;
    final next = state.copyWith(placed: placed, clearSelection: true, clearHint: true);
    state = next.copyWith(isSolved: placed.length == next.puzzle.cellCount);
  }

  /// One domino the player can place next, or the first one they got wrong.
  ///
  /// The board is unique, so the answer is the only covering there is; the hint
  /// may point at it without spoiling anything the player could not work out.
  void hint() {
    if (state.isSolved) return;
    final puzzle = state.puzzle;

    for (final entry in state.placed.entries) {
      if (entry.key < entry.value && puzzle.partner[entry.key] != entry.value) {
        state = state.copyWith(hintCell: entry.key, hintPartner: entry.value);
        return;
      }
    }

    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      if (state.placed.containsKey(cell)) continue;
      state = state.copyWith(hintCell: cell, hintPartner: puzzle.partner[cell]);
      return;
    }
  }
}
