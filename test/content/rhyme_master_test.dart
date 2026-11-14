import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/rhyme_master/rhyme_master_engine.dart';

/// A rhyme is a phoneme tail, not a spelling. The audit found sets that
/// accepted `VIEW`, `NEW`, `FUEL` and `MULE` for `BLUE` and `COOL`: near
/// rhymes, the vowel coloured by a `y` glide. Eyeballing cannot catch that, so
/// the tail of every word is written out here and compared.
///
/// ARPAbet, the rime only (what comes after the onset):
const Map<String, String> _rime = {
  // AE T
  'CAT': 'AE T', 'BAT': 'AE T', 'HAT': 'AE T', 'MAT': 'AE T',
  'RAT': 'AE T', 'SAT': 'AE T', 'FAT': 'AE T', 'PAT': 'AE T',
  'VAT': 'AE T',
  // AY T
  'LIGHT': 'AY T', 'BRIGHT': 'AY T', 'FIGHT': 'AY T', 'NIGHT': 'AY T',
  'SIGHT': 'AY T', 'TIGHT': 'AY T', 'MIGHT': 'AY T', 'RIGHT': 'AY T',
  'WHITE': 'AY T',
  // EY
  'PLAY': 'EY', 'DAY': 'EY', 'MAY': 'EY', 'SAY': 'EY', 'STAY': 'EY',
  'WAY': 'EY', 'GRAY': 'EY', 'PRAY': 'EY', 'TRAY': 'EY',
  // UW
  'BLUE': 'UW', 'DUE': 'UW', 'GLUE': 'UW', 'TRUE': 'UW', 'TWO': 'UW',
  'ZOO': 'UW', 'SHOE': 'UW', 'TOO': 'UW', 'CREW': 'UW',
  // IH NG
  'SING': 'IH NG', 'BRING': 'IH NG', 'KING': 'IH NG', 'RING': 'IH NG',
  'WING': 'IH NG', 'THING': 'IH NG', 'SPRING': 'IH NG', 'STRING': 'IH NG',
  'SWING': 'IH NG',
  // OW L D
  'BOLD': 'OW L D', 'COLD': 'OW L D', 'GOLD': 'OW L D', 'HOLD': 'OW L D',
  'OLD': 'OW L D', 'SOLD': 'OW L D', 'TOLD': 'OW L D', 'FOLD': 'OW L D',
  'MOLD': 'OW L D',
  // UW L
  'COOL': 'UW L', 'POOL': 'UW L', 'RULE': 'UW L', 'SCHOOL': 'UW L',
  'TOOL': 'UW L', 'FOOL': 'UW L', 'SPOOL': 'UW L', 'STOOL': 'UW L',
  'DROOL': 'UW L',
  // The near rhymes that shipped and must never come back.
  'VIEW': 'Y UW', 'NEW': 'Y UW', 'FUEL': 'Y UW L', 'MULE': 'Y UW L',
};

void main() {
  final engine = RhymeMasterEngine();

  test('every rhyme shares the target rime', () {
    final wrong = <String>[];
    for (final set in engine.sets) {
      final target = _rime[set.target];
      expect(target, isNotNull, reason: '${set.target} has no transcription');
      for (final word in set.rhymes) {
        final tail = _rime[word];
        if (tail == null) {
          wrong.add('$word (no transcription)');
        } else if (tail != target) {
          wrong.add('${set.target}: $word is $tail, not $target');
        }
      }
    }
    expect(wrong, isEmpty, reason: wrong.join('\n'));
  });

  test('the sets the audit called dishonest are gone', () {
    for (final set in engine.sets) {
      expect(set.rhymes, isNot(contains('VIEW')));
      expect(set.rhymes, isNot(contains('NEW')));
      expect(set.rhymes, isNot(contains('FUEL')));
      expect(set.rhymes, isNot(contains('MULE')));
    }
  });

  test('every word in a set is a word the app knows', () {
    final words = <String>{
      for (final line in File('assets/chain_words.txt').readAsLinesSync())
        if (line.trim().isNotEmpty) line.trim().toUpperCase(),
    };
    final missing = [
      for (final set in engine.sets)
        for (final word in [...set.rhymes, set.target])
          if (!words.contains(word)) word,
    ];
    expect(missing, isEmpty, reason: 'not in the dictionary: $missing');
  });

  test('a set is a full board and has no repeats', () {
    for (final set in engine.sets) {
      expect(set.rhymes, hasLength(8));
      expect(set.rhymes.toSet(), hasLength(8));
      expect(set.rhymes, isNot(contains(set.target)));
    }
  });

  test('isRhyme answers from the set, and rejects a near rhyme', () {
    expect(engine.isRhyme('BLUE', 'zoo', []), isFalse,
        reason: 'a set has to be passed in; the engine never guesses');
    expect(engine.isRhyme('BLUE', 'ZOO', ['DUE', 'ZOO']), isTrue);
    expect(engine.isRhyme('BLUE', 'VIEW', ['DUE', 'ZOO']), isFalse);
  });
}
