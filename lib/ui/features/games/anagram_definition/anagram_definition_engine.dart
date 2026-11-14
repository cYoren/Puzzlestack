import 'dart:math';

class AnagramDefinitionEngine {
  /// Anagrams with the definition of the *answer*, so the scramble and the clue
  /// have to agree. A run draws one, so the pool is what stands between a
  /// player and the same eight puzzles forever.
  final List<AnagramTask> _tasks = [
    AnagramTask(scrambled: 'DEALER', target: 'LEADER', definition: 'A person who commands a group, organization, or country.'),
    AnagramTask(scrambled: 'DORMITORY', target: 'DIRTY ROOM', definition: 'A place where many people sleep (a famous anagram).'),
    AnagramTask(scrambled: 'LISTEN', target: 'SILENT', definition: 'Making no utterance or sound.'),
    AnagramTask(scrambled: 'ELBOW', target: 'BELOW', definition: 'At a lower level or layer than something.'),
    AnagramTask(scrambled: 'NIGHT', target: 'THING', definition: 'An object that one need not or cannot name specifically.'),
    AnagramTask(scrambled: 'STATE', target: 'TASTE', definition: 'The sensation of flavour perceived in the mouth.'),
    AnagramTask(scrambled: 'ARC', target: 'CAR', definition: 'A road vehicle, typically with four wheels.'),
    AnagramTask(scrambled: 'BRAG', target: 'GRAB', definition: 'Seize suddenly and roughly.'),
    AnagramTask(scrambled: 'SAVE', target: 'VASE', definition: 'A decorative container, typically of glass or china.'),
    AnagramTask(scrambled: 'MELON', target: 'LEMON', definition: 'A yellow citrus fruit with a sour taste.'),
    AnagramTask(scrambled: 'EVIL', target: 'VILE', definition: 'Morally reprehensible; extremely unpleasant.'),
    AnagramTask(scrambled: 'NOTE', target: 'TONE', definition: 'A musical or vocal sound regarded for its pitch and quality.'),
    AnagramTask(scrambled: 'MEAT', target: 'TEAM', definition: 'A group of people playing or working together on one side.'),
    AnagramTask(scrambled: 'EARTH', target: 'HEART', definition: 'The organ that pumps blood around the body.'),
    AnagramTask(scrambled: 'SALE', target: 'SEAL', definition: 'A device used to close something so that nothing can escape.'),
    AnagramTask(scrambled: 'TIDE', target: 'DIET', definition: 'The kinds of food that a person habitually eats.'),
    AnagramTask(scrambled: 'LAMP', target: 'PALM', definition: 'The inner surface of the hand between the wrist and the fingers.'),
    AnagramTask(scrambled: 'RESIN', target: 'RINSE', definition: 'Wash something with clean water to remove soap or dirt.'),
    AnagramTask(scrambled: 'ALERT', target: 'LATER', definition: 'At a time in the future; after the expected time.'),
    AnagramTask(scrambled: 'EAST', target: 'SEAT', definition: 'A thing made or used for sitting on.'),
    AnagramTask(scrambled: 'STONE', target: 'ONSET', definition: 'The beginning of something, especially something unpleasant.'),
    AnagramTask(scrambled: 'CHEAP', target: 'PEACH', definition: 'A round stone fruit with juicy yellow flesh and downy skin.'),
    AnagramTask(scrambled: 'ANGEL', target: 'ANGLE', definition: 'The space between two intersecting lines where they meet.'),
    AnagramTask(scrambled: 'TIMES', target: 'ITEMS', definition: 'Individual articles or units in a list or collection.'),
    AnagramTask(scrambled: 'TRAIL', target: 'TRIAL', definition: 'A formal examination of evidence in a court of law.'),
    AnagramTask(scrambled: 'SPINE', target: 'SNIPE', definition: 'A wading bird with a long straight bill.'),
    AnagramTask(scrambled: 'OCEAN', target: 'CANOE', definition: 'A light narrow boat propelled with a paddle.'),
    AnagramTask(scrambled: 'SHARE', target: 'SHEAR', definition: 'Cut something, or clip the wool from a sheep.'),
    AnagramTask(scrambled: 'BAKER', target: 'BREAK', definition: 'Separate into pieces as a result of a blow or strain.'),
    AnagramTask(scrambled: 'SPACE', target: 'PACES', definition: 'Single steps taken while walking or running.'),
    AnagramTask(scrambled: 'SWORD', target: 'WORDS', definition: 'Units of language that carry meaning.'),
    AnagramTask(scrambled: 'CRUEL', target: 'ULCER', definition: 'An open sore on an external or internal surface of the body.'),
    AnagramTask(scrambled: 'VOTER', target: 'TROVE', definition: 'A store of valuable or delightful things.'),
    AnagramTask(scrambled: 'ASIDE', target: 'IDEAS', definition: 'Thoughts or suggestions about what to do.'),
    AnagramTask(scrambled: 'MARCH', target: 'CHARM', definition: 'The power of delighting, attracting, or fascinating others.'),
    AnagramTask(scrambled: 'PEARS', target: 'SPARE', definition: 'Kept in reserve as an alternative or in case of need.'),
    AnagramTask(scrambled: 'LEADS', target: 'DEALS', definition: 'Agreements entered into by two or more parties.'),
    AnagramTask(scrambled: 'CLEAN', target: 'LANCE', definition: 'A long weapon with a wooden shaft and a pointed steel head.'),
    AnagramTask(scrambled: 'RANGE', target: 'ANGER', definition: 'A strong feeling of annoyance, displeasure, or hostility.'),
    AnagramTask(scrambled: 'CARED', target: 'CEDAR', definition: 'A tall coniferous tree with durable, pleasantly scented wood.'),
    AnagramTask(scrambled: 'TALES', target: 'STEAL', definition: 'Take another person\'s property without permission.'),
    AnagramTask(scrambled: 'HORSE', target: 'SHORE', definition: 'The land along the edge of a sea, lake, or other large body of water.'),
    AnagramTask(scrambled: 'WOLF', target: 'FLOW', definition: 'Move along steadily and continuously in a current or stream.'),
    AnagramTask(scrambled: 'OPTS', target: 'SPOT', definition: 'A small round mark differing in colour from the surface around it.'),
    AnagramTask(scrambled: 'LIPS', target: 'SLIP', definition: 'Slide unintentionally a short distance, typically losing balance.'),
    AnagramTask(scrambled: 'NAPS', target: 'SNAP', definition: 'Break suddenly and completely with a sharp cracking sound.'),
    AnagramTask(scrambled: 'MEAL', target: 'MALE', definition: 'Of or denoting the sex that produces small, mobile gametes.'),
    AnagramTask(scrambled: 'VETO', target: 'VOTE', definition: 'A formal indication of a choice between candidates or courses of action.'),
    AnagramTask(scrambled: 'SENATOR', target: 'TREASON', definition: 'The crime of betraying one\'s country.'),
    AnagramTask(scrambled: 'CREDIT', target: 'DIRECT', definition: 'Extending or moving from one place to another by the shortest way.'),
    AnagramTask(scrambled: 'CATERS', target: 'TRACES', definition: 'Marks or indications of the former presence of something.'),
    AnagramTask(scrambled: 'DANGER', target: 'GARDEN', definition: 'A piece of ground adjoining a house, used for growing plants.'),
    AnagramTask(scrambled: 'CREATION', target: 'REACTION', definition: 'An action performed or a feeling experienced in response to a situation.'),
    AnagramTask(scrambled: 'SINK', target: 'SKIN', definition: 'The thin layer of tissue forming the outer covering of the body.'),
    AnagramTask(scrambled: 'PLEA', target: 'LEAP', definition: 'Jump or spring a long way, to a great height, or with great force.'),
    AnagramTask(scrambled: 'EARN', target: 'NEAR', definition: 'Located a short distance away.'),
    AnagramTask(scrambled: 'STOP', target: 'POST', definition: 'A thick piece of timber or metal set upright in the ground.'),
    AnagramTask(scrambled: 'FEELS', target: 'FLEES', definition: 'Runs away from a place of danger.'),
  ];

  /// Every task, so a test can check that each scramble really is an anagram of
  /// its own answer.
  List<AnagramTask> get tasks => List.unmodifiable(_tasks);

  AnagramTask getRandomTask() {
    return _tasks[Random().nextInt(_tasks.length)];
  }

  bool checkAnswer(String guess, String target) {
    return guess.toUpperCase().replaceAll(' ', '') == target.toUpperCase().replaceAll(' ', '');
  }
}

class AnagramTask {
  final String scrambled;
  final String target;
  final String definition;

  AnagramTask({
    required this.scrambled,
    required this.target,
    required this.definition,
  });
}
