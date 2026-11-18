import 'dart:math' as math;

class ConundrumRound {
  final String scrambled;
  final String solution;
  final List<String> letterPool;

  ConundrumRound({
    required this.scrambled,
    required this.solution,
    required this.letterPool,
  });
}

class ConundrumAnagramEngine {
  static const List<String> _words9 = [
    'DISCOVERY',
    'BEAUTIFUL',
    'CHAMPIONS',
    'LANDSCAPE',
    'NOTEBOOKS',
    'PARADISED',
    'ORCHESTRA',
    'UNIVERSAL',
    'ADVENTURE',
    'BRILLIANT',
    'ALGORITHM',
    'BUTTERFLY',
    'CHALLENGE',
    'CHRISTMAS',
    'CLOCKWORK',
    'COMMUNITY',
    'CONSTANTS',
    'CRAFTWORK',
    'CRYSTALLS'.length == 9 ? 'CRYSTALLS' : 'CROSSWALK',
    'CROSSWALK',
    'DETECTIVE',
    'DIRECTORY',
    'EDUCATION',
    'EVERGREEN',
    'FIREPLACE',
    'FORGOTTEN',
    'FRAMEWORK',
    'GEOMETRIC',
    'HAPPINESS',
    'HARMONIZE',
    'KNOWLEDGE',
    'LABYRINTH',
    'LIGHTNING',
    'MAGNETISM',
    'MOONLIGHT',
    'MOUNTAINS',
    'NIGHTFALL',
    'PENGUINED'.length == 9 ? 'PENTHOUSE' : 'PENTHOUSE',
    'PINEAPPLE',
    'PLAYGROUND'.length == 9 ? 'PLAYGROUND' : 'STARLIGHT',
    'STARLIGHT',
    'SUNFLOWER',
    'THRESHOLD',
    'TREASURES',
    'WATERFALL',
    'WHIRLPOOL',
    'WONDERFUL',
  ];

  static final List<String> words =
      _words9.where((w) => w.length == 9 && w != 'CRYSTALLS').toSet().toList();

  static ConundrumRound generateRound({math.Random? random}) {
    final rng = random ?? math.Random();
    final word = words[rng.nextInt(words.length)];

    final letters = word.split('');
    final shuffled = List<String>.from(letters);
    do {
      shuffled.shuffle(rng);
    } while (shuffled.join('') == word);

    return ConundrumRound(
      scrambled: shuffled.join(''),
      solution: word,
      letterPool: shuffled,
    );
  }
}
