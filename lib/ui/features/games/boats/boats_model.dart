import '../../../../core/deduction.dart';
import 'boats_puzzle.dart';

/// Boats as a deduction board.
///
/// Every cell knows whether it can still be water, boat, or either. The rules
/// are the ones a player uses, easy idea first, and the last of them is the
/// exact fleet search: it places whole boats, so it is allowed to decide a cell
/// that the local rules cannot. A board that needs it is the hard tier.
const int kRegularWater = 1;
const int kRegularShip = 2;
const int kUndecided = kRegularWater | kRegularShip;

class BoatsModel implements DeductionModel<BoatsModel> {
  BoatsModel({required this.puzzle, required this.masks});

  factory BoatsModel.fresh(BoatsPuzzle puzzle) => BoatsModel(
        puzzle: puzzle,
        masks: [
          for (var cell = 0; cell < puzzle.cellCount; cell++)
            switch (puzzle.given(cell)) {
              kKnownWater => kRegularWater,
              kKnownShip => kRegularShip,
              _ => kUndecided,
            },
        ],
      );

  final BoatsPuzzle puzzle;

  /// Per cell: which of water/boat it can still be. Decided cells hold exactly
  /// one bit; undecided cells hold both.
  final List<int> masks;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  @override
  BoatsModel copy() => BoatsModel(puzzle: puzzle, masks: [...masks]);

  @override
  bool get isComplete => !masks.any((mask) => mask == kUndecided);

  @override
  Choice? get choice {
    for (var cell = 0; cell < masks.length; cell++) {
      if (masks[cell] == kUndecided) {
        return Choice(cell, const [kRegularWater, kRegularShip]);
      }
    }
    return null;
  }

  @override
  BoatsModel assume(int slot, int value) {
    final next = copy();
    next.masks[slot] = value;
    return next;
  }

  /// 0 when the cell is undecided, else [kRegularWater] or [kRegularShip].
  int valueAt(int cell) => masks[cell] == kUndecided ? 0 : masks[cell];

  /// 1 when this was news, 0 when it was already known, -1 on contradiction.
  int set(int cell, int value) {
    final mask = masks[cell];
    if (mask == value) return 0;
    if (mask & value == 0) return -1;
    masks[cell] = value;
    return 1;
  }

  /// 1 when this was news, 0 when already ruled out, -1 on contradiction.
  int remove(int cell, int value) {
    final mask = masks[cell];
    if (mask & value == 0) return 0;
    if (mask == value) return -1;
    masks[cell] = mask & ~value;
    return 1;
  }

  int row(int cell) => cell ~/ cols;

  int col(int cell) => cell % cols;

  bool inside(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  int at(int row, int col) => row * cols + col;

  /// The two cells either side along one axis, where they exist.
  List<int> along(int cell, {required bool horizontal}) {
    final r = row(cell);
    final c = col(cell);
    return [
      if (horizontal && c > 0) at(r, c - 1),
      if (horizontal && c + 1 < cols) at(r, c + 1),
      if (!horizontal && r > 0) at(r - 1, c),
      if (!horizontal && r + 1 < rows) at(r + 1, c),
    ];
  }

  List<int> diagonal(int cell) {
    final r = row(cell);
    final c = col(cell);
    return [
      for (var dr = -1; dr <= 1; dr += 2)
        for (var dc = -1; dc <= 1; dc += 2)
          if (inside(r + dr, c + dc)) at(r + dr, c + dc),
    ];
  }

  /// How long a boat could be through this cell along one axis, counting cells
  /// that may still be boat.
  int runLength(int cell, {required bool horizontal}) {
    var length = 1;
    final r = row(cell);
    final c = col(cell);
    for (final step in [-1, 1]) {
      var k = 1;
      while (true) {
        final nr = horizontal ? r : r + step * k;
        final nc = horizontal ? c + step * k : c;
        if (!inside(nr, nc)) break;
        final probe = at(nr, nc);
        if (masks[probe] & kRegularShip == 0) break;
        length++;
        k++;
      }
    }
    return length;
  }

  List<int> line({required bool row, required int index}) => [
        for (var k = 0; k < (row ? cols : rows); k++)
          row ? index * cols + k : k * cols + index,
      ];
}

/// The numbers outside the grid, applied as far as they go.
class BoatsCounts implements DeductionRule<BoatsModel> {
  const BoatsCounts();

  @override
  int get level => 1;

  @override
  String get name => 'row and column counts';

  @override
  int apply(BoatsModel model) {
    var news = 0;
    for (final isRow in [true, false]) {
      final count = isRow ? model.rows : model.cols;
      for (var index = 0; index < count; index++) {
        final target = isRow
            ? model.puzzle.rowCounts[index]
            : model.puzzle.colCounts[index];
        final cells = model.line(row: isRow, index: index);
        var ships = 0;
        final open = <int>[];
        for (final cell in cells) {
          final value = model.valueAt(cell);
          if (value == kRegularShip) {
            ships++;
          } else if (value == 0) {
            open.add(cell);
          }
        }
        if (ships > target) return -1;
        if (ships == target) {
          for (final cell in open) {
            final n = model.set(cell, kRegularWater);
            if (n < 0) return -1;
            news += n;
          }
        } else if (ships + open.length == target) {
          for (final cell in open) {
            final n = model.set(cell, kRegularShip);
            if (n < 0) return -1;
            news += n;
          }
        }
      }
    }
    return news;
  }
}

/// Two boats may not touch at a corner.
class BoatsApart implements DeductionRule<BoatsModel> {
  const BoatsApart();

  @override
  int get level => 1;

  @override
  String get name => 'boats never touch at a corner';

  @override
  int apply(BoatsModel model) {
    var news = 0;
    for (var cell = 0; cell < model.masks.length; cell++) {
      if (model.valueAt(cell) != kRegularShip) continue;
      for (final other in model.diagonal(cell)) {
        final n = model.set(other, kRegularWater);
        if (n < 0) return -1;
        news += n;
      }
    }
    return news;
  }
}

/// A boat is straight, so a boat cell has neighbours along one axis only.
class BoatsStraight implements DeductionRule<BoatsModel> {
  const BoatsStraight();

  @override
  int get level => 1;

  @override
  String get name => 'a boat is a straight run';

  @override
  int apply(BoatsModel model) {
    var news = 0;
    for (var cell = 0; cell < model.masks.length; cell++) {
      final value = model.valueAt(cell);
      final horizontal = model
          .along(cell, horizontal: true)
          .any((other) => model.valueAt(other) == kRegularShip);
      final vertical = model
          .along(cell, horizontal: false)
          .any((other) => model.valueAt(other) == kRegularShip);

      if (value == kRegularShip) {
        // Both axes means a bend, which no boat has.
        if (horizontal && vertical) return -1;
        continue;
      }
      if (value != 0) continue;
      // If it were a boat cell it would bend, so it is water.
      if (horizontal && vertical) {
        final n = model.set(cell, kRegularWater);
        if (n < 0) return -1;
        news += n;
      }
    }
    return news;
  }
}

/// A cell with no room for the shortest boat, in either direction, is water.
class BoatsRunRoom implements DeductionRule<BoatsModel> {
  const BoatsRunRoom();

  @override
  int get level => 2;

  @override
  String get name => 'no boat fits through here';

  @override
  int apply(BoatsModel model) {
    final shortest = model.puzzle.fleet.last;
    var news = 0;
    for (var cell = 0; cell < model.masks.length; cell++) {
      if (model.valueAt(cell) != 0) continue;
      final reach = [
        model.runLength(cell, horizontal: true),
        model.runLength(cell, horizontal: false),
      ].reduce((a, b) => a > b ? a : b);
      if (reach >= shortest) continue;
      final n = model.set(cell, kRegularWater);
      if (n < 0) return -1;
      news += n;
    }
    return news;
  }
}

/// The exact fleet search, as a rule.
///
/// It places whole boats instead of deciding cells one at a time, so it settles
/// cells that the local rules cannot see: "whichever fleet fits, this cell is
/// water". It is the last rule and the hard tier, and it is sound by
/// construction — it only writes a cell when every fleet consistent with the
/// board agrees on it.
class BoatsFleetRule implements DeductionRule<BoatsModel> {
  const BoatsFleetRule();

  @override
  int get level => 3;

  @override
  String get name => 'the only fleet that fits';

  @override
  int apply(BoatsModel model) {
    final count = BoatsFleetSearch(
      rows: model.rows,
      cols: model.cols,
      rowCounts: model.puzzle.rowCounts,
      colCounts: model.puzzle.colCounts,
      fleet: model.puzzle.fleet,
      known: [for (final mask in model.masks) _knownOf(mask)],
      limit: 4096,
      budget: 60000,
    ).run();

    if (count.truncated) return 0;
    if (count.solutions == 0) return -1;

    var news = 0;
    for (final cell in count.shipInAll) {
      final n = model.set(cell, kRegularShip);
      if (n < 0) return -1;
      news += n;
    }
    for (final cell in count.waterInAll) {
      final n = model.set(cell, kRegularWater);
      if (n < 0) return -1;
      news += n;
    }
    return news;
  }

  static int _knownOf(int mask) {
    if (mask == kRegularWater) return kKnownWater;
    if (mask == kRegularShip) return kKnownShip;
    return kKnownAny;
  }
}

/// The rules, easiest idea first. The highest level a board needs is its
/// difficulty.
const List<DeductionRule<BoatsModel>> boatsRules = [
  BoatsCounts(),
  BoatsApart(),
  BoatsStraight(),
  BoatsRunRoom(),
  BoatsFleetRule(),
];
