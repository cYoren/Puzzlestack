import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/homophone_hunt/homophone_hunt_engine.dart';

/// Eleven sentences, one per run: the whole game was eleven rounds long.
void main() {
  final engine = HomophoneHuntEngine();
  final data = engine.data;

  test('the pool outlasts a session', () {
    expect(data.length, greaterThanOrEqualTo(20));
  });

  test('every sentence has one blank, and the right word fills it', () {
    for (final item in data) {
      final sentence = item['sentence'] as String;
      final correct = item['correct'] as String;
      final wrong = item['wrong'] as String;
      final full = item['full'] as String;
      expect('____'.allMatches(sentence).length, 1,
          reason: 'one blank per sentence: $sentence');
      expect(correct.toLowerCase(), isNot(wrong.toLowerCase()),
          reason: '${item['sentence']} offers one word twice');
      expect(sentence.replaceFirst('____', correct), full,
          reason: 'the full sentence is not the sentence with its answer');
      expect(full.contains('____'), isFalse);
      // Both candidates have to be plausible in the same slot: the puzzle is a
      // sound-alike choice, not a vocabulary test.
      expect(correct.trim(), isNotEmpty);
      expect(wrong.trim(), isNotEmpty);
    }
  });

  test('no sentence is asked twice', () {
    final sentences = data.map((item) => item['sentence'] as String).toList();
    expect(sentences.toSet(), hasLength(sentences.length));
  });

  test('the two syllables really are two spellings', () {
    // A homophone pair differs in spelling by construction. Equal-length pairs
    // are fine (right/write); identical ones are not.
    for (final item in data) {
      final correct = (item['correct'] as String).toLowerCase();
      final wrong = (item['wrong'] as String).toLowerCase();
      expect(correct, isNot(wrong));
      expect('$correct|$wrong', isNot('$wrong|$correct'));
    }
  });

  test('a puzzle is one of the sentences, blank and all', () {
    final sentences = data.map((item) => item['sentence'] as String).toSet();
    for (var i = 0; i < 200; i++) {
      final puzzle = engine.generatePuzzle();
      expect(sentences, contains(puzzle.sentence));
      expect(puzzle.sentence.replaceFirst('____', puzzle.correctAnswer),
          puzzle.fullSentence);
      expect(puzzle.fullSentence, contains(puzzle.correctAnswer));
      expect(puzzle.correctAnswer, isNot(puzzle.wrongAnswer));
    }
  });
}
