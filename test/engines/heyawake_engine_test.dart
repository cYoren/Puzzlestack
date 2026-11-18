import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/heyawake/heyawake_engine.dart';

void main() {
  group('HeyawakeEngine', () {
    test('generatePuzzle covers all grid cells in rooms and proves unique', () {
      final rng = Random(42);
      for (int i = 0; i < 15; i++) {
        final puzzle = HeyawakeEngine.generatePuzzle(random: rng);
        expect(puzzle.size, 5);
        for (int r = 0; r < puzzle.size; r++) {
          for (int c = 0; c < puzzle.size; c++) {
            final roomsContainingCell =
                puzzle.rooms.where((rm) => rm.contains(r, c));
            expect(
              roomsContainingCell.length,
              1,
              reason: 'Cell ($r, $c) must be contained in exactly one room',
            );
          }
        }
        expect(
          HeyawakeEngine.countSolutions(puzzle.rooms, puzzle.size),
          1,
          reason: 'Board $i must have a unique solution',
        );
      }
    });

    test('isSolved accepts valid grid and rejects 3-room white line', () {
      final rooms = [
        HeyawakeRoom(id: 0, startR: 0, startC: 0, endR: 2, endC: 0, clue: 1),
        HeyawakeRoom(id: 1, startR: 0, startC: 1, endR: 1, endC: 2),
        HeyawakeRoom(id: 2, startR: 3, startC: 0, endR: 4, endC: 0, clue: 0),
        HeyawakeRoom(id: 3, startR: 0, startC: 4, endR: 1, endC: 4, clue: 1),
        HeyawakeRoom(id: 4, startR: 2, startC: 4, endR: 4, endC: 4, clue: 2),
        HeyawakeRoom(id: 5, startR: 0, startC: 3, endR: 4, endC: 3),
        HeyawakeRoom(id: 6, startR: 2, startC: 1, endR: 4, endC: 2),
      ];
      final valid = List.generate(
        5,
        (_) => List.generate(5, (_) => HeyawakeCellState.white),
      );
      valid[0][1] = HeyawakeCellState.black;
      valid[0][4] = HeyawakeCellState.black;
      valid[1][2] = HeyawakeCellState.black;
      valid[2][0] = HeyawakeCellState.black;
      valid[2][4] = HeyawakeCellState.black;
      valid[3][2] = HeyawakeCellState.black; // breaks row 3 across rooms 2,6,5,4
      valid[4][1] = HeyawakeCellState.black;
      valid[4][4] = HeyawakeCellState.black;
      expect(HeyawakeEngine.isSolved(valid, rooms, 5), isTrue);

      // Turning (3,2) white makes row 3 an unbroken white line across rooms
      // 2 -> 6 -> 5 -> 4, violating Heyawake's 3-room orthogonal white-line rule
      // while clues, connectivity, and non-adjacency all remain valid.
      final threeRoomLine = List.generate(
        5,
        (r) => List<HeyawakeCellState>.from(valid[r]),
      );
      threeRoomLine[3][2] = HeyawakeCellState.white;
      expect(HeyawakeEngine.isSolved(threeRoomLine, rooms, 5), isFalse);
    });
  });
}
