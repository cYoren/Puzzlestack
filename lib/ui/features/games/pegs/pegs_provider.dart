import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'pegs_engine.dart';

part 'pegs_provider.g.dart';

@immutable
class PegsState extends PuzzleState {
  const PegsState({
    required this.puzzle,
    required this.grid,
    required this.difficulty,
    this.selected,
    this.isSolved = false,
    this.hint,
  });

  final PegsPuzzle puzzle;
  final List<PegCell> grid;
  final PegsDifficulty difficulty;

  /// The peg the player has picked up, as a flat index. Tap-only play needs
  /// this: pick a peg, then tap where it lands.
  final int? selected;

  final bool isSolved;

  /// The jump the hint button is offering, cleared on the next move.
  final PegsJump? hint;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  int get pegsLeft => grid.where((c) => c == PegCell.peg).length;

  PegsState copyWith({
    List<PegCell>? grid,
    int? selected,
    bool clearSelection = false,
    bool? isSolved,
    PegsJump? hint,
    bool clearHint = false,
  }) {
    return PegsState(
      puzzle: puzzle,
      grid: grid ?? this.grid,
      difficulty: difficulty,
      selected: clearSelection ? null : (selected ?? this.selected),
      isSolved: isSolved ?? this.isSolved,
      hint: clearHint ? null : (hint ?? this.hint),
    );
  }
}

@riverpod
class PegsNotifier extends _$PegsNotifier {
  final PegsEngine _engine = const PegsEngine();

  @override
  PegsState build() => _newPuzzle(PegsDifficulty.medium);

  PegsState _newPuzzle(PegsDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty: difficulty);
    return PegsState(
      puzzle: puzzle,
      grid: puzzle.start,
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(PegsDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  void applyMove(PuzzleMove<PegsState> move) {
    if (state.isSolved) return;
    final next = move.apply(state);
    state = next.copyWith(isSolved: _engine.isSolved(next.grid));
  }

  /// One jump that still leads to a solution. The hint never plays the move
  /// for the player.
  ///
  /// The board already knows a line from where it started, so while the player
  /// is still on it the hint is exact and free. Once they step off, a bounded
  /// search looks for a new line; if that runs out of budget the hint falls
  /// back to the first legal jump rather than pretending.
  PegsJump? hint() {
    if (state.isSolved) return null;
    final jumps = _engine.legalJumps(state.grid, state.rows, state.cols);
    if (jumps.isEmpty) return null;

    final jump = _nextOnKnownLine() ??
        _engine
            .solve(state.grid, state.rows, state.cols, maxNodes: 120000)
            ?.first ??
        jumps.first;

    state = state.copyWith(hint: jump);
    return jump;
  }

  /// The next jump of the line the board was generated from, when the player
  /// has not left it.
  PegsJump? _nextOnKnownLine() {
    final puzzle = state.puzzle;
    var grid = [...puzzle.start];
    for (final jump in puzzle.solution) {
      if (_sameGrid(grid, state.grid)) return jump;
      if (!_engine
          .legalJumps(grid, puzzle.rows, puzzle.cols)
          .contains(jump)) {
        return null;
      }
      grid = _engine.apply(grid, jump);
    }
    return null;
  }

  bool _sameGrid(List<PegCell> a, List<PegCell> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Replays the generator's line, which by construction ends on one peg.
  void solve() {
    if (state.isSolved) return;
    var grid = List<PegCell>.from(state.puzzle.start);
    for (final jump in state.puzzle.solution) {
      grid = _engine.apply(grid, jump);
    }
    state = state.copyWith(
      grid: grid,
      clearSelection: true,
      clearHint: true,
      isSolved: _engine.isSolved(grid),
    );
  }
}
