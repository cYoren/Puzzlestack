import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/salad/salad_engine.dart';
import 'package:puzzle/ui/features/games/salad/salad_model.dart';
import 'package:puzzle/ui/features/games/salad/salad_provider.dart';
import 'package:puzzle/ui/features/games/salad/salad_puzzle.dart';

const engine = SaladEngine();

/// Dealing is the expensive part (the 7x7 tries about 200 Latin squares before
/// it finds a border that proves itself), so each size is dealt once and the
/// tests share it.
final _dealt = <SaladSize, SaladPuzzle>{};

SaladPuzzle dealt(SaladSize size, {int seed = 0}) => _dealt.putIfAbsent(
      size,
      () => engine.generate(size, random: Random(seed + size.index)),
    );

/// Every board that obeys the game's own rule, counted by plain enumeration.
///
/// This is the check the model cannot make about itself: if a deduction rule is
/// wrong, the search and the rules agree with each other and are both wrong. The
/// enumeration shares no code with [SaladModel] — it builds rows, refuses a
/// repeat in a column, and reads the border with its own scan.
int bruteForceCount(SaladPuzzle puzzle) {
  final n = puzzle.n;
  final nums = puzzle.nums;
  final holes = puzzle.holes;

  // Every way one line can be filled: each letter once, exactly `holes` holes.
  final patterns = <List<int>>[];
  final row = List<int>.filled(n, kSaladHole);
  void build(int col, int used, int holeCount) {
    if (col == n) {
      if (holeCount == holes) patterns.add(List<int>.from(row));
      return;
    }
    if (holeCount < holes) {
      row[col] = kSaladHole;
      build(col + 1, used, holeCount + 1);
    }
    for (var letter = 1; letter <= nums; letter++) {
      if (used & (1 << letter) != 0) continue;
      row[col] = letter;
      build(col + 1, used | (1 << letter), holeCount);
    }
  }

  build(0, 0, 0);

  final grid = List<int>.filled(n * n, kSaladHole);
  final colUsed = List<int>.filled(n, 0);
  final colHoles = List<int>.filled(n, 0);
  var found = 0;

  /// The first cell that is not a hole, read from that edge.
  bool clueTrue(SaladClueDir dir, int index) {
    final wanted = puzzle.clue(dir, index);
    if (wanted == kSaladNoClue) return true;
    for (final cell in puzzle.line(dir, index)) {
      if (grid[cell] == kSaladHole) continue;
      return grid[cell] == wanted;
    }
    // A finished line with no letter breaks every clue: each letter appears
    // once in every line.
    return false;
  }

  /// A prune, not a rule: the clue letter is the first letter a line shows, so
  /// it cannot sit further in than the line has holes. Cutting those branches
  /// changes the number of boards walked, never the number counted.
  ///
  /// It only fires once the cells it reads have been placed: rows go in from the
  /// top, so the near cells of a bottom clue are the last thing known.
  bool reachable(SaladClueDir dir, int index, int placed,
      {bool bottom = false}) {
    final wanted = puzzle.clue(dir, index);
    if (wanted == kSaladNoClue) return true;
    if (bottom ? placed < n : placed <= holes) return true;
    final cells = puzzle.line(dir, index);
    for (var i = 0; i <= holes; i++) {
      if (grid[cells[i]] == wanted) return true;
    }
    return false;
  }

  void place(int r) {
    if (r == n) {
      for (var c = 0; c < n; c++) {
        if (!clueTrue(SaladClueDir.top, c)) return;
        if (!clueTrue(SaladClueDir.bottom, c)) return;
      }
      found++;
      return;
    }
    for (final pattern in patterns) {
      var ok = true;
      for (var c = 0; c < n && ok; c++) {
        final value = pattern[c];
        if (value == kSaladHole) {
          if (colHoles[c] + 1 > holes) ok = false;
        } else if (colUsed[c] & (1 << value) != 0) {
          ok = false;
        }
      }
      if (!ok) continue;
      for (var c = 0; c < n; c++) {
        final value = pattern[c];
        if (value == kSaladHole) {
          colHoles[c]++;
        } else {
          colUsed[c] |= 1 << value;
        }
        grid[r * n + c] = value;
      }
      var keep =
          clueTrue(SaladClueDir.left, r) && clueTrue(SaladClueDir.right, r);
      for (var c = 0; c < n && keep; c++) {
        keep = reachable(SaladClueDir.top, c, r + 1) &&
            reachable(SaladClueDir.bottom, c, r + 1, bottom: true);
      }
      if (keep) place(r + 1);
      for (var c = 0; c < n; c++) {
        final value = pattern[c];
        if (value == kSaladHole) {
          colHoles[c]--;
        } else {
          colUsed[c] &= ~(1 << value);
        }
      }
    }
  }

  place(0);
  return found;
}

void main() {
  group('Salad vocabularies', () {
    test('a hole, a missing clue and an unwritten cell are three things', () {
      expect(kSaladHole, 0);
      expect(kSaladNoClue, -1);
      expect(kSaladBlank, -2);
      expect(<int>{kSaladHole, kSaladNoClue, kSaladBlank}, hasLength(3));
    });

    test('a dealt clue is a letter or nothing, never the hole', () {
      // The bug this guards is a board where 0 means both "hole" and "no clue":
      // it plays fine and the win test lies.
      for (final size in SaladSize.values) {
        for (final clue in dealt(size).clues) {
          expect(
              clue == kSaladNoClue || (clue >= 1 && clue <= size.nums), isTrue,
              reason: '${size.name} dealt the clue $clue');
        }
      }
    });
  });

  group('SaladEngine', () {
    test('a dealt board is a Latin square with the right holes', () {
      for (final size in SaladSize.values) {
        final puzzle = dealt(size);
        expect(puzzle.isSolution(puzzle.solution), isTrue, reason: size.name);
        for (var line = 0; line < size.n; line++) {
          final row = <int>[];
          final col = <int>[];
          for (var i = 0; i < size.n; i++) {
            row.add(puzzle.solution[puzzle.cell(line, i)]);
            col.add(puzzle.solution[puzzle.cell(i, line)]);
          }
          for (final cells in [row, col]) {
            expect(cells.where((v) => v == kSaladHole).length, size.holes,
                reason: '${size.name} line $line has the wrong hole count');
            expect(cells.where((v) => v != kSaladHole).toSet(),
                {for (var letter = 1; letter <= size.nums; letter++) letter},
                reason: '${size.name} line $line is not the alphabet');
          }
        }
      }
    });

    test('every border clue is true of the answer it was read from', () {
      for (final size in SaladSize.values) {
        final puzzle = dealt(size);
        for (final dir in SaladClueDir.values) {
          for (var index = 0; index < size.n; index++) {
            final wanted = puzzle.clue(dir, index);
            if (wanted == kSaladNoClue) continue;
            // The first cell that is not a hole, read from that edge.
            final seen = puzzle
                .line(dir, index)
                .map((cell) => puzzle.solution[cell])
                .firstWhere((value) => value != kSaladHole);
            expect(seen, wanted,
                reason: '${size.name} ${dir.name} $index says $wanted, '
                    'the answer shows $seen');
          }
        }
      }
    });

    test('the clues pin down exactly one answer, at every size', () {
      for (final size in SaladSize.values) {
        expect(engine.count(dealt(size)), 1,
            reason: '${size.name} is ambiguous');
      }
    });

    test('the clues can be finished without a guess, at every size', () {
      for (final size in SaladSize.values) {
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
      final puzzle = dealt(SaladSize.small);
      expect(bruteForceCount(puzzle), engine.count(puzzle));
    });

    test('a board with no clues at all is ambiguous', () {
      // The other side of the generator's claim: the border is what makes the
      // answer unique.
      final puzzle = dealt(SaladSize.small);
      final bare = SaladPuzzle(
        size: puzzle.size,
        clues: List<int>.filled(puzzle.clueCount, kSaladNoClue),
        solution: puzzle.solution,
      );
      final brute = bruteForceCount(bare);
      // 161,280 boards on a 5x5 with A~D and one hole per line, so the
      // enumeration really is walking the space and not tripping over its own
      // prune. The model's counter stops at its limit, which is the point: two
      // answers already refute uniqueness.
      expect(brute, greaterThan(1000));
      expect(engine.count(bare), 2);
      expect(bare.isSolution(puzzle.solution), isTrue);
    });

    test('the hint writes a value the answer agrees with, and advances', () {
      final puzzle = dealt(SaladSize.small, seed: 4);
      final values = List<int>.filled(puzzle.cellCount, kSaladBlank);
      var taken = 0;
      while (true) {
        final found = engine.hint(puzzle, values);
        if (found == null) break;
        expect(values[found.cell], kSaladBlank,
            reason: 'the hint picked a cell that is already written');
        expect(found.symbol, puzzle.solution[found.cell],
            reason: 'the hint contradicts the answer');
        values[found.cell] = found.symbol;
        taken++;
        if (taken > puzzle.cellCount) fail('the hint never runs out');
      }
      expect(taken, greaterThan(0));
      expect(puzzle.isSolution(values), isTrue);
    });

    test('a wrong value is a conflict, an unfinished board is not solved', () {
      final puzzle = dealt(SaladSize.small, seed: 8);
      final values = List<int>.filled(puzzle.cellCount, kSaladBlank);
      // Two copies of one letter in a row: the letter is only allowed once.
      values[puzzle.cell(0, 0)] = 1;
      values[puzzle.cell(0, 1)] = 1;
      expect(puzzle.conflicts(values), contains(puzzle.cell(0, 0)));
      expect(puzzle.conflicts(values), contains(puzzle.cell(0, 1)));
      expect(engine.isSolved(puzzle, values), isFalse);
      expect(puzzle.isLegal(values), isFalse);
    });

    test('an unfinished enumeration proves nothing', () {
      // Agreement among the first `limit` answers is not agreement among every
      // answer, and the exact rule must not read it as one.
      final size = SaladSize.medium;
      final bare = SaladPuzzle(
        size: size,
        clues: List<int>.filled(size.clueCount, kSaladNoClue),
        solution: dealt(size).solution,
      );
      final count = SaladSearch(
        puzzle: bare,
        masks: SaladModel.fresh(bare).masks,
        limit: 3,
      ).run();
      expect(count.solutions, 3);
      expect(count.truncated, isFalse);
      expect(count.exhausted, isFalse);
      expect(count.forced.every((symbol) => symbol == null), isTrue);
      final model = SaladModel.fresh(bare);
      expect(const SaladForced().apply(model), 0,
          reason: 'the rule wrote a cell it had not proved');
    });

    test('the board starts blank, with its clues on the border', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(saladNotifierProvider);
      expect(state.values.every((value) => value == kSaladBlank), isTrue);
      expect(state.puzzle.clues.where((c) => c != kSaladNoClue), isNotEmpty);
      // No in-grid givens: nothing is printed inside the grid at all.
      expect(state.puzzle.solution.length, state.n * state.n);
      expect(state.size, SaladSize.medium);
    });

    test('a board can be finished by playing it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(saladNotifierProvider.notifier);
      final puzzle = container.read(saladNotifierProvider).puzzle;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        // The only input is the tap cycle, so write the answer the way a player
        // does: tap until the symbol is there.
        var guard = 0;
        while (container.read(saladNotifierProvider).values[cell] !=
            puzzle.solution[cell]) {
          notifier.tap(cell);
          if (++guard > puzzle.nums + 2) fail('the cycle never reached it');
        }
      }
      expect(container.read(saladNotifierProvider).isSolved, isTrue);
      expect(container.read(saladNotifierProvider).values, puzzle.solution);
    });

    test('the tap cycle runs hole, the letters, and back to a hole', () {
      expect(SaladNotifier.nextValue(kSaladBlank, 4), kSaladHole);
      expect(SaladNotifier.nextValue(kSaladHole, 4), 1);
      expect(SaladNotifier.nextValue(2, 4), 3);
      expect(SaladNotifier.nextValue(4, 4), kSaladHole);
    });
  });
}
