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
