import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

enum LetterStatus { initial, notInWord, wrongSpot, correctSpot }

class FindWordEngine {
  static const int maxTries = 6;
  static const int wordLength = 5;
  static final Map<String, Set<String>> _cachedWords = {};
  static Set<String>? _cachedAnswers;

  static Set<String> _processWords(String data) {
    return data
        .split('\n')
        .map((w) => w.trim().toUpperCase())
        .where((w) => w.length == wordLength)
        .toSet();
  }

  /// The words a target can be drawn from.
  ///
  /// `find_word_words.txt` is a guess validator: 14,855 five-letter strings of
  /// which three quarters are words nobody has seen. The first ten a player
  /// could be handed were aahed aalii aapas aargh aarti abaca abaci aback
  /// abacs abaft. Fine for "is this a word", useless for "guess this word".
  /// Targets come from the curated list instead, and every entry there is also
  /// in the full list, so a target can always be typed back in as a guess.
  Future<Set<String>> loadAnswers() async {
    final cached = _cachedAnswers;
    if (cached != null) return cached;
    try {
      final data =
          await rootBundle.loadString('assets/find_word_answers.txt');
      final answers = await compute(_processWords, data);
      if (answers.isEmpty) return _getFallbackWords();
      return _cachedAnswers = answers;
    } catch (e) {
      return _getFallbackWords();
    }
  }

  /// Every five-letter string a guess may be. English only: the asset is
  /// English, and this used to take a `languageCode` it never read.
  Future<Set<String>> loadWords() async {
    final cached = _cachedWords['en'];
    if (cached != null) return cached;
    
    try {
      final data = await rootBundle.loadString('assets/find_word_words.txt');
      final words = await compute(_processWords, data);
      
      if (words.isEmpty) {
        return _getFallbackWords();
      }
      _cachedWords['en'] = words;
      return words;
    } catch (e) {
      return _getFallbackWords();
    }
  }

  Set<String> _getFallbackWords() {
    return {'APPLE', 'BRAIN', 'CHAIR', 'DANCE', 'EARTH'};
  }

  String getRandomWord(Set<String> words) {
    if (words.isEmpty) return 'APPLE';
    return words.elementAt(Random().nextInt(words.length));
  }

  List<LetterStatus> checkGuess(String guess, String target) {
    List<LetterStatus> results = List.filled(wordLength, LetterStatus.notInWord);
    
    // Safety check: ensure both words have the expected length
    if (guess.length != wordLength || target.length != wordLength) {
      return results;
    }

    List<String> targetList = target.split('');
    List<String> guessList = guess.split('');

    // First pass: Correct spots
    for (int i = 0; i < wordLength; i++) {
      if (guessList[i] == targetList[i]) {
        results[i] = LetterStatus.correctSpot;
        targetList[i] = ''; // Mark as used
        guessList[i] = ''; // Mark as handled
      }
    }

    // Second pass: Wrong spots
    for (int i = 0; i < wordLength; i++) {
      if (guessList[i] != '') {
        int index = targetList.indexOf(guessList[i]);
        if (index != -1) {
          results[i] = LetterStatus.wrongSpot;
          targetList[index] = ''; // Mark as used
        }
      }
    }

    return results;
  }
}
