import 'dart:math';

class TennerGridPuzzle {
  final int rows;
  final int cols;
  final List<List<int>> solution;
  final List<List<bool>> fixed;
  final List<int> colSums;

  TennerGridPuzzle({
    required this.rows,
    required this.cols,
    required this.solution,
    required this.fixed,
    required this.colSums,
  });
}

class TennerGridEngine {
  static const int defaultRows = 3;
  static const int defaultCols = 10;

  static TennerGridPuzzle generatePuzzle({
    int rows = defaultRows,
    int cols = defaultCols,
    Random? random,
  }) {
    final rng = random ?? Random();
    final solution = _generateSolution(rows, cols, rng);
    final colSums = [
      for (int c = 0; c < cols; c++)
        [for (int r = 0; r < rows; r++) solution[r][c]].reduce((a, b) => a + b),
    ];

    final fixed = List.generate(rows, (_) => List.filled(cols, true));
    final order = [
      for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++) (r, c),
    ]..shuffle(rng);

    int remainingFixed = rows * cols;
    for (final (r, c) in order) {
      if (remainingFixed <= 8) break;
      fixed[r][c] = false;
      final puzzleGrid = [
        for (int rr = 0; rr < rows; rr++)
          [
            for (int cc = 0; cc < cols; cc++)
              fixed[rr][cc] ? solution[rr][cc] : -1,
          ],
      ];
      if (countSolutions(puzzleGrid, colSums, limit: 2) != 1) {
        fixed[r][c] = true;
      } else {
        remainingFixed--;
      }
    }

    return TennerGridPuzzle(
      rows: rows,
      cols: cols,
      solution: solution,
      fixed: fixed,
      colSums: colSums,
    );
  }

  static List<List<int>> _generateSolution(int rows, int cols, Random rng) {
    final grid = <List<int>>[];
    final digits = List<int>.generate(cols, (i) => i);

    while (grid.length < rows) {
      final candidate = List<int>.from(digits)..shuffle(rng);
      if (grid.isEmpty) {
        grid.add(candidate);
        continue;
      }
      final prev = grid.last;
      bool valid = true;
      for (int c = 0; c < cols; c++) {
        for (int dc = -1; dc <= 1; dc++) {
          final nc = c + dc;
          if (nc >= 0 && nc < cols && candidate[c] == prev[nc]) {
            valid = false;
            break;
          }
        }
        if (!valid) break;
      }
      if (valid) grid.add(candidate);
    }
    return grid;
  }

  static bool isSolved(List<List<int>> grid, List<int> colSums) {
    final rows = grid.length;
    if (rows == 0) return false;
    final cols = grid[0].length;
    if (colSums.length != cols) return false;

    for (int r = 0; r < rows; r++) {
      final seen = <int>{};
      for (int c = 0; c < cols; c++) {
        final v = grid[r][c];
        if (v < 0 || v >= cols) return false;
        if (!seen.add(v)) return false;
      }
    }

    for (int c = 0; c < cols; c++) {
      int sum = 0;
      for (int r = 0; r < rows; r++) {
        sum += grid[r][c];
      }
      if (sum != colSums[c]) return false;
    }

    for (int r = 0; r < rows - 1; r++) {
      for (int c = 0; c < cols; c++) {
        final v = grid[r][c];
        for (int dc = -1; dc <= 1; dc++) {
          final nc = c + dc;
          if (nc >= 0 && nc < cols && grid[r + 1][nc] == v) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Counts valid Tenner Grid solutions up to [limit] using column-by-column MRV.
  static int countSolutions(
    List<List<int>> initialGrid,
    List<int> colSums, {
    int limit = 2,
  }) {
    final rows = initialGrid.length;
    final cols = initialGrid[0].length;
    final grid = [for (final r in initialGrid) List<int>.from(r)];
    final rowUsed = List<int>.filled(rows, 0);
    final colSumCur = List<int>.filled(cols, 0);
    final colEmpty = List<int>.filled(cols, 0);
    final emptyCells = <(int r, int c)>[];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final v = grid[r][c];
        if (v != -1) {
          if (v < 0 || v >= cols) return 0;
          if ((rowUsed[r] & (1 << v)) != 0) return 0;
          rowUsed[r] |= (1 << v);
          colSumCur[c] += v;
        } else {
          colEmpty[c]++;
          emptyCells.add((r, c));
        }
      }
    }

    // Check prefilled adjacency & sum bounds.
    for (int r = 0; r < rows - 1; r++) {
      for (int c = 0; c < cols; c++) {
        final v = grid[r][c];
        if (v == -1) continue;
        for (int dc = -1; dc <= 1; dc++) {
          final nc = c + dc;
          if (nc >= 0 && nc < cols && grid[r + 1][nc] == v) return 0;
        }
      }
    }
    for (int c = 0; c < cols; c++) {
      if (colEmpty[c] == 0 && colSumCur[c] != colSums[c]) return 0;
      if (colSumCur[c] > colSums[c]) return 0;
    }

    bool canPlace(int r, int c, int v) {
      if ((rowUsed[r] & (1 << v)) != 0) return false;
      // Column sum feasibility.
      final newSum = colSumCur[c] + v;
      final rem = colEmpty[c] - 1;
      if (rem == 0) {
        if (newSum != colSums[c]) return false;
      } else {
        if (newSum > colSums[c]) return false;
        if (newSum + rem * (cols - 1) < colSums[c]) return false;
      }
      // Adjacent rows check (up and down).
      if (r > 0) {
        for (int dc = -1; dc <= 1; dc++) {
          final nc = c + dc;
          if (nc >= 0 && nc < cols && grid[r - 1][nc] == v) return false;
        }
      }
      if (r < rows - 1) {
        for (int dc = -1; dc <= 1; dc++) {
          final nc = c + dc;
          if (nc >= 0 && nc < cols && grid[r + 1][nc] == v) return false;
        }
      }
      return true;
    }

    int solutions = 0;

    void search(int solvedCount) {
      if (solutions >= limit) return;
      if (solvedCount == emptyCells.length) {
        solutions++;
        return;
      }

      // MRV: pick unfilled cell with fewest candidates.
      int bestR = -1, bestC = -1, bestCount = 999;
      int bestMask = 0;
      for (final (r, c) in emptyCells) {
        if (grid[r][c] != -1) continue;
        int mask = 0;
        int count = 0;
        for (int v = 0; v < cols; v++) {
          if (canPlace(r, c, v)) {
            mask |= (1 << v);
            count++;
          }
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

      for (int v = 0; v < cols; v++) {
        if (solutions >= limit) return;
        if ((bestMask & (1 << v)) == 0) continue;
        grid[bestR][bestC] = v;
        rowUsed[bestR] |= (1 << v);
        colSumCur[bestC] += v;
        colEmpty[bestC]--;

        search(solvedCount + 1);

        colEmpty[bestC]++;
        colSumCur[bestC] -= v;
        rowUsed[bestR] &= ~(1 << v);
        grid[bestR][bestC] = -1;
      }
    }

    search(0);
    return solutions;
  }
}
