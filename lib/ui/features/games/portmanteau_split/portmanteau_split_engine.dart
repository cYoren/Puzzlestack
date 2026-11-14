import 'dart:math';

class PortmanteauSplitEngine {
  final Random _random = Random();

  /// One blend and the two words it was made from. A run draws one puzzle, so
  /// fourteen blends was fourteen rounds and then the same fourteen again.
  final List<PortmanteauPuzzle> _puzzles = [
    PortmanteauPuzzle(portmanteau: 'BRUNCH', word1: 'BREAKFAST', word2: 'LUNCH'),
    PortmanteauPuzzle(portmanteau: 'SMOG', word1: 'SMOKE', word2: 'FOG'),
    PortmanteauPuzzle(portmanteau: 'MOTEL', word1: 'MOTOR', word2: 'HOTEL'),
    PortmanteauPuzzle(portmanteau: 'SPORK', word1: 'SPOON', word2: 'FORK'),
    PortmanteauPuzzle(portmanteau: 'CHILLAX', word1: 'CHILL', word2: 'RELAX'),
    PortmanteauPuzzle(portmanteau: 'GLAMPING', word1: 'GLAMOROUS', word2: 'CAMPING'),
    PortmanteauPuzzle(portmanteau: 'BROMANCE', word1: 'BROTHER', word2: 'ROMANCE'),
    PortmanteauPuzzle(portmanteau: 'FREEMIUM', word1: 'FREE', word2: 'PREMIUM'),
    PortmanteauPuzzle(portmanteau: 'PODCAST', word1: 'IPOD', word2: 'BROADCAST'),
    PortmanteauPuzzle(portmanteau: 'LABRADOODLE', word1: 'LABRADOR', word2: 'POODLE'),
    PortmanteauPuzzle(portmanteau: 'MOCKTAIL', word1: 'MOCK', word2: 'COCKTAIL'),
    PortmanteauPuzzle(portmanteau: 'EMOTICON', word1: 'EMOTION', word2: 'ICON'),
    PortmanteauPuzzle(portmanteau: 'STAGFLATION', word1: 'STAGNATION', word2: 'INFLATION'),
    PortmanteauPuzzle(portmanteau: 'BIONIC', word1: 'BIOLOGY', word2: 'ELECTRONIC'),
    PortmanteauPuzzle(portmanteau: 'WEBINAR', word1: 'WEB', word2: 'SEMINAR'),
    PortmanteauPuzzle(portmanteau: 'CYBORG', word1: 'CYBERNETIC', word2: 'ORGANISM'),
    PortmanteauPuzzle(portmanteau: 'GUESTIMATE', word1: 'GUESS', word2: 'ESTIMATE'),
    PortmanteauPuzzle(portmanteau: 'INFOMERCIAL', word1: 'INFORMATION', word2: 'COMMERCIAL'),
    PortmanteauPuzzle(portmanteau: 'NETIZEN', word1: 'INTERNET', word2: 'CITIZEN'),
    PortmanteauPuzzle(portmanteau: 'MODEM', word1: 'MODULATOR', word2: 'DEMODULATOR'),
    PortmanteauPuzzle(portmanteau: 'CAMCORDER', word1: 'CAMERA', word2: 'RECORDER'),
    PortmanteauPuzzle(portmanteau: 'FROYO', word1: 'FROZEN', word2: 'YOGURT'),
    PortmanteauPuzzle(portmanteau: 'TANGELO', word1: 'TANGERINE', word2: 'POMELO'),
    PortmanteauPuzzle(portmanteau: 'PLUOT', word1: 'PLUM', word2: 'APRICOT'),
    PortmanteauPuzzle(portmanteau: 'GLITTERATI', word1: 'GLITTER', word2: 'LITERATI'),
    PortmanteauPuzzle(portmanteau: 'BLOGGER', word1: 'BLOG', word2: 'LOGGER'),
    PortmanteauPuzzle(portmanteau: 'COSPLAY', word1: 'COSTUME', word2: 'PLAY'),
    PortmanteauPuzzle(portmanteau: 'FANFIC', word1: 'FAN', word2: 'FICTION'),
    PortmanteauPuzzle(portmanteau: 'ROMCOM', word1: 'ROMANTIC', word2: 'COMEDY'),
    PortmanteauPuzzle(portmanteau: 'DRAMEDY', word1: 'DRAMA', word2: 'COMEDY'),
    PortmanteauPuzzle(portmanteau: 'DOCUDRAMA', word1: 'DOCUMENTARY', word2: 'DRAMA'),
    PortmanteauPuzzle(portmanteau: 'SITCOM', word1: 'SITUATION', word2: 'COMEDY'),
    PortmanteauPuzzle(portmanteau: 'CHUNNEL', word1: 'CHANNEL', word2: 'TUNNEL'),
    PortmanteauPuzzle(portmanteau: 'OXBRIDGE', word1: 'OXFORD', word2: 'CAMBRIDGE'),
    PortmanteauPuzzle(portmanteau: 'INTERCOM', word1: 'INTERNAL', word2: 'COMMUNICATION'),
    PortmanteauPuzzle(portmanteau: 'ELECTROCUTION', word1: 'ELECTRIC', word2: 'EXECUTION'),
    PortmanteauPuzzle(portmanteau: 'SCREENAGER', word1: 'SCREEN', word2: 'TEENAGER'),
    PortmanteauPuzzle(portmanteau: 'ADVERTORIAL', word1: 'ADVERTISEMENT', word2: 'EDITORIAL'),
    PortmanteauPuzzle(portmanteau: 'WORKAHOLIC', word1: 'WORK', word2: 'ALCOHOLIC'),
    PortmanteauPuzzle(portmanteau: 'SHOPAHOLIC', word1: 'SHOP', word2: 'ALCOHOLIC'),
    PortmanteauPuzzle(portmanteau: 'FRENEMY', word1: 'FRIEND', word2: 'ENEMY'),
    PortmanteauPuzzle(portmanteau: 'STAYCATION', word1: 'STAY', word2: 'VACATION'),
    PortmanteauPuzzle(portmanteau: 'DAYCATION', word1: 'DAY', word2: 'VACATION'),
    PortmanteauPuzzle(portmanteau: 'FLEXITARIAN', word1: 'FLEXIBLE', word2: 'VEGETARIAN'),
    PortmanteauPuzzle(portmanteau: 'LOCAVORE', word1: 'LOCAL', word2: 'CARNIVORE'),
    PortmanteauPuzzle(portmanteau: 'FREEGAN', word1: 'FREE', word2: 'VEGAN'),
  ];

  /// Every puzzle, so a test can check that each blend really does come from
  /// its two sources rather than from a third word nobody listed.
  List<PortmanteauPuzzle> get puzzles => List.unmodifiable(_puzzles);

  PortmanteauPuzzle generatePuzzle() {
    final puzzle = _puzzles[_random.nextInt(_puzzles.length)];
    
    // Generate distractors
    final distractors = <String>{};
    while (distractors.length < 4) {
      final p = _puzzles[_random.nextInt(_puzzles.length)];
      if (p.word1 != puzzle.word1 && p.word1 != puzzle.word2) distractors.add(p.word1);
      if (p.word2 != puzzle.word1 && p.word2 != puzzle.word2) distractors.add(p.word2);
    }
    
    final options = [puzzle.word1, puzzle.word2, ...distractors.take(4)];
    options.shuffle(_random);
    
    return PortmanteauPuzzle(
      portmanteau: puzzle.portmanteau,
      word1: puzzle.word1,
      word2: puzzle.word2,
      options: options,
    );
  }
}

class PortmanteauPuzzle {
  final String portmanteau;
  final String word1;
  final String word2;
  final List<String> options;

  PortmanteauPuzzle({
    required this.portmanteau,
    required this.word1,
    required this.word2,
    this.options = const [],
  });
}
