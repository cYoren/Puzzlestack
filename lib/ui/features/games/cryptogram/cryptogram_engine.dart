import 'dart:math';

class CryptogramEngine {
  /// Quotes to encode. A run consumes one, so the pool is deliberately longer
  /// than a session: six quotes meant the third cryptogram was a repeat.
  final List<String> _quotes = [
    "DREAM BIG AND DARE TO FAIL",
    "STAY HUNGRY STAY FOOLISH",
    "LIFE IS WHAT HAPPENS WHILE YOU ARE MAKING OTHER PLANS",
    "THE ONLY WAY TO DO GREAT WORK IS TO LOVE WHAT YOU DO",
    "BE THE CHANGE YOU WISH TO SEE IN THE WORLD",
    "WHATEVER YOU ARE BE A GOOD ONE",
    "THE JOURNEY OF A THOUSAND MILES BEGINS WITH ONE STEP",
    "A PENNY SAVED IS A PENNY EARNED",
    "WHERE THERE IS A WILL THERE IS A WAY",
    "ACTIONS SPEAK LOUDER THAN WORDS",
    "HONESTY IS THE BEST POLICY",
    "EVERY CLOUD HAS A SILVER LINING",
    "TIME AND TIDE WAIT FOR NO MAN",
    "THE EARLY BIRD CATCHES THE WORM",
    "ALWAYS LOOK BEFORE YOU LEAP",
    "TOO MANY COOKS SPOIL THE BROTH",
    "STRIKE WHILE THE IRON IS HOT",
    "A ROLLING STONE GATHERS NO MOSS",
    "ROME WAS NOT BUILT IN A DAY",
    "ALL THAT GLITTERS IS NOT GOLD",
    "SLOW AND STEADY WINS THE RACE",
    "SIMPLICITY IS THE ULTIMATE SOPHISTICATION",
    "THE BEST WAY TO PREDICT THE FUTURE IS TO CREATE IT",
    "NOTHING VENTURED NOTHING GAINED",
  ];

  /// Every quote, so a test can hold the pool to the letters the cipher needs.
  List<String> get quotes => List.unmodifiable(_quotes);

  Map<String, dynamic> generatePuzzle() {
    final random = Random();
    final quote = _quotes[random.nextInt(_quotes.length)];
    
    // Create alphabet mapping
    List<String> alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('');
    List<String> shuffled = List.from(alphabet)..shuffle();
    
    // Ensure no letter maps to itself
    for (int i = 0; i < alphabet.length; i++) {
      if (alphabet[i] == shuffled[i]) {
        // Swap with next
        int next = (i + 1) % alphabet.length;
        String temp = shuffled[i];
        shuffled[i] = shuffled[next];
        shuffled[next] = temp;
      }
    }

    Map<String, String> encodingMap = {};
    for (int i = 0; i < alphabet.length; i++) {
      encodingMap[alphabet[i]] = shuffled[i];
    }

    String encodedQuote = "";
    for (int i = 0; i < quote.length; i++) {
      String char = quote[i];
      if (alphabet.contains(char)) {
        encodedQuote += encodingMap[char]!;
      } else {
        encodedQuote += char;
      }
    }

    return {
      'original': quote,
      'encoded': encodedQuote,
    };
  }

  bool checkWin(String original, Map<String, String> userMapping, String encoded) {
    for (int i = 0; i < encoded.length; i++) {
      String encodedChar = encoded[i];
      if ("ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(encodedChar)) {
        if (userMapping[encodedChar] != original[i]) {
          return false;
        }
      }
    }
    return true;
  }
}
