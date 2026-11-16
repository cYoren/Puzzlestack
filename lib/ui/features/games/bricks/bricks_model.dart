/// Bricks as a deduction board.
///
/// A cell's mask says which of the two states it can still be, and three ideas
/// do the work a player does with a pencil: a number counts shaded neighbours
/// (so a cell is fixed once its count is tight, in either direction), no three
/// shaded cells sit in a row, and a shaded cell has to stand on one — the
/// heaviest of the three, and the one worth a level of its own, because
/// "below" is a pair of cells and not a single one.
///
/// The last rule is exact: [BricksForced] enumerates whole shadings, so "one
/// answer" and "finishable without a guess" are the same claim for this game.
///
/// Masks are `int` bits and the largest board is 56 cells, so every mask is two
/// bits and nothing here is near the 32-bit ceiling the web build truncates at.
library;

import '../../../../core/deduction.dart';
import 'bricks_puzzle.dart';

/// Bit for an unshaded cell.
const int kBricksUnshadedBit = 1;

/// Bit for a shaded cell.
const int kBricksShadedBit = 2;

/// Both: the cell is not decided yet.
const int kBricksEitherBit = 3;

int bricksBit(int shading) =>
    shading == kBricksShaded ? kBricksShadedBit : kBricksUnshadedBit;

int bricksShadingOf(int mask) =>
    mask == kBricksShadedBit ? kBricksShaded : kBricksUnshaded;

class BricksModel implements DeductionModel<BricksModel> {
  BricksModel({
    required this.puzzle,
    required this.masks,
    this.broken = false,
  });

  /// A fresh board: every cell open except the numbered ones, which rule 4
  /// fixes as unshaded before a single deduction is made.
  factory BricksModel.fresh(BricksPuzzle puzzle) => BricksModel(
        puzzle: puzzle,
        masks: [
          for (var cell = 0; cell < puzzle.cellCount; cell++)
            puzzle.hasClue(cell) ? kBricksUnshadedBit : kBricksEitherBit,
        ],
      );

  final BricksPuzzle puzzle;

  /// Per cell, the states it can still hold. A single bit is a decided cell.
  final List<int> masks;

  bool broken;

  BricksLattice get lattice => puzzle.lattice;

  int get cellCount => puzzle.cellCount;

  @override
  BricksModel copy() =>
      BricksModel(puzzle: puzzle, masks: List<int>.from(masks), broken: broken);

  @override
  bool get isComplete {
    if (broken) return false;
    for (final mask in masks) {
      if (mask != kBricksUnshadedBit && mask != kBricksShadedBit) return false;
    }
    // Decided and legal are two questions, and the counter trusts this one: a
    // board can be complete and wrong — every cell shaded on a board of numbers
    // — and a counter that does not ask the second one calls that an answer.
    return puzzle.isLegal(values);
  }

  @override
  Choice? get choice {
    for (var cell = 0; cell < cellCount; cell++) {
      if (masks[cell] == kBricksEitherBit) {
        return Choice(cell, const [kBricksUnshaded, kBricksShaded]);
      }
    }
    return null;
  }

  @override
  BricksModel assume(int slot, int value) {
    final next = copy();
    if (next.set(slot, value) < 0) next.broken = true;
    return next;
  }

  /// The board as shadings, with the open bits read as unshaded.
  ///
  /// Only a complete board is all shadings; asking an open board for its values
  /// is asking a question with no answer, which is why the counter checks
  /// [isComplete] first.
  List<int> get values => [
        for (final mask in masks)
          mask == kBricksShadedBit ? kBricksShaded : kBricksUnshaded,
      ];

  /// The shading of [cell], or null while it is still open.
  int? shadingAt(int cell) {
    final mask = masks[cell];
    if (mask == kBricksUnshadedBit) return kBricksUnshaded;
    if (mask == kBricksShadedBit) return kBricksShaded;
    return null;
  }

  bool isDecided(int cell) => masks[cell] != kBricksEitherBit;

  /// Writes [shading] in [cell]. 1 when that was news, 0 when it was already
  /// known, -1 on a contradiction.
  int set(int cell, int shading) {
    final bit = bricksBit(shading);
    final mask = masks[cell];
    if (mask & bit == 0) {
      broken = true;
      return -1;
    }
    if (mask == bit) return 0;
    masks[cell] = bit;
    return 1;
  }

  /// Removes [shading] from [cell], for a rule that proved it impossible.
  int eliminate(int cell, int shading) {
    final bit = bricksBit(shading);
    final mask = masks[cell];
    if (mask & bit == 0) return 0;
    if (mask == bit) {
      broken = true;
      return -1;
    }
    masks[cell] = mask & ~bit;
    return 1;
  }
}

/// Rule 3, and rule 4 read off it: a number counts the shaded cells around it.
/// Level 1 — counting neighbours is the first thing anyone does on a grid.
///
/// Two moves, both of them the same count read from either end. A number with
/// as many shaded neighbours as it asks for makes every neighbour still open
/// unshaded; one that needs every neighbour it has left makes them all shaded.
class BricksCounts implements DeductionRule<BricksModel> {
  const BricksCounts();

  @override
  int get level => 1;

  @override
  String get name => 'the shaded neighbours a number counts';

  @override
  int apply(BricksModel model) {
    if (model.broken) return -1;
    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      if (!model.puzzle.hasClue(cell)) continue;
      final wanted = model.puzzle.clue(cell);
      var shaded = 0;
      final open = <int>[];
      for (final other in model.lattice.around(cell)) {
        final mask = model.masks[other];
        if (mask == kBricksShadedBit) {
          shaded++;
        } else if (mask == kBricksEitherBit) {
          open.add(other);
        }
      }

      // More shaded neighbours than the number counts: the board is wrong, and
      // saying so here is what stops the exact rule reasoning over a board the
      // game would paint red.
      if (shaded > wanted) return -1;
      // Even shading every open neighbour would not reach the count.
      if (shaded + open.length < wanted) return -1;

      if (shaded == wanted) {
        for (final other in open) {
          final changed = model.set(other, kBricksUnshaded);
          if (changed < 0) return -1;
          news += changed;
        }
      } else if (shaded + open.length == wanted) {
        for (final other in open) {
          final changed = model.set(other, kBricksShaded);
          if (changed < 0) return -1;
          news += changed;
        }
      }
    }
    return news;
  }
}

/// Rule 2: no three shaded cells in a horizontal run. Level 1 — the same
/// counting idea as the numbers, on a line instead of a neighbourhood.
class BricksThrees implements DeductionRule<BricksModel> {
  const BricksThrees();

  @override
  int get level => 1;

  @override
  String get name => 'no three shaded cells in a row';

  @override
  int apply(BricksModel model) {
    if (model.broken) return -1;
    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      // Every run is seen three times, once from each of its cells. Settling a
      // cell that is already settled returns 0, so the repetition costs a pass
      // and changes nothing.
      final left = model.lattice.leftOf(cell);
      final right = model.lattice.rightOf(cell);
      if (left == null || right == null) continue;
      final run = [left, cell, right];

      var shaded = 0;
      var open = -1;
      for (final other in run) {
        final mask = model.masks[other];
        if (mask == kBricksShadedBit) {
          shaded++;
        } else if (mask == kBricksEitherBit) {
          open = other;
        }
      }
      if (shaded == 3) return -1;
      // Two of the three are shaded: the third cannot be, whatever else it
      // could have been.
      if (shaded == 2 && open >= 0) {
        final changed = model.set(open, kBricksUnshaded);
        if (changed < 0) return -1;
        news += changed;
      }
    }
    return news;
  }
}

/// Rule 1: a shaded cell stands on a shaded cell. Level 2 — it is the one rule
/// specific to this game, and the one that needs the C's neighbour table read
/// correctly, because "below" is two cells and never one.
///
/// The move has two directions:
///
///  * a shaded cell with only one cell still open under it puts the shade
///    there, and one with nothing shaded under it and nothing open is a
///    contradiction;
///  * a cell whose cells below are all known unshaded cannot be shaded itself —
///    the contrapositive. That is the move that clears the top of the board,
///    and without it the rule would only ever look downwards.
class BricksGravity implements DeductionRule<BricksModel> {
  const BricksGravity();

  @override
  int get level => 2;

  @override
  String get name => 'a shaded cell stands on another';

  @override
  int apply(BricksModel model) {
    if (model.broken) return -1;
    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      // The bottom row is exempt, which is the "unless it is on the bottom row"
      // half of the rule.
      if (model.lattice.isBottomRow(cell)) continue;
      final under = model.lattice.below(cell);

      var shaded = 0;
      final open = <int>[];
      for (final other in under) {
        final mask = model.masks[other];
        if (mask == kBricksShadedBit) {
          shaded++;
        } else if (mask == kBricksEitherBit) {
          open.add(other);
        }
      }

      // Nothing under it can be shaded: so this cell cannot be shaded.
      if (shaded == 0 && open.isEmpty) {
        final changed = model.eliminate(cell, kBricksShaded);
        if (changed < 0) return -1;
        news += changed;
        continue;
      }
      if (model.masks[cell] != kBricksShadedBit) continue;
      // It is shaded, so one of the two under it must be. When only one is
      // still open there is no choice left, and when none is open the board
      // contradicts itself.
      if (shaded > 0) continue;
      if (open.isEmpty) return -1;
      if (open.length == 1) {
        final changed = model.set(open.single, kBricksShaded);
        if (changed < 0) return -1;
        news += changed;
      }
    }
    return news;
  }
}

/// The exact rule: a cell is only written when a search proves the other state
/// impossible. Level 3, so a board finished by it is not "solvable by logic" —
/// and because it also counts, it is what makes the generator's promise
/// ("exactly one answer") true.
class BricksForced implements DeductionRule<BricksModel> {
  const BricksForced({this.limit = 4096, this.budget = 60000});

  final int limit;
  final int budget;

  @override
  int get level => 3;

  @override
  String get name => 'searching every other shading';

  @override
  int apply(BricksModel model) {
    if (model.broken) return -1;
    final found = BricksSearch(
      puzzle: model.puzzle,
      masks: model.masks,
      limit: limit,
      budget: budget,
    ).run();
    if (found.truncated) return 0;
    // Never write a cell the search did not finish proving: agreement among the
    // first few answers says nothing about the rest.
    if (!found.exhausted) return 0;
    if (found.solutions == 0) return -1;
    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      final forced = found.forced[cell];
      if (forced == null) continue;
      if (model.isDecided(cell)) continue;
      final changed = model.set(cell, forced);
      if (changed < 0) return -1;
      news += changed;
    }
    return news;
  }
}

/// Every rule, easiest first, ending with the exact one.
const List<DeductionRule<BricksModel>> bricksRules = [
  BricksCounts(),
  BricksThrees(),
  BricksGravity(),
  BricksForced(),
];

/// The rules a player can be expected to use, without the search. Levels 1 and
/// 2 are the whole reach of the app's promise: a board without a path through
/// these two is a lookup, not a puzzle.
const List<DeductionRule<BricksModel>> bricksPlayerRules = [
  BricksCounts(),
  BricksThrees(),
  BricksGravity(),
];

/// What a search over [BricksModel] found.
class BricksCount {
  const BricksCount({
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

  /// Per cell, the shading every answer agrees on, or null when they disagree.
  /// All null unless [exhausted]: a shading is only a proof if the search
  /// finished.
  final List<int?> forced;

  bool get isUnique => solutions == 1 && !truncated;
}

/// The search behind [BricksForced]: shade the board, counting answers.
class BricksSearch {
  BricksSearch({
    required this.puzzle,
    required List<int> masks,
    this.limit = 2,
    this.budget = 60000,
  }) : _masks = List<int>.from(masks);

  final BricksPuzzle puzzle;
  final List<int> _masks;
  final int limit;
  final int budget;

  int _nodes = 0;
  int _solutions = 0;
  bool _truncated = false;
  List<int>? _first;
  late final List<int> _seen =
      List<int>.filled(puzzle.cellCount, kBricksEitherBit);

  BricksCount run() {
    _search(BricksModel(puzzle: puzzle, masks: _masks));
    // Stopping at the limit is not finishing: the answers beyond it were never
    // looked at, so nothing is proved about them.
    final exhausted = !_truncated && _solutions < limit;
    final forced = List<int?>.filled(puzzle.cellCount, null);
    if (exhausted && _solutions > 0) {
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        final mask = _seen[cell];
        if (mask != kBricksUnshadedBit && mask != kBricksShadedBit) continue;
        forced[cell] = bricksShadingOf(mask);
      }
    }
    return BricksCount(
      solutions: _solutions,
      truncated: _truncated,
      exhausted: exhausted,
      first: _first ?? const [],
      forced: forced,
    );
  }

  int _search(BricksModel model) {
    if (_truncated || _solutions >= limit) return 0;
    if (_nodes++ > budget) {
      _truncated = true;
      return 0;
    }
    final outcome = deduce(model, bricksPlayerRules);
    if (!outcome.consistent) return 0;
    if (model.isComplete) {
      final values = model.values;
      _first ??= values;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        _seen[cell] &= bricksBit(values[cell]);
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
      // that already reached the limit must stop the whole walk.
      if (_solutions >= limit || _truncated) break;
    }
    return found;
  }
}
