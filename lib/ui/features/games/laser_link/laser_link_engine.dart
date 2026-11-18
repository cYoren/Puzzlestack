import 'dart:math';

enum MirrorType {
  none,
  forwardSlash, // /
  backSlash,    // \
}

enum Direction {
  up,
  down,
  left,
  right,
}

class LaserLinkEngine {
  final int size;
  final Random _random;

  LaserLinkEngine({this.size = 5, Random? random})
      : _random = random ?? Random();

  Map<String, dynamic> generateLevel() {
    for (int attempt = 0; attempt < 200; attempt++) {
      // 1. Randomly place a laser source on the edge
      final sourcePos = _getRandomEdgePos();
      final sourceDir = _getInwardDirection(sourcePos);

      // 2. Generate a path with some mirrors
      final mirrorsPos = <Point<int>>[];
      final mirrorsType = <MirrorType>[];
      final targets = <Point<int>>[];

      Point<int> currentPos = sourcePos;
      Direction currentDir = sourceDir;

      final mirrorCount = 3 + _random.nextInt(3);

      for (int i = 0; i < 20 && mirrorsPos.length < mirrorCount; i++) {
        final nextPos = _move(currentPos, currentDir);

        if (!_isInBounds(nextPos)) {
          if (mirrorsPos.length >= mirrorCount - 1 &&
              !targets.contains(currentPos)) {
            targets.add(currentPos);
            break;
          }
          break;
        }

        currentPos = nextPos;

        // Place a mirror along interior/edge turns (never duplicate coords).
        if (_random.nextDouble() < 0.35 && !mirrorsPos.contains(currentPos)) {
          final type = _random.nextBool()
              ? MirrorType.forwardSlash
              : MirrorType.backSlash;
          mirrorsPos.add(currentPos);
          mirrorsType.add(type);
          currentDir = _reflect(currentDir, type);
        }
      }

      if (targets.isEmpty && currentPos != sourcePos) {
        targets.add(currentPos);
      }
      if (mirrorsPos.isEmpty || targets.isEmpty) continue;

      // Ensure 0-mirror straight beam does not already solve the level.
      final baselinePath = tracePath(sourcePos, sourceDir, {});
      if (targets.every(baselinePath.contains)) continue;

      return {
        'size': size,
        'sourcePos': sourcePos,
        'sourceDir': sourceDir,
        'targets': targets,
        'solutionMirrors': Map.fromIterables(mirrorsPos, mirrorsType),
      };
    }

    // Verified non-trivial fallback (straight beam hits (0,4), mirror at (0,2)
    // reflects right to (4,2)).
    return {
      'size': size,
      'sourcePos': const Point(0, 0),
      'sourceDir': Direction.down,
      'targets': [Point(size - 1, 2)],
      'solutionMirrors': {const Point(0, 2): MirrorType.backSlash},
    };
  }

  Point<int> _getRandomEdgePos() {
    int edge = _random.nextInt(4);
    int pos = _random.nextInt(size);
    switch (edge) {
      case 0: return Point(pos, 0); // Top
      case 1: return Point(pos, size - 1); // Bottom
      case 2: return Point(0, pos); // Left
      case 3: return Point(size - 1, pos); // Right
      default: return Point(0, 0);
    }
  }

  Direction _getInwardDirection(Point<int> pos) {
    if (pos.y == 0) return Direction.down;
    if (pos.y == size - 1) return Direction.up;
    if (pos.x == 0) return Direction.right;
    if (pos.x == size - 1) return Direction.left;
    return Direction.down;
  }

  Point<int> _move(Point<int> pos, Direction dir) {
    switch (dir) {
      case Direction.up: return Point(pos.x, pos.y - 1);
      case Direction.down: return Point(pos.x, pos.y + 1);
      case Direction.left: return Point(pos.x - 1, pos.y);
      case Direction.right: return Point(pos.x + 1, pos.y);
    }
  }

  Direction _reflect(Direction dir, MirrorType type) {
    if (type == MirrorType.forwardSlash) { // /
      switch (dir) {
        case Direction.up: return Direction.right;
        case Direction.down: return Direction.left;
        case Direction.left: return Direction.down;
        case Direction.right: return Direction.up;
      }
    } else if (type == MirrorType.backSlash) { // \
      switch (dir) {
        case Direction.up: return Direction.left;
        case Direction.down: return Direction.right;
        case Direction.left: return Direction.up;
        case Direction.right: return Direction.down;
      }
    }
    return dir;
  }

  bool _isInBounds(Point<int> pos) {
    return pos.x >= 0 && pos.x < size && pos.y >= 0 && pos.y < size;
  }

  List<Point<int>> tracePath(Point<int> sourcePos, Direction sourceDir, Map<Point<int>, MirrorType> mirrors) {
    List<Point<int>> path = [sourcePos];
    Point<int> currentPos = sourcePos;
    Direction currentDir = sourceDir;

    for (int i = 0; i < 100; i++) {
      if (mirrors.containsKey(currentPos)) {
        currentDir = _reflect(currentDir, mirrors[currentPos]!);
      }

      Point<int> nextPos = _move(currentPos, currentDir);
      if (!_isInBounds(nextPos)) break;

      currentPos = nextPos;
      path.add(currentPos);
      
      // Prevent infinite loops if we hit the same pos with same dir
      if (path.length > size * size * 2) break;
    }

    return path;
  }

  static Map<String, dynamic> generateLevelWrapper(int size) {
    return LaserLinkEngine(size: size).generateLevel();
  }
}
