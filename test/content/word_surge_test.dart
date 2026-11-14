import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/word_surge/word_surge_engine.dart';
import 'package:puzzle/ui/features/games/word_surge/word_surge_provider.dart';

/// Fifteen pairs against a target of fifteen points: one run used the whole
/// pool, so the second game was the same words again.
void main() {
  final engine = WordSurgeEngine();
  final pairs = engine.wordPairs;
  final runLength = WordSurgeState().targetScore;

  test('the pool covers several runs', () {
    expect(pairs.length, greaterThanOrEqualTo(runLength * 3),
        reason: '${pairs.length} pairs for a $runLength-point run');
  });

  test('no word is asked twice', () {
    final words = pairs.map((pair) => (pair['word'] as String).toLowerCase());
    expect(words.toSet(), hasLength(pairs.length));
  });

  test('every pair has three synonyms and three antonyms', () {
    for (final pair in pairs) {
      final word = pair['word'] as String;
      final synonyms = (pair['synonyms'] as List).cast<String>();
      final antonyms = (pair['antonyms'] as List).cast<String>();
      expect(synonyms, hasLength(3), reason: word);
      expect(antonyms, hasLength(3), reason: word);
      expect(synonyms.toSet(), hasLength(3), reason: '$word repeats a synonym');
      expect(antonyms.toSet(), hasLength(3), reason: '$word repeats an antonym');
      for (final option in [...synonyms, ...antonyms]) {
        expect(option.trim(), isNotEmpty);
        expect(option.toLowerCase(), isNot(word.toLowerCase()),
            reason: '$word lists itself');
        expect(RegExp(r"^[A-Za-z' -]+$").hasMatch(option), isTrue,
            reason: '$word: "$option"');
      }
      // A synonym is never also an antonym.
      expect(
        synonyms.map((s) => s.toLowerCase()).toSet().intersection(
            antonyms.map((a) => a.toLowerCase()).toSet()),
        isEmpty,
        reason: '$word uses the same option on both sides',
      );
    }
  });

  test('a challenge offers four options, one of them right', () {
    for (var i = 0; i < 200; i++) {
      final challenge = engine.getRandomChallenge();
      expect(challenge.options, hasLength(4));
      expect(challenge.options.toSet(), hasLength(4));
      expect(challenge.options, contains(challenge.answer));
    }
  });
}
