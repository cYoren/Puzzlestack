import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/word_search/word_search_engine.dart';

/// 105 words, a 4..8 letter filter and eight words a board meant five boards
/// before every word had been used, and sixteen of the longest entries could
/// never appear at all. A word search lives on its supply.
void main() {
  final raw = File('assets/word_search_words.txt')
      .readAsLinesSync()
      .map((line) => line.trim().toUpperCase())
      .where((line) => line.isNotEmpty)
      .toList();

  /// What the provider feeds the engine: the asset through the filter.
  final usable =
      raw.where((word) => word.length >= 4 && word.length <= 10).toList();

  test('every entry is a word the 10x10 board can hold', () {
    final wrong = raw.where((word) =>
        !RegExp(r'^[A-Z]+$').hasMatch(word) ||
        word.length < 4 ||
        word.length > 10);
    expect(wrong, isEmpty, reason: 'not placeable: ${wrong.join(', ')}');
  });

  test('the supply lasts more than a handful of boards', () {
    expect(usable.length, greaterThanOrEqualTo(300),
        reason: '${usable.length} words left after the filter');
    // Eight words a board.
    expect(usable.length ~/ 8, greaterThanOrEqualTo(20));
  });

  test('no word is listed twice', () {
    expect(raw.toSet(), hasLength(raw.length));
  });

  test('a ten-letter word still fits', () {
    // The filter used to stop at eight, so every 9- and 10-letter entry in the
    // asset was dead weight. The board is exactly wide enough for ten.
    final board = WordSearchEngine.generateBoard(['ABCDEFGHIJ']);
    expect(board.words.map((w) => w.word), contains('ABCDEFGHIJ'));
  });

  test('boards drawn from the shipped list are playable and honest', () {
    final random = Random(11);
    final pool = List<String>.from(usable);
    for (var board = 0; board < 20; board++) {
      pool.shuffle(random);
      final generated = WordSearchEngine.generateBoard(pool.take(15).toList());
      expect(generated.words, isNotEmpty, reason: 'board $board placed nothing');
      expect(generated.words.length, lessThanOrEqualTo(8));
      for (final placed in generated.words) {
        expect(usable, contains(placed.word),
            reason: '${placed.word} is not in the pool');
        // Every letter of the placed word is really on the grid, in order.
        final letters = placed.positions
            .map((p) => generated.grid[p.y][p.x])
            .join();
        expect(letters, placed.word);
      }
    }
  });
}
