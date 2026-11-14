import 'dart:math';

class HomophonePuzzle {
  final String sentence;
  final String correctAnswer;
  final String wrongAnswer;
  final String fullSentence;

  HomophonePuzzle({
    required this.sentence,
    required this.correctAnswer,
    required this.wrongAnswer,
    required this.fullSentence,
  });
}

class HomophoneHuntEngine {
  final Random _random = Random();

  /// One sentence, one blank, two homophones that both fit the sound and only
  /// one of which fits the grammar. A run draws one, so the pool is the whole
  /// game: eleven sentences meant a repeat within eleven rounds.
  final List<Map<String, dynamic>> _data = [
    {
      'sentence': 'I hope the ____ is nice tomorrow.',
      'correct': 'weather',
      'wrong': 'whether',
      'full': 'I hope the weather is nice tomorrow.',
    },
    {
      'sentence': 'I don\'t know ____ I should go or stay.',
      'correct': 'whether',
      'wrong': 'weather',
      'full': 'I don\'t know whether I should go or stay.',
    },
    {
      'sentence': 'The dog wagged ____ tail.',
      'correct': 'its',
      'wrong': 'it\'s',
      'full': 'The dog wagged its tail.',
    },
    {
      'sentence': '____ a very beautiful day.',
      'correct': 'It\'s',
      'wrong': 'Its',
      'full': 'It\'s a very beautiful day.',
    },
    {
      'sentence': 'They left ____ bags in the car.',
      'correct': 'their',
      'wrong': 'there',
      'full': 'They left their bags in the car.',
    },
    {
      'sentence': 'Go over ____ and sit down.',
      'correct': 'there',
      'wrong': 'their',
      'full': 'Go over there and sit down.',
    },
    {
      'sentence': '____ going to the park later.',
      'correct': 'They\'re',
      'wrong': 'Their',
      'full': 'They\'re going to the park later.',
    },
    {
      'sentence': 'I need to ____ some new clothes.',
      'correct': 'buy',
      'wrong': 'by',
      'full': 'I need to buy some new clothes.',
    },
    {
      'sentence': 'He sat ____ the window.',
      'correct': 'by',
      'wrong': 'buy',
      'full': 'He sat by the window.',
    },
    {
      'sentence': 'I read the ____ book in one day.',
      'correct': 'whole',
      'wrong': 'hole',
      'full': 'I read the whole book in one day.',
    },
    {
      'sentence': 'There is a ____ in my sock.',
      'correct': 'hole',
      'wrong': 'whole',
      'full': 'There is a hole in my sock.',
    },
    {
      'sentence': 'Can you ____ the bell from here?',
      'correct': 'hear',
      'wrong': 'here',
      'full': 'Can you hear the bell from here?',
    },
    {
      'sentence': 'Please come over ____.',
      'correct': 'here',
      'wrong': 'hear',
      'full': 'Please come over here.',
    },
    {
      'sentence': 'I would like a ____ of cake.',
      'correct': 'piece',
      'wrong': 'peace',
      'full': 'I would like a piece of cake.',
    },
    {
      'sentence': 'The two countries are finally at ____.',
      'correct': 'peace',
      'wrong': 'piece',
      'full': 'The two countries are finally at peace.',
    },
    {
      'sentence': 'The sky was completely ____.',
      'correct': 'clear',
      'wrong': 'clerk',
      'full': 'The sky was completely clear.',
    },
    {
      'sentence': 'Please ____ your name on the line.',
      'correct': 'write',
      'wrong': 'right',
      'full': 'Please write your name on the line.',
    },
    {
      'sentence': 'Turn ____ at the corner.',
      'correct': 'right',
      'wrong': 'write',
      'full': 'Turn right at the corner.',
    },
    {
      'sentence': 'She wore a ____ dress to the party.',
      'correct': 'plain',
      'wrong': 'plane',
      'full': 'She wore a plain dress to the party.',
    },
    {
      'sentence': 'The ____ landed on time.',
      'correct': 'plane',
      'wrong': 'plain',
      'full': 'The plane landed on time.',
    },
    {
      'sentence': 'We need ____ eggs for the recipe.',
      'correct': 'two',
      'wrong': 'too',
      'full': 'We need two eggs for the recipe.',
    },
    {
      'sentence': 'It is ____ cold to swim.',
      'correct': 'too',
      'wrong': 'two',
      'full': 'It is too cold to swim.',
    },
    {
      'sentence': 'I want to go ____ the beach.',
      'correct': 'to',
      'wrong': 'too',
      'full': 'I want to go to the beach.',
    },
    {
      'sentence': 'The ____ is shining today.',
      'correct': 'sun',
      'wrong': 'son',
      'full': 'The sun is shining today.',
    },
    {
      'sentence': 'Their ____ is starting school.',
      'correct': 'son',
      'wrong': 'sun',
      'full': 'Their son is starting school.',
    },
    {
      'sentence': 'She ____ the ball across the field.',
      'correct': 'threw',
      'wrong': 'through',
      'full': 'She threw the ball across the field.',
    },
    {
      'sentence': 'We walked ____ the forest.',
      'correct': 'through',
      'wrong': 'threw',
      'full': 'We walked through the forest.',
    },
    {
      'sentence': 'The ____ of the story was sad.',
      'correct': 'end',
      'wrong': 'and',
      'full': 'The end of the story was sad.',
    },
    {
      'sentence': 'We waited for an hour ____ left.',
      'correct': 'then',
      'wrong': 'than',
      'full': 'We waited for an hour then left.',
    },
    {
      'sentence': 'He is taller ____ his brother.',
      'correct': 'than',
      'wrong': 'then',
      'full': 'He is taller than his brother.',
    },
    {
      'sentence': 'The wind ____ the door shut.',
      'correct': 'blew',
      'wrong': 'blue',
      'full': 'The wind blew the door shut.',
    },
    {
      'sentence': 'Her favourite colour is ____.',
      'correct': 'blue',
      'wrong': 'blew',
      'full': 'Her favourite colour is blue.',
    },
    {
      'sentence': 'I ____ the answer yesterday.',
      'correct': 'knew',
      'wrong': 'new',
      'full': 'I knew the answer yesterday.',
    },
    {
      'sentence': 'She bought a ____ coat.',
      'correct': 'new',
      'wrong': 'knew',
      'full': 'She bought a new coat.',
    },
    {
      'sentence': 'The ____ was full of people.',
      'correct': 'hall',
      'wrong': 'haul',
      'full': 'The hall was full of people.',
    },
    {
      'sentence': 'They had to ____ the boat ashore.',
      'correct': 'haul',
      'wrong': 'hall',
      'full': 'They had to haul the boat ashore.',
    },
    {
      'sentence': 'He caught a ____ in the river.',
      'correct': 'bass',
      'wrong': 'base',
      'full': 'He caught a bass in the river.',
    },
    {
      'sentence': 'The lamp has a heavy ____.',
      'correct': 'base',
      'wrong': 'bass',
      'full': 'The lamp has a heavy base.',
    },
    {
      'sentence': 'We ____ them at the station.',
      'correct': 'met',
      'wrong': 'mat',
      'full': 'We met them at the station.',
    },
    {
      'sentence': 'Wipe your feet on the ____.',
      'correct': 'mat',
      'wrong': 'met',
      'full': 'Wipe your feet on the mat.',
    },
  ];

  /// Every sentence, so a test can check that the blank is really blank, that
  /// the two answers sound alike and differ, and that the full sentence is the
  /// sentence with the right answer in it.
  List<Map<String, dynamic>> get data => List.unmodifiable(_data);

  HomophonePuzzle generatePuzzle() {
    final item = _data[_random.nextInt(_data.length)];
    return HomophonePuzzle(
      sentence: item['sentence'],
      correctAnswer: item['correct'],
      wrongAnswer: item['wrong'],
      fullSentence: item['full'],
    );
  }
}
