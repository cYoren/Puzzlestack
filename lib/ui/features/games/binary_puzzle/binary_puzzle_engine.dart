import 'dart:math';

class BinaryPuzzleBoard {
  final int size;
  final List<List<int?>> grid; // null for empty, 0 or 1

  BinaryPuzzleBoard({
    required this.size,
    required this.grid,
  });
}

class BinaryPuzzleEngine {
  final Random _random;

  BinaryPuzzleEngine([Random? random]) : _random = random ?? Random();

  BinaryPuzzleBoard generateBoard({int size = 6}) {
    List<List<int>> solution = _generateFullGrid(size);
    List<List<int?>> grid = _createPuzzle(solution, size);

    return BinaryPuzzleBoard(
      size: size,
      grid: grid,
    );
  }

  List<List<int>> _generateFullGrid(int size) {
    for (int attempt = 0; attempt < 1000; attempt++) {
      List<List<int>> grid = List.generate(size, (_) => List.filled(size, -1));
      if (_fillGrid(grid, 0, 0, size)) {
        if (_isFinalValid(grid, size)) {
          return grid;
        }
      }
    }
    // Fallback or throw if it fails too many times, 
    // but for 6x6 it should find one very quickly.
    return List.generate(size, (r) => List.generate(size, (c) => (r + c) % 2));
  }

  bool _fillGrid(List<List<int>> grid, int row, int col, int size) {
    if (row == size) return true;

    int nextRow = col == size - 1 ? row + 1 : row;
    int nextCol = col == size - 1 ? 0 : col + 1;

    List<int> values = [0, 1]..shuffle(_random);

    for (int val in values) {
      if (_isValidPlacement(grid, row, col, val, size)) {
        grid[row][col] = val;
        if (_fillGrid(grid, nextRow, nextCol, size)) return true;
        grid[row][col] = -1;
      }
    }

    return false;
  }

  bool _isValidPlacement(List<List<int>> grid, int row, int col, int val, int size) {
    // Rule 1: No more than two same adjacent
    if (col >= 2 && grid[row][col - 1] == val && grid[row][col - 2] == val) return false;
    if (row >= 2 && grid[row - 1][col] == val && grid[row - 2][col] == val) return false;
    // Also check ahead if we are validating a full grid (though in fillGrid we only check behind)
    if (col < size - 2 && grid[row][col + 1] == val && grid[row][col + 2] == val) return false;
    if (row < size - 2 && grid[row + 1][col] == val && grid[row + 2][col] == val) return false;
    // Check sandwich
    if (col > 0 && col < size - 1 && grid[row][col - 1] == val && grid[row][col + 1] == val) return false;
    if (row > 0 && row < size - 1 && grid[row - 1][col] == val && grid[row + 1][col] == val) return false;

    // Rule 2: Equal number of 0s and 1s
    int count0 = 0;
    int count1 = 0;
    for (int c = 0; c < size; c++) {
      if (grid[row][c] == 0) count0++;
      if (grid[row][c] == 1) count1++;
    }
    if (val == 0 && count0 >= size / 2) return false;
    if (val == 1 && count1 >= size / 2) return false;

    count0 = 0;
    count1 = 0;
    for (int r = 0; r < size; r++) {
      if (grid[r][col] == 0) count0++;
      if (grid[r][col] == 1) count1++;
    }
    if (val == 0 && count0 >= size / 2) return false;
    if (val == 1 && count1 >= size / 2) return false;

    // Rule 3: Uniqueness of rows and columns (only when nearly complete)
    // This is actually better checked after a row/col is finished.
    return true;
  }

  List<List<int?>> _createPuzzle(List<List<int>> solution, int size) {
    final puzzle = List.generate(
      size,
      (r) => List<int?>.generate(size, (c) => solution[r][c]),
    );

    final cells = <Point<int>>[
      for (int r = 0; r < size; r++)
        for (int c = 0; c < size; c++) Point(c, r),
    ]..shuffle(_random);

    final targetClues = (size * size * 0.4).toInt() + _random.nextInt(size);
    int remaining = size * size;
    for (final cell in cells) {
      if (remaining <= targetClues) break;
      final saved = puzzle[cell.y][cell.x];
      puzzle[cell.y][cell.x] = null;
      if (countSolutions(puzzle, size, limit: 2) != 1) {
        puzzle[cell.y][cell.x] = saved;
      } else {
        remaining--;
      }
    }

    return puzzle;
  }

  /// Counts valid Binary Puzzle solutions up to [limit].
  static int countSolutions(
    List<List<int?>> initialGrid,
    int size, {
    int limit = 2,
  }) {
    final half = size ~/ 2;
    final grid = [
      for (int r = 0; r < size; r++)
        [for (int c = 0; c < size; c++) initialGrid[r][c] ?? -1],
    ];
    final row0 = List<int>.filled(size, 0);
    final row1 = List<int>.filled(size, 0);
    final col0 = List<int>.filled(size, 0);
    final col1 = List<int>.filled(size, 0);
    final empty = <(int r, int c)>[];

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final v = grid[r][c];
        if (v == 0) {
          row0[r]++;
          col0[c]++;
        } else if (v == 1) {
          row1[r]++;
          col1[c]++;
        } else {
          empty.add((r, c));
        }
      }
    }

    // Check prefilled legality.
    for (int i = 0; i < size; i++) {
      if (row0[i] > half || row1[i] > half) return 0;
      if (col0[i] > half || col1[i] > half) return 0;
    }

    bool canPlace(int r, int c, int v) {
      if (v == 0 && (row0[r] >= half || col0[c] >= half)) return false;
      if (v == 1 && (row1[r] >= half || col1[c] >= half)) return false;

      if (c >= 2 && grid[r][c - 1] == v && grid[r][c - 2] == v) return false;
      if (c < size - 2 && grid[r][c + 1] == v && grid[r][c + 2] == v) {
        return false;
      }
      if (c > 0 && c < size - 1 && grid[r][c - 1] == v && grid[r][c + 1] == v) {
        return false;
      }

      if (r >= 2 && grid[r - 1][c] == v && grid[r - 2][c] == v) return false;
      if (r < size - 2 && grid[r + 1][c] == v && grid[r + 2][c] == v) {
        return false;
      }
      if (r > 0 && r < size - 1 && grid[r - 1][c] == v && grid[r + 1][c] == v) {
        return false;
      }

      // Check row uniqueness once completing row r.
      if (row0[r] + row1[r] + 1 == size) {
        for (int rr = 0; rr < size; rr++) {
          if (rr == r || row0[rr] + row1[rr] != size) continue;
          bool same = true;
          for (int cc = 0; cc < size; cc++) {
            final cur = cc == c ? v : grid[r][cc];
            if (grid[rr][cc] != cur) {
              same = false;
              break;
            }
          }
          if (same) return false;
        }
      }

      // Check col uniqueness once completing col c.
      if (col0[c] + col1[c] + 1 == size) {
        for (int cc = 0; cc < size; cc++) {
          if (cc == c || col0[cc] + col1[cc] != size) continue;
          bool same = true;
          for (int rr = 0; rr < size; rr++) {
            final cur = rr == r ? v : grid[rr][c];
            if (grid[rr][cc] != cur) {
              same = false;
              break;
            }
          }
          if (same) return false;
        }
      }
      return true;
    }

    int solutions = 0;

    void search(int solvedCount) {
      if (solutions >= limit) return;
      if (solvedCount == empty.length) {
        solutions++;
        return;
      }

      int bestR = -1, bestC = -1, bestCount = 3, bestMask = 0;
      for (final (r, c) in empty) {
        if (grid[r][c] != -1) continue;
        int mask = 0;
        int count = 0;
        if (canPlace(r, c, 0)) {
          mask |= 1;
          count++;
        }
        if (canPlace(r, c, 1)) {
          mask |= 2;
          count++;
        }
        if (count == 0) return;
        if (count < bestCount) {
          bestCount = count;
          bestR = r;
          bestC = c;
          bestMask = mask;
          if (count == 1) break;
        }
      }

      for (int v = 0; v <= 1; v++) {
        if (solutions >= limit) return;
        if ((bestMask & (1 << v)) == 0) continue;
        grid[bestR][bestC] = v;
        if (v == 0) {
          row0[bestR]++;
          col0[bestC]++;
        } else {
          row1[bestR]++;
          col1[bestC]++;
        }
        search(solvedCount + 1);
        if (v == 0) {
          row0[bestR]--;
          col0[bestC]--;
        } else {
          row1[bestR]--;
          col1[bestC]--;
        }
        grid[bestR][bestC] = -1;
      }
    }

    search(0);
    return solutions;
  }

  bool _isFinalValid(List<List<int>> grid, int size) {
    // Check all rows and columns are unique
    for (int i = 0; i < size; i++) {
      for (int j = i + 1; j < size; j++) {
        // Rows
        bool rowSame = true;
        for (int k = 0; k < size; k++) {
          if (grid[i][k] != grid[j][k]) {
            rowSame = false;
            break;
          }
        }
        if (rowSame) return false;

        // Cols
        bool colSame = true;
        for (int k = 0; k < size; k++) {
          if (grid[k][i] != grid[k][j]) {
            colSame = false;
            break;
          }
        }
        if (colSame) return false;
      }
    }
    return true;
  }

  List<List<bool>> getInvalidCells(List<List<int?>> grid, int size) {
    List<List<bool>> invalid = List.generate(size, (_) => List.filled(size, false));

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size - 2; c++) {
        final val = grid[r][c];
        if (val != null && grid[r][c + 1] == val && grid[r][c + 2] == val) {
          invalid[r][c] = true;
          invalid[r][c + 1] = true;
          invalid[r][c + 2] = true;
        }
      }
    }

    for (int c = 0; c < size; c++) {
      for (int r = 0; r < size - 2; r++) {
        final val = grid[r][c];
        if (val != null && grid[r + 1][c] == val && grid[r + 2][c] == val) {
          invalid[r][c] = true;
          invalid[r + 1][c] = true;
          invalid[r + 2][c] = true;
        }
      }
    }

    int half = size ~/ 2;
    for (int r = 0; r < size; r++) {
      int count0 = 0;
      int count1 = 0;
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == 0) count0++;
        if (grid[r][c] == 1) count1++;
      }
      if (count0 > half) {
        for (int c = 0; c < size; c++) {
          if (grid[r][c] == 0) invalid[r][c] = true;
        }
      }
      if (count1 > half) {
        for (int c = 0; c < size; c++) {
          if (grid[r][c] == 1) invalid[r][c] = true;
        }
      }
    }

    for (int c = 0; c < size; c++) {
      int count0 = 0;
      int count1 = 0;
      for (int r = 0; r < size; r++) {
        if (grid[r][c] == 0) count0++;
        if (grid[r][c] == 1) count1++;
      }
      if (count0 > half) {
        for (int r = 0; r < size; r++) {
          if (grid[r][c] == 0) invalid[r][c] = true;
        }
      }
      if (count1 > half) {
        for (int r = 0; r < size; r++) {
          if (grid[r][c] == 1) invalid[r][c] = true;
        }
      }
    }

    for (int i = 0; i < size; i++) {
      bool rowIFull = true;
      for (int k = 0; k < size; k++) {
        if (grid[i][k] == null) {
          rowIFull = false;
          break;
        }
      }
      if (!rowIFull) continue;

      for (int j = i + 1; j < size; j++) {
        bool rowJFull = true;
        for (int k = 0; k < size; k++) {
          if (grid[j][k] == null) {
            rowJFull = false;
            break;
          }
        }
        if (!rowJFull) continue;

        bool rowSame = true;
        for (int k = 0; k < size; k++) {
          if (grid[i][k] != grid[j][k]) {
            rowSame = false;
            break;
          }
        }
        if (rowSame) {
          for (int k = 0; k < size; k++) {
            invalid[i][k] = true;
            invalid[j][k] = true;
          }
        }
      }
    }

    for (int i = 0; i < size; i++) {
      bool colIFull = true;
      for (int k = 0; k < size; k++) {
        if (grid[k][i] == null) {
          colIFull = false;
          break;
        }
      }
      if (!colIFull) continue;

      for (int j = i + 1; j < size; j++) {
        bool colJFull = true;
        for (int k = 0; k < size; k++) {
          if (grid[k][j] == null) {
            colJFull = false;
            break;
          }
        }
        if (!colJFull) continue;

        bool colSame = true;
        for (int k = 0; k < size; k++) {
          if (grid[k][i] != grid[k][j]) {
            colSame = false;
            break;
          }
        }
        if (colSame) {
          for (int k = 0; k < size; k++) {
            invalid[k][i] = true;
            invalid[k][j] = true;
          }
        }
      }
    }

    return invalid;
  }

  bool isCompleteAndValid(List<List<int?>> grid, int size) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == null) return false;
      }
    }

    final invalid = getInvalidCells(grid, size);
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (invalid[r][c]) return false;
      }
    }

    return true;
  }
}
