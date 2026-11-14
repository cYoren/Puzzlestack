import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'akari_engine.dart';

part 'akari_provider.g.dart';

class AkariState {
  final IList<IList<int>> grid; // -2: white, -1: wall, 0-4: numbered wall
  final IList<IList<bool>> bulbs;
  final IList<IList<bool>> lit;
  final bool isVictory;
  final bool isLoading;

  /// Encoded `row * size + col` cells that are already wrong: two bulbs in
  /// sight of each other, or a numbered wall with too many bulbs around it.
  final Set<int> conflicts;

  AkariState({
    required this.grid,
    required this.bulbs,
    required this.lit,
    this.isVictory = false,
    this.isLoading = true,
    this.conflicts = const <int>{},
  });

  AkariState copyWith({
    IList<IList<int>>? grid,
    IList<IList<bool>>? bulbs,
    IList<IList<bool>>? lit,
    bool? isVictory,
    bool? isLoading,
    Set<int>? conflicts,
  }) {
    return AkariState(
      grid: grid ?? this.grid,
      bulbs: bulbs ?? this.bulbs,
      lit: lit ?? this.lit,
      isVictory: isVictory ?? this.isVictory,
      isLoading: isLoading ?? this.isLoading,
      conflicts: conflicts ?? this.conflicts,
    );
  }
}

@riverpod
class AkariNotifier extends _$AkariNotifier {
  final _engine = AkariEngine();

  @override
  AkariState build() {
    return AkariState(
      grid: <IList<int>>[].lock,
      bulbs: <IList<bool>>[].lock,
      lit: <IList<bool>>[].lock,
    );
  }

  void initGame() {
    final level = _engine.generateLevel();
    final grid = level['grid'] as List<List<int>>;
    final size = grid.length;
    
    final immutableGrid = grid.map((r) => r.lock).toIList();
    final immutableBulbs = List.generate(size, (_) => List.filled(size, false).lock).toIList();
    
    final initialBulbs = List.generate(size, (_) => List.filled(size, false));
    final newLit = AkariEngine.calculateLit(grid, initialBulbs);
    
    state = AkariState(
      grid: immutableGrid,
      bulbs: immutableBulbs,
      lit: newLit.map((r) => r.lock).toIList(),
      isLoading: false,
    );
  }

  void toggleBulb(int r, int c) {
    if (state.isVictory || state.grid[r][c] != -2) return;

    final bulbs = state.bulbs.map((row) => row.toList()).toList();
    bulbs[r][c] = !bulbs[r][c];
    
    final grid = state.grid.map((r) => r.toList()).toList();
    final newLit = AkariEngine.calculateLit(grid, bulbs);
    final isVictory = AkariEngine.checkVictory(grid, bulbs, newLit);

    state = state.copyWith(
      bulbs: bulbs.map((row) => row.lock).toIList(),
      lit: newLit.map((r) => r.lock).toIList(),
      isVictory: isVictory,
      conflicts: AkariEngine.conflicts(grid, bulbs),
    );
  }

  /// Places a full, valid answer. Used by the shell's solve button; the board
  /// still checks the answer against the clues rather than against a key.
  void solve() {
    if (state.isVictory || state.isLoading) return;
    final grid = state.grid.map((row) => row.toList()).toList();
    final answer = AkariEngine.solve(grid);
    if (answer == null) return;
    final lit = AkariEngine.calculateLit(grid, answer);
    state = state.copyWith(
      bulbs: answer.map((row) => row.lock).toIList(),
      lit: lit.map((row) => row.lock).toIList(),
      isVictory: true,
      conflicts: const <int>{},
    );
  }

  /// Puts one bulb the answer needs, without filling the board. A hint, not a
  /// solve: it names a bulb and lets the player carry on.
  void hint() {
    if (state.isVictory || state.isLoading) return;
    final grid = state.grid.map((row) => row.toList()).toList();
    final answer = AkariEngine.solve(grid);
    if (answer == null) return;
    final bulbs = state.bulbs.map((row) => row.toList()).toList();
    for (var r = 0; r < bulbs.length; r++) {
      for (var c = 0; c < bulbs.length; c++) {
        if (answer[r][c] && !bulbs[r][c]) {
          bulbs[r][c] = true;
          final lit = AkariEngine.calculateLit(grid, bulbs);
          state = state.copyWith(
            bulbs: bulbs.map((row) => row.lock).toIList(),
            lit: lit.map((row) => row.lock).toIList(),
            isVictory: AkariEngine.checkVictory(grid, bulbs, lit),
            conflicts: AkariEngine.conflicts(grid, bulbs),
          );
          return;
        }
      }
    }
  }
}
