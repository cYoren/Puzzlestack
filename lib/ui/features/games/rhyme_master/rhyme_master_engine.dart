import 'dart:math';

class RhymeMasterEngine {
  final Random _random = Random();

  /// Each set is one rime: every rhyme has the same vowel-and-after as the
  /// target, not merely a similar spelling. `test/content/rhyme_master_test.dart`
  /// carries the phonetic transcription and fails on a near-rhyme, so a set
  /// cannot drift back into words that only look alike (`VIEW`, `NEW`, `FUEL`,
  /// `MULE` were glide onsets, not the same rime).
  final List<RhymeSet> _rhymeSets = const [
    RhymeSet(target: 'CAT', rhymes: ['BAT', 'HAT', 'MAT', 'RAT', 'SAT', 'FAT', 'PAT', 'VAT']),
    RhymeSet(target: 'LIGHT', rhymes: ['BRIGHT', 'FIGHT', 'NIGHT', 'SIGHT', 'TIGHT', 'MIGHT', 'RIGHT', 'WHITE']),
    RhymeSet(target: 'PLAY', rhymes: ['DAY', 'MAY', 'SAY', 'STAY', 'WAY', 'GRAY', 'PRAY', 'TRAY']),
    RhymeSet(target: 'BLUE', rhymes: ['DUE', 'GLUE', 'TRUE', 'TWO', 'ZOO', 'SHOE', 'TOO', 'CREW']),
    RhymeSet(target: 'SING', rhymes: ['BRING', 'KING', 'RING', 'WING', 'THING', 'SPRING', 'STRING', 'SWING']),
    RhymeSet(target: 'BOLD', rhymes: ['COLD', 'GOLD', 'HOLD', 'OLD', 'SOLD', 'TOLD', 'FOLD', 'MOLD']),
    RhymeSet(target: 'COOL', rhymes: ['POOL', 'RULE', 'SCHOOL', 'TOOL', 'FOOL', 'SPOOL', 'STOOL', 'DROOL']),
  ];

  /// The sets, for tests. The game only deals them.
  List<RhymeSet> get sets => List.unmodifiable(_rhymeSets);

  RhymeMasterPuzzle generatePuzzle() {
    final rhymeSet = _rhymeSets[_random.nextInt(_rhymeSets.length)];
    return RhymeMasterPuzzle(
      targetWord: rhymeSet.target,
      allRhymes: rhymeSet.rhymes,
    );
  }

  bool isRhyme(String targetWord, String word, List<String> allRhymes) {
    return allRhymes.contains(word.toUpperCase().trim());
  }
}

class RhymeSet {
  final String target;
  final List<String> rhymes;

  const RhymeSet({required this.target, required this.rhymes});
}

class RhymeMasterPuzzle {
  final String targetWord;
  final List<String> allRhymes;

  RhymeMasterPuzzle({
    required this.targetWord,
    required this.allRhymes,
  });
}
