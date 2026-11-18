import 'dart:math';

class WordMastermindEngine {
  static const int wordLength = 4;
  static const int maxTries = 10;

  final Random _random;

  WordMastermindEngine([Random? random]) : _random = random ?? Random();

  // Dedicated 4-letter English word dataset for Word Mastermind
  static const List<String> _words = [
    'BLUE', 'GOLD', 'DARK', 'MIND', 'CODE', 'PLAY', 'GAME', 'TIME', 'FAST', 'SLOW',
    'FIRE', 'WIND', 'SNOW', 'RAIN', 'STAR', 'MOON', 'DAWN', 'COOL', 'HEAT', 'ROCK',
    'TREE', 'LEAF', 'BIRD', 'FISH', 'SHIP', 'BOAT', 'ROAD', 'CITY', 'LAND', 'SAND',
    'WAVE', 'TIDE', 'PEAK', 'VALE', 'GLOW', 'LAMP', 'BELL', 'RING', 'SONG', 'NOTE',
    'BOOK', 'PAGE', 'INKY', 'DESK', 'PATH', 'GATE', 'WALL', 'ROOF', 'DOOR', 'ROOM',
    'KING', 'DUKE', 'FORT', 'CAST', 'COIN', 'GEMS', 'WORK', 'TASK', 'PLAN', 'IDEA',
    'FORM', 'LINE', 'EDGE', 'ARCH', 'DOME', 'CUBE', 'CONE', 'GEAR', 'BOLT', 'WIRE',
    'IRON', 'ZINC', 'SALT', 'MILK', 'PEAR', 'PLUM', 'LIME', 'CORN', 'RICE', 'OATS',
    'SOUP', 'CAKE', 'LOAF', 'FORK', 'BOWL', 'MUGS', 'VASE', 'SILK', 'WOOL', 'KNOT',
    'CAPE', 'COAT', 'BELT', 'SHOE', 'SOCK', 'GLAD', 'CALM', 'BOLD', 'WISE', 'KEEN',
    'PURE', 'WARM', 'DEEP', 'HIGH', 'WIDE', 'LONG', 'NEAR', 'OPEN', 'TRUE', 'SAFE',
    'JUMP', 'SWIM', 'DIVE', 'WALK', 'HIKE', 'RIDE', 'SAIL', 'SOAR', 'TURN', 'SPIN',
  ];

  List<String> get words => _words;

  String getRandomWord() {
    return _words[_random.nextInt(_words.length)].toUpperCase();
  }

  // Returns [bulls, cows]
  // Bulls: Correct letter, correct position
  // Cows: Correct letter, wrong position
  List<int> checkGuess(String guess, String target) {
    int bulls = 0;
    int cows = 0;

    List<String> targetList = target.toUpperCase().split('');
    List<String> guessList = guess.toUpperCase().split('');
    List<bool> targetUsed = List.filled(wordLength, false);
    List<bool> guessUsed = List.filled(wordLength, false);

    // First pass: Find Bulls
    for (int i = 0; i < wordLength; i++) {
      if (guessList[i] == targetList[i]) {
        bulls++;
        targetUsed[i] = true;
        guessUsed[i] = true;
      }
    }

    // Second pass: Find Cows
    for (int i = 0; i < wordLength; i++) {
      if (!guessUsed[i]) {
        for (int j = 0; j < wordLength; j++) {
          if (!targetUsed[j] && guessList[i] == targetList[j]) {
            cows++;
            targetUsed[j] = true;
            break;
          }
        }
      }
    }

    return [bulls, cows];
  }
}
