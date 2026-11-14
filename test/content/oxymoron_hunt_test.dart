import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/oxymoron_hunt/oxymoron_hunt_engine.dart';

/// Eighteen pairs, four per round: the fourth round was content the player had
/// already seen, and the wrong options came from the same eighteen.
void main() {
  final engine = OxymoronHuntEngine();
  final pairs = engine.allPairs;

  test('the pool outlasts a session', () {
    // Four pairs a round, so a dozen rounds needs three times that.
    expect(pairs.length, greaterThanOrEqualTo(40));
  });

  test('a pair is two different words, never the same word twice', () {
    for (final pair in pairs) {
      expect(pair.word1, isNot(pair.word2), reason: '${pair.word1}/${pair.word2}');
      expect(pair.word1.trim(), isNotEmpty);
      expect(pair.word2.trim(), isNotEmpty);
      expect(RegExp(r'^[A-Z]+$').hasMatch(pair.word1), isTrue, reason: pair.word1);
      expect(RegExp(r'^[A-Z]+$').hasMatch(pair.word2), isTrue, reason: pair.word2);
    }
  });

  test('no pair is listed twice, in either order', () {
    final seen = <String>{};
    for (final pair in pairs) {
      final words = [pair.word1, pair.word2]..sort();
      expect(seen.add(words.join('/')), isTrue,
          reason: '${pair.word1}/${pair.word2} is already in the table');
    }
  });

  test('a round deals four pairs and their eight words', () {
    for (var i = 0; i < 300; i++) {
      final puzzle = engine.generatePuzzle();
      expect(puzzle.pairs, hasLength(4));
      expect(puzzle.words, hasLength(8));
      expect(puzzle.words.toSet(), hasLength(8), reason: 'a word is dealt twice');
      final fromPairs = [
        for (final pair in puzzle.pairs) ...[pair.word1, pair.word2],
      ]..sort();
      final dealt = [...puzzle.words]..sort();
      expect(dealt, fromPairs, reason: 'the words are not the pairs\' words');
      for (final pair in puzzle.pairs) {
        expect(pairs, contains(pair));
      }
    }
  });
}
