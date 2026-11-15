/// Seismic: Ripple Effect. The board is cut into regions, and the numbers
/// repeat until no two of them are close enough to touch.
///
/// The rules are Hakyuu's (see `seismic.c` in `x-sheep/puzzles-unreleased`,
/// MIT, pinned in `REFERENCE.md`), and they are the whole game:
///
///  * a region of N cells holds 1..N, once each;
///  * two equal numbers in one row or column must have at least that many
///    cells between them, so the digit d keeps its neighbours d cells away;
///  * every given number on the board is true of the answer.
///
/// Three vocabularies live in this file and they are deliberately separate:
///
///  * a cell of the answer holds a digit 1..N. There is no zero in an answer.
///  * a *clue* is a digit printed on the board, or [kSeismicNoClue]. A clue
///    of zero is impossible, so the two never collide.
///  * a *player cell* is a digit, or [kSeismicBlank] when nothing is written.
///
/// Sharing one zero between "no clue" and "blank" is the bug that cost three
/// rounds in the Boats port, so this file spells all three separately.
library;

/// The three boards the game ships.
///
/// The feed size is 6x6: it is the default in the C collection, it is small
/// enough for a first-timer to finish in about a minute, and it is the first
/// size where the ripple rule actually bites. 4x4 and 7x7 are the Stack's.
enum SeismicSize {
  small(4),
  medium(6),
  large(7);

  const SeismicSize(this.n);

  /// Side of the square grid. A region is at most this many cells.
  final int n;

  int get cellCount => n * n;
}

/// Nothing printed on this cell.
const int kSeismicNoClue = 0;

/// Nothing written in this cell by the player.
const int kSeismicBlank = 0;

/// A Seismic board: the region layout, the clues, and the one answer.
class SeismicPuzzle {
  SeismicPuzzle({
    required this.size,
    required this.regions,
    required this.regionSizes,
    required this.givens,
    required this.solution,
  })  : assert(regions.length == size.cellCount),
        assert(givens.length == size.cellCount),
        assert(solution.length == size.cellCount),
        assert(regions.every((region) => region >= 0));

  final SeismicSize size;

  /// Per cell, which region it belongs to. Regions are numbered 0..r-1.
  final List<int> regions;

  /// The number of cells in each region, by region number.
  final List<int> regionSizes;

  /// Per cell, the printed digit, or [kSeismicNoClue].
  final List<int> givens;

  /// Per cell, the unique answer. Digits 1..regionSize.
  final List<int> solution;

  int get n => size.n;

  int get cellCount => size.cellCount;

  /// The largest digit the board can hold.
  int get maxDigit =>
      regionSizes.isEmpty ? 0 : regionSizes.reduce((a, b) => a > b ? a : b);

  int cell(int row, int col) => row * n + col;

  int row(int cell) => cell ~/ n;

  int col(int cell) => cell % n;

  int regionOf(int cell) => regions[cell];

  int regionSizeOf(int cell) => regionSizes[regions[cell]];

  int given(int cell) => givens[cell];

  int givenCount() => givens.where((value) => value != kSeismicNoClue).length;

  bool sameRegion(int a, int b) => regions[a] == regions[b];

  /// Every cell of [region], in row-major order.
  List<int> cellsOfRegion(int region) {
    final out = <int>[];
    for (var cell = 0; cell < cellCount; cell++) {
      if (regions[cell] == region) out.add(cell);
    }
    return out;
  }

  /// The cells within [digit] steps of [cell] in its row or column, excluding
  /// itself. These are the cells the digit [digit] may not also occupy.
  List<int> inRange(int cell, int digit) {
    final r = row(cell);
    final c = col(cell);
    return [
      for (var step = 1; step <= digit; step++) ...[
        if (c - step >= 0) cell - step,
        if (c + step < n) cell + step,
        if (r - step >= 0) cell - step * n,
        if (r + step < n) cell + step * n,
      ],
    ];
  }

  /// True when [values] is a legal answer: each region holds 1..its size and
  /// no two equal digits are close enough to touch.
  bool isLegal(List<int> values) {
    if (values.length != cellCount) return false;
    for (var cell = 0; cell < cellCount; cell++) {
      final value = values[cell];
      if (value < 1 || value > regionSizeOf(cell)) return false;
    }

    // Each region holds 1..size exactly once.
    for (var region = 0; region < regionSizes.length; region++) {
      final seen = List<bool>.filled(regionSizes[region] + 1, false);
      for (var cell = 0; cell < cellCount; cell++) {
        if (regions[cell] != region) continue;
        final value = values[cell];
        if (value < 1 || value >= seen.length || seen[value]) return false;
        seen[value] = true;
      }
    }

    // The ripple rule, read as a pairwise spacing: two equal digits d must be
    // more than d cells apart. This is the same statement as `inRange`, written
    // the other way round, so the two cannot drift apart.
    for (var cell = 0; cell < cellCount; cell++) {
      final value = values[cell];
      for (var step = 1; step <= value; step++) {
        final c = col(cell);
        final r = row(cell);
        if (c + step < n && values[cell + step] == value) return false;
        if (r + step < n && values[cell + step * n] == value) return false;
        if (c - step >= 0 && values[cell - step] == value) return false;
        if (r - step >= 0 && values[cell - step * n] == value) return false;
      }
    }
    return true;
  }

  /// True when [values] fits every printed number.
  bool matchesGivens(List<int> values) {
    for (var cell = 0; cell < cellCount; cell++) {
      final clue = givens[cell];
      if (clue != kSeismicNoClue && values[cell] != clue) return false;
    }
    return true;
  }

  /// True when the player has finished: a legal answer that agrees with every
  /// clue. Blank cells are not water here — a blank is unfinished work.
  bool isSolved(List<int> values) {
    if (values.any((value) => value == kSeismicBlank)) return false;
    return matchesGivens(values) && isLegal(values);
  }

  /// The cells the player has made impossible, so the board can say so.
  ///
  /// Same tests as [isLegal], reported per cell instead of as a verdict, and
  /// it lives in the puzzle so a test can ask without pumping a screen.
  Set<int> conflicts(List<int> values) {
    final bad = <int>{};
    for (var cell = 0; cell < cellCount; cell++) {
      final value = values[cell];
      if (value == kSeismicBlank) continue;
      if (value > regionSizeOf(cell)) {
        bad.add(cell);
        continue;
      }
      for (var step = 1; step <= value; step++) {
        final c = col(cell);
        final r = row(cell);
        for (final other in [
          if (c + step < n) cell + step,
          if (c - step >= 0) cell - step,
          if (r + step < n) cell + step * n,
          if (r - step >= 0) cell - step * n,
        ]) {
          if (values[other] == value) {
            bad.add(cell);
            bad.add(other);
          }
        }
      }
    }
    // A digit repeated inside a region is impossible even far apart.
    for (var region = 0; region < regionSizes.length; region++) {
      final cells = cellsOfRegion(region);
      for (var i = 0; i < cells.length; i++) {
        for (var j = i + 1; j < cells.length; j++) {
          final a = values[cells[i]];
          final b = values[cells[j]];
          if (a != kSeismicBlank && a == b) {
            bad.add(cells[i]);
            bad.add(cells[j]);
          }
        }
      }
    }
    return bad;
  }
}
