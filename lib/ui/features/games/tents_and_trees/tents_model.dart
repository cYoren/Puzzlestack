import '../../../../core/deduction.dart';
import 'tents_puzzle.dart';

/// Tents & Trees as a deduction board: every non-tree cell knows whether it can
/// still hold a tent.
///
/// The rules are Tatham's (`tents_solve` in `tents.c`), with one addition that
/// makes the puzzle unambiguous to a player: a tent is adjacent to **exactly
/// one** tree. Tatham allows a tent to sit between two trees and be linked to
/// one of them; here that cell can never be a tent, which removes a whole class
/// of "which tree does this belong to" confusion.
const int kTent = 1;
const int kGrass = 2;

class TentsModel implements DeductionModel<TentsModel> {
  TentsModel({required this.puzzle, required this.masks});

  factory TentsModel.fresh(TentsPuzzle puzzle) => TentsModel(
        puzzle: puzzle,
        masks: [
          for (var cell = 0; cell < puzzle.cellCount; cell++)
            puzzle.isTree(cell) ? 0 : kTent | kGrass,
        ],
      );

  final TentsPuzzle puzzle;

  /// Per cell: which of tent/grass it can still be. A tree has 0 and is never
  /// decided.
  final List<int> masks;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  bool isTree(int cell) => puzzle.isTree(cell);

  @override
  TentsModel copy() => TentsModel(puzzle: puzzle, masks: [...masks]);

  @override
  bool get isComplete {
    for (var cell = 0; cell < masks.length; cell++) {
      if (isTree(cell)) continue;
      if (masks[cell] != kTent && masks[cell] != kGrass) return false;
    }
    return true;
  }

  @override
  Choice? get choice {
    for (var cell = 0; cell < masks.length; cell++) {
      if (isTree(cell)) continue;
      final mask = masks[cell];
      if (mask == kTent || mask == kGrass) continue;
      return Choice(cell, [
        if (mask & kTent != 0) kTent,
        if (mask & kGrass != 0) kGrass,
      ]);
    }
    return null;
  }

  @override
  TentsModel assume(int slot, int value) {
    final next = copy();
    next.masks[slot] = value;
    return next;
  }

  int valueAt(int cell) {
    final mask = masks[cell];
    return mask == kTent || mask == kGrass ? mask : 0;
  }

  /// 1 when that was news, -1 on contradiction. Trees are never touched.
  int set(int cell, int value) {
    if (isTree(cell)) return 0;
    final mask = masks[cell];
    if (mask == value) return 0;
    if (mask & value == 0) return -1;
    masks[cell] = value;
    return 1;
  }

  /// 1 when that was news, -1 on contradiction.
  int unset(int cell, int value) {
    if (isTree(cell)) return 0;
    final mask = masks[cell];
    if (mask & value == 0) return 0;
    if (mask == value) return -1;
    masks[cell] = mask & ~value;
    return 1;
  }

  /// The four orthogonally adjacent cells that exist.
  List<int> orthogonal(int cell) {
    final row = cell ~/ cols;
    final col = cell % cols;
    return [
      if (row > 0) cell - cols,
      if (row + 1 < rows) cell + cols,
      if (col > 0) cell - 1,
      if (col + 1 < cols) cell + 1,
    ];
  }

  /// All eight neighbours that exist.
  List<int> around(int cell) {
    final row = cell ~/ cols;
    final col = cell % cols;
    return [
      for (var dr = -1; dr <= 1; dr++)
        for (var dc = -1; dc <= 1; dc++)
          if (dr != 0 || dc != 0)
            if (row + dr >= 0 &&
                row + dr < rows &&
                col + dc >= 0 &&
                col + dc < cols)
              (row + dr) * cols + col + dc,
    ];
  }

  List<int> line({required bool row, required int index}) => [
        for (var k = 0; k < (row ? cols : rows); k++)
          row ? index * cols + k : k * cols + index,
      ];
}

/// A cell that no tree can reach, or that two trees could claim, is grass.
class TentsReach implements DeductionRule<TentsModel> {
  const TentsReach();

  @override
  int get level => 1;

  @override
  String get name => 'a tent needs exactly one tree';

  @override
  int apply(TentsModel model) {
    var news = 0;
    for (var cell = 0; cell < model.masks.length; cell++) {
      if (model.isTree(cell)) continue;
      if (model.valueAt(cell) != 0) continue;
      final trees = model.orthogonal(cell).where(model.isTree).length;
      if (trees == 1) continue;
      final n = model.set(cell, kGrass);
      if (n < 0) return -1;
      news += n;
    }
    return news;
  }
}

/// Two tents may not touch, not even at a corner.
class TentsApart implements DeductionRule<TentsModel> {
  const TentsApart();

  @override
  int get level => 1;

  @override
  String get name => 'tents never touch';

  @override
  int apply(TentsModel model) {
    var news = 0;
    for (var cell = 0; cell < model.masks.length; cell++) {
      if (model.valueAt(cell) != kTent) continue;
      for (final other in model.around(cell)) {
        final n = model.set(other, kGrass);
        if (n < 0) return -1;
        news += n;
      }
    }
    return news;
  }
}

/// Every tree has exactly one tent beside it.
class TentsTree implements DeductionRule<TentsModel> {
  const TentsTree();

  @override
  int get level => 1;

  @override
  String get name => 'every tree has one tent';

  @override
  int apply(TentsModel model) {
    var news = 0;
    for (final tree in model.puzzle.trees) {
      final neighbours = model.orthogonal(tree);
      final tents = neighbours.where((c) => model.valueAt(c) == kTent).length;
      final open = neighbours
          .where((c) => model.valueAt(c) == 0 && model.masks[c] & kTent != 0)
          .toList();

      if (tents > 1) return -1;
      if (tents == 1) {
        for (final cell in open) {
          final n = model.set(cell, kGrass);
          if (n < 0) return -1;
          news += n;
        }
        continue;
      }
      if (open.isEmpty) return -1;
      if (open.length == 1) {
        final n = model.set(open.single, kTent);
        if (n < 0) return -1;
        news += n;
      }
    }
    return news;
  }
}

/// The numbers along the edges.
class TentsCounts implements DeductionRule<TentsModel> {
  const TentsCounts();

  @override
  int get level => 2;

  @override
  String get name => 'row and column counts';

  @override
  int apply(TentsModel model) {
    var news = 0;
    for (final row in [true, false]) {
      final count = row ? model.rows : model.cols;
      for (var index = 0; index < count; index++) {
        final target = row
            ? model.puzzle.rowCounts[index]
            : model.puzzle.colCounts[index];
        final cells = model.line(row: row, index: index);
        final tents = cells.where((c) => model.valueAt(c) == kTent).length;
        final open = cells
            .where((c) => model.valueAt(c) == 0 && model.masks[c] & kTent != 0)
            .toList();

        if (tents > target) return -1;
        if (tents == target) {
          for (final cell in open) {
            final n = model.set(cell, kGrass);
            if (n < 0) return -1;
            news += n;
          }
        } else if (target - tents == open.length) {
          for (final cell in open) {
            final n = model.set(cell, kTent);
            if (n < 0) return -1;
            news += n;
          }
        }
      }
    }
    return news;
  }
}

/// When a tree has two possible tent spots diagonally apart, the cell that
/// touches both of them cannot be a tent.
class TentsDiagonal implements DeductionRule<TentsModel> {
  const TentsDiagonal();

  @override
  int get level => 3;

  @override
  String get name => 'two diagonal spots rule out the corner';

  @override
  int apply(TentsModel model) {
    var news = 0;
    for (final tree in model.puzzle.trees) {
      final neighbours = model.orthogonal(tree);
      if (neighbours.any((c) => model.valueAt(c) == kTent)) continue;
      final open = neighbours
          .where((c) => model.valueAt(c) == 0 && model.masks[c] & kTent != 0)
          .toList();
      if (open.length != 2) continue;

      final a = open[0];
      final b = open[1];
      final sameRow = a ~/ model.cols == b ~/ model.cols;
      final sameCol = a % model.cols == b % model.cols;
      if (sameRow || sameCol) continue; // opposite sides of the tree, not a corner

      // The rectangle's two other corners; one of them is the tree, and the
      // other touches both candidate cells.
      final cornerA = (a ~/ model.cols) * model.cols + (b % model.cols);
      final cornerB = (b ~/ model.cols) * model.cols + (a % model.cols);
      final corner = cornerA == tree ? cornerB : cornerA;
      if (corner == tree) continue;
      final n = model.set(corner, kGrass);
      if (n < 0) return -1;
      news += n;
    }
    return news;
  }
}

/// Every arrangement a line's remaining tents can take, intersected.
///
/// A row of seven with three tents left has at most 35 arrangements, so this is
/// cheap; a cell that is a tent in every one of them is a tent, and a cell that
/// is grass in every one is grass. It is a relaxation — it only knows the count
/// and that tents in the same line cannot touch — but that is enough to decide
/// boards the local rules leave open.
class TentsLineFilter implements DeductionRule<TentsModel> {
  const TentsLineFilter();

  @override
  int get level => 3;

  @override
  String get name => 'every arrangement of the line';

  @override
  int apply(TentsModel model) {
    var news = 0;
    for (final row in [true, false]) {
      final count = row ? model.rows : model.cols;
      for (var index = 0; index < count; index++) {
        final n = _applyLine(model, row: row, index: index);
        if (n < 0) return -1;
        news += n;
      }
    }
    return news;
  }

  int _applyLine(TentsModel model, {required bool row, required int index}) {
    final cells = model.line(row: row, index: index);
    final target = row
        ? model.puzzle.rowCounts[index]
        : model.puzzle.colCounts[index];

    var settled = 0;
    final open = <int>[];
    for (final cell in cells) {
      final value = model.valueAt(cell);
      if (value == kTent) {
        settled++;
      } else if (value == 0 && model.masks[cell] & kTent != 0) {
        open.add(cell);
      }
    }
    final need = target - settled;
    if (need < 0) return -1;
    if (need == 0) {
      var news = 0;
      for (final cell in open) {
        final n = model.set(cell, kGrass);
        if (n < 0) return -1;
        news += n;
      }
      return news;
    }
    if (need > open.length) return -1;
    if (open.length > 20) return 0; // not worth enumerating

    final position = {for (var i = 0; i < cells.length; i++) cells[i]: i};
    final alwaysTent = <int>{...open};
    final alwaysGrass = <int>{...open};
    var arrangements = 0;

    void walk(int start, List<int> chosen) {
      if (chosen.length == need) {
        arrangements++;
        final tents = chosen.toSet();
        alwaysTent.removeWhere((cell) => !tents.contains(cell));
        alwaysGrass.removeWhere(tents.contains);
        return;
      }
      for (var i = start; i < open.length; i++) {
        final cell = open[i];
        // Two tents in the same line may not sit side by side.
        if (chosen.isNotEmpty &&
            (position[cell]! - position[chosen.last]!).abs() == 1) {
          continue;
        }
        chosen.add(cell);
        walk(i + 1, chosen);
        chosen.removeLast();
      }
    }

    walk(0, []);
    if (arrangements == 0) return -1;

    var news = 0;
    for (final cell in alwaysTent) {
      final n = model.set(cell, kTent);
      if (n < 0) return -1;
      news += n;
    }
    for (final cell in alwaysGrass) {
      final n = model.set(cell, kGrass);
      if (n < 0) return -1;
      news += n;
    }
    return news;
  }
}

/// The rules, easiest idea first. The level a board needs is its difficulty.
const List<DeductionRule<TentsModel>> tentsRules = [
  TentsReach(),
  TentsApart(),
  TentsTree(),
  TentsCounts(),
  TentsDiagonal(),
  TentsLineFilter(),
];
