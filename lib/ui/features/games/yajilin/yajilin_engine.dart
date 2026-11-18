import 'dart:math' as math;

enum ArrowDirection { up, down, left, right }

class YajilinClue {
  final ArrowDirection dir;
  final int count;

  YajilinClue(this.dir, this.count);
}

enum YajilinCellState { empty, black, dot }

class YajilinCell {
  final int r;
  final int c;
  final YajilinClue? clue;
  YajilinCellState state;

  YajilinCell({
    required this.r,
    required this.c,
    this.clue,
    this.state = YajilinCellState.empty,
  });

  bool get isClue => clue != null;
}

class YajilinEdge {
  final int r1, c1, r2, c2;

  YajilinEdge(this.r1, this.c1, this.r2, this.c2);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! YajilinEdge) return false;
    return (r1 == other.r1 &&
            c1 == other.c1 &&
            r2 == other.r2 &&
            c2 == other.c2) ||
        (r1 == other.r2 && c1 == other.c2 && r2 == other.r1 && c2 == other.c1);
  }

  @override
  int get hashCode => (r1 + r2) * 31 + (c1 + c2);
}

class YajilinPuzzle {
  final int size;
  final List<List<YajilinCell>> grid;
  final Set<YajilinEdge> edges;

  YajilinPuzzle({
    required this.size,
    required this.grid,
    required this.edges,
  });
}

class YajilinEngine {
  static const int defaultSize = 5;

  static YajilinPuzzle generatePuzzle({
    int size = defaultSize,
    math.Random? random,
  }) {
    final rng = random ?? math.Random();

    for (int attempt = 0; attempt < 250; attempt++) {
      final cluePositions = _pickCluePositions(size, rng);
      final sol = _findRandomSolution(size, cluePositions, rng);
      if (sol == null) continue;

      final grid = _assignClues(size, cluePositions, sol, rng);
      if (grid == null) continue;

      if (countSolutions(grid, size, limit: 2) != 1) continue;

      return YajilinPuzzle(size: size, grid: grid, edges: {});
    }

    return _fallbackPuzzle(size);
  }

  static Set<int> _pickCluePositions(int size, math.Random rng) {
    final total = size * size;
    final targetClues = size <= 4 ? 3 : 4 + rng.nextInt(3); // 4..6 clues for 5x5
    final indices = List<int>.generate(total, (i) => i)..shuffle(rng);
    return indices.take(targetClues).toSet();
  }

  static List<List<bool>>? _findRandomSolution(
    int size,
    Set<int> cluePositions,
    math.Random rng,
  ) {
    final total = size * size;
    final isClue = List<bool>.generate(total, cluePositions.contains);
    final isBlack = List.generate(size, (_) => List.filled(size, false));
    final hEdge = List.generate(size, (_) => List.filled(size, false));
    final vEdge = List.generate(size, (_) => List.filled(size, false));
    final parent = List<int>.generate(total, (i) => i);
    int cyclesClosed = 0;
    int nodesVisited = 0;

    int find(int x) {
      while (parent[x] != x) {
        x = parent[x];
      }
      return x;
    }

    bool search(int idx) {
      if (nodesVisited > 4000) return false;
      nodesVisited++;
      if (idx == total) {
        if (cyclesClosed != 1) return false;
        int blacks = 0;
        for (int r = 0; r < size; r++) {
          for (int c = 0; c < size; c++) {
            if (isBlack[r][c]) blacks++;
          }
        }
        return blacks >= 2;
      }

      final r = idx ~/ size;
      final c = idx % size;
      final topEdge = r > 0 && vEdge[r - 1][c];
      final leftEdge = c > 0 && hEdge[r][c - 1];

      if (isClue[idx]) {
        if (topEdge || leftEdge) return false;
        return search(idx + 1);
      }

      final inDeg = (topEdge ? 1 : 0) + (leftEdge ? 1 : 0);
      final canRight = c + 1 < size && !isClue[idx + 1];
      final canDown = r + 1 < size && !isClue[idx + size];

      final options = <int>[];
      // Option 0: black cell
      if (inDeg == 0 &&
          !(r > 0 && isBlack[r - 1][c]) &&
          !(c > 0 && isBlack[r][c - 1])) {
        options.add(0);
      }
      // Option 1: loop cell with (right=true, down=true)
      if (inDeg == 0 && canRight && canDown) options.add(1);
      // Option 2: loop cell with (right=true, down=false)
      if (inDeg == 1 && canRight) options.add(2);
      // Option 3: loop cell with (right=false, down=true)
      if (inDeg == 1 && canDown) options.add(3);
      // Option 4: loop cell with (right=false, down=false)
      if (inDeg == 2) options.add(4);

      if (options.length > 1) options.shuffle(rng);

      for (final opt in options) {
        if (opt == 0) {
          isBlack[r][c] = true;
          if (search(idx + 1)) return true;
          isBlack[r][c] = false;
          continue;
        }

        final right = opt == 1 || opt == 2;
        final down = opt == 1 || opt == 3;
        hEdge[r][c] = right;
        vEdge[r][c] = down;

        int? modifiedV;
        int prevCycles = cyclesClosed;
        bool valid = true;

        if (topEdge && !leftEdge) {
          parent[idx] = find((r - 1) * size + c);
        } else if (leftEdge && !topEdge) {
          parent[idx] = find(r * size + (c - 1));
        } else if (topEdge && leftEdge) {
          final u = find((r - 1) * size + c);
          final v = find(r * size + (c - 1));
          if (u == v) {
            cyclesClosed++;
            if (cyclesClosed > 1) valid = false;
            parent[idx] = u;
          } else {
            parent[idx] = u;
            parent[v] = u;
            modifiedV = v;
          }
        }

        if (valid && search(idx + 1)) return true;

        cyclesClosed = prevCycles;
        if (modifiedV != null) parent[modifiedV] = modifiedV;
        parent[idx] = idx;
        hEdge[r][c] = false;
        vEdge[r][c] = false;
      }
      return false;
    }

    if (!search(0)) return null;
    return isBlack;
  }

  static List<List<YajilinCell>>? _assignClues(
    int size,
    Set<int> cluePositions,
    List<List<bool>> isBlack,
    math.Random rng,
  ) {
    final grid = List.generate(size, (r) {
      return List.generate(size, (c) {
        if (!cluePositions.contains(r * size + c)) {
          return YajilinCell(r: r, c: c);
        }
        final candidates = <(ArrowDirection, int, int)>[];
        for (final dir in ArrowDirection.values) {
          int blacks = 0;
          int len = 0;
          switch (dir) {
            case ArrowDirection.up:
              for (int nr = r - 1; nr >= 0; nr--) {
                len++;
                if (isBlack[nr][c]) blacks++;
              }
            case ArrowDirection.down:
              for (int nr = r + 1; nr < size; nr++) {
                len++;
                if (isBlack[nr][c]) blacks++;
              }
            case ArrowDirection.left:
              for (int nc = c - 1; nc >= 0; nc--) {
                len++;
                if (isBlack[r][nc]) blacks++;
              }
            case ArrowDirection.right:
              for (int nc = c + 1; nc < size; nc++) {
                len++;
                if (isBlack[r][nc]) blacks++;
              }
          }
          if (len > 0) {
            candidates.add((dir, blacks, len));
          }
        }
        if (candidates.isEmpty) {
          return YajilinCell(r: r, c: c);
        }
        final withBlacks = candidates.where((e) => e.$2 > 0).toList();
        final pool = withBlacks.isNotEmpty ? withBlacks : candidates;
        final chosen = pool[rng.nextInt(pool.length)];
        return YajilinCell(
          r: r,
          c: c,
          clue: YajilinClue(chosen.$1, chosen.$2),
        );
      });
    });
    return grid;
  }

  static YajilinPuzzle _fallbackPuzzle(int size) {
    // Verified unique 5x5 Yajilin puzzle (countSolutions == 1).
    if (size == 5) {
      final clues = <(int, int), YajilinClue>{
        (0, 2): YajilinClue(ArrowDirection.down, 1),
        (2, 1): YajilinClue(ArrowDirection.up, 0),
        (2, 2): YajilinClue(ArrowDirection.down, 1),
        (3, 4): YajilinClue(ArrowDirection.down, 1),
      };
      final grid = List.generate(
        5,
        (r) => List.generate(
          5,
          (c) => YajilinCell(r: r, c: c, clue: clues[(r, c)]),
        ),
      );
      return YajilinPuzzle(size: 5, grid: grid, edges: {});
    }
    return YajilinPuzzle(
      size: size,
      grid: List.generate(
        size,
        (r) => List.generate(
          size,
          (c) => YajilinCell(
            r: r,
            c: c,
            clue: (r == 0 && c == 0)
                ? YajilinClue(ArrowDirection.right, 1)
                : (r == size - 1 && c == size - 1)
                    ? YajilinClue(ArrowDirection.up, 1)
                    : null,
          ),
        ),
      ),
      edges: {},
    );
  }

  /// Counts valid Yajilin solutions (black cell placement + single loop)
  /// up to [limit].
  static int countSolutions(
    List<List<YajilinCell>> grid,
    int size, {
    int limit = 2,
  }) {
    final total = size * size;
    final isClue = List<bool>.filled(total, false);
    final clueTargets = <int>[];
    final clueRemain = <int>[];
    final clueCurrent = <int>[];
    final watchedBy = List.generate(total, (_) => <int>[]);

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final clue = grid[r][c].clue;
        if (clue != null) {
          isClue[r * size + c] = true;
          final cid = clueTargets.length;
          clueTargets.add(clue.count);
          clueCurrent.add(0);
          int cells = 0;
          switch (clue.dir) {
            case ArrowDirection.up:
              for (int nr = r - 1; nr >= 0; nr--) {
                watchedBy[nr * size + c].add(cid);
                cells++;
              }
            case ArrowDirection.down:
              for (int nr = r + 1; nr < size; nr++) {
                watchedBy[nr * size + c].add(cid);
                cells++;
              }
            case ArrowDirection.left:
              for (int nc = c - 1; nc >= 0; nc--) {
                watchedBy[r * size + nc].add(cid);
                cells++;
              }
            case ArrowDirection.right:
              for (int nc = c + 1; nc < size; nc++) {
                watchedBy[r * size + nc].add(cid);
                cells++;
              }
          }
          clueRemain.add(cells);
          if (clue.count < 0 || clue.count > cells) return 0;
        }
      }
    }

    final isBlack = List.generate(size, (_) => List.filled(size, false));
    final hEdge = List.generate(size, (_) => List.filled(size, false));
    final vEdge = List.generate(size, (_) => List.filled(size, false));
    final parent = List<int>.generate(total, (i) => i);
    int cyclesClosed = 0;
    int solutions = 0;

    int find(int x) {
      while (parent[x] != x) {
        x = parent[x];
      }
      return x;
    }

    void search(int idx) {
      if (solutions >= limit) return;
      if (idx == total) {
        if (cyclesClosed == 1) {
          solutions++;
        }
        return;
      }

      final r = idx ~/ size;
      final c = idx % size;
      final topEdge = r > 0 && vEdge[r - 1][c];
      final leftEdge = c > 0 && hEdge[r][c - 1];

      // Decrement remaining ray counters for clues watching this cell.
      final watchers = watchedBy[idx];
      bool canBeNonBlack = true;
      bool canBeBlack = !isClue[idx] &&
          !(r > 0 && isBlack[r - 1][c]) &&
          !(c > 0 && isBlack[r][c - 1]) &&
          !topEdge &&
          !leftEdge;

      for (final cid in watchers) {
        clueRemain[cid]--;
        if (clueCurrent[cid] + clueRemain[cid] < clueTargets[cid]) {
          canBeNonBlack = false;
        }
        if (clueCurrent[cid] + 1 > clueTargets[cid]) {
          canBeBlack = false;
        }
      }

      if (isClue[idx]) {
        if (!topEdge && !leftEdge && canBeNonBlack) {
          search(idx + 1);
        }
      } else {
        // Branch 1: black cell
        if (canBeBlack) {
          isBlack[r][c] = true;
          for (final cid in watchers) {
            clueCurrent[cid]++;
          }
          search(idx + 1);
          for (final cid in watchers) {
            clueCurrent[cid]--;
          }
          isBlack[r][c] = false;
        }

        // Branch 2: loop cell (if feasible for all watching clues)
        if (canBeNonBlack && solutions < limit) {
          final inDeg = (topEdge ? 1 : 0) + (leftEdge ? 1 : 0);
          final canRight = c + 1 < size && !isClue[idx + 1];
          final canDown = r + 1 < size && !isClue[idx + size];

          void tryLoop(bool right, bool down) {
            if (solutions >= limit) return;
            hEdge[r][c] = right;
            vEdge[r][c] = down;

            int? modifiedV;
            final prevCycles = cyclesClosed;
            bool valid = true;

            if (topEdge && !leftEdge) {
              parent[idx] = find((r - 1) * size + c);
            } else if (leftEdge && !topEdge) {
              parent[idx] = find(r * size + (c - 1));
            } else if (topEdge && leftEdge) {
              final u = find((r - 1) * size + c);
              final v = find(r * size + (c - 1));
              if (u == v) {
                cyclesClosed++;
                if (cyclesClosed > 1) valid = false;
                parent[idx] = u;
              } else {
                parent[idx] = u;
                parent[v] = u;
                modifiedV = v;
              }
            }

            if (valid) search(idx + 1);

            cyclesClosed = prevCycles;
            if (modifiedV != null) parent[modifiedV] = modifiedV;
            parent[idx] = idx;
            hEdge[r][c] = false;
            vEdge[r][c] = false;
          }

          if (inDeg == 0) {
            if (canRight && canDown) tryLoop(true, true);
          } else if (inDeg == 1) {
            if (canRight) tryLoop(true, false);
            if (canDown) tryLoop(false, true);
          } else {
            tryLoop(false, false);
          }
        }
      }

      for (final cid in watchers) {
        clueRemain[cid]++;
      }
    }

    search(0);
    return solutions;
  }

  static bool isSolved(
    List<List<YajilinCell>> grid,
    Set<YajilinEdge> edges,
    int size,
  ) {
    if (edges.isEmpty) return false;

    // Rule 0: Clue cells cannot be black.
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c].isClue &&
            grid[r][c].state == YajilinCellState.black) {
          return false;
        }
      }
    }

    // Rule 1: Black cells cannot be orthogonally adjacent.
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c].state == YajilinCellState.black) {
          if (r > 0 && grid[r - 1][c].state == YajilinCellState.black) {
            return false;
          }
          if (r < size - 1 &&
              grid[r + 1][c].state == YajilinCellState.black) {
            return false;
          }
          if (c > 0 && grid[r][c - 1].state == YajilinCellState.black) {
            return false;
          }
          if (c < size - 1 &&
              grid[r][c + 1].state == YajilinCellState.black) {
            return false;
          }
        }
      }
    }

    // Rule 2: Clues must match black cell count along ray.
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final clue = grid[r][c].clue;
        if (clue != null) {
          int count = 0;
          if (clue.dir == ArrowDirection.right) {
            for (int nc = c + 1; nc < size; nc++) {
              if (grid[r][nc].state == YajilinCellState.black) count++;
            }
          } else if (clue.dir == ArrowDirection.left) {
            for (int nc = c - 1; nc >= 0; nc--) {
              if (grid[r][nc].state == YajilinCellState.black) count++;
            }
          } else if (clue.dir == ArrowDirection.up) {
            for (int nr = r - 1; nr >= 0; nr--) {
              if (grid[nr][c].state == YajilinCellState.black) count++;
            }
          } else if (clue.dir == ArrowDirection.down) {
            for (int nr = r + 1; nr < size; nr++) {
              if (grid[nr][c].state == YajilinCellState.black) count++;
            }
          }
          if (count != clue.count) return false;
        }
      }
    }

    // Rule 3: Edges connect orthogonally adjacent non-black, non-clue cells
    // into a single continuous loop visiting all non-black, non-clue cells.
    final adj = <int, List<int>>{};
    for (final e in edges) {
      if (e.r1 < 0 ||
          e.r1 >= size ||
          e.c1 < 0 ||
          e.c1 >= size ||
          e.r2 < 0 ||
          e.r2 >= size ||
          e.c2 < 0 ||
          e.c2 >= size) {
        return false;
      }
      if ((e.r1 - e.r2).abs() + (e.c1 - e.c2).abs() != 1) return false;
      final c1 = grid[e.r1][e.c1];
      final c2 = grid[e.r2][e.c2];
      if (c1.isClue ||
          c1.state == YajilinCellState.black ||
          c2.isClue ||
          c2.state == YajilinCellState.black) {
        return false;
      }
      final k1 = e.r1 * size + e.c1;
      final k2 = e.r2 * size + e.c2;
      (adj[k1] ??= []).add(k2);
      (adj[k2] ??= []).add(k1);
    }

    if (adj.isEmpty) return false;
    for (final neighbors in adj.values) {
      if (neighbors.length != 2) return false;
    }

    // Verify all non-black non-clue cells are on the loop.
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final cell = grid[r][c];
        if (!cell.isClue && cell.state != YajilinCellState.black) {
          if (!adj.containsKey(r * size + c)) return false;
        }
      }
    }

    // Verify single connected cycle (reject disjoint loops).
    final start = adj.keys.first;
    final visited = <int>{start};
    final queue = <int>[start];
    int head = 0;
    while (head < queue.length) {
      final cur = queue[head++];
      for (final next in adj[cur]!) {
        if (visited.add(next)) {
          queue.add(next);
        }
      }
    }
    return visited.length == adj.length;
  }
}
