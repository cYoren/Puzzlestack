import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/netslide/netslide_engine.dart';

void main() {
  const engine = NetEngine();

  group('generator', () {
    for (final difficulty in NetDifficulty.values) {
      test('${difficulty.name}: 20 boards, each undone by its own slides', () {
        final rng = Random(difficulty.index + 83);
        for (var i = 0; i < 20; i++) {
          final puzzle = engine.generate(difficulty, random: rng);
          final where = '${difficulty.name} board $i';

          expect(puzzle.rows, difficulty.rows);
          expect(puzzle.cols, difficulty.cols);
          expect(puzzle.cellCount.isEven, isTrue,
              reason: '$where: a Hamiltonian cycle needs an even cell count');

          // The target board is a win: every pipe meets a pipe.
          final target = NetPuzzle(
            rows: puzzle.rows,
            cols: puzzle.cols,
            masks: puzzle.solvedMasks,
            solvedMasks: puzzle.solvedMasks,
            walls: puzzle.walls,
            scrambles: 0,
          );
          expect(engine.isSolved(target, puzzle.solvedMasks), isTrue,
              reason: '$where: the solved board is not solved');
          expect(engine.isSolved(puzzle, puzzle.masks), isFalse,
              reason: '$where: the scramble left the board solved');

          // Every cell has two pipes: the loop enters and leaves everywhere.
          for (var cell = 0; cell < puzzle.cellCount; cell++) {
            final mask = puzzle.solvedMasks[cell];
            var bits = 0;
            for (var bit = 0; bit < 4; bit++) {
              if (mask & (1 << bit) != 0) bits++;
            }
            expect(bits, 2, reason: '$where: cell $cell has $bits pipes');
          }

          // Undo the scramble, and the board is solved. This is the proof that a
          // player can finish it, not a hope about the construction.
          var masks = [...puzzle.masks];
          final moves = puzzle.scrambleMoves;
          expect(moves.length, puzzle.scrambles);
          for (final move in moves.reversed) {
            final next = engine.slide(puzzle, masks,
                row: move.row, index: move.index, forward: !move.forward);
            expect(next, isNotNull,
                reason: '$where: the reverse of a legal slide was refused');
            masks = next!;
          }
          expect(masks, puzzle.solvedMasks,
              reason: '$where: undoing the scramble did not restore the board');
          expect(engine.isSolved(puzzle, masks), isTrue);
        }
      });
    }
  });

  group('rules', () {
    test('a slide is a cycle, so sliding one way round restores the line', () {
      final puzzle = engine.generate(NetDifficulty.easy, random: Random(3));
      var masks = [...puzzle.masks];
      final before = [...masks];
      // Find a row the barriers allow to slide at all.
      final row = List.generate(puzzle.rows, (r) => r).firstWhere(
        (r) => engine.slide(puzzle, masks, row: true, index: r, forward: true) != null,
        orElse: () => -1,
      );
      expect(row, isNot(-1), reason: 'no row can slide');
      for (var i = 0; i < puzzle.cols; i++) {
        masks = engine.slide(puzzle, masks, row: true, index: row, forward: true)!;
      }
      expect(masks, before, reason: 'a row slid back to itself in ${puzzle.cols} steps');
    });

    test('a walled row cannot slide', () {
      final puzzle = engine.generate(NetDifficulty.hard, random: Random(5));
      var checked = 0;
      for (var row = 0; row < puzzle.rows; row++) {
        var walled = false;
        for (var col = 0; col + 1 < puzzle.cols; col++) {
          if (puzzle.hasWall(row * puzzle.cols + col, NetDirection.east)) {
            walled = true;
          }
        }
        if (!walled) continue;
        checked++;
        expect(
          engine.slide(puzzle, puzzle.masks, row: true, index: row, forward: true),
          isNull,
          reason: 'row $row has a wall but slid anyway',
        );
      }
      expect(checked, greaterThan(0), reason: 'this board has no walled rows');
    });

    test('half a pipe is not a pipe', () {
      final puzzle = engine.generate(NetDifficulty.easy, random: Random(7));
      final masks = [...puzzle.solvedMasks];
      // Break one pipe by removing a single half-edge.
      final cell = masks.indexWhere((mask) => mask != 0);
      masks[cell] = masks[cell] & ~NetBits.east;
      expect(engine.isSolved(puzzle, masks), isFalse);
    });
  });

  group('hint', () {
    test('suggests a slide that joins at least one more pipe', () {
      final puzzle = engine.generate(NetDifficulty.medium, random: Random(11));
      final hint = engine.hint(puzzle, puzzle.masks);
      expect(hint, isNotNull, reason: 'no hint on a scrambled board');
      final next = engine.slide(puzzle, puzzle.masks,
          row: hint!.row, index: hint.index, forward: hint.forward);
      expect(next, isNotNull);
      expect(engine.isSolved(puzzle, next!), isFalse);
    });

    test('has nothing to suggest on a solved board', () {
      final puzzle = engine.generate(NetDifficulty.easy, random: Random(13));
      expect(engine.hint(puzzle, puzzle.solvedMasks), isNull);
    });
  });
}
