import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/bricks/bricks_engine.dart';
import 'package:puzzle/ui/features/games/bricks/bricks_model.dart';
import 'package:puzzle/ui/features/games/bricks/bricks_provider.dart';

const engine = BricksEngine();

/// Counts the shadings [puzzle]'s numbers allow, with no code in common with
/// [BricksModel].
///
/// The model's claim is "exactly one answer", and a model that agrees with
/// itself proves nothing — a rule that is too strong and a rule that is too weak
/// can cancel out. So this walks the cells with its own arrays, in the one order
/// that makes the rules checkable as it goes (rows bottom-up, so "is it held up"
/// is already answered; left to right, so a run of three is visible as it is
/// built), prunes on the clues' counts, and asks [BricksPuzzle.isLegal] at the
/// leaf — the puzzle's own definition, not the solver's.
int bruteCount(BricksPuzzle puzzle) {
  final lattice = puzzle.lattice;
  final values = List<int>.filled(puzzle.cellCount, kBricksUnshaded);
  final seen = List<int>.filled(puzzle.cellCount, 0);
  final order = [
    for (var y = puzzle.rows - 1; y >= 0; y--)
      for (var x = lattice.leftmost(y); x <= lattice.rightmost(y); x++)
        lattice.cellAt(y, x)!,
  ];
  var count = 0;

  void place(int index, int run) {
    if (index == order.length) {
      if (puzzle.isLegal(values)) count++;
      return;
    }
    final cell = order[index];
    final clue = puzzle.clue(cell);
    // A numbered cell is unshaded, and a run never reaches three.
    final options = <int>[kBricksUnshaded];
    if (clue == kBricksNoClue && run < 2) options.add(kBricksShaded);
    // "Bottom-up" means the two cells under this one are already decided, so
    // rule 1 is a filter here and not a check at the leaf.
    final below = lattice.below(cell);
    final bottom = lattice.isBottomRow(cell);

    for (final shade in options) {
      if (shade == kBricksShaded &&
          !bottom &&
          !below.any((other) => values[other] == kBricksShaded)) {
        continue;
      }
      var over = false;
      if (shade == kBricksShaded) {
        for (final other in lattice.around(cell)) {
          final wanted = puzzle.clue(other);
          if (wanted == kBricksNoClue) continue;
          seen[other]++;
          if (seen[other] > wanted) over = true;
        }
      }
      if (!over) {
        values[cell] = shade;
        final nextRun = shade == kBricksShaded ? run + 1 : 0;
        final last = index + 1 == order.length;
        // The run resets when the walk moves to the next row up.
        if (!last && lattice.row[order[index + 1]] != lattice.row[cell]) {
          place(index + 1, 0);
        } else {
          place(index + 1, nextRun);
        }
        values[cell] = kBricksUnshaded;
      }
      if (shade == kBricksShaded) {
        for (final other in lattice.around(cell)) {
          if (puzzle.clue(other) == kBricksNoClue) continue;
          seen[other]--;
        }
      }
    }
  }

  place(0, 0);
  return count;
}

void main() {
  group('BricksEngine', () {
    test('an unfinished enumeration proves nothing', () {
      // A board with no numbers at all leaves only rules 1 and 2, so there are
      // far more shadings than the limit asks for. The exact rule must not hand
      // out forced cells, and must write nothing: agreement among the first
      // three answers says nothing about the fourth.
      final bare = BricksPuzzle(
        size: BricksSize.small,
        clues: List<int>.filled(BricksSize.small.cellCount, kBricksNoClue),
        solution: List<int>.filled(BricksSize.small.cellCount, kBricksShaded),
      );
      final found = BricksSearch(
        puzzle: bare,
        masks: BricksModel.fresh(bare).masks,
        limit: 3,
      ).run();
      expect(found.solutions, 3);
      expect(found.exhausted, isFalse);
      expect(found.forced.every((value) => value == null), isTrue);

      final model = BricksModel.fresh(bare);
      expect(const BricksForced().apply(model), 0,
          reason: 'the rule wrote a cell it had not proved');
    });

    test('a dealt board is a legal shading', () {
      final rng = Random(1);
      for (final size in BricksSize.values) {
        final puzzle = engine.generate(size, random: rng);
        expect(puzzle.isLegal(puzzle.solution), isTrue, reason: size.name);
        // The board is not legal by accident of an empty clue list.
        expect(puzzle.clueCount(), greaterThan(0), reason: size.name);
      }
    });

    test('every number is the shaded cells around it', () {
      // The numbers are read off the answer, so this catches two shapes of the
      // same bug: a number that is not the count it claims, and a number
      // printed on a shaded cell, which rule 4 forbids. Cells the generator
      // stripped have no number, which is the point of stripping them.
      for (final size in BricksSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 2));
        expect(puzzle.clueCount(), greaterThan(0), reason: size.name);
        for (var cell = 0; cell < puzzle.cellCount; cell++) {
          if (!puzzle.hasClue(cell)) continue;
          // Rule 4, from the other side: a number is never printed on a
          // shaded cell, which is the one bug a count-only check would miss.
          expect(puzzle.solution[cell], kBricksUnshaded,
              reason: '${size.name} cell $cell is shaded and numbered');
          expect(
            puzzle.clue(cell),
            puzzle.shadedAround(puzzle.solution, cell),
            reason: '${size.name} cell $cell prints the wrong count',
          );
        }
      }
    });

    test('the numbers pin down exactly one shading, at every size', () {
      for (final size in BricksSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 5));
        final found = engine.count(puzzle, limit: 2);
        expect(found.truncated, isFalse, reason: size.name);
        expect(found.solutions, 1, reason: '${size.name} is ambiguous');
        expect(found.forced, puzzle.solution, reason: size.name);
      }
    });

    test('a plain enumeration agrees with the counter', () {
      // Two counts, no shared code: the model's search and a bottom-up walk
      // that only reads the puzzle. The dealt board first — one answer each —
      // then the same board with all but two numbers taken away, where the
      // answer is many: "one" agreeing with "one" would not catch a rule that
      // is too strong, and a board with a handful of answers would not catch
      // one that is too weak.
      final dealt = engine.generate(BricksSize.small, random: Random(17));
      expect(bruteCount(dealt), 1);
      expect(engine.count(dealt, limit: 2).solutions, 1);

      final kept = [
        for (var cell = 0; cell < dealt.cellCount; cell++)
          if (dealt.hasClue(cell)) cell,
      ].take(2).toSet();
      final thin = BricksPuzzle(
        size: dealt.size,
        clues: [
          for (var cell = 0; cell < dealt.cellCount; cell++)
            kept.contains(cell)
                ? dealt.shadedAround(dealt.solution, cell)
                : kBricksNoClue,
        ],
        solution: dealt.solution,
      );
      final many = bruteCount(thin);
      expect(many, greaterThan(1));
      final found = engine.count(thin, limit: many + 1);
      expect(found.truncated, isFalse);
      expect(found.solutions, many);
    });

    test('the numbers can be finished without a guess, at every size', () {
      for (final size in BricksSize.values) {
        final puzzle = engine.generate(size, random: Random(size.index + 9));
        final level = engine.levelOf(puzzle);
        expect(level, isNotNull, reason: '${size.name} needs a guess');
        expect(level, lessThanOrEqualTo(2),
            reason: '${size.name} needs the exact search to get anywhere');
      }
    });

    test('a shaded cell that floats is not a solution', () {
      final puzzle = engine.generate(BricksSize.small, random: Random(21));
      final values = List<int>.from(puzzle.solution);
      expect(puzzle.isLegal(values), isTrue);
      expect(puzzle.conflicts(values), isEmpty);

      // Shade a cell on the top row that nothing holds up: the shading is now
      // wrong by rule 1, and the board must be able to say where.
      final float = [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          if (puzzle.lattice.row[cell] == 0 &&
              puzzle.clue(cell) == kBricksNoClue)
            cell,
      ].first;
      values[float] = kBricksShaded;
      expect(puzzle.isLegal(values), isFalse);
      expect(puzzle.conflicts(values), contains(float));
    });

    test('a run of three is not a solution', () {
      final puzzle = engine.generate(BricksSize.small, random: Random(23));
      final values = List<int>.from(puzzle.solution);
      // Find a row where two neighbouring, unnumbered cells are unshaded and can
      // be shaded without breaking anything but rule 2.
      var run = const <int>[];
      for (var cell = 0; cell < puzzle.cellCount && run.isEmpty; cell++) {
        final left = puzzle.lattice.leftOf(cell);
        final right = puzzle.lattice.rightOf(cell);
        if (left == null || right == null) continue;
        final triple = [left, cell, right];
        if (triple.any(puzzle.hasClue)) continue;
        run = triple;
      }
      expect(run, isNotEmpty, reason: 'the dealt board has no free triple');
      for (final entry in run) {
        values[entry] = kBricksShaded;
      }
      expect(puzzle.isLegal(values), isFalse);
      expect(puzzle.conflicts(values), containsAll(run));
    });

    test('a number cannot be shaded', () {
      final puzzle = engine.generate(BricksSize.small, random: Random(27));
      final values = List<int>.from(puzzle.solution);
      final numbered = [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          if (puzzle.hasClue(cell)) cell,
      ].first;
      values[numbered] = kBricksShaded;
      expect(puzzle.isLegal(values), isFalse);
      expect(puzzle.conflicts(values), contains(numbered));
    });

    test('the hint writes a shading the answer agrees with, and advances', () {
      final puzzle = engine.generate(BricksSize.small, random: Random(31));
      final values = List<int>.filled(puzzle.cellCount, kBricksUnshaded);
      final first = engine.hint(puzzle, values);
      expect(first, isNotNull);
      expect(first!.shading, puzzle.solution[first.cell]);
      values[first.cell] = first.shading;
      final second = engine.hint(puzzle, values);
      expect(second, isNotNull);
      expect(second!.cell, isNot(first.cell));
      expect(second.shading, puzzle.solution[second.cell]);
    });

    test('a tap flips a cell, and a numbered cell does not move', () {
      expect(nextShading(kBricksUnshaded), kBricksShaded);
      expect(nextShading(kBricksShaded), kBricksUnshaded);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(bricksNotifierProvider.notifier);
      final puzzle = container.read(bricksNotifierProvider).puzzle;
      final numbered = [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          if (puzzle.hasClue(cell)) cell,
      ].first;
      notifier.tap(numbered);
      expect(container.read(bricksNotifierProvider).values[numbered],
          kBricksUnshaded);

      final free = [
        for (var cell = 0; cell < puzzle.cellCount; cell++)
          if (!puzzle.hasClue(cell)) cell,
      ].first;
      notifier.tap(free);
      expect(
          container.read(bricksNotifierProvider).values[free], kBricksShaded);
      notifier.tap(free);
      expect(
          container.read(bricksNotifierProvider).values[free], kBricksUnshaded);
    });

    test('a board can be finished by playing it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(bricksNotifierProvider.notifier);
      final puzzle = container.read(bricksNotifierProvider).puzzle;
      expect(container.read(bricksNotifierProvider).isSolved, isFalse);
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        if (puzzle.solution[cell] != kBricksShaded) continue;
        notifier.tap(cell);
      }
      expect(container.read(bricksNotifierProvider).isSolved, isTrue);
      expect(container.read(bricksNotifierProvider).conflicts, isEmpty);
    });

    test('the six neighbours are the six hexagons that touch', () {
      // The rules are the C's table; the paint is a honeycomb. This is the seam
      // between them, so it is measured rather than assumed: every neighbour
      // sits exactly one hexagon away, and [BricksLattice.below] is the pair
      // that is lower on the screen.
      final lattice = BricksLattice(BricksSize.values.last);
      const px = BricksLattice.pitchX;
      const py = BricksLattice.pitchY;
      for (var cell = 0; cell < lattice.cellCount; cell++) {
        for (final other in lattice.around(cell)) {
          final dx = (lattice.centreX(other) - lattice.centreX(cell)).abs();
          final dy = lattice.centreY(other) - lattice.centreY(cell);
          final horizontal = (dx - px).abs() < 1e-9 && dy.abs() < 1e-9;
          final diagonal =
              (dx - px / 2).abs() < 1e-9 && (dy.abs() - py).abs() < 1e-9;
          expect(horizontal || diagonal, isTrue,
              reason: 'cell $cell and $other are not hexagon neighbours');
        }
        // "Below" is a direction, not a guess: the two cells that are lower and
        // share a lower edge.
        for (final under in lattice.below(cell)) {
          expect(lattice.centreY(under), greaterThan(lattice.centreY(cell)));
          expect((lattice.centreX(under) - lattice.centreX(cell)).abs(),
              closeTo(px / 2, 1e-9));
        }
        if (lattice.isBottomRow(cell)) {
          expect(lattice.below(cell), isEmpty);
        } else {
          expect(lattice.below(cell), isNotEmpty,
              reason: 'cell $cell hangs over nothing');
        }
      }
    });

    test('the honeycomb is the C cut: every row carries the same cells', () {
      // `bricks_apply_bounds` cuts the corners of the rectangle, and the point
      // of the cut is that each row keeps `params->w` cells. A row with a
      // different count would be a lattice the fill and the numbers disagree
      // about.
      for (final size in BricksSize.values) {
        final lattice = BricksLattice(size);
        expect(lattice.cellCount, size.cellCount);
        for (var y = 0; y < size.rows; y++) {
          final inRow = [
            for (var cell = 0; cell < lattice.cellCount; cell++)
              if (lattice.row[cell] == y) cell,
          ];
          expect(inRow, hasLength(size.cols), reason: '${size.name} row $y');
          // Left to right, with no hole in the middle of a row.
          for (var x = 0; x < inRow.length; x++) {
            expect(lattice.col[inRow[x]], lattice.leftmost(y) + x);
          }
        }
      }
    });
  });
}
