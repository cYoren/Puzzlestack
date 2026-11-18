import 'dart:math' as math;

enum TapaCellState { empty, white, black }

class TapaCell {
  final int row;
  final int col;
  final List<int>? clues; // e.g. [1, 3] or [2]
  TapaCellState state;

  TapaCell({
    required this.row,
    required this.col,
    this.clues,
    this.state = TapaCellState.empty,
  });

  bool get isClue => clues != null && clues!.isNotEmpty;
}

class TapaPuzzle {
  final int size;
  final List<List<TapaCell>> grid;
  final List<List<bool>> solutionBlack;

  TapaPuzzle({
    required this.size,
    required this.grid,
    required this.solutionBlack,
  });
}

class TapaEngine {
  static const int defaultSize = 5;

  static TapaPuzzle generatePuzzle({int size = defaultSize, math.Random? random}) {
    final rng = random ?? math.Random();
    
    // Create valid continuous wall without 2x2 blocks
    while (true) {
      final isBlack = List.generate(size, (_) => List.generate(size, (_) => false));
      
      // Start a random path wall
      int startR = rng.nextInt(size);
      int startC = rng.nextInt(size);
      isBlack[startR][startC] = true;
      int wallSize = 1;
      final targetWallSize = (size * size * 0.45).round();

      int attempts = 0;
      while (wallSize < targetWallSize && attempts < 300) {
        attempts++;
        final r = rng.nextInt(size);
        final c = rng.nextInt(size);
        if (isBlack[r][c]) continue;

        // Must connect to existing wall
        bool adjacentToWall = false;
        if (r > 0 && isBlack[r - 1][c]) adjacentToWall = true;
        if (r < size - 1 && isBlack[r + 1][c]) adjacentToWall = true;
        if (c > 0 && isBlack[r][c - 1]) adjacentToWall = true;
        if (c < size - 1 && isBlack[r][c + 1]) adjacentToWall = true;
        if (!adjacentToWall) continue;

        // Check if adding this creates a 2x2
        isBlack[r][c] = true;
        if (_has2x2(isBlack, size)) {
          isBlack[r][c] = false;
          continue;
        }

        wallSize++;
      }

      if (wallSize < (size * size * 0.40).round()) continue;
      if (!_isSingleConnectedWall(isBlack, size, wallSize)) continue;

      // Extract clues for non-wall cells
      final nonWallCells = <List<int>>[];
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          if (!isBlack[r][c]) {
            nonWallCells.add([r, c]);
          }
        }
      }

      nonWallCells.shuffle(rng);
      final minClues = (size * 1.6).round().clamp(1, nonWallCells.length);
      final clueGrid = List.generate(
        size,
        (r) => List<List<int>?>.filled(size, null),
      );
      int clueCount = 0;
      for (final coord in nonWallCells) {
        if (clueCount >= minClues) break;
        final cr = coord[0], cc = coord[1];
        clueGrid[cr][cc] = _calculateTapaClues(isBlack, size, cr, cc);
        clueCount++;
      }

      // Build grid with current clues and tighten until unique if needed.
      List<List<TapaCell>> buildGrid() => List.generate(size, (r) {
            return List.generate(size, (c) {
              final clues = clueGrid[r][c];
              return TapaCell(
                row: r,
                col: c,
                clues: clues,
                state: clues != null ? TapaCellState.white : TapaCellState.empty,
              );
            });
          });

      var grid = buildGrid();
      if (countSolutions(grid, size, limit: 2) != 1) {
        // Add extra non-wall clues until unique (fast on 5x5).
        bool unique = false;
        for (int i = clueCount; i < nonWallCells.length; i++) {
          final coord = nonWallCells[i];
          clueGrid[coord[0]][coord[1]] =
              _calculateTapaClues(isBlack, size, coord[0], coord[1]);
          grid = buildGrid();
          if (countSolutions(grid, size, limit: 2) == 1) {
            unique = true;
            break;
          }
        }
        if (!unique) continue;

        // Prune redundant clues down to minimal unique set.
        final activeCoords = [
          for (int r = 0; r < size; r++)
            for (int c = 0; c < size; c++)
              if (clueGrid[r][c] != null) (r, c),
        ]..shuffle(rng);
        for (final (r, c) in activeCoords) {
          final saved = clueGrid[r][c];
          clueGrid[r][c] = null;
          if (countSolutions(buildGrid(), size, limit: 2) != 1) {
            clueGrid[r][c] = saved;
          }
        }
        grid = buildGrid();
      }

      return TapaPuzzle(
        size: size,
        grid: grid,
        solutionBlack: isBlack,
      );
    }
  }

  /// Counts valid Tapa solutions up to [limit].
  static int countSolutions(
    List<List<TapaCell>> grid,
    int size, {
    int limit = 2,
  }) {
    const offsets = [
      (-1, -1),
      (-1, 0),
      (-1, 1),
      (0, 1),
      (1, 1),
      (1, 0),
      (1, -1),
      (0, -1),
    ];

    final isClue = List.generate(
      size,
      (r) => List.generate(size, (c) => grid[r][c].isClue),
    );
    // -1 = undecided, 0 = white, 1 = black
    final state = List.generate(
      size,
      (r) => List.generate(size, (c) => isClue[r][c] ? 0 : -1),
    );
    final unknownCells = <(int r, int c)>[
      for (int r = 0; r < size; r++)
        for (int c = 0; c < size; c++)
          if (!isClue[r][c]) (r, c),
    ];

    // Collect clues and the neighboring cells that determine them.
    final clueNodes = <(int r, int c, List<int> target)>[];
    final cellClues = List.generate(size * size, (_) => <int>[]);
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final clues = grid[r][c].clues;
        if (clues != null && clues.isNotEmpty) {
          final cid = clueNodes.length;
          clueNodes.add((r, c, clues));
          for (final (dr, dc) in offsets) {
            final nr = r + dr, nc = c + dc;
            if (nr >= 0 && nr < size && nc >= 0 && nc < size && !isClue[nr][nc]) {
              cellClues[nr * size + nc].add(cid);
            }
          }
        }
      }
    }

    bool clueConsistent(int cid) {
      final (cr, cc, target) = clueNodes[cid];
      final targetSum = target.length == 1 && target[0] == 0
          ? 0
          : target.reduce((a, b) => a + b);
      int blacks = 0;
      int unknowns = 0;
      for (final (dr, dc) in offsets) {
        final nr = cr + dr, nc = cc + dc;
        if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
          final st = state[nr][nc];
          if (st == 1) blacks++;
          if (st == -1) unknowns++;
        }
      }
      if (blacks > targetSum || blacks + unknowns < targetSum) return false;
      if (unknowns == 0) {
        final isBlack = List.generate(
          size,
          (r) => List.generate(size, (c) => state[r][c] == 1),
        );
        final actual = _calculateTapaClues(isBlack, size, cr, cc);
        if (actual.length != target.length) return false;
        for (int i = 0; i < target.length; i++) {
          if (actual[i] != target[i]) return false;
        }
      }
      return true;
    }

    for (int cid = 0; cid < clueNodes.length; cid++) {
      if (!clueConsistent(cid)) return 0;
    }

    bool makes2x2(int r, int c) {
      for (final (dr, dc) in const [(-1, -1), (-1, 0), (0, -1), (0, 0)]) {
        final r0 = r + dr, c0 = c + dc;
        if (r0 < 0 || r0 + 1 >= size || c0 < 0 || c0 + 1 >= size) continue;
        if (state[r0][c0] == 1 &&
            state[r0 + 1][c0] == 1 &&
            state[r0][c0 + 1] == 1 &&
            state[r0 + 1][c0 + 1] == 1) {
          return true;
        }
      }
      return false;
    }

    int solutions = 0;

    void search(int idx, int blackCount) {
      if (solutions >= limit) return;
      if (idx == unknownCells.length) {
        if (blackCount == 0) return;
        final isBlack = List.generate(
          size,
          (r) => List.generate(size, (c) => state[r][c] == 1),
        );
        if (_isSingleConnectedWall(isBlack, size, blackCount)) {
          solutions++;
        }
        return;
      }

      final (r, c) = unknownCells[idx];
      final cids = cellClues[r * size + c];

      // Try black (1)
      state[r][c] = 1;
      if (!makes2x2(r, c)) {
        bool ok = true;
        for (final cid in cids) {
          if (!clueConsistent(cid)) {
            ok = false;
            break;
          }
        }
        if (ok) search(idx + 1, blackCount + 1);
      }

      // Try white (0)
      if (solutions < limit) {
        state[r][c] = 0;
        bool ok = true;
        for (final cid in cids) {
          if (!clueConsistent(cid)) {
            ok = false;
            break;
          }
        }
        if (ok) search(idx + 1, blackCount);
      }

      state[r][c] = -1;
    }

    search(0, 0);
    return solutions;
  }

  static bool _has2x2(List<List<bool>> isBlack, int size) {
    for (int r = 0; r < size - 1; r++) {
      for (int c = 0; c < size - 1; c++) {
        if (isBlack[r][c] && isBlack[r + 1][c] && isBlack[r][c + 1] && isBlack[r + 1][c + 1]) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _isSingleConnectedWall(List<List<bool>> isBlack, int size, int totalBlack) {
    int startR = -1;
    int startC = -1;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (isBlack[r][c]) {
          startR = r;
          startC = c;
          break;
        }
      }
      if (startR != -1) break;
    }
    if (startR == -1) return false;

    final visited = List.generate(size, (_) => List.generate(size, (_) => false));
    final queue = <List<int>>[[startR, startC]];
    visited[startR][startC] = true;
    int count = 0;

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      count++;
      final cr = curr[0];
      final cc = curr[1];

      final neighbors = [
        [cr - 1, cc],
        [cr + 1, cc],
        [cr, cc - 1],
        [cr, cc + 1],
      ];

      for (final n in neighbors) {
        final nr = n[0];
        final nc = n[1];
        if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
          if (isBlack[nr][nc] && !visited[nr][nc]) {
            visited[nr][nc] = true;
            queue.add([nr, nc]);
          }
        }
      }
    }

    return count == totalBlack;
  }

  static List<int> _calculateTapaClues(List<List<bool>> isBlack, int size, int r, int c) {
    // 8 neighbors in clockwise order starting from top-left
    final neighborOffsets = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, 1],
      [1, 1], [1, 0], [1, -1],
      [0, -1]
    ];

    final neighborBits = <bool>[];
    for (final offset in neighborOffsets) {
      final nr = r + offset[0];
      final nc = c + offset[1];
      if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
        neighborBits.add(isBlack[nr][nc]);
      } else {
        neighborBits.add(false);
      }
    }

    // Count consecutive true blocks around the loop
    final blocks = <int>[];
    int currentRun = 0;
    for (int i = 0; i < neighborBits.length; i++) {
      if (neighborBits[i]) {
        currentRun++;
      } else {
        if (currentRun > 0) {
          blocks.add(currentRun);
          currentRun = 0;
        }
      }
    }
    if (currentRun > 0) {
      // Connect wrap around if first and last are true
      if (blocks.isNotEmpty && neighborBits[0]) {
        blocks[0] += currentRun;
      } else {
        blocks.add(currentRun);
      }
    }

    if (blocks.isEmpty) return [0];
    blocks.sort();
    return blocks;
  }

  static bool isSolved(List<List<TapaCell>> grid, int size) {
    int blackCount = 0;
    final isBlack = List.generate(size, (r) => List.generate(size, (c) => false));

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c].state == TapaCellState.black) {
          if (grid[r][c].isClue) return false;
          isBlack[r][c] = true;
          blackCount++;
        }
      }
    }

    if (blackCount == 0) return false;
    if (_has2x2(isBlack, size)) return false;
    if (!_isSingleConnectedWall(isBlack, size, blackCount)) return false;

    // Check all clues
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final clues = grid[r][c].clues;
        if (clues != null && clues.isNotEmpty) {
          final actualClues = _calculateTapaClues(isBlack, size, r, c);
          if (actualClues.length != clues.length) return false;
          for (int i = 0; i < clues.length; i++) {
            if (actualClues[i] != clues[i]) return false;
          }
        }
      }
    }

    return true;
  }
}
