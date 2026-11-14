import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/word_snake_trail/word_snake_trail_screen.dart';

/// Ten words on a 4x4 board, one per round, so the tenth round was the first
/// again. A trail cannot reuse a cell, which makes a word with a repeated
/// letter unsolvable even though the generator places it -- the test traces
/// every word on the real board to prove it.
void main() {
  test('the pool outlasts a session', () {
    expect(wordSnakePool.length, greaterThanOrEqualTo(30));
  });

  test('every word is plain and fits the board', () {
    final cells = wordSnakeGridSize * wordSnakeGridSize;
    for (final word in wordSnakePool) {
      expect(RegExp(r'^[A-Z]+$').hasMatch(word), isTrue, reason: word);
      expect(word.length, greaterThanOrEqualTo(3), reason: word);
      expect(word.length, lessThanOrEqualTo(cells), reason: word);
    }
  });

  test('no word is listed twice', () {
    expect(wordSnakePool.toSet(), hasLength(wordSnakePool.length));
  });

  test('every word can be traced without reusing a cell', () {
    // The generator walks a path of unvisited cells; a repeated letter makes
    // that impossible to solve, because the tap handler refuses a cell twice.
    for (final word in wordSnakePool) {
      expect(word.split('').toSet(), hasLength(word.length),
          reason: '$word repeats a letter and cannot be traced');
    }
  });

  test('a trail always completes, one cell per letter', () {
    // The generator used to walk randomly and reuse a cell when it cornered
    // itself, which put one letter on two cells: the board looked solvable and
    // was not. Two thousand builds, no repeated cell, always the right length.
    for (var i = 0; i < 2000; i++) {
      final word = wordSnakePool[i % wordSnakePool.length];
      final trail = buildWordSnakeTrail(
        gridSize: wordSnakeGridSize,
        length: word.length,
        random: Random(i),
      );
      expect(trail, hasLength(word.length));
      expect(trail.toSet(), hasLength(word.length),
          reason: '$word was traced onto a cell twice');
      for (var step = 1; step < trail.length; step++) {
        final a = trail[step - 1];
        final b = trail[step];
        expect((a.x - b.x).abs() + (a.y - b.y).abs(), 1,
            reason: 'step $step of $word is not a step on the board');
      }
      for (final point in trail) {
        expect(point.x, inInclusiveRange(0, wordSnakeGridSize - 1));
        expect(point.y, inInclusiveRange(0, wordSnakeGridSize - 1));
      }
    }
  });
}
