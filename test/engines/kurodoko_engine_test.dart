import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/deduction.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_engine.dart';

/// Counts answers with no cleverness at all: try every cell white or black,
/// pruning only on the rules of the puzzle itself.
///
/// This is the independent check on [rate]. The solver's rules are allowed to
/// be fast; they are not allowed to be wrong, and the only way to know is to
/// count without them. It prunes on exactly what the game says — a clue is
/// never black, two blacks never touch, a clue never sees more white than it
/// asks for — and on nothing the solver invented.
///
/// Returns null when the budget ran out, so a caller can tell "one answer" from
/// "gave up".
int? bruteForce(KurodokoPuzzle puzzle, {int limit = 2, int maxNodes = 400000}) {
  const engine = KurodokoEngine();
  final grid = List<KurodokoCell>.filled(puzzle.cellCount, KurodokoCell.unknown);
  var found = 0;
  var nodes = 0;
  var truncated = false;

  bool place(int cell) {
    if (found >= limit) return true;
    if (nodes++ > maxNodes) {
      truncated = true;
      return true;
    }
    if (cell == grid.length) {
      if (engine.isSolved(puzzle, grid)) found++;
      return found >= limit;
    }

    for (final colour in const [KurodokoCell.white, KurodokoCell.black]) {
      if (colour == KurodokoCell.black && puzzle.clues[cell] > 0) continue;
      grid[cell] = colour;

      // Two blacks never touch.
      var clash = false;
      if (colour == KurodokoCell.black) {
        for (final other in puzzle.neighbours(cell)) {
          if (grid[other] == KurodokoCell.black) {
            clash = true;
            break;
          }
        }
      }
      // A clue never sees more white than it asks for, and never has fewer
      // cells left in its row and column than it needs.
      if (!clash) {
        for (var other = 0; other < grid.length; other++) {
          final clue = puzzle.clues[other];
          if (clue == 0) continue;
          if (_seen(puzzle, grid, other) > clue) {
            clash = true;
            break;
          }
          if (_room(puzzle, grid, other) < clue) {
            clash = true;
            break;
          }
        }
      }
      if (!clash) {
        if (place(cell + 1)) {
          grid[cell] = KurodokoCell.unknown;
          return true;
        }
      }
      grid[cell] = KurodokoCell.unknown;
    }
    return false;
  }

  place(0);
  return truncated ? null : found;
}

/// The most a clue could ever see: every cell in its row and column that is
/// not black.
///
/// A plain count of the cross, not the run analysis the solver does — an upper
/// bound has to be generous to stay honest, and this one is.
int _room(KurodokoPuzzle puzzle, List<KurodokoCell> grid, int cell) {
  final row = cell ~/ puzzle.cols;
  final col = cell % puzzle.cols;
  var n = 1;
  for (var c = 0; c < puzzle.cols; c++) {
    if (c != col && grid[puzzle.index(row, c)] != KurodokoCell.black) n++;
  }
  for (var r = 0; r < puzzle.rows; r++) {
    if (r != row && grid[puzzle.index(r, col)] != KurodokoCell.black) n++;
  }
  return n;
}

/// White cells a clue sees *right now*.
///
/// Only cells already white count. Counting undecided cells as white would
/// make every clue look over-satisfied on an empty board and prune the whole
/// search before it started.
int _seen(KurodokoPuzzle puzzle, List<KurodokoCell> grid, int cell) {
  var n = 1;
  for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
    var r = cell ~/ puzzle.cols + dr;
    var c = cell % puzzle.cols + dc;
    while (puzzle.inBounds(r, c) &&
        grid[puzzle.index(r, c)] == KurodokoCell.white) {
      n++;
      r += dr;
      c += dc;
    }
  }
  return n;
}

void main() {
  const engine = KurodokoEngine();

  group('a generated board', () {
    test('the answer the generator kept satisfies every rule', () {
      final random = Random(2024);
      for (var i = 0; i < 30; i++) {
        final puzzle = engine.generate(
          difficulty: KurodokoDifficulty.easy,
          random: random,
        );
        expect(engine.isSolved(puzzle, puzzle.solution), isTrue,
            reason: 'board $i: the stored answer is not an answer');
      }
    });

    // A 48-cell board cannot be counted by brute force; 2^48 is not a number
    // of nodes, it is a number of universes. So the independent count runs on
    // boards small enough to enumerate exhaustively, which is what it is for:
    // checking that the counting machinery agrees with plain enumeration.
    // Generated boards are covered by the soundness test below instead, which
    // is the stronger argument anyway — a rule that never settles a cell
    // wrongly means finishing a board *proves* the answer is forced.
    test('the solver counts the same as plain enumeration on small boards', () {
      final random = Random(7);
      var checked = 0;
      for (final (rows, cols) in [(4, 4), (4, 5), (5, 4), (5, 5)]) {
        final tiny = KurodokoDifficulty(
          rows: rows,
          cols: cols,
          level: 2,
          label: 'tiny',
        );
        for (var i = 0; i < 8; i++) {
          final puzzle = engine.propose(tiny, random);
          final independent = bruteForce(puzzle, maxNodes: 2000000);
          if (independent == null) continue;
          checked++;
          final rated = rate(KurodokoModel.blank(puzzle), kurodokoRules);
          expect(rated.solutions, independent,
              reason: '${rows}x$cols board $i: solver says '
                  '${rated.solutions}, enumeration says $independent');
        }
      }
      expect(checked, greaterThan(20),
          reason: 'the enumeration never finished a board');
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('no single cell can be flipped to make a second answer', () {
      // Not a proof of uniqueness, but it is independent of the solver and it
      // catches the failure that matters: a board with a free cell in it.
      final random = Random(31);
      for (var i = 0; i < 20; i++) {
        final puzzle = engine.generate(
          difficulty: KurodokoDifficulty.easy,
          random: random,
        );
        for (var cell = 0; cell < puzzle.cellCount; cell++) {
          if (puzzle.clues[cell] > 0) continue;
          final flipped = [...puzzle.solution];
          flipped[cell] = flipped[cell] == KurodokoCell.black
              ? KurodokoCell.white
              : KurodokoCell.black;
          expect(engine.isSolved(puzzle, flipped), isFalse,
              reason: 'board $i: flipping cell $cell gives a second answer');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('every clue is a number the answer actually produces', () {
      final random = Random(11);
      for (var i = 0; i < 20; i++) {
        final puzzle = engine.generate(
          difficulty: KurodokoDifficulty.easy,
          random: random,
        );
        final model = KurodokoModel(puzzle, [...puzzle.solution]);
        for (var cell = 0; cell < puzzle.cellCount; cell++) {
          final clue = puzzle.clues[cell];
          if (clue == 0) continue;
          expect(model.whiteSeenFrom(cell), clue,
              reason: 'board $i: clue at $cell says $clue');
        }
      }
    });
  });

  group('the rules are sound', () {
    // The whole design rests on this: a rule only ever settles a cell that is
    // forced. If one could settle a cell wrongly, the generator would strip
    // clues against a lie and ship ambiguous boards.
    test('no rule ever contradicts a board or settles a wrong cell', () {
      final random = Random(7);
      final cheap = kurodokoRules.where((rule) => rule.level < 4).toList();
      var checked = 0;

      for (var i = 0; i < 10; i++) {
        final puzzle = engine.generate(
          difficulty: KurodokoDifficulty.easy,
          random: random,
        );

        for (var cell = 0; cell < puzzle.cellCount; cell++) {
          if (puzzle.clues[cell] > 0) continue;
          for (final colour in const [
            KurodokoCell.black,
            KurodokoCell.white,
          ]) {
            checked++;
            final model = KurodokoModel.blank(puzzle);
            model.settle(cell, colour);
            final outcome = deduce(model, cheap);

            if (colour == puzzle.solution[cell]) {
              expect(outcome.consistent, isTrue,
                  reason: 'board $i: the right colour at $cell was refuted');
            }
            if (!outcome.consistent) continue;

            for (var k = 0; k < model.grid.length; k++) {
              if (model.grid[k] == KurodokoCell.unknown) continue;
              if (puzzle.clues[k] > 0) continue;
              expect(model.grid[k], puzzle.solution[k],
                  reason: 'board $i: from $cell=${colour.name}, '
                      'cell $k was settled wrong');
            }
          }
        }
      }
      expect(checked, greaterThan(500));
    }, timeout: const Timeout(Duration(minutes: 4)));
  });

  group('the 200-board bar', () {
    test('200 easy boards, each with exactly one solution', () {
      final random = Random(99);
      for (var i = 0; i < 200; i++) {
        final puzzle = engine.generate(
          difficulty: KurodokoDifficulty.easy,
          random: random,
        );
        final rating = rate(KurodokoModel.blank(puzzle), kurodokoRules);
        expect(rating.verdict, PuzzleVerdict.solved, reason: 'board $i: $rating');
        expect(rating.solutions, 1, reason: 'board $i: $rating');
        expect(rating.level, KurodokoDifficulty.easy.level,
            reason: 'board $i: $rating');
      }
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('200 medium boards, each with exactly one solution', () {
      final random = Random(1234);
      for (var i = 0; i < 200; i++) {
        final puzzle = engine.generate(
          difficulty: KurodokoDifficulty.medium,
          random: random,
        );
        final rating = rate(KurodokoModel.blank(puzzle), kurodokoRules);
        expect(rating.verdict, PuzzleVerdict.solved, reason: 'board $i: $rating');
        expect(rating.solutions, 1, reason: 'board $i: $rating');
        expect(rating.level, KurodokoDifficulty.medium.level,
            reason: 'board $i: $rating');
      }
    }, timeout: const Timeout(Duration(minutes: 6)));

    test('200 hard boards, each with exactly one solution', () {
      final random = Random(555);
      for (var i = 0; i < 200; i++) {
        final puzzle = engine.generate(
          difficulty: KurodokoDifficulty.hard,
          random: random,
        );
        final rating = rate(KurodokoModel.blank(puzzle), kurodokoRules);
        expect(rating.verdict, PuzzleVerdict.solved, reason: 'board $i: $rating');
        expect(rating.solutions, 1, reason: 'board $i: $rating');
        expect(rating.level, KurodokoDifficulty.hard.level,
            reason: 'board $i: $rating');
      }
    }, timeout: const Timeout(Duration(minutes: 12)));
  });

  group('difficulty', () {
    test('each tier needs its own rule level and not the one below', () {
      final random = Random(4242);
      for (final difficulty in KurodokoDifficulty.values) {
        for (var i = 0; i < 6; i++) {
          final puzzle = engine.generate(
            difficulty: difficulty,
            random: random,
          );
          final rating = rate(KurodokoModel.blank(puzzle), kurodokoRules);
          expect(rating.level, difficulty.level,
              reason: '${difficulty.label} board $i came back at '
                  '${rating.level}');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 6)));

    test('the levels are ordered by how hard the rules are', () {
      expect(kurodokoRules.map((rule) => rule.level), [1, 2, 3, 4]);
    });

    test('a board gets bigger as the difficulty rises', () {
      final sizes = [
        for (final d in KurodokoDifficulty.values) d.rows * d.cols,
      ];
      expect(sizes[0] < sizes[1], isTrue);
      expect(sizes[1] < sizes[2], isTrue);
    });
  });

  group('rules', () {
    test('a black cell forces its neighbours white', () {
      final puzzle = _board(
        rows: 3,
        cols: 3,
        clues: const [0, 0, 0, 0, 0, 0, 0, 0, 0],
      );
      final model = KurodokoModel.blank(puzzle);
      model.settle(4, KurodokoCell.black);
      expect(const KurodokoNeighbourRule().apply(model), 4);
      for (final cell in [1, 3, 5, 7]) {
        expect(model.grid[cell], KurodokoCell.white);
      }
    });

    test('two black cells side by side is a contradiction', () {
      final puzzle = _board(
        rows: 1,
        cols: 3,
        clues: const [0, 0, 0],
      );
      final model = KurodokoModel.blank(puzzle);
      model.settle(0, KurodokoCell.black);
      model.settle(1, KurodokoCell.black);
      expect(const KurodokoNeighbourRule().apply(model), -1);
    });

    test('a clue is never black', () {
      final puzzle = _board(
        rows: 1,
        cols: 3,
        clues: const [0, 2, 0],
      );
      final model = KurodokoModel.blank(puzzle);
      expect(model.settle(1, KurodokoCell.black), -1);
    });

    test('a clue that already sees its number blackens the next cell', () {
      // One row, clue 1 in the middle: it sees only itself, so both
      // neighbours have to be black.
      final puzzle = _board(
        rows: 1,
        cols: 3,
        clues: const [0, 1, 0],
      );
      final model = KurodokoModel.blank(puzzle);
      const KurodokoClueRule().apply(model);
      expect(model.grid[0], KurodokoCell.black);
      expect(model.grid[2], KurodokoCell.black);
    });

    test('a clue with no room anywhere is a contradiction', () {
      // A clue of 5 on a row of 3 can never see 5 cells.
      final puzzle = _board(
        rows: 1,
        cols: 3,
        clues: const [0, 5, 0],
      );
      final model = KurodokoModel.blank(puzzle);
      expect(const KurodokoClueRule().apply(model), -1);
    });

    test('settling a cell twice is not news', () {
      final puzzle = _board(
        rows: 1,
        cols: 2,
        clues: const [0, 0],
      );
      final model = KurodokoModel.blank(puzzle);
      expect(model.settle(0, KurodokoCell.white), 1);
      expect(model.settle(0, KurodokoCell.white), 0,
          reason: 'a rule that re-derives a cell must not report progress');
      expect(model.settle(0, KurodokoCell.black), -1);
    });
  });

  group('answers', () {
    test('a finished board is checked against the rules, not a key', () {
      final puzzle = _board(
        rows: 1,
        cols: 3,
        clues: const [0, 3, 0],
      );
      expect(
        engine.isSolved(puzzle, const [
          KurodokoCell.white,
          KurodokoCell.white,
          KurodokoCell.white,
        ]),
        isTrue,
      );
      expect(
        engine.isSolved(puzzle, const [
          KurodokoCell.black,
          KurodokoCell.white,
          KurodokoCell.white,
        ]),
        isFalse,
        reason: 'the clue would only see two cells',
      );
    });

    test('an unfinished board is not solved', () {
      final puzzle = _board(
        rows: 1,
        cols: 3,
        clues: const [0, 3, 0],
      );
      expect(
        engine.isSolved(puzzle, const [
          KurodokoCell.unknown,
          KurodokoCell.white,
          KurodokoCell.white,
        ]),
        isFalse,
      );
    });

    test('whites that are cut in two are not solved', () {
      final puzzle = _board(
        rows: 1,
        cols: 5,
        clues: const [0, 0, 0, 0, 0],
      );
      expect(
        engine.isSolved(puzzle, const [
          KurodokoCell.white,
          KurodokoCell.black,
          KurodokoCell.white,
          KurodokoCell.black,
          KurodokoCell.white,
        ]),
        isFalse,
      );
    });
  });
}

/// A board with the clues given and no answer, for testing one rule at a time.
KurodokoPuzzle _board({
  required int rows,
  required int cols,
  required List<int> clues,
}) {
  return KurodokoPuzzle(
    rows: rows,
    cols: cols,
    clues: clues,
    solution: List<KurodokoCell>.filled(rows * cols, KurodokoCell.white),
  );
}
