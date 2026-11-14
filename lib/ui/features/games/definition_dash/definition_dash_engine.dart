import 'dart:math';

class DefinitionDashEngine {
  final Random _random = Random();

  /// Each pair is one question: the definition is the prompt and the word is
  /// the answer. The other pairs supply the distractors, so the pool is also the
  /// distractor supply -- ten pairs meant the wrong answers repeated too.
  final List<DefinitionPair> _pairs = [
    DefinitionPair(word: 'EPHEMERAL', definition: 'Lasting for a very short time.'),
    DefinitionPair(word: 'ELOQUENT', definition: 'Fluent or persuasive in speaking or writing.'),
    DefinitionPair(word: 'LUCID', definition: 'Expressed clearly; easy to understand.'),
    DefinitionPair(word: 'METICULOUS', definition: 'Showing great attention to detail; very careful and precise.'),
    DefinitionPair(word: 'PRAGMATIC', definition: 'Dealing with things sensibly and realistically.'),
    DefinitionPair(word: 'RESILIENT', definition: 'Able to withstand or recover quickly from difficult conditions.'),
    DefinitionPair(word: 'UBIQUITOUS', definition: 'Present, appearing, or found everywhere.'),
    DefinitionPair(word: 'BENEVOLENT', definition: 'Well meaning and kindly.'),
    DefinitionPair(word: 'CANDID', definition: 'Truthful and straightforward; frank.'),
    DefinitionPair(word: 'DILIGENT', definition: 'Having or showing care and conscientiousness in work.'),
    DefinitionPair(word: 'TENACIOUS', definition: 'Holding firmly to something; persistent.'),
    DefinitionPair(word: 'AMBIGUOUS', definition: 'Open to more than one interpretation; unclear.'),
    DefinitionPair(word: 'CONCISE', definition: 'Giving a lot of information clearly in few words.'),
    DefinitionPair(word: 'FRUGAL', definition: 'Sparing or economical with money or food.'),
    DefinitionPair(word: 'GREGARIOUS', definition: 'Fond of company; sociable.'),
    DefinitionPair(word: 'INEVITABLE', definition: 'Certain to happen; unavoidable.'),
    DefinitionPair(word: 'JUBILANT', definition: 'Feeling or expressing great happiness and triumph.'),
    DefinitionPair(word: 'LETHARGIC', definition: 'Affected by a lack of energy; sluggish and apathetic.'),
    DefinitionPair(word: 'NONCHALANT', definition: 'Calm and relaxed; not displaying anxiety or interest.'),
    DefinitionPair(word: 'OBSOLETE', definition: 'No longer produced or used; out of date.'),
    DefinitionPair(word: 'PLACID', definition: 'Calm and peaceful, with little movement or activity.'),
    DefinitionPair(word: 'QUIXOTIC', definition: 'Exceedingly idealistic; unrealistic and impractical.'),
    DefinitionPair(word: 'RELUCTANT', definition: 'Unwilling and hesitant.'),
    DefinitionPair(word: 'SCRUPULOUS', definition: 'Diligent and thorough in attending to what is right.'),
    DefinitionPair(word: 'TANGIBLE', definition: 'Perceptible by touch; clear and definite.'),
    DefinitionPair(word: 'VIVACIOUS', definition: 'Attractively lively and animated.'),
    DefinitionPair(word: 'WARY', definition: 'Feeling or showing caution about possible dangers.'),
    DefinitionPair(word: 'ZEALOUS', definition: 'Having or showing great energy in pursuit of a cause.'),
    DefinitionPair(word: 'AUSTERE', definition: 'Severe or strict in manner or attitude; plain.'),
    DefinitionPair(word: 'BANAL', definition: 'So lacking in originality as to be obvious and boring.'),
    DefinitionPair(word: 'DEFT', definition: 'Neatly skilful and quick in movement.'),
    DefinitionPair(word: 'EARNEST', definition: 'Showing sincere and intense conviction.'),
    DefinitionPair(word: 'FEEBLE', definition: 'Lacking physical strength or effectiveness.'),
    DefinitionPair(word: 'GENIAL', definition: 'Friendly and cheerful.'),
    DefinitionPair(word: 'HASTY', definition: 'Done or acting with excessive speed or urgency.'),
    DefinitionPair(word: 'IDLE', definition: 'Not active or in use; avoiding work.'),
    DefinitionPair(word: 'JADED', definition: 'Tired or lacking enthusiasm after too much of something.'),
    DefinitionPair(word: 'LAVISH', definition: 'Sumptuously rich, elaborate, or luxurious.'),
    DefinitionPair(word: 'MUNDANE', definition: 'Lacking interest or excitement; ordinary.'),
    DefinitionPair(word: 'NOVEL', definition: 'New and original rather than derived from something else.'),
    DefinitionPair(word: 'OPULENT', definition: 'Ostentatiously rich and luxurious.'),
    DefinitionPair(word: 'PENSIVE', definition: 'Engaged in deep or serious thought.'),
    DefinitionPair(word: 'RIGOROUS', definition: 'Extremely thorough, exhaustive, or accurate.'),
    DefinitionPair(word: 'SOLEMN', definition: 'Formal and dignified; not cheerful.'),
    DefinitionPair(word: 'TRIVIAL', definition: 'Of little value or importance.'),
    DefinitionPair(word: 'VAGUE', definition: 'Of uncertain or indefinite character; not clearly expressed.'),
    DefinitionPair(word: 'WITTY', definition: 'Showing quick and inventive humour.'),
    DefinitionPair(word: 'YIELDING', definition: 'Giving way under pressure; compliant.'),
  ];

  /// Every pair, so a test can hold the pool to the rules the screen promises:
  /// one definition per word, and four distinct options per puzzle.
  List<DefinitionPair> get pairs => List.unmodifiable(_pairs);

  DefinitionDashPuzzle generatePuzzle() {
    final correctPair = _pairs[_random.nextInt(_pairs.length)];
    
    // Get 3 other random definitions
    final otherDefinitions = _pairs
        .where((p) => p.word != correctPair.word)
        .map((p) => p.definition)
        .toList()
      ..shuffle(_random);
    
    final options = [correctPair.definition, ...otherDefinitions.take(3)].toList()
      ..shuffle(_random);

    return DefinitionDashPuzzle(
      word: correctPair.word,
      correctDefinition: correctPair.definition,
      options: options,
    );
  }
}

class DefinitionPair {
  final String word;
  final String definition;

  DefinitionPair({required this.word, required this.definition});
}

class DefinitionDashPuzzle {
  final String word;
  final String correctDefinition;
  final List<String> options;

  DefinitionDashPuzzle({
    required this.word,
    required this.correctDefinition,
    required this.options,
  });
}
