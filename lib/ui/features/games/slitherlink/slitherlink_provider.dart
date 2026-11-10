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
  });

  final SlitherlinkLevel level;
  final List<List<bool>> currentHEdges;
  final List<List<bool>> currentVEdges;
  final bool isSolved;

  SlitherlinkState copyWith({
    SlitherlinkLevel? level,
    List<List<bool>>? currentHEdges,
    List<List<bool>>? currentVEdges,
    bool? isSolved,
  }) {
    return SlitherlinkState(
      level: level ?? this.level,
      currentHEdges: currentHEdges ?? this.currentHEdges,
      currentVEdges: currentVEdges ?? this.currentVEdges,
      isSolved: isSolved ?? this.isSolved,
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
