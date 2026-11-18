import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/conundrum_anagram/conundrum_anagram_engine.dart';

void main() {
  group('ConundrumAnagramEngine', () {
    test('generateRound always scrambles 9-letter words from expanded pool', () {
      final seenSolutions = <String>{};
      final rng = Random(42);
      for (int i = 0; i < 40; i++) {
        final round = ConundrumAnagramEngine.generateRound(random: rng);
        expect(round.solution.length, 9);
        expect(round.scrambled.length, 9);
        expect(round.scrambled, isNot(equals(round.solution)));
        seenSolutions.add(round.solution);
      }
      expect(seenSolutions.length, greaterThan(12));
    });
  });
}
