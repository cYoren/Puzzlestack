/// Signpost, ported from Tatham's `signpost.c` (Janko's "arrow path").
///
/// Every cell carries an arrow, and the arrow points *along a ray* rather than
/// at a neighbour: the cell holding `k` must point at the cell holding `k+1`,
/// wherever that is on the line. Every number from 1 to N is used exactly once,
/// and a handful of them are given to start with.
///
/// The ray is what makes this more than a jigsaw. Two cells can be joined from
/// anywhere along the line, so the board is not a graph of neighbours but a set
/// of chains, and whether a set of given numbers pins the chains down is a fact
/// about the numbers, not about how they were placed. So the board is counted,
/// like every other deduction puzzle here.
///
/// The player's board is **the links**, not the numbers. `links[cell]` is the
/// cell that follows it; the numbers are read off the chains, which is why a
/// link can be moved without wiping out what the player already worked out, and
/// why a chain that has not met a given number yet shows no numbers at all
/// instead of guessing at them. Tatham's own board numbers those provisional
/// chains too, in colours; leaving them blank is the same information without
/// an arbitrary claim attached to it.
///
/// Tatham's answer to "how do you know the numbers are enough" is a solver that
/// adds numbers until it can finish, and then takes them away again while it
/// still can. That is the generator here, and the rules it uses are the rules
/// the harness grades against: a forced link, a refutation, and a lookahead.
library;

import 'dart:math';

import '../../../../core/deduction.dart';

/// The eight ray directions, in the order the arrows are stored.
///
/// `n` first and clockwise, so the opposite of a direction is four along.
const List<int> _dx = [0, 1, 1, 1, 0, -1, -1, -1];
const List<int> _dy = [-1, -1, 0, 1, 1, 1, 0, -1];

int _opposite(int direction) => (direction + 4) % 8;

/// The step an arrow direction points in, each of x and y being -1, 0 or 1.
(int, int) signpostStep(int direction) => (_dx[direction], _dy[direction]);

/// The direction index for a step of (-1, 0 or 1) in each axis.
int _directionOf(int stepX, int stepY) {
  for (var direction = 0; direction < 8; direction++) {
    if (_dx[direction] == stepX && _dy[direction] == stepY) return direction;
  }
  return -1;
}

/// One board and its answer.
class SignpostPuzzle {
  SignpostPuzzle({
    required this.rows,
    required this.cols,
    required List<int> dirs,
    required List<int> clues,
    required List<int> solution,
  })  : assert(dirs.length == rows * cols),
        assert(clues.length == rows * cols),
        assert(solution.length == rows * cols),
        dirs = List<int>.unmodifiable(dirs),
        clues = List<int>.unmodifiable(clues),
        solution = List<int>.unmodifiable(solution);

  final int rows;
  final int cols;

  /// The arrow in each cell, as an index into [_dx] and [_dy].
  final List<int> dirs;

  /// The numbers the board gives away, `0` where it gives none.
  final List<int> clues;

  /// The answer, as a number per cell. Kept for the hint's last resort and for
  /// the tests; the player's board is never checked against it.
  final List<int> solution;

  int get cellCount => rows * cols;

  int index(int row, int col) => row * cols + col;

  int rowOf(int cell) => cell ~/ cols;

  int colOf(int cell) => cell % cols;

  bool isClue(int cell) => clues[cell] > 0;

  int get clueCount => clues.where((clue) => clue > 0).length;

  /// The cell holding [number] in the answer.
  int cellOfNumber(int number) => solution.indexOf(number);
}

/// The three difficulties, which differ in the strength of reasoning the board
/// needs before they differ in size.
///
/// Signpost has one deduction worth the name — a link that is forced — so the
/// strength of the reasoning is what separates the tiers. Medium and hard are
/// both 5x5: the difference between them is the free ends and the rule the board
/// needs, not another row of cells. 6x6 was tried for hard and took twenty
/// seconds a board, which is not a difficulty, it is a hang.
enum SignpostDifficulty {
  easy(4, 4, 1, false),
  medium(5, 5, 2, false),
  hard(5, 5, 3, true);

  const SignpostDifficulty(this.rows, this.cols, this.level, this.freeEnds);

  final int rows;
  final int cols;

  /// The rule level the board must need — exactly, not at least. A board the
  /// forced link alone finishes is easy however big it is; a board that needs a
  /// refutation is not.
  final int level;

  /// Whether 1 and N are anywhere rather than pinned to the corners. Free ends
  /// cost the player the two anchors that are easiest to reason from, which is
  /// most of what makes the largest tier hard.
  final bool freeEnds;
}

/// A board mid-solve, with everything that follows from its links.
///
/// Numbers are derived rather than stored, so a link can be rewired without
/// rewriting the numbers: a chain that has met a given number carries the
/// numbers that number implies, and a chain that has not says nothing yet.
class SignpostPosition {
  SignpostPosition._({
    required this.links,
    required this.prev,
    required this.numbers,
    required this.numbersByValue,
    required this.chainOf,
    required this.chainLength,
    required this.impossible,
  });

  /// For each cell, the cell that follows it, or -1.
  final List<int> links;

  /// For each cell, the cell before it, or -1. Derived from [links].
  final List<int> prev;

  /// The number each cell holds, or 0 when the chain has no given number to
  /// read it from.
  final List<int> numbers;

  /// For each number, the cell holding it, or -1.
  final List<int> numbersByValue;

  /// Which chain each cell belongs to. A lone cell is a chain of one.
  final List<int> chainOf;

  /// How many cells each chain has.
  final List<int> chainLength;

  /// True when the links cannot be a partial answer: two cells pointing at the
  /// same place, a loop, or numbers that disagree with each other.
  final bool impossible;

  /// Reads every chain and works out what it already says.
  static SignpostPosition of(SignpostPuzzle puzzle, List<int> links) {
    final count = puzzle.cellCount;
    final prev = List<int>.filled(count, -1);
    var impossible = false;

    for (var cell = 0; cell < count; cell++) {
      final next = links[cell];
      if (next < 0 || next >= count) continue;
      // A cell has exactly one predecessor; two arrows into it is a dead board.
      if (prev[next] != -1) impossible = true;
      prev[next] = cell;
    }

    // Every cell belongs to exactly one path. Anything not reachable from a
    // head is inside a loop, which no answer can contain.
    final chainOf = List<int>.filled(count, -1);
    final chainLength = <int>[];
    for (var cell = 0; cell < count; cell++) {
      if (prev[cell] != -1) continue;
      final id = chainLength.length;
      var walk = cell;
      var length = 0;
      while (walk >= 0 && chainOf[walk] == -1) {
        chainOf[walk] = id;
        length++;
        final next = links[walk];
        walk = (next >= 0 && next < count) ? next : -1;
      }
      chainLength.add(length);
    }
    if (chainOf.contains(-1)) impossible = true;

    final numbers = List<int>.filled(count, 0);
    final numbersByValue = List<int>.filled(count + 1, -1);

    for (var id = 0; id < chainLength.length; id++) {
      var head = -1;
      for (var cell = 0; cell < count; cell++) {
        if (chainOf[cell] == id && prev[cell] == -1) {
          head = cell;
          break;
        }
      }
      if (head < 0) continue;

      // Where does this chain start? Every given number in it answers that
      // question, and they all have to agree.
      int? headNumber;
      var position = 0;
      var walk = head;
      while (walk >= 0) {
        final clue = puzzle.clues[walk];
        if (clue > 0) {
          final startsAt = clue - position;
          if (headNumber == null) {
            headNumber = startsAt;
          } else if (headNumber != startsAt) {
            impossible = true;
          }
        }
        position++;
        final next = links[walk];
        walk = (next >= 0 && next < count) ? next : -1;
        if (position > count) break;
      }

      // A chain with no given number has no number to read off, so it stays
      // blank. That is the honest answer: it could sit anywhere.
      if (headNumber == null) continue;

      position = 0;
      walk = head;
      while (walk >= 0) {
        final value = headNumber + position;
        if (value < 1 || value > count) {
          // A chain can grow past the ends of the sequence, and once it does
          // the board can never be finished.
          impossible = true;
        } else {
          if (numbersByValue[value] != -1) impossible = true;
          numbersByValue[value] = walk;
          numbers[walk] = value;
        }
        position++;
        final next = links[walk];
        walk = (next >= 0 && next < count) ? next : -1;
        if (position > count) break;
      }
    }

    return SignpostPosition._(
      links: links,
      prev: prev,
      numbers: numbers,
      numbersByValue: numbersByValue,
      chainOf: chainOf,
      chainLength: chainLength,
      impossible: impossible,
    );
  }

  /// How many cells of the chain are already joined.
  int sizeOf(int cell) => chainLength[chainOf[cell]];
}

/// True when [from]'s arrow runs through [to].
bool _pointsAt(SignpostPuzzle puzzle, int from, int to) {
  final stepY = puzzle.rowOf(to) - puzzle.rowOf(from);
  final stepX = puzzle.colOf(to) - puzzle.colOf(from);
  if (stepX == 0 && stepY == 0) return false;
  // A ray only goes in one of eight directions, so an off-axis cell is not on
  // it even if the arrow points at it.
  if (stepX != 0 && stepY != 0 && stepX.abs() != stepY.abs()) return false;
  final direction = _directionOf(stepX.sign, stepY.sign);
  return puzzle.dirs[from] == direction;
}

/// How many numbers above [number] are still unused, before the next given one.
int _roomAbove(SignpostPosition position, int total, int number) {
  var room = 0;
  for (var value = number + 1; value <= total; value++) {
    if (position.numbersByValue[value] >= 0) break;
    room++;
  }
  return room;
}

/// How many numbers below [number] are still unused.
int _roomBelow(SignpostPosition position, int number) {
  var room = 0;
  for (var value = number - 1; value >= 1; value--) {
    if (position.numbersByValue[value] >= 0) break;
    room++;
  }
  return room;
}

/// True when [to] may follow [from] on the board as it stands.
///
/// This is the whole rule book: an arrow to follow, one predecessor each, no
/// loops, consecutive numbers when both ends are known, and enough room in the
/// sequence for a chain that is not known yet. Tatham's `isvalidmove`, with the
/// provisional numbering taken out.
bool _legal(
  SignpostPosition position,
  SignpostPuzzle puzzle,
  int from,
  int to,
) {
  if (from == to) return false;
  if (from < 0 || from >= puzzle.cellCount) return false;
  if (to < 0 || to >= puzzle.cellCount) return false;
  if (position.links[from] >= 0) return false;
  if (position.prev[to] >= 0) return false;
  if (!_pointsAt(puzzle, from, to)) return false;

  final total = puzzle.cellCount;
  final numberFrom = position.numbers[from];
  final numberTo = position.numbers[to];

  // The last number points at nothing, and nothing precedes the first.
  if (numberFrom == total) return false;
  if (numberTo == 1) return false;

  // Joining two cells that are already in the same chain would make a loop.
  if (position.chainOf[from] == position.chainOf[to]) return false;

  if (numberFrom > 0 && numberTo > 0) return numberTo == numberFrom + 1;

  if (numberFrom > 0) {
    // The whole chain of [to] lands above [from], and it has to fit in the
    // numbers that are still free there.
    final size = position.sizeOf(to);
    return size <= _roomAbove(position, total, numberFrom);
  }

  if (numberTo > 0) {
    final size = position.sizeOf(from);
    return size <= _roomBelow(position, numberTo);
  }

  return true;
}

/// A board a deduction solver can work on: the links are the decisions.
class SignpostModel implements DeductionModel<SignpostModel> {
  SignpostModel(this.puzzle, List<int> links) : links = List<int>.from(links);

  /// A fresh board: every cell alone, so only the given numbers show.
  SignpostModel.blank(this.puzzle)
      : links = List<int>.filled(puzzle.cellCount, -1);

  final SignpostPuzzle puzzle;
  final List<int> links;

  SignpostPosition? _position;

  SignpostPosition get position =>
      _position ??= SignpostPosition.of(puzzle, links);

  bool get impossible => position.impossible;

  /// Joins two cells. Legality is the caller's business; this only records it.
  void link(int from, int to) {
    links[from] = to;
    _position = null;
  }

  @override
  SignpostModel copy() => SignpostModel(puzzle, links);

  /// Every cell numbered, and all of it in **one** chain.
  ///
  /// Both halves matter. Numbers alone are not enough: two separate chains can
  /// each be anchored by a given number and number every cell between them —
  /// 1..2 and 3..4 — while the 2 never points at the 3. That board looks
  /// finished and is not, so the count of tails has to be one.
  @override
  bool get isComplete {
    final current = position;
    if (current.impossible) return false;
    final total = puzzle.cellCount;
    var tails = 0;
    for (var cell = 0; cell < total; cell++) {
      if (links[cell] < 0) tails++;
      final number = current.numbers[cell];
      if (number < 1 || number > total) return false;
    }
    return tails == 1;
  }

  /// Where the rules ran out.
  ///
  /// The cell with the fewest places to point is the cheapest one to guess on,
  /// which is what keeps the count from fanning out.
  @override
  Choice? get choice {
    List<int>? best;
    var slot = -1;
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final candidates = _candidates(this, cell);
      if (candidates.isEmpty) continue;
      if (best == null || candidates.length < best.length) {
        best = candidates;
        slot = cell;
      }
    }
    if (best == null) return null;
    return Choice(slot, best);
  }

  @override
  SignpostModel assume(int slot, int value) {
    final next = copy();
    next.link(slot, value);
    return next;
  }
}

/// Every cell [cell] could point at, as the board stands.
List<int> _candidates(SignpostModel model, int cell) {
  if (model.links[cell] >= 0) return const [];
  final position = model.position;
  if (position.numbers[cell] == model.puzzle.cellCount) return const [];

  final result = <int>[];
  for (var other = 0; other < model.puzzle.cellCount; other++) {
    if (_legal(position, model.puzzle, cell, other)) result.add(other);
  }
  return result;
}

/// The engine behind a rule: a link nobody can avoid, and what to do about the
/// rest.
///
/// With no [refutes], this is Tatham's solver — link wherever only one place is
/// possible, from either end, until nothing more is forced. With [refutes], a
/// candidate the board cannot survive is dropped first, which is how the two
/// harder tiers get anything the forced link cannot see.
///
/// Only a cell with exactly two candidates is doubted. That is measured, not
/// tidy: refuting every candidate on a 5x5 board costs seconds a board, and a
/// cell with three or more candidates almost never loses all but one, so the
/// work would buy nothing.
int _settle(
  SignpostModel model,
  bool Function(SignpostModel probe, int from, int to)? refutes,
) {
  if (model.impossible) return -1;
  final count = model.puzzle.cellCount;
  var settled = 0;

  for (var cell = 0; cell < count; cell++) {
    if (model.links[cell] >= 0) continue;
    if (model.position.numbers[cell] == count) continue;

    var options = _candidates(model, cell);
    if (options.isEmpty) return -1;
    if (refutes != null && options.length == 2) {
      options = options.where((to) => !refutes(model, cell, to)).toList();
      if (options.isEmpty) return -1;
    }
    if (options.length != 1) continue;
    model.link(cell, options.first);
    settled++;
  }

  for (var cell = 0; cell < count; cell++) {
    if (model.position.prev[cell] >= 0) continue;
    if (model.position.numbers[cell] == 1) continue;

    var options = [
      for (var from = 0; from < count; from++)
        if (from != cell && _legal(model.position, model.puzzle, from, cell))
          from,
    ];
    if (options.isEmpty) return -1;
    if (refutes != null && options.length == 2) {
      options = options.where((from) => !refutes(model, from, cell)).toList();
      if (options.isEmpty) return -1;
    }
    if (options.length != 1) continue;
    model.link(options.first, cell);
    settled++;
  }

  return settled;
}

/// A link nobody can avoid: one place to point, or one arrow that can reach.
class SignpostForcedRule implements DeductionRule<SignpostModel> {
  const SignpostForcedRule();

  @override
  int get level => 1;

  @override
  String get name => 'forced link';

  @override
  int apply(SignpostModel model) => _settle(model, null);
}

/// Runs [rules] over [model] for a few rounds and reports whether it survived.
///
/// A bounded propagation rather than a full solve: the point of a lookahead is
/// to notice a dead end quickly, and a dead end shows up within a few rounds.
bool _consistent(
  SignpostModel model,
  List<DeductionRule<SignpostModel>> rules, {
  int maxRounds = 12,
}) {
  for (var round = 0; round < maxRounds; round++) {
    var changed = false;
    for (final rule in rules) {
      final settled = rule.apply(model);
      if (settled < 0) return false;
      if (settled > 0) changed = true;
    }
    if (!changed) break;
  }
  return true;
}

/// A link whose consequences cannot be finished.
///
/// The second strength: assume the link, let the forced rule work over it, and
/// drop it when the board dies. The forced link only ever looks at one move;
/// this one looks at the move and everything it causes, which is what finds the
/// dead ends that are two steps away instead of one.
class SignpostRefuteRule implements DeductionRule<SignpostModel> {
  const SignpostRefuteRule();

  static const List<DeductionRule<SignpostModel>> _forced = [
    SignpostForcedRule(),
  ];

  @override
  int get level => 2;

  @override
  String get name => 'refutation';

  @override
  int apply(SignpostModel model) => _settle(model, (probe, from, to) {
        final assumed = probe.assume(from, to);
        return !_consistent(assumed, _forced);
      });
}

/// A link whose consequences cannot be finished even with the refutation.
///
/// The deepest strength here: assume the link and run both cheaper rules over
/// it. Two rounds is enough to expose a dead end and cheap enough to stay
/// inside a generation budget.
class SignpostLookaheadRule implements DeductionRule<SignpostModel> {
  const SignpostLookaheadRule();

  static const List<DeductionRule<SignpostModel>> _deeper = [
    SignpostForcedRule(),
    SignpostRefuteRule(),
  ];

  @override
  int get level => 3;

  @override
  String get name => 'lookahead';

  @override
  int apply(SignpostModel model) => _settle(model, (probe, from, to) {
        final assumed = probe.assume(from, to);
        return !_consistent(assumed, _deeper, maxRounds: 1);
      });
}

/// The rules, easy idea first.
const List<DeductionRule<SignpostModel>> signpostRules = [
  SignpostForcedRule(),
  SignpostRefuteRule(),
  SignpostLookaheadRule(),
];

/// Generates boards, checks answers and grades them.
class SignpostEngine {
  const SignpostEngine();

  // ----------------------------------------------------------------- rules

  bool legal(
          SignpostPosition position, SignpostPuzzle puzzle, int from, int to) =>
      _legal(position, puzzle, from, to);

  /// The cells [cell] could point at, on the board as it stands.
  List<int> candidatesFor(
    SignpostPuzzle puzzle,
    List<int> links,
    int cell,
  ) =>
      _candidates(SignpostModel(puzzle, links), cell);

  /// True when the links are the answer.
  ///
  /// Checked against the arrows rather than against the stored answer, so a
  /// player who finds a different chain is still right — and so a bug in the
  /// generator cannot hide behind its own answer key.
  bool isSolved(SignpostPuzzle puzzle, List<int> links) {
    final position = SignpostPosition.of(puzzle, links);
    if (position.impossible) return false;
    final total = puzzle.cellCount;
    for (var cell = 0; cell < total; cell++) {
      final number = position.numbers[cell];
      if (number < 1 || number > total) return false;
      if (number == total) continue;
      final next = position.numbersByValue[number + 1];
      if (next < 0) return false;
      // The link has to be on the board, not merely on the line: two chains
      // that happen to point at each other are still two chains.
      if (links[cell] != next) return false;
      if (!_pointsAt(puzzle, cell, next)) return false;
    }
    return true;
  }

  /// True when the rules up to [level] finish the board on their own.
  ///
  /// Every rule is sound — it only ever makes a link that the answer must
  /// contain — so a board the rules can finish has exactly one answer. That is
  /// why the generator can strip numbers against this instead of counting, and
  /// why the tests count separately.
  bool solvableAt(SignpostPuzzle puzzle, int level) {
    final rules = signpostRules
        .where((rule) => rule.level <= level)
        .toList(growable: false);
    final outcome = deduce(SignpostModel.blank(puzzle), rules);
    return outcome.consistent && outcome.complete;
  }

  /// The lowest rule level that finishes the board, or null when a guess is
  /// needed.
  int? levelOf(SignpostPuzzle puzzle) =>
      solvingLevel(SignpostModel.blank(puzzle), signpostRules);

  /// The harness's verdict: how many answers, and how hard the reasoning is.
  PuzzleRating rateBoard(SignpostPuzzle puzzle) =>
      rate(SignpostModel.blank(puzzle), signpostRules);

  /// The links of the stored answer.
  List<int> answerLinks(SignpostPuzzle puzzle) {
    final links = List<int>.filled(puzzle.cellCount, -1);
    final total = puzzle.cellCount;
    for (var cell = 0; cell < total; cell++) {
      final number = puzzle.solution[cell];
      if (number >= total) continue;
      links[cell] = puzzle.cellOfNumber(number + 1);
    }
    return links;
  }

  /// One link the rules can prove, from the board as it stands.
  ///
  /// The rules are run to a fixed point first, so the step named is one the
  /// player could have reasoned to from where they are — not a peek at the
  /// stored answer.
  ({int from, int to})? hint(SignpostPuzzle puzzle, List<int> links) {
    final model = SignpostModel(puzzle, links);
    final before = List<int>.from(model.links);
    final outcome = deduce(model, signpostRules);
    if (outcome.consistent) {
      for (var cell = 0; cell < before.length; cell++) {
        final now = model.links[cell];
        if (now >= 0 && now != before[cell]) return (from: cell, to: now);
      }
    }

    // The rules have nothing to say from here, which usually means the player
    // has taken a wrong turn. Offer the answer's link instead, and only where
    // it is still a legal move from the board they are looking at.
    final answer = answerLinks(puzzle);
    final position = SignpostPosition.of(puzzle, before);
    for (var cell = 0; cell < before.length; cell++) {
      final expected = answer[cell];
      if (expected < 0 || expected == before[cell]) continue;
      if (_legal(position, puzzle, cell, expected)) {
        return (from: cell, to: expected);
      }
    }
    return null;
  }

  // ------------------------------------------------------------- generator

  /// A board that needs [difficulty]'s rule level.
  ///
  /// The level is a target, not a promise. A hard board takes a few hundred
  /// milliseconds to find and the tier is only reached some of the time, and a
  /// screen that thinks for ten seconds is worse than a board that is a little
  /// easier than asked for. So the search runs inside [budget] and returns the
  /// hardest board it found, which is always a real one: [strip] only gives
  /// numbers away while the rules still finish the board, so every candidate is
  /// unique and every candidate is playable. Raise [budget] when the exact
  /// level is what is being checked, which is what the tests do.
  SignpostPuzzle generate(
    SignpostDifficulty difficulty, {
    Random? random,
    Duration budget = const Duration(milliseconds: 900),
    int attempts = 400,
  }) {
    final rng = random ?? Random();
    final watch = Stopwatch()..start();
    SignpostPuzzle? hardest;
    var hardestLevel = 0;

    for (var attempt = 0; attempt < attempts; attempt++) {
      if (watch.elapsed > budget) break;

      final filled = _fill(difficulty, rng);
      if (filled == null) continue;

      final clues = _strip(filled, difficulty, rng);
      if (clues == null) continue;

      final puzzle = SignpostPuzzle(
        rows: difficulty.rows,
        cols: difficulty.cols,
        dirs: filled.dirs,
        clues: clues,
        solution: filled.numbers,
      );
      final level = levelOf(puzzle) ?? 1;
      if (level == difficulty.level) return puzzle;
      if (level > hardestLevel) {
        hardest = puzzle;
        hardestLevel = level;
      }
    }

    if (hardest != null) return hardest;
    throw StateError(
      'could not build a ${difficulty.rows}x${difficulty.cols} Signpost board',
    );
  }

  /// A random full path through every cell, with an arrow in each cell that
  /// points at its successor.
  ///
  /// Tatham's `new_game_fill`: grow from the head and the tail at once, taking
  /// any unclaimed cell along a ray, and keep going while only one way is left.
  /// The two ends meet in the middle and are joined by whatever direction runs
  /// between them — which fails when they are not on a line, and that is the
  /// common case worth retrying.
  ({List<int> dirs, List<int> numbers})? _fill(
    SignpostDifficulty difficulty,
    Random rng,
  ) {
    final rows = difficulty.rows;
    final cols = difficulty.cols;
    final count = rows * cols;
    if (count < 2) return null;

    final dirs = List<int>.filled(count, 0);
    final numbers = List<int>.filled(count, 0);

    var head = difficulty.freeEnds ? rng.nextInt(count) : 0;
    var tail = difficulty.freeEnds ? rng.nextInt(count) : count - 1;
    if (difficulty.freeEnds) {
      while (tail == head) {
        tail = rng.nextInt(count);
      }
    } else if (head == tail) {
      return null;
    }

    numbers[head] = 1;
    numbers[tail] = count;
    var filled = 2;

    while (filled < count) {
      var options = _visible(numbers, rows, cols, head);
      do {
        if (options.isEmpty) return null;
        final pick = options[rng.nextInt(options.length)];
        dirs[head] = pick.direction;
        numbers[pick.cell] = numbers[head] + 1;
        filled++;
        head = pick.cell;
        options = _visible(numbers, rows, cols, head);
      } while (options.length == 1);

      if (filled == count) break;

      options = _visible(numbers, rows, cols, tail);
      do {
        if (options.isEmpty) return null;
        final pick = options[rng.nextInt(options.length)];
        dirs[pick.cell] = _opposite(pick.direction);
        numbers[pick.cell] = numbers[tail] - 1;
        filled++;
        tail = pick.cell;
        options = _visible(numbers, rows, cols, tail);
      } while (options.length == 1);
    }

    final join = _directionBetween(rows, cols, head, tail);
    if (join < 0) return null;
    dirs[head] = join;
    return (dirs: dirs, numbers: numbers);
  }

  /// Every unclaimed cell along each of the eight rays out of [cell].
  List<({int cell, int direction})> _visible(
    List<int> numbers,
    int rows,
    int cols,
    int cell,
  ) {
    final result = <({int cell, int direction})>[];
    final row = cell ~/ cols;
    final col = cell % cols;
    for (var direction = 0; direction < 8; direction++) {
      var r = row + _dy[direction];
      var c = col + _dx[direction];
      while (r >= 0 && r < rows && c >= 0 && c < cols) {
        final other = r * cols + c;
        if (numbers[other] == 0) {
          result.add((cell: other, direction: direction));
        }
        r += _dy[direction];
        c += _dx[direction];
      }
    }
    return result;
  }

  int _directionBetween(int rows, int cols, int from, int to) {
    final stepY = (to ~/ cols) - (from ~/ cols);
    final stepX = (to % cols) - (from % cols);
    if (stepX == 0 && stepY == 0) return -1;
    if (stepX != 0 && stepY != 0 && stepX.abs() != stepY.abs()) return -1;
    return _directionOf(stepX.sign, stepY.sign);
  }

  /// Takes the answer away again, keeping only what the rules need.
  ///
  /// Tatham's `new_game_strip`: start with 1 and N, add given numbers at random
  /// until the board falls to reasoning, then take each one back out while it
  /// still does. The result is the fewest numbers that still solve at the
  /// target strength — so the given count *is* the difficulty.
  List<int>? _strip(
    ({List<int> dirs, List<int> numbers}) filled,
    SignpostDifficulty difficulty,
    Random rng,
  ) {
    final total = filled.numbers.length;
    final clues = List<int>.filled(total, 0);
    final startsAt = filled.numbers.indexOf(1);
    final endsAt = filled.numbers.indexOf(total);
    clues[startsAt] = 1;
    clues[endsAt] = total;

    final order = List<int>.generate(total, (index) => index)..shuffle(rng);

    SignpostPuzzle build() => SignpostPuzzle(
          rows: difficulty.rows,
          cols: difficulty.cols,
          dirs: filled.dirs,
          clues: List<int>.from(clues),
          solution: filled.numbers,
        );

    // Always arm the board at the cheapest strength first, so there is
    // something solvable to take numbers away from.
    if (!solvableAt(build(), 1)) {
      var solved = false;
      for (final cell in order) {
        if (clues[cell] > 0) continue;
        clues[cell] = filled.numbers[cell];
        if (solvableAt(build(), 1)) {
          solved = true;
          break;
        }
      }
      if (!solved) return null;

      // Then take them back out, keeping only what the rules still finish.
      for (final cell in order) {
        final clue = clues[cell];
        if (clue <= 0 || clue == 1 || clue == total) continue;
        clues[cell] = 0;
        if (!solvableAt(build(), 1)) clues[cell] = clue;
      }
    }

    // The harder tiers want the board to *need* the stronger rule, so give
    // numbers away again for as long as the target strength still finishes it.
    if (difficulty.level > 1) {
      for (final cell in order) {
        final clue = clues[cell];
        if (clue <= 0 || clue == 1 || clue == total) continue;
        clues[cell] = 0;
        if (!solvableAt(build(), difficulty.level)) clues[cell] = clue;
      }
    }

    return clues;
  }
}
