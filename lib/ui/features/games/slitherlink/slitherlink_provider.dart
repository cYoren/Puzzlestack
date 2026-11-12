import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/board/puzzle_board.dart';
import 'slitherlink_engine.dart';

part 'slitherlink_provider.g.dart';

class SlitherlinkState extends PuzzleState {
  const SlitherlinkState({
    required this.level,
    required this.currentHEdges,
    required this.currentVEdges,
    this.isSolved = false,
    this.conflicts = const [],
    this.hintEdge,
  });

  final SlitherlinkLevel level;
  final List<List<bool>> currentHEdges;
  final List<List<bool>> currentVEdges;
  final bool isSolved;

  /// Clues the loop has already broken, recomputed on every move so the board
  /// can paint them red the moment the line lands.
  final List<({int row, int col, int drawn, int clue})> conflicts;

  /// The edge the hint is offering, cleared by the next move.
  final ({bool horizontal, int row, int col})? hintEdge;

  SlitherlinkState copyWith({
    SlitherlinkLevel? level,
    List<List<bool>>? currentHEdges,
    List<List<bool>>? currentVEdges,
    bool? isSolved,
    List<({int row, int col, int drawn, int clue})>? conflicts,
    ({bool horizontal, int row, int col})? hintEdge,
    bool clearHint = false,
  }) {
    return SlitherlinkState(
      level: level ?? this.level,
      currentHEdges: currentHEdges ?? this.currentHEdges,
      currentVEdges: currentVEdges ?? this.currentVEdges,
      isSolved: isSolved ?? this.isSolved,
      conflicts: conflicts ?? this.conflicts,
      hintEdge: clearHint ? null : (hintEdge ?? this.hintEdge),
    );
  }
}

@riverpod
class SlitherlinkNotifier extends _$SlitherlinkNotifier {
  final _engine = SlitherlinkEngine();

  @override
  SlitherlinkState build() {
    final level = _engine.generateLevel(size: 3);
    return SlitherlinkState(
      level: level,
      currentHEdges: List.generate(level.size + 1, (_) => List.filled(level.size, false)),
      currentVEdges: List.generate(level.size, (_) => List.filled(level.size + 1, false)),
    );
  }

  /// The only way this state changes. The board owns the rules; this is a store.
  void applyMove(PuzzleMove<SlitherlinkState> move) {
    if (state.isSolved) return;
    final next = move.apply(state);
    state = next.copyWith(
      isSolved: _engine.isSolved(
        next.level,
        next.currentHEdges,
        next.currentVEdges,
      ),
      conflicts: _engine.brokenClues(
        next.level,
        next.currentHEdges,
        next.currentVEdges,
      ),
      clearHint: true,
    );
  }

  /// Offers the first edge of the answer that is still missing.
  void hint() {
    if (state.isSolved) return;
    final found = _engine.missingEdge(
      state.level,
      state.currentHEdges,
      state.currentVEdges,
    );
    if (found == null) return;
    state = state.copyWith(hintEdge: found);
  }

  /// Draws the answer's loop.
  void solve() {
    if (state.isSolved) return;
    state = state.copyWith(
      currentHEdges: [
        for (final line in state.level.solutionHEdges) List<bool>.from(line),
      ],
      currentVEdges: [
        for (final line in state.level.solutionVEdges) List<bool>.from(line),
      ],
      isSolved: true,
      conflicts: const [],
      clearHint: true,
    );
  }

  void reset() {
    state = SlitherlinkState(
      level: state.level,
      currentHEdges: List.generate(state.level.size + 1, (_) => List.filled(state.level.size, false)),
      currentVEdges: List.generate(state.level.size, (_) => List.filled(state.level.size + 1, false)),
      isSolved: false,
    );
  }

  void newGame() {
    final level = _engine.generateLevel(size: 3);
    state = SlitherlinkState(
      level: level,
      currentHEdges: List.generate(level.size + 1, (_) => List.filled(level.size, false)),
      currentVEdges: List.generate(level.size, (_) => List.filled(level.size + 1, false)),
      isSolved: false,
    );
  }
}
