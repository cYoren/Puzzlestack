import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/spoonerism_solver/spoonerism_solver_engine.dart';

/// Eleven tasks, one per run, and half of them were not spoonerisms at all: one
/// row was its own pair reversed, one offered the spoonerism on the card as a
/// wrong answer, and one swapped "SOUP OF THE DAY" with "DOUP OF THE SAY",
/// which is not a phrase in any language.
void main() {
  final engine = SpoonerismSolverEngine();
  final tasks = engine.tasks;

  String cluster(String word) {
    final match = RegExp(r'^[BCDFGHJKLMNPQRSTVWXYZ]*').firstMatch(word)!;
    return match.group(0)!;
  }

  String swapPair(String phrase, int i, int j) {
    final words = phrase.split(' ');
    final first = cluster(words[i]);
    final second = cluster(words[j]);
    words[i] = second + words[i].substring(first.length);
    words[j] = first + words[j].substring(second.length);
    return words.join(' ');
  }

  /// Every pair of words whose opening sounds could have been swapped.
  List<String> possibleSpoonerisms(String original) {
    final words = original.split(' ');
    final out = <String>[];
    for (var i = 0; i < words.length; i++) {
      for (var j = 0; j < words.length; j++) {
        if (i != j) out.add(swapPair(original, i, j));
      }
    }
    return out;
  }

  test('the pool outlasts a session', () {
    expect(tasks.length, greaterThanOrEqualTo(20));
  });

  test('every spoonerism really is its phrase with two sounds swapped', () {
    for (final task in tasks) {
      expect(possibleSpoonerisms(task.original), contains(task.spoonerism),
          reason: '"${task.spoonerism}" is not "${task.original}" with two '
              'opening sounds swapped');
      expect(task.spoonerism, isNot(task.original));
    }
  });

  test('no phrase and no spoonerism appears twice', () {
    final originals = tasks.map((task) => task.original).toList();
    final spoonerisms = tasks.map((task) => task.spoonerism).toList();
    expect(originals.toSet(), hasLength(originals.length));
    expect(spoonerisms.toSet(), hasLength(spoonerisms.length));
    // A row and its own reverse would be two cards with one answer.
    for (final task in tasks) {
      expect(originals.contains(task.spoonerism) &&
              spoonerisms.contains(task.original) &&
              task.spoonerism != task.original,
          isFalse,
          reason: '${task.original} and ${task.spoonerism} are each other');
    }
  });

  test('the options are three originals, one of them the answer', () {
    for (var i = 0; i < 200; i++) {
      final task = engine.getRandomTask();
      final options = engine.getOptions(task);
      expect(options, hasLength(3));
      expect(options.toSet(), hasLength(3));
      expect(options, contains(task.original));
      // The card shows the spoonerism, so it can never be one of the buttons.
      expect(options, isNot(contains(task.spoonerism)),
          reason: '${task.spoonerism} is offered as a wrong answer to itself');
    }
  });
}
