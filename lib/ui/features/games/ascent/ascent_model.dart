/// Ascent as a deduction board.
///
/// A cell's domain says which numbers could still sit there. Placing a number
/// is the whole propagation, and it is three statements at once:
///
///  * the number is used up, so no other cell can hold it;
///  * the number before it can only sit in a cell that touches this one;
///  * the number after it can only sit in a cell that touches this one.
///
/// The rules after that only look for cells and numbers with one possibility
/// left, and the last rule is exact: it enumerates whole paths and keeps only
/// what every path agrees on. So "one answer" and "finishable without a guess"
/// are the same claim for this game.
library;

import '../../../../core/deduction.dart';
import 'ascent_puzzle.dart';

class AscentModel implements DeductionModel<AscentModel> {
  AscentModel({
    required this.puzzle,
    required this.domains,
    this.broken = false,
  });

  factory AscentModel.fresh(AscentPuzzle puzzle) {
    final model = AscentModel(
      puzzle: puzzle,
      domains: [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          {for (var number = 1; number <= puzzle.maxNumber; number++) number},
      ],
    );
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final clue = puzzle.given(cell);
      if (clue == kAscentNoClue) continue;
      if (model.set(cell, clue) < 0) model.broken = true;
    }
    return model;
  }

  final AscentPuzzle puzzle;

  /// Per cell, the numbers it can still hold.
  ///
  /// A set, not a bitmask: a 7x7 board has 49 numbers and Dart's web build
  /// truncates integer bitwise operations to 32 bits. A bitmask would silently
  /// lose every number above 32 on the web target, which makes the larger
  /// boards unsolvable there and only there.
  final List<Set<int>> domains;

  /// Set when the printed numbers contradict each other.
  bool broken;

  int get cellCount => puzzle.cellCount;

  int get maxNumber => puzzle.maxNumber;

  @override
  AscentModel copy() => AscentModel(
        puzzle: puzzle,
        domains: [
          for (final domain in domains) {...domain}
        ],
        broken: broken,
      );

  @override
  bool get isComplete =>
      !broken && domains.every((domain) => domain.length == 1);

  @override
  Choice? get choice {
    var best = -1;
    var bestCount = 99;
    for (var cell = 0; cell < domains.length; cell++) {
      final count = domains[cell].length;
      if (count <= 1 || count >= bestCount) continue;
      best = cell;
      bestCount = count;
    }
    if (best < 0) return null;
    return Choice(best, domains[best].toList()..sort());
  }

  @override
  AscentModel assume(int slot, int value) {
    final next = copy();
    if (next.set(slot, value) < 0) next.broken = true;
    return next;
  }

  /// The number a decided cell holds, or 0 when it is still open.
  int numberAt(int cell) {
    final domain = domains[cell];
    return domain.length == 1 ? domain.first : 0;
  }

  /// Places [number] at [cell] and propagates it. 1 when that was news, 0 when
  /// it was already known, -1 on a contradiction.
  ///
  /// It propagates even when the cell was already down to this number, because
  /// a cell narrowed by elimination has never told its neighbours anything:
  /// "decided" and "propagated" are two different states.
  int set(int cell, int number) {
    final domain = domains[cell];
    if (!domain.contains(number)) return -1;

    var news = domain.length == 1 ? 0 : 1;
    domains[cell] = {number};

    // The number is used up.
    for (var other = 0; other < cellCount; other++) {
      if (other == cell) continue;
      final changed = _remove(other, number);
      if (changed < 0) return -1;
      news += changed;
    }

    // Its neighbours in the path must touch it.
    final touching = {
      for (final other in puzzle.neighboursOf(cell)) other,
      cell,
    };
    if (number > 1) {
      for (var other = 0; other < cellCount; other++) {
        if (touching.contains(other)) continue;
        final changed = _remove(other, number - 1);
        if (changed < 0) return -1;
        news += changed;
      }
    }
    if (number < maxNumber) {
      for (var other = 0; other < cellCount; other++) {
        if (touching.contains(other)) continue;
        final changed = _remove(other, number + 1);
        if (changed < 0) return -1;
        news += changed;
      }
    }
    return news;
  }

  int _remove(int cell, int number) {
    final domain = domains[cell];
    if (!domain.contains(number)) return 0;
    if (domain.length == 1) return -1;
    domain.remove(number);
    return 1;
  }

  /// Removes [number] from [cell], for a rule that has proved it impossible.
  int eliminate(int cell, int number) => _remove(cell, number);

  /// The numbers a cell can still hold, in order.
  List<int> candidates(int cell) => domains[cell].toList()..sort();

  /// True when some cell touching [cell] could still hold [number].
  bool neighbourCanTake(int cell, int number) {
    for (final other in puzzle.neighboursOf(cell)) {
      if (domains[other].contains(number)) return true;
    }
    return false;
  }
}

/// A cell with one number left takes it.
class AscentSingles implements DeductionRule<AscentModel> {
  const AscentSingles();

  @override
  int get level => 1;

  @override
  String get name => 'a cell with one number left';

  @override
  int apply(AscentModel model) {
    if (model.broken) return -1;
    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      final domain = model.domains[cell];
      if (domain.isEmpty) return -1;
      if (domain.length != 1) continue;
      final settled = model.set(cell, domain.first);
      if (settled < 0) return -1;
      news += settled;
    }
    return news;
  }
}

/// A number with only one cell left to live in must live there.
class AscentHiddenSingles implements DeductionRule<AscentModel> {
  const AscentHiddenSingles();

  @override
  int get level => 1;

  @override
  String get name => 'one place left for this number';

  @override
  int apply(AscentModel model) {
    if (model.broken) return -1;
    var news = 0;
    for (var number = 1; number <= model.maxNumber; number++) {
      int? only;
      var places = 0;
      for (var cell = 0; cell < model.cellCount; cell++) {
        if (!model.domains[cell].contains(number)) continue;
        places++;
        only = cell;
        if (places > 1) break;
      }
      if (places == 0) return -1;
      if (places > 1) continue;
      final settled = model.set(only!, number);
      if (settled < 0) return -1;
      news += settled;
    }
    return news;
  }
}

/// A number whose neighbour in the path has nowhere to go cannot be there.
///
/// This is the rule a player uses when they see a lone cell: if 7 sits here,
/// 8 has to touch it, and the only cells that could hold 8 are taken, so 7 is
/// not here.
class AscentPathRoom implements DeductionRule<AscentModel> {
  const AscentPathRoom();

  @override
  int get level => 2;

  @override
  String get name => 'no room for the number beside it';

  @override
  int apply(AscentModel model) {
    if (model.broken) return -1;
    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      final open = model.candidates(cell);
      if (open.length < 2) continue;
      for (final number in open) {
        if (number > 1 && !model.neighbourCanTake(cell, number - 1)) {
          final changed = model.eliminate(cell, number);
          if (changed < 0) return -1;
          news += changed;
          continue;
        }
        if (number < model.maxNumber &&
            !model.neighbourCanTake(cell, number + 1)) {
          final changed = model.eliminate(cell, number);
          if (changed < 0) return -1;
          news += changed;
        }
      }
    }
    return news;
  }
}

/// The result of counting the paths a set of domains allows.
class AscentCount {
  const AscentCount({
    required this.solutions,
    required this.truncated,
    required this.forced,
  });

  final int solutions;
  final bool truncated;

  /// Per cell, the number every path found agrees on, or 0.
  final List<int> forced;

  bool get isUnique => solutions == 1 && !truncated;
}

/// A complete search over whole paths, bounded by a node budget.
class AscentSearch {
  AscentSearch({
    required this.puzzle,
    required List<Set<int>> domains,
    this.limit = 2,
    this.budget = 40000,
  }) : domains = [
          for (final domain in domains) {...domain}
        ];

  final AscentPuzzle puzzle;

  /// The starting domains, by cell. Copied, so the caller keeps its own.
  final List<Set<int>> domains;

  final int limit;
  final int budget;

  int _nodes = 0;
  int _solutions = 0;
  bool _truncated = false;
  late List<Set<int>> _seen;

  AscentCount run() {
    _seen = [for (var cell = 0; cell < puzzle.cellCount; cell++) <int>{}];
    _search(AscentModel(
      puzzle: puzzle,
      domains: [
        for (final domain in domains) {...domain}
      ],
    ));
    final forced = List<int>.filled(puzzle.cellCount, 0);
    if (!_truncated && _solutions > 0) {
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (_seen[cell].length == 1) forced[cell] = _seen[cell].first;
      }
    }
    return AscentCount(
      solutions: _solutions,
      truncated: _truncated,
      forced: forced,
    );
  }

  void _search(AscentModel model) {
    if (_truncated || _solutions >= limit) return;
    if (_nodes++ > budget) {
      _truncated = true;
      return;
    }

    final outcome = deduce(model, ascentDeductionRules);
    if (!outcome.consistent) return;
    if (model.isComplete) {
      _solutions++;
      for (var cell = 0; cell < model.cellCount; cell++) {
        _seen[cell].addAll(model.domains[cell]);
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

/// The exact rule: enumerate whole paths, keep what every one agrees on.
class AscentForced implements DeductionRule<AscentModel> {
  const AscentForced();

  @override
  int get level => 3;

  @override
  String get name => 'the only path that fits';

  @override
  int apply(AscentModel model) {
    if (model.broken) return -1;
    final count = AscentSearch(
      puzzle: model.puzzle,
      domains: model.domains,
      limit: 4096,
      budget: 40000,
    ).run();
    if (count.truncated) return 0;
    if (count.solutions == 0) return -1;

    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      final number = count.forced[cell];
      if (number == 0) continue;
      if (model.domains[cell].length == 1) continue;
      final settled = model.set(cell, number);
      if (settled < 0) return -1;
      news += settled;
    }
    return news;
  }
}

/// What a player can do without thinking twice.
const List<DeductionRule<AscentModel>> ascentEasyRules = [
  AscentSingles(),
  AscentHiddenSingles(),
];

/// The generation ladder: a board ships only when these finish it.
const List<DeductionRule<AscentModel>> ascentDeductionRules = [
  AscentSingles(),
  AscentHiddenSingles(),
  AscentPathRoom(),
];

/// Every rule, easiest idea first. The highest level a board needs is its
/// difficulty.
const List<DeductionRule<AscentModel>> ascentRules = [
  AscentSingles(),
  AscentHiddenSingles(),
  AscentPathRoom(),
  AscentForced(),
];
