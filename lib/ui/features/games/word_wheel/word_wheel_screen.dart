import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/utils/haptic_feedback.dart';
import 'package:puzzle/utils/l10n_game_helpers.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';
import '../../../core/juice/game_scaffold.dart';

class WordWheelPuzzle {
  final String pangram;
  final String centralLetter;
  final List<String> letters;
  final Set<String> validWords;

  WordWheelPuzzle({
    required this.pangram,
    required this.centralLetter,
    required this.letters,
    required this.validWords,
  })  : assert(letters.length == 7),
        assert(letters.toSet().length == 7),
        assert(letters.contains(centralLetter)) {
    if (letters.length != 7 ||
        letters.toSet().length != 7 ||
        !letters.contains(centralLetter)) {
      throw ArgumentError(
          'Word wheel puzzle must have exactly 7 unique letters including the central letter');
    }
  }
}

class WordWheelScreen extends ConsumerStatefulWidget {
  const WordWheelScreen({super.key});

  static Set<String>? _dictionary;
  static Future<void>? _loadingFuture;

  static Set<String>? get dictionary => _dictionary;

  /// Loads the accepted-guess dictionary so common English words outside a
  /// curated wheel's core list (such as TREE, ROTOR, RED, TEN, HEN, NET) are
  /// accepted, while the wheels themselves remain strictly the 30 hand-curated
  /// [puzzles].
  static Future<void> loadDictionary() async {
    if (_dictionary != null) return;
    _loadingFuture ??= _loadFromAsset();
    await _loadingFuture;
  }

  static Future<void> _loadFromAsset() async {
    try {
      final data = await rootBundle.loadString('assets/chain_words.txt');
      final words = data
          .split('\n')
          .map((w) => w.trim().toUpperCase())
          .where((w) => w.length >= 3)
          .toSet();
      for (final extra in const <String>[
        'assets/find_word_words.txt',
        'assets/word_search_words.txt',
      ]) {
        try {
          final extraData = await rootBundle.loadString(extra);
          words.addAll(
            extraData
                .split('\n')
                .map((w) => w.trim().toUpperCase())
                .where((w) => w.length >= 3),
          );
        } catch (_) {}
      }
      _dictionary = words;
    } catch (_) {
      _dictionary = null;
      _loadingFuture = null;
    }
  }

  static void setDictionary(Set<String>? words) {
    _dictionary = words;
    _loadingFuture = null;
  }

  static bool isWordValid(WordWheelPuzzle puzzle, String word,
      [Set<String>? dictionary]) {
    final normalized = word.toUpperCase();
    if (!normalized.contains(puzzle.centralLetter)) return false;
    if (puzzle.validWords.contains(normalized)) return true;
    final allowedLetters = puzzle.letters.toSet();
    final usesAllowedLettersOnly =
        normalized.split('').every(allowedLetters.contains);
    final dict = dictionary ?? _dictionary;
    final inDictionary = dict?.contains(normalized) ?? false;
    return usesAllowedLettersOnly && normalized.length >= 3 && inDictionary;
  }

  static final List<WordWheelPuzzle> puzzles = [
    WordWheelPuzzle(
      pangram: 'PROJECT',
      centralLetter: 'R',
      letters: ['P', 'R', 'O', 'J', 'E', 'C', 'T'],
      validWords: {
        'PROJECT',
        'ROPE',
        'PORT',
        'CROP',
        'PORE',
        'CORE',
        'ROTE',
        'PRO',
        'REPO',
        'TROPE',
        'REPRO',
        'RECTO',
        'CREPT',
        'COPER',
        'CORP',
        'TORE',
        'TORC',
        'ERECT',
        'ROOT',
        'POOR',
        'CREEP',
        'RETRO',
        'REPORT',
        'PROTECT',
        'REJECT',
        'TROOP',
        'PROP',
        'PEER',
        'COERCE',
        'CORRECT',
        'COPPER',
        'PROJECTOR'
      },
    ),
    WordWheelPuzzle(
      pangram: 'FLOWERS',
      centralLetter: 'O',
      letters: ['F', 'L', 'O', 'W', 'E', 'R', 'S'],
      validWords: {
        'FLOWERS',
        'FLOWER',
        'FLOW',
        'FLOWS',
        'WOLF',
        'SLOW',
        'ROSE',
        'ROSES',
        'ROLE',
        'ROLES',
        'ROLL',
        'ROLLS',
        'FOOL',
        'FELLOW',
        'FLOOR',
        'FLOORS',
        'FOR',
        'LOSE',
        'LOSS',
        'LOW',
        'LOWER',
        'LOWS',
        'SOLE',
        'SOLO',
        'ROOF',
        'ROW',
        'ROWS',
        'WOOL',
        'WORSE',
        'OFFER',
        'OFFERS',
        'FELLOWS',
        'FOWL',
        'FOWLS',
        'SLOWS',
        'SOWER',
        'SWORE',
        'LORE'
      },
    ),
    WordWheelPuzzle(
      pangram: 'PAINTER',
      centralLetter: 'A',
      letters: ['P', 'A', 'I', 'N', 'T', 'E', 'R'],
      validWords: {
        'PAINTER',
        'PAINT',
        'PAIN',
        'PAIR',
        'PART',
        'PARENT',
        'PARTNER',
        'PAT',
        'PATE',
        'PAPER',
        'RAIN',
        'TRAIN',
        'TRAP',
        'TAPE',
        'TEAR',
        'RATE',
        'NEAR',
        'EARN',
        'AIR',
        'ANT',
        'ART',
        'ATE',
        'EAT',
        'TEA',
        'PAN',
        'TAP',
        'RAT',
        'TAN',
        'TAR',
        'ARE',
        'ERA',
        'REPEAT',
        'REPAIR',
        'RETAIN',
        'PIRATE',
        'PATENT',
        'ATTIRE',
        'RETINA'
      },
    ),
    WordWheelPuzzle(
      pangram: 'ORANGES',
      centralLetter: 'G',
      letters: ['O', 'R', 'A', 'N', 'G', 'E', 'S'],
      validWords: {
        'ORANGES',
        'ORANGE',
        'GEAR',
        'RAGE',
        'SANG',
        'SONG',
        'GONE',
        'RANG',
        'GORE',
        'OGRE',
        'GROAN',
        'GROANS',
        'RAGES',
        'GEARS',
        'GNAR',
        'GOES',
        'GORES',
        'AGE',
        'AGES',
        'EGG',
        'GOA',
        'NAG',
        'NAGS',
        'RAG',
        'RAGS',
        'SAG',
        'GANG',
        'GORGE',
        'GAG',
        'GAGS',
        'GRASS',
        'ORGAN',
        'SAGE',
        'RANGE',
        'RANGES',
        'ANGER',
        'ANGERS',
        'GREEN',
        'GREENS',
        'EAGER',
        'ENGAGE',
        'GARAGE'
      },
    ),
    WordWheelPuzzle(
      pangram: 'BLANKET',
      centralLetter: 'A',
      letters: ['B', 'L', 'A', 'N', 'K', 'E', 'T'],
      validWords: {
        'BLANKET',
        'BLANK',
        'BLEAT',
        'LATE',
        'TALE',
        'LANE',
        'LEAN',
        'BEAK',
        'BAKE',
        'BANE',
        'BEAT',
        'BETA',
        'BALE',
        'ABLE',
        'TANK',
        'TALK',
        'LEAK',
        'LAKE',
        'KALE',
        'NEAT',
        'BAT',
        'TAB',
        'BAN',
        'NAB',
        'LAB',
        'ALE',
        'ATE',
        'EAT',
        'TEA',
        'TAN',
        'ANT',
        'BANK',
        'BATE',
        'TEAK',
        'TABLE',
        'ANKLE'
      },
    ),
    WordWheelPuzzle(
      pangram: 'MONSTER',
      centralLetter: 'T',
      letters: ['M', 'O', 'N', 'S', 'T', 'E', 'R'],
      validWords: {
        'MONSTER',
        'MONSTERS',
        'METRO',
        'MENTOR',
        'MOMENT',
        'MOMENTS',
        'METER',
        'METERS',
        'NEST',
        'NET',
        'NOT',
        'NOTE',
        'NOTES',
        'REMOTE',
        'RENT',
        'RESET',
        'RESORT',
        'REST',
        'RESTORE',
        'RETRO',
        'ROOT',
        'ROSTER',
        'SENT',
        'SET',
        'SETS',
        'SORT',
        'SORTS',
        'STEM',
        'STEREO',
        'STONE',
        'STONES',
        'STORE',
        'STORES',
        'STORM',
        'STREET',
        'STRESS',
        'TENT',
        'TERM',
        'TERMS',
        'TEST',
        'TOE',
        'TONE',
        'TONES',
        'TREE',
        'TREES',
        'METEOR',
        'TENOR',
        'TORSO',
        'SMOTE',
        'SEMESTER'
      },
    ),
    WordWheelPuzzle(
      pangram: 'CAMPING',
      centralLetter: 'A',
      letters: ['C', 'A', 'M', 'P', 'I', 'N', 'G'],
      validWords: {
        'AAA',
        'ACACIA',
        'ACING',
        'AGAIN',
        'AGING',
        'AGNI',
        'AIM',
        'AIMING',
        'AMA',
        'AMAIN',
        'AMIGA',
        'AMMAN',
        'AMP',
        'ANA',
        'ANACIN',
        'ANGINA',
        'ANI',
        'ANN',
        'ANNA',
        'ANNAM',
        'API',
        'APIA',
        'APING',
        'APP',
        'CAGING',
        'CAIN',
        'CAM',
        'CAMP',
        'CAMPING',
        'CAN',
        'CANAAN',
        'CANCAN',
        'CANING',
        'CANNA',
        'CANNING',
        'CAP',
        'CAPPING',
        'CIA',
        'CPA',
        'GAG'
      },
    ),
    WordWheelPuzzle(
      pangram: 'GARDENS',
      centralLetter: 'E',
      letters: ['G', 'A', 'R', 'D', 'E', 'N', 'S'],
      validWords: {
        'GARDENS',
        'ADAGE',
        'ADAGES',
        'ADDED',
        'ADDEND',
        'ADDENDA',
        'ADDENDS',
        'ADDER',
        'ADDERS',
        'ADDRESS',
        'ADEN',
        'AEGEAN',
        'AENEAS',
        'AGE',
        'AGED',
        'AGENDA',
        'AGENDAS',
        'AGERS',
        'AGES',
        'AGNES',
        'AGREE',
        'AGREED',
        'AGREES',
        'ANDEAN',
        'ANDES',
        'ANDRE',
        'ANDREA',
        'ANDRES',
        'ANGER',
        'ANGERED',
        'ANGERS',
        'ANNE',
        'ARDEN',
        'ARE',
        'AREA',
        'AREAS',
        'ARENA',
        'ARENAS',
        'ARES',
        'ARRANGE'
      },
    ),
    WordWheelPuzzle(
      pangram: 'KITCHEN',
      centralLetter: 'I',
      letters: ['K', 'I', 'T', 'C', 'H', 'E', 'N'],
      validWords: {
        'KITCHEN',
        'CHI',
        'CHIC',
        'CHICHI',
        'CHICK',
        'CHICKEN',
        'CHIN',
        'CHINE',
        'CHINK',
        'CHIT',
        'CHITIN',
        'CINCH',
        'CITE',
        'ENTICE',
        'ETHIC',
        'ETHNIC',
        'HECTIC',
        'HEINE',
        'HETTIE',
        'HICK',
        'HIE',
        'HIKE',
        'HINT',
        'HIT',
        'HITCH',
        'HITTITE',
        'ICC',
        'ICE',
        'IEEE',
        'III',
        'IKE',
        'INC',
        'INCH',
        'INCITE',
        'INK',
        'INN',
        'INT',
        'INTENT',
        'ITCH',
        'KEITH'
      },
    ),
    WordWheelPuzzle(
      pangram: 'WINTERS',
      centralLetter: 'I',
      letters: ['W', 'I', 'N', 'T', 'E', 'R', 'S'],
      validWords: {
        'WINTERS',
        'EERIE',
        'EERIER',
        'EERIEST',
        'EIRE',
        'EISNER',
        'ENTIRE',
        'ENTRIES',
        'ENTWINE',
        'ERIE',
        'ERIN',
        'ERIS',
        'ERISES',
        'ERNIE',
        'ERWIN',
        'ESSIE',
        'IEEE',
        'III',
        'INERT',
        'INES',
        'INN',
        'INNER',
        'INNS',
        'INS',
        'INSERT',
        'INSERTS',
        'INSET',
        'INSETS',
        'INSIST',
        'INSISTS',
        'INT',
        'INTENSE',
        'INTENT',
        'INTENTS',
        'INTER',
        'INTERN',
        'INTERNE',
        'INTERNS',
        'INTERS',
        'IRE'
      },
    ),
    WordWheelPuzzle(
      pangram: 'CHAPTER',
      centralLetter: 'E',
      letters: ['C', 'H', 'A', 'P', 'T', 'E', 'R'],
      validWords: {
        'ACCEPT',
        'ACE',
        'ACETATE',
        'ACHE',
        'ACRE',
        'AERATE',
        'APACE',
        'APACHE',
        'APE',
        'APPEAR',
        'APTER',
        'ARCHER',
        'ARE',
        'AREA',
        'ATE',
        'CACHE',
        'CACHET',
        'CAPE',
        'CAPER',
        'CAPET',
        'CARE',
        'CAREER',
        'CARET',
        'CARPET',
        'CARTE',
        'CARTER',
        'CATCHER',
        'CATER',
        'CATERER',
        'CATHER',
        'CHAPTER',
        'CHARTER',
        'CHATTER',
        'CHE',
        'CHEAP',
        'CHEAPER',
        'CHEAT',
        'CHEATER',
        'CHEEP',
        'CHEER'
      },
    ),
    WordWheelPuzzle(
      pangram: 'DOLPHIN',
      centralLetter: 'O',
      letters: ['D', 'O', 'L', 'P', 'H', 'I', 'N'],
      validWords: {
        'DIDO',
        'DILLON',
        'DINO',
        'DION',
        'DODO',
        'DOLL',
        'DOLLOP',
        'DOLPHIN',
        'DON',
        'DONN',
        'HIPPO',
        'HOD',
        'HOLD',
        'HON',
        'HOOD',
        'HOODOO',
        'HOOP',
        'HOP',
        'HOPI',
        'IDOL',
        'INDIO',
        'ION',
        'IPO',
        'IPOD',
        'LION',
        'LODI',
        'LOIN',
        'LOLL',
        'LON',
        'LONDON',
        'LOON',
        'LOOP',
        'LOP',
        'NIPPON',
        'NOD',
        'NOH',
        'NON',
        'NOON',
        'ODD',
        'ODIN'
      },
    ),
    WordWheelPuzzle(
      pangram: 'HARVEST',
      centralLetter: 'A',
      letters: ['H', 'A', 'R', 'V', 'E', 'S', 'T'],
      validWords: {
        'HARVEST',
        'AAA',
        'AERATE',
        'AERATES',
        'AHA',
        'ARA',
        'ARARAT',
        'ARE',
        'AREA',
        'AREAS',
        'ARES',
        'ARHAT',
        'ARREARS',
        'ARREST',
        'ARRESTS',
        'ART',
        'ARTS',
        'ASH',
        'ASHE',
        'ASHES',
        'ASS',
        'ASSERT',
        'ASSERTS',
        'ASSES',
        'ASSESS',
        'ASSET',
        'ASSETS',
        'ASST',
        'ASTARTE',
        'ASTER',
        'ASTERS',
        'ATE',
        'ATS',
        'ATTAR',
        'ATTEST',
        'ATTESTS',
        'ATV',
        'AVA',
        'AVAST',
        'AVATAR'
      },
    ),
    WordWheelPuzzle(
      pangram: 'MUSICAL',
      centralLetter: 'I',
      letters: ['M', 'U', 'S', 'I', 'C', 'A', 'L'],
      validWords: {
        'MUSICAL',
        'ACACIA',
        'ACACIAS',
        'ACCLAIM',
        'AIL',
        'AILS',
        'AIM',
        'AIMS',
        'AIS',
        'ALI',
        'ALIAS',
        'ALICIA',
        'ALISA',
        'ALISSA',
        'ALLIS',
        'AMALIA',
        'AMISS',
        'ASCII',
        'ASCIIS',
        'ASIA',
        'ASSAI',
        'ASSAIL',
        'ASSAILS',
        'ASSISI',
        'CALAIS',
        'CALCIUM',
        'CALCULI',
        'CALI',
        'CAMILLA',
        'CASSIA',
        'CASSIAS',
        'CASSIUS',
        'CIA',
        'CILIA',
        'CILIUM',
        'CIS',
        'CLAIM',
        'CLAIMS',
        'CLASSIC',
        'CLII'
      },
    ),
    WordWheelPuzzle(
      pangram: 'PLASTIC',
      centralLetter: 'A',
      letters: ['P', 'L', 'A', 'S', 'T', 'I', 'C'],
      validWords: {
        'PLASTIC',
        'AAA',
        'ACACIA',
        'ACACIAS',
        'ACCT',
        'ACT',
        'ACTS',
        'AIL',
        'AILS',
        'AIS',
        'ALA',
        'ALAS',
        'ALI',
        'ALIAS',
        'ALICIA',
        'ALISA',
        'ALISSA',
        'ALIT',
        'ALL',
        'ALLIS',
        'ALPACA',
        'ALPACAS',
        'ALPS',
        'ALT',
        'ALTA',
        'ALTAI',
        'ALTAIC',
        'ALTS',
        'API',
        'APIA',
        'APP',
        'APPAL',
        'APPALL',
        'APPALLS',
        'APPALS',
        'APPS',
        'APSIS',
        'APT',
        'ASAP',
        'ASCII'
      },
    ),
    WordWheelPuzzle(
      pangram: 'STORAGE',
      centralLetter: 'O',
      letters: ['S', 'T', 'O', 'R', 'A', 'G', 'E'],
      validWords: {
        'STORAGE',
        'AERATOR',
        'AGO',
        'AGOG',
        'AORTA',
        'AORTAE',
        'AORTAS',
        'ARGO',
        'ARGOS',
        'ARGOT',
        'ARGOTS',
        'AROSE',
        'ASSORT',
        'ASSORTS',
        'ASTOR',
        'EEO',
        'EGGO',
        'EGO',
        'EGOS',
        'ERATO',
        'ERGO',
        'EROS',
        'EROSES',
        'ERROR',
        'ERRORS',
        'GAROTE',
        'GAROTES',
        'GAROTTE',
        'GARROTE',
        'GATOR',
        'GEO',
        'GEORGE',
        'GEORGES',
        'GOA',
        'GOAT',
        'GOATEE',
        'GOATEES',
        'GOATS',
        'GOES',
        'GOG'
      },
    ),
    WordWheelPuzzle(
      pangram: 'THUNDER',
      centralLetter: 'E',
      letters: ['T', 'H', 'U', 'N', 'D', 'E', 'R'],
      validWords: {
        'THUNDER',
        'DDED',
        'DEE',
        'DEED',
        'DEEDED',
        'DEER',
        'DEERE',
        'DEN',
        'DENT',
        'DENTED',
        'DENTURE',
        'DENUDE',
        'DENUDED',
        'DETER',
        'DUDE',
        'DUDED',
        'DUE',
        'DUET',
        'DUNE',
        'DUNNE',
        'DUNNED',
        'DUNNER',
        'EDEN',
        'EDT',
        'END',
        'ENDED',
        'ENDER',
        'ENDUE',
        'ENDUED',
        'ENDURE',
        'ENDURED',
        'ENTENTE',
        'ENTER',
        'ENTERED',
        'ENURE',
        'ENURED',
        'ERE',
        'ERR',
        'ERRED',
        'ETD'
      },
    ),
    WordWheelPuzzle(
      pangram: 'CLIMATE',
      centralLetter: 'I',
      letters: ['C', 'L', 'I', 'M', 'A', 'T', 'E'],
      validWords: {
        'ACACIA',
        'ACCLAIM',
        'ACETIC',
        'AIL',
        'AIM',
        'AIMEE',
        'ALI',
        'ALICE',
        'ALICIA',
        'ALIT',
        'ALLIE',
        'ALTAI',
        'ALTAIC',
        'AMALIA',
        'AMATI',
        'AMELIA',
        'AMIE',
        'ATTIC',
        'ATTICA',
        'ATTILA',
        'CACTI',
        'CALCITE',
        'CALI',
        'CALLIE',
        'CAMILLA',
        'CAMILLE',
        'CATTAIL',
        'CECELIA',
        'CECIL',
        'CECILE',
        'CECILIA',
        'CELIA',
        'CELLI',
        'CELTIC',
        'CIA',
        'CILIA',
        'CITE',
        'CLAIM',
        'CLII',
        'CLIMATE'
      },
    ),
    WordWheelPuzzle(
      pangram: 'DEFAULT',
      centralLetter: 'A',
      letters: ['D', 'E', 'F', 'A', 'U', 'L', 'T'],
      validWords: {
        'AAA',
        'ADA',
        'ADD',
        'ADDED',
        'ADDLE',
        'ADDLED',
        'ADELA',
        'ADELE',
        'ADULATE',
        'ADULT',
        'AFT',
        'ALA',
        'ALE',
        'ALEUT',
        'ALFALFA',
        'ALL',
        'ALLUDE',
        'ALLUDED',
        'ALT',
        'ALTA',
        'ATE',
        'ATTLEE',
        'DAD',
        'DADA',
        'DAFT',
        'DALE',
        'DAT',
        'DATA',
        'DATE',
        'DATED',
        'DEAD',
        'DEAF',
        'DEAL',
        'DEALT',
        'DEFAULT',
        'DEFEAT',
        'DEFLATE',
        'DELLA',
        'DELTA',
        'DUAL'
      },
    ),
    WordWheelPuzzle(
      pangram: 'GRANITE',
      centralLetter: 'R',
      letters: ['G', 'R', 'A', 'N', 'I', 'T', 'E'],
      validWords: {
        'GRANITE',
        'AERATE',
        'AERIE',
        'AGAR',
        'AGRA',
        'AGREE',
        'AIR',
        'AIRER',
        'AIRIER',
        'AIRING',
        'ANGARA',
        'ANGER',
        'ANGRIER',
        'ARA',
        'ARARAT',
        'ARE',
        'AREA',
        'ARENA',
        'ARIA',
        'ARRAIGN',
        'ARRANGE',
        'ARRANT',
        'ART',
        'ARTIE',
        'ARTIER',
        'ATARI',
        'ATRIA',
        'ATTAR',
        'ATTIRE',
        'EAGER',
        'EAGERER',
        'EAR',
        'EARN',
        'EARNER',
        'EARNING',
        'EARRING',
        'EATER',
        'EERIE',
        'EERIER',
        'EGRET'
      },
    ),
    WordWheelPuzzle(
      pangram: 'KINGDOM',
      centralLetter: 'I',
      letters: ['K', 'I', 'N', 'G', 'D', 'O', 'M'],
      validWords: {
        'KINGDOM',
        'DDING',
        'DID',
        'DIDO',
        'DIG',
        'DIGGING',
        'DIKING',
        'DIM',
        'DIMMING',
        'DIN',
        'DING',
        'DINGING',
        'DINGO',
        'DINING',
        'DINK',
        'DINNING',
        'DINO',
        'DION',
        'DODGING',
        'DOGGING',
        'DOING',
        'DOMING',
        'DOMINGO',
        'DOMINO',
        'DONNING',
        'DOOMING',
        'GIG',
        'GIGGING',
        'GIGO',
        'GIN',
        'GINGKO',
        'GINKGO',
        'GINNING',
        'GINO',
        'GOING',
        'GONGING',
        'IDIOM',
        'III',
        'IKON',
        'IMO'
      },
    ),
    WordWheelPuzzle(
      pangram: 'MIRACLE',
      centralLetter: 'R',
      letters: ['M', 'I', 'R', 'A', 'C', 'L', 'E'],
      validWords: {
        'MIRACLE',
        'ACCRA',
        'ACRE',
        'AERIAL',
        'AERIE',
        'AIMER',
        'AIR',
        'AIRER',
        'AIRIER',
        'AIRMAIL',
        'ALAR',
        'ALARIC',
        'ALARM',
        'AMEER',
        'AMERICA',
        'AMIR',
        'ARA',
        'ARACELI',
        'ARAL',
        'ARAMAIC',
        'ARC',
        'ARE',
        'AREA',
        'ARIA',
        'ARIEL',
        'ARM',
        'ARMER',
        'CALLER',
        'CALMER',
        'CAMERA',
        'CAR',
        'CARA',
        'CARAMEL',
        'CARE',
        'CAREER',
        'CARL',
        'CARLA',
        'CARMELA',
        'CARR',
        'CARREL'
      },
    ),
    WordWheelPuzzle(
      pangram: 'PLANETS',
      centralLetter: 'L',
      letters: ['P', 'L', 'A', 'N', 'E', 'T', 'S'],
      validWords: {
        'PLANETS',
        'ALA',
        'ALAN',
        'ALANA',
        'ALAS',
        'ALE',
        'ALES',
        'ALL',
        'ALLAN',
        'ALLEN',
        'ALPS',
        'ALT',
        'ALTA',
        'ALTS',
        'ANAL',
        'ANNAL',
        'ANNALS',
        'ANNEAL',
        'ANNEALS',
        'APPAL',
        'APPALL',
        'APPALLS',
        'APPALS',
        'APPEAL',
        'APPEALS',
        'APPLE',
        'APPLES',
        'ASL',
        'ASLANT',
        'ASLEEP',
        'ASPELL',
        'ATLANTA',
        'ATLAS',
        'ATLASES',
        'ATTLEE',
        'EASEL',
        'EASELS',
        'EEL',
        'EELS',
        'ELAPSE'
      },
    ),
    WordWheelPuzzle(
      pangram: 'SANDBOX',
      centralLetter: 'A',
      letters: ['S', 'A', 'N', 'D', 'B', 'O', 'X'],
      validWords: {
        'SANDBOX',
        'AAA',
        'ABANDON',
        'ABBAS',
        'ADA',
        'ADAN',
        'ADANA',
        'ADAS',
        'ADD',
        'ADDS',
        'ADO',
        'ADS',
        'ANA',
        'AND',
        'ANN',
        'ANNA',
        'ANON',
        'ANONS',
        'ASS',
        'ASSAD',
        'ASSN',
        'AXON',
        'AXONS',
        'BAA',
        'BAAS',
        'BABOON',
        'BABOONS',
        'BAD',
        'BAN',
        'BANANA',
        'BANANAS',
        'BAND',
        'BANDANA',
        'BANDS',
        'BANNS',
        'BANS',
        'BAOBAB',
        'BAOBABS',
        'BASS',
        'BASSO'
      },
    ),
    WordWheelPuzzle(
      pangram: 'WHISPER',
      centralLetter: 'I',
      letters: ['W', 'H', 'I', 'S', 'P', 'E', 'R'],
      validWords: {
        'WHISPER',
        'EERIE',
        'EERIER',
        'EIRE',
        'ERIE',
        'ERIS',
        'ERISES',
        'ESPIES',
        'ESSIE',
        'HEIR',
        'HEIRESS',
        'HEIRS',
        'HIE',
        'HIES',
        'HIP',
        'HIPPER',
        'HIPPIE',
        'HIPPIES',
        'HIPS',
        'HIRE',
        'HIRER',
        'HIRES',
        'HIS',
        'HISS',
        'HISSES',
        'IEEE',
        'III',
        'IRE',
        'IRIS',
        'IRISES',
        'IRISH',
        'IRISHER',
        'IRS',
        'ISIS',
        'ISP',
        'ISS',
        'PEI',
        'PEPPIER',
        'PEPSI',
        'PERISH'
      },
    ),
    WordWheelPuzzle(
      pangram: 'CABINET',
      centralLetter: 'A',
      letters: ['C', 'A', 'B', 'I', 'N', 'E', 'T'],
      validWords: {
        'CABINET',
        'AAA',
        'ABACI',
        'ABATE',
        'ABC',
        'ABE',
        'ABET',
        'ACACIA',
        'ACCENT',
        'ACCT',
        'ACE',
        'ACETATE',
        'ACETIC',
        'ACNE',
        'ACT',
        'ANA',
        'ANACIN',
        'ANCIENT',
        'ANENT',
        'ANI',
        'ANITA',
        'ANN',
        'ANNA',
        'ANNE',
        'ANNETTE',
        'ANNIE',
        'ANT',
        'ANTE',
        'ANTENNA',
        'ANTI',
        'ANTIC',
        'ATE',
        'ATTAIN',
        'ATTIC',
        'ATTICA',
        'BAA',
        'BABBITT',
        'BABE',
        'BAIT',
        'BAN'
      },
    ),
    WordWheelPuzzle(
      pangram: 'CURTAIN',
      centralLetter: 'R',
      letters: ['C', 'U', 'R', 'T', 'A', 'I', 'N'],
      validWords: {
        'ACCRA',
        'AIR',
        'ARA',
        'ARARAT',
        'ARC',
        'ARCTIC',
        'ARIA',
        'ARRANT',
        'ART',
        'ATARI',
        'ATRIA',
        'ATTAR',
        'ATTRACT',
        'AURA',
        'AURIC',
        'CAIRN',
        'CAR',
        'CARA',
        'CARAT',
        'CARINA',
        'CARR',
        'CART',
        'CIRCA',
        'CIRCUIT',
        'CITRIC',
        'CRANIA',
        'CRITIC',
        'CRT',
        'CUR',
        'CURIA',
        'CURRANT',
        'CURT',
        'CURTAIN',
        'INCUR',
        'IRA',
        'IRAN',
        'IRANIAN',
        'IRC',
        'NAIR',
        'NARC'
      },
    ),
    WordWheelPuzzle(
      pangram: 'FORTUNE',
      centralLetter: 'O',
      letters: ['F', 'O', 'R', 'T', 'U', 'N', 'E'],
      validWords: {
        'EEO',
        'EFFORT',
        'ENRON',
        'EON',
        'ERROR',
        'ETON',
        'EURO',
        'FOE',
        'FONT',
        'FOO',
        'FOOT',
        'FOR',
        'FORE',
        'FORT',
        'FORTE',
        'FORTUNE',
        'FOUNT',
        'FOUR',
        'FREON',
        'FRO',
        'FRONT',
        'FUROR',
        'FUTON',
        'NEO',
        'NEON',
        'NERO',
        'NEURON',
        'NEUTRON',
        'NOE',
        'NON',
        'NONE',
        'NOON',
        'NOR',
        'NOREEN',
        'NORTON',
        'NOT',
        'NOTE',
        'NOUN',
        'OFF',
        'OFFER'
      },
    ),
    WordWheelPuzzle(
      pangram: 'GLACIER',
      centralLetter: 'A',
      letters: ['G', 'L', 'A', 'C', 'I', 'E', 'R'],
      validWords: {
        'GLACIER',
        'AAA',
        'ACACIA',
        'ACCRA',
        'ACE',
        'ACRE',
        'ACREAGE',
        'AERIAL',
        'AERIE',
        'AGAR',
        'AGE',
        'AGGIE',
        'AGILE',
        'AGLAIA',
        'AGRA',
        'AGREE',
        'AIL',
        'AIR',
        'AIRER',
        'AIRIER',
        'ALA',
        'ALAR',
        'ALARIC',
        'ALE',
        'ALEC',
        'ALGA',
        'ALGAE',
        'ALGAL',
        'ALGER',
        'ALGERIA',
        'ALI',
        'ALICE',
        'ALICIA',
        'ALL',
        'ALLEGE',
        'ALLEGRA',
        'ALLIE',
        'ARA',
        'ARACELI',
        'ARAL'
      },
    ),
    WordWheelPuzzle(
      pangram: 'JOURNEY',
      centralLetter: 'E',
      letters: ['J', 'O', 'U', 'R', 'N', 'E', 'Y'],
      validWords: {
        'EEO',
        'EERY',
        'EEYORE',
        'ENJOY',
        'ENRON',
        'ENURE',
        'EON',
        'ERE',
        'ERR',
        'ERROR',
        'EURO',
        'EYE',
        'EYRE',
        'JEER',
        'JEJUNE',
        'JENNER',
        'JENNY',
        'JERRY',
        'JOE',
        'JOEY',
        'JOURNEY',
        'JOYNER',
        'JUNE',
        'NEO',
        'NEON',
        'NERO',
        'NEURON',
        'NOE',
        'NONE',
        'NOREEN',
        'NUNNERY',
        'NYERERE',
        'ONE',
        'ORE',
        'OREO',
        'ORNERY',
        'RENE',
        'RENEE',
        'RENO',
        'RERUN'
      },
    ),
  ];

  @override
  ConsumerState<WordWheelScreen> createState() => _WordWheelScreenState();
}

class _WordWheelScreenState extends ConsumerState<WordWheelScreen> {
  final Random _random = Random();

  late WordWheelPuzzle _currentPuzzle;
  late List<String> _outerLetters;
  String _currentInput = '';
  final Set<String> _foundWords = {};
  int _score = 0;
  final int _targetScore = 4;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
    WordWheelScreen.loadDictionary();
  }

  void _generatePuzzle() {
    _foundWords.clear();
    _currentInput = '';
    _isGameOver = false;
    _score = 0;

    _currentPuzzle = WordWheelScreen
        .puzzles[_random.nextInt(WordWheelScreen.puzzles.length)];
    _outerLetters = _currentPuzzle.letters
        .toSet()
        .where((letter) => letter != _currentPuzzle.centralLetter)
        .toList();
    _outerLetters.shuffle(_random);
  }

  void _onLetterTapped(String letter) {
    if (_isGameOver) return;
    HapticFeedbackUtil.lightImpact();
    setState(() {
      _currentInput += letter;
    });
  }

  void _onBackspace() {
    if (_currentInput.isEmpty || _isGameOver) return;
    HapticFeedbackUtil.lightImpact();
    setState(() {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
    });
  }

  void _onSubmit() async {
    if (_isGameOver || _currentInput.isEmpty) return;

    final word = _currentInput.toUpperCase();
    if (!word.contains(_currentPuzzle.centralLetter)) {
      HapticFeedbackUtil.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .snackbarWordMustContainCentral(_currentPuzzle.centralLetter)),
          duration: const Duration(seconds: 1),
        ),
      );
      setState(() {
        _currentInput = '';
      });
      return;
    }

    if (_foundWords.contains(word)) {
      HapticFeedbackUtil.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.snackbarWordAlreadyFound),
          duration: const Duration(seconds: 1),
        ),
      );
      setState(() {
        _currentInput = '';
      });
      return;
    }

    await WordWheelScreen.loadDictionary();
    if (!mounted) return;

    final isValid = WordWheelScreen.isWordValid(_currentPuzzle, word);

    if (isValid) {
      HapticFeedbackUtil.success();
      setState(() {
        _foundWords.add(word);
        _score++;
        _currentInput = '';

        if (_score >= _targetScore) {
          _isGameOver = true;
          _onGameComplete();
        }
      });
    } else {
      HapticFeedbackUtil.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.snackbarNotAValidWord),
          duration: const Duration(seconds: 1),
        ),
      );
      setState(() {
        _currentInput = '';
      });
    }
  }

  void _onGameComplete() async {
    HapticFeedbackUtil.victory();
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('word_wheel');
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameCompletionDialog(
        title: AppLocalizations.of(context)!.wellDone.toUpperCase(),
        message: AppLocalizations.of(context)!.completed,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _generatePuzzle();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GameScaffold(
      title: L10nGameHelpers.getGameTitle(context, 'word_wheel'),
      subtitle: L10nGameHelpers.getGameSubtitle(context, 'word_wheel'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            HapticFeedbackUtil.lightImpact();
            setState(() {
              _generatePuzzle();
            });
          },
        ),
      ],
      body: Column(
        children: [
          // Header / Input Board
          Padding(
            padding: const EdgeInsets.all(DesignSystem.spaceMD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? DesignSystem.darkSurface
                          : DesignSystem.surface,
                      borderRadius:
                          BorderRadius.circular(DesignSystem.radiusSM),
                      border: Border.all(
                        color: isDark
                            ? DesignSystem.darkOutline
                            : DesignSystem.outline,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _currentInput,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: DesignSystem.primary,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignSystem.spaceSM),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: DesignSystem.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSM),
                  ),
                  child: Text(
                    '$_score / $_targetScore',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: DesignSystem.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
          // Interactive Letter Wheel
          Expanded(
            child: Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Letters
                    ...List.generate(6, (index) {
                      final double angle = (index * 2 * pi / 6) - pi / 2;
                      final double radius = 90.0;
                      final double x = radius * cos(angle);
                      final double y = radius * sin(angle);
                      final letter = _outerLetters[index];

                      return Transform.translate(
                        offset: Offset(x, y),
                        child: GestureDetector(
                          onTap: () => _onLetterTapped(letter),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: isDark
                                ? DesignSystem.darkSurface
                                : Colors.white,
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    // Central Letter
                    GestureDetector(
                      onTap: () =>
                          _onLetterTapped(_currentPuzzle.centralLetter),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: DesignSystem.primary,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _currentPuzzle.centralLetter,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Found Words Lists & Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            height: 60,
            alignment: Alignment.center,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _foundWords.map((word) {
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  color: DesignSystem.gameGreen.withValues(alpha: 0.15),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Text(
                      word,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.gameGreen,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Buttons
          Padding(
            padding: const EdgeInsets.all(DesignSystem.spaceMD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.backspace_rounded, size: 28),
                  onPressed: _onBackspace,
                ),
                ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignSystem.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignSystem.radiusMD),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.btnSubmit,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
