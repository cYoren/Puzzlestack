import 'dart:math';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../providers/game_tier_provider.dart';
import '../../../core/board/puzzle_board.dart';
import '../../feed/feed_session.dart';
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
  static const int feedBoardSize = 4;
  static const int feedClues = 8;
  static const int stackClues = 35;

  @override
  Future<SudokuState> build() async {
    ref.watch(tierRevisionProvider('sudoku'));
    return _generateNewGame();
  }

  Future<SudokuState> _generateNewGame() async {
    final bool inFeed = FeedSession.inFeed;
    final int? seed = FeedSession.seedOf('sudoku');
    if (inFeed) {
      final engine = SudokuEngine(
        boardSize: feedBoardSize,
        random: seed == null ? null : Random(seed),
      );
      final solved = engine.generateBoard();
      final puzzle = engine.createPuzzle(solved, feedClues);
      return SudokuState(
        initialBoard: puzzle.map((r) => r.lock).toIList(),
        currentBoard: puzzle.map((r) => r.lock).toIList(),
        solvedBoard: solved.map((r) => r.lock).toIList(),
      );
    }

    final solved = await compute(SudokuEngine.generateFullBoard, {
      'size': boardSize,
      'seed': seed,
    });
    final puzzle = await compute(SudokuEngine.generateInitialPuzzle, {
      'solved': solved,
      'clues': stackClues,
      'seed': seed == null ? null : seed ^ 0x5A17,
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
    return SudokuEngine(boardSize: board.length).isCorrect(board, board);
  }

  /// Reveals one deducible step (preferring a cell with the fewest legal
  /// candidates) and selects that cell.
  void hint() {
    if (!state.hasValue) return;
    final current = state.value!;
    if (current.isSolved) return;

    final int n = current.currentBoard.length;
    int? bestRow;
    int? bestCol;
    int bestCandidates = n + 1;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (current.initialBoard[r][c] != 0) continue;
        final int val = current.currentBoard[r][c];
        final int answer = current.solvedBoard[r][c];
        if (val == answer) continue;
        int candidates = 0;
        for (int d = 1; d <= n; d++) {
          if (SudokuEngine.isValid(current.currentBoard, r, c, d)) {
            candidates++;
          }
        }
        if (candidates < bestCandidates) {
          bestCandidates = candidates;
          bestRow = r;
          bestCol = c;
          if (candidates <= 1) break;
        }
      }
      if (bestCandidates <= 1 && bestRow != null) break;
    }

    if (bestRow == null || bestCol == null) return;
    final nextBoard = [
      for (final line in current.currentBoard) line.toList(),
    ];
    nextBoard[bestRow][bestCol] = current.solvedBoard[bestRow][bestCol];
    final nextState = current.copyWith(
      currentBoard: nextBoard.map((r) => r.lock).toIList(),
      selectedRow: bestRow,
      selectedCol: bestCol,
    );
    state = AsyncValue.data(
      nextState.copyWith(isSolved: _isSolved(nextState)),
    );
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
