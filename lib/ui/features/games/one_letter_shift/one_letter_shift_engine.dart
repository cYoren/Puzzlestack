import 'dart:math';

class OneLetterShiftEngine {
  /// One letter changes; nothing else moves. The subtitle promises exactly this
  /// ("transform one word into another with one letter change") and 24 of the
  /// 26 rows that shipped were anagrams instead, so a player who followed the
  /// rule was told they were wrong. `test/content/one_letter_shift_test.dart`
  /// holds every row to one differing position.
  static const List<Map<String, String>> _puzzles = [
    {'start': 'BEARD', 'end': 'BOARD', 'hint': 'A flat plank, or a committee'},
    {'start': 'BIRCH', 'end': 'BIRTH', 'hint': 'The moment of being born'},
    {'start': 'BLOCK', 'end': 'CLOCK', 'hint': 'It tells the time'},
    {'start': 'BLOOD', 'end': 'FLOOD', 'hint': 'A river overflowing'},
    {'start': 'BRAIN', 'end': 'TRAIN', 'hint': 'It runs on rails'},
    {'start': 'BRICK', 'end': 'TRICK', 'hint': 'A deceptive act'},
    {'start': 'BROWN', 'end': 'CROWN', 'hint': 'Worn by a king'},
    {'start': 'BRUSH', 'end': 'CRUSH', 'hint': 'To press flat'},
    {'start': 'CABLE', 'end': 'TABLE', 'hint': 'The furniture you eat at'},
    {'start': 'COACH', 'end': 'COUCH', 'hint': 'The sofa'},
    {'start': 'COAST', 'end': 'TOAST', 'hint': 'Bread browned by heat'},
    {'start': 'DAILY', 'end': 'DAISY', 'hint': 'A small white flower'},
    {'start': 'DRESS', 'end': 'PRESS', 'hint': 'Newspapers, or to push'},
    {'start': 'FLAME', 'end': 'FLARE', 'hint': 'A bright burst of light'},
    {'start': 'FLAME', 'end': 'FRAME', 'hint': 'It holds a picture'},
    {'start': 'FORCE', 'end': 'FORGE', 'hint': 'A blacksmith\'s shop'},
    {'start': 'FRONT', 'end': 'FROST', 'hint': 'Ice on a cold morning'},
    {'start': 'GLASS', 'end': 'GRASS', 'hint': 'The green ground cover'},
    {'start': 'GRACE', 'end': 'GRAPE', 'hint': 'A small round fruit'},
    {'start': 'GRAPE', 'end': 'GRAPH', 'hint': 'A chart of values'},
    {'start': 'GREEN', 'end': 'GREET', 'hint': 'To welcome someone'},
    {'start': 'HONEY', 'end': 'MONEY', 'hint': 'What you pay with'},
    {'start': 'LIGHT', 'end': 'NIGHT', 'hint': 'The dark half of the day'},
    {'start': 'LIGHT', 'end': 'SIGHT', 'hint': 'The sense of seeing'},
    {'start': 'MARCH', 'end': 'MATCH', 'hint': 'It starts a fire'},
    {'start': 'MONTH', 'end': 'MOUTH', 'hint': 'Where you speak from'},
    {'start': 'NORTH', 'end': 'WORTH', 'hint': 'Its value'},
    {'start': 'PAINT', 'end': 'POINT', 'hint': 'A dot, or the aim'},
    {'start': 'PEACE', 'end': 'PLACE', 'hint': 'A location'},
    {'start': 'PLACE', 'end': 'PLANE', 'hint': 'It flies'},
    {'start': 'PRICE', 'end': 'PRIDE', 'hint': 'Too much self-respect'},
    {'start': 'PRICE', 'end': 'PRIZE', 'hint': 'What a winner gets'},
    {'start': 'RADIO', 'end': 'RATIO', 'hint': 'One number over another'},
    {'start': 'SCORE', 'end': 'SHORE', 'hint': 'Where land meets the sea'},
    {'start': 'SCORE', 'end': 'STORE', 'hint': 'A shop'},
    {'start': 'SHAPE', 'end': 'SHARE', 'hint': 'A portion for each'},
    {'start': 'SHEEP', 'end': 'SHEET', 'hint': 'A bed covering'},
    {'start': 'SHEEP', 'end': 'SLEEP', 'hint': 'What you do at night'},
    {'start': 'SHIFT', 'end': 'SHIRT', 'hint': 'Clothing with a collar'},
    {'start': 'SHIRT', 'end': 'SHORT', 'hint': 'Not long'},
    {'start': 'SKILL', 'end': 'STILL', 'hint': 'Not moving'},
    {'start': 'SLICE', 'end': 'SLIDE', 'hint': 'A playground chute'},
    {'start': 'STAGE', 'end': 'STATE', 'hint': 'A country'},
    {'start': 'STORM', 'end': 'STORY', 'hint': 'A tale'},
    {'start': 'THANK', 'end': 'THINK', 'hint': 'To use your mind'},
    {'start': 'TRACK', 'end': 'TRUCK', 'hint': 'A large vehicle'},
    {'start': 'WHILE', 'end': 'WHITE', 'hint': 'The colour of snow'},
    {'start': 'WHITE', 'end': 'WRITE', 'hint': 'To put words on paper'},
    {'start': 'PLACE', 'end': 'PLATE', 'hint': 'You eat from it'},
    {'start': 'PLANE', 'end': 'PLANT', 'hint': 'It grows in soil'},
  ];

  /// Every puzzle, so a test can check the rule rather than a sample.
  static List<Map<String, String>> get allPuzzles => _puzzles;

  Map<String, String> getRandomPuzzle() {
    final random = Random();
    return _puzzles[random.nextInt(_puzzles.length)];
  }

  bool isCorrect(String endWord, String userWord) {
    return endWord.toUpperCase() == userWord.toUpperCase();
  }
}
