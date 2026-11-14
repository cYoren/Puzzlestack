import 'package:puzzle/core/deduction.dart';

/// A nonogram as a deduction board, so `countSolutions` can prove a clue grid
/// has exactly one answer before it is dealt.
///
/// A cell is [unknown], [empty] or [filled]. The only rule is the line solver a
/// player uses: for each row and column, lay the clue blocks out in every way
/// the decided cells allow, and any cell that every layout agrees on can be
/// decided. Where that runs out the counter guesses, so a board that needs a
/// guess is still counted — it is only "unique" that matters here.
class NonogramModel extends DeductionModel<NonogramModel> {
  NonogramModel({
    required this.cells,
    required this.rowClues,
    required this.colClues,
  });

  /// [size] x [size], each cell [unknown], [empty] or [filled].
  final List<List<int>> cells;
  final List<List<int>> rowClues;
  final List<List<int>> colClues;

  static const int unknown = -1;
  static const int empty = 0;
  static const int filled = 1;

  int get size => cells.length;

  @override
  NonogramModel copy() => NonogramModel(
        cells: [for (final row in cells) List<int>.from(row)],
        rowClues: rowClues,
        colClues: colClues,
      );

  @override
  bool get isComplete =>
      cells.every((row) => row.every((cell) => cell != unknown));

  @override
  Choice? get choice {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (cells[r][c] == unknown) {
          return Choice(r * size + c, const [empty, filled]);
        }
      }
    }
    return null;
  }

  @override
  NonogramModel assume(int slot, int value) {
    final board = copy();
    board.cells[slot ~/ size][slot % size] = value;
    return board;
  }
}

/// Every legal layout of [clue] on a line of [length] that agrees with the
/// cells already decided. Each layout is a list of 0/1.
List<List<int>> lineLayouts(List<int> clue, List<int> line) {
  final length = line.length;
  final layouts = <List<int>>[];
  final blocks = clue.where((block) => block > 0).toList();

  void place(int block, int at, List<int> current) {
    if (block == blocks.length) {
      final rest = List<int>.filled(length - current.length, 0);
      if (_agrees([...current, ...rest], line)) {
        layouts.add([...current, ...rest]);
      }
      return;
    }
    final run = blocks[block];
    // Gaps that still have to fit after this block, plus their separators.
    var trailing = 0;
    for (var i = block + 1; i < blocks.length; i++) {
      trailing += blocks[i] + 1;
    }
    final last = length - trailing - run;
    for (var start = at; start <= last; start++) {
      final next = List<int>.from(current);
      while (next.length < start) {
        next.add(0);
      }
      next.addAll(List<int>.filled(run, 1));
      if (block + 1 < blocks.length) next.add(0);
      if (!_agrees(next, line)) continue;
      place(block + 1, next.length, next);
    }
  }

  place(0, 0, <int>[]);
  return layouts;
}

bool _agrees(List<int> layout, List<int> line) {
  for (var i = 0; i < line.length && i < layout.length; i++) {
    if (line[i] != NonogramModel.unknown && line[i] != layout[i]) return false;
  }
  return true;
}

/// The one rule: decide whatever every layout of a line agrees on.
class LineSolver implements DeductionRule<NonogramModel> {
  const LineSolver();

  @override
  int get level => 1;

  @override
  String get name => 'line';

  @override
  int apply(NonogramModel model) {
    var settled = 0;
    settled += _sweepRows(model);
    settled += _sweepColumns(model);
    return settled;
  }

  int _sweepRows(NonogramModel model) {
    var settled = 0;
    for (var r = 0; r < model.size; r++) {
      final layouts = lineLayouts(model.rowClues[r], model.cells[r]);
      if (layouts.isEmpty) return -1;
      for (var c = 0; c < model.size; c++) {
        if (model.cells[r][c] != NonogramModel.unknown) continue;
        final value = layouts.first[c];
        if (layouts.every((layout) => layout[c] == value)) {
          model.cells[r][c] = value;
          settled++;
        }
      }
    }
    return settled;
  }

  int _sweepColumns(NonogramModel model) {
    var settled = 0;
    for (var c = 0; c < model.size; c++) {
      final line = [for (var r = 0; r < model.size; r++) model.cells[r][c]];
      final layouts = lineLayouts(model.colClues[c], line);
      if (layouts.isEmpty) return -1;
      for (var r = 0; r < model.size; r++) {
        if (model.cells[r][c] != NonogramModel.unknown) continue;
        final value = layouts.first[r];
        if (layouts.every((layout) => layout[r] == value)) {
          model.cells[r][c] = value;
          settled++;
        }
      }
    }
    return settled;
  }
}

const List<DeductionRule<NonogramModel>> nonogramRules = [LineSolver()];

/// Clues for a finished grid: the run lengths of filled cells in each line.
List<int> cluesFor(List<bool> line) {
  final clues = <int>[];
  var run = 0;
  for (final cell in line) {
    if (cell) {
      run++;
    } else if (run > 0) {
      clues.add(run);
      run = 0;
    }
  }
  if (run > 0) clues.add(run);
  return clues.isEmpty ? [0] : clues;
}

/// Counts answers for a clue grid, using the same solver the player has.
SolutionCount countNonogramSolutions({
  required List<List<int>> rowClues,
  required List<List<int>> colClues,
  int limit = 2,
}) {
  final size = rowClues.length;
  return countSolutions(
    NonogramModel(
      cells: List.generate(size, (_) => List<int>.filled(size, NonogramModel.unknown)),
      rowClues: rowClues,
      colClues: colClues,
    ),
    nonogramRules,
    limit: limit,
  );
}
