import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/pangram_sprint/pangram_sprint_engine.dart';

/// The win check is "these letters cover the alphabet", so a board with 25
/// distinct letters is a board that can never be won. The audit found one
/// (`...balthazar bolden...`, no `f`). Board 4 is now a real pangram and the
/// engine filters through `isPangram`; this test keeps both true.
void main() {
  final engine = PangramSprintEngine();

  test('every board is a pangram', () {
    final dead = [
      for (final task in engine.tasks)
        if (!engine.isPangram(task.sentence)) task.sentence,
    ];
    expect(dead, isEmpty, reason: 'unwinnable boards: ${dead.join(' | ')}');
  });

  test('the words of a board spell its sentence', () {
    for (final task in engine.tasks) {
      final joined = task.words.join(' ');
      expect(
        joined.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''),
        task.sentence.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''),
      );
    }
  });

  test('a dealt board is always one the player can finish', () {
    final dealt = <String>{};
    for (var i = 0; i < 200; i++) {
      final task = engine.getRandomTask();
      dealt.add(task.sentence);
      expect(engine.isPangram(task.sentence), isTrue);
    }
    expect(dealt, isNotEmpty);
  });

  test('isPangram rejects the board the audit found', () {
    expect(
      engine.isPangram(
          'How vexingly quick balthazar bolden jumps gazing'),
      isFalse,
    );
  });
}
