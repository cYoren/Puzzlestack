import 'dart:math';

class LetterBridgeEngine {
  /// One letter joins the two halves: [first] + letter and letter + [second]
  /// are both words. Every entry is checked against the app's own dictionaries
  /// by `test/content/letter_bridge_test.dart`, so a row that cannot be solved
  /// fails the build instead of the player.
  static const List<Map<String, String>> _puzzles = [
    {'first': 'HEAR', 'second': 'ABLE', 'bridge': 'T'},
    {'first': 'STAR', 'second': 'RAIN', 'bridge': 'T'},
    {'first': 'PLAN', 'second': 'EASE', 'bridge': 'T'},
    {'first': 'WIN', 'second': 'EAR', 'bridge': 'D'},
    {'first': 'FOR', 'second': 'EST', 'bridge': 'T'},
    {'first': 'PAL', 'second': 'ALE', 'bridge': 'M'},
    {'first': 'WAR', 'second': 'ASH', 'bridge': 'M'},
    {'first': 'HER', 'second': 'OLD', 'bridge': 'B'},
    {'first': 'FAR', 'second': 'ARE', 'bridge': 'M'},
    {'first': 'CAR', 'second': 'ART', 'bridge': 'T'},
    {'first': 'SIN', 'second': 'ATE', 'bridge': 'G'},
    {'first': 'BOOK', 'second': 'LOW', 'bridge': 'S'},
    {'first': 'BACK', 'second': 'EAR', 'bridge': 'S'},
    {'first': 'TIME', 'second': 'AND', 'bridge': 'S'},
    {'first': 'RAIN', 'second': 'END', 'bridge': 'S'},
    {'first': 'FIRE', 'second': 'HOT', 'bridge': 'S'},
    {'first': 'BLUE', 'second': 'HIP', 'bridge': 'S'},
    {'first': 'BEE', 'second': 'LAP', 'bridge': 'F'},
    {'first': 'SUN', 'second': 'LASS', 'bridge': 'G'},
    {'first': 'BREAD', 'second': 'TICK', 'bridge': 'S'},
    {'first': 'COIN', 'second': 'TAR', 'bridge': 'S'},
    {'first': 'TEA', 'second': 'POON', 'bridge': 'S'},
    {'first': 'SEA', 'second': 'IDE', 'bridge': 'S'},
    {'first': 'ROCK', 'second': 'TAR', 'bridge': 'S'},
    {'first': 'POP', 'second': 'TAR', 'bridge': 'S'},
    {'first': 'DOOR', 'second': 'TEP', 'bridge': 'S'},
    {'first': 'SAND', 'second': 'TONE', 'bridge': 'S'},
    {'first': 'BAN', 'second': 'RUM', 'bridge': 'D'},
    {'first': 'BAN', 'second': 'ART', 'bridge': 'D'},
    {'first': 'BAN', 'second': 'ASH', 'bridge': 'D'},
    {'first': 'BAN', 'second': 'OWN', 'bridge': 'D'},
    {'first': 'BAN', 'second': 'RUG', 'bridge': 'D'},
    {'first': 'BAN', 'second': 'NEW', 'bridge': 'K'},
    {'first': 'BAN', 'second': 'NOT', 'bridge': 'K'},
    {'first': 'BAR', 'second': 'ILL', 'bridge': 'K'},
    {'first': 'BOA', 'second': 'OWN', 'bridge': 'T'},
    {'first': 'BOA', 'second': 'RIP', 'bridge': 'T'},
    {'first': 'BOA', 'second': 'RAY', 'bridge': 'T'},
    {'first': 'BOA', 'second': 'ONE', 'bridge': 'T'},
    {'first': 'BOA', 'second': 'ALE', 'bridge': 'T'},
    {'first': 'BOA', 'second': 'RAP', 'bridge': 'T'},
    {'first': 'BOA', 'second': 'WIG', 'bridge': 'T'},
    {'first': 'BOA', 'second': 'RIM', 'bridge': 'T'},
    {'first': 'BOW', 'second': 'AND', 'bridge': 'L'},
    {'first': 'BOW', 'second': 'ION', 'bridge': 'L'},
    {'first': 'BOW', 'second': 'ACE', 'bridge': 'L'},
    {'first': 'BOW', 'second': 'AMP', 'bridge': 'L'},
    {'first': 'BOW', 'second': 'IKE', 'bridge': 'L'},
    {'first': 'BOW', 'second': 'END', 'bridge': 'L'},
    {'first': 'BUS', 'second': 'EAR', 'bridge': 'H'},
    {'first': 'BUS', 'second': 'ILL', 'bridge': 'H'},
    {'first': 'BUS', 'second': 'OLD', 'bridge': 'H'},
    {'first': 'BUS', 'second': 'ALL', 'bridge': 'H'},
    {'first': 'BUS', 'second': 'AND', 'bridge': 'H'},
    {'first': 'BUS', 'second': 'ARM', 'bridge': 'H'},
    {'first': 'BUS', 'second': 'IRE', 'bridge': 'H'},
    {'first': 'CAR', 'second': 'RAW', 'bridge': 'D'},
    {'first': 'CAR', 'second': 'OWN', 'bridge': 'D'},
    {'first': 'CAR', 'second': 'ASH', 'bridge': 'D'},
    {'first': 'DIE', 'second': 'RIO', 'bridge': 'T'},
    {'first': 'DIE', 'second': 'ASK', 'bridge': 'T'},
    {'first': 'DIE', 'second': 'WIN', 'bridge': 'T'},
    {'first': 'DIE', 'second': 'APE', 'bridge': 'T'},
    {'first': 'DIE', 'second': 'AIL', 'bridge': 'T'},
    {'first': 'DIE', 'second': 'HUG', 'bridge': 'T'},
    {'first': 'DIE', 'second': 'HEM', 'bridge': 'T'},
    {'first': 'DIE', 'second': 'URN', 'bridge': 'T'},
  ];

  Map<String, String> getRandomPuzzle() {
    final random = Random();
    return _puzzles[random.nextInt(_puzzles.length)];
  }

  /// Every puzzle, in table order. Tests read this; the game never does.
  static List<Map<String, String>> get allPuzzles => _puzzles;

  bool isCorrect(String bridge, String userLetter) {
    return bridge.toUpperCase() == userLetter.toUpperCase();
  }
}
