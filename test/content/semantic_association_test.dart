import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/semantic_association/semantic_association_screen.dart';

/// Eight puzzles, one per run: the ninth round was the first puzzle again. The
/// game is "three clues, one answer", so the table is the whole product.
void main() {
  final puzzles = semanticAssociationPool;

  test('the pool outlasts a session', () {
    expect(puzzles.length, greaterThanOrEqualTo(30));
  });

  test('every puzzle is three clues for one word', () {
    for (final puzzle in puzzles) {
      expect(puzzle.clues, hasLength(3), reason: puzzle.answer);
      expect(RegExp(r'^[A-Z]+$').hasMatch(puzzle.answer), isTrue,
          reason: '${puzzle.answer} is not a plain word');
      for (final clue in puzzle.clues) {
        expect(clue.trim(), isNotEmpty, reason: puzzle.answer);
        // A clue that repeats the answer is not a clue.
        expect(clue.toUpperCase(), isNot(puzzle.answer),
            reason: '${puzzle.answer} is given away by its own clue');
      }
      expect(puzzle.clues.toSet(), hasLength(3),
          reason: '${puzzle.answer} has a repeat clue');
    }
  });

  test('no answer is asked twice', () {
    final answers = puzzles.map((puzzle) => puzzle.answer).toList();
    expect(answers.toSet(), hasLength(answers.length));
  });
}
