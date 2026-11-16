import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/deduction.dart';
import 'package:puzzle/ui/features/games/crossing/crossing_engine.dart';
import 'package:puzzle/ui/features/games/crossing/crossing_model.dart';
import 'package:puzzle/ui/features/games/crossing/crossing_provider.dart';
import 'package:puzzle/ui/features/games/crossing/crossing_puzzle.dart';

const engine = CrossingEngine();

/// Dealing is the cheap part here (a board is proved in about two milliseconds),
/// but each size is dealt once and shared so the file finishes in a blink.
final _dealt = <CrossingSize, CrossingPuzzle>{};

CrossingPuzzle dealt(CrossingSize size, {int seed = 0}) => _dealt.putIfAbsent(
      size,
      () => engine.generate(size, random: Random(seed + size.index)),
    );

/// A tiny board written by hand: [runs] and the [numbers] to lay into them.
CrossingPuzzle board(
  List<CrossingRun> runs,
  List<String> numbers, {
  int n = 5,
  List<int>? solution,
}) {
  final cells = List<int>.filled(n * n, kCrossingEmpty);
  if (solution != null) {
    for (var i = 0; i < solution.length; i++) {
      cells[i] = solution[i];
    }
  }
  return CrossingPuzzle(
    size: CrossingSize.small,
    numbers: numbers,
    runs: runs,
    solution: cells,
  );
}

/// Every way to lay the whole list into the runs, counted the slow way.
///
/// This shares no code with [CrossingModel]: it puts the numbers in the list
/// order, refuses a run that is taken or a digit that disagrees with what is
/// already there, and counts the assignments it completes. A filling here is a
/// bijection between the list and the runs, which is exactly what the game says
/// a win is — so if the model and this disagree, the model is wrong.
int bruteForceCount(CrossingPuzzle puzzle) {
  final cells = List<int>.filled(puzzle.cellCount, kCrossingEmpty);
  final taken = List<bool>.filled(puzzle.runCount, false);
  var found = 0;

  void placeNumber(int number) {
    if (number == puzzle.numbers.length) {
      found++;
      return;
    }
    final text = puzzle.numbers[number];
    for (var run = 0; run < puzzle.runCount; run++) {
      if (taken[run]) continue;
      final runCells = puzzle.runCells(run);
      if (runCells.length != text.length) continue;
      var ok = true;
      for (var i = 0; i < runCells.length && ok; i++) {
        final digit = text.codeUnitAt(i) - 48;
        if (cells[runCells[i]] != kCrossingEmpty &&
            cells[runCells[i]] != digit) {
          ok = false;
        }
      }
      if (!ok) continue;
      final before = [for (final cell in runCells) cells[cell]];
      for (var i = 0; i < runCells.length; i++) {
        cells[runCells[i]] = text.codeUnitAt(i) - 48;
      }
      taken[run] = true;
      placeNumber(number + 1);
      taken[run] = false;
      for (var i = 0; i < runCells.length; i++) {
        cells[runCells[i]] = before[i];
      }
    }
  }

  placeNumber(0);
  return found;
}

void main() {
  group('Crossing vocabularies', () {
    test('empty is zero, digits start at one, and a number never holds a zero',
        () {
      expect(kCrossingEmpty, 0);
      for (final size in CrossingSize.values) {
        for (final number in dealt(size).numbers) {
          expect(number, isNotEmpty);
          for (final digit in number.split('')) {
            expect(int.parse(digit), inInclusiveRange(1, 9),
                reason: '${size.name} listed a number with a $digit in it');
          }
          expect(number.length, inInclusiveRange(2, 3), reason: size.name);
        }
        // The list is a set: two runs reading the same number would make the
        // list a worse clue than the grid it describes.
        expect(
            dealt(size).numbers.toSet(), hasLength(dealt(size).numbers.length));
      }
    });

    test('a run is its first cell, its direction and its length', () {
      final puzzle = dealt(CrossingSize.small);
      for (var run = 0; run < puzzle.runCount; run++) {
        final cells = puzzle.runCells(run);
        expect(cells.first, puzzle.runs[run].start);
        expect(cells, hasLength(puzzle.runs[run].length));
        for (var i = 1; i < cells.length; i++) {
          expect(cells[i] - cells[i - 1],
              puzzle.runs[run].horizontal ? 1 : puzzle.n);
        }
      }
    });
  });

  group('CrossingEngine', () {
    test('a dealt board is a legal filling', () {
      for (final size in CrossingSize.values) {
        final puzzle = dealt(size);
        expect(puzzle.isSolution(puzzle.solution), isTrue,
            reason: '${size.name} dealt an answer its own rule rejects');
        expect(puzzle.numbers, hasLength(puzzle.runCount),
            reason: '${size.name}: one number per run, or the list is a lie');
        expect(puzzle.numbers.length,
            inInclusiveRange(size.minNumbers, size.maxNumbers),
            reason: size.name);
      }
    });

    test('the list pins down exactly one filling, at every size', () {
      for (final size in CrossingSize.values) {
        expect(engine.count(dealt(size)), 1,
            reason: '${size.name} is ambiguous');
      }
    });

    test('the list can be laid out without a guess, at every size', () {
      for (final size in CrossingSize.values) {
        final level = engine.levelOf(dealt(size));
        expect(level, isNotNull, reason: '${size.name} needs a guess');
        // Levels 1 and 2 are the player's rules. Level 3 is the exact search,
        // and a board that only the search can finish must not be dealt.
        expect(level, inInclusiveRange(1, 2), reason: size.name);
      }
    });

    test('the counter agrees with plain enumeration', () {
      // A model that agrees with itself proves nothing, so one board is counted
      // the slow, obvious way and both numbers have to match.
      final puzzle = dealt(CrossingSize.small, seed: 3);
      expect(bruteForceCount(puzzle), 1);
      expect(bruteForceCount(puzzle), engine.count(puzzle));
    });

    test('the rules finish a dealt board, and the grade says so', () {
      for (final size in CrossingSize.values) {
        final puzzle = dealt(size);
        final rating = rate(CrossingModel.fresh(puzzle), crossingPlayerRules);
        expect(rating.verdict, PuzzleVerdict.solved, reason: size.name);
        expect(rating.solutions, 1);
        expect(rating.level, inInclusiveRange(1, 2));
      }
    });

    test('a list that cannot be laid out is a contradiction', () {
      // Two runs of two cells crossing in one: the across number wants a 1
      // there and the down number wants a 2, and one cell cannot be both.
      final crossed = board(
        const [
          CrossingRun(start: 0, length: 2, horizontal: true),
          CrossingRun(start: 1, length: 2, horizontal: false),
        ],
        ['11', '22'],
      );
      expect(engine.count(crossed), 0);
      // The digits sweep alone cannot see it: each cell still has two digits,
      // because each run on its own could be either number. It is the count of
      // whole layouts that knows the list does not fit, which is why the exact
      // rule has to exist.
      final found = CrossingSearch(CrossingModel.fresh(crossed)).run();
      expect(found.solutions, 0);
      expect(found.exhausted, isTrue);
      expect(const CrossingForced().apply(CrossingModel.fresh(crossed)), -1);
      expect(rate(CrossingModel.fresh(crossed), crossingPlayerRules).verdict,
          PuzzleVerdict.impossible);
    });

    test('the hint writes what the rules prove, and finishes the board', () {
      final puzzle = dealt(CrossingSize.small, seed: 4);
      final values = List<int>.filled(puzzle.cellCount, kCrossingEmpty);
      var steps = 0;
      while (true) {
        final found = engine.hint(puzzle, values);
        if (found == null) break;
        expect(found.cells, isNotEmpty);
        expect(found.cells, hasLength(found.digits.length));
        for (var i = 0; i < found.cells.length; i++) {
          expect(values[found.cells[i]], kCrossingEmpty,
              reason: 'the hint wrote a cell that already holds a digit');
          expect(found.digits[i], puzzle.solution[found.cells[i]],
              reason: 'the hint contradicts the answer');
          values[found.cells[i]] = found.digits[i];
        }
        steps++;
        if (steps > puzzle.runCount) fail('the hint never runs out');
      }
      expect(steps, greaterThan(0));
      expect(puzzle.isSolution(values), isTrue);
    });

    test('a digit no number writes stops the hint', () {
      final puzzle = board(
        const [
          CrossingRun(start: 0, length: 2, horizontal: true),
          CrossingRun(start: 10, length: 2, horizontal: true),
        ],
        ['12', '34'],
        solution: [
          1,
          2,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          3,
          4,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0
        ],
      );
      final values = List<int>.filled(puzzle.cellCount, kCrossingEmpty);
      // No listed number starts with a 9, so this cell has no run left at all
      // and there is nothing to prove on top of it.
      values[0] = 9;
      expect(engine.hint(puzzle, values), isNull);
      // The right digit leaves the hint free to finish the board.
      values[0] = 1;
      final found = engine.hint(puzzle, values)!;
      expect(found.digits, [2]);
      expect(found.cells, [1]);
    });
  });

  group('CrossingModel: the objects are the numbers', () {
    test('a guess names a number and where it goes', () {
      final puzzle = dealt(CrossingSize.medium, seed: 6);
      final model = CrossingModel.fresh(puzzle);
      final choice = model.choice!;
      // The slot is a number, not a cell: a cell-domain model cannot say "this
      // number is in one place and nowhere else".
      expect(choice.slot, inInclusiveRange(0, model.numberCount - 1));
      expect(choice.values.length, greaterThan(1));
      for (final run in choice.values) {
        expect(puzzle.runs[run].length, puzzle.numbers[choice.slot].length,
            reason: 'a number was offered a run it does not fit');
      }

      final next = model.assume(choice.slot, choice.values.first);
      expect(next.placementCount(choice.slot), 1);
      expect(next.placementsOf(choice.slot), [choice.values.first]);
      // Placing it takes that run off the table for every other number, which
      // is the constraint a cell-domain model has nowhere to put.
      for (var other = 0; other < next.numberCount; other++) {
        if (other == choice.slot) continue;
        expect(next.placementsOf(other), isNot(contains(choice.values.first)));
      }
    });

    test('a number with one run left is placed', () {
      final puzzle = board(
        const [
          CrossingRun(start: 0, length: 3, horizontal: true),
          CrossingRun(start: 10, length: 2, horizontal: true),
        ],
        ['123', '45'],
        solution: [
          1,
          2,
          3,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          4,
          5,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0
        ],
      );
      final model = CrossingModel.fresh(puzzle);
      // Only the three-cell number fits the three-cell run.
      expect(model.placementCount(0), 1);
      expect(model.sweepPlaced(), isNonNegative);
      final outcome = deduce(model, crossingPlayerRules);
      expect(outcome.consistent, isTrue);
      expect(outcome.complete, isTrue);
      expect(puzzle.isSolution(model.values), isTrue);
    });

    test('a run with one number left takes it', () {
      final puzzle = board(
        const [
          CrossingRun(start: 0, length: 2, horizontal: true),
          CrossingRun(start: 10, length: 2, horizontal: true),
        ],
        ['12', '34'],
        solution: [
          1,
          2,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          3,
          4,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0
        ],
      );
      // Hand-built masks: the 34 can only be in the first run, and the 12 still
      // thinks it has both. That is the state the rule exists for.
      final model = CrossingModel(
        puzzle: puzzle,
        placements: [0x3, 0x1],
        domains: [
          for (var cell = 0; cell < puzzle.cellCount; cell++)
            puzzle.isWall(cell) ? 0 : kCrossingFullDomain,
        ],
      );
      expect(model.sweepOneHome(), greaterThan(0));
      expect(model.placementsOf(1), [0]);
      // And the 12 is pushed out of the first run by the same move.
      expect(model.placementsOf(0), [1]);
      expect(deduce(model, crossingPlayerRules).complete, isTrue);
    });

    test('a digit the crossings agree on is decided, and it rules numbers out',
        () {
      final puzzle = dealt(CrossingSize.large, seed: 7);
      final model = CrossingModel.fresh(puzzle);
      expect(model.sweepDigits(), greaterThan(0));
      // Everything it wrote is what the answer says: a deduction that invents a
      // digit would still look like progress.
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (!model.isDecided(cell)) continue;
        expect(model.digitAt(cell), puzzle.solution[cell]);
      }
      // And every number it ruled out of a run really does not fit there.
      for (var number = 0; number < model.numberCount; number++) {
        for (final run in model.placementsOf(number)) {
          final cells = puzzle.runCells(run);
          for (var i = 0; i < cells.length; i++) {
            if (!model.isDecided(cells[i])) continue;
            expect(puzzle.numbers[number].codeUnitAt(i) - 48,
                model.digitAt(cells[i]),
                reason: 'number $number is still offered run $run, which '
                    'cannot hold it');
          }
        }
      }
    });

    test('an unfinished count proves nothing', () {
      // Two runs that do not cross, and a list of two numbers: both orders fit,
      // so there are two fillings and neither forced claim is a proof.
      final puzzle = board(
        const [
          CrossingRun(start: 0, length: 2, horizontal: true),
          CrossingRun(start: 10, length: 2, horizontal: true),
        ],
        ['12', '34'],
        solution: [
          1,
          2,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          3,
          4,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0
        ],
      );
      expect(bruteForceCount(puzzle), 2);

      final stopped =
          CrossingSearch(CrossingModel.fresh(puzzle), limit: 2).run();
      expect(stopped.solutions, 2);
      expect(stopped.truncated, isFalse);
      expect(stopped.exhausted, isFalse);
      expect(stopped.forced.every((digit) => digit == null), isTrue);
      expect(stopped.forcedRuns.every((run) => run == null), isTrue);

      // Finished instead: both orders were seen, and they disagree everywhere.
      final whole = CrossingSearch(CrossingModel.fresh(puzzle), limit: 3).run();
      expect(whole.solutions, 2);
      expect(whole.exhausted, isTrue);
      expect(whole.forced.every((digit) => digit == null), isTrue,
          reason: 'the search claimed a cell both fillings disagree on');

      final model = CrossingModel.fresh(puzzle);
      expect(const CrossingForced().apply(model), 0,
          reason: 'the rule wrote something it had not proved');
    });

    test('a search that runs out of budget is not a count', () {
      // A dealt board needs no branch at all, so it is finished inside the first
      // node whatever the budget says. This one has to branch.
      final puzzle = board(
        const [
          CrossingRun(start: 0, length: 2, horizontal: true),
          CrossingRun(start: 10, length: 2, horizontal: true),
        ],
        ['12', '34'],
        solution: [
          1,
          2,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          3,
          4,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0
        ],
      );
      final count = CrossingSearch(
        CrossingModel.fresh(puzzle),
        limit: 3,
        budget: 0,
      ).run();
      expect(count.truncated, isTrue);
      expect(count.exhausted, isFalse);
      expect(count.isUnique, isFalse);
    });

    test('the exact rule proves a dealt board without guessing', () {
      final puzzle = dealt(CrossingSize.medium, seed: 10);
      final found = CrossingSearch(CrossingModel.fresh(puzzle)).run();
      expect(found.solutions, 1);
      expect(found.exhausted, isTrue);
      expect(puzzle.isSolution(found.first), isTrue);
      // Every digit is forced, and every number sits in one run: the search is
      // a proof, not a first answer.
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (puzzle.isWall(cell)) continue;
        expect(found.forced[cell], puzzle.solution[cell]);
      }
      for (var number = 0; number < puzzle.runCount; number++) {
        expect(found.forcedRuns[number], isNotNull);
        expect(puzzle.runText(found.forcedRuns[number]!, found.first),
            puzzle.numbers[number]);
      }
    });
  });

  group('CrossingPuzzle: the win test is the list, not the grid', () {
    test('a full grid that repeats a number is not a win', () {
      final puzzle = board(
        const [
          CrossingRun(start: 0, length: 2, horizontal: true),
          CrossingRun(start: 10, length: 2, horizontal: true),
        ],
        ['12', '21'],
        solution: [
          1,
          2,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          2,
          1,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0
        ],
      );
      final values = [...puzzle.solution];
      expect(puzzle.isSolution(values), isTrue);
      expect(puzzle.blankCount(values), 0);

      // Every cell of both runs written, and both runs read 12: the grid is as
      // full as it can be and the list is still wrong.
      values[10] = 1;
      values[11] = 2;
      expect(puzzle.blankCount(values), 0);
      expect(puzzle.isSolution(values), isFalse);
      expect(puzzle.isLegal(values), isFalse);
      expect(puzzle.conflicts(values), containsAll([0, 1, 10, 11]));
      expect(engine.isSolved(puzzle, values), isFalse);
    });

    test('a digit outside a placement is not a win', () {
      final puzzle = dealt(CrossingSize.small, seed: 12);
      final values = [...puzzle.solution];
      final wall = [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          if (puzzle.isWall(cell)) cell
      ].first;
      values[wall] = 4;
      expect(puzzle.isSolution(values), isFalse);
      expect(puzzle.conflicts(values), contains(wall));
      expect(puzzle.isLegal(values), isFalse);
    });

    test('an unfinished board is neither a win nor a mistake', () {
      final puzzle = dealt(CrossingSize.small, seed: 13);
      final values = List<int>.filled(puzzle.cellCount, kCrossingEmpty);
      expect(puzzle.isSolution(values), isFalse);
      expect(puzzle.isLegal(values), isTrue);
      // Half of one run, from its last cell: writing the end of a number first
      // is allowed, and it has to be the right digit.
      final run = 0;
      final cells = puzzle.runCells(run);
      values[cells.last] = puzzle.solution[cells.last];
      expect(puzzle.isLegal(values), isTrue);
      values[cells.last] = puzzle.solution[cells.last] % 9 + 1;
      expect(puzzle.isLegal(values), isFalse);
      expect(puzzle.conflicts(values), contains(cells.last));
    });

    test('a half-written run that no number can finish is a mistake', () {
      final puzzle = board(
        const [
          CrossingRun(start: 0, length: 3, horizontal: true),
          CrossingRun(start: 10, length: 2, horizontal: true),
        ],
        ['123', '45'],
        solution: [
          1,
          2,
          3,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          4,
          5,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0
        ],
      );
      final values = List<int>.filled(puzzle.cellCount, kCrossingEmpty);
      values[0] = 3; // no listed number starts with a 3
      expect(puzzle.isLegal(values), isFalse);
      expect(puzzle.conflicts(values), [0]);
      values[0] = 1;
      expect(puzzle.isLegal(values), isTrue);
      expect(puzzle.conflicts(values), isEmpty);
    });
  });

  group('CrossingNotifier', () {
    test('the tap cycle runs empty, 1..9, and back to empty', () {
      expect(CrossingNotifier.nextValue(kCrossingEmpty), 1);
      expect(CrossingNotifier.nextValue(1), 2);
      expect(CrossingNotifier.nextValue(8), 9);
      expect(CrossingNotifier.nextValue(9), kCrossingEmpty);
    });

    test('the board starts empty with its list under it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(crossingNotifierProvider);
      expect(state.size, CrossingSize.small);
      expect(state.puzzle.numbers, isNotEmpty);
      for (var cell = 0; cell < state.puzzle.cellCount; cell++) {
        expect(state.values[cell], kCrossingEmpty);
      }
      expect(state.satisfied, isEmpty);
    });

    test('a wall takes no digit, and a cell cycles', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(crossingNotifierProvider.notifier);
      final puzzle = container.read(crossingNotifierProvider).puzzle;
      final wall = [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          if (puzzle.isWall(cell)) cell
      ].first;
      notifier.tap(wall);
      expect(container.read(crossingNotifierProvider).values[wall],
          kCrossingEmpty);

      final open = [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          if (!puzzle.isWall(cell)) cell
      ].first;
      notifier.tap(open);
      expect(container.read(crossingNotifierProvider).values[open], 1);
      notifier.tap(open);
      expect(container.read(crossingNotifierProvider).values[open], 2);
    });

    test('a board can be finished by playing it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(crossingNotifierProvider.notifier);
      final puzzle = container.read(crossingNotifierProvider).puzzle;
      for (final cell in [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          if (!puzzle.isWall(cell)) cell
      ]) {
        // The only input is the tap cycle, so write the answer the way a player
        // does: tap until the digit is there.
        var guard = 0;
        while (container.read(crossingNotifierProvider).values[cell] !=
            puzzle.solution[cell]) {
          notifier.tap(cell);
          if (++guard > 11) fail('the cycle never reached it');
        }
      }
      expect(container.read(crossingNotifierProvider).isSolved, isTrue);
      expect(container.read(crossingNotifierProvider).values, puzzle.solution);
      expect(container.read(crossingNotifierProvider).satisfied,
          hasLength(puzzle.numbers.length));
    });

    test('the hint writes the rules, and the board marks it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(crossingNotifierProvider.notifier);
      notifier.hint();
      final state = container.read(crossingNotifierProvider);
      expect(state.hintCells, isNotEmpty);
      for (final cell in state.hintCells) {
        expect(state.values[cell], state.puzzle.solution[cell]);
      }
    });
  });
}
