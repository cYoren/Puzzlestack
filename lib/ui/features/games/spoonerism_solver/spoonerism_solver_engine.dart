import 'dart:math';

class SpoonerismSolverEngine {
  /// A phrase and the spoonerism made by swapping the opening sounds of two of
  /// its words. The options are other originals from the same table, so the
  /// wrong answers cannot be the spoonerism already on screen -- the old table
  /// offered 'JELLY BEANS' as a wrong answer to 'JELLY BEANS'.
  final List<SpoonerismTask> _tasks = [
    SpoonerismTask(spoonerism: 'RUNNY BABBIT', original: 'BUNNY RABBIT'),
    SpoonerismTask(spoonerism: 'BLUSHING CROW', original: 'CRUSHING BLOW'),
    SpoonerismTask(spoonerism: 'HAGS FLUNG OUT', original: 'FLAGS HUNG OUT'),
    SpoonerismTask(spoonerism: 'SCOOP OF BOY TROUTS', original: 'TROOP OF BOY SCOUTS'),
    SpoonerismTask(spoonerism: 'CHIPPING THE FLANNEL', original: 'FLIPPING THE CHANNEL'),
    SpoonerismTask(spoonerism: 'BELLY JEANS', original: 'JELLY BEANS'),
    SpoonerismTask(spoonerism: 'FLOW SNAKE', original: 'SNOW FLAKE'),
    SpoonerismTask(spoonerism: 'BEEN GROWL', original: 'GREEN BOWL'),
    SpoonerismTask(spoonerism: 'LATER WEATHER', original: 'WATER LEATHER'),
    SpoonerismTask(spoonerism: 'ROAST TOAD', original: 'TOAST ROAD'),
    SpoonerismTask(spoonerism: 'POPPER CAPER', original: 'COPPER PAPER'),
    SpoonerismTask(spoonerism: 'CELT BOAT', original: 'BELT COAT'),
    SpoonerismTask(spoonerism: 'SMELLY BALL', original: 'BELLY SMALL'),
    SpoonerismTask(spoonerism: 'FORKS WIRE', original: 'WORKS FIRE'),
    SpoonerismTask(spoonerism: 'LOAD RIGHT', original: 'ROAD LIGHT'),
    SpoonerismTask(spoonerism: 'BELLY JAG', original: 'JELLY BAG'),
    SpoonerismTask(spoonerism: 'ROVING LOAD', original: 'LOVING ROAD'),
    SpoonerismTask(spoonerism: 'LEAN DEMON', original: 'DEAN LEMON'),
    SpoonerismTask(spoonerism: 'BASS GLEANS', original: 'GLASS BEANS'),
    SpoonerismTask(spoonerism: 'BOON SPELL', original: 'SPOON BELL'),
    SpoonerismTask(spoonerism: 'BAGS FLUTTER', original: 'FLAGS BUTTER'),
    SpoonerismTask(spoonerism: 'BAILS SELL', original: 'SAILS BELL'),
    SpoonerismTask(spoonerism: 'CHEWS NIPPING', original: 'NEWS CHIPPING'),
    SpoonerismTask(spoonerism: 'HIPPING FLUNG', original: 'FLIPPING HUNG'),
  ];

  /// Every task, so a test can swap the sounds back and check the answer.
  List<SpoonerismTask> get tasks => List.unmodifiable(_tasks);

  SpoonerismTask getRandomTask() {
    return _tasks[Random().nextInt(_tasks.length)];
  }

  /// The answer plus two other originals, shuffled.
  List<String> getOptions(SpoonerismTask task, {Random? random}) {
    final rng = random ?? Random();
    final others = _tasks
        .where((other) => other.original != task.original)
        .map((other) => other.original)
        .toSet()
        .toList()
      ..shuffle(rng);
    return [task.original, ...others.take(2)]..shuffle(rng);
  }

  bool checkAnswer(String selected, String correct) {
    return selected == correct;
  }
}

class SpoonerismTask {
  final String spoonerism;
  final String original;

  SpoonerismTask({required this.spoonerism, required this.original});
}
