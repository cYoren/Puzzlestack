import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/cryptogram/cryptogram_engine.dart';

/// Six quotes, one per run: the third cryptogram was a repeat. A quote pool is
/// the cheapest content in the app, so there is no reason for it to be short.
void main() {
  final engine = CryptogramEngine();
  final quotes = engine.quotes;

  test('the pool outlasts a session', () {
    expect(quotes.length, greaterThanOrEqualTo(12));
    expect(quotes.toSet(), hasLength(quotes.length));
  });

  test('every quote fits the board and the cipher', () {
    for (final quote in quotes) {
      expect(RegExp(r'^[A-Z ]+$').hasMatch(quote), isTrue, reason: quote);
      expect(quote.length, greaterThanOrEqualTo(20), reason: quote);
      expect(quote.length, lessThanOrEqualTo(60), reason: quote);
      expect(quote.trim(), quote);
      // Four or more distinct letters, or the substitution has nothing to say.
      expect(quote.replaceAll(' ', '').split('').toSet().length,
          greaterThanOrEqualTo(4),
          reason: quote);
    }
  });

  test('a puzzle keeps the quote length and hides every letter', () {
    for (var i = 0; i < 50; i++) {
      final puzzle = engine.generatePuzzle();
      final original = puzzle['original'] as String;
      final encoded = puzzle['encoded'] as String;
      expect(encoded.length, original.length);
      expect(quotes, contains(original));
      for (var j = 0; j < original.length; j++) {
        // Spaces stay; a letter is never encoded as itself.
        if (original[j] == ' ') {
          expect(encoded[j], ' ');
        } else {
          expect(encoded[j], isNot(original[j]),
              reason: '${original[j]} encoded as itself in "$original"');
        }
      }
      // The cipher is a permutation: two letters never share an encoding.
      final mapping = <String, String>{};
      for (var j = 0; j < original.length; j++) {
        if (original[j] == ' ') continue;
        final previous = mapping[encoded[j]];
        expect(previous == null || previous == original[j], isTrue,
            reason: '${encoded[j]} decodes to two letters');
        mapping[encoded[j]] = original[j];
      }
      // And the solver's own win check accepts the mapping that produced it.
      expect(engine.checkWin(original, mapping, encoded), isTrue);
    }
  });
}
