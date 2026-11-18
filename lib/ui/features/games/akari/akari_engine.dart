import 'dart:math';

class AkariEngine {
  final Random _random = Random();

  // Grid cell types:
  // 0-4: Numbered wall (adjacent bulb count)
  // -1: Wall without number
  // -2: White cell (placeable)

  static final List<List<List<int>>> predefinedLevels = [
    [
      [-2, -2, -1, -1, -2],
      [-2, -2, -2, -2, -2],
      [2, -2, -2, -2, -1],
      [-2, -2, -2, -2, 2],
      [-2, -2, -2, -2, -2],
    ],
    [
      [-2, 1, -2, -2, -2],
      [-2, -2, -2, 0, -2],
      [-2, 2, -2, 2, -2],
      [-2, -2, -2, -2, -2],
      [-2, -2, -2, -2, -1],
    ],
    [
      [-2, -2, -2, -2, -2],
      [-2, -2, -2, -2, 1],
      [-2, -2, -2, -2, -1],
      [-2, -2, -2, 2, -1],
      [-2, 2, -2, -2, -2],
    ],
    [
      [-1, -2, -2, -2, -2],
      [-2, -2, -2, -2, 2],
      [-2, -2, -2, -2, -2],
      [-2, -2, -2, 1, -2],
      [2, -2, -2, -2, -2],
    ],
    [
      [-2, -2, -2, -2, -2],
      [-2, -2, -2, 1, 2],
      [1, -1, -2, -2, -2],
      [-2, -2, -2, 1, -2],
      [-2, -2, -2, -2, -2],
    ],
    [
      [-2, -2, 0, -2, -2],
      [-2, -2, 1, -2, -1],
      [-2, -2, -2, -2, -2],
      [2, -2, -2, 2, -2],
      [-2, -2, -2, -2, -2],
    ],
    [
      [-2, -2, -2, -1, -1],
      [-2, -2, -2, -2, -2],
      [3, -2, -2, -2, -2],
      [-2, -1, -2, -2, -2],
      [-2, -2, 3, -2, -2],
    ],
    [
      [-2, -2, -2, -2, 2],
      [-2, -2, -2, -2, -2],
      [-2, -2, -2, -1, -2],
      [-2, 2, -2, -2, 2],
      [-2, -2, -2, -2, -2],
    ],
    [
      [-2, -2, -2, -2, -2],
      [0, -1, -2, -2, 2],
      [-2, 2, -2, -2, -1],
      [-2, -2, -2, -2, -2],
      [-2, -2, -2, -2, -2],
    ],
    [
      [-2, -2, -2, -2, -1],
      [-2, -2, -2, 3, -1],
      [-2, 2, -2, -2, -1],
      [-2, -2, -2, -2, -2],
      [-2, -2, -2, -2, -2],
    ],
  ];

  Map<String, dynamic> generateLevel({int size = 5, Random? random}) {
    final rng = random ?? _random;
    for (int attempt = 0; attempt < 80; attempt++) {
      final result = _tryGenerate(size, rng);
      if (result != null) return result;
    }
    if (size == 5) {
      final template = predefinedLevels[rng.nextInt(predefinedLevels.length)];
      final grid = template.map((r) => List<int>.from(r)).toList();
      return {'grid': grid};
    }
    return {'grid': _fallback6x6.map((r) => List<int>.from(r)).toList()};
  }

  static const List<List<int>> _fallback6x6 = [
    [-2, -2, 1, -2, -2, -2],
    [-2, -2, -2, -2, 2, -2],
    [1, -2, -2, -2, -2, -1],
    [-1, -2, -2, -2, -2, 1],
    [-2, 2, -2, -2, -2, -2],
    [-2, -2, -2, 1, -2, -2],
  ];

  Map<String, dynamic>? _tryGenerate(int size, Random rng) {
    final grid = List.generate(size, (_) => List.filled(size, -2));

    // 1. Place walls (~25% of cells), keeping at least two-thirds white.
    final wallTarget = max(3, (size * size * 0.25).round());
    final allCells = [
      for (int r = 0; r < size; r++)
        for (int c = 0; c < size; c++) [r, c],
    ]..shuffle(rng);

    for (int i = 0; i < wallTarget && i < allCells.length; i++) {
      final r = allCells[i][0];
      final c = allCells[i][1];
      grid[r][c] = -1;
    }

    // 2. Find a valid bulb placement on the walled grid.
    final solution = _findRandomBulbCover(grid, size, rng);
    if (solution == null) return null;

    // 3. Fill every wall with its exact adjacent bulb count.
    final wallCells = <List<int>>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] != -2) {
          int count = 0;
          if (r > 0 && solution[r - 1][c]) count++;
          if (r < size - 1 && solution[r + 1][c]) count++;
          if (c > 0 && solution[r][c - 1]) count++;
          if (c < size - 1 && solution[r][c + 1]) count++;
          grid[r][c] = count;
          wallCells.add([r, c]);
        }
      }
    }

    // Require unique solution even with all wall clues present.
    if (countSolutions(grid) != 1) return null;

    // 4. Prune wall numbers while keeping uniqueness.
    wallCells.shuffle(rng);
    for (final w in wallCells) {
      final r = w[0];
      final c = w[1];
      final backup = grid[r][c];
      grid[r][c] = -1;
      if (countSolutions(grid) != 1) {
        grid[r][c] = backup;
      }
    }

    return {'grid': grid};
  }

  List<List<bool>>? _findRandomBulbCover(
    List<List<int>> grid,
    int size,
    Random rng,
  ) {
    final bulbs = List.generate(size, (_) => List.filled(size, false));
    final white = <(int, int)>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == -2) white.add((r, c));
      }
    }
    white.shuffle(rng);

    // Greedy randomized backtracking on white cells: pick an unlit white cell
    // and try placing a bulb in a cell that lights it.
    bool rec() {
      (int, int)? target;
      for (final (r, c) in white) {
        if (!_isCellLit(grid, bulbs, size, r, c)) {
          target = (r, c);
          break;
        }
      }
      if (target == null) return true;

      final candidates = _lightingCandidates(grid, bulbs, size, target.$1, target.$2)
        ..shuffle(rng);
      for (final (br, bc) in candidates) {
        bulbs[br][bc] = true;
        if (rec()) return true;
        bulbs[br][bc] = false;
      }
      return false;
    }

    return rec() ? bulbs : null;
  }

  static bool _isCellLit(
    List<List<int>> grid,
    List<List<bool>> bulbs,
    int size,
    int r,
    int c,
  ) {
    if (bulbs[r][c]) return true;
    for (int j = c - 1; j >= 0 && grid[r][j] == -2; j--) {
      if (bulbs[r][j]) return true;
    }
    for (int j = c + 1; j < size && grid[r][j] == -2; j++) {
      if (bulbs[r][j]) return true;
    }
    for (int i = r - 1; i >= 0 && grid[i][c] == -2; i--) {
      if (bulbs[i][c]) return true;
    }
    for (int i = r + 1; i < size && grid[i][c] == -2; i++) {
      if (bulbs[i][c]) return true;
    }
    return false;
  }

  static List<(int, int)> _lightingCandidates(
    List<List<int>> grid,
    List<List<bool>> bulbs,
    int size,
    int r,
    int c,
  ) {
    final out = <(int, int)>[];
    bool clear(int cr, int cc) {
      if (bulbs[cr][cc]) return false;
      for (int j = cc - 1; j >= 0 && grid[cr][j] == -2; j--) {
        if (bulbs[cr][j]) return false;
      }
      for (int j = cc + 1; j < size && grid[cr][j] == -2; j++) {
        if (bulbs[cr][j]) return false;
      }
      for (int i = cr - 1; i >= 0 && grid[i][cc] == -2; i--) {
        if (bulbs[i][cc]) return false;
      }
      for (int i = cr + 1; i < size && grid[i][cc] == -2; i++) {
        if (bulbs[i][cc]) return false;
      }
      return true;
    }

    if (clear(r, c)) out.add((r, c));
    for (int j = c - 1; j >= 0 && grid[r][j] == -2; j--) {
      if (clear(r, j)) out.add((r, j));
    }
    for (int j = c + 1; j < size && grid[r][j] == -2; j++) {
      if (clear(r, j)) out.add((r, j));
    }
    for (int i = r - 1; i >= 0 && grid[i][c] == -2; i--) {
      if (clear(i, c)) out.add((i, c));
    }
    for (int i = r + 1; i < size && grid[i][c] == -2; i++) {
      if (clear(i, c)) out.add((i, c));
    }
    return out;
  }

  /// Counts solutions to [grid] up to [limit] (default 2, enough for uniqueness).
  static int countSolutions(List<List<int>> grid, {int limit = 2}) {
    final size = grid.length;
    // State per white cell: -1 = unknown, 0 = forbidden (no bulb), 1 = bulb.
    final state = List.generate(
      size,
      (r) => List<int>.generate(size, (c) => grid[r][c] == -2 ? -1 : 0),
    );
    return _searchSolutions(grid, state, size, 0, limit);
  }

  static int _searchSolutions(
    List<List<int>> grid,
    List<List<int>> state,
    int size,
    int found,
    int limit,
  ) {
    if (found >= limit) return found;

    // Save snapshot for propagation rollback.
    final saved = [for (final row in state) List<int>.from(row)];
    if (!_propagate(grid, state, size)) {
      _restore(state, saved);
      return found;
    }

    // Pick the unlit white cell with the fewest possible bulb positions (MRV).
    (int, int)? bestCell;
    List<(int, int)> bestOpts = const [];
    bool allLit = true;

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] != -2) continue;
        if (_isLitInState(grid, state, size, r, c)) continue;
        allLit = false;
        final opts = _openLighters(grid, state, size, r, c);
        if (opts.isEmpty) {
          _restore(state, saved);
          return found;
        }
        if (bestCell == null || opts.length < bestOpts.length) {
          bestCell = (r, c);
          bestOpts = opts;
          if (bestOpts.length == 1) break;
        }
      }
      if (bestCell != null && bestOpts.length == 1) break;
    }

    if (allLit) {
      // Every white cell is lit; branch on any remaining unknown white cell or
      // verify all numbered walls are satisfied.
      (int, int)? unknown;
      for (int r = 0; r < size && unknown == null; r++) {
        for (int c = 0; c < size; c++) {
          if (grid[r][c] == -2 && state[r][c] == -1) {
            unknown = (r, c);
            break;
          }
        }
      }
      if (unknown == null) {
        final ok = _wallsExact(grid, state, size);
        _restore(state, saved);
        return ok ? found + 1 : found;
      }
      final (ur, uc) = unknown;
      state[ur][uc] = 1;
      found = _searchSolutions(grid, state, size, found, limit);
      if (found < limit) {
        state[ur][uc] = 0;
        found = _searchSolutions(grid, state, size, found, limit);
      }
      _restore(state, saved);
      return found;
    }

    // Branch on the first candidate for bestCell: either bulb=1 or bulb=0.
    final (br, bc) = bestOpts.first;
    state[br][bc] = 1;
    found = _searchSolutions(grid, state, size, found, limit);
    if (found < limit) {
      state[br][bc] = 0;
      found = _searchSolutions(grid, state, size, found, limit);
    }

    _restore(state, saved);
    return found;
  }

  static void _restore(List<List<int>> state, List<List<int>> saved) {
    for (int r = 0; r < state.length; r++) {
      for (int c = 0; c < state.length; c++) {
        state[r][c] = saved[r][c];
      }
    }
  }

  static bool _propagate(List<List<int>> grid, List<List<int>> state, int size) {
    bool changed = true;
    while (changed) {
      changed = false;

      // 1. Any placed bulb forbids every visible white cell in its row/col.
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          if (state[r][c] != 1) continue;
          for (int j = c - 1; j >= 0 && grid[r][j] == -2; j--) {
            if (state[r][j] == 1) return false;
            if (state[r][j] == -1) {
              state[r][j] = 0;
              changed = true;
            }
          }
          for (int j = c + 1; j < size && grid[r][j] == -2; j++) {
            if (state[r][j] == 1) return false;
            if (state[r][j] == -1) {
              state[r][j] = 0;
              changed = true;
            }
          }
          for (int i = r - 1; i >= 0 && grid[i][c] == -2; i--) {
            if (state[i][c] == 1) return false;
            if (state[i][c] == -1) {
              state[i][c] = 0;
              changed = true;
            }
          }
          for (int i = r + 1; i < size && grid[i][c] == -2; i++) {
            if (state[i][c] == 1) return false;
            if (state[i][c] == -1) {
              state[i][c] = 0;
              changed = true;
            }
          }
        }
      }

      // 2. Numbered walls: enforce count bounds and force when exact.
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          final clue = grid[r][c];
          if (clue < 0) continue;
          int bulbs = 0;
          final open = <(int, int)>[];
          for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
            final nr = r + dr;
            final nc = c + dc;
            if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
            if (grid[nr][nc] != -2) continue;
            if (state[nr][nc] == 1) {
              bulbs++;
            } else if (state[nr][nc] == -1) {
              open.add((nr, nc));
            }
          }
          if (bulbs > clue || bulbs + open.length < clue) return false;
          if (bulbs == clue && open.isNotEmpty) {
            for (final (nr, nc) in open) {
              state[nr][nc] = 0;
            }
            changed = true;
          } else if (bulbs + open.length == clue && open.isNotEmpty) {
            for (final (nr, nc) in open) {
              state[nr][nc] = 1;
            }
            changed = true;
          }
        }
      }

      // 3. Unlit white cells with only one open lighter force that bulb.
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          if (grid[r][c] != -2) continue;
          if (_isLitInState(grid, state, size, r, c)) continue;
          final opts = _openLighters(grid, state, size, r, c);
          if (opts.isEmpty) return false;
          if (opts.length == 1) {
            final (br, bc) = opts.first;
            if (state[br][bc] == 0) return false;
            state[br][bc] = 1;
            changed = true;
          }
        }
      }
    }
    return true;
  }

  static bool _isLitInState(
    List<List<int>> grid,
    List<List<int>> state,
    int size,
    int r,
    int c,
  ) {
    if (state[r][c] == 1) return true;
    for (int j = c - 1; j >= 0 && grid[r][j] == -2; j--) {
      if (state[r][j] == 1) return true;
    }
    for (int j = c + 1; j < size && grid[r][j] == -2; j++) {
      if (state[r][j] == 1) return true;
    }
    for (int i = r - 1; i >= 0 && grid[i][c] == -2; i--) {
      if (state[i][c] == 1) return true;
    }
    for (int i = r + 1; i < size && grid[i][c] == -2; i++) {
      if (state[i][c] == 1) return true;
    }
    return false;
  }

  static List<(int, int)> _openLighters(
    List<List<int>> grid,
    List<List<int>> state,
    int size,
    int r,
    int c,
  ) {
    final opts = <(int, int)>[];
    if (state[r][c] == -1) opts.add((r, c));
    for (int j = c - 1; j >= 0 && grid[r][j] == -2; j--) {
      if (state[r][j] == -1) opts.add((r, j));
    }
    for (int j = c + 1; j < size && grid[r][j] == -2; j++) {
      if (state[r][j] == -1) opts.add((r, j));
    }
    for (int i = r - 1; i >= 0 && grid[i][c] == -2; i--) {
      if (state[i][c] == -1) opts.add((i, c));
    }
    for (int i = r + 1; i < size && grid[i][c] == -2; i++) {
      if (state[i][c] == -1) opts.add((i, c));
    }
    return opts;
  }

  static bool _wallsExact(List<List<int>> grid, List<List<int>> state, int size) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final clue = grid[r][c];
        if (clue < 0) continue;
        int bulbs = 0;
        if (r > 0 && state[r - 1][c] == 1) bulbs++;
        if (r < size - 1 && state[r + 1][c] == 1) bulbs++;
        if (c > 0 && state[r][c - 1] == 1) bulbs++;
        if (c < size - 1 && state[r][c + 1] == 1) bulbs++;
        if (bulbs != clue) return false;
      }
    }
    return true;
  }

  static List<List<bool>> calculateLit(List<List<int>> grid, List<List<bool>> bulbs) {
    final size = grid.length;
    final lit = List.generate(size, (_) => List.filled(size, false));

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (bulbs[r][c]) {
          lit[r][c] = true;
          for (int i = r - 1; i >= 0 && grid[i][c] == -2; i--) {
            lit[i][c] = true;
          }
          for (int i = r + 1; i < size && grid[i][c] == -2; i++) {
            lit[i][c] = true;
          }
          for (int j = c - 1; j >= 0 && grid[r][j] == -2; j--) {
            lit[r][j] = true;
          }
          for (int j = c + 1; j < size && grid[r][j] == -2; j++) {
            lit[r][j] = true;
          }
        }
      }
    }
    return lit;
  }

  static bool checkVictory(List<List<int>> grid, List<List<bool>> bulbs, List<List<bool>> lit) {
    final size = grid.length;

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == -2 && !lit[r][c]) return false;
      }
    }

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (bulbs[r][c]) {
          for (int j = c + 1; j < size && grid[r][j] == -2; j++) {
            if (bulbs[r][j]) return false;
          }
          for (int i = r + 1; i < size && grid[i][c] == -2; i++) {
            if (bulbs[i][c]) return false;
          }
        }
      }
    }

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final val = grid[r][c];
        if (val >= 0) {
          int count = 0;
          if (r > 0 && bulbs[r - 1][c]) count++;
          if (r < size - 1 && bulbs[r + 1][c]) count++;
          if (c > 0 && bulbs[r][c - 1]) count++;
          if (c < size - 1 && bulbs[r][c + 1]) count++;
          if (count != val) return false;
        }
      }
    }

    return true;
  }

  static List<List<bool>> calculateLitWrapper(Map<String, dynamic> params) {
    return calculateLit(
      params['grid'] as List<List<int>>,
      params['bulbs'] as List<List<bool>>,
    );
  }

  static bool checkVictoryWrapper(Map<String, dynamic> params) {
    return checkVictory(
      params['grid'] as List<List<int>>,
      params['bulbs'] as List<List<bool>>,
      params['lit'] as List<List<bool>>,
    );
  }

  // ------------------------------------------------------------- feedback

  /// Every cell that is already wrong: a bulb that sees another bulb, or a
  /// numbered wall with more bulbs around it than it allows.
  ///
  /// Under-filled clues are not errors yet — the player may still be working —
  /// so only overloads are flagged. The point is to answer "why didn't that
  /// work?" in the same second as the tap, not to finish the puzzle for them.
  static Set<int> conflicts(
    List<List<int>> grid,
    List<List<bool>> bulbs,
  ) {
    final size = grid.length;
    final bad = <int>{};
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (!bulbs[r][c]) continue;
        var seesAnother = false;
        for (var j = c + 1; j < size && grid[r][j] == -2; j++) {
          if (bulbs[r][j]) seesAnother = true;
        }
        for (var j = c - 1; j >= 0 && grid[r][j] == -2; j--) {
          if (bulbs[r][j]) seesAnother = true;
        }
        for (var i = r + 1; i < size && grid[i][c] == -2; i++) {
          if (bulbs[i][c]) seesAnother = true;
        }
        for (var i = r - 1; i >= 0 && grid[i][c] == -2; i--) {
          if (bulbs[i][c]) seesAnother = true;
        }
        if (seesAnother) bad.add(r * size + c);
      }
    }
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final value = grid[r][c];
        if (value < 0) continue;
        var count = 0;
        if (r > 0 && bulbs[r - 1][c]) count++;
        if (r < size - 1 && bulbs[r + 1][c]) count++;
        if (c > 0 && bulbs[r][c - 1]) count++;
        if (c < size - 1 && bulbs[r][c + 1]) count++;
        if (count > value) bad.add(r * size + c);
      }
    }
    return bad;
  }

  // ---------------------------------------------------------------- solver

  /// A complete bulb placement for [grid], or null when the board has none.
  ///
  /// The boards are 5x5 and 6x6 and the walls cut the search down, so a plain
  /// backtracker with two prunes (no two bulbs in sight, no wall over its
  /// number) finishes instantly. Used by the solve button and by the tests that
  /// ask whether a template is a real puzzle at all.
  static List<List<bool>>? solve(List<List<int>> grid) {
    final size = grid.length;
    final bulbs = List.generate(size, (_) => List.filled(size, false));
    final white = <(int, int)>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] == -2) white.add((r, c));
      }
    }

    bool seesBulb(int r, int c) {
      for (var j = c + 1; j < size && grid[r][j] == -2; j++) {
        if (bulbs[r][j]) return true;
      }
      for (var j = c - 1; j >= 0 && grid[r][j] == -2; j--) {
        if (bulbs[r][j]) return true;
      }
      for (var i = r + 1; i < size && grid[i][c] == -2; i++) {
        if (bulbs[i][c]) return true;
      }
      for (var i = r - 1; i >= 0 && grid[i][c] == -2; i--) {
        if (bulbs[i][c]) return true;
      }
      return false;
    }

    bool wallOver(int r, int c) {
      var count = 0;
      if (r > 0 && bulbs[r - 1][c]) count++;
      if (r < size - 1 && bulbs[r + 1][c]) count++;
      if (c > 0 && bulbs[r][c - 1]) count++;
      if (c < size - 1 && bulbs[r][c + 1]) count++;
      return count > grid[r][c];
    }

    bool rec(int index) {
      if (index == white.length) {
        final lit = calculateLit(grid, bulbs);
        return checkVictory(grid, bulbs, lit);
      }
      if (rec(index + 1)) return true;
      final (r, c) = white[index];
      if (seesBulb(r, c)) return false;
      bulbs[r][c] = true;
      var ok = true;
      for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final rr = r + dr;
        final cc = c + dc;
        if (rr < 0 || rr >= size || cc < 0 || cc >= size) continue;
        if (grid[rr][cc] >= 0 && wallOver(rr, cc)) {
          ok = false;
          break;
        }
      }
      if (ok && rec(index + 1)) return true;
      bulbs[r][c] = false;
      return false;
    }

    return rec(0) ? bulbs : null;
  }
}
