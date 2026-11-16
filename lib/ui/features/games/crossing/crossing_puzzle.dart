/// Crossing (Nansuke, Number Skeleton): lay every number in the list into the
/// grid once, across or down, and make the crossings agree.
///
/// Rules are the genre's (see `crossing.c` in `x-sheep/puzzles-unreleased`, MIT,
/// pinned in `REFERENCE.md`):
///
///  * every number in the list is written into the grid exactly once, one digit
///    per cell, either across or down;
///  * a run of cells that a number occupies is the whole run: the grid's other
///    cells are walls, and a digit never sits outside a number;
///  * where an across number and a down number meet, they share one cell, so
///    both must have the same digit there.
///
/// **The skeleton is the puzzle.** The source draws walls, and they are what
/// makes the answer findable: on a bare grid with a list of numbers, every
/// number can be dropped anywhere there is room, so no list of numbers has one
/// filling at all. Here the walls are the cells no number covers, and every run
/// of cells they leave is one number, outlined on the board so that where a
/// number ends is never a guess. That outline is not decoration: two numbers may
/// end up side by side in a row, and without it the player would have to guess
/// whether they were looking at one long number or two short ones.
///
/// `test/content/crossing_test.dart` pins the two halves of the deal: the number
/// list is exactly what the runs read, once each, and no cell outside a run
/// holds a digit.
///
/// One vocabulary, on purpose. A cell holds a digit `1..9` or [kCrossingEmpty],
/// and empty means "no digit": a wall, or a cell the player has not written yet.
/// The two are the same value because neither is ever a claim about a digit, and
/// a *number* is a string of digits, never a number with a sentinel in it, so
/// there is no arithmetic zero anywhere to be mistaken for a blank.
library;

/// The three boards the game ships.
enum CrossingSize {
  small(5, 6, 8),
  medium(6, 7, 9),
  large(7, 8, 10);

  const CrossingSize(this.n, this.minNumbers, this.maxNumbers);

  /// Side of the square grid the walls are cut out of.
  final int n;

  /// How many numbers the deal aims for. Fewer and the list stops pinning the
  /// grid down; more and the list is a grid of its own and will not fit under
  /// the board on a phone.
  final int minNumbers;
  final int maxNumbers;

  int get cellCount => n * n;
}

/// What an empty cell holds: a wall, or nothing written yet.
///
/// Never a digit, and never a sentinel for a clue: clues here are digit strings,
/// so there is nothing for this zero to be double-booked as.
const int kCrossingEmpty = 0;

/// How long the numbers in the list are. Two and three keep a deal readable on a
/// phone and leave the crossings to do the work.
const List<int> kCrossingLengths = [2, 3];

/// One place a number can go: its first cell, its direction and how long it is.
///
/// The source calls this a run. It is *the* object of the game — a number is
/// placed in a run, and the grid is only the table the runs share — so the model
/// in `crossing_model.dart` works over these, never over cells.
class CrossingRun {
  const CrossingRun({
    required this.start,
    required this.length,
    required this.horizontal,
  });

  /// Cell index of the first digit, reading left to right or top to bottom.
  final int start;

  final int length;

  /// Across when true, down when false.
  final bool horizontal;

  /// The cells in reading order.
  List<int> cells(int n) => [
        for (var i = 0; i < length; i++) horizontal ? start + i : start + i * n,
      ];

  @override
  String toString() =>
      'Run($start, $length, ${horizontal ? 'across' : 'down'})';
}

/// A Crossing board: the walls, the number list, and the one filling.
class CrossingPuzzle {
  CrossingPuzzle({
    required this.size,
    required this.numbers,
    required this.runs,
    required this.solution,
  })  : assert(numbers.length == runs.length),
        assert(solution.length == size.cellCount),
        _runCells = [for (final run in runs) run.cells(size.n)],
        _runsAt = List.generate(size.cellCount, (_) => <(int, int)>[]) {
    // One number per run, so every run's length has to be a length the list has.
    // The other half of the shape — that no two runs in one direction touch or
    // overlap, and that both ends of every run are free — is checked where the
    // runs are cut (`CrossingEngine._skeleton`), because it is a fact about the
    // dealing, not about one board.
    for (var run = 0; run < runs.length; run++) {
      assert(numbers.any((number) => number.length == runs[run].length),
          'run $run is ${runs[run].length} long, no number is');
      final cells = _runCells[run];
      for (var pos = 0; pos < cells.length; pos++) {
        _runsAt[cells[pos]].add((run, pos));
      }
    }
  }

  final CrossingSize size;

  /// The numbers to place, sorted the way the list under the board shows them.
  /// Digits `1..9` only, and no two the same.
  final List<String> numbers;

  /// The runs the walls cut the grid into, one number each.
  final List<CrossingRun> runs;

  /// The filling, row-major: [kCrossingEmpty] on a wall, a digit elsewhere.
  final List<int> solution;

  final List<List<int>> _runCells;

  /// Per cell, the runs through it, with the position of the cell in each.
  /// A cell on a crossing belongs to two; a cell in the middle of one run
  /// belongs to one; a wall belongs to none.
  final List<List<(int, int)>> _runsAt;

  int get n => size.n;

  int get cellCount => size.cellCount;

  int get runCount => runs.length;

  int cell(int row, int col) => row * n + col;

  int row(int cell) => cell ~/ n;

  int col(int cell) => cell % n;

  /// Cells the runs do not cover. A wall never holds a digit.
  bool isWall(int cell) => _runsAt[cell].isEmpty;

  List<int> runCells(int run) => _runCells[run];

  List<(int, int)> runsAt(int cell) => _runsAt[cell];

  /// The number a run shows on a full board, or '' while it is not full.
  String runText(int run, List<int> values) {
    final buffer = StringBuffer();
    for (final cell in _runCells[run]) {
      final value = cell < values.length ? values[cell] : kCrossingEmpty;
      if (value < 1 || value > 9) return '';
      buffer.write(value);
    }
    return buffer.toString();
  }

  /// The number a run shows in the answer.
  String answerText(int run) => runText(run, solution);

  /// The index of the number [text] spells, or -1.
  int numberIndex(String text) => numbers.indexOf(text);

  /// Per run, the index of the number it shows, or -1 when it shows none.
  ///
  /// The list has no duplicates, so at most one number can fit a run: this is a
  /// lookup, not a search.
  List<int> shown(List<int> values) => [
        for (var run = 0; run < runCount; run++)
          numberIndex(runText(run, values)),
      ];

  /// The numbers the player has written somewhere, for striking the list
  /// through. A number written twice still counts as written; [conflicts] is
  /// what says so.
  Set<int> satisfied(List<int> values) =>
      shown(values).where((number) => number >= 0).toSet();

  /// Whether a run could still show [number] given what is written in it.
  ///
  /// Blank cells constrain nothing, so this is a prefix-free match at whatever
  /// positions the player has reached: writing the last digit of a run first is
  /// allowed, and still has to be the right one.
  bool compatible(int run, int number, List<int> values) {
    final text = numbers[number];
    if (text.length != runs[run].length) return false;
    final cells = _runCells[run];
    for (var i = 0; i < cells.length; i++) {
      final value = values[cells[i]];
      if (value == kCrossingEmpty) continue;
      if (value != text.codeUnitAt(i) - 48) return false;
    }
    return true;
  }

  /// Whether [values] is the filling: every listed number appears exactly once
  /// and no cell holds a digit outside a placement.
  ///
  /// This is the win test, and it is not "the grid is full" — the grid *is*
  /// full of digits in any board the model finishes, because a run is never
  /// half filled. It is the number list that has to come out even.
  bool isSolution(List<int> values) {
    if (values.length != cellCount) return false;
    for (var cell = 0; cell < cellCount; cell++) {
      final value = values[cell];
      if (isWall(cell)) {
        // A digit on a wall is a digit outside a placement.
        if (value != kCrossingEmpty) return false;
        continue;
      }
      if (value < 1 || value > 9) return false;
    }
    final used = List<bool>.filled(numbers.length, false);
    for (var run = 0; run < runCount; run++) {
      final at = numberIndex(runText(run, values));
      if (at < 0) return false;
      if (used[at]) return false;
      used[at] = true;
    }
    // One number per run and one run per number, so this can only be false when
    // the counts disagree — which is a broken board, not a broken answer.
    return used.every((taken) => taken);
  }

  /// Whether a half-filled board has not gone wrong yet.
  ///
  /// A blank cell breaks no rule. A run whose written digits no number can
  /// match, a run that spells no listed number, or one number used by two runs
  /// are mistakes, and the board shows them as they are made.
  bool isLegal(List<int> values) {
    if (values.length != cellCount) return false;
    for (var cell = 0; cell < cellCount; cell++) {
      final value = values[cell];
      if (isWall(cell)) {
        if (value != kCrossingEmpty) return false;
        continue;
      }
      if (value != kCrossingEmpty && (value < 1 || value > 9)) return false;
    }
    final used = <int>{};
    for (var run = 0; run < runCount; run++) {
      final text = runText(run, values);
      if (text.isNotEmpty) {
        final at = numberIndex(text);
        if (at < 0) return false;
        if (!used.add(at)) return false;
        continue;
      }
      // Not full: it still has to be able to become a number nobody has used.
      var possible = false;
      for (var number = 0; number < numbers.length; number++) {
        if (used.contains(number)) continue;
        if (!compatible(run, number, values)) continue;
        possible = true;
        break;
      }
      if (!possible) return false;
    }
    return true;
  }

  /// The cells that break a rule on [values], for the board to paint red.
  Set<int> conflicts(List<int> values) {
    final bad = <int>{};
    final byNumber = <int, List<int>>{};
    for (var run = 0; run < runCount; run++) {
      final text = runText(run, values);
      if (text.isEmpty) {
        // Half a run: accuse it only when nothing can finish it.
        var possible = false;
        for (var number = 0; number < numbers.length; number++) {
          if (compatible(run, number, values)) {
            possible = true;
            break;
          }
        }
        if (!possible) {
          for (final cell in _runCells[run]) {
            if (values[cell] != kCrossingEmpty) bad.add(cell);
          }
        }
        continue;
      }
      final at = numberIndex(text);
      if (at < 0) {
        bad.addAll(_runCells[run]);
      } else {
        (byNumber[at] ??= []).add(run);
      }
    }
    // One number cannot be in two places at once; both runs are wrong.
    byNumber.forEach((_, at) {
      if (at.length < 2) return;
      for (final run in at) {
        bad.addAll(_runCells[run]);
      }
    });
    for (var cell = 0; cell < cellCount; cell++) {
      if (isWall(cell) && values[cell] != kCrossingEmpty) bad.add(cell);
    }
    return bad;
  }

  /// Cells still waiting for a digit, walls excluded.
  int blankCount(List<int> values) => [for (var c = 0; c < cellCount; c++) c]
      .where((c) => !isWall(c) && values[c] == kCrossingEmpty)
      .length;
}
