import 'dart:math';

class OxymoronHuntEngine {
  final Random _random = Random();

  /// Two words that contradict each other. A run deals four pairs and the
  /// player finds the odd one out, so eighteen pairs was four rounds of content.
  final List<OxymoronPair> _allPairs = [
    OxymoronPair('DEAFENING', 'SILENCE'),
    OxymoronPair('BITTER', 'SWEET'),
    OxymoronPair('ONLY', 'CHOICE'),
    OxymoronPair('ORIGINAL', 'COPY'),
    OxymoronPair('AWFUL', 'GOOD'),
    OxymoronPair('ALONE', 'TOGETHER'),
    OxymoronPair('LIQUID', 'GAS'),
    OxymoronPair('SERIOUSLY', 'FUNNY'),
    OxymoronPair('SMALL', 'CROWD'),
    OxymoronPair('OPEN', 'SECRET'),
    OxymoronPair('FOUND', 'MISSING'),
    OxymoronPair('CLEARLY', 'CONFUSED'),
    OxymoronPair('ACT', 'NATURALLY'),
    OxymoronPair('VIRTUAL', 'REALITY'),
    OxymoronPair('CRUEL', 'KINDNESS'),
    OxymoronPair('PRETTY', 'UGLY'),
    OxymoronPair('OLD', 'NEWS'),
    OxymoronPair('LIVING', 'DEAD'),
    OxymoronPair('SAME', 'DIFFERENCE'),
    OxymoronPair('PASSIVE', 'AGGRESSIVE'),
    OxymoronPair('CONSTANT', 'CHANGE'),
    OxymoronPair('EXACT', 'ESTIMATE'),
    OxymoronPair('GROWING', 'SMALLER'),
    OxymoronPair('RANDOM', 'ORDER'),
    OxymoronPair('SOFT', 'ROCK'),
    OxymoronPair('LOUD', 'WHISPER'),
    OxymoronPair('WORKING', 'VACATION'),
    OxymoronPair('AUTHENTIC', 'REPLICA'),
    OxymoronPair('WISE', 'FOOL'),
    OxymoronPair('SWEET', 'SORROW'),
    OxymoronPair('SILENT', 'SCREAM'),
    OxymoronPair('BURNING', 'COLD'),
    OxymoronPair('SIMPLY', 'COMPLEX'),
    OxymoronPair('ORDERLY', 'CHAOS'),
    OxymoronPair('ROLLING', 'STOP'),
    OxymoronPair('DELIBERATE', 'MISTAKE'),
    OxymoronPair('HAPPY', 'SADNESS'),
    OxymoronPair('FREEZING', 'HEAT'),
    OxymoronPair('CIVIL', 'WAR'),
    OxymoronPair('FRESH', 'FROZEN'),
    OxymoronPair('JUMBO', 'SHRIMP'),
    OxymoronPair('BLACK', 'LIGHT'),
    OxymoronPair('STILL', 'MOVING'),
    OxymoronPair('CALM', 'STORM'),
    OxymoronPair('WICKED', 'GOOD'),
    OxymoronPair('PRETTY', 'AWFUL'),
    OxymoronPair('ALMOST', 'EXACT'),
    OxymoronPair('ALMOST', 'PERFECT'),
  ];

  /// Every pair, so a test can check the table is a table: two distinct words,
  /// no pair twice, no pair made of the same word.
  List<OxymoronPair> get allPairs => List.unmodifiable(_allPairs);

  OxymoronHuntPuzzle generatePuzzle() {
    final pairs = List<OxymoronPair>.from(_allPairs);
    pairs.shuffle(_random);

    // Four pairs, and no word twice on the board. Pairs in the table may share
    // a word legitimately (BITTER/SWEET and SWEET/SORROW), but dealing both at
    // once puts one word in two cells and the grid shows seven words for eight
    // slots.
    final selectedPairs = <OxymoronPair>[];
    final dealtWords = <String>{};
    for (final pair in pairs) {
      if (selectedPairs.length == 4) break;
      if (dealtWords.contains(pair.word1) || dealtWords.contains(pair.word2)) {
        continue;
      }
      selectedPairs.add(pair);
      dealtWords.addAll([pair.word1, pair.word2]);
    }

    final words = dealtWords.toList()..shuffle(_random);

    return OxymoronHuntPuzzle(
      words: words,
      pairs: selectedPairs,
    );
  }
}

class OxymoronPair {
  final String word1;
  final String word2;

  OxymoronPair(this.word1, this.word2);

  bool contains(String word) => word1 == word || word2 == word;
}

class OxymoronHuntPuzzle {
  final List<String> words;
  final List<OxymoronPair> pairs;

  OxymoronHuntPuzzle({
    required this.words,
    required this.pairs,
  });
}
