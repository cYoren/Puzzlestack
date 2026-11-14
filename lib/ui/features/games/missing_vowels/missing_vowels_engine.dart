import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class MissingVowelsEngine {
  static const int minWordLength = 5;
  static const int maxWordLength = 8;

  static List<String> _processWords(String data) {
    return data
        .split('\n')
        .map((w) => w.trim().toUpperCase())
        .where((w) => w.length >= minWordLength && w.length <= maxWordLength)
        .where((w) => w.contains(RegExp('[AEIOU]'))) // Must have vowels
        .toList();
  }

  /// English only: the shipped word asset is English, and the parameter this
  /// used to accept was never read.
  Future<List<String>> loadWords() async {
    try {
      // Curated answers, not the guess-validating list: an obscure word with
      // its vowels removed is unguessable, not hard.
      final data = await rootBundle.loadString('assets/find_word_answers.txt');
      return await compute(_processWords, data);
    } catch (e) {
      return ['APPLE', 'BANANA', 'CHERRY', 'ORANGE', 'GRAPES'];
    }
  }

  String getRandomWord(List<String> words) {
    if (words.isEmpty) return 'APPLE';
    return words[Random().nextInt(words.length)];
  }

  String hideVowels(String word) {
    return word.replaceAll(RegExp('[AEIOU]'), '_');
  }

  bool checkGuess(String guess, String target) {
    return guess.trim().toUpperCase() == target.trim().toUpperCase();
  }
}
