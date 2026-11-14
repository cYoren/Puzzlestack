import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/compound_connect/compound_connect_engine.dart';

/// Fifteen tasks, one per run, and the wrong buttons came from the same fifteen.
/// Worse than the repetition: two tasks sharing a prefix would make a real word
/// the game calls wrong, so the prefix has to be the unique key of the pool.
void main() {
  final engine = CompoundConnectEngine();
  final tasks = engine.tasks;

  test('the pool outlasts a session', () {
    expect(tasks.length, greaterThanOrEqualTo(30));
  });

  test('each task really is its two halves', () {
    for (final task in tasks) {
      expect('${task.prefix}${task.suffix}', task.result,
          reason: '${task.prefix} + ${task.suffix} is not ${task.result}');
      expect(task.prefix, isNotEmpty);
      expect(task.suffix, isNotEmpty);
      expect(RegExp(r'^[A-Z]+$').hasMatch(task.result), isTrue, reason: task.result);
    }
  });

  test('one answer per prefix, and no word twice', () {
    final prefixes = tasks.map((task) => task.prefix).toList();
    final results = tasks.map((task) => task.result).toList();
    expect(prefixes.toSet(), hasLength(prefixes.length),
        reason: 'a prefix with two answers is a task the player cannot win: '
            '${_duplicates(prefixes)}');
    expect(results.toSet(), hasLength(results.length));
  });

  test('a round offers four distinct halves, one of them right', () {
    for (var i = 0; i < 300; i++) {
      final task = engine.getRandomTask();
      final options = engine.getOptions(task);
      expect(options, hasLength(4));
      expect(options.toSet(), hasLength(4),
          reason: 'duplicate button for ${task.result}: $options');
      expect(options, contains(task.suffix));
      for (final other in options.where((o) => o != task.suffix)) {
        expect(other, isNot(task.suffix));
      }
    }
  });
}

List<String> _duplicates(List<String> values) {
  final seen = <String>{};
  final twice = <String>{};
  for (final value in values) {
    if (!seen.add(value)) twice.add(value);
  }
  return twice.toList();
}
