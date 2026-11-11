/// Kurodoko, ported from Tatham's `range.c` (Nikoli's Kurodoko, also sold as
/// Kuromasu; Tatham calls it Range).
///
/// The board is a grid of cells, some carrying a number. Paint some cells black
/// so that:
///
///  * a numbered cell is never black;
///  * no two black cells share an edge;
///  * the white cells are all connected through other white cells;
///  * a cell numbered `n` sees `n` white cells, counting itself — the white run
///    across it plus the white run down it, minus the cell counted twice.
///
/// The last rule is the whole puzzle. Everything else is bookkeeping that makes
/// the count checkable.
library;

import 'dart:math';

import '../../../../core/deduction.dart';

/// What a cell is. A clue is a positive number and is always white, so it is
/// carried separately from the player's grid.
enum KurodokoCell { unknown, white, black }

/// A board and its answer.
class KurodokoPuzzle {
  KurodokoPuzzle({
    required this.rows,
    required this.cols,
    required this.clues,
    required this.solution,
  })  : assert(clues.length == rows * cols),
        assert(solution.length == rows * cols);

  final int rows;
  final int cols;

  /// 0 where there is no clue, otherwise the number the cell shows.
  final List<int> clues;

  /// The black set, as the generator found it. The player's grid is checked
  /// against the rules rather than against this, so any valid answer wins.
  final List<KurodokoCell> solution;

  int get cellCount => rows * cols;

  int index(int row, int col) => row * cols + col;

  bool inBounds(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  int clueAt(int row, int col) => clues[index(row, col)];

  bool isClue(int row, int col) => clues[index(row, col)] > 0;

  /// The four orthogonal neighbours of a cell, in bounds.
  List<int> neighbours(int cell) {
    final row = cell ~/ cols;
    final col = cell % cols;
    return [
      if (row > 0) index(row - 1, col),
      if (row < rows - 1) index(row + 1, col),
      if (col > 0) index(row, col - 1),
      if (col < cols - 1) index(row, col + 1),
    ];
  }

  /// How many black cells this board has. Used by the difficulty tiers, which
  /// are partly about how crowded the board is.
  int get blackCount => solution.where((c) => c == KurodokoCell.black).length;
}

/// The three difficulties, differing in how deep the reasoning has to go.
class KurodokoDifficulty {
  const KurodokoDifficulty({
    required this.rows,
    required this.cols,
    required this.level,
    required this.label,
  });

  final int rows;
  final int cols;

  /// The rule level a board of this difficulty has to need. See
  /// [kurodokoRules] for what each level means.
  final int level;

  final String label;

  /// The tiers step in depth first and size second. Depth is the rule level a
  /// board needs — a board that falls to counting is easy however big it is —
  /// and the sizes are the largest that still generate in a fraction of a
  /// second, measured rather than guessed. A hard board is only a little wider
  /// than a medium one because the look-ahead rule costs a solve per cell
  /// tried, and a bigger board buys nothing but a longer wait.
  static const easy = KurodokoDifficulty(
    rows: 6,
    cols: 8,
    level: 2,
    label: 'easy',
  );

  static const medium = KurodokoDifficulty(
    rows: 7,
    cols: 10,
    level: 3,
    label: 'medium',
  );

  static const hard = KurodokoDifficulty(
    rows: 8,
    cols: 10,
    level: 4,
    label: 'hard',
  );

  static const values = [easy, medium, hard];
}

// --------------------------------------------------------------- the model

/// A board mid-solve.
///
/// The clues are fixed; only [grid] moves. That split is what lets a guess be
/// thrown away cheaply: [copy] duplicates the grid and shares the clues.
class KurodokoModel implements DeductionModel<KurodokoModel> {
  KurodokoModel(this.puzzle, this.grid);

  /// A fresh board, with the clue cells already white.
  ///
  /// A clue is white by the rules, so starting them undecided would only give
  /// the solver cells to waste guesses on.
  KurodokoModel.blank(this.puzzle)
      : grid = [
          for (var cell = 0; cell < puzzle.cellCount; cell++)
            puzzle.clues[cell] > 0
                ? KurodokoCell.white
                : KurodokoCell.unknown,
        ];

  final KurodokoPuzzle puzzle;
  final List<KurodokoCell> grid;

  int get rows => puzzle.rows;
  int get cols => puzzle.cols;

  KurodokoCell at(int cell) => grid[cell];

  bool isUnknown(int cell) => grid[cell] == KurodokoCell.unknown;

  bool isBlack(int cell) => grid[cell] == KurodokoCell.black;

  bool isWhite(int cell) => grid[cell] == KurodokoCell.white;

  /// Tries to give a cell a colour.
  ///
  /// Returns 1 when that was news, 0 when the cell already had that colour, and
  /// -1 when the board contradicts itself: the cell had the other colour, or it
  /// is a clue being blackened.
  ///
  /// Reporting news only when something actually changed is what stops the
  /// fixed-point loop from spinning: a rule that re-derives a cell it already
  /// knows must say 0, or [deduce] never reaches a fixed point.
  int settle(int cell, KurodokoCell value) {
    final current = grid[cell];
    if (current == value) return 0;
    if (current != KurodokoCell.unknown) return -1;
    if (value == KurodokoCell.black && puzzle.clues[cell] > 0) return -1;
    grid[cell] = value;
    return 1;
  }

  @override
  KurodokoModel copy() => KurodokoModel(puzzle, [...grid]);

  @override
  bool get isComplete => !grid.contains(KurodokoCell.unknown);

  static final List<int> _colours = [
    KurodokoCell.black.index,
    KurodokoCell.white.index,
  ];

  /// The cell to guess on when the rules run out.
  ///
  /// A cell next to a decided cell is worth more than a lonely one: whatever
  /// colour it takes, the rules immediately have something to work with.
  @override
  Choice? get choice {
    var fallback = -1;
    for (var cell = 0; cell < grid.length; cell++) {
      if (!isUnknown(cell)) continue;
      if (fallback == -1) fallback = cell;
      final touching = puzzle
          .neighbours(cell)
          .any((other) => grid[other] != KurodokoCell.unknown);
      if (touching) {
        return Choice(cell, _colours);
      }
    }
    if (fallback == -1) return null;
    return Choice(fallback, _colours);
  }

  @override
  KurodokoModel assume(int slot, int value) {
    final next = copy();
    next.grid[slot] = KurodokoCell.values[value];
    return next;
  }

  /// Every clue is satisfied.
  ///
  /// Only meaningful on a finished board: an undecided cell counts as white, so
  /// the count can still change.
  bool get cluesHold {
    for (var cell = 0; cell < grid.length; cell++) {
      final clue = puzzle.clues[cell];
      if (clue == 0) continue;
      if (grid[cell] == KurodokoCell.black) return false;
      if (whiteSeenFrom(cell) != clue) return false;
    }
    return true;
  }

  /// The white run across a cell plus the white run down it, minus the cell.
  int whiteSeenFrom(int cell) {
    final row = cell ~/ cols;
    final col = cell % cols;
    return _run(row, col, 0, -1) +
        _run(row, col, 0, 1) +
        _run(row, col, -1, 0) +
        _run(row, col, 1, 0) +
        1;
  }

  /// Consecutive white cells from (row, col) in one direction, not counting it.
  int _run(int row, int col, int dr, int dc) {
    var n = 0;
    var r = row + dr;
    var c = col + dc;
    while (puzzle.inBounds(r, c) && !isBlack(puzzle.index(r, c))) {
      n++;
      r += dr;
      c += dc;
    }
    return n;
  }

  /// No two black cells share an edge.
  bool get noAdjacentBlacks {
    for (var cell = 0; cell < grid.length; cell++) {
      if (!isBlack(cell)) continue;
      for (final other in puzzle.neighbours(cell)) {
        if (isBlack(other)) return false;
      }
    }
    return true;
  }

  /// Every white cell is reachable from every other.
  bool get whitesConnected {
    final start = grid.indexWhere((c) => c != KurodokoCell.black);
    if (start == -1) return false;
    final seen = <int>{start};
    final queue = <int>[start];
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      for (final other in puzzle.neighbours(cell)) {
        if (grid[other] == KurodokoCell.black) continue;
        if (seen.add(other)) queue.add(other);
      }
    }
    for (var cell = 0; cell < grid.length; cell++) {
      if (grid[cell] != KurodokoCell.black && !seen.contains(cell)) {
        return false;
      }
    }
    return true;
  }
}

// --------------------------------------------------------------- the rules

/// A black cell forces its neighbours white, and a clue is never black.
///
/// The cheapest idea on the board, and the one that needs no counting.
class KurodokoNeighbourRule implements DeductionRule<KurodokoModel> {
  const KurodokoNeighbourRule();

  @override
  int get level => 1;

  @override
  String get name => 'neighbour';

  @override
  int apply(KurodokoModel model) {
    var settled = 0;

    for (var cell = 0; cell < model.grid.length; cell++) {
      if (!model.isBlack(cell)) continue;
      // A clue is white by the rules, so a black clue is already a dead board.
      if (model.puzzle.clues[cell] > 0) return -1;
      for (final other in model.puzzle.neighbours(cell)) {
        final news = model.settle(other, KurodokoCell.white);
        if (news < 0) return -1;
        settled += news;
      }
    }
    return settled;
  }
}

/// A clue counts the white it can see, so it can rule cells in and out.
///
/// This is the rule that starts a fresh board. Three counts per direction:
/// the white run, the undecided run after it, and the cells beyond that which
/// are not black yet — those could still turn white, so they are space.
///
/// From those, two things follow:
///
///  * if the clue already sees everything it asks for, the next cell in every
///    direction has to be black, or it would see too much;
///  * if the clue cannot reach its number even using every direction, then the
///    directions it must lean on have to be white, cell by cell.
class KurodokoClueRule implements DeductionRule<KurodokoModel> {
  const KurodokoClueRule();

  @override
  int get level => 2;

  @override
  String get name => 'clue';

  static const _directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];

  @override
  int apply(KurodokoModel model) {
    final puzzle = model.puzzle;
    var settled = 0;

    for (var cell = 0; cell < model.grid.length; cell++) {
      final clue = puzzle.clues[cell];
      if (clue == 0) continue;

      final row = cell ~/ puzzle.cols;
      final col = cell % puzzle.cols;

      final white = List<int>.filled(4, 0);
      final empty = List<int>.filled(4, 0);
      final beyond = List<int>.filled(4, 0);
      final room = List<int>.filled(4, 0);
      final usable = List<int>.filled(4, 0);

      for (var d = 0; d < 4; d++) {
        final (dr, dc) = _directions[d];
        var r = row + dr;
        var c = col + dc;

        int run(bool Function(KurodokoCell) passable) {
          var n = 0;
          while (puzzle.inBounds(r, c) && passable(model.grid[puzzle.index(r, c)])) {
            n++;
            r += dr;
            c += dc;
          }
          return n;
        }

        white[d] = run((v) => v == KurodokoCell.white);
        empty[d] = run((v) => v == KurodokoCell.unknown);

        // Past the undecided cells the run is broken, and two different
        // questions get asked about what is out there. They need separate
        // answers, which is why there are four runs and not three.
        final pastR = r;
        final pastC = c;

        // Already white. This is what the "too big" test below counts: if every
        // undecided cell in this direction went white the run would carry on
        // into these cells, so seeing too much means one of the undecided cells
        // has to be black. It has to be *already* white for that to hold — if
        // these cells were merely undecided the cut could happen out here
        // instead, and blaming the gap would be wrong.
        beyond[d] = run((v) => v == KurodokoCell.white);

        // Anything not black, which is the optimistic answer to "how far could
        // this run still reach". Used for the room a clue has, where being too
        // small would force cells that are not forced.
        r = pastR;
        c = pastC;
        room[d] = run((v) => v != KurodokoCell.black);
      }

      var whites = 1;
      for (var d = 0; d < 4; d++) {
        whites += white[d];
      }
      // Seeing more white than the clue asks for is already a contradiction.
      if (whites > clue) return -1;

      for (var d = 0; d < 4; d++) {
        final (dr, dc) = _directions[d];
        // The first cell past the white run in this direction.
        final r = row + (1 + white[d]) * dr;
        final c = col + (1 + white[d]) * dc;

        if (whites == clue) {
          // Nothing more can join this direction: the clue already sees its
          // number, so the run stops here. This has to be set even when the
          // run already reaches the edge and there is no cell to blacken —
          // otherwise the room this direction offers counts as zero and the
          // clue looks unsatisfiable.
          usable[d] = white[d];
          if (puzzle.inBounds(r, c)) {
            final news = model.settle(puzzle.index(r, c), KurodokoCell.black);
            if (news < 0) return -1;
            settled += news;
          }
          continue;
        }

        if (whites + empty[d] + beyond[d] > clue) {
          // This direction would overshoot if everything in it went white, so
          // it has to be cut short. The last undecided cell is the only place
          // to cut it, and if there is exactly one it must be black.
          usable[d] = white[d] + empty[d] - 1;
          if (empty[d] == 1 && puzzle.inBounds(r, c)) {
            final news = model.settle(puzzle.index(r, c), KurodokoCell.black);
            if (news < 0) return -1;
            settled += news;
          }
        } else {
          usable[d] = white[d] + empty[d] + room[d];
        }
      }

      var space = 1;
      for (var d = 0; d < 4; d++) {
        space += usable[d];
      }
      // Not enough room anywhere for the clue to see its number.
      if (space < clue) return -1;

      for (var d = 0; d < 4; d++) {
        final (dr, dc) = _directions[d];
        // Everything the clue can use that is not in this direction.
        final elsewhere = space - usable[d];
        if (elsewhere >= clue) continue;
        // So this direction has to supply the rest, from the cell next door.
        var r = row + dr;
        var c = col + dc;
        for (var need = elsewhere; need < clue; need++) {
          if (!puzzle.inBounds(r, c)) break;
          final news = model.settle(puzzle.index(r, c), KurodokoCell.white);
          if (news < 0) return -1;
          settled += news;
          r += dr;
          c += dc;
        }
      }
    }
    return settled;
  }
}

/// The white cells have to stay connected, so a cell the white region cannot do
/// without cannot be black.
///
/// That is a question about articulation points: run a depth-first search over
/// everything that is not black and mark the cells whose removal would split
/// it. A board already split in two can never be joined up again, because cells
/// only ever leave the not-black set.
class KurodokoConnectRule implements DeductionRule<KurodokoModel> {
  const KurodokoConnectRule();

  @override
  int get level => 3;

  @override
  String get name => 'connect';

  @override
  int apply(KurodokoModel model) {
    final puzzle = model.puzzle;
    final n = model.grid.length;

    var root = -1;
    for (var cell = 0; cell < n; cell++) {
      if (!model.isBlack(cell)) {
        root = cell;
        break;
      }
    }
    if (root == -1) return -1;

    final depth = List<int>.filled(n, -1);
    final low = List<int>.filled(n, 0);
    final parent = List<int>.filled(n, -1);
    final mustBeWhite = <int>{};

    // Iterative, because a long thin board would otherwise recurse as deep as
    // it is long and the stack is not ours to spend.
    final stack = <(int, int)>[(root, 0)];
    depth[root] = 0;
    low[root] = 0;
    var rootChildren = 0;

    while (stack.isNotEmpty) {
      final (cell, next) = stack.removeLast();
      final around = puzzle.neighbours(cell);

      if (next < around.length) {
        stack.add((cell, next + 1));
        final other = around[next];
        if (model.isBlack(other)) continue;

        if (depth[other] == -1) {
          parent[other] = cell;
          depth[other] = depth[cell] + 1;
          low[other] = depth[other];
          if (cell == root) rootChildren++;
          stack.add((other, 0));
        } else if (other != parent[cell]) {
          low[cell] = min(low[cell], depth[other]);
        }
        continue;
      }

      // Coming back up: the parent learns how far down this branch reaches.
      final up = parent[cell];
      if (up != -1) {
        low[up] = min(low[up], low[cell]);
        // A child that cannot reach above us means we are the only way through.
        if (low[cell] >= depth[up] && up != root) {
          mustBeWhite.add(up);
        }
      }
    }

    // A not-black graph that is already in pieces is *not* a contradiction.
    // The white cells only have to end up connected, and they are free to be a
    // single one of those pieces with the rest going black — so the search
    // simply never looks at the pieces it did not reach. Tatham does the same,
    // and adding the check here made the solver reject valid boards.
    if (rootChildren >= 2) mustBeWhite.add(root);

    var settled = 0;
    for (final cell in mustBeWhite) {
      final news = model.settle(cell, KurodokoCell.white);
      if (news < 0) return -1;
      settled += news;
    }
    return settled;
  }
}

/// When nothing else moves, try a cell both ways and keep the one that survives.
///
/// This is still reasoning, not guessing: a colour that contradicts the rules
/// cannot be the answer, so the other one is forced. It is the last rung
/// because it costs a full solve per cell tried.
class KurodokoLookaheadRule implements DeductionRule<KurodokoModel> {
  const KurodokoLookaheadRule();

  @override
  int get level => 4;

  @override
  String get name => 'lookahead';

  @override
  int apply(KurodokoModel model) {
    final cheap = kurodokoRules
        .where((rule) => rule.level < level)
        .toList(growable: false);

    for (var cell = 0; cell < model.grid.length; cell++) {
      if (!model.isUnknown(cell)) continue;

      KurodokoCell? survivor;
      var refuted = 0;
      for (final colour in const [
        KurodokoCell.black,
        KurodokoCell.white,
      ]) {
        final trial = model.copy();
        if (trial.settle(cell, colour) < 0) {
          refuted++;
          continue;
        }
        if (!deduce(trial, cheap).consistent) {
          refuted++;
          continue;
        }
        survivor = colour;
      }

      if (refuted == 2) return -1;
      if (refuted == 1 && survivor != null) {
        final news = model.settle(cell, survivor);
        if (news < 0) return -1;
        return news;
      }
    }
    return 0;
  }
}

/// The rules in the order a player meets them.
const List<DeductionRule<KurodokoModel>> kurodokoRules = [
  KurodokoNeighbourRule(),
  KurodokoClueRule(),
  KurodokoConnectRule(),
  KurodokoLookaheadRule(),
];

// --------------------------------------------------------------- the engine

/// Generates boards, checks answers, and grades a board by how deep it goes.
class KurodokoEngine {
  const KurodokoEngine();

  /// A board that needs exactly [difficulty]'s rule level, or null if the
  /// attempt budget ran out.
  KurodokoPuzzle? generate({
    required KurodokoDifficulty difficulty,
    Random? random,
    int attempts = 400,
  }) {
    random ??= Random();
    for (var attempt = 0; attempt < attempts; attempt++) {
      final puzzle = propose(difficulty, random);
      // The rules are sound, so a board they can finish has exactly one answer
      // and counting it would only re-derive that. Asking the two questions
      // that matter — does the level finish it, and does the level below? — is
      // the same verdict for a fraction of the cost. The tests count properly.
      if (!_solvableAt(puzzle, difficulty.level)) continue;
      if (_solvableAt(puzzle, difficulty.level - 1)) continue;
      return puzzle;
    }
    return null;
  }

  /// One candidate: place black cells, number the white ones, then take clues
  /// away for as long as the board still falls to reasoning at [difficulty]'s
  /// level.
  KurodokoPuzzle propose(KurodokoDifficulty difficulty, Random random) {
    final rows = difficulty.rows;
    final cols = difficulty.cols;
    final n = rows * cols;

    final grid = List<KurodokoCell>.filled(n, KurodokoCell.white);
    final order = List<int>.generate(n, (i) => i)..shuffle(random);

    // Black cells, about a third of the board, never next to each other and
    // never splitting the white into pieces.
    var blacks = 0;
    for (var k = 0; k < n ~/ 3; k++) {
      final cell = order[k];
      final row = cell ~/ cols;
      final col = cell % cols;

      var blocked = false;
      for (final other in _neighbours(rows, cols, row, col)) {
        if (grid[other] == KurodokoCell.black) {
          blocked = true;
          break;
        }
      }
      if (blocked) continue;

      grid[cell] = KurodokoCell.black;
      blacks++;
      if (!_whitesAllReachable(rows, cols, grid, n, blacks)) {
        grid[cell] = KurodokoCell.white;
        blacks--;
      }
    }

    final clues = _numberTheWhites(rows, cols, grid);

    // Take clues away while the board still falls to reasoning. Fewer clues is
    // a harder board, so this is what sets the difficulty.
    final strip = List<int>.generate(n, (i) => i)..shuffle(random);
    for (final cell in strip) {
      if (clues[cell] == 0) continue;
      final was = clues[cell];
      clues[cell] = 0;
      final puzzle = KurodokoPuzzle(
        rows: rows,
        cols: cols,
        clues: clues,
        solution: grid,
      );
      if (!_solvableAt(puzzle, difficulty.level)) clues[cell] = was;
    }

    return KurodokoPuzzle(
      rows: rows,
      cols: cols,
      clues: clues,
      solution: grid,
    );
  }

  /// True when the rules up to [level] finish the board on their own.
  ///
  /// Every rule is sound — it only ever settles a cell that is forced — so a
  /// board the rules can finish has exactly one answer. That is why the
  /// generator can strip clues against this and not against a full count.
  bool solvableAt(KurodokoPuzzle puzzle, int level) =>
      _solvableAt(puzzle, level);

  bool _solvableAt(KurodokoPuzzle puzzle, int level) {
    final rules =
        kurodokoRules.where((rule) => rule.level <= level).toList(growable: false);
    final outcome = deduce(KurodokoModel.blank(puzzle), rules);
    return outcome.consistent && outcome.complete;
  }

  /// A finished grid that satisfies every rule.
  ///
  /// Checked against the rules rather than against the stored answer, so a
  /// player who finds a different valid arrangement is still right — and so a
  /// bug in the generator cannot hide behind an answer key.
  bool isSolved(KurodokoPuzzle puzzle, List<KurodokoCell> grid) {
    if (grid.length != puzzle.cellCount) return false;
    if (grid.contains(KurodokoCell.unknown)) return false;
    final model = KurodokoModel(puzzle, [...grid]);
    return model.noAdjacentBlacks && model.whitesConnected && model.cluesHold;
  }

  /// Every cell that has to be black in [grid], for the hint.
  List<int> blackIn(KurodokoPuzzle puzzle, List<KurodokoCell> grid) => [
        for (var cell = 0; cell < grid.length; cell++)
          if (grid[cell] == KurodokoCell.black) cell,
      ];

  List<int> _neighbours(int rows, int cols, int row, int col) => [
        if (row > 0) (row - 1) * cols + col,
        if (row < rows - 1) (row + 1) * cols + col,
        if (col > 0) row * cols + col - 1,
        if (col < cols - 1) row * cols + col + 1,
      ];

  /// Whether every cell that is not black can be reached from any one of them.
  bool _whitesAllReachable(
    int rows,
    int cols,
    List<KurodokoCell> grid,
    int n,
    int blacks,
  ) {
    var start = -1;
    for (var cell = 0; cell < n; cell++) {
      if (grid[cell] != KurodokoCell.black) {
        start = cell;
        break;
      }
    }
    if (start == -1) return false;

    final seen = <int>{start};
    final queue = <int>[start];
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      for (final other in _neighbours(rows, cols, cell ~/ cols, cell % cols)) {
        if (grid[other] == KurodokoCell.black) continue;
        if (seen.add(other)) queue.add(other);
      }
    }
    return seen.length + blacks == n;
  }

  /// Numbers every white cell with what it would see.
  List<int> _numberTheWhites(
    int rows,
    int cols,
    List<KurodokoCell> grid,
  ) {
    final clues = List<int>.filled(rows * cols, 0);
    for (var row = 0; row < rows; row++) {
      var run = 0;
      for (var col = 0; col <= cols; col++) {
        if (col == cols || grid[row * cols + col] == KurodokoCell.black) {
          for (var back = col - run; back < col; back++) {
            clues[row * cols + back] += run;
          }
          run = 0;
        } else {
          run++;
        }
      }
    }
    for (var col = 0; col < cols; col++) {
      var run = 0;
      for (var row = 0; row <= rows; row++) {
        if (row == rows || grid[row * cols + col] == KurodokoCell.black) {
          for (var back = row - run; back < row; back++) {
            clues[back * cols + col] += run;
          }
          run = 0;
        } else {
          run++;
        }
      }
    }
    // The cell was counted once in each direction, so take one back.
    for (var cell = 0; cell < clues.length; cell++) {
      if (grid[cell] != KurodokoCell.black) clues[cell]--;
    }
    return clues;
  }
}
