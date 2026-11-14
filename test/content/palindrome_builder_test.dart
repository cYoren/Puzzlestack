import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/palindrome_builder/palindrome_builder_engine.dart';

/// Thirteen tasks, one per run: the whole game was thirteen rounds. The rule is
/// the word, so the test can insist on it: fill the gap and it must read the
/// same backwards.
void main() {
  final engine = PalindromeBuilderEngine();
  final tasks = engine.tasks;

  // The gap is one dot per missing letter, so the whole run gets the answer.
  String filled(PalindromeTask task) =>
      task.display.replaceAll(RegExp(r'\.+'), task.solution).toUpperCase();

  test('the pool outlasts a session', () {
    expect(tasks.length, greaterThanOrEqualTo(24));
  });

  test('every answer reads the same in both directions', () {
    for (final task in tasks) {
      final word = filled(task);
      expect(word, word.split('').reversed.join(),
          reason: '$word is not a palindrome');
      expect(word.length, task.incomplete.length, reason: task.incomplete);
    }
  });

  test('the gap is one gap, and the dots match the letters that fill it', () {
    for (final task in tasks) {
      expect('_'.allMatches(task.incomplete).length, task.solution.length,
          reason: '${task.incomplete} has a gap the answer does not fill');
      expect('.'.allMatches(task.display).length, task.solution.length,
          reason: '${task.display} renders a gap of the wrong size');
      expect(task.solution.toUpperCase(), isNot(contains('_')),
          reason: 'the answer must not be part of the printed word');
      // The visible letters have to survive the fill, or the word on screen is
      // not the word being completed.
      for (final letter in task.incomplete.replaceAll('_', ' ').split(' ')) {
        expect(wordOf(task), contains(letter), reason: letter);
      }
    }
  });

  test('no palindrome is asked twice', () {
    final words = tasks.map(filled).toList();
    expect(words.toSet(), hasLength(words.length));
  });

  test('a single letter answer stays a single letter', () {
    // The one-letter tasks are three-letter words (M_M), where a two-letter
    // answer would leave the board six cells for five letters.
    for (final task in tasks.where((task) => task.solution.length == 1)) {
      expect(filled(task).length, 3, reason: task.display);
    }
  });
}

String wordOf(PalindromeTask task) =>
    task.display.replaceAll(RegExp(r'\.+'), task.solution).toUpperCase();
