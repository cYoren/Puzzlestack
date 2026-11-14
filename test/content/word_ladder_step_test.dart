import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/word_ladder_step/word_ladder_step_engine.dart';

/// Eight ladders, one per run: the ninth round was the first ladder again. The
/// game promises one letter changes per step, which is a rule a test can walk.
void main() {
  final ladders = WordLadderStepEngine.ladders;

  int distance(String a, String b) {
    var changes = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) changes++;
    }
    return changes;
  }

  test('the pool outlasts a session', () {
    expect(ladders.length, greaterThanOrEqualTo(30));
  });

  test('every ladder is three words of one length', () {
    for (final ladder in ladders) {
      expect(ladder, hasLength(3));
      expect(ladder.map((word) => word.length).toSet(), hasLength(1),
          reason: '$ladder mixes word lengths');
      for (final word in ladder) {
        expect(RegExp(r'^[A-Z]+$').hasMatch(word), isTrue, reason: word);
      }
    }
  });

  test('each step changes exactly one letter', () {
    for (final ladder in ladders) {
      expect(distance(ladder[0], ladder[1]), 1,
          reason: '${ladder[0]} -> ${ladder[1]} is not one letter');
      expect(distance(ladder[1], ladder[2]), 1,
          reason: '${ladder[1]} -> ${ladder[2]} is not one letter');
      expect(ladder[0], isNot(ladder[2]),
          reason: '$ladder ends where it started');
      expect(ladder.toSet(), hasLength(3));
    }
  });

  test('no ladder is asked twice', () {
    // A word may appear in two ladders (WORD ends two of them); that is a
    // different puzzle, not a duplicate.
    final keys = ladders.map((ladder) => ladder.join('>')).toList();
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('a question asks for the middle word and offers four choices', () {
    for (var i = 0; i < 200; i++) {
      final question = WordLadderStepEngine.generateQuestion();
      final ladder = ladders.firstWhere((candidate) =>
          candidate[0] == question.startWord &&
          candidate[2] == question.endWord);
      expect(question.correctMiddleWord, ladder[1]);
      expect(question.endWord, ladder[2]);
      expect(question.choices, hasLength(4));
      expect(question.choices.toSet(), hasLength(4));
      expect(question.choices, contains(ladder[1]));
      // A wrong answer of another length gives itself away, so the choices are
      // same-length middles -- except on the only three-letter ladder, where
      // there are not three others and the pool has to be topped up.
      final sameLengthOthers = ladders
          .map((candidate) => candidate[1])
          .where((word) =>
              word.length == ladder[1].length && word != ladder[1])
          .toSet();
      if (sameLengthOthers.length >= 3) {
        for (final choice in question.choices) {
          expect(choice.length, ladder[1].length,
              reason: 'choice $choice gives away the answer by its length');
        }
      }
    }
  });
}
