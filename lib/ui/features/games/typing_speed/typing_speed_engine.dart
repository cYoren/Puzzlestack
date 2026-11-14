import 'dart:math';

class TypingSpeedEngine {
  /// Phrases to type, 35 to 65 characters so a run is a run.
  ///
  /// This list used to include "FLUTTER IS A POWERFUL FRAMEWORK FOR APPS",
  /// which is developer filler shipped to players, and stopped at eight
  /// phrases. `test/content/typing_speed_test.dart` keeps both from returning.
  final List<String> _phrases = [
    "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG",
    "PRACTICE MAKES PERFECT IN EVERY ENDEAVOR",
    "KNOWLEDGE IS POWER AND TIME IS MONEY",
    "TYPE AS FAST AS YOU CAN WITHOUT MISTAKES",
    "CHALLENGE YOUR BRAIN WITH A DAILY PUZZLE",
    "SUCCESS IS NOT FINAL AND FAILURE IS NOT FATAL",
    "CONSISTENCY IS THE KEY TO GREAT RESULTS",
    "A CALM MIND MAKES QUICK WORK OF HARD TASKS",
    "SMALL STEPS EVERY DAY BUILD LASTING HABITS",
    "THE MORNING LIGHT FILLS THE EMPTY KITCHEN",
    "SHE PACKED A LUNCH AND RODE THE TRAIN TO WORK",
    "RAIN FELL SOFTLY ON THE TIN ROOF ALL NIGHT",
    "THE OLD BRIDGE CREAKED UNDER THE HEAVY CART",
    "BIRDS GATHERED ON THE WIRE ABOVE THE STREET",
    "HE READ THE MAP TWICE BEFORE TURNING LEFT",
    "WARM BREAD AND STRONG COFFEE START THE DAY",
    "THE CAT SLEPT IN A SQUARE OF SUNLIGHT",
    "EVERY WINDOW IN THE HOUSE WAS OPEN WIDE",
    "WE CLIMBED THE HILL TO WATCH THE SUN SET",
    "HER LAUGH CARRIED ACROSS THE QUIET HARBOR",
    "THE TRAIN LEFT THE STATION TWO MINUTES EARLY",
    "A COLD WIND CAME DOWN FROM THE MOUNTAINS",
    "THE MARKET WAS FULL OF FRUIT AND FLOWERS",
    "HE WROTE THE ADDRESS ON THE BACK OF HIS HAND",
    "LIGHT RAIN FELL WHILE THE KETTLE BOILED",
    "THE DOG WAITED BY THE GATE EVERY EVENING",
    "SHE FOLDED THE LETTER AND PUT IT AWAY",
    "OUR BOAT DRIFTED SLOWLY TOWARD THE SHORE",
    "THE CLOCK IN THE HALL TICKED LOUDLY",
    "FRESH SNOW COVERED THE ROOF AND THE GARDEN",
    "THE PIANIST MISSED THE SAME NOTE TWICE",
    "A BEE HUMMED AROUND THE OPEN JAM JAR",
    "THEY SHARED A JOKE AND FORGOT THE TIME",
    "THE LAMP ON THE DESK FLICKERED ONCE",
    "SIXTEEN APPLES ROLLED OUT OF THE PAPER BAG",
    "HE COUNTED THE STEPS DOWN TO THE RIVER",
    "THE SHOP ON THE CORNER SELLS FRESH BREAD",
    "SHE TYPED THE LAST LINE AND CLOSED THE BOOK",
    "WAVES BROKE AGAINST THE ROCKS BELOW THE CLIFF",
    "A SINGLE CANDLE BURNED IN THE WINDOW",
    "THE GARDEN SMELLED OF WET GRASS AND MINT",
    "WE WALKED THE LONG WAY HOME ALONG THE CANAL",
    "THE BABY LAUGHED AT THE FALLING LEAVES",
    "HER NOTES FILLED THREE PAGES AND ONE MARGIN",
    "THE FERRY SOUNDED ITS HORN IN THE FOG",
    "PICK THE RIPE TOMATOES BEFORE THE RAIN",
  ];

  /// Every phrase, so a test can hold the list to its own rule.
  List<String> get phrases => List.unmodifiable(_phrases);

  String getRandomPhrase() {
    return _phrases[Random().nextInt(_phrases.length)];
  }

  double calculateWPM(int correctChars, int secondsElapsed) {
    if (secondsElapsed <= 0) return 0.0;
    // Standard WPM: (chars / 5) / (seconds / 60)
    return (correctChars / 5.0) / (secondsElapsed / 60.0);
  }

  int countCorrectChars(String input, String target) {
    int count = 0;
    int length = min(input.length, target.length);
    for (int i = 0; i < length; i++) {
      if (input[i].toUpperCase() == target[i].toUpperCase()) {
        count++;
      }
    }
    return count;
  }
}
