import 'dart:math';

class CompoundConnectEngine {
  /// Prefix and suffix that make one word. A run draws one task, and the other
  /// tasks supply the wrong buttons, so the pool is both the questions and the
  /// distractors: fifteen tasks meant the same wrong buttons every round.
  final List<CompoundTask> _tasks = [
    CompoundTask(prefix: 'SUN', suffix: 'FLOWER', result: 'SUNFLOWER'),
    CompoundTask(prefix: 'BACK', suffix: 'PACK', result: 'BACKPACK'),
    CompoundTask(prefix: 'FIRE', suffix: 'FLY', result: 'FIREFLY'),
    CompoundTask(prefix: 'WATER', suffix: 'FALL', result: 'WATERFALL'),
    CompoundTask(prefix: 'RAIN', suffix: 'BOW', result: 'RAINBOW'),
    CompoundTask(prefix: 'KEY', suffix: 'BOARD', result: 'KEYBOARD'),
    CompoundTask(prefix: 'DRAGON', suffix: 'FLY', result: 'DRAGONFLY'),
    CompoundTask(prefix: 'NOTE', suffix: 'BOOK', result: 'NOTEBOOK'),
    CompoundTask(prefix: 'TOOTH', suffix: 'BRUSH', result: 'TOOTHBRUSH'),
    CompoundTask(prefix: 'STAR', suffix: 'FISH', result: 'STARFISH'),
    CompoundTask(prefix: 'EAR', suffix: 'RING', result: 'EARRING'),
    CompoundTask(prefix: 'PAN', suffix: 'CAKE', result: 'PANCAKE'),
    CompoundTask(prefix: 'BASKET', suffix: 'BALL', result: 'BASKETBALL'),
    CompoundTask(prefix: 'SNOW', suffix: 'MAN', result: 'SNOWMAN'),
    CompoundTask(prefix: 'HAND', suffix: 'SHAKE', result: 'HANDSHAKE'),
        CompoundTask(prefix: 'MOON', suffix: 'LIGHT', result: 'MOONLIGHT'),
    CompoundTask(prefix: 'BOOK', suffix: 'SHELF', result: 'BOOKSHELF'),
            CompoundTask(prefix: 'CUP', suffix: 'CAKE', result: 'CUPCAKE'),
    CompoundTask(prefix: 'GRAND', suffix: 'MOTHER', result: 'GRANDMOTHER'),
    CompoundTask(prefix: 'FOOT', suffix: 'BALL', result: 'FOOTBALL'),
    CompoundTask(prefix: 'BED', suffix: 'ROOM', result: 'BEDROOM'),
    CompoundTask(prefix: 'CLASS', suffix: 'ROOM', result: 'CLASSROOM'),
    CompoundTask(prefix: 'AIR', suffix: 'PORT', result: 'AIRPORT'),
        CompoundTask(prefix: 'TEA', suffix: 'SPOON', result: 'TEASPOON'),
    CompoundTask(prefix: 'HAIR', suffix: 'CUT', result: 'HAIRCUT'),
    CompoundTask(prefix: 'EYE', suffix: 'BROW', result: 'EYEBROW'),
    CompoundTask(prefix: 'SAND', suffix: 'PAPER', result: 'SANDPAPER'),
    CompoundTask(prefix: 'GOLD', suffix: 'FISH', result: 'GOLDFISH'),
    CompoundTask(prefix: 'LIGHT', suffix: 'HOUSE', result: 'LIGHTHOUSE'),
    CompoundTask(prefix: 'OVER', suffix: 'COAT', result: 'OVERCOAT'),
    CompoundTask(prefix: 'UNDER', suffix: 'WEAR', result: 'UNDERWEAR'),
    CompoundTask(prefix: 'PLAY', suffix: 'GROUND', result: 'PLAYGROUND'),
    CompoundTask(prefix: 'BREAK', suffix: 'FAST', result: 'BREAKFAST'),
    CompoundTask(prefix: 'BIRTH', suffix: 'DAY', result: 'BIRTHDAY'),
    CompoundTask(prefix: 'POST', suffix: 'CARD', result: 'POSTCARD'),
    CompoundTask(prefix: 'WIND', suffix: 'MILL', result: 'WINDMILL'),
        CompoundTask(prefix: 'BUTTER', suffix: 'FLY', result: 'BUTTERFLY'),
    CompoundTask(prefix: 'STRAW', suffix: 'BERRY', result: 'STRAWBERRY'),
    CompoundTask(prefix: 'THUNDER', suffix: 'STORM', result: 'THUNDERSTORM'),
        CompoundTask(prefix: 'PINE', suffix: 'APPLE', result: 'PINEAPPLE'),
    CompoundTask(prefix: 'RATTLE', suffix: 'SNAKE', result: 'RATTLESNAKE'),
        CompoundTask(prefix: 'BATH', suffix: 'ROOM', result: 'BATHROOM'),
    CompoundTask(prefix: 'TIME', suffix: 'TABLE', result: 'TIMETABLE'),
    CompoundTask(prefix: 'NEWS', suffix: 'PAPER', result: 'NEWSPAPER'),
    CompoundTask(prefix: 'FINGER', suffix: 'PRINT', result: 'FINGERPRINT'),
    CompoundTask(prefix: 'HONEY', suffix: 'COMB', result: 'HONEYCOMB'),
    CompoundTask(prefix: 'CAVE', suffix: 'MAN', result: 'CAVEMAN'),
    CompoundTask(prefix: 'FLASH', suffix: 'LIGHT', result: 'FLASHLIGHT'),
    CompoundTask(prefix: 'SEA', suffix: 'HORSE', result: 'SEAHORSE'),
    CompoundTask(prefix: 'WORK', suffix: 'SHOP', result: 'WORKSHOP'),
    CompoundTask(prefix: 'COW', suffix: 'BOY', result: 'COWBOY'),
    CompoundTask(prefix: 'BULL', suffix: 'DOG', result: 'BULLDOG'),
    CompoundTask(prefix: 'SIDE', suffix: 'WALK', result: 'SIDEWALK'),
  ];

  /// Every task, so a test can hold the pool to what the screen promises: the
  /// two halves really do make the result, and one prefix never has two answers.
  List<CompoundTask> get tasks => List.unmodifiable(_tasks);

  CompoundTask getRandomTask() {
    return _tasks[Random().nextInt(_tasks.length)];
  }

  List<String> getOptions(CompoundTask task) {
    final options = [task.suffix];
    // A suffix can belong to more than one task, so the raw list can hold the
    // same distractor twice and the player sees a duplicate button. Dedupe
    // before taking three.
    final otherSuffixes = _tasks
        .where((t) => t.suffix != task.suffix)
        .map((t) => t.suffix)
        .toSet()
        .toList()
      ..shuffle();
    options.addAll(otherSuffixes.take(3));
    options.shuffle();
    return options;
  }

  bool checkAnswer(String selected, String correct) {
    return selected == correct;
  }
}

class CompoundTask {
  final String prefix;
  final String suffix;
  final String result;

  CompoundTask({
    required this.prefix,
    required this.suffix,
    required this.result,
  });
}
