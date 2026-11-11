/// Latin-square puzzles: Sudoku, Skyscrapers, Futoshiki, KenKen.
///
/// They share one skeleton — every row and every column holds each value
/// exactly once — and differ only in the extra constraint on a line. So the
/// model, the elimination rules and the permutation filter live here, and a
/// puzzle supplies one predicate per line.
///
/// The permutation filter is the interesting part. For `n <= 6` a line has at
/// most 720 arrangements, so a line can be *enumerated*: keep the arrangements
/// that respect both the cells' candidates and the puzzle's predicate, then
/// intersect each cell with the values those arrangements allow. That is
/// stronger than any hand-written visibility or inequality rule, and it is
/// still deduction — no value is guessed.
library;

import 'deduction.dart';

/// One row or column: its cells, and what makes this puzzle's line legal.
class LatinLine {
  const LatinLine({
    required this.cells,
    required this.accept,
    required this.name,
  });

  /// Cell indices, in reading order along the line.
  final List<int> cells;

  /// Whether an arrangement of values (one per cell, in [cells] order) obeys
  /// this puzzle's extra constraint. A line with no extra constraint accepts
  /// everything.
  final bool Function(List<int> values) accept;

  /// For diagnostics: `row 3`, `col 1`.
  final String name;
}

/// A partially decided Latin square.
///
/// [masks] holds one bitmask per cell: bit `v - 1` set means value `v` is still
/// possible. A cell with a single bit set is decided.
class LatinModel implements DeductionModel<LatinModel> {
  LatinModel({
    required this.n,
    required this.masks,
    required this.lines,
  });

  final int n;
  final List<int> masks;
  final List<LatinLine> lines;

  int get cellCount => masks.length;

  int bitFor(int value) => 1 << (value - 1);

  int fullMask() => (1 << n) - 1;

  @override
  LatinModel copy() => LatinModel(n: n, masks: [...masks], lines: lines);

  @override
  bool get isComplete => masks.every(isDecided);

  static bool isDecided(int mask) => mask != 0 && (mask & (mask - 1)) == 0;

  static int valueOf(int mask) => mask.bitLength;

  static List<int> valuesOf(int mask) => [
        for (var value = 1; value <= 32; value++)
          if (mask & (1 << (value - 1)) != 0) value,
      ];

  @override
  Choice? get choice {
    var best = -1;
    var bestCount = 1 << 30;
    for (var i = 0; i < masks.length; i++) {
      final count = valuesOf(masks[i]).length;
      if (count > 1 && count < bestCount) {
        best = i;
        bestCount = count;
        if (count == 2) break;
      }
    }
    if (best == -1) return null;
    return Choice(best, valuesOf(masks[best]));
  }

  @override
  LatinModel assume(int slot, int value) {
    final next = copy();
    next.masks[slot] = bitFor(value);
    return next;
  }

  /// The decided value, or 0 when the cell is still open.
  int valueAt(int cell) => isDecided(masks[cell]) ? valueOf(masks[cell]) : 0;

  /// The grid as a list of rows, with 0 for undecided cells.
  List<List<int>> toGrid() {
    final size = n;
    return [
      for (var row = 0; row < size; row++)
        [for (var col = 0; col < size; col++) valueAt(row * size + col)],
    ];
  }
}

/// A value already decided in a line cannot appear again in it.
class LatinElimination implements DeductionRule<LatinModel> {
  const LatinElimination();

  @override
  int get level => 1;

  @override
  String get name => 'latin elimination';

  @override
  int apply(LatinModel model) {
    var settled = 0;
    for (final line in model.lines) {
      final taken = <int>{};
      for (final cell in line.cells) {
        if (LatinModel.isDecided(model.masks[cell])) taken.add(model.masks[cell]);
      }
      if (taken.isEmpty) continue;
      for (final cell in line.cells) {
        final mask = model.masks[cell];
        if (LatinModel.isDecided(mask)) continue;
        var next = mask;
        for (final value in taken) {
          next &= ~value;
        }
        if (next == 0) return -1;
        if (next != mask) {
          model.masks[cell] = next;
          settled++;
        }
      }
    }
    return settled;
  }
}

/// A value that fits only one cell of a line belongs there.
class LatinHiddenSingle implements DeductionRule<LatinModel> {
  const LatinHiddenSingle();

  @override
  int get level => 2;

  @override
  String get name => 'hidden single';

  @override
  int apply(LatinModel model) {
    var settled = 0;
    for (final line in model.lines) {
      for (var value = 1; value <= model.n; value++) {
        final bit = model.bitFor(value);
        int? only;
        var count = 0;
        var alreadyPlaced = false;
        for (final cell in line.cells) {
          final mask = model.masks[cell];
          if (mask == bit) {
            alreadyPlaced = true;
            break;
          }
          if (mask & bit != 0) {
            only = cell;
            count++;
          }
        }
        if (alreadyPlaced || count != 1) continue;
        if (model.masks[only!] != bit) {
          model.masks[only] = bit;
          settled++;
        }
      }
    }
    return settled;
  }
}

/// The strongest rule: enumerate the line's legal arrangements and keep only
/// the values that appear in one.
///
/// This is what makes a visibility clue or an inequality chain bite. It is
/// deduction, not search: the line is filtered against a constraint the puzzle
/// already stated, and nothing is assumed.
class LatinLineFilter implements DeductionRule<LatinModel> {
  const LatinLineFilter();

  @override
  int get level => 3;

  @override
  String get name => 'line filter';

  @override
  int apply(LatinModel model) {
    var settled = 0;
    for (final line in model.lines) {
      final open = line.cells.where((c) => !LatinModel.isDecided(model.masks[c]));
      if (open.isEmpty) continue;

      final allowed = List<int>.filled(line.cells.length, 0);
      final values = List<int>.filled(line.cells.length, 0);
      final used = <int>{};
      var any = false;

      void walk(int at) {
        if (at == line.cells.length) {
          if (!line.accept(values)) return;
          any = true;
          for (var i = 0; i < values.length; i++) {
            allowed[i] |= model.bitFor(values[i]);
          }
          return;
        }
        final cell = line.cells[at];
        final mask = model.masks[cell];
        for (var value = 1; value <= model.n; value++) {
          if (mask & model.bitFor(value) == 0) continue;
          if (!used.add(value)) continue;
          values[at] = value;
          walk(at + 1);
          used.remove(value);
        }
      }

      walk(0);
      if (!any) return -1;

      for (var i = 0; i < line.cells.length; i++) {
        final cell = line.cells[i];
        final next = model.masks[cell] & allowed[i];
        if (next == 0) return -1;
        if (next != model.masks[cell]) {
          model.masks[cell] = next;
          settled++;
        }
      }
    }
    return settled;
  }
}

/// The rule list every Latin puzzle starts from. A puzzle with a cheap extra
/// constraint can insert its own rule between the hidden single and the filter.
const List<DeductionRule<LatinModel>> latinRules = [
  LatinElimination(),
  LatinHiddenSingle(),
  LatinLineFilter(),
];

/// Builds a model for a puzzle: `lines` are rows then columns, and every cell
/// starts with every value open unless [givens] says otherwise.
LatinModel latinModel({
  required int n,
  required List<LatinLine> lines,
  Map<int, int> givens = const {},
}) {
  final masks = List<int>.filled(n * n, (1 << n) - 1);
  givens.forEach((cell, value) {
    masks[cell] = 1 << (value - 1);
  });
  return LatinModel(n: n, masks: masks, lines: lines);
}
