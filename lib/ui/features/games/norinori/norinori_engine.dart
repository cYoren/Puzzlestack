import 'dart:math';

/// Norinori: every room holds exactly two shaded cells, and every shaded cell
/// belongs to a domino — a pair that touches orthogonally.
///
/// The old screen shipped three hand-made rooms and a few fixed layouts, so the
/// same three boards came round again and again. This generates a partition of
/// the grid into connected rooms, then **counts** the shadings that fit: a
/// board ships only when exactly one arrangement exists, which is what makes
/// the hint a proof rather than a guess at a stored key.
class NorinoriPuzzle {
  NorinoriPuzzle({
    required this.rows,
    required this.cols,
    required this.roomIds,
    required this.totalRooms,
    required this.solution,
  })  : assert(roomIds.length == rows),
        assert(roomIds.every((row) => row.length == cols)),
        assert(solution.length == rows),
        assert(solution.every((row) => row.length == cols));

  final int rows;
  final int cols;

  /// Row-major room index per cell.
  final List<List<int>> roomIds;

  final int totalRooms;

  /// The one arrangement that satisfies the rules.
  final List<List<bool>> solution;

  int get cellCount => rows * cols;
}

class NorinoriEngine {
  const NorinoriEngine();

  /// A board with exactly one answer.
  NorinoriPuzzle generate({
    int size = 4,
    int rooms = 4,
    Random? random,
    int attempts = 4000,
  }) {
    final rng = random ?? Random();
    for (var attempt = 0; attempt < attempts; attempt++) {
      final partition = _partition(size, rooms, rng);
      if (partition == null) continue;

      final candidates = _allValid(partition.$1, partition.$2);
      if (candidates.length != 1) continue;

      return NorinoriPuzzle(
        rows: size,
        cols: size,
        roomIds: partition.$1,
        totalRooms: partition.$2,
        solution: candidates.single,
      );
    }
    throw StateError('could not build a $size x $size Norinori board');
  }

  /// Exactly two shaded cells per room, and every shaded group is a domino.
  bool isValid(NorinoriPuzzle puzzle, List<List<bool>> shaded) {
    final counts = List<int>.filled(puzzle.totalRooms, 0);
    for (var row = 0; row < puzzle.rows; row++) {
      for (var col = 0; col < puzzle.cols; col++) {
        if (shaded[row][col]) counts[puzzle.roomIds[row][col]]++;
      }
    }
    if (counts.any((count) => count != 2)) return false;

    for (var row = 0; row < puzzle.rows; row++) {
      for (var col = 0; col < puzzle.cols; col++) {
        if (shaded[row][col] && _groupSize(shaded, row, col) != 2) return false;
      }
    }
    return true;
  }

  /// Every cell of the domino containing ([row], [col]).
  int _groupSize(List<List<bool>> shaded, int row, int col) {
    final rows = shaded.length;
    final cols = shaded.first.length;
    final seen = <(int, int)>{(row, col)};
    final queue = <(int, int)>[(row, col)];
    while (queue.isNotEmpty) {
      final (r, c) = queue.removeLast();
      for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nr = r + dr;
        final nc = c + dc;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        if (shaded[nr][nc] && seen.add((nr, nc))) queue.add((nr, nc));
      }
    }
    return seen.length;
  }

  /// How many arrangements satisfy the rules, counted up to [limit].
  int countSolutions(NorinoriPuzzle puzzle, {int limit = 2}) {
    return _allValid(puzzle.roomIds, puzzle.totalRooms, limit: limit).length;
  }

  /// The answer, for the hint and the solve button.
  List<List<bool>>? solve(NorinoriPuzzle puzzle) {
    final found = _allValid(puzzle.roomIds, puzzle.totalRooms, limit: 1);
    return found.isEmpty ? null : found.first;
  }

  // ------------------------------------------------------------- generation

  /// A random partition into connected rooms, or null when a room came out too
  /// small to be interesting.
  (List<List<int>>, int)? _partition(int size, int rooms, Random rng) {
    if (rooms < 2 || rooms > size * size ~/ 3) return null;
    final ids = List.generate(size, (_) => List.filled(size, -1));
    final seeds = <(int, int)>[];
    while (seeds.length < rooms) {
      final next = (rng.nextInt(size), rng.nextInt(size));
      if (!seeds.contains(next)) seeds.add(next);
    }
    for (var i = 0; i < seeds.length; i++) {
      ids[seeds[i].$1][seeds[i].$2] = i;
    }

    var assigned = rooms;
    final total = size * size;
    while (assigned < total) {
      final frontier = <(int, int, int)>[];
      for (var row = 0; row < size; row++) {
        for (var col = 0; col < size; col++) {
          if (ids[row][col] >= 0) continue;
          for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            final nr = row + dr;
            final nc = col + dc;
            if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
            if (ids[nr][nc] >= 0) {
              frontier.add((row, col, ids[nr][nc]));
            }
          }
        }
      }
      if (frontier.isEmpty) return null;
      final pick = frontier[rng.nextInt(frontier.length)];
      ids[pick.$1][pick.$2] = pick.$3;
      assigned++;
    }

    final counts = List<int>.filled(rooms, 0);
    for (final row in ids) {
      for (final id in row) {
        counts[id]++;
      }
    }
    // A room with two cells is decided before the player looks at it.
    if (counts.any((count) => count < 3)) return null;
    return (ids, rooms);
  }

  /// Every shading that satisfies the rules, up to [limit].
  ///
  /// The grid is at most 5x5, so a bitmask walk with two prunes (a room cannot
  /// take a third cell, a shaded cell cannot join a group of three) is fast
  /// enough to run while the player waits.
  List<List<List<bool>>> _allValid(
    List<List<int>> roomIds,
    int totalRooms, {
    int limit = 2,
  }) {
    final rows = roomIds.length;
    final cols = roomIds.first.length;
    final total = rows * cols;
    final found = <List<List<bool>>>[];
    final shaded = List<bool>.filled(total, false);
    final roomCounts = List<int>.filled(totalRooms, 0);

    bool groupTooBig(int cell) {
      final seen = <int>{cell};
      final stack = <int>[cell];
      while (stack.isNotEmpty) {
        final current = stack.removeLast();
        final r = current ~/ cols;
        final c = current % cols;
        for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nr = r + dr;
          final nc = c + dc;
          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
          final index = nr * cols + nc;
          if (shaded[index] && seen.add(index)) stack.add(index);
        }
      }
      return seen.length > 2;
    }

    void walk(int index) {
      if (found.length >= limit) return;
      if (index == total) {
        if (roomCounts.every((count) => count == 2)) {
          // Every group is at most two by construction; a lone cell would be a
          // group of one, so check none are left alone.
          for (var cell = 0; cell < total; cell++) {
            if (!shaded[cell]) continue;
            if (!_hasNeighbour(shaded, cell, rows, cols)) return;
          }
          found.add([
            for (var r = 0; r < rows; r++)
              [for (var c = 0; c < cols; c++) shaded[r * cols + c]],
          ]);
        }
        return;
      }

      final room = roomIds[index ~/ cols][index % cols];
      // Do not shade.
      walk(index + 1);

      // Shade, if the room still has room and the domino stays a domino.
      if (roomCounts[room] >= 2) return;
      shaded[index] = true;
      roomCounts[room]++;
      if (!groupTooBig(index)) {
        walk(index + 1);
      }
      roomCounts[room]--;
      shaded[index] = false;
    }

    walk(0);
    return found;
  }

  bool _hasNeighbour(
    List<bool> shaded,
    int cell,
    int rows,
    int cols,
  ) {
    final row = cell ~/ cols;
    final col = cell % cols;
    for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nr = row + dr;
      final nc = col + dc;
      if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
      if (shaded[nr * cols + nc]) return true;
    }
    return false;
  }
}
