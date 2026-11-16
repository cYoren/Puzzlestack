import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/rome/rome_engine.dart';
import 'package:puzzle/ui/features/games/rome/rome_model.dart';
import 'package:puzzle/ui/features/games/rome/rome_provider.dart';
import 'package:puzzle/ui/features/games/rome/rome_puzzle.dart';

const engine = RomeEngine();

/// Dealing costs a few dozen milliseconds (three arrow fields per board, each
/// proved and stripped), so each size is dealt once and the tests share it.
final _dealt = <RomeSize, RomePuzzle>{};

RomePuzzle dealt(RomeSize size, {int seed = 0}) => _dealt.putIfAbsent(
      size,
      () => engine.generate(size, random: Random(seed + size.index)),
    );

/// The arrow that steps from [from] to [to], or null when they are not
/// neighbours. Written here rather than taken from the puzzle, so the checks
/// below do not ask the code under test what a step is.
int? _direction(RomePuzzle puzzle, int from, int to) {
  for (var arrow = kRomeUp; arrow <= kRomeLeft; arrow++) {
    if (puzzle.neighbour(from, arrow) == to) return arrow;
  }
  return null;
}

/// An independent reading of the game's rules: a chain is followed one arrow at
/// a time from the values themselves, with its own step arithmetic and its own
/// loop test.
///
/// This is the check the model cannot make about itself. If the rules are wrong
/// in the same way the puzzle is wrong, the search agrees with the puzzle and
/// both are wrong; this walks the board with a second pair of eyes.
bool plainChainsEnd(RomePuzzle puzzle, List<int> values) {
  final n = puzzle.n;
  final cells = puzzle.cellCount;
  for (var start = 0; start < cells; start++) {
    if (puzzle.isGoal(start)) continue;
    var cell = start;
    final seen = <int>{};
    while (!puzzle.isGoal(cell)) {
      if (!seen.add(cell)) return false;
      final arrow = values[cell];
      if (arrow < kRomeUp || arrow > kRomeLeft) return false;
      final row = cell ~/ n + kRomeSteps[arrow][1];
      final col = cell % n + kRomeSteps[arrow][0];
      if (row < 0 || row >= n || col < 0 || col >= n) return false;
      cell = row * n + col;
    }
  }
  return true;
}

void main() {
  group('Rome vocabularies', () {
    test('a goal, an absent given and an unwritten cell are three things', () {
      expect(kRomeGoal, 4);
      expect(kRomeNoGiven, -1);
      expect(kRomeBlank, -2);
      expect(<int>{kRomeGoal, kRomeNoGiven, kRomeBlank}, hasLength(3));
      // A goal is not an arrow, so the four arrows and the goal are five
      // different values and not four plus a sentinel.
      expect(kRomeGoal, kRomeArrowCount);
      // An arrow is 0..3 and a goal is 4, so every value the board can hold is
      // distinct from every sentinel.
      for (var arrow = kRomeUp; arrow <= kRomeLeft; arrow++) {
        expect(arrow, isNot(kRomeGoal));
        expect(arrow, isNot(kRomeNoGiven));
        expect(arrow, isNot(kRomeBlank));
      }
    });

    test('four arrows, no fifth', () {
      expect(kRomeArrowCount, 4);
      expect(kRomeSteps, hasLength(4));
      // No zero step: a cell never points at itself, which is why the smallest
      // loop this game can have is two cells.
      for (final step in kRomeSteps) {
        expect(step[0].abs() + step[1].abs(), 1);
      }
    });
  });

  group('RomeEngine', () {
    test('a dealt board obeys the rules of the game', () {
      for (final size in RomeSize.values) {
        final puzzle = dealt(size);
        final values = puzzle.solution;
        expect(values, hasLength(puzzle.cellCount), reason: size.name);
        // Exactly one value per cell: an arrow, or the goal's own value.
        for (var cell = 0; cell < puzzle.cellCount; cell++) {
          if (puzzle.isGoal(cell)) {
            expect(values[cell], kRomeGoal,
                reason: '${size.name} goal $cell holds ${values[cell]}');
          } else {
            expect(values[cell], inInclusiveRange(kRomeUp, kRomeLeft),
                reason: '${size.name} cell $cell holds ${values[cell]}');
          }
        }
        // Rule 1: no arrow twice in an area.
        for (var area = 0; area < puzzle.areaCount; area++) {
          final arrows = [
            for (final cell in puzzle.areaCells(area))
              if (!puzzle.isGoal(cell)) values[cell]
          ];
          expect(arrows.toSet(), hasLength(arrows.length),
              reason: '${size.name} area $area repeats an arrow: $arrows');
          expect(arrows.length, lessThanOrEqualTo(puzzle.maxArea));
        }
        // Rule 2: every chain ends at a goal, by a second implementation.
        expect(plainChainsEnd(puzzle, values), isTrue, reason: size.name);
        expect(puzzle.chainsEnd(values), isTrue, reason: size.name);
        expect(puzzle.isSolution(values), isTrue, reason: size.name);
      }
    });

    test('the printed arrows are the answer, not a clue read off something',
        () {
      for (final size in RomeSize.values) {
        final puzzle = dealt(size);
        for (var cell = 0; cell < puzzle.cellCount; cell++) {
          final given = puzzle.given(cell);
          if (given == kRomeNoGiven) continue;
          expect(puzzle.isGoal(cell), isFalse,
              reason: '${size.name} goal $cell has a printed arrow');
          expect(given, puzzle.solution[cell],
              reason: '${size.name} cell $cell prints $given, '
                  'the answer is ${puzzle.solution[cell]}');
        }
        // The board is a puzzle, not the answer: at least one arrow is the
        // player's, and at least one goal is circled.
        final printed =
            puzzle.givens.where((given) => given != kRomeNoGiven).length;
        final arrows = puzzle.cellCount - puzzle.goals.length;
        expect(puzzle.goals, isNotEmpty, reason: size.name);
        expect(printed, lessThan(arrows),
            reason: '${size.name} prints every arrow: $printed of $arrows');
      }
    });

    test('the areas are outlines a player can see', () {
      for (final size in RomeSize.values) {
        final puzzle = dealt(size);
        final seen = <int>{};
        for (var area = 0; area < puzzle.areaCount; area++) {
          final cells = puzzle.areaCells(area);
          expect(cells, isNotEmpty);
          expect(cells.length, lessThanOrEqualTo(puzzle.maxArea),
              reason: '${size.name} area $area has ${cells.length} cells');
          seen.addAll(cells);
          // Contiguous: every cell of an area is one step from another cell of
          // it, which is what makes the outline an outline and not a scatter.
          if (cells.length == 1) continue;
          final reached = <int>{cells.first};
          final queue = [cells.first];
          while (queue.isNotEmpty) {
            final cell = queue.removeLast();
            for (var arrow = kRomeUp; arrow <= kRomeLeft; arrow++) {
              final next = puzzle.neighbour(cell, arrow);
              if (next == null || !cells.contains(next)) continue;
              if (reached.add(next)) queue.add(next);
            }
          }
          expect(reached, hasLength(cells.length),
              reason: '${size.name} area $area is not one piece');
        }
        expect(seen, hasLength(puzzle.cellCount));
      }
    });

    test('the board has exactly one answer, at every size', () {
      for (final size in RomeSize.values) {
        expect(engine.count(dealt(size)), 1,
            reason: '${size.name} is ambiguous');
      }
    });

    test('the board can be finished without a guess, at every size', () {
      for (final size in RomeSize.values) {
        final level = engine.levelOf(dealt(size));
        expect(level, isNotNull, reason: '${size.name} needs a guess');
        // Level 1 is the scan (areas and edges), level 2 is chain reasoning.
        // There is no level 3 in this game, so anything else is a bug.
        expect(level, inInclusiveRange(1, 2), reason: size.name);
      }
    });

    test('a board with no printed arrows is not the answer', () {
      // The other side of the generator's claim: the printed arrows are what
      // pins the answer down. Without them the goals and outlines alone leave
      // several fillings, so a board that printed nothing would be ambiguous.
      final puzzle = dealt(RomeSize.small);
      final bare = RomePuzzle(
        size: puzzle.size,
        areas: puzzle.areas,
        goals: puzzle.goals,
        givens: List<int>.filled(puzzle.cellCount, kRomeNoGiven),
        solution: puzzle.solution,
      );
      expect(bare.isSolution(puzzle.solution), isTrue,
          reason: 'the answer still obeys the rules with nothing printed');
      expect(engine.count(bare), greaterThan(1));
      expect(engine.levelOf(bare), isNull,
          reason: 'the outlines and goals alone should not be enough');
    });

    test('the rule that walks a chain catches a loop, not just a bad goal', () {
      final puzzle = dealt(RomeSize.medium);
      // A board is legal only if every chain ends at a goal. Two neighbours
      // pointing at each other is the smallest loop there is, and it must be
      // refused by the writer's test and by the plain one.
      var refused = 0;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (puzzle.isGoal(cell)) continue;
        for (final other in [
          for (var arrow = kRomeUp; arrow <= kRomeLeft; arrow++)
            puzzle.neighbour(cell, arrow)
        ]) {
          if (other == null || puzzle.isGoal(other)) continue;
          final values = List<int>.from(puzzle.solution);
          final there = _direction(puzzle, cell, other);
          final back = _direction(puzzle, other, cell);
          if (there == null || back == null) continue;
          values[cell] = there;
          values[other] = back;
          expect(plainChainsEnd(puzzle, values), isFalse,
              reason: 'a two-cell loop at $cell/$other passed the plain check');
          expect(puzzle.isSolution(values), isFalse,
              reason: 'a two-cell loop at $cell/$other was called a solution');
          refused++;
        }
      }
      expect(refused, greaterThan(0));
    });

    test('the hint writes an arrow the answer agrees with, and advances', () {
      final puzzle = dealt(RomeSize.small, seed: 4);
      final values = [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          puzzle.isGoal(cell) ? kRomeGoal : kRomeBlank,
      ];
      var taken = 0;
      while (true) {
        final found = engine.hint(puzzle, values);
        if (found == null) break;
        expect(values[found.cell], kRomeBlank,
            reason: 'the hint picked a cell that is already written');
        expect(puzzle.isGoal(found.cell), isFalse,
            reason: 'a hint cannot write a goal');
        expect(found.arrow, puzzle.solution[found.cell],
            reason: 'the hint contradicts the answer');
        values[found.cell] = found.arrow;
        taken++;
        if (taken > puzzle.cellCount) fail('the hint never runs out');
      }
      expect(taken, greaterThan(0));
      // What the rules can prove is legal at every step, and filling the rest
      // from the answer finishes the board.
      expect(puzzle.isLegal(values), isTrue);
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        values[cell] = puzzle.solution[cell];
      }
      expect(engine.isSolved(puzzle, values), isTrue);
    });

    test('a repeated arrow in an area is a conflict, an empty cell is not', () {
      final puzzle = dealt(RomeSize.small, seed: 8);
      // An area with two arrow cells: writing the same arrow twice breaks rule
      // 1 and nothing else.
      var area = -1;
      for (var index = 0; index < puzzle.areaCount; index++) {
        final arrows = [
          for (final cell in puzzle.areaCells(index))
            if (!puzzle.isGoal(cell)) cell
        ];
        if (arrows.length >= 2) {
          area = index;
          break;
        }
      }
      expect(area, isNot(-1), reason: 'no area holds two arrows');
      final cells = [
        for (final cell in puzzle.areaCells(area))
          if (!puzzle.isGoal(cell)) cell
      ];
      final values = [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          puzzle.isGoal(cell) ? kRomeGoal : kRomeBlank,
      ];
      values[cells[0]] = puzzle.solution[cells[0]];
      values[cells[1]] = puzzle.solution[cells[0]];
      expect(puzzle.conflicts(values), contains(cells[0]));
      expect(puzzle.conflicts(values), contains(cells[1]));
      expect(puzzle.isLegal(values), isFalse);
      expect(engine.isSolved(puzzle, values), isFalse);

      // The same arrow once is legal, and an empty board accuses nobody.
      values[cells[1]] = kRomeBlank;
      expect(puzzle.conflicts(values), isEmpty);
      expect(puzzle.isLegal(values), isTrue);
      expect(puzzle.conflicts(List<int>.filled(puzzle.cellCount, kRomeBlank)),
          isEmpty);
    });

    test('an unfinished enumeration proves nothing', () {
      // Agreement among the first `limit` answers is not agreement among every
      // answer. A count that stopped at its limit must never hand out a forced
      // value, because nothing was proved about the answers it did not reach.
      final size = RomeSize.medium;
      final puzzle = dealt(size);
      final bare = RomePuzzle(
        size: size,
        areas: puzzle.areas,
        goals: puzzle.goals,
        givens: List<int>.filled(puzzle.cellCount, kRomeNoGiven),
        solution: puzzle.solution,
      );
      final count = RomeSearch(
        puzzle: bare,
        masks: RomeModel.fresh(bare).masks,
        limit: 3,
      ).run();
      expect(count.solutions, 3);
      expect(count.truncated, isFalse);
      expect(count.exhausted, isFalse);
      expect(count.isUnique, isFalse);
      expect(count.forced.every((value) => value == null), isTrue);
    });

    test('the board starts with its givens on and nothing else written', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(romeNotifierProvider);
      expect(state.size, RomeSize.small, reason: '5x5 is the feed size');
      expect(state.puzzle.goals, isNotEmpty);
      for (var cell = 0; cell < state.cellCount; cell++) {
        if (state.puzzle.isGoal(cell)) {
          expect(state.values[cell], kRomeGoal);
        } else if (state.puzzle.given(cell) != kRomeNoGiven) {
          expect(state.values[cell], state.puzzle.given(cell));
        } else {
          expect(state.values[cell], kRomeBlank);
        }
      }
      expect(state.written, 0);
      expect(state.conflicts, isEmpty);
    });

    test('a board can be finished by tapping it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(romeNotifierProvider.notifier);
      final puzzle = container.read(romeNotifierProvider).puzzle;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        // The only input is the tap cycle, so write the answer the way a player
        // does: tap until the arrow is there. Goals and printed arrows are not
        // the player's cells and must not move.
        if (puzzle.isGoal(cell)) continue;
        if (puzzle.given(cell) != kRomeNoGiven) continue;
        var guard = 0;
        while (container.read(romeNotifierProvider).values[cell] !=
            puzzle.solution[cell]) {
          notifier.tap(cell);
          if (++guard > kRomeArrowCount + 2) fail('the cycle never reached it');
        }
      }
      expect(container.read(romeNotifierProvider).isSolved, isTrue);
      expect(container.read(romeNotifierProvider).values, puzzle.solution);
    });

    test('a tap cycles the four arrows and then back to blank', () {
      expect(RomeNotifier.nextValue(kRomeBlank), kRomeUp);
      expect(RomeNotifier.nextValue(kRomeUp), kRomeRight);
      expect(RomeNotifier.nextValue(kRomeRight), kRomeDown);
      expect(RomeNotifier.nextValue(kRomeDown), kRomeLeft);
      expect(RomeNotifier.nextValue(kRomeLeft), kRomeBlank);
    });

    test('a tap does nothing to a goal or a printed arrow', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(romeNotifierProvider.notifier);
      final puzzle = container.read(romeNotifierProvider).puzzle;
      final goal = puzzle.goals.first;
      final given = [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          if (puzzle.given(cell) != kRomeNoGiven) cell
      ].first;
      final before = container.read(romeNotifierProvider).values;
      notifier.tap(goal);
      notifier.tap(given);
      expect(container.read(romeNotifierProvider).values, before);
    });
  });
}
