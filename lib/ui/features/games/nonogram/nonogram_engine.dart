import 'dart:math';

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
  final Random _random = Random();

  /// Proposes a random picture, derives the clues, and ships the board only
  /// when the clues pin down exactly one answer.
  ///
  /// Without the count, roughly one 8x8 board in five had more than one
  /// answer: the win check compares clues, so a player could "finish" a picture
  /// the generator never drew, and the house rule ("every puzzle has exactly
  /// one solution") was simply false. The count uses the same line solver a
  /// player reasons with (`nonogram_model.dart`).
  NonogramPuzzle generatePuzzle(int size) {
    for (var attempt = 0; attempt < 500; attempt++) {
      final List<List<bool>> solution = List.generate(
        size,
        (_) => List.generate(size, (_) => _random.nextDouble() > 0.45),
      );

      final List<List<int>> rowClues = [
        for (int r = 0; r < size; r++) _calculateClues(solution[r]),
      ];
      final List<List<int>> colClues = [
        for (int c = 0; c < size; c++)
          _calculateClues([for (int r = 0; r < size; r++) solution[r][c]]),
      ];

      final count = countNonogramSolutions(
        rowClues: rowClues,
        colClues: colClues,
      );
      if (count.truncated) {
        // A count we did not finish proves nothing; try another board.
        continue;
      }
      if (count.isUnique) {
        return NonogramPuzzle(rowClues: rowClues, colClues: colClues);
      }
    }
    throw StateError('no unique nonogram after 500 attempts at $size');
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

  static bool isCorrect(List<List<int>> currentGrid, List<List<int>> rowClues, List<List<int>> colClues) {
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
