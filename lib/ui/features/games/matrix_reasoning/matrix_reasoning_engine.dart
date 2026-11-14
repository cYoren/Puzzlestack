import 'dart:math';
import 'package:flutter/material.dart';

/// Raven-style matrix reasoning.
///
/// The old generator had three fixed layouts, always hid the bottom-right cell
/// and filled the distractors with random shape/colour pairs. Two things were
/// wrong with that: the pattern was visible from the first row, and the wrong
/// answers could be eliminated without reading the matrix at all.
///
/// This one builds a real progression:
///
///  * **easy** — one attribute runs along the rows, the other is constant.
///  * **medium** — shape runs along the rows, colour down the columns.
///  * **hard** — both attributes form a Latin square: every row holds all three
///    shapes once, every column all three colours once, so the answer is the
///    only cell that completes both lines.
///
/// The missing cell is at a random position, and every distractor is exactly
/// one attribute away from the answer, so guessing is a coin toss between four
/// plausible cells rather than a lucky pick from noise.
class MatrixReasoningEngine {
  final Random _random = Random();

  static const List<IconData> _shapes = [
    Icons.circle,
    Icons.square,
    Icons.change_history,
    Icons.star,
    Icons.pentagon,
    Icons.hexagon,
  ];

  static const List<Color> _colours = [
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFA855F7),
    Color(0xFF06B6D4),
  ];

  /// [level] is 0..2 and is fed by the score, so a run gets harder as it goes.
  MatrixReasoningPuzzle generatePuzzle({int level = 1}) {
    final tier = level.clamp(0, 2);
    final shapes = [..._shapes]..shuffle(_random);
    final colours = [..._colours]..shuffle(_random);

    final rowShift = _random.nextInt(3);
    final columnShift = _random.nextInt(3);

    MatrixCell cellAt(int row, int col) {
      switch (tier) {
        case 0:
          // Shape along the row, one colour throughout.
          return MatrixCell(
            shape: shapes[(col + rowShift) % 3],
            color: colours[0],
          );
        case 2:
          // Latin square: shapes cycle with the row, colours with the column.
          return MatrixCell(
            shape: shapes[(row + col + rowShift) % 3],
            color: colours[(row + col + columnShift) % 3],
          );
        default:
          // Shape along the row, colour down the column.
          return MatrixCell(
            shape: shapes[(col + rowShift) % 3],
            color: colours[(row + columnShift) % 3],
          );
      }
    }

    final cells = [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++) cellAt(row, col),
    ];

    final missingIndex = _random.nextInt(9);
    final answer = cells[missingIndex];

    // Every wrong option is one attribute away, so all four are plausible at a
    // glance and only the rule separates them.
    final otherShapes = shapes.where((shape) => shape != answer.shape).toList()
      ..shuffle(_random);
    final otherColours =
        colours.where((colour) => colour != answer.color).toList()
          ..shuffle(_random);
    final options = <MatrixCell>[
      answer,
      MatrixCell(shape: answer.shape, color: otherColours.first),
      MatrixCell(shape: otherShapes[0], color: answer.color),
      MatrixCell(shape: otherShapes[1], color: answer.color),
    ]..shuffle(_random);

    return MatrixReasoningPuzzle(
      cells: cells,
      answer: answer,
      options: options,
      missingIndex: missingIndex,
      level: tier,
    );
  }
}

class MatrixCell {
  final IconData shape;
  final Color color;

  MatrixCell({required this.shape, required this.color});
}

class MatrixReasoningPuzzle {
  final List<MatrixCell> cells;
  final MatrixCell answer;
  final List<MatrixCell> options;
  final int missingIndex;
  final int level;

  MatrixReasoningPuzzle({
    required this.cells,
    required this.answer,
    required this.options,
    required this.missingIndex,
    this.level = 1,
  });
}
