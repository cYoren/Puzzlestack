import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import '../../../core/board/puzzle_board.dart';
import 'sudoku_engine.dart';

part 'sudoku_provider.g.dart';

class SudokuState extends PuzzleState {
  final IList<IList<int>> initialBoard;
  final IList<IList<int>> currentBoard;
  final IList<IList<int>> solvedBoard;
  final int? selectedRow;
  final int? selectedCol;
  final bool isSolved;

  const SudokuState({
    required this.initialBoard,
    required this.currentBoard,
    required this.solvedBoard,
    this.selectedRow,
    this.selectedCol,
    this.isSolved = false,
  });

  SudokuState copyWith({
    IList<IList<int>>? currentBoard,
    int? selectedRow,
    int? selectedCol,
    bool? isSolved,
  }) {
    return SudokuState(
      initialBoard: initialBoard,
      currentBoard: currentBoard ?? this.currentBoard,
      solvedBoard: solvedBoard,
      selectedRow: selectedRow ?? this.selectedRow,
      selectedCol: selectedCol ?? this.selectedCol,
      isSolved: isSolved ?? this.isSolved,
    );
  }
}

@riverpod
class SudokuNotifier extends _$SudokuNotifier {
  static const int boardSize = 9;

  @override
  Future<SudokuState> build() async {
    return _generateNewGame();
  }

  Future<SudokuState> _generateNewGame() async {
    final solved = await compute(SudokuEngine.generateFullBoard, null);
    final puzzle = await compute(SudokuEngine.generateInitialPuzzle, {
      'solved': solved,
      'clues': 35,
    });
    
    return SudokuState(
      initialBoard: puzzle.map((r) => r.lock).toIList(),
      currentBoard: puzzle.map((r) => r.lock).toIList(),
      solvedBoard: solved.map((r) => r.lock).toIList(),
    );
  }

  Future<void> initGame() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _generateNewGame());
  }

  /// The only way this state changes. A move comes from the board, which is
  /// the only thing that knows the rules, so the notifier stays a store.
  void applyMove(PuzzleMove<SudokuState> move) {
    if (!state.hasValue) return;
    final current = state.value!;
    if (current.isSolved) return;

    final next = move.apply(current);
    state = AsyncValue.data(next.copyWith(isSolved: _isSolved(next)));
  }

  bool _isSolved(SudokuState value) {
    final board = [
      for (final line in value.currentBoard) line.toList(),
    ];
    for (final line in board) {
      if (line.contains(0)) return false;
    }
    return SudokuEngine().isCorrect(board, board);
  }

  /// Fills the board with the answer.
  void solve() {
    if (!state.hasValue) return;
    final current = state.value!;
    if (current.isSolved) return;
    state = AsyncValue.data(
      current.copyWith(
        currentBoard: current.solvedBoard,
        isSolved: true,
      ),
    );
  }
}
