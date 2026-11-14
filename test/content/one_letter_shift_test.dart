import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/one_letter_shift/one_letter_shift_engine.dart';

/// The subtitle says "transform one word into another with one letter change".
/// 24 of the 26 rows that shipped were anagrams, so the rule the player was
/// told was false. Every row now changes exactly one position.
void main() {
  final puzzles = OneLetterShiftEngine.allPuzzles;

  test('every row changes exactly one letter, in place', () {
    final wrong = <String>[];
    for (final puzzle in puzzles) {
      final start = puzzle['start']!;
      final end = puzzle['end']!;
      if (start.length != end.length) {
        wrong.add('$start -> $end (different lengths)');
        continue;
      }
      final changed = [
        for (var i = 0; i < start.length; i++)
          if (start[i] != end[i]) i,
      ];
      if (changed.length != 1) {
        wrong.add('$start -> $end (${changed.length} positions)');
      }
    }
    expect(wrong, isEmpty, reason: wrong.join('\n'));
  });

  test('both words are real words the app knows', () {
    final dictionary = <String>{
      for (final line in File('assets/chain_words.txt').readAsLinesSync())
        if (line.trim().isNotEmpty) line.trim().toUpperCase(),
    };
    final missing = [
      for (final puzzle in puzzles)
        for (final key in ['start', 'end'])
          if (!dictionary.contains(puzzle[key])) puzzle[key]!,
    ];
    expect(missing, isEmpty, reason: 'not in the dictionary: $missing');
  });

  test('every row has a hint and a unique pair', () {
    final seen = <String>{};
    for (final puzzle in puzzles) {
      expect(puzzle['hint']!.trim(), isNotEmpty);
      final key = '${puzzle['start']}->${puzzle['end']}';
      expect(seen.add(key), isTrue, reason: 'duplicate row $key');
    }
    expect(puzzles.length, greaterThanOrEqualTo(30));
  });

  test('the pair the audit called out is gone', () {
    for (final puzzle in puzzles) {
      expect(puzzle['end'], isNot('ROSET'));
      expect(puzzle['start'], isNot('SWING'));
    }
  });

  test('the engine accepts the answer and only the answer', () {
    final engine = OneLetterShiftEngine();
    expect(engine.isCorrect('BOARD', 'board'), isTrue);
    expect(engine.isCorrect('BOARD', 'BEARD'), isFalse);
  });
}
