import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/deduction.dart';
import 'package:puzzle/ui/features/games/nonogram/nonogram_engine.dart';
import 'package:puzzle/ui/features/games/nonogram/nonogram_model.dart';

NonogramModel _blank(NonogramPuzzle puzzle) {
  final size = puzzle.rowClues.length;
  return NonogramModel(
    cells: List.generate(
      size,
      (_) => List<int>.filled(size, NonogramModel.unknown),
    ),
    rowClues: puzzle.rowClues,
    colClues: puzzle.colClues,
  );
}

void main() {
  test('every generated board has exactly one answer', () {
    for (final size in [5, 8, 12]) {
      // Seeded, so a failure names a board that can be dealt again.
      final random = Random(size);
      for (var i = 0; i < 30; i++) {
        final puzzle = NonogramEngine().generatePuzzle(size, random: random);
        final count = countNonogramSolutions(
          rowClues: puzzle.rowClues,
          colClues: puzzle.colClues,
        );
        expect(count.truncated, isFalse);
        expect(count.count, 1, reason: 'size $size board $i');
      }
    }
  });

  test('every generated board falls to its own rules at level 2 or easier', () {
    // The generator re-draws until the line solver finishes the board, so this
    // is the promise a deal carries, not a lucky property of the sample. It is
    // the same bar `deal_families.dart` checks, held to here at sizes the Deck
    // does not deal, so a regression cannot hide behind the feed size.
    for (final size in [5, 6, 8, 12]) {
      final random = Random(1000 + size);
      for (var i = 0; i < 20; i++) {
        final puzzle = NonogramEngine().generatePuzzle(size, random: random);
        final rating = rate(_blank(puzzle), nonogramRules);
        expect(rating.verdict, PuzzleVerdict.solved, reason: 'size $size $i');
        expect(rating.level, lessThanOrEqualTo(2), reason: 'size $size $i');
      }
    }
  });

  test('one answer is not enough: a board can be unique and still need a guess',
      () {
    // The bar the generator used to hold, and why it was raised. This clue grid
    // has exactly one answer, and the line solver stalls 15 cells in, so a
    // player is stuck on a board with no second answer and no next move. A
    // generator that only counted answers dealt one of these about 3 times in
    // 1000 at 6x6, which is the G4 gate failing intermittently.
    const rows = [
      [2, 1],
      [2],
      [1],
      [3],
      [1, 4],
      [1],
    ];
    const cols = [
      [1, 2],
      [1, 1],
      [1, 2],
      [1, 2],
      [2],
      [1, 1],
    ];
    final count = countNonogramSolutions(rowClues: rows, colClues: cols);
    expect(count.count, 1);
    final board = NonogramModel(
      cells: List.generate(
        6,
        (_) => List<int>.filled(6, NonogramModel.unknown),
      ),
      rowClues: rows,
      colClues: cols,
    );
    expect(deduce(board.copy(), nonogramRules).complete, isFalse);
    expect(rate(board, nonogramRules).verdict, PuzzleVerdict.unfinished);
  });

  test('a below-bar draw is redrawn, not shipped', () {
    // Mutation that proves the check is load-bearing: delete the
    // `!outcome.complete` branch in `generatePuzzle` and this test fails on the
    // `isNot` below, because the first picture `Random(901)` draws is exactly
    // the one it then hands back. That picture has one answer and the line
    // solver stalls on it, so it is a real deal the app must not make.
    const seed = 901;
    final draw = Random(seed);
    final first = [
      for (var r = 0; r < 6; r++)
        [for (var c = 0; c < 6; c++) draw.nextDouble() > 0.45],
    ];
    final firstRows = [for (final row in first) cluesFor(row)];
    final firstCols = [
      for (var c = 0; c < 6; c++) cluesFor([for (final row in first) row[c]]),
    ];
    final firstCount = countNonogramSolutions(
      rowClues: firstRows,
      colClues: firstCols,
    );
    expect(firstCount.count, 1, reason: 'the first draw is uniquely solvable');
    final firstRating = rate(
      NonogramModel(
        cells: List.generate(
          6,
          (_) => List<int>.filled(6, NonogramModel.unknown),
        ),
        rowClues: firstRows,
        colClues: firstCols,
      ),
      nonogramRules,
    );
    expect(firstRating.verdict, PuzzleVerdict.unfinished);

    final deal = NonogramEngine().generatePuzzle(6, random: Random(seed));
    expect(deal.rowClues, isNot(equals(firstRows)));
    final dealRating = rate(_blank(deal), nonogramRules);
    expect(dealRating.verdict, PuzzleVerdict.solved);
    expect(dealRating.level, lessThanOrEqualTo(2));
  });

  test('random pictures really do produce ambiguous clue grids', () {
    // This is why the generator counts: a plain random fill is ambiguous often
    // enough that shipping it unchecked handed players ~1 board in 5 with more
    // than one answer.
    final random = Random(8);
    var ambiguous = 0;
    for (var attempt = 0; attempt < 80; attempt++) {
      final grid = [
        for (var r = 0; r < 8; r++)
          [for (var c = 0; c < 8; c++) random.nextDouble() > 0.45],
      ];
      final rows = [for (final row in grid) cluesFor(row)];
      final cols = [
        for (var c = 0; c < 8; c++) cluesFor([for (final row in grid) row[c]]),
      ];
      final count = countNonogramSolutions(rowClues: rows, colClues: cols);
      if (count.count > 1) ambiguous++;
    }
    expect(ambiguous, greaterThan(0));
  });

  test('the line solver decides what is forced and nothing more', () {
    // A single block of 5 in a line of 5 fills everything.
    final line = List<int>.filled(5, NonogramModel.unknown);
    final layouts = lineLayouts([5], line);
    expect(layouts, hasLength(1));
    expect(layouts.single, [1, 1, 1, 1, 1]);
  });
}
