/// Clusters as a deduction board.
///
/// A cell's mask says which colours it can still be. The only rule is a count
/// of neighbours, and it has three faces, which is why it is one rule and not
/// three: a dotted cell needs exactly one same-coloured neighbour, a plain cell
/// needs two, and both become "the neighbours still open are forced" once the
/// count is tight. The last rule is exact: it enumerates whole colourings.
library;

import '../../../../core/deduction.dart';
import 'clusters_puzzle.dart';

int _popCount(int mask) {
  var count = 0;
  while (mask != 0) {
    mask &= mask - 1;
    count++;
  }
  return count;
}

int colourBit(int colour) => colour == kClusterRed ? 1 : 2;

int colourOfBit(int bit) => bit == 1 ? kClusterRed : kClusterBlue;

const int kClusterEither = 3;

class ClustersModel implements DeductionModel<ClustersModel> {
  ClustersModel({
    required this.puzzle,
    required this.masks,
    this.broken = false,
  });

  factory ClustersModel.fresh(ClustersPuzzle puzzle) {
    final model = ClustersModel(
      puzzle: puzzle,
      masks: List<int>.filled(puzzle.cellCount, kClusterEither),
    );
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final clue = puzzle.clue(cell);
      if (clue == kClusterNoClue) continue;
      model.masks[cell] = colourBit(clue);
    }
    return model;
  }

  final ClustersPuzzle puzzle;

  /// Per cell: [kClusterEither], or the single bit of a decided colour.
  final List<int> masks;

  bool broken;

  int get cellCount => puzzle.cellCount;

  @override
  ClustersModel copy() =>
      ClustersModel(puzzle: puzzle, masks: [...masks], broken: broken);

  @override
  bool get isComplete {
    if (broken) return false;
    final values = <int>[];
    for (final mask in masks) {
      if (_popCount(mask) != 1) return false;
      values.add(colourOfBit(mask));
    }
    // Decided and legal are two different questions. A board can be complete
    // and wrong — all red dots on an all-red board — and a counter that does
    // not ask the second question calls that one answer.
    return puzzle.isLegal(values);
  }

  @override
  Choice? get choice {
    for (var cell = 0; cell < masks.length; cell++) {
      if (_popCount(masks[cell]) == 2) {
        return Choice(cell, const [1, 2]);
      }
    }
    return null;
  }

  @override
  ClustersModel assume(int slot, int value) {
    final next = copy();
    next.masks[slot] = value;
    return next;
  }

  /// The colour a decided cell holds, or 0 when it is still open.
  int colourAt(int cell) {
    final mask = masks[cell];
    return _popCount(mask) == 1 ? colourOfBit(mask) : 0;
  }

  /// 1 when this was news, 0 when it was already known, -1 on contradiction.
  int set(int cell, int colour) {
    final bit = colourBit(colour);
    final mask = masks[cell];
    if (mask & bit == 0) return -1;
    if (mask == bit) return 0;
    masks[cell] = bit;
    return 1;
  }

  /// Removes a colour from a cell, for a rule that proved it impossible.
  int eliminate(int cell, int colour) {
    final bit = colourBit(colour);
    final mask = masks[cell];
    if (mask & bit == 0) return 0;
    if (mask == bit) return -1;
    masks[cell] = mask & ~bit;
    return 1;
  }
}

/// The neighbour count, applied as far as it goes.
class ClustersCounts implements DeductionRule<ClustersModel> {
  const ClustersCounts();

  @override
  int get level => 1;

  @override
  String get name => 'the number of neighbours of my colour';

  @override
  int apply(ClustersModel model) {
    if (model.broken) return -1;
    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      final clue = model.puzzle.clue(cell);
      final dotted = clue != kClusterNoClue;
      // A dot needs exactly one neighbour of its colour; a plain cell needs at
      // least two.
      final need = dotted ? 1 : 2;
      final mask = model.masks[cell];
      final decided = _popCount(mask) == 1;
      final neighbours = model.puzzle.neighboursOf(cell);

      for (final colour in const [kClusterRed, kClusterBlue]) {
        final bit = colourBit(colour);
        if (mask & bit == 0) continue;

        var same = 0;
        final open = <int>[];
        for (final other in neighbours) {
          final otherMask = model.masks[other];
          if (otherMask == bit) {
            same++;
          } else if (_popCount(otherMask) == 2) {
            open.add(other);
          }
        }

        // A dot is exactly one, so two same-coloured neighbours already break
        // it. Reporting that here matters: without it an all-red board of red
        // dots counted as a legal colouring, and the exact rule reasoned over
        // boards the game would call wrong.
        if (dotted && same > 1) return -1;

        final room = need - same;
        if (room > open.length) {
          // If this cell were this colour, it could not reach its count.
          final changed = model.eliminate(cell, colour);
          if (changed < 0) return -1;
          news += changed;
          continue;
        }
        // Forcing a neighbour is only sound once this cell's colour is settled:
        // "if it were red, that cell would be red" says nothing while it could
        // still be blue, which is exactly the bug this note replaced.
        if (!decided || open.isEmpty) continue;
        if (dotted && room <= 0) {
          // Exactly one neighbour of its colour: every other one is the other.
          for (final other in open) {
            final changed = model.set(other, otherColour(colour));
            if (changed < 0) return -1;
            news += changed;
          }
        } else if (room == open.length && room > 0) {
          for (final other in open) {
            final changed = model.set(other, colour);
            if (changed < 0) return -1;
            news += changed;
          }
        }
      }
    }
    return news;
  }
}

/// The result of counting the colourings a set of masks allows.
class ClustersCount {
  const ClustersCount({
    required this.solutions,
    required this.truncated,
    required this.exhausted,
    required this.first,
    required this.forced,
  });

  final int solutions;
  final bool truncated;

  /// True when the search finished, so [forced] is a proof and not a guess.
  final bool exhausted;

  /// The first answer the search completed, per cell, or empty.
  final List<int> first;

  /// Per cell, the colour every colouring found agrees on, or 0. Empty unless
  /// [exhausted].
  final List<int> forced;

  bool get isUnique => solutions == 1 && !truncated;
}

/// A complete search over whole colourings, bounded by a node budget.
class ClustersSearch {
  ClustersSearch({
    required this.puzzle,
    required List<int> masks,
    this.limit = 2,
    this.budget = 60000,
  }) : masks = List<int>.from(masks);

  final ClustersPuzzle puzzle;
  final List<int> masks;
  final int limit;
  final int budget;

  int _nodes = 0;
  int _solutions = 0;
  List<int>? _first;
  bool _truncated = false;
  late List<int> _seen;

  ClustersCount run() {
    _seen = List<int>.filled(puzzle.cellCount, 0);
    _search(ClustersModel(puzzle: puzzle, masks: masks));
    // Stopping at the limit is not finishing: the answers beyond it were never
    // looked at, so nothing is proved about them.
    final exhausted = !_truncated && _solutions < limit;
    final forced = List<int>.filled(puzzle.cellCount, 0);
    if (exhausted && _solutions > 0) {
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (_popCount(_seen[cell]) == 1) {
          forced[cell] = colourOfBit(_seen[cell]);
        }
      }
    }
    return ClustersCount(
      solutions: _solutions,
      truncated: _truncated,
      exhausted: exhausted,
      first: _first ?? const [],
      forced: forced,
    );
  }

  List<int> _valuesOf(ClustersModel model) => [
        for (var cell = 0; cell < model.cellCount; cell++) model.colourAt(cell),
      ];

  void _search(ClustersModel model) {
    if (_truncated || _solutions >= limit) return;
    if (_nodes++ > budget) {
      _truncated = true;
      return;
    }

    final outcome = deduce(model, clustersEasyRules);
    if (!outcome.consistent) return;
    if (model.isComplete) {
      _first ??= _valuesOf(model);
      _solutions++;
      for (var cell = 0; cell < model.cellCount; cell++) {
        _seen[cell] |= model.masks[cell];
      }
      return;
    }

    final choice = model.choice;
    if (choice == null) return;
    for (final value in choice.values) {
      _search(model.assume(choice.slot, value));
      if (_truncated || _solutions >= limit) return;
    }
  }
}

/// The exact rule: a colour is kept only when some complete colouring uses it.
class ClustersForced implements DeductionRule<ClustersModel> {
  const ClustersForced();

  @override
  int get level => 3;

  @override
  String get name => 'the only colouring that fits';

  @override
  int apply(ClustersModel model) {
    if (model.broken) return -1;
    final count = ClustersSearch(
      puzzle: model.puzzle,
      masks: model.masks,
      limit: 4096,
      budget: 60000,
    ).run();
    if (count.truncated) return 0;
    // Never write a cell the search did not finish proving: agreement among
    // the first few answers says nothing about the rest.
    if (!count.exhausted) return 0;
    if (count.solutions == 0) return -1;

    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      final colour = count.forced[cell];
      if (colour == 0) continue;
      final changed = model.set(cell, colour);
      if (changed < 0) return -1;
      news += changed;
    }
    return news;
  }
}

/// The one cheap idea.
const List<DeductionRule<ClustersModel>> clustersEasyRules = [
  ClustersCounts(),
];

/// The generation ladder.
const List<DeductionRule<ClustersModel>> clustersDeductionRules = [
  ClustersCounts(),
];

/// Every rule, easiest idea first.
const List<DeductionRule<ClustersModel>> clustersRules = [
  ClustersCounts(),
  ClustersForced(),
];
