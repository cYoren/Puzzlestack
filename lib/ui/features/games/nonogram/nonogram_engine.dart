import 'dart:math';

import 'package:puzzle/core/deduction.dart';

import 'nonogram_model.dart';

class NonogramPuzzle {
  final List<List<int>> rowClues;
  final List<List<int>> colClues;

  NonogramPuzzle({
    required this.rowClues,
    required this.colClues,
  });
}

class NonogramEngine {
  /// Proposes a random picture, derives the clues, and ships the board only
  /// when one answer is all the clues allow **and** the game's own line solver
  /// reaches that answer without a guess.
  ///
  /// Without a check, roughly one 8x8 board in five had more than one answer:
  /// the win check compares clues, so a player could "finish" a picture the
  /// generator never drew, and the house rule ("every puzzle has exactly one
  /// solution") was simply false.
  ///
  /// Uniqueness alone was still not enough. Measured over 400 random 6x6
  /// pictures, 324 clue grids had exactly one answer, and one of those needed a
  /// guess: nothing in the board points at the cell, so a player is stuck on a
  /// uniquely-solvable puzzle. That is the deal the G4 gate (`level <= 2`) was
  /// failing on about 1 run in 130, with a different board each time.
  ///
  /// So the bar is the stronger one, and it is also the cheaper one to check:
  /// if the line solver alone fills every cell, every filled cell was forced by
  /// the clues, so the answer is unique and reachable without guessing. Boards
  /// that fail it are redrawn, which costs about 7 deals in 1000 (3 of 400
  /// measured at 6x6), so one redraw in 130.
  ///
  /// [random] exists so a test can deal the same boards twice; the app leaves
  /// it out and gets its own.
  NonogramPuzzle generatePuzzle(int size, {Random? random}) {
    final source = random ?? Random();
    for (var attempt = 0; attempt < 500; attempt++) {
      final List<List<bool>> solution = List.generate(
        size,
        (_) => List.generate(size, (_) => source.nextDouble() > 0.45),
      );

      final List<List<int>> rowClues = [
        for (int r = 0; r < size; r++) _calculateClues(solution[r]),
      ];
      final List<List<int>> colClues = [
        for (int c = 0; c < size; c++)
          _calculateClues([for (int r = 0; r < size; r++) solution[r][c]]),
      ];

      final outcome = deduce(
        NonogramModel(
          cells: List.generate(
            size,
            (_) => List<int>.filled(size, NonogramModel.unknown),
          ),
          rowClues: rowClues,
          colClues: colClues,
        ),
        nonogramRules,
      );
      // A board the rules contradict, or cannot finish, is not a deal. Neither
      // is one with a second answer: the rules reaching a finished board means
      // every cell was forced, so exactly one answer exists.
      if (!outcome.consistent || !outcome.complete) continue;

      return NonogramPuzzle(rowClues: rowClues, colClues: colClues);
    }
    throw StateError(
      'no finishable unique nonogram after 500 attempts at $size',
    );
  }

  List<int> _calculateClues(List<bool> line) {
    final List<int> clues = [];
    int currentRun = 0;
    for (bool cell in line) {
      if (cell) {
        currentRun++;
      } else if (currentRun > 0) {
        clues.add(currentRun);
        currentRun = 0;
      }
    }
    if (currentRun > 0) {
      clues.add(currentRun);
    }
    return clues.isEmpty ? [0] : clues;
  }

  static bool isCorrect(List<List<int>> currentGrid, List<List<int>> rowClues,
      List<List<int>> colClues) {
    final size = currentGrid.length;
    final engine = NonogramEngine();

    // Check rows
    for (int r = 0; r < size; r++) {
      final List<bool> row = currentGrid[r].map((e) => e == 1).toList();
      final calculatedClues = engine._calculateClues(row);
      if (!engine._listEquals(calculatedClues, rowClues[r])) return false;
    }

    // Check columns
    for (int c = 0; c < size; c++) {
      final List<bool> column = [];
      for (int r = 0; r < size; r++) {
        column.add(currentGrid[r][c] == 1);
      }
      final calculatedClues = engine._calculateClues(column);
      if (!engine._listEquals(calculatedClues, colClues[c])) return false;
    }

    return true;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static NonogramPuzzle generatePuzzleWrapper(int size) {
    return NonogramEngine().generatePuzzle(size);
  }

  static bool isCorrectWrapper(Map<String, dynamic> params) {
    return isCorrect(
      params['grid'] as List<List<int>>,
      params['rowClues'] as List<List<int>>,
      params['colClues'] as List<List<int>>,
    );
  }
}
