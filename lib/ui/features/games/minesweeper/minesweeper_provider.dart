import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../providers/game_tier_provider.dart';
import '../../../../providers/user_providers.dart';
import '../../feed/feed_session.dart';
import 'minesweeper_engine.dart';

part 'minesweeper_provider.g.dart';

class MinesweeperState {
  final List<List<MinesweeperCell>> board;
  final bool isGameOver;
  final bool isWon;
  final int minesRemaining;
  final bool firstMove;

  MinesweeperState({
    required this.board,
    this.isGameOver = false,
    this.isWon = false,
    this.minesRemaining = 12,
    this.firstMove = true,
  });

  int get rows => board.length;
  int get cols => board.isEmpty ? 0 : board.first.length;

  MinesweeperState copyWith({
    List<List<MinesweeperCell>>? board,
    bool? isGameOver,
    bool? isWon,
    int? minesRemaining,
    bool? firstMove,
  }) {
    return MinesweeperState(
      board: board ?? this.board,
      isGameOver: isGameOver ?? this.isGameOver,
      isWon: isWon ?? this.isWon,
      minesRemaining: minesRemaining ?? this.minesRemaining,
      firstMove: firstMove ?? this.firstMove,
    );
  }
}

@riverpod
class MinesweeperNotifier extends _$MinesweeperNotifier {
  late MinesweeperEngine _engine;
  late int _activeMines;

  static const int rows = 10;
  static const int cols = 8;
  static const int totalMines = 12;

  static const int feedRows = 6;
  static const int feedCols = 6;
  static const int feedMines = 5;

  @override
  MinesweeperState build() {
    ref.watch(tierRevisionProvider('minesweeper'));
    final bool inFeed = FeedSession.inFeed;
    final int r = inFeed ? feedRows : rows;
    final int c = inFeed ? feedCols : cols;
    _activeMines = inFeed ? feedMines : totalMines;
    _engine = MinesweeperEngine(
      rows: r,
      cols: c,
      mineCount: _activeMines,
      random: FeedSession.randomFor('minesweeper'),
    );
    return MinesweeperState(
      board: _engine.generateBoard(),
      minesRemaining: _activeMines,
    );
  }

  void reset() {
    final bool inFeed = FeedSession.inFeed;
    final int r = inFeed ? feedRows : rows;
    final int c = inFeed ? feedCols : cols;
    _activeMines = inFeed ? feedMines : totalMines;
    _engine = MinesweeperEngine(
      rows: r,
      cols: c,
      mineCount: _activeMines,
      random: FeedSession.randomFor('minesweeper'),
    );
    state = MinesweeperState(
      board: _engine.generateBoard(),
      minesRemaining: _activeMines,
    );
  }

  void revealCell(int r, int c) {
    if (state.isGameOver || state.isWon) return;
    if (state.board[r][c].state != CellState.hidden) return;

    final int boardRows = state.rows;
    final int boardCols = state.cols;

    List<List<MinesweeperCell>> newBoard = List.generate(
      boardRows,
      (i) => List.generate(boardCols, (j) => state.board[i][j]),
    );

    if (state.firstMove) {
      newBoard = _engine.generateBoard(startRow: r, startCol: c);
      state = state.copyWith(firstMove: false);
    }

    if (newBoard[r][c].isMine) {
      for (final row in newBoard) {
        for (int ci = 0; ci < row.length; ci++) {
          if (row[ci].isMine) {
            row[ci] = row[ci].copyWith(state: CellState.revealed);
          }
        }
      }
      state = state.copyWith(board: newBoard, isGameOver: true);
      return;
    }

    newBoard = _engine.revealEmptyCells(newBoard, r, c);

    final isWon = _engine.checkWin(newBoard);
    state = state.copyWith(board: newBoard, isWon: isWon);

    if (isWon) {
      ref
          .read(gameStreakNotifierProvider.notifier)
          .completeGame('minesweeper', xpAmount: 30);
    }
  }

  void toggleFlag(int r, int c) {
    if (state.isGameOver || state.isWon) return;
    if (state.board[r][c].state == CellState.revealed) return;

    final int boardRows = state.rows;
    final int boardCols = state.cols;

    final newBoard = List.generate(
      boardRows,
      (i) => List.generate(boardCols, (j) => state.board[i][j]),
    );

    final currentCell = newBoard[r][c];
    int mineAdjustment = 0;

    if (currentCell.state == CellState.hidden) {
      newBoard[r][c] = currentCell.copyWith(state: CellState.flagged);
      mineAdjustment = -1;
    } else if (currentCell.state == CellState.flagged) {
      newBoard[r][c] = currentCell.copyWith(state: CellState.hidden);
      mineAdjustment = 1;
    }

    state = state.copyWith(
      board: newBoard,
      minesRemaining: state.minesRemaining + mineAdjustment,
    );
  }
}
