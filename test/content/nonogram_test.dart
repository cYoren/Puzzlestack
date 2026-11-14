import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/nonogram/nonogram_engine.dart';
import 'package:puzzle/ui/features/games/nonogram/nonogram_model.dart';

void main() {
  test('every generated board has exactly one answer', () {
    final engine = NonogramEngine();
    for (final size in [5, 8, 12]) {
      for (var i = 0; i < 30; i++) {
        final puzzle = engine.generatePuzzle(size);
        final count = countNonogramSolutions(
          rowClues: puzzle.rowClues,
          colClues: puzzle.colClues,
        );
        expect(count.truncated, isFalse);
        expect(count.count, 1, reason: 'size $size board $i');
      }
    }
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
