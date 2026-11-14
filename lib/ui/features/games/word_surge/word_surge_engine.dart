import 'dart:math';

enum WordSurgeType { synonym, antonym }

class WordSurgeChallenge {
  final String target;
  final String answer;
  final List<String> options;
  final WordSurgeType type;

  WordSurgeChallenge({
    required this.target,
    required this.answer,
    required this.options,
    required this.type,
  });
}

class WordSurgeEngine {
  final Random _random = Random();

  final List<Map<String, dynamic>> _wordPairs = [
    {"word": "Happy", "synonyms": ["Joyful", "Cheerful", "Glad"], "antonyms": ["Sad", "Miserable", "Gloomy"]},
    {"word": "Fast", "synonyms": ["Quick", "Rapid", "Swift"], "antonyms": ["Slow", "Sluggish", "Leisurely"]},
    {"word": "Big", "synonyms": ["Large", "Huge", "Enormous"], "antonyms": ["Small", "Tiny", "Little"]},
    {"word": "Smart", "synonyms": ["Intelligent", "Clever", "Bright"], "antonyms": ["Stupid", "Dull", "Foolish"]},
    {"word": "Brave", "synonyms": ["Courageous", "Fearless", "Valiant"], "antonyms": ["Cowardly", "Fearful", "Timid"]},
    {"word": "Strong", "synonyms": ["Powerful", "Mighty", "Tough"], "antonyms": ["Weak", "Fragile", "Feeble"]},
    {"word": "Kind", "synonyms": ["Generous", "Friendly", "Caring"], "antonyms": ["Cruel", "Mean", "Unkind"]},
    {"word": "Bright", "synonyms": ["Shining", "Radiant", "Luminous"], "antonyms": ["Dark", "Dim", "Dull"]},
    {"word": "Cold", "synonyms": ["Chilly", "Freezing", "Icy"], "antonyms": ["Hot", "Warm", "Burning"]},
    {"word": "Quiet", "synonyms": ["Silent", "Still", "Calm"], "antonyms": ["Loud", "Noisy", "Rowdy"]},
    {"word": "Ancient", "synonyms": ["Old", "Antique", "Aged"], "antonyms": ["Modern", "New", "Fresh"]},
    {"word": "Difficult", "synonyms": ["Hard", "Challenging", "Tough"], "antonyms": ["Easy", "Simple", "Effortless"]},
    {"word": "Beautiful", "synonyms": ["Pretty", "Lovely", "Gorgeous"], "antonyms": ["Ugly", "Hideous", "Repulsive"]},
    {"word": "Wealthy", "synonyms": ["Rich", "Affluent", "Prosperous"], "antonyms": ["Poor", "Needy", "Destitute"]},
    {"word": "Honest", "synonyms": ["Sincere", "Truthful", "Candid"], "antonyms": ["Dishonest", "Deceitful", "Fake"]},
    {"word": "Calm", "synonyms": ["Serene", "Peaceful", "Tranquil"], "antonyms": ["Agitated", "Restless", "Tense"]},
    {"word": "Loud", "synonyms": ["Noisy", "Deafening", "Booming"], "antonyms": ["Hushed", "Muffled", "Faint"]},
    {"word": "Hard", "synonyms": ["Solid", "Firm", "Rigid"], "antonyms": ["Soft", "Pliable", "Spongy"]},
    {"word": "Clean", "synonyms": ["Spotless", "Tidy", "Pure"], "antonyms": ["Dirty", "Filthy", "Grimy"]},
    {"word": "Begin", "synonyms": ["Start", "Commence", "Launch"], "antonyms": ["End", "Finish", "Conclude"]},
    {"word": "Buy", "synonyms": ["Purchase", "Acquire", "Obtain"], "antonyms": ["Sell", "Trade", "Peddle"]},
    {"word": "Build", "synonyms": ["Construct", "Assemble", "Create"], "antonyms": ["Destroy", "Demolish", "Wreck"]},
    {"word": "Accept", "synonyms": ["Receive", "Take", "Admit"], "antonyms": ["Refuse", "Decline", "Deny"]},
    {"word": "Allow", "synonyms": ["Permit", "Authorise", "Enable"], "antonyms": ["Forbid", "Ban", "Block"]},
    {"word": "Arrive", "synonyms": ["Reach", "Appear", "Land"], "antonyms": ["Leave", "Depart", "Exit"]},
    {"word": "Attack", "synonyms": ["Assault", "Strike", "Raid"], "antonyms": ["Defend", "Protect", "Guard"]},
    {"word": "Careful", "synonyms": ["Cautious", "Wary", "Prudent"], "antonyms": ["Careless", "Reckless", "Hasty"]},
    {"word": "Choose", "synonyms": ["Select", "Pick", "Elect"], "antonyms": ["Discard", "Ignore", "Reject"]},
    {"word": "Danger", "synonyms": ["Risk", "Peril", "Hazard"], "antonyms": ["Safety", "Security", "Shelter"]},
    {"word": "Empty", "synonyms": ["Vacant", "Bare", "Hollow"], "antonyms": ["Full", "Packed", "Crowded"]},
    {"word": "Enjoy", "synonyms": ["Relish", "Savour", "Like"], "antonyms": ["Dislike", "Hate", "Loathe"]},
    {"word": "Famous", "synonyms": ["Renowned", "Celebrated", "Noted"], "antonyms": ["Unknown", "Obscure", "Anonymous"]},
    {"word": "Gentle", "synonyms": ["Mild", "Tender", "Soothing"], "antonyms": ["Rough", "Harsh", "Violent"]},
    {"word": "Gather", "synonyms": ["Collect", "Assemble", "Amass"], "antonyms": ["Scatter", "Disperse", "Spread"]},
    {"word": "Increase", "synonyms": ["Raise", "Grow", "Expand"], "antonyms": ["Decrease", "Reduce", "Shrink"]},
    {"word": "Lazy", "synonyms": ["Idle", "Sluggish", "Inactive"], "antonyms": ["Diligent", "Busy", "Energetic"]},
    {"word": "Narrow", "synonyms": ["Thin", "Tight", "Slim"], "antonyms": ["Wide", "Broad", "Spacious"]},
    {"word": "Neat", "synonyms": ["Tidy", "Orderly", "Trim"], "antonyms": ["Messy", "Untidy", "Chaotic"]},
    {"word": "Polite", "synonyms": ["Courteous", "Civil", "Respectful"], "antonyms": ["Rude", "Blunt", "Insolent"]},
    {"word": "Rare", "synonyms": ["Scarce", "Uncommon", "Unusual"], "antonyms": ["Common", "Frequent", "Usual"]},
    {"word": "Simple", "synonyms": ["Easy", "Plain", "Basic"], "antonyms": ["Complex", "Intricate", "Tangled"]},
    {"word": "Small", "synonyms": ["Tiny", "Little", "Minute"], "antonyms": ["Large", "Huge", "Giant"]},
    {"word": "Strange", "synonyms": ["Odd", "Weird", "Bizarre"], "antonyms": ["Normal", "Usual", "Familiar"]},
    {"word": "Sudden", "synonyms": ["Abrupt", "Swift", "Unexpected"], "antonyms": ["Gradual", "Slow", "Expected"]},
    {"word": "Warm", "synonyms": ["Heated", "Toasty", "Mild"], "antonyms": ["Cold", "Cool", "Chilly"]},
    {"word": "Weak", "synonyms": ["Frail", "Feeble", "Faint"], "antonyms": ["Strong", "Sturdy", "Robust"]},
    {"word": "Wise", "synonyms": ["Sage", "Shrewd", "Prudent"], "antonyms": ["Foolish", "Silly", "Unwise"]},
    {"word": "Angry", "synonyms": ["Furious", "Mad", "Irate"], "antonyms": ["Calm", "Pleased", "Content"]},
    {"word": "Safe", "synonyms": ["Secure", "Protected", "Harmless"], "antonyms": ["Dangerous", "Risky", "Unsafe"]},
    {"word": "Early", "synonyms": ["Prompt", "Premature", "Advance"], "antonyms": ["Late", "Delayed", "Tardy"]},
    {"word": "Deep", "synonyms": ["Profound", "Bottomless", "Sunken"], "antonyms": ["Shallow", "Surface", "Flat"]},
    {"word": "Generous", "synonyms": ["Giving", "Liberal", "Openhanded"], "antonyms": ["Stingy", "Selfish", "Miserly"]},
    {"word": "Tired", "synonyms": ["Weary", "Exhausted", "Drained"], "antonyms": ["Fresh", "Rested", "Energetic"]},
    {"word": "Friendly", "synonyms": ["Warm", "Amicable", "Sociable"], "antonyms": ["Hostile", "Aloof", "Unfriendly"]},
    {"word": "Rough", "synonyms": ["Coarse", "Bumpy", "Uneven"], "antonyms": ["Smooth", "Even", "Polished"]},
    {"word": "Certain", "synonyms": ["Sure", "Confident", "Definite"], "antonyms": ["Unsure", "Doubtful", "Hesitant"]},
    {"word": "Hidden", "synonyms": ["Concealed", "Secret", "Covered"], "antonyms": ["Visible", "Obvious", "Exposed"]},
    {"word": "Slow", "synonyms": ["Sluggish", "Leisurely", "Gradual"], "antonyms": ["Fast", "Quick", "Rapid"]},
    {"word": "Cheap", "synonyms": ["Inexpensive", "Economical", "Affordable"], "antonyms": ["Expensive", "Costly", "Pricey"]},
    {"word": "Busy", "synonyms": ["Occupied", "Engaged", "Swamped"], "antonyms": ["Idle", "Free", "Available"]},
  ];

  /// Every pair, so a test can check the pool against the score to win.
  List<Map<String, dynamic>> get wordPairs => List.unmodifiable(_wordPairs);

  WordSurgeChallenge getRandomChallenge() {
    final pair = _wordPairs[_random.nextInt(_wordPairs.length)];
    final type = _random.nextBool() ? WordSurgeType.synonym : WordSurgeType.antonym;
    
    final answer = type == WordSurgeType.synonym 
        ? pair["synonyms"][_random.nextInt(3)] 
        : pair["antonyms"][_random.nextInt(3)];

    final List<String> options = [answer];
    
    // Add 3 wrong options
    while (options.length < 4) {
      final wrongPair = _wordPairs[_random.nextInt(_wordPairs.length)];
      if (wrongPair["word"] == pair["word"]) continue;

      final wrongOptions = [...wrongPair["synonyms"], ...wrongPair["antonyms"]];
      final wrongChoice = wrongOptions[_random.nextInt(wrongOptions.length)];
      
      if (!options.contains(wrongChoice)) {
        options.add(wrongChoice);
      }
    }

    options.shuffle(_random);

    return WordSurgeChallenge(
      target: pair["word"],
      answer: answer,
      options: options,
      type: type,
    );
  }
}
