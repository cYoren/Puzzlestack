import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/board/next_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'salad_engine.dart';
import 'salad_puzzle.dart';

part 'salad_provider.g.dart';

@immutable
class SaladState extends PuzzleState {
  const SaladState({
    required this.puzzle,
    required this.values,
    required this.size,
    this.selected,
    this.isSolved = false,
    this.hintCell,
  });

  final SaladPuzzle puzzle;

  /// Per cell, what the player wrote: [kSaladBlank] when nothing is written, a
  /// letter `1..nums`, or [kSaladHole] for a hole.
  final List<int> values;

  final SaladSize size;
  final int? selected;
  final bool isSolved;

  /// The cell the last hint wrote, so the board can ring it.
  final int? hintCell;

  int get n => puzzle.n;

  int get nums => puzzle.nums;

  /// Cells the player has written something in, a hole included.
  int get written => values.where((value) => value != kSaladBlank).length;

  /// Cells the player has made impossible, so the board can paint them.
  Set<int> get conflicts => puzzle.conflicts(values);

  SaladState copyWith({
    List<int>? values,
    int? selected,
    bool clearSelection = false,
    bool? isSolved,
    int? hintCell,
    bool clearHint = false,
  }) {
    return SaladState(
      puzzle: puzzle,
      values: values ?? this.values,
      size: size,
      selected: clearSelection ? null : (selected ?? this.selected),
      isSolved: isSolved ?? this.isSolved,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
    );
  }
}

@riverpod
class SaladNotifier extends _$SaladNotifier {
  final SaladEngine _engine = const SaladEngine();

  /// One board ahead, per size.
  ///
  /// Salad's generator costs about 12ms at 5x5 and 270ms at 7x7 (measured, see
  /// [SaladEngine.generate]), and paying that on the tap is what made "play
  /// again" and the size chips feel like a screen that had stopped. The cache
  /// builds them after the board on screen has been painted, so both taps take
  /// a board that already exists.
  NextBoard<SaladSize, SaladPuzzle>? _boards;

  NextBoard<SaladSize, SaladPuzzle> get _next => _boards ??=
      NextBoard<SaladSize, SaladPuzzle>((size) => _engine.generate(size));

  /// How many boards this game has built. Warm-ups count; a tap that finds its
  /// board ready does not.
  int get boardsBuilt => _boards?.built ?? 0;

  @override
  SaladState build() {
    // A rebuild starts the cache over; the old one's queued warm-ups go with
    // it, so nothing is generated for a board nobody will see.
    _boards?.dispose();
    _boards = null;
    final boards = _next;
    ref.onDispose(boards.dispose);
    return _newPuzzle(SaladSize.medium);
  }

  /// Every cell starts blank. Salad prints its clues on the border, so nothing
  /// in the grid is given and the values start empty — the three vocabularies
  /// never meet in one array until the player writes.
  SaladState _newPuzzle(SaladSize size) {
    final puzzle = _next.take(size);
    _warm(size);
    return SaladState(
      puzzle: puzzle,
      values: List<int>.filled(size.cellCount, kSaladBlank),
      size: size,
    );
  }

  /// Makes the board the next tap will ask for: the size in hand first, then
  /// every other size the chips offer.
  void _warm(SaladSize first) => _next.fill(SaladSize.values, first: first);

  void newGame() => state = _newPuzzle(state.size);

  void setSize(SaladSize size) {
    if (size == state.size) return;
    state = _newPuzzle(size);
  }

  /// The value one tap writes in [cell].
  ///
  /// A cycle rather than a keypad — hole, then the letters, then back to a hole.
  /// A hole is a real value here, not an empty cell, so the cycle has no "clear"
  /// step to fall out of: the player can always get back to a hole.
  static int nextValue(int current, int nums) {
    if (current == kSaladBlank) return kSaladHole;
    if (current >= nums) return kSaladHole;
    return current + 1;
  }

  /// Cycles one cell. This is the only way a value reaches the board.
  void tap(int cell) {
    if (state.isSolved) return;
    if (cell < 0 || cell >= state.values.length) return;
    final values = [...state.values];
    values[cell] = nextValue(values[cell], state.nums);
    final next =
        state.copyWith(values: values, selected: cell, clearHint: true);
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, values));
  }

  /// Applies one value the rules prove.
  ///
  /// It writes the value rather than outlining the cell: a ring says "something
  /// is here" and the player still has to work out which of the letters, or
  /// whether it is a hole at all, it is.
  void hint() {
    if (state.isSolved) return;
    final found = _engine.hint(state.puzzle, state.values);
    if (found == null) return;
    final values = [...state.values];
    values[found.cell] = found.symbol;
    final next = state.copyWith(values: values, hintCell: found.cell);
    state = next.copyWith(isSolved: _engine.isSolved(state.puzzle, values));
  }

  /// The lowest rule level that finishes the board, or null when the rules run
  /// out. Not shown on the card: the number is a fact about the deal, not a
  /// thing the player can act on.
  int? get level => _engine.levelOf(state.puzzle);

  /// Writes the answer.
  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      values: List<int>.from(state.puzzle.solution),
      clearSelection: true,
      clearHint: true,
      isSolved: true,
    );
  }
}
