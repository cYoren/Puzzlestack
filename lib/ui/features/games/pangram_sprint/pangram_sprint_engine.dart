import 'dart:math';

class PangramSprintEngine {
  final List<PangramTask> _tasks = [
    PangramTask(
      sentence: 'The quick brown fox jumps over the lazy dog',
      words: ['THE', 'QUICK', 'BROWN', 'FOX', 'JUMPS', 'OVER', 'THE', 'LAZY', 'DOG'],
    ),
    PangramTask(
      sentence: 'Pack my box with five dozen liquor jugs',
      words: ['PACK', 'MY', 'BOX', 'WITH', 'FIVE', 'DOZEN', 'LIQUOR', 'JUGS'],
    ),
    PangramTask(
      sentence: 'Sphinx of black quartz judge my vow',
      words: ['SPHINX', 'OF', 'BLACK', 'QUARTZ', 'JUDGE', 'MY', 'VOW'],
    ),
    PangramTask(
      sentence: 'Glib jocks quiz nymph to vex dwarf',
      words: ['GLIB', 'JOCKS', 'QUIZ', 'NYMPH', 'TO', 'VEX', 'DWARF'],
    ),
    PangramTask(
      sentence: 'Two driven jocks help fax my big quiz',
      words: ['TWO', 'DRIVEN', 'JOCKS', 'HELP', 'FAX', 'MY', 'BIG', 'QUIZ'],
    ),
    PangramTask(
      sentence: 'How quickly daft jumping zebras vex',
      words: ['HOW', 'QUICKLY', 'DAFT', 'JUMPING', 'ZEBRAS', 'VEX'],
    ),
    PangramTask(
      sentence: 'Jackdaws love my big sphinx of quartz',
      words: ['JACKDAWS', 'LOVE', 'MY', 'BIG', 'SPHINX', 'OF', 'QUARTZ'],
    ),
    PangramTask(
      sentence: 'Waltz bad nymph for quick jigs vex',
      words: ['WALTZ', 'BAD', 'NYMPH', 'FOR', 'QUICK', 'JIGS', 'VEX'],
    ),
    PangramTask(
      sentence: 'Quick zephyrs blow vexing daft Jim',
      words: ['QUICK', 'ZEPHYRS', 'BLOW', 'VEXING', 'DAFT', 'JIM'],
    ),
    PangramTask(
      sentence: 'The five boxing wizards jump quickly',
      words: ['THE', 'FIVE', 'BOXING', 'WIZARDS', 'JUMP', 'QUICKLY'],
    ),
    PangramTask(
      sentence: 'Vamp fox held quartz duck just by wing',
      words: ['VAMP', 'FOX', 'HELD', 'QUARTZ', 'DUCK', 'JUST', 'BY', 'WING'],
    ),
    PangramTask(
      sentence: 'Bright vixens jump dozy fowl quack',
      words: ['BRIGHT', 'VIXENS', 'JUMP', 'DOZY', 'FOWL', 'QUACK'],
    ),
    PangramTask(
      sentence: 'Grumpy wizards make toxic brew for the evil queen and jack',
      words: ['GRUMPY', 'WIZARDS', 'MAKE', 'TOXIC', 'BREW', 'FOR', 'THE', 'EVIL', 'QUEEN', 'AND', 'JACK'],
    ),
    PangramTask(
      sentence: 'Fix problem quickly with galvanized jets',
      words: ['FIX', 'PROBLEM', 'QUICKLY', 'WITH', 'GALVANIZED', 'JETS'],
    ),
  ];

  /// Every task, so a test can check each board is winnable.
  List<PangramTask> get tasks => List.unmodifiable(_tasks);

  /// Deals a board. `isPangram` is the filter, not a comment: a board that
  /// cannot reach 26 letters is never dealt, because the win check is 26.
  PangramTask getRandomTask() {
    final playable = _tasks.where((task) => isPangram(task.sentence)).toList();
    return playable[Random().nextInt(playable.length)];
  }

  bool isPangram(String text) {
    final letters = text.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '').split('');
    return Set.from(letters).length == 26;
  }
}

class PangramTask {
  final String sentence;
  final List<String> words;

  PangramTask({
    required this.sentence,
    required this.words,
  });
}
