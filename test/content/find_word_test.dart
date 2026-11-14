import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// find_word, word_scramble and missing_vowels drew their targets from a guess
/// validator: 14,855 five-letter strings of which three quarters are words
/// nobody has seen. The first ten a player could be handed were
/// aahed aalii aapas aargh aarti abaca abaci aback abacs abaft.
void main() {
  List<String> read(String path) => File(path)
      .readAsLinesSync()
      .map((line) => line.trim().toUpperCase())
      .where((line) => line.isNotEmpty)
      .toList();

  final answers = read('assets/find_word_answers.txt');
  final valid = read('assets/find_word_words.txt').toSet();

  test('every answer is a real five-letter word a player could know', () {
    expect(answers.length, greaterThanOrEqualTo(1000));
    for (final word in answers) {
      expect(RegExp(r'^[A-Z]{5}$').hasMatch(word), isTrue, reason: word);
      expect(RegExp('[AEIOU]').hasMatch(word), isTrue,
          reason: '$word has no vowel');
    }
  });

  test('no answer is listed twice', () {
    expect(answers.toSet(), hasLength(answers.length));
  });

  test('every answer can be typed back in as a guess', () {
    // A target that the validator rejects is a game that tells a player their
    // correct answer is not a word.
    final missing = answers.where((word) => !valid.contains(word)).toList();
    expect(missing, isEmpty, reason: 'not in the validator: $missing');
  });

  test('the answers the audit named are gone', () {
    for (final junk in ['AALII', 'AAPAS', 'AARGH', 'AARTI', 'ABACS']) {
      expect(answers, isNot(contains(junk)));
    }
  });

  test('everyday words survived the curation', () {
    const everyday = [
      'CRANE',
      'PLANT',
      'WATER',
      'BRAIN',
      'HOUSE',
      'TIGER',
      'MONEY',
      'LIGHT',
      'SMILE',
      'OCEAN',
      'CHAIR',
      'DREAM',
      'BREAD',
      'HORSE',
      'STONE',
      'MUSIC',
      'GREEN',
      'NIGHT',
      'CLOUD',
      'RIVER',
      'SUGAR',
      'TEACH',
      'WORLD',
      'YOUTH',
    ];
    final missing = everyday.where((word) => !answers.contains(word)).toList();
    expect(missing, isEmpty, reason: 'answers lost: $missing');
    // The validator accepts them all too.
    expect(everyday.where((word) => !valid.contains(word)), isEmpty);
  });

  test('the guess list is still the bigger one', () {
    expect(valid.length, greaterThan(answers.length * 2));
  });
}
