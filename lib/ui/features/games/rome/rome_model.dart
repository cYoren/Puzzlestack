/// Rome as a deduction board.
///
/// A cell's mask says which arrows it can still hold. A goal is not part of that
/// question: it carries the single [kRomeGoalBit] from the start, because a
/// goal has no arrow and nothing about it is ever decided.
///
/// Three rules, easy to hard, and the third is the whole game:
///
///  * [RomeAreas] — an area holds no repeated arrow (level 1);
///  * [RomeEdges] — an arrow that leaves the grid is impossible (level 1);
///  * [RomeReach] — no chain may end anywhere but at a goal (level 2).
///
/// The third rule is a property of the whole board, not of a cell, so it is
/// written as a reachability fixpoint: a cell is *good* when some arrow still
/// open to it steps to a good cell, goals are good by definition, and the
/// least fixpoint of that is the set of cells that can still end at a goal.
/// A cell that is not good is a contradiction, and an arrow that steps to a
/// cell that is not good is impossible. That one idea covers every way a chain
/// can die — a loop of decided arrows, a loop of candidates, a chain reaching
/// the edge — which is why the loop rule the C original spells out separately
/// is not a rule here: it is the same fixpoint, one step in.
///
/// Masks are `int` bits and there are five of them at most, so they are safe on
/// every target, including the web build that truncates bitwise integers to 32
/// bits.
library;

import '../../../../core/deduction.dart';
import 'rome_puzzle.dart';

/// The bit for [arrow] (`0..3`).
int romeBit(int arrow) => 1 << arrow;

/// Every arrow a cell can hold.
const int kRomeArrowMask = 0xF;

/// The one bit a goal carries, so a goal is a decided cell that is not an arrow.
const int kRomeGoalBit = 1 << kRomeGoal;

int _popCount(int mask) {
  var count = 0;
  while (mask != 0) {
    mask &= mask - 1;
    count++;
  }
  return count;
}

/// The value of a single-bit mask: an arrow `0..3`, or [kRomeGoal].
int _valueOf(int mask) => mask.bitLength - 1;

class RomeModel implements DeductionModel<RomeModel> {
  RomeModel({
    required this.puzzle,
    required this.masks,
    this.broken = false,
  });

  /// A fresh board: four arrows everywhere, a goal bit in the goals, then the
  /// printed arrows.
  ///
  /// The givens go straight into the masks, **without** propagating. That is not
  /// an optimisation: propagation is what the rules do, and a fresh model that
  /// had already run it would come back to [solvingLevel] finished, so every
  /// board would report level 0 and the app's difficulty would be a lie. A given
  /// that contradicts another is found by the first rule pass, which is exactly
  /// where a contradiction belongs.
  factory RomeModel.fresh(RomePuzzle puzzle) {
    final masks = [
      for (var cell = 0; cell < puzzle.cellCount; cell++)
        puzzle.isGoal(cell) ? kRomeGoalBit : kRomeArrowMask,
    ];
    var broken = false;
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final given = puzzle.given(cell);
      if (given == kRomeNoGiven) continue;
      if (puzzle.isGoal(cell) || given < kRomeUp || given > kRomeLeft) {
        // A goal holds no arrow, and nothing else is an arrow.
        broken = true;
        continue;
      }
      masks[cell] = romeBit(given);
    }
    return RomeModel(puzzle: puzzle, masks: masks, broken: broken);
  }

  final RomePuzzle puzzle;

  /// Per cell, the arrows it can still hold — or the goal bit alone.
  final List<int> masks;

  /// Set when the board contradicts itself. A rule reports it as a contradiction
  /// instead of pretending the board is still workable.
  bool broken;

  int get n => puzzle.n;

  int get cellCount => puzzle.cellCount;

  @override
  RomeModel copy() =>
      RomeModel(puzzle: puzzle, masks: [...masks], broken: broken);

  @override
  bool get isComplete {
    if (broken) return false;
    for (final mask in masks) {
      if (_popCount(mask) != 1) return false;
    }
    // Decided and correct are two questions, and the counter trusts this one: a
    // board can be complete and wrong.
    return puzzle.isSolution(values);
  }

  @override
  Choice? get choice {
    var best = -1;
    var bestCount = 99;
    for (var cell = 0; cell < cellCount; cell++) {
      final count = _popCount(masks[cell]);
      if (count < 2 || count >= bestCount) continue;
      best = cell;
      bestCount = count;
    }
    if (best < 0) return null;
    return Choice(best, candidates(best));
  }

  @override
  RomeModel assume(int slot, int value) {
    final next = copy();
    if (next.set(slot, value) < 0) next.broken = true;
    return next;
  }

  /// The board as values, with [kRomeBlank] where nothing is decided.
  ///
  /// Only a complete board is all values; asking an open board for its values is
  /// asking a question with no answer, which is why the counter checks
  /// [isComplete] first.
  List<int> get values => [
        for (final mask in masks)
          _popCount(mask) == 1 ? _valueOf(mask) : kRomeBlank,
      ];

  /// The arrow of [cell], or [kRomeGoal], or null when it is not decided.
  int? valueAt(int cell) =>
      _popCount(masks[cell]) == 1 ? _valueOf(masks[cell]) : null;

  bool isDecided(int cell) => _popCount(masks[cell]) == 1;

  /// The arrows [cell] can still hold. Empty for a goal.
  List<int> candidates(int cell) => [
        for (var arrow = kRomeUp; arrow <= kRomeLeft; arrow++)
          if (masks[cell] & romeBit(arrow) != 0) arrow,
      ];

  /// Writes [value] in [cell] and propagates. -1 on a contradiction, otherwise
  /// the number of cells this settled.
  int set(int cell, int value) {
    final bit = 1 << value;
    if (masks[cell] & bit == 0) {
      broken = true;
      return -1;
    }
    var news = 0;
    if (masks[cell] != bit) {
      masks[cell] = bit;
      news++;
    }
    final pushed = _propagate();
    if (pushed < 0) return -1;
    return news + pushed;
  }

  /// Removes [symbols] from [cell], as a mask of bits. Does not propagate;
  /// [set] does.
  int eliminate(int cell, int symbols) {
    if (masks[cell] & symbols == 0) return 0;
    final left = masks[cell] & ~symbols;
    if (left == 0) {
      broken = true;
      return -1;
    }
    masks[cell] = left;
    return 1;
  }

  /// Runs the two rules a single written arrow implies, until nothing moves.
  ///
  /// They feed each other — an area single is often only found after the edge
  /// rule has trimmed a corner cell — so this is one loop over both, not two
  /// passes in a fixed order. This is the only place that propagation lives, so
  /// [RomeAreas], [RomeEdges] and [set] cannot disagree about it.
  ///
  /// [RomeReach] is deliberately **not** in here. It is the level 2 rule, and a
  /// level 1 rule that quietly ran it would report level 1 for a board that
  /// needs level 2 — a difficulty the app would then be lying about.
  int _propagate() {
    var news = 0;
    var moved = true;
    while (moved) {
      moved = false;
      for (final step in [_edges, _areas]) {
        final changed = step();
        if (changed < 0) return -1;
        if (changed == 0) continue;
        news += changed;
        moved = true;
      }
    }
    return news;
  }

  /// Rule 2a: nothing points off the board.
  ///
  /// A decided arrow that leaves the grid is a contradiction, not an
  /// elimination: there is nothing left to take away.
  int _edges() {
    var news = 0;
    for (var cell = 0; cell < cellCount; cell++) {
      if (puzzle.isGoal(cell)) continue;
      final mask = masks[cell];
      if (_popCount(mask) == 1) {
        if (puzzle.neighbour(cell, _valueOf(mask)) == null) {
          broken = true;
          return -1;
        }
        continue;
      }
      for (var arrow = kRomeUp; arrow <= kRomeLeft; arrow++) {
        if (mask & romeBit(arrow) == 0) continue;
        if (puzzle.neighbour(cell, arrow) != null) continue;
        final changed = eliminate(cell, romeBit(arrow));
        if (changed < 0) return -1;
        news += changed;
      }
    }
    return news;
  }

  /// Rule 1: an area holds no repeated arrow.
  ///
  /// A decided arrow leaves the rest of its area. When all four cells of an area
  /// are arrows, the area holds each of the four exactly once, so an arrow with
  /// a single home is decided there — the one hidden single this game has, and
  /// it only exists because an area is never bigger than the number of arrows.
  int _areas() {
    var news = 0;
    for (var area = 0; area < puzzle.areaCount; area++) {
      final cells = puzzle.areaCells(area);
      final arrows = [
        for (final cell in cells)
          if (!puzzle.isGoal(cell)) cell
      ];
      final taken = <int>{};
      for (final cell in arrows) {
        final value = valueAt(cell);
        if (value == null) continue;
        if (!taken.add(value)) {
          broken = true;
          return -1;
        }
      }
      for (final cell in arrows) {
        if (isDecided(cell)) continue;
        for (final arrow in taken) {
          final changed = eliminate(cell, romeBit(arrow));
          if (changed < 0) return -1;
          news += changed;
        }
      }
      // Four cells and four arrows: the area is a line of a four-symbol Latin
      // square, so every arrow has a home here. Fewer arrow cells than that and
      // an arrow is simply absent from the area, and a single home proves
      // nothing.
      if (arrows.length != kRomeArrowCount) continue;
      for (var arrow = kRomeUp; arrow <= kRomeLeft; arrow++) {
        final homes = [
          for (final cell in arrows)
            if (masks[cell] & romeBit(arrow) != 0) cell
        ];
        if (homes.isEmpty) {
          broken = true;
          return -1;
        }
        if (homes.length > 1) continue;
        if (isDecided(homes.single)) continue;
        final changed = set(homes.single, arrow);
        if (changed < 0) return -1;
        news += changed;
      }
    }
    return news;
  }

  /// Rule 3: every chain has to end at a goal.
  ///
  /// Two moves, and the second is the one that cracks a board.
  ///
  /// **Can it reach one?** [goodCells] is the least fixpoint of "some open arrow
  /// steps to a good cell", starting from the goals. A cell outside it can never
  /// end at a goal, so the board contradicts itself; an arrow that steps outside
  /// it walks into a dead end, so it goes. This one idea covers every way a chain
  /// dies at once — a loop of decided arrows, a loop of candidates, a chain into
  /// the edge — which is why the loop rule the C original spells out separately
  /// is not a rule here: it is this fixpoint, one step in.
  ///
  /// **Does it walk through me?** That question is what "can it reach one?" can
  /// not answer. A cell can reach a goal *through the cell it is deciding*: then
  /// choosing to point at it closes a loop, and the fixpoint still calls both of
  /// them good, because it only asks whether *some* route exists. So for every
  /// open cell this runs the same fixpoint with that cell taken out of the board
  /// and drops any arrow whose target can no longer reach a goal without going
  /// through it. A target whose every route comes back through the cell pointing
  /// at it is a loop, and this is the cheapest honest way to see it.
  int _reach() {
    final good = goodCells();
    var news = 0;
    for (var cell = 0; cell < cellCount; cell++) {
      if (puzzle.isGoal(cell)) continue;
      if (!good[cell]) {
        broken = true;
        return -1;
      }
      if (isDecided(cell)) continue;
      for (final arrow in candidates(cell)) {
        final next = puzzle.neighbour(cell, arrow);
        if (next != null && good[next]) continue;
        final changed = eliminate(cell, romeBit(arrow));
        if (changed < 0) return -1;
        news += changed;
      }
    }
    // Only once the cheap move has nothing left to say: each of these runs the
    // whole fixpoint again, so it is the expensive half of the rule.
    if (news > 0) return news;
    for (var cell = 0; cell < cellCount; cell++) {
      if (puzzle.isGoal(cell) || isDecided(cell)) continue;
      final without = goodCells(blocked: cell);
      for (final arrow in candidates(cell)) {
        final next = puzzle.neighbour(cell, arrow);
        if (next == null || without[next]) continue;
        final changed = eliminate(cell, romeBit(arrow));
        if (changed < 0) return -1;
        news += changed;
      }
    }
    return news;
  }

  /// The cells from which some chain of open arrows still reaches a goal.
  ///
  /// A goal is good by definition, and a cell is good when one of its open
  /// arrows steps to a good cell — the least fixpoint, so it only ever says
  /// "possible", never "forced". [blocked] takes one cell out of the board, as
  /// if it could not be walked through; that is how [RomeReach] asks whether a
  /// chain can get home without doubling back on itself.
  List<bool> goodCells({int blocked = -1}) {
    final good = List<bool>.filled(cellCount, false);
    for (final goal in puzzle.goals) {
      good[goal] = true;
    }
    var moved = true;
    while (moved) {
      moved = false;
      for (var cell = 0; cell < cellCount; cell++) {
        if (good[cell] || cell == blocked) continue;
        for (final arrow in candidates(cell)) {
          final next = puzzle.neighbour(cell, arrow);
          if (next == null || !good[next]) continue;
          good[cell] = true;
          moved = true;
          break;
        }
      }
    }
    return good;
  }
}

/// An area holds no repeated arrow. Level 1: the first rule anyone reads.
class RomeAreas implements DeductionRule<RomeModel> {
  const RomeAreas();

  @override
  int get level => 1;

  @override
  String get name => 'one of each arrow in an area';

  @override
  int apply(RomeModel model) {
    if (model.broken) return -1;
    final news = model._propagate();
    if (news < 0) return -1;
    return model.broken ? -1 : news;
  }
}

/// An arrow that leaves the board is impossible. Level 1: it needs no reasoning
/// beyond looking at where the arrow points.
class RomeEdges implements DeductionRule<RomeModel> {
  const RomeEdges();

  @override
  int get level => 1;

  @override
  String get name => 'no arrow off the board';

  @override
  int apply(RomeModel model) {
    if (model.broken) return -1;
    final news = model._propagate();
    if (news < 0) return -1;
    return model.broken ? -1 : news;
  }
}

/// Every chain ends at a goal. Level 2: the rule specific to this game, and the
/// only one that looks at the board as a whole.
class RomeReach implements DeductionRule<RomeModel> {
  const RomeReach();

  @override
  int get level => 2;

  @override
  String get name => 'every chain ends at a goal';

  @override
  int apply(RomeModel model) {
    if (model.broken) return -1;
    final news = model._reach();
    if (news < 0) return -1;
    if (model.broken) return -1;
    final more = model._propagate();
    if (more < 0) return -1;
    return model.broken ? -1 : news + more;
  }
}

/// Every rule, easiest first.
///
/// There is no exact rule here on purpose: the generator proves its boards with
/// these three and the search in [RomeSearch], and a board that needed a fourth
/// rule would be a board this port cannot claim is solvable by reasoning.
const List<DeductionRule<RomeModel>> romeRules = [
  RomeAreas(),
  RomeEdges(),
  RomeReach(),
];

/// The rules a player can be expected to use. Every rule is a player rule in
/// Rome, which is why the list is the same object.
const List<DeductionRule<RomeModel>> romePlayerRules = romeRules;

/// What a search over [RomeModel] found.
class RomeCount {
  const RomeCount({
    required this.solutions,
    required this.truncated,
    required this.exhausted,
    required this.first,
    required this.forced,
  });

  /// Answers found, capped at the limit asked for.
  final int solutions;

  /// True when the budget ran out. A truncated count proves nothing.
  final bool truncated;

  /// True when the search finished: no budget ran out and the limit was not
  /// reached. Only then is [forced] a proof.
  final bool exhausted;

  /// The first answer the search completed, per cell, or empty.
  final List<int> first;

  /// Per cell, the value every answer agrees on, or null when they disagree.
  /// All null unless [exhausted]: a value is only a proof if the search
  /// finished.
  final List<int?> forced;

  bool get isUnique => solutions == 1 && !truncated;
}

/// The search behind the generator's promise: fill the board, counting answers.
class RomeSearch {
  RomeSearch({
    required this.puzzle,
    required this.masks,
    this.limit = 2,
    this.budget = 40000,
  });

  final RomePuzzle puzzle;
  final List<int> masks;
  final int limit;
  final int budget;

  int _nodes = 0;
  int _solutions = 0;
  bool _truncated = false;
  List<int>? _first;
  late final List<int> _seen = [
    for (var cell = 0; cell < puzzle.cellCount; cell++)
      puzzle.isGoal(cell) ? kRomeGoalBit : kRomeArrowMask,
  ];

  RomeCount run() {
    _search(RomeModel(puzzle: puzzle, masks: List<int>.from(masks)));
    // Stopping at the limit is not finishing: the answers beyond it were never
    // looked at, so nothing is proved about them.
    final exhausted = !_truncated && _solutions < limit;
    final forced = List<int?>.filled(puzzle.cellCount, null);
    if (exhausted && _solutions > 0) {
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (puzzle.isGoal(cell)) {
          forced[cell] = kRomeGoal;
          continue;
        }
        final mask = _seen[cell] & kRomeArrowMask;
        forced[cell] = _popCount(mask) == 1 ? mask.bitLength - 1 : null;
      }
    }
    return RomeCount(
      solutions: _solutions,
      truncated: _truncated,
      exhausted: exhausted,
      first: _first ?? const [],
      forced: forced,
    );
  }

  int _search(RomeModel model) {
    if (_truncated) return 0;
    if (_nodes++ > budget) {
      _truncated = true;
      return 0;
    }
    final outcome = deduce(model, romePlayerRules);
    if (!outcome.consistent) return 0;
    if (model.isComplete) {
      final values = model.values;
      _first ??= values;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (puzzle.isGoal(cell)) continue;
        _seen[cell] &= romeBit(values[cell]);
      }
      _solutions++;
      return 1;
    }
    final choice = model.choice;
    if (choice == null) return 0;
    var found = 0;
    for (final value in choice.values) {
      found += _search(model.assume(choice.slot, value));
      // The limit is global: `found` is this node's subtotal, so a deep branch
      // that already reached the limit must stop the whole walk, not just this
      // loop.
      if (_solutions >= limit || _truncated) break;
    }
    return found;
  }
}
