import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';
import '../../../core/board/puzzle_board.dart';
import 'water_sort_engine.dart';

part 'water_sort_provider.g.dart';

class WaterSortState extends PuzzleState {
  const WaterSortState({
    required this.tubes,
    this.selectedTubeIndex,
    this.isSolved = false,
  });

  final List<List<Color>> tubes;
  final int? selectedTubeIndex;
  final bool isSolved;

  WaterSortState copyWith({
    List<List<Color>>? tubes,
    int? selectedTubeIndex,
    bool? isSolved,
    bool clearSelection = false,
  }) {
    return WaterSortState(
      tubes: tubes ?? this.tubes,
      selectedTubeIndex:
          clearSelection ? null : (selectedTubeIndex ?? this.selectedTubeIndex),
      isSolved: isSolved ?? this.isSolved,
    );
  }
}

@riverpod
class WaterSortNotifier extends _$WaterSortNotifier {
  final WaterSortEngine _engine = WaterSortEngine();

  @override
  WaterSortState build() {
    return WaterSortState(tubes: _engine.generateLevel());
  }

  /// The only way this state changes. The board owns the rules; this is a store.
  void applyMove(PuzzleMove<WaterSortState> move) {
    if (state.isSolved) return;
    final next = move.apply(state);
    state = next.copyWith(isSolved: _engine.isSolved(next.tubes));
  }

  void reset() {
    state = WaterSortState(tubes: _engine.generateLevel());
  }
}
