import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/crossing/crossing_engine.dart';
import 'package:puzzle/ui/features/games/crossing/crossing_puzzle.dart';

/// The content rule for Crossing: every dealt board is a skeleton of runs, and
/// the number list is exactly what those runs read in the answer.
///
/// A list that is one number short, or a run whose end touches another run, makes
/// a board that looks normal and cannot be finished: no layout test can see that,
/// and no player can. The checks here are written from the outside — they look at
/// the cells and the answer, not at how the engine built them.
void main() {
  const engine = CrossingEngine();

  test('no two runs in one direction touch or overlap', () {
    // Two runs of the same direction that share a cell would be one cell holding
    // two members. Two that touch end to end would read as a single longer
    // number, and the two runs would be one run: the board must not offer them.
    final rng = Random(31);
    for (final size in CrossingSize.values) {
      for (var deal = 0; deal < 2; deal++) {
        final puzzle = engine.generate(size, random: rng);
        for (var a = 0; a < puzzle.runCount; a++) {
          for (var b = a + 1; b < puzzle.runCount; b++) {
            if (puzzle.runs[a].horizontal != puzzle.runs[b].horizontal) {
              continue;
            }
            final cellsA = puzzle.runCells(a).toSet();
            final cellsB = puzzle.runCells(b).toSet();
            expect(cellsA.intersection(cellsB), isEmpty,
                reason: '${size.name}: runs $a and $b share a cell');
            final horizontal = puzzle.runs[a].horizontal;
            for (final cell in cellsA) {
              final next = horizontal ? cell + 1 : cell + puzzle.n;
              final before = horizontal ? cell - 1 : cell - puzzle.n;
              if (horizontal && cell % puzzle.n == puzzle.n - 1) continue;
              expect(cellsB.contains(next) && cellsA.contains(next), isFalse,
                  reason: '${size.name}: runs $a and $b touch end to end');
              expect(cellsB.contains(before), isFalse,
                  reason: '${size.name}: runs $a and $b touch end to end');
            }
          }
        }
      }
    }
  });

  test('a crossing is one cell, never two', () {
    // Two numbers meet in a cell or they do not meet. Two shared cells would mean
    // two numbers running side by side, which is not a crossing.
    final rng = Random(32);
    for (final size in CrossingSize.values) {
      final puzzle = engine.generate(size, random: rng);
      for (var a = 0; a < puzzle.runCount; a++) {
        for (var b = a + 1; b < puzzle.runCount; b++) {
          if (puzzle.runs[a].horizontal == puzzle.runs[b].horizontal) continue;
          final shared = puzzle
              .runCells(a)
              .toSet()
              .intersection(puzzle.runCells(b).toSet());
          expect(shared.length, lessThanOrEqualTo(1),
              reason: '${size.name}: runs $a and $b share $shared');
        }
      }
    }
  });

  test('every run reads a listed number, and every number is used once', () {
    final rng = Random(33);
    for (final size in CrossingSize.values) {
      final puzzle = engine.generate(size, random: rng);
      final used = <String>{};
      for (var run = 0; run < puzzle.runCount; run++) {
        final text = puzzle.answerText(run);
        expect(puzzle.numbers, contains(text),
            reason:
                '${size.name}: run $run reads $text, which is not a number');
        expect(used.add(text), isTrue,
            reason: '${size.name}: $text is used twice');
      }
      expect(used, puzzle.numbers.toSet(), reason: size.name);
      expect(puzzle.numbers, hasLength(puzzle.runCount),
          reason: '${size.name}: one number per run, or the list is a lie');
    }
  });

  test('no cell holds a digit outside a placement', () {
    final rng = Random(34);
    for (final size in CrossingSize.values) {
      final puzzle = engine.generate(size, random: rng);
      final inRun = <int>{
        for (var run = 0; run < puzzle.runCount; run++) ...puzzle.runCells(run)
      };
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        final value = puzzle.solution[cell];
        if (inRun.contains(cell)) {
          expect(value, inInclusiveRange(1, 9),
              reason: '${size.name}: a run cell at $cell holds no digit');
        } else {
          expect(puzzle.isWall(cell), isTrue);
          expect(value, kCrossingEmpty,
              reason: '${size.name}: a wall at $cell holds a digit');
        }
      }
    }
  });

  test('the numbers are short, distinct, and all digits 1 to 9', () {
    final rng = Random(35);
    for (final size in CrossingSize.values) {
      final puzzle = engine.generate(size, random: rng);
      expect(puzzle.numbers.length,
          inInclusiveRange(size.minNumbers, size.maxNumbers),
          reason: size.name);
      expect(puzzle.numbers.toSet(), hasLength(puzzle.numbers.length),
          reason: '${size.name} listed a number twice');
      for (final number in puzzle.numbers) {
        expect(number.length, inInclusiveRange(2, 3), reason: number);
        for (final digit in number.split('')) {
          expect(int.parse(digit), inInclusiveRange(1, 9),
              reason: '${size.name} listed $number');
        }
      }
    }
  });

  test('the run graph is one piece, so no number floats on its own', () {
    final rng = Random(36);
    for (final size in CrossingSize.values) {
      final puzzle = engine.generate(size, random: rng);
      // Runs are nodes; a crossing is an edge. A component of one would be a
      // number the list could be moved around without touching anything else.
      final neighbours = List.generate(puzzle.runCount, (_) => <int>{});
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        final here = puzzle.runsAt(cell);
        if (here.length < 2) continue;
        neighbours[here[0].$1].add(here[1].$1);
        neighbours[here[1].$1].add(here[0].$1);
      }
      final seen = <int>{0};
      final queue = [0];
      while (queue.isNotEmpty) {
        for (final next in neighbours[queue.removeLast()]) {
          if (seen.add(next)) queue.add(next);
        }
      }
      expect(seen, hasLength(puzzle.runCount),
          reason: '${size.name}: the runs are in pieces');
      for (var run = 0; run < puzzle.runCount; run++) {
        expect(neighbours[run], isNotEmpty,
            reason: '${size.name}: run $run crosses nothing');
      }
    }
  });

  test('the list is a puzzle, not the answer printed as a list', () {
    final rng = Random(37);
    for (final size in CrossingSize.values) {
      final puzzle = engine.generate(size, random: rng);
      // The board starts blank, so the list and the skeleton are all the player
      // is given: they have to pin the grid down to one filling.
      expect(engine.count(puzzle), 1, reason: '${size.name} is ambiguous');
      expect(engine.levelOf(puzzle), isNotNull,
          reason: '${size.name} cannot be reasoned to');
      expect(puzzle.runCount, greaterThan(1), reason: size.name);
    }
  });
}
