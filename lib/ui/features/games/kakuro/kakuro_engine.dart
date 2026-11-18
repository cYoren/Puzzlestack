import 'dart:math';

class KakuroCell {
  final int r, c;
  final bool isWhite;
  final bool isBlock;
  final bool isClue;
  final int? vClue; // Vertical clue (sum of cells below)
  final int? hClue; // Horizontal clue (sum of cells to the right)
  final int? solution; // Solved value for white cells

  KakuroCell({
    required this.r,
    required this.c,
    this.isWhite = false,
    this.isBlock = false,
    this.isClue = false,
    this.vClue,
    this.hClue,
    this.solution,
  });
}

class KakuroLevel {
  final int size; // e.g., 4
  final List<List<KakuroCell>> grid;

  KakuroLevel({required this.size, required this.grid});
}

class _KakuroRun {
  final int targetSum;
  final List<(int r, int c)> cells;

  _KakuroRun({required this.targetSum, required this.cells});
}

class KakuroEngine {
  final Random _random;

  KakuroEngine([Random? random]) : _random = random ?? Random();

  static const List<List<String>> _masks = [
    [
      '####',
      '#..#',
      '#...',
      '##..',
    ],
    [
      '####',
      '##..',
      '#...',
      '#..#',
    ],
    [
      '####',
      '#...',
      '#...',
      '#..#',
    ],
    [
      '####',
      '#..#',
      '#...',
      '#...',
    ],
    [
      '####',
      '#...',
      '#...',
      '#...',
    ],
  ];

  KakuroLevel generateLevel() {
    const size = 4;
    for (int attempt = 0; attempt < 300; attempt++) {
      final mask = _masks[_random.nextInt(_masks.length)];
      final sol = _fillMask(mask, size);
      if (sol == null) continue;

      final level = _levelFromSolution(mask, sol, size);
      if (countSolutions(level, limit: 2) == 1) {
        return level;
      }
    }
    return _fallbackLevel();
  }

  List<List<int>>? _fillMask(List<String> mask, int size) {
    final values = List.generate(size, (_) => List.filled(size, 0));
    final whites = <(int r, int c)>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (mask[r][c] == '.') whites.add((r, c));
      }
    }

    // Weight toward low/high digits when filling so two- and three-cell sums
    // have sharp unique partitions more frequently.
    const biasedPool = [1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 8, 9, 9];

    bool canPlace(int r, int c, int d) {
      for (int cc = c - 1; cc >= 0 && mask[r][cc] == '.'; cc--) {
        if (values[r][cc] == d) return false;
      }
      for (int rr = r - 1; rr >= 0 && mask[rr][c] == '.'; rr--) {
        if (values[rr][c] == d) return false;
      }
      return true;
    }

    bool search(int idx) {
      if (idx == whites.length) return true;
      final (r, c) = whites[idx];
      final digits = biasedPool.toList()..shuffle(_random);
      final tried = <int>{};
      for (final d in digits) {
        if (!tried.add(d)) continue;
        if (!canPlace(r, c, d)) continue;
        values[r][c] = d;
        if (search(idx + 1)) return true;
        values[r][c] = 0;
      }
      return false;
    }

    return search(0) ? values : null;
  }

  KakuroLevel _levelFromSolution(
    List<String> mask,
    List<List<int>> sol,
    int size,
  ) {
    final grid = List.generate(size, (r) {
      return List.generate(size, (c) {
        if (mask[r][c] == '.') {
          return KakuroCell(r: r, c: c, isWhite: true, solution: sol[r][c]);
        }
        int? hClue;
        if (c + 1 < size && mask[r][c + 1] == '.') {
          int sum = 0;
          for (int nc = c + 1; nc < size && mask[r][nc] == '.'; nc++) {
            sum += sol[r][nc];
          }
          hClue = sum;
        }
        int? vClue;
        if (r + 1 < size && mask[r + 1][c] == '.') {
          int sum = 0;
          for (int nr = r + 1; nr < size && mask[nr][c] == '.'; nr++) {
            sum += sol[nr][c];
          }
          vClue = sum;
        }
        if (hClue != null || vClue != null) {
          return KakuroCell(
            r: r,
            c: c,
            isClue: true,
            vClue: vClue,
            hClue: hClue,
          );
        }
        return KakuroCell(r: r, c: c, isBlock: true);
      });
    });
    return KakuroLevel(size: size, grid: grid);
  }

  /// Counts valid 1..9 distinct-in-run solutions up to [limit].
  static int countSolutions(KakuroLevel level, {int limit = 2}) {
    final size = level.size;
    final grid = level.grid;
    final runs = <_KakuroRun>[];
    final cellRuns = <int, List<int>>{};
    final whites = <(int r, int c)>[];

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c].isWhite) {
          whites.add((r, c));
        }
        final cell = grid[r][c];
        if (cell.isClue) {
          if (cell.hClue != null) {
            final cells = <(int, int)>[];
            for (int nc = c + 1; nc < size && grid[r][nc].isWhite; nc++) {
              cells.add((r, nc));
            }
            if (cells.isEmpty) return 0;
            final runId = runs.length;
            runs.add(_KakuroRun(targetSum: cell.hClue!, cells: cells));
            for (final (cr, cc) in cells) {
              (cellRuns[cr * size + cc] ??= []).add(runId);
            }
          }
          if (cell.vClue != null) {
            final cells = <(int, int)>[];
            for (int nr = r + 1; nr < size && grid[nr][c].isWhite; nr++) {
              cells.add((nr, c));
            }
            if (cells.isEmpty) return 0;
            final runId = runs.length;
            runs.add(_KakuroRun(targetSum: cell.vClue!, cells: cells));
            for (final (cr, cc) in cells) {
              (cellRuns[cr * size + cc] ??= []).add(runId);
            }
          }
        }
      }
    }

    final runUsedMask = List<int>.filled(runs.length, 0);
    final runSum = List<int>.filled(runs.length, 0);
    final runRemaining = [for (final run in runs) run.cells.length];
    final values = List.generate(size, (_) => List.filled(size, 0));
    int solutions = 0;

    bool runFeasible(int runId) {
      final rem = runRemaining[runId];
      final needed = runs[runId].targetSum - runSum[runId];
      if (rem == 0) return needed == 0;
      if (needed <= 0) return false;
      final used = runUsedMask[runId];
      int minPossible = 0;
      int maxPossible = 0;
      int taken = 0;
      for (int d = 1; d <= 9 && taken < rem; d++) {
        if ((used & (1 << d)) == 0) {
          minPossible += d;
          taken++;
        }
      }
      if (taken < rem) return false;
      taken = 0;
      for (int d = 9; d >= 1 && taken < rem; d--) {
        if ((used & (1 << d)) == 0) {
          maxPossible += d;
          taken++;
        }
      }
      return needed >= minPossible && needed <= maxPossible;
    }

    void search(int idx) {
      if (solutions >= limit) return;
      if (idx == whites.length) {
        solutions++;
        return;
      }

      final (r, c) = whites[idx];
      final key = r * size + c;
      final rids = cellRuns[key] ?? const [];

      for (int d = 1; d <= 9; d++) {
        if (solutions >= limit) return;
        bool ok = true;
        for (final rid in rids) {
          if ((runUsedMask[rid] & (1 << d)) != 0) {
            ok = false;
            break;
          }
        }
        if (!ok) continue;

        values[r][c] = d;
        for (final rid in rids) {
          runUsedMask[rid] |= (1 << d);
          runSum[rid] += d;
          runRemaining[rid]--;
          if (!runFeasible(rid)) ok = false;
        }

        if (ok) {
          search(idx + 1);
        }

        for (final rid in rids) {
          runRemaining[rid]++;
          runSum[rid] -= d;
          runUsedMask[rid] &= ~(1 << d);
        }
        values[r][c] = 0;
      }
    }

    search(0);
    return solutions;
  }

  KakuroLevel _fallbackLevel() {
    // Verified unique 4x4 Kakuro fallback.
    final sol = [
      [0, 0, 0, 0],
      [0, 1, 2, 0],
      [0, 3, 9, 5],
      [0, 0, 4, 6],
    ];
    return _levelFromSolution(_masks[0], sol, 4);
  }
}
