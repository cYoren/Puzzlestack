import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/puzzle_board.dart';
import 'signpost_engine.dart';

part 'signpost_provider.g.dart';

/// A link the rules can prove, and where it goes.
typedef SignpostHint = ({int from, int to});

@immutable
class SignpostState extends PuzzleState {
  SignpostState({
    required this.puzzle,
    required List<int> links,
    required this.difficulty,
    this.selected,
    this.moves = 0,
    this.hint,
  })  : links = List<int>.unmodifiable(links),
        position = SignpostPosition.of(puzzle, links);

  final SignpostPuzzle puzzle;

  /// For each cell, the cell that follows it, or -1. This is the board: the
  /// numbers are read off the links, so rewiring one never rewrites a number.
  final List<int> links;

  /// Everything that follows from [links]: the numbers, the chains, and
  /// whether the links have gone wrong.
  final SignpostPosition position;

  final SignpostDifficulty difficulty;

  /// The cell the player is joining from, if they tapped one.
  final int? selected;

  final int moves;

  /// The link the hint button is offering, cleared on the next move.
  final SignpostHint? hint;

  int get rows => puzzle.rows;

  int get cols => puzzle.cols;

  int get clueCount => puzzle.clueCount;

  int get linkedCount => links.where((link) => link >= 0).length;

  bool get isSolved => const SignpostEngine().isSolved(puzzle, links);

  SignpostState copyWith({
    List<int>? links,
    int? selected,
    bool clearSelected = false,
    int? moves,
    SignpostHint? hint,
    bool clearHint = false,
  }) =>
      SignpostState(
        puzzle: puzzle,
        links: links ?? this.links,
        difficulty: difficulty,
        selected: clearSelected ? null : (selected ?? this.selected),
        moves: moves ?? this.moves,
        hint: clearHint ? null : (hint ?? this.hint),
      );
}

@riverpod
class SignpostNotifier extends _$SignpostNotifier {
  final SignpostEngine _engine = const SignpostEngine();

  @override
  SignpostState build() => _newPuzzle(SignpostDifficulty.easy);

  SignpostState _newPuzzle(SignpostDifficulty difficulty) {
    final puzzle = _engine.generate(difficulty);
    return SignpostState(
      puzzle: puzzle,
      links: List<int>.filled(puzzle.cellCount, -1),
      difficulty: difficulty,
    );
  }

  void newGame() => state = _newPuzzle(state.difficulty);

  void setDifficulty(SignpostDifficulty difficulty) {
    if (difficulty == state.difficulty) return;
    state = _newPuzzle(difficulty);
  }

  /// Joins two cells. Refused when the arrow does not run through the target,
  /// when either end already has a link, or when the numbers could not fit.
  bool link({required int from, required int to}) {
    if (state.isSolved) return false;
    if (!_engine.legal(state.position, state.puzzle, from, to)) return false;
    state = state.copyWith(
      links: [...state.links]..[from] = to,
      moves: state.moves + 1,
      clearSelected: true,
      clearHint: true,
    );
    return true;
  }

  /// Takes a link out again, which splits one chain into two.
  void unlink(int cell) {
    if (state.isSolved) return;
    if (state.links[cell] < 0) return;
    state = state.copyWith(
      links: [...state.links]..[cell] = -1,
      moves: state.moves + 1,
      clearSelected: true,
      clearHint: true,
    );
  }

  void select(int? cell) {
    if (state.isSolved) return;
    state = state.copyWith(
      selected: cell,
      clearSelected: cell == null,
      clearHint: true,
    );
  }

  /// Applies a move the board built, which already knows which link it makes.
  void applyBoardMove(PuzzleMove<SignpostState> move) {
    if (state.isSolved) return;
    final next = move.apply(state);
    if (identical(next, state)) return;
    state = next;
  }

  /// One link the rules can prove from the board as it stands.
  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.links);
    if (found == null) return;
    state = state.copyWith(hint: found, selected: found.from);
  }

  /// Writes the answer's links.
  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      links: _engine.answerLinks(state.puzzle),
      clearSelected: true,
      clearHint: true,
    );
  }
}
