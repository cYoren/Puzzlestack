import 'dart:math' as math;

enum HeyawakeCellState { empty, white, black }

class HeyawakeRoom {
  final int id;
  final int startR;
  final int startC;
  final int endR; // inclusive
  final int endC; // inclusive
  final int? clue; // number of black cells in this room

  HeyawakeRoom({
    required this.id,
    required this.startR,
    required this.startC,
    required this.endR,
    required this.endC,
    this.clue,
  });

  HeyawakeRoom copyWith({int? clue, bool clearClue = false}) => HeyawakeRoom(
        id: id,
        startR: startR,
        startC: startC,
        endR: endR,
        endC: endC,
        clue: clearClue ? null : (clue ?? this.clue),
      );

  bool contains(int r, int c) =>
      r >= startR && r <= endR && c >= startC && c <= endC;
}

class HeyawakePuzzle {
  final int size;
  final List<HeyawakeRoom> rooms;
  final List<List<HeyawakeCellState>> grid;

  HeyawakePuzzle({
    required this.size,
    required this.rooms,
    required this.grid,
  });
}

class HeyawakeEngine {
  static const int defaultSize = 5;

  static HeyawakePuzzle generatePuzzle({
    int size = defaultSize,
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    for (int attempt = 0; attempt < 250; attempt++) {
      final rooms = _partitionRectangles(size, rng);
      final roomOf = _buildRoomMap(rooms, size);
      for (int trySol = 0; trySol < 4; trySol++) {
        final black = _findRandomSolution(rooms, roomOf, size, rng);
        if (black == null) continue;

        final cluedRooms = [
          for (final room in rooms)
            room.copyWith(clue: _countBlackInRoom(black, room)),
        ];

        if (countSolutions(cluedRooms, size) != 1) continue;

        // Drop optional room clues while keeping a single solution.
        final working = List<HeyawakeRoom>.from(cluedRooms);
        final indices = List<int>.generate(working.length, (i) => i)
          ..shuffle(rng);
        for (final idx in indices) {
          final backup = working[idx];
          working[idx] = backup.copyWith(clearClue: true);
          if (countSolutions(working, size) != 1) {
            working[idx] = backup;
          }
        }

        final grid = List.generate(
          size,
          (_) => List.generate(size, (_) => HeyawakeCellState.empty),
        );
        return HeyawakePuzzle(size: size, rooms: working, grid: grid);
      }
    }

    // Verified unique 5x5 fallback.
    final fallbackRooms = [
      HeyawakeRoom(id: 0, startR: 0, startC: 0, endR: 1, endC: 0),
      HeyawakeRoom(id: 1, startR: 0, startC: 1, endR: 1, endC: 4, clue: 3),
      HeyawakeRoom(id: 2, startR: 2, startC: 0, endR: 2, endC: 0, clue: 1),
      HeyawakeRoom(id: 3, startR: 2, startC: 1, endR: 3, endC: 3, clue: 1),
      HeyawakeRoom(id: 4, startR: 2, startC: 4, endR: 2, endC: 4),
      HeyawakeRoom(id: 5, startR: 3, startC: 4, endR: 4, endC: 4),
      HeyawakeRoom(id: 6, startR: 3, startC: 0, endR: 4, endC: 0, clue: 1),
      HeyawakeRoom(id: 7, startR: 4, startC: 1, endR: 4, endC: 3),
    ];
    final grid = List.generate(
      size,
      (_) => List.generate(size, (_) => HeyawakeCellState.empty),
    );
    return HeyawakePuzzle(size: size, rooms: fallbackRooms, grid: grid);
  }

  static List<HeyawakeRoom> _partitionRectangles(int size, math.Random rng) {
    final rects = <(int r0, int c0, int r1, int c1)>[(0, 0, size - 1, size - 1)];
    final targetRooms = size + 1 + rng.nextInt(3);

    for (int step = 0; step < 30 && rects.length < targetRooms; step++) {
      final splittable = <int>[];
      for (int i = 0; i < rects.length; i++) {
        final (r0, c0, r1, c1) = rects[i];
        if ((r1 - r0 + 1) >= 2 || (c1 - c0 + 1) >= 2) {
          if ((r1 - r0 + 1) * (c1 - c0 + 1) >= 3) {
            splittable.add(i);
          }
        }
      }
      if (splittable.isEmpty) break;
      final pick = splittable[rng.nextInt(splittable.length)];
      final (r0, c0, r1, c1) = rects[pick];
      final h = r1 - r0 + 1;
      final w = c1 - c0 + 1;

      final splitHorizontal = (h >= 2 && w >= 2)
          ? rng.nextBool()
          : (h >= 2);
      if (splitHorizontal) {
        final cut = r0 + rng.nextInt(h - 1);
        rects[pick] = (r0, c0, cut, c1);
        rects.add((cut + 1, c0, r1, c1));
      } else {
        final cut = c0 + rng.nextInt(w - 1);
        rects[pick] = (r0, c0, r1, cut);
        rects.add((r0, cut + 1, r1, c1));
      }
    }

    return [
      for (int i = 0; i < rects.length; i++)
        HeyawakeRoom(
          id: i,
          startR: rects[i].$1,
          startC: rects[i].$2,
          endR: rects[i].$3,
          endC: rects[i].$4,
        ),
    ];
  }

  static List<List<int>> _buildRoomMap(List<HeyawakeRoom> rooms, int size) {
    final map = List.generate(size, (_) => List.filled(size, -1));
    for (final room in rooms) {
      for (int r = room.startR; r <= room.endR; r++) {
        for (int c = room.startC; c <= room.endC; c++) {
          map[r][c] = room.id;
        }
      }
    }
    return map;
  }

  static List<List<bool>>? _findRandomSolution(
    List<HeyawakeRoom> rooms,
    List<List<int>> roomOf,
    int size,
    math.Random rng,
  ) {
    final isBlack = List.generate(size, (_) => List.filled(size, false));
    final cells = [
      for (int r = 0; r < size; r++)
        for (int c = 0; c < size; c++) (r, c),
    ]..shuffle(rng);

    final targetBlacks = (size * size * 0.25).round() + rng.nextInt(3);
    int placed = 0;
    for (final (r, c) in cells) {
      if (placed >= targetBlacks) break;
      if (_hasAdjacentBlack(isBlack, r, c, size)) continue;
      isBlack[r][c] = true;
      if (!_allWhiteConnected(isBlack, size)) {
        isBlack[r][c] = false;
        continue;
      }
      placed++;
    }
    // Add blacks where needed to break any 3-room white line.
    if (!_noThreeRoomWhiteLine(isBlack, roomOf, size)) {
      for (final (r, c) in cells) {
        if (isBlack[r][c] || _hasAdjacentBlack(isBlack, r, c, size)) continue;
        isBlack[r][c] = true;
        if (_allWhiteConnected(isBlack, size)) {
          if (_noThreeRoomWhiteLine(isBlack, roomOf, size)) break;
        } else {
          isBlack[r][c] = false;
        }
      }
    }
    if (!_noThreeRoomWhiteLine(isBlack, roomOf, size)) return null;
    if (!_allWhiteConnected(isBlack, size)) return null;
    return isBlack;
  }

  static int _countBlackInRoom(List<List<bool>> isBlack, HeyawakeRoom room) {
    int count = 0;
    for (int r = room.startR; r <= room.endR; r++) {
      for (int c = room.startC; c <= room.endC; c++) {
        if (isBlack[r][c]) count++;
      }
    }
    return count;
  }

  static bool _hasAdjacentBlack(List<List<bool>> isBlack, int r, int c, int size) {
    if (r > 0 && isBlack[r - 1][c]) return true;
    if (r < size - 1 && isBlack[r + 1][c]) return true;
    if (c > 0 && isBlack[r][c - 1]) return true;
    if (c < size - 1 && isBlack[r][c + 1]) return true;
    return false;
  }

  /// Counts valid solutions up to [limit] (default 2 for uniqueness).
  static int countSolutions(
    List<HeyawakeRoom> rooms,
    int size, {
    int limit = 2,
  }) {
    final roomOf = _buildRoomMap(rooms, size);
    // -1 = unset, 0 = white, 1 = black
    final state = List.generate(size, (_) => List.filled(size, -1));

    bool canPlaceBlack(int r, int c) {
      if (r > 0 && state[r - 1][c] == 1) return false;
      if (r < size - 1 && state[r + 1][c] == 1) return false;
      if (c > 0 && state[r][c - 1] == 1) return false;
      if (c < size - 1 && state[r][c + 1] == 1) return false;
      final room = rooms[roomOf[r][c]];
      if (room.clue != null) {
        int blacks = 0;
        for (int rr = room.startR; rr <= room.endR; rr++) {
          for (int cc = room.startC; cc <= room.endC; cc++) {
            if (state[rr][cc] == 1) blacks++;
          }
        }
        if (blacks + 1 > room.clue!) return false;
      }
      return true;
    }

    bool roomFeasible(HeyawakeRoom room) {
      if (room.clue == null) return true;
      int blacks = 0;
      int unset = 0;
      for (int rr = room.startR; rr <= room.endR; rr++) {
        for (int cc = room.startC; cc <= room.endC; cc++) {
          if (state[rr][cc] == 1) blacks++;
          if (state[rr][cc] == -1) unset++;
        }
      }
      return blacks <= room.clue! && blacks + unset >= room.clue!;
    }

    bool rowWhiteRunOk(int r) {
      int distinct = 0;
      int lastRoom = -1;
      for (int c = 0; c < size; c++) {
        if (state[r][c] == 0) {
          final rm = roomOf[r][c];
          if (rm != lastRoom) {
            distinct++;
            lastRoom = rm;
            if (distinct >= 3) return false;
          }
        } else {
          distinct = 0;
          lastRoom = -1;
        }
      }
      return true;
    }

    bool colWhiteRunOk(int c) {
      int distinct = 0;
      int lastRoom = -1;
      for (int r = 0; r < size; r++) {
        if (state[r][c] == 0) {
          final rm = roomOf[r][c];
          if (rm != lastRoom) {
            distinct++;
            lastRoom = rm;
            if (distinct >= 3) return false;
          }
        } else {
          distinct = 0;
          lastRoom = -1;
        }
      }
      return true;
    }

    int search(int idx, int found) {
      if (found >= limit) return found;
      if (idx == size * size) {
        final isBlack = List.generate(
          size,
          (r) => List.generate(size, (c) => state[r][c] == 1),
        );
        if (!_allWhiteConnected(isBlack, size)) return found;
        return found + 1;
      }

      final r = idx ~/ size;
      final c = idx % size;
      final room = rooms[roomOf[r][c]];

      // Try white (0)
      state[r][c] = 0;
      if (roomFeasible(room) && rowWhiteRunOk(r) && colWhiteRunOk(c)) {
        found = search(idx + 1, found);
      }

      // Try black (1)
      if (found < limit && canPlaceBlack(r, c)) {
        state[r][c] = 1;
        if (roomFeasible(room)) {
          found = search(idx + 1, found);
        }
      }

      state[r][c] = -1;
      return found;
    }

    return search(0, 0);
  }

  static bool isSolved(
    List<List<HeyawakeCellState>> grid,
    List<HeyawakeRoom> rooms,
    int size,
  ) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == HeyawakeCellState.empty) return false;
      }
    }

    final isBlack = List.generate(
      size,
      (r) => List.generate(size, (c) => grid[r][c] == HeyawakeCellState.black),
    );

    // Rule 1: No adjacent black cells orthogonally.
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (isBlack[r][c] && _hasAdjacentBlack(isBlack, r, c, size)) {
          return false;
        }
      }
    }

    // Rule 2: All white cells must be connected.
    if (!_allWhiteConnected(isBlack, size)) return false;

    // Rule 3: Room clues must match exact black cell count.
    for (final room in rooms) {
      if (room.clue != null && _countBlackInRoom(isBlack, room) != room.clue) {
        return false;
      }
    }

    // Rule 4: No orthogonal white line may span 3 or more rooms.
    final roomOf = _buildRoomMap(rooms, size);
    if (!_noThreeRoomWhiteLine(isBlack, roomOf, size)) return false;

    return true;
  }

  static bool _noThreeRoomWhiteLine(
    List<List<bool>> isBlack,
    List<List<int>> roomOf,
    int size,
  ) {
    for (int r = 0; r < size; r++) {
      int distinct = 0;
      int lastRoom = -1;
      for (int c = 0; c < size; c++) {
        if (!isBlack[r][c]) {
          final rm = roomOf[r][c];
          if (rm != lastRoom) {
            distinct++;
            lastRoom = rm;
            if (distinct >= 3) return false;
          }
        } else {
          distinct = 0;
          lastRoom = -1;
        }
      }
    }
    for (int c = 0; c < size; c++) {
      int distinct = 0;
      int lastRoom = -1;
      for (int r = 0; r < size; r++) {
        if (!isBlack[r][c]) {
          final rm = roomOf[r][c];
          if (rm != lastRoom) {
            distinct++;
            lastRoom = rm;
            if (distinct >= 3) return false;
          }
        } else {
          distinct = 0;
          lastRoom = -1;
        }
      }
    }
    return true;
  }

  static bool _allWhiteConnected(List<List<bool>> isBlack, int size) {
    int startR = -1;
    int startC = -1;
    int whiteCount = 0;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (!isBlack[r][c]) {
          whiteCount++;
          if (startR == -1) {
            startR = r;
            startC = c;
          }
        }
      }
    }
    if (whiteCount == 0) return false;

    final visited = List.generate(size, (_) => List.generate(size, (_) => false));
    final queue = <List<int>>[[startR, startC]];
    visited[startR][startC] = true;
    int reachable = 0;

    while (queue.isNotEmpty) {
      final curr = queue.removeLast();
      reachable++;
      final cr = curr[0];
      final cc = curr[1];

      for (final (nr, nc) in [
        (cr - 1, cc),
        (cr + 1, cc),
        (cr, cc - 1),
        (cr, cc + 1),
      ]) {
        if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
          if (!isBlack[nr][nc] && !visited[nr][nc]) {
            visited[nr][nc] = true;
            queue.add([nr, nc]);
          }
        }
      }
    }

    return reachable == whiteCount;
  }
}
