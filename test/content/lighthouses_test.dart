import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/lighthouses/lighthouses_engine.dart';

/// The audit found the hardcoded fallback board had zero solutions under the
/// game's own no-touch rule: the one code path that exists for failure was the
/// one that was certainly wrong. The fallback is now a board the solver accepts,
/// and generation is held to the same standard.
void main() {
  final engine = LighthousesEngine();

  test('the fallback board has exactly one answer', () {
    final clues = LighthousesEngine.fallbackClues;
    expect(clues.length, 5);
    expect(engine.hasUniqueSolution(clues, 5), isTrue);
  });

  test('the fallback board is the shape the game expects', () {
    final board = engine.fallbackBoard();
    final clues = board['clues'] as List<List<int?>>;
    expect(clues, hasLength(5));
    for (final row in clues) {
      expect(row, hasLength(5));
    }
    expect(clues.expand((row) => row).where((clue) => clue != null).length, 5,
        reason: 'five lighthouses, one per clue');
  });

  test('the fallback is not the board the audit killed', () {
    final dead = [
      [null, null, null, null, 1],
      [null, 2, null, null, null],
      [null, null, null, 1, null],
      [2, null, null, null, null],
      [null, null, 2, null, null],
    ];
    expect(engine.hasUniqueSolution(dead, 5), isFalse);
  });

  test('200 generated boards are unique and come back playable', () {
    for (var i = 0; i < 200; i++) {
      final board = engine.generateLevel();
      final clues = board['clues'] as List<List<int?>>;
      expect(clues.length, 5, reason: 'board $i');
      expect(engine.hasUniqueSolution(clues, 5), isTrue, reason: 'board $i');
    }
  });

  test('generation is not silently returning the fallback every time', () {
    final shapes = <String>{};
    for (var i = 0; i < 40; i++) {
      final board = engine.generateLevel();
      shapes.add(
          (board['clues'] as List<List<int?>>).map((row) => row.join(',')).join('|'));
    }
    expect(shapes.length, greaterThan(5));
  });
}
