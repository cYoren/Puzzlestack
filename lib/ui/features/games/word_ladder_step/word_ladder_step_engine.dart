import 'dart:math' as math;

class WordLadderQuestion {
  final String startWord;
  final String endWord;
  final String correctMiddleWord;
  final List<String> choices;

  WordLadderQuestion({
    required this.startWord,
    required this.endWord,
    required this.correctMiddleWord,
    required this.choices,
  });
}

class WordLadderStepEngine {
  /// Start, middle and end of a three-word ladder: each step changes exactly
  /// one letter. A run draws one ladder, so eight ladders was eight rounds and
  /// then the same eight again.
  static final List<List<String>> _ladders = [
    ['COLD', 'CORD', 'WORD'],
    ['HEAD', 'HEAL', 'TEAL'],
    ['WARM', 'WORM', 'WORD'],
    ['COT', 'DOT', 'DOG'],
    ['FOUR', 'FOUL', 'FOOL'],
    ['BEST', 'BEAT', 'BOAT'],
    ['LEAD', 'LOAD', 'TOAD'],
    ['MORE', 'MARE', 'MAKE'],
    ['DOWN', 'DAWN', 'DARN'],
    ['ZEAL', 'VEAL', 'DEAL'],
    ['FATE', 'FARE', 'HARE'],
    ['LODE', 'LONE', 'BONE'],
    ['ZONE', 'HONE', 'HOPE'],
    ['FEED', 'REED', 'HEED'],
    ['TOOK', 'LOOK', 'HOOK'],
    ['DARE', 'DAME', 'NAME'],
    ['NINE', 'VINE', 'LINE'],
    ['MORE', 'WORE', 'CORE'],
    ['PALE', 'SALE', 'TALE'],
    ['HIDE', 'TIDE', 'TIME'],
    ['SOCK', 'SICK', 'LICK'],
    ['MILK', 'MILD', 'MILE'],
    ['PLED', 'FLED', 'FLEA'],
    ['NICE', 'MICE', 'MIME'],
    ['LATE', 'HATE', 'DATE'],
    ['BITE', 'BIDE', 'SIDE'],
    ['HOOF', 'HOOT', 'HOOP'],
    ['SANG', 'GANG', 'PANG'],
    ['TEST', 'TENT', 'SENT'],
    ['YEAR', 'BEAR', 'BEAT'],
    ['MAKE', 'FAKE', 'TAKE'],
    ['TAME', 'LAME', 'LAMB'],
    ['BLUE', 'FLUE', 'CLUE'],
    ['CRAB', 'GRAB', 'GRUB'],
    ['SUNG', 'SUNK', 'DUNK'],
    ['BOLD', 'COLD', 'SOLD'],
    ['PEAR', 'GEAR', 'REAR'],
    ['MAIL', 'RAIL', 'WAIL'],
    ['MAZE', 'DAZE', 'GAZE'],
    ['CASE', 'CAVE', 'RAVE'],
    ['DUMP', 'HUMP', 'BUMP'],
    ['TOOT', 'FOOT', 'FOOD'],
    ['NOOK', 'ROOK', 'COOK'],
    ['RATE', 'RAKE', 'RACE'],
    ['MASK', 'TASK', 'TACK'],
    ['WART', 'WARY', 'WARE'],
    ['BUST', 'GUST', 'GUSH'],
    ['DUST', 'MUST', 'MOST'],
  ];

  /// Every ladder, so a test can walk each one letter at a time.
  static List<List<String>> get ladders => List.unmodifiable(_ladders);

  static WordLadderQuestion generateQuestion({math.Random? random}) {
    final rng = random ?? math.Random();
    final entry = _ladders[rng.nextInt(_ladders.length)];

    final start = entry[0];
    final mid = entry[1];
    final end = entry[2];

    // Distractors come from other ladders, and a three-letter middle in a
    // four-letter ladder is not a near miss: the length alone gives it away.
    // Same-length middles first, then anything, so a rung of the only
    // three-letter ladder still gets four buttons.
    final sameLength = _ladders
        .map((ladder) => ladder[1])
        .where((word) => word.length == mid.length && word != mid)
        .toSet()
        .toList()
      ..shuffle(rng);
    final distractorSet = <String>{mid, ...sameLength.take(3)};
    final others = _ladders.map((ladder) => ladder[1]).toSet().toList()
      ..shuffle(rng);
    for (final word in others) {
      if (distractorSet.length >= 4) break;
      distractorSet.add(word);
    }

    final choices = distractorSet.toList()..shuffle(rng);

    return WordLadderQuestion(
      startWord: start,
      endWord: end,
      correctMiddleWord: mid,
      choices: choices,
    );
  }
}
