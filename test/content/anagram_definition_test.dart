import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/anagram_definition/anagram_definition_engine.dart';

/// Ten tasks, one per run. The screen shows a scramble and the definition of
/// the answer, so the only thing that makes the puzzle fair is that the two are
/// the same letters: no player can solve a scramble that does not unscramble
/// into the word being described.
void main() {
  final engine = AnagramDefinitionEngine();
  final tasks = engine.tasks;

  String letters(String word) {
    final chars = word.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '').split('');
    chars.sort();
    return chars.join();
  }

  test('the pool outlasts a session', () {
    expect(tasks.length, greaterThanOrEqualTo(30));
  });

  test('every scramble is an anagram of its own answer', () {
    for (final task in tasks) {
      expect(letters(task.scrambled), letters(task.target),
          reason: '${task.scrambled} does not unscramble into ${task.target}');
      expect(task.scrambled.toUpperCase(), isNot(task.target.toUpperCase()),
          reason: '${task.target} is shown unscrambled');
    }
  });

  test('no answer is asked twice', () {
    final targets = tasks.map((task) => task.target.toUpperCase());
    expect(targets.toSet(), hasLength(tasks.length));
  });

  test('every task carries a definition of its own answer', () {
    for (final task in tasks) {
      expect(task.definition.trim(), isNotEmpty, reason: task.target);
      expect(task.definition.trim().endsWith('.'), isTrue,
          reason: '${task.target}: "${task.definition}"');
      // The definition must not contain the answer, or the puzzle is a copy.
      expect(task.definition.toUpperCase(), isNot(contains(task.target.toUpperCase())),
          reason: '${task.target} appears in its own definition');
    }
    final definitions = tasks.map((task) => task.definition.trim().toLowerCase());
    expect(definitions.toSet(), hasLength(tasks.length));
  });

  test('the answer check ignores case and spacing', () {
    expect(engine.checkAnswer('leader', 'LEADER'), isTrue);
    expect(engine.checkAnswer('dirty room', 'DIRTY ROOM'), isTrue);
    expect(engine.checkAnswer('leadre', 'LEADER'), isFalse);
  });
}
