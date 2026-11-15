import '../../../../core/deduction.dart';
import 'abcd_puzzle.dart';

/// ABCD as a deduction board: every cell keeps the set of letters it can still
/// hold, as a bitmask.
///
/// The rules are the three a player uses, and they are enough for the boards the
/// generator ships: a placed letter rules itself out of the cells beside it, and
/// a line's counts say both "this letter cannot go here any more" and "every
/// remaining cell of this line is this letter".
class AbcdModel implements DeductionModel<AbcdModel> {
  AbcdModel({required this.puzzle, required this.masks});

  factory AbcdModel.fresh(AbcdPuzzle puzzle) => AbcdModel(
        puzzle: puzzle,
        masks: List<int>.filled(
          puzzle.cellCount,
          (1 << puzzle.letters) - 1,
        ),
      );

  final AbcdPuzzle puzzle;

  /// Per cell, the set of letters it can still hold. A single bit is decided.
  final List<int> masks;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  int get letters => puzzle.letters;

  @override
  AbcdModel copy() => AbcdModel(puzzle: puzzle, masks: [...masks]);

  @override
  bool get isComplete {
    for (final mask in masks) {
      if (mask & (mask - 1) != 0) return false;
    }
    return true;
  }

  @override
  Choice? get choice {
    // The narrowest cell first: guessing there costs the least.
    var best = -1;
    var bestCount = letters + 1;
    for (var cell = 0; cell < masks.length; cell++) {
      final count = _count(masks[cell]);
      if (count <= 1) continue;
      if (count < bestCount) {
        best = cell;
        bestCount = count;
        if (count == 2) break;
      }
    }
    if (best < 0) return null;
    return Choice(best, [
      for (var letter = 0; letter < letters; letter++)
        if (masks[best] & (1 << letter) != 0) letter,
    ]);
  }

  @override
  AbcdModel assume(int slot, int value) {
    final next = copy();
    next.masks[slot] = 1 << value;
    return next;
  }

  /// The letter of a decided single-bit mask.
  static int single(int mask) {
    var i = 0;
    var bit = mask;
    while (bit > 1) {
      bit >>= 1;
      i++;
    }
    return i;
  }

  /// The letter at that cell, or -1 when it is not decided yet.
  int valueAt(int cell) {
    final mask = masks[cell];
    if (mask & (mask - 1) != 0) return -1;
    return _index(mask);
  }

  /// Rules a letter out of a cell. 1 when that was news, 0 when it was already
  /// out, -1 on contradiction.
  int remove(int cell, int letter) {
    final bit = 1 << letter;
    final mask = masks[cell];
    if (mask & bit == 0) return 0;
    if (mask == bit) return -1;
    masks[cell] = mask & ~bit;
    return 1;
  }

  /// Decides a cell. 1 when that was news, 0 when it already held that letter,
  /// -1 on contradiction.
  int set(int cell, int letter) {
    final bit = 1 << letter;
    final mask = masks[cell];
    if (mask == bit) return 0;
    if (mask & bit == 0) return -1;
    masks[cell] = bit;
    return 1;
  }

  List<int> line({required bool row, required int index}) => [
        for (var k = 0; k < (row ? cols : rows); k++)
          row ? index * cols + k : k * cols + index,
      ];

  List<int> neighbours(int cell) {
    final row = cell ~/ cols;
    final col = cell % cols;
    return [
      if (row > 0) cell - cols,
      if (row + 1 < rows) cell + cols,
      if (col > 0) cell - 1,
      if (col + 1 < cols) cell + 1,
    ];
  }

  static int _count(int mask) {
    var n = 0;
    while (mask != 0) {
      mask &= mask - 1;
      n++;
    }
    return n;
  }

  static int _index(int singleBit) {
    var i = 0;
    var bit = singleBit;
    while (bit > 1) {
      bit >>= 1;
      i++;
    }
    return i;
  }
}

/// Two identical letters may not touch along an edge.
class AbcdApart implements DeductionRule<AbcdModel> {
  const AbcdApart();

  @override
  int get level => 1;

  @override
  String get name => 'identical letters do not touch';

  @override
  int apply(AbcdModel model) {
    var news = 0;
    for (var cell = 0; cell < model.masks.length; cell++) {
      final value = model.valueAt(cell);
      if (value < 0) continue;
      for (final other in model.neighbours(cell)) {
        final n = model.remove(other, value);
        if (n < 0) return -1;
        news += n;
      }
    }
    return news;
  }
}

/// The numbers on the edge, in both directions.
class AbcdCounts implements DeductionRule<AbcdModel> {
  const AbcdCounts();

  @override
  int get level => 2;

  @override
  String get name => 'the counts on the edge';

  @override
  int apply(AbcdModel model) {
    var news = 0;
    for (final isRow in [true, false]) {
      final lines = isRow ? model.rows : model.cols;
      for (var index = 0; index < lines; index++) {
        final cells = model.line(row: isRow, index: index);
        for (var letter = 0; letter < model.letters; letter++) {
          final target = isRow
              ? model.puzzle.rowCounts[index][letter]
              : model.puzzle.colCounts[index][letter];
          var placed = 0;
          final open = <int>[];
          for (final cell in cells) {
            final mask = model.masks[cell];
            final bit = 1 << letter;
            if (mask == bit) {
              placed++;
            } else if (mask & bit != 0) {
              open.add(cell);
            }
          }
          if (placed > target) return -1;
          if (placed + open.length < target) return -1;
          if (placed == target) {
            for (final cell in open) {
              final n = model.remove(cell, letter);
              if (n < 0) return -1;
              news += n;
            }
          } else if (placed + open.length == target) {
            for (final cell in open) {
              final n = model.set(cell, letter);
              if (n < 0) return -1;
              news += n;
            }
          }
        }
      }
    }
    return news;
  }
}

/// The rules, easiest idea first. The highest level a board needs is its
/// difficulty.
///
/// [abcdRules] is what a player has: the local rules plus an exact search. The
/// exact rule is deliberately last, because a board that only needs the counts
/// is the easy tier and a board that needs the search is not.
const List<DeductionRule<AbcdModel>> abcdRules = [
  AbcdApart(),
  AbcdCounts(),
  AbcdExact(),
];

/// The rules the exact search propagates with.
///
/// It must not include [AbcdExact], or the search would call itself.
const List<DeductionRule<AbcdModel>> abcdBaseRules = [
  AbcdApart(),
  AbcdCounts(),
];

/// The whole board, solved exactly.
///
/// Two local rules cannot see a row that has to alternate ABAB because nothing
/// else fits. This rule can: it searches for complete grids that fit the board
/// and only writes when there is exactly one. It is sound by construction, and
/// it is what makes "unique" and "finishable without a guess" the same claim
/// for this game.
class AbcdExact implements DeductionRule<AbcdModel> {
  const AbcdExact({this.budget = 60000});

  /// Search steps before giving up. A board the search cannot finish is
  /// rejected by the generator rather than shipped unproved.
  final int budget;

  @override
  int get level => 3;

  @override
  String get name => 'the only grid that fits';

  @override
  int apply(AbcdModel model) {
    final found = <List<int>>[];
    var steps = 0;
    var gaveUp = false;

    void search(AbcdModel board) {
      if (gaveUp || found.length > 1) return;
      if (++steps > budget) {
        gaveUp = true;
        return;
      }
      final outcome = deduce(board, abcdBaseRules);
      if (!outcome.consistent) return;
      if (board.isComplete) {
        found.add([for (final mask in board.masks) AbcdModel.single(mask)]);
        return;
      }
      final choice = board.choice;
      if (choice == null) return;
      for (final value in choice.values) {
        search(board.assume(choice.slot, value));
        if (gaveUp || found.length > 1) return;
      }
    }

    search(model.copy());
    if (gaveUp) return 0;
    if (found.isEmpty) return -1;
    if (found.length > 1) return 0;

    var news = 0;
    final only = found.single;
    for (var cell = 0; cell < model.masks.length; cell++) {
      final n = model.set(cell, only[cell]);
      if (n < 0) return -1;
      news += n;
    }
    return news;
  }
}
