import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/letter_bridge/letter_bridge_engine.dart';

/// The app's own dictionaries, read from disk — the same two files the game
/// ships and the audit measured. A row that is not two words around the bridge
/// is unguessable, not hard.
Set<String> _dictionary() {
  final words = <String>{};
  for (final path in const [
    'assets/chain_words.txt',
    'assets/find_word_words.txt',
  ]) {
    for (final line in File(path).readAsLinesSync()) {
      final word = line.trim().toLowerCase();
      if (word.isNotEmpty) words.add(word);
    }
  }
  return words;
}

void main() {
  final dictionary = _dictionary();

  test('every bridge joins two real words', () {
    final broken = <String>[];
    for (final puzzle in LetterBridgeEngine.allPuzzles) {
      final first = puzzle['first']!.toLowerCase();
      final second = puzzle['second']!.toLowerCase();
      final bridge = puzzle['bridge']!.toLowerCase();

      if (!dictionary.contains(first + bridge)) {
        broken.add('$first + $bridge = ${first + bridge}');
      }
      if (!dictionary.contains(bridge + second)) {
        broken.add('$bridge + $second = ${bridge + second}');
      }
    }
    expect(broken, isEmpty,
        reason: 'unguessable rows:\n${broken.join('\n')}');
  });

  test('the bridge is a single letter that completes both halves', () {
    for (final puzzle in LetterBridgeEngine.allPuzzles) {
      expect(puzzle['bridge'], hasLength(1));
      expect(puzzle['bridge']!.toUpperCase(), puzzle['bridge']);
      expect(puzzle['first'], puzzle['first']!.toUpperCase());
      expect(puzzle['second'], puzzle['second']!.toUpperCase());
    }
  });

  test('no two puzzles show the same halves with different answers', () {
    final seen = <String, String>{};
    for (final puzzle in LetterBridgeEngine.allPuzzles) {
      final display = '${puzzle['first']}/${puzzle['second']}';
      final previous = seen[display];
      expect(previous == null || previous == puzzle['bridge'], isTrue,
          reason: '$display asks for both $previous and ${puzzle['bridge']}');
      seen[display] = puzzle['bridge']!;
    }
  });

  test('the pool is deep enough to not repeat inside a session', () {
    expect(LetterBridgeEngine.allPuzzles.length, greaterThanOrEqualTo(30));
  });

  test('the engine accepts the table answer and nothing else', () {
    final engine = LetterBridgeEngine();
    for (final puzzle in LetterBridgeEngine.allPuzzles.take(10)) {
      expect(engine.isCorrect(puzzle['bridge']!, puzzle['bridge']!.toLowerCase()),
          isTrue);
    }
    expect(engine.isCorrect('T', 'X'), isFalse);
  });
}
