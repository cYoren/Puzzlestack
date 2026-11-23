/// The rules of Mirror Maze, in one place.
///
/// A cell holds [Mirror.empty], [Mirror.slash] or [Mirror.backslash]. The beam
/// enters at a start cell travelling a direction, reflects in every cell that
/// holds a mirror, and leaves as soon as a step would take it off the board. A
/// deal is the start edge plus the cell and direction the beam must leave by.
///
/// The screen, the generator and the tests all read the rules from here, so
/// there is one answer to "what does this board do" and one to "does this board
/// win". [mirrorMazeLayouts] enumerates every layout that wins a deal, which is
/// how a deal can be shown to be more than a one-mirror shortcut.
library;

import 'dart:math';

/// What a board cell holds.
///
/// [Mirror.stateCount] is a three-way cycle, because a cell is tapped through
/// empty, `/`, `\` and back to empty. That cycle is the reason a single tap
/// never jumps straight from `/` to `\`: [next] is the only correct way to step
/// a cell, and a caller that wants "the other mirror" must clear the cell first.
abstract final class Mirror {
  /// No mirror; the beam passes straight through.
  static const int empty = 0;

  /// `/`, bottom-left to top-right.
  static const int slash = 1;

  /// `\`, top-left to bottom-right.
  static const int backslash = 2;

  /// How many states one tap cycle visits.
  static const int stateCount = 3;

  /// The two states that are a mirror, in cycle order.
  static const List<int> kinds = <int>[slash, backslash];

  /// The state one tap after [state]. This is the whole tap rule.
  static int next(int state) => (state + 1) % stateCount;

  /// A direction with the mirror's reflection applied. An empty cell leaves the
  /// beam alone.
  static Point<int> reflect(Point<int> direction, int mirror) {
    if (mirror == slash) {
      return Point<int>(-direction.y, -direction.x);
    }
    if (mirror == backslash) {
      return Point<int>(direction.y, direction.x);
    }
    return direction;
  }
}

/// Where a beam went.
class MirrorMazeTrace {
  const MirrorMazeTrace({
    required this.path,
    required this.hit,
    required this.exitCell,
    required this.exitDir,
  });

  /// Every cell the beam was in, start first. The last entry is the cell the
  /// beam left from, but only when [exited] — a beam that never leaves is
  /// stopped by the step limit and its last cell is not an exit.
  final List<Point<int>> path;

  /// The mirrors the beam actually reflected in, and nothing else. A mirror on
  /// a cell the beam never reaches does not change the beam, so it is not a
  /// part of the answer.
  final Map<Point<int>, int> hit;

  /// The cell the beam left the board from, or null when it never left.
  final Point<int>? exitCell;

  /// The direction the beam travelled as it left. Meaningless unless [exited].
  final Point<int> exitDir;

  /// True when the beam left the board instead of running into the step limit.
  bool get exited => exitCell != null;
}

/// The board edge a beam enters from, taken as a cell plus the direction it
/// travels in.
class MirrorMazeStart {
  const MirrorMazeStart(this.cell, this.direction);

  final Point<int> cell;
  final Point<int> direction;
}

/// One deal: where the beam enters, where it must leave, and the layout this
/// deal was built from.
class MirrorMazeDeal {
  const MirrorMazeDeal({
    required this.start,
    required this.startDir,
    required this.target,
    required this.targetDir,
    required this.answer,
    required this.depth,
  });

  /// The cell the beam enters the board at.
  final Point<int> start;

  /// The direction it travels when it enters.
  final Point<int> startDir;

  /// The cell it must leave the board from.
  final Point<int> target;

  /// The direction it must be travelling when it leaves.
  final Point<int> targetDir;

  /// One of the winning two-mirror layouts: the one this deal was built from,
  /// traced before the deal was returned.
  ///
  /// Not the only answer. A beam deal has several legal two-mirror layouts, the
  /// turn pair sliding along a free column or row, and any of them wins because
  /// the win condition is the exit and not a layout. [depth], the mirror count,
  /// is what is proved.
  final Map<Point<int>, int> answer;

  /// The fewest mirrors any winning layout takes: two for every dealt board, and
  /// [mirrorMazeDealIsFair] proves no cheaper layout wins.
  final int depth;

  /// A stable identity for this deal, for caching proofs.
  String get key => '${start.x},${start.y}|${startDir.x},${startDir.y}|'
      '${target.x},${target.y}|${targetDir.x},${targetDir.y}';

  @override
  String toString() => 'MirrorMazeDeal($key, depth $depth)';
}

/// The side of the dealt board.
///
/// This is the deal space and nothing else. A 4x4 board can only be dealt 96
/// boards that take two mirrors, which is too few for "never the same board
/// twice in 30 days"; 5x5 gives 160, counted by enumeration. A bigger board is
/// not a harder rule: an odd number of turns leaves the board on the other axis,
/// at a row one mirror would have reached, and four or more turns must come back
/// up the column the detour started in, where the mirror that started it is
/// waiting. So a deal costs two mirrors at most, whatever the board, and what
/// grows with the board is the number of places a turn can happen.
const int mirrorMazeSize = 5;

/// How many cells a beam may visit before it is called a loop.
///
/// A path visits each cell at most once before it either leaves the board or
/// repeats a (cell, direction) state. [mirrorMazeSize] squared is 25, so a real
/// exit needs no more than this.
const int mirrorMazeMaxSteps = 32;

/// Follows the beam through [mirrors].
MirrorMazeTrace traceBeam({
  required Map<Point<int>, int> mirrors,
  required Point<int> start,
  required Point<int> startDir,
  int size = mirrorMazeSize,
}) {
  final List<Point<int>> path = <Point<int>>[start];
  final Map<Point<int>, int> hit = <Point<int>, int>{};
  Point<int> current = start;
  Point<int> direction = startDir;

  for (int step = 0; step < mirrorMazeMaxSteps; step++) {
    final int mirror = mirrors[current] ?? Mirror.empty;
    if (mirror != Mirror.empty) {
      hit[current] = mirror;
      direction = Mirror.reflect(direction, mirror);
    }
    final Point<int> next = Point<int>(
      current.x + direction.x,
      current.y + direction.y,
    );
    if (next.x < 0 || next.x >= size || next.y < 0 || next.y >= size) {
      return MirrorMazeTrace(
        path: path,
        hit: hit,
        exitCell: current,
        exitDir: direction,
      );
    }
    path.add(next);
    current = next;
  }

  return MirrorMazeTrace(
    path: path,
    hit: hit,
    exitCell: null,
    exitDir: direction,
  );
}

/// True when [mirrors] makes the beam leave [deal] exactly where it must.
bool mirrorMazeLayoutWins(MirrorMazeDeal deal, Map<Point<int>, int> mirrors) {
  final MirrorMazeTrace trace = traceBeam(
    mirrors: mirrors,
    start: deal.start,
    startDir: deal.startDir,
  );
  return trace.exitCell == deal.target && trace.exitDir == deal.targetDir;
}

/// Every distinct layout of exactly [count] mirrors that wins [deal].
///
/// Exhaustive: it places [count] mirrors on every set of cells and tries both
/// mirror kinds on each, so an empty result is a proof that the deal cannot be
/// won with that many mirrors. A layout is reported as the mirrors the beam
/// actually hit, so tapping a mirror somewhere the beam never goes is not
/// counted as a second answer.
List<Map<Point<int>, int>> mirrorMazeLayouts(
  MirrorMazeDeal deal,
  int count, {
  int size = mirrorMazeSize,
}) {
  final Map<String, Map<Point<int>, int>> found =
      <String, Map<Point<int>, int>>{};

  void consider(Map<Point<int>, int> board, int count) {
    final MirrorMazeTrace trace = traceBeam(
      mirrors: board,
      start: deal.start,
      startDir: deal.startDir,
      size: size,
    );
    if (trace.exitCell != deal.target || trace.exitDir != deal.targetDir) {
      return;
    }
    // A layout with no hit mirror is the straight shot: an answer only when no
    // mirrors were asked for. `count` mirrors that the beam never reaches are
    // not an answer.
    if (count > 0 && trace.hit.isEmpty) return;
    final String key = _layoutKey(trace.hit);
    found.putIfAbsent(key, () => trace.hit);
  }

  if (count == 0) {
    consider(const <Point<int>, int>{}, 0);
    return found.values.toList();
  }

  final List<Point<int>> cells = <Point<int>>[
    for (int r = 0; r < size; r++)
      for (int c = 0; c < size; c++) Point<int>(r, c),
  ];
  final List<Point<int>> chosen = <Point<int>>[];

  void assign() {
    for (int mask = 0; mask < (1 << count); mask++) {
      consider(<Point<int>, int>{
        for (int i = 0; i < count; i++)
          chosen[i]: (mask & (1 << i)) == 0 ? Mirror.slash : Mirror.backslash,
      }, count);
    }
  }

  void choose(int from) {
    if (chosen.length == count) {
      assign();
      return;
    }
    for (int i = from; i < cells.length; i++) {
      chosen.add(cells[i]);
      choose(i + 1);
      chosen.removeLast();
    }
  }

  choose(0);
  return found.values.toList();
}

/// The fewest mirrors any winning layout of [deal] needs, or null when none
/// needs at most [maxDepth].
int? mirrorMazeDepth(MirrorMazeDeal deal,
    {int maxDepth = 3, int size = mirrorMazeSize}) {
  for (int count = 0; count <= maxDepth; count++) {
    if (mirrorMazeLayouts(deal, count, size: size).isNotEmpty) return count;
  }
  return null;
}

/// True when [deal] is fair: winnable, and not winnable with fewer than
/// [MirrorMazeGenerator.mirrorMazeDealDepth] mirrors.
///
/// Load-bearing for the generator, and named here so a test can hand it a deal
/// that *is* a shortcut and watch it say no. Every check is exhaustive:
/// [mirrorMazeLayouts] tries both mirror kinds on every set of cells, so a
/// `false` here is a proof that some cheaper layout wins, and `true` is a proof
/// that none does.
///
/// What this does **not** prove, and must not be read as proving: that the deal
/// has one answer. A two-mirror beam deal has several legal two-mirror layouts
/// (the U-turn pair can slide along any free row or column), and any of them
/// wins. The property that matters for the player is the mirror count: no
/// straight shot, no single mirror, two mirrors whatever the route.
bool mirrorMazeDealIsFair(MirrorMazeDeal deal, {int size = mirrorMazeSize}) {
  // Depth and answer have to agree, or "the deal costs two mirrors" is a label
  // stuck on a cheaper or a dearer layout.
  if (deal.depth != MirrorMazeGenerator.mirrorMazeDealDepth) return false;
  if (deal.answer.length != deal.depth) return false;
  if (!mirrorMazeLayoutWins(deal, deal.answer)) return false;
  if (!mirrorMazeNoCheaperLayout(deal, size: size)) return false;
  return mirrorMazeLayouts(deal, deal.depth, size: size).isNotEmpty;
}

/// The layout half of [mirrorMazeDealIsFair]: no layout of no mirrors and no
/// layout of one mirror, of either kind on any cell, wins [deal].
///
/// Split out because the verdict's other half is about labels, and a label check
/// that fails first would mean a shortcut deal never reached the enumeration
/// that proves it is a shortcut. A test can assert this half on its own and know
/// the counting ran.
bool mirrorMazeNoCheaperLayout(MirrorMazeDeal deal,
    {int size = mirrorMazeSize}) {
  if (mirrorMazeLayouts(deal, 0, size: size).isNotEmpty) return false;
  if (mirrorMazeLayouts(deal, 1, size: size).isNotEmpty) return false;
  return true;
}

/// Deals a Mirror Maze board that cannot be won with fewer than two mirrors.
///
/// The rule the generator holds itself to, through [mirrorMazeDealIsFair]:
/// there is no straight shot through the board, no single mirror that happens to
/// point the beam at the receiver, and a two-mirror layout is what the deal
/// costs. One mirror alone, of either kind, on any cell, always leaves the deal
/// unsolved, which is what makes "a misrouted beam stays unsolved" a fact and
/// not a hope.
///
/// Several two-mirror layouts win a given deal; [MirrorMazeDeal.answer] is one of
/// them, not the only one. See [mirrorMazeDealIsFair] for why that is not a
/// defect of this game: the win condition is the exit, not a layout.
class MirrorMazeGenerator {
  MirrorMazeGenerator({Random? random, this.size = mirrorMazeSize})
      : _random = random ?? Random();

  /// The mirror count every dealt board needs.
  static const int mirrorMazeDealDepth = 2;

  /// How many candidate layouts to try before falling back.
  static const int attempts = 400;

  /// A deal that passes every check, used if the random search ever fails. It
  /// is proven by `test/content/spatial_rule_tests_test.dart`, so it cannot go
  /// stale without a test going red. Not const: a `Point` key has no primitive
  /// equality, so a map of them cannot be a constant.
  static final MirrorMazeDeal fallback = MirrorMazeDeal(
    start: Point<int>(mirrorMazeSize - 1, 2),
    startDir: Point<int>(-1, 0),
    target: Point<int>(mirrorMazeSize - 1, 0),
    targetDir: Point<int>(1, 0),
    answer: <Point<int>, int>{
      Point<int>(2, 2): Mirror.backslash,
      Point<int>(2, 0): Mirror.slash,
    },
    depth: mirrorMazeDealDepth,
  );

  final Random _random;

  /// Board side length.
  final int size;

  final Map<String, bool> _fair = <String, bool>{};

  /// The next deal.
  MirrorMazeDeal next() {
    for (int attempt = 0; attempt < attempts; attempt++) {
      final MirrorMazeDeal? deal = _candidate();
      if (deal != null && _isFair(deal)) return deal;
    }
    return fallback;
  }

  /// A deal built from a random two-mirror layout, or null when the beam never
  /// reaches both mirrors.
  MirrorMazeDeal? _candidate() {
    final MirrorMazeStart start = _randomStart();
    final List<Point<int>> cells = <Point<int>>[
      for (int r = 0; r < size; r++)
        for (int c = 0; c < size; c++) Point<int>(r, c),
    ]..shuffle(_random);
    final Point<int> first = cells[0];
    final Point<int> second = cells[1];
    final Map<Point<int>, int> board = <Point<int>, int>{
      first: Mirror.kinds[_random.nextInt(Mirror.kinds.length)],
      second: Mirror.kinds[_random.nextInt(Mirror.kinds.length)],
    };

    final MirrorMazeTrace trace = traceBeam(
      mirrors: board,
      start: start.cell,
      startDir: start.direction,
      size: size,
    );
    if (!trace.exited) return null;
    if (trace.exitCell == start.cell) return null;
    if (trace.hit.length != mirrorMazeDealDepth) return null;

    return MirrorMazeDeal(
      start: start.cell,
      startDir: start.direction,
      target: trace.exitCell!,
      targetDir: trace.exitDir,
      answer: Map<Point<int>, int>.unmodifiable(trace.hit),
      depth: trace.hit.length,
    );
  }

  /// True when the deal passes [mirrorMazeDealIsFair]. Memoised because the
  /// generator keeps asking about the same small set of deals.
  ///
  /// The memo key is everything the verdict reads, not just the deal's edges: a
  /// key of start and exit alone would answer a question about a different
  /// `depth` and a different `answer` with the first deal's result.
  bool _isFair(MirrorMazeDeal deal) => _fair.putIfAbsent(
        _fairKey(deal),
        () => mirrorMazeDealIsFair(deal, size: size),
      );

  MirrorMazeStart _randomStart() {
    final int side = _random.nextInt(4);
    final int offset = _random.nextInt(size);
    switch (side) {
      case 0:
        return MirrorMazeStart(
          Point<int>(0, offset),
          const Point<int>(1, 0),
        );
      case 1:
        return MirrorMazeStart(
          Point<int>(size - 1, offset),
          const Point<int>(-1, 0),
        );
      case 2:
        return MirrorMazeStart(
          Point<int>(offset, 0),
          const Point<int>(0, 1),
        );
      default:
        return MirrorMazeStart(
          Point<int>(offset, size - 1),
          const Point<int>(0, -1),
        );
    }
  }
}

/// Everything [mirrorMazeDealIsFair] reads, as a string.
String _fairKey(MirrorMazeDeal deal) =>
    '${deal.key}|${deal.depth}|${_layoutKey(deal.answer)}';

String _layoutKey(Map<Point<int>, int> layout) {
  final List<Point<int>> cells = layout.keys.toList()
    ..sort((Point<int> a, Point<int> b) => a.x != b.x ? a.x - b.x : a.y - b.y);
  return cells.map((Point<int> c) => '${c.x},${c.y}:${layout[c]}').join(' ');
}
