import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/rome/rome_engine.dart';
import 'package:puzzle/ui/features/games/rome/rome_puzzle.dart';

/// The content rule for Rome: a dealt board is an arrow field whose chains all
/// end at a goal, cut into outlines that hold no repeated arrow, with a few of
/// its arrows printed. A board that broke any of that would look normal and play
/// wrong — the failure no layout test can catch.
///
/// Everything here is checked with its own arithmetic, not through the puzzle's
/// own helpers: a checker that asks the code under test what a step is can only
/// ever agree with it.
void main() {
  const engine = RomeEngine();

  final deals = <String, RomePuzzle>{};

  RomePuzzle deal(RomeSize size, int seed) => deals.putIfAbsent(
        '${size.name}/$seed',
        () => engine.generate(size, random: Random(seed)),
      );

  /// The cell one step from [cell] in [arrow], or null off the board.
  int? step(RomePuzzle puzzle, int cell, int arrow) {
    final n = puzzle.n;
    final row = cell ~/ n + kRomeSteps[arrow][1];
    final col = cell % n + kRomeSteps[arrow][0];
    if (row < 0 || row >= n) return null;
    if (col < 0 || col >= n) return null;
    return row * n + col;
  }

  test('every chain in the answer arrives at a goal, and never loops', () {
    for (final size in RomeSize.values) {
      for (var seed = 0; seed < 2; seed++) {
        final puzzle = deal(size, 100 + seed);
        final values = puzzle.solution;
        for (var start = 0; start < puzzle.cellCount; start++) {
          if (puzzle.goals.contains(start)) continue;
          var cell = start;
          final walked = <int>{};
          while (!puzzle.goals.contains(cell)) {
            expect(walked.add(cell), isTrue,
                reason: '${size.name} seed $seed loops through $cell');
            final arrow = values[cell];
            expect(arrow, inInclusiveRange(kRomeUp, kRomeLeft),
                reason: '${size.name} cell $cell holds $arrow');
            final next = step(puzzle, cell, arrow);
            expect(next, isNotNull,
                reason: '${size.name} cell $cell points off the board');
            cell = next!;
          }
        }
      }
    }
  });

  test('no area repeats an arrow, and no area is bigger than the arrows', () {
    for (final size in RomeSize.values) {
      for (var seed = 0; seed < 2; seed++) {
        final puzzle = deal(size, 100 + seed);
        final areas = <int, List<int>>{};
        for (var cell = 0; cell < puzzle.cellCount; cell++) {
          (areas[puzzle.areas[cell]] ??= []).add(cell);
        }
        expect(puzzle.areas.toSet(), hasLength(areas.length),
            reason: 'the area ids have a hole in them');
        for (final entry in areas.entries) {
          final cells = entry.value;
          expect(cells.length, lessThanOrEqualTo(4),
              reason:
                  '${size.name} area ${entry.key} has ${cells.length} cells');
          final arrows = [
            for (final cell in cells)
              if (!puzzle.goals.contains(cell)) puzzle.solution[cell]
          ];
          expect(arrows.toSet(), hasLength(arrows.length),
              reason:
                  '${size.name} area ${entry.key} repeats an arrow: $arrows');
        }
      }
    }
  });

  test('a printed arrow is the answer, and a goal is never printed', () {
    for (final size in RomeSize.values) {
      for (var seed = 0; seed < 2; seed++) {
        final puzzle = deal(size, 100 + seed);
        for (var cell = 0; cell < puzzle.cellCount; cell++) {
          final given = puzzle.given(cell);
          if (given == kRomeNoGiven) continue;
          expect(puzzle.goals, isNot(contains(cell)),
              reason: '${size.name} prints an arrow in goal $cell');
          expect(given, inInclusiveRange(kRomeUp, kRomeLeft));
          expect(given, puzzle.solution[cell],
              reason: '${size.name} cell $cell prints $given, '
                  'the answer is ${puzzle.solution[cell]}');
        }
      }
    }
  });

  test('the board leaves work to do, and every goal is circled', () {
    for (final size in RomeSize.values) {
      for (var seed = 0; seed < 2; seed++) {
        final puzzle = deal(size, 100 + seed);
        final arrows = puzzle.cellCount - puzzle.goals.length;
        final printed =
            puzzle.givens.where((given) => given != kRomeNoGiven).length;
        expect(puzzle.goals, isNotEmpty, reason: size.name);
        expect(printed, greaterThan(0),
            reason: '${size.name} prints nothing, so it is all outlines and '
                'circles and no information');
        expect(printed, lessThan(arrows),
            reason: '${size.name} prints every arrow: $printed of $arrows');
      }
    }
  });

  test('two deals are two boards', () {
    // A generator that answered with the same board every time would pass every
    // rule check above, so the variety is a content rule of its own.
    for (final size in RomeSize.values) {
      final one = deal(size, 11);
      final two = deal(size, 12);
      expect(one.solution, isNot(two.solution), reason: size.name);
    }
  });

  test('the deal is proved: one answer, and the rules reach it', () {
    for (final size in RomeSize.values) {
      final puzzle = deal(size, 100);
      expect(engine.count(puzzle), 1, reason: '${size.name} is ambiguous');
      expect(engine.levelOf(puzzle), inInclusiveRange(1, 2),
          reason: '${size.name} needs a guess');
    }
  });
}
