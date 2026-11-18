import 'dart:math';

class SudokuEngine {
  static const int size = 9;
  static const int boxSize = 3;

  SudokuEngine({this.boardSize = size, Random? random})
      : _random = random ?? Random();

  final int boardSize;
  final Random _random;

  List<List<int>> generateBoard() {
    final List<List<int>> board =
        List.generate(boardSize, (_) => List.filled(boardSize, 0));
    _fillBoard(board);
    return board;
  }

  static List<List<int>> generateFullBoard([dynamic params]) {
    if (params is Map) {
      final int sz = (params['size'] as int?) ?? size;
      final int? seed = params['seed'] as int?;
      return SudokuEngine(
        boardSize: sz,
        random: seed == null ? null : Random(seed),
      ).generateBoard();
    }
    return SudokuEngine().generateBoard();
  }

  static List<List<int>> generateInitialPuzzle(Map<String, dynamic> params) {
    final solved = params['solved'] as List<List<int>>;
    final clues = params['clues'] as int;
    final int? seed = params['seed'] as int?;
    return SudokuEngine(
      boardSize: solved.length,
      random: seed == null ? null : Random(seed),
    ).createPuzzle(solved, clues);
  }

  bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (board[row][col] == 0) {
          final List<int> numbers =
              List.generate(boardSize, (i) => i + 1)..shuffle(_random);
          for (final int num in numbers) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              if (_fillBoard(board)) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool isValid(dynamic board, int row, int col, int num) {
    final int n = board.length as int;
    final int b = n == 4 ? 2 : 3;
    for (int i = 0; i < n; i++) {
      if (i != col && board[row][i] == num) return false;
    }
    for (int i = 0; i < n; i++) {
      if (i != row && board[i][col] == num) return false;
    }
    final int boxRow = (row ~/ b) * b;
    final int boxCol = (col ~/ b) * b;
    for (int i = 0; i < b; i++) {
      for (int j = 0; j < b; j++) {
        final int r = boxRow + i;
        final int c = boxCol + j;
        if ((r != row || c != col) && board[r][c] == num) return false;
      }
    }
    return true;
  }

  bool _isValid(dynamic board, int row, int col, int num) {
    return SudokuEngine.isValid(board, row, col, num);
  }

  List<List<int>> createPuzzle(List<List<int>> solvedBoard, int clues) {
    final List<List<int>> puzzle =
        List.generate(boardSize, (r) => List<int>.from(solvedBoard[r]));
    final int totalCells = boardSize * boardSize;
    final int minClues = boardSize == 4 ? 4 : 17;
    int toRemove = (totalCells - clues).clamp(0, totalCells - minClues);

    final List<List<int>> candidates = [];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        candidates.add([r, c]);
      }
    }
    candidates.shuffle(_random);

    int removed = 0;
    for (final candidate in candidates) {
      if (removed >= toRemove) break;
      final int r = candidate[0];
      final int c = candidate[1];
      if (puzzle[r][c] == 0) continue;

      final int backup = puzzle[r][c];
      puzzle[r][c] = 0;

      if (_countSolutions(puzzle) == 1) {
        removed++;
      } else {
        puzzle[r][c] = backup;
      }
    }
    return puzzle;
  }

  int _countSolutions(List<List<int>> board) {
    return _solve(board, 0);
  }

  int _solve(List<List<int>> board, int count) {
    if (count > 1) return count;

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (board[row][col] == 0) {
          for (int num = 1; num <= boardSize; num++) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              count = _solve(board, count);
              board[row][col] = 0;
              if (count > 1) return count;
            }
          }
          return count;
        }
      }
    }
    return count + 1;
  }

  bool isComplete(List<List<int>> board) {
    final int n = board.length;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (board[r][c] == 0) return false;
      }
    }
    return true;
  }

  bool isCorrect(List<List<int>> board, List<List<int>> solvedBoard) {
    if (!isComplete(board)) return false;

    final int n = board.length;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final int val = board[r][c];
        if (val < 1 || val > n) return false;
        if (!SudokuEngine.isValid(board, r, c, val)) return false;
      }
    }
    return true;
  }
}
