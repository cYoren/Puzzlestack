import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/definition_dash/definition_dash_engine.dart';

/// Ten pairs, one per run, and the wrong answers were those same ten. A player
/// saw every definition in the game twice inside ten rounds.
void main() {
  final engine = DefinitionDashEngine();
  final pairs = engine.pairs;

  test('the pool outlasts a session', () {
    expect(pairs.length, greaterThanOrEqualTo(30));
  });

  test('one definition per word, one word per definition', () {
    final words = pairs.map((pair) => pair.word.toUpperCase()).toList();
    final definitions = pairs.map((pair) => pair.definition.trim().toLowerCase()).toList();
    expect(words.toSet(), hasLength(words.length));
    expect(definitions.toSet(), hasLength(definitions.length));
  });

  test('every definition is a sentence about its own word', () {
    for (final pair in pairs) {
      expect(pair.definition.trim(), isNotEmpty, reason: pair.word);
      expect(pair.definition.trim().endsWith('.'), isTrue,
          reason: '${pair.word}: "${pair.definition}"');
      expect(pair.definition.toUpperCase(), isNot(contains(pair.word.toUpperCase())),
          reason: '${pair.word} gives itself away');
      expect(RegExp(r'^[A-Z]+$').hasMatch(pair.word), isTrue,
          reason: '${pair.word} is not a plain word');
    }
  });

  test('a puzzle offers four distinct definitions, one of them right', () {
    for (var i = 0; i < 300; i++) {
      final puzzle = engine.generatePuzzle();
      expect(puzzle.options, hasLength(4));
      expect(puzzle.options.toSet(), hasLength(4));
      expect(puzzle.options, contains(puzzle.correctDefinition));
      expect(pairs.map((pair) => pair.definition), contains(puzzle.correctDefinition));
      expect(pairs.map((pair) => pair.word), contains(puzzle.word));
    }
  });
}
