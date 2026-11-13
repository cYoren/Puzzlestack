import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/norinori/norinori_engine.dart';

void main() {
  const engine = NorinoriEngine();

  test('a generated board is a partition of connected rooms', () {
    for (var seed = 0; seed < 20; seed++) {
      final puzzle = engine.generate(random: Random(seed));
      final size = puzzle.rows;

      final counts = List<int>.filled(puzzle.totalRooms, 0);
      for (final row in puzzle.roomIds) {
        expect(row.length, size);
        for (final id in row) {
          expect(id, inInclusiveRange(0, puzzle.totalRooms - 1));
          counts[id]++;
        }
      }
      expect(counts.every((count) => count >= 3), isTrue,
          reason: 'a room with two cells is solved before it is played');

      // Every room is one orthogonally connected region.
      for (var id = 0; id < puzzle.totalRooms; id++) {
        final cells = [
          for (var r = 0; r < size; r++)
            for (var c = 0; c < size; c++)
              if (puzzle.roomIds[r][c] == id) (r, c),
        ];
        final seen = <(int, int)>{cells.first};
        final queue = <(int, int)>[cells.first];
        while (queue.isNotEmpty) {
          final (r, c) = queue.removeLast();
          for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            final next = (r + dr, c + dc);
            if (cells.contains(next) && seen.add(next)) queue.add(next);
          }
        }
        expect(seen.length, cells.length, reason: 'room $id is split');
      }
    }
  });

  test('every generated board has exactly one answer', () {
    for (var seed = 0; seed < 12; seed++) {
      final puzzle = engine.generate(random: Random(seed));
      expect(engine.countSolutions(puzzle), 1, reason: 'seed $seed');
      expect(engine.isValid(puzzle, puzzle.solution), isTrue);
    }
  });

  test('the solution is the only valid shading among its neighbours', () {
    final puzzle = engine.generate(random: Random(7));
    final size = puzzle.rows;
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final flipped = [
          for (final line in puzzle.solution) List<bool>.from(line),
        ];
        flipped[row][col] = !flipped[row][col];
        expect(engine.isValid(puzzle, flipped), isFalse,
            reason: 'flipping ($row,$col) still wins');
      }
    }
  });

  test('a saved seed generates the same board twice', () {
    final a = engine.generate(random: Random(42));
    final b = engine.generate(random: Random(42));
    expect(a.roomIds, b.roomIds);
    expect(a.solution, b.solution);
  });
}
