import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/portmanteau_split/portmanteau_split_engine.dart';

/// Fourteen blends, one per run. A blend is a word and its two parents, so the
/// table can be checked rather than trusted: the parents have to be in it.
void main() {
  final engine = PortmanteauSplitEngine();
  final puzzles = engine.puzzles;

  int longestCommonRun(String a, String b) {
    var best = 0;
    for (var i = 0; i < a.length; i++) {
      for (var j = i + best + 1; j <= a.length; j++) {
        if (b.contains(a.substring(i, j))) {
          best = j - i;
        } else {
          break;
        }
      }
    }
    return best;
  }

  test('the pool outlasts a session', () {
    expect(puzzles.length, greaterThanOrEqualTo(30));
  });

  test('each blend is built out of the two words it names', () {
    for (final puzzle in puzzles) {
      final blend = puzzle.portmanteau;
      final fromFirst = longestCommonRun(blend, puzzle.word1);
      final fromSecond = longestCommonRun(blend, puzzle.word2);
      expect(fromFirst, greaterThanOrEqualTo(2),
          reason: '$blend shares nothing with ${puzzle.word1}');
      expect(fromSecond, greaterThanOrEqualTo(2),
          reason: '$blend shares nothing with ${puzzle.word2}');
      // The first letter is the head of word1 and the last is the tail of
      // word2, which is what makes a blend read as one word.
      expect(puzzle.word1.contains(blend[0]), isTrue,
          reason: '$blend does not start inside ${puzzle.word1}');
      expect(puzzle.word2.contains(blend[blend.length - 1]), isTrue,
          reason: '$blend does not end inside ${puzzle.word2}');
      // A blend is shorter than its parents concatenated; otherwise it is just
      // a compound with extra syllables.
      expect(blend.length, lessThan(puzzle.word1.length + puzzle.word2.length),
          reason: blend);
      expect(blend, isNot(puzzle.word1));
      expect(blend, isNot(puzzle.word2));
    }
  });

  test('no blend is asked twice', () {
    // Parent words may repeat: FREEMIUM and FREEGAN both come from FREE, and
    // that is a different puzzle, not a duplicate.
    final blends = puzzles.map((puzzle) => puzzle.portmanteau).toList();
    expect(blends.toSet(), hasLength(blends.length));
  });

  test('a puzzle offers both parents and no duplicates', () {
    for (var i = 0; i < 300; i++) {
      final puzzle = engine.generatePuzzle();
      // Six chips for two answers: the player picks the pair, not one word.
      expect(puzzle.options, hasLength(6));
      expect(puzzle.options.toSet(), hasLength(6), reason: puzzle.portmanteau);
      expect(puzzle.options, contains(puzzle.word1));
      expect(puzzle.options, contains(puzzle.word2));
      for (final option in puzzle.options) {
        expect(option, isNot(puzzle.portmanteau));
      }
    }
  });
}
