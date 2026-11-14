import 'dart:math';

enum CellState { hidden, revealed, flagged }

class MinesweeperCell {
  final int row;
  final int col;
  final bool isMine;
  final int neighborMines;
  final CellState state;

  const MinesweeperCell({
    required this.row,
    required this.col,
    required this.isMine,
    this.neighborMines = 0,
    this.state = CellState.hidden,
  });

  MinesweeperCell copyWith({
    CellState? state,
  }) {
    return MinesweeperCell(
      row: row,
      col: col,
      isMine: isMine,
      neighborMines: neighborMines,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MinesweeperCell &&
          row == other.row &&
          col == other.col &&
          isMine == other.isMine &&
          neighborMines == other.neighborMines &&
          state == other.state;

  @override
  int get hashCode => Object.hash(row, col, isMine, neighborMines, state);
}

/// One numbered cell as a solver sees it: its value and the cells it still has to explain.
class _Clue {
  final int mines;
  final Set<int> unknown;

  const _Clue(this.mines, this.unknown);
}

class MinesweeperEngine {
  final int rows;
  final int cols;
  final int mineCount;
  final Random _random;

  /// How many deals to try before giving up on finding one that a player can finish by
  /// reasoning. A 6x6 board with 5 mines is accepted on most attempts; the wide sizes take
  /// more, and the loop is cheap (a few thousand constraint passes at worst).
  static const int maxDeals = 400;

  MinesweeperEngine({
    this.rows = 10,
    this.cols = 8,
    this.mineCount = 12,
    Random? random,
  }) : _random = random ?? Random();

  /// Deals a board.
  ///
  /// With a first tap (`startRow`, `startCol`) the deal is guaranteed to be solvable without
  /// ever guessing: the start and its neighbours are mine-free, the reveal from there is
  /// played out, and the deal is accepted only if straightforward deduction (numbers, subsets
  /// and the mine count) finishes the board. That is the same reasoning a player does, so a
  /// no-guess deal is a fair deal: there is always a next cell that is certainly safe or
  /// certainly a mine, and no step needs luck.
  List<List<MinesweeperCell>> generateBoard({int? startRow, int? startCol}) {
    if (startRow == null || startCol == null) {
      return _build(_placeMines());
    }
    final available = rows * cols - _blockedAround(startRow, startCol).length;
    if (mineCount > available) {
      throw ArgumentError(
        'a $rows x $cols board cannot hide $mineCount mines and keep the first tap open',
      );
    }
    for (var attempt = 0; attempt < maxDeals; attempt++) {
      final mines = _placeMines(startRow, startCol);
      final board = _build(mines);
      if (isSolvableWithoutGuess(board, startRow, startCol)) {
        return board;
      }
    }
    // An expert board (16x12 with 45 mines) has almost no fair deals: at that density the
    // deduction a phone game offers cannot finish a random board. Refusing to deal is the
    // honest answer; a board that needs a guess is not a puzzle, and dealing an easier board
    // than the size asks for would be a quiet lie about the level. A size this dense needs a
    // stronger generator (constraint-programming solver) before it can be offered.
    throw StateError(
      'no $rows x $cols minesweeper deal with $mineCount mines is provably solvable without a '
      'guess after $maxDeals attempts; that density is too high to deal fairly',
    );
  }

  /// True when a player who only uses what the numbers say can finish the board: no cell ever
  /// has to be guessed. The board is left untouched; this is the guarantee `generateBoard`
  /// makes when it deals a first tap.
  bool isSolvableWithoutGuess(
    List<List<MinesweeperCell>> board,
    int startRow,
    int startCol,
  ) {
    final mines = List.generate(
      rows,
      (r) => List.generate(cols, (c) => board[r][c].isMine),
    );
    return _solverFindsIt(mines, startRow, startCol);
  }

  /// Every cell the deal can put a mine in, i.e. everything but the first tap's 3x3 block.
  List<List<bool>> _placeMines([int? startRow, int? startCol]) {
    final mines = List.generate(rows, (_) => List.filled(cols, false));
    final blocked = startRow == null || startCol == null
        ? <int>{}
        : _blockedAround(startRow, startCol);
    final candidates = <int>[
      for (var i = 0; i < rows * cols; i++)
        if (!blocked.contains(i)) i,
    ];
    candidates.shuffle(_random);
    for (final index in candidates.take(mineCount)) {
      mines[index ~/ cols][index % cols] = true;
    }
    if (mines.any((row) => row.any((isMine) => isMine)) == false) {
      throw StateError('a deal with no mines is not a puzzle');
    }
    return mines;
  }

  Set<int> _blockedAround(int startRow, int startCol) {
    final blocked = <int>{};
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final r = startRow + dr;
        final c = startCol + dc;
        if (r >= 0 && r < rows && c >= 0 && c < cols) blocked.add(r * cols + c);
      }
    }
    return blocked;
  }

  List<List<MinesweeperCell>> _build(List<List<bool>> mines) {
    return List.generate(rows, (r) {
      return List.generate(cols, (c) {
        var neighbors = 0;
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            final nr = r + dr;
            final nc = c + dc;
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && mines[nr][nc]) {
              neighbors++;
            }
          }
        }
        return MinesweeperCell(
          row: r,
          col: c,
          isMine: mines[r][c],
          neighborMines: neighbors,
        );
      });
    });
  }

  int _count(List<List<bool>> mines, int r, int c) {
    var n = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = c + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && mines[nr][nc]) n++;
      }
    }
    return n;
  }

  Iterable<List<int>> _neighbours(int r, int c) sync* {
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = c + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) yield [nr, nc];
      }
    }
  }

  /// The player's reasoning, played out from the first tap: reveal, read the numbers, reveal
  /// cells a clue accounts for, flag cells a clue proves, repeat. Returns true when every
  /// non-mine cell is open.
  bool _solverFindsIt(List<List<bool>> mines, int startRow, int startCol) {
    final revealed = List.generate(rows, (_) => List.filled(cols, false));
    final flagged = List.generate(rows, (_) => List.filled(cols, false));
    if (mines[startRow][startCol]) return false;

    _floodReveal(mines, revealed, startRow, startCol);

    var safeTotal = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!mines[r][c]) safeTotal++;
      }
    }

    while (true) {
      var revealedSafe = 0;
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          if (revealed[r][c] && !mines[r][c]) revealedSafe++;
        }
      }
      if (revealedSafe == safeTotal) return true;

      final clues = <_Clue>[];
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          if (!revealed[r][c]) continue;
          var minesAround = 0;
          final unknown = <int>{};
          for (final cell in _neighbours(r, c)) {
            final nr = cell[0];
            final nc = cell[1];
            if (flagged[nr][nc]) {
              minesAround++;
            } else if (!revealed[nr][nc]) {
              unknown.add(nr * cols + nc);
            }
          }
          if (unknown.isEmpty) continue;
          clues.add(_Clue(_count(mines, r, c) - minesAround, unknown));
        }
      }
      if (clues.isEmpty) return false;

      var changed = false;
      final provenSafe = <int>{};
      final provenMines = <int>{};

      for (final clue in clues) {
        if (clue.mines < 0 || clue.mines > clue.unknown.length) {
          // Two clues disagree, so the reasoning itself is unsound; never happens on a legal
          // board, but a board that produces it is not one to deal.
          return false;
        }
        if (clue.mines == 0) provenSafe.addAll(clue.unknown);
        if (clue.mines == clue.unknown.length) provenMines.addAll(clue.unknown);
      }

      // Subset rule: if one clue's unknowns are inside another's, the difference is decided.
      final sorted = [...clues]
        ..sort((a, b) => a.unknown.length - b.unknown.length);
      for (var i = 0; i < sorted.length; i++) {
        for (var j = i + 1; j < sorted.length; j++) {
          final small = sorted[i];
          final big = sorted[j];
          if (!small.unknown.every(big.unknown.contains)) continue;
          final rest = big.unknown.difference(small.unknown);
          if (rest.isEmpty) continue;
          final delta = big.mines - small.mines;
          if (delta == 0) provenSafe.addAll(rest);
          if (delta == rest.length) provenMines.addAll(rest);
        }
      }

      // The mine count is information too: it is on screen from the first cell.
      final hidden = <int>[];
      var flaggedCount = 0;
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          if (flagged[r][c]) flaggedCount++;
          if (!revealed[r][c] && !flagged[r][c]) hidden.add(r * cols + c);
        }
      }
      final left = mineCount - flaggedCount;
      if (left == 0) provenSafe.addAll(hidden);
      if (left == hidden.length) provenMines.addAll(hidden);

      provenMines.removeAll(provenSafe);
      for (final index in provenSafe) {
        final r = index ~/ cols;
        final c = index % cols;
        if (revealed[r][c] || flagged[r][c]) continue;
        _floodReveal(mines, revealed, r, c);
        changed = true;
      }
      for (final index in provenMines) {
        final r = index ~/ cols;
        final c = index % cols;
        if (revealed[r][c] || flagged[r][c]) continue;
        flagged[r][c] = true;
        changed = true;
      }
      if (!changed) return false;
    }
  }

  void _floodReveal(
    List<List<bool>> mines,
    List<List<bool>> revealed,
    int r,
    int c,
  ) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return;
    if (revealed[r][c] || mines[r][c]) return;
    revealed[r][c] = true;
    if (_count(mines, r, c) != 0) return;
    for (final cell in _neighbours(r, c)) {
      _floodReveal(mines, revealed, cell[0], cell[1]);
    }
  }

  List<List<MinesweeperCell>> revealEmptyCells(
      List<List<MinesweeperCell>> board, int r, int c) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return board;
    if (board[r][c].state != CellState.hidden || board[r][c].isMine) {
      return board;
    }

    board[r][c] = board[r][c].copyWith(state: CellState.revealed);

    if (board[r][c].neighborMines == 0) {
      for (var i = -1; i <= 1; i++) {
        for (var j = -1; j <= 1; j++) {
          revealEmptyCells(board, r + i, c + j);
        }
      }
    }
    return board;
  }

  bool checkWin(List<List<MinesweeperCell>> board) {
    for (var row in board) {
      for (var cell in row) {
        if (!cell.isMine && cell.state != CellState.revealed) {
          return false;
        }
      }
    }
    return true;
  }
}
