import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/typing_speed/typing_speed_engine.dart';

/// Eight phrases is a five-minute novelty, and one of the eight was
/// "FLUTTER IS A POWERFUL FRAMEWORK FOR APPS": developer filler, shipped to
/// people who came to practise typing.
void main() {
  final engine = TypingSpeedEngine();
  final phrases = engine.phrases;

  test('there is enough to type for a while', () {
    expect(phrases.length, greaterThanOrEqualTo(40));
  });

  test('no phrase is listed twice', () {
    expect(phrases.toSet(), hasLength(phrases.length));
  });

  test('no phrase is about the tools this app was built with', () {
    final devTalk = RegExp(r'\b(FLUTTER|DART|WIDGET|PACKAGE|FRAMEWORK|REPOSITORY)\b');
    final wrong = phrases.where(devTalk.hasMatch).toList();
    expect(wrong, isEmpty, reason: 'developer filler: $wrong');
  });

  test('every phrase is typeable and long enough to measure', () {
    for (final phrase in phrases) {
      expect(RegExp(r'^[A-Z0-9 ]+$').hasMatch(phrase), isTrue,
          reason: 'not plain capitals: "$phrase"');
      expect(phrase.length, greaterThanOrEqualTo(20), reason: '"$phrase"');
      expect(phrase.length, lessThanOrEqualTo(70), reason: '"$phrase"');
      expect(phrase.trim(), phrase);
    }
  });

  test('the words-per-minute formula still measures a real minute', () {
    // 300 characters in 60 seconds is 60 words per minute by the standard
    // "five characters is a word" convention.
    expect(engine.calculateWPM(300, 60), closeTo(60, 0.001));
    expect(engine.calculateWPM(300, 0), 0);
    expect(engine.countCorrectChars('ABCDE', 'ABCXY'), 3);
  });
}
