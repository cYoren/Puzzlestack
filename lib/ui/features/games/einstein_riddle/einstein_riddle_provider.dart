import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'einstein_riddle_engine.dart';

part 'einstein_riddle_provider.g.dart';

class EinsteinRiddleState {
  final List<String> categories;
  final Map<String, List<String>> options;
  final List<String> clues;
  final Map<String, Map<String, String>> userSolution; // House -> Category -> Value
  final Map<String, Map<String, String>> actualSolution;
  final bool isVictory;
  final bool isLoading;

  EinsteinRiddleState({
    required this.categories,
    required this.options,
    required this.clues,
    required this.userSolution,
    required this.actualSolution,
    this.isVictory = false,
    this.isLoading = true,
  });

  EinsteinRiddleState copyWith({
    List<String>? categories,
    Map<String, List<String>>? options,
    List<String>? clues,
    Map<String, Map<String, String>>? userSolution,
    Map<String, Map<String, String>>? actualSolution,
    bool? isVictory,
    bool? isLoading,
  }) {
    return EinsteinRiddleState(
      categories: categories ?? this.categories,
      options: options ?? this.options,
      clues: clues ?? this.clues,
      userSolution: userSolution ?? this.userSolution,
      actualSolution: actualSolution ?? this.actualSolution,
      isVictory: isVictory ?? this.isVictory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class EinsteinRiddleNotifier extends _$EinsteinRiddleNotifier {
  final _engine = EinsteinRiddleEngine();

  @override
  EinsteinRiddleState build() {
    return EinsteinRiddleState(
      categories: [],
      options: {},
      clues: [],
      userSolution: {},
      actualSolution: {},
    );
  }

  void initGame() {
    state = state.copyWith(isLoading: true, isVictory: false);
    
    final level = _engine.generatePuzzle();
    final houses = level['options']['House'] as List<String>;
    
    Map<String, Map<String, String>> userSolution = {};
    for (var house in houses) {
      userSolution[house] = {};
    }

    state = EinsteinRiddleState(
      categories: List<String>.from(level['categories']),
      options: Map<String, List<String>>.from(level['options']),
      clues: List<String>.from(level['clues']),
      userSolution: userSolution,
      actualSolution: Map<String, Map<String, String>>.from(level['solution']),
      isLoading: false,
    );
  }

  /// Assigns [value] to [house]'s [category].
  ///
  /// Returns false when the value is already used in that category, because in
  /// this puzzle every value belongs to exactly one house. The old version
  /// accepted the duplicate silently and then refused to win, with nothing on
  /// screen to explain why.
  bool updateAssignment(String house, String category, String value) {
    if (state.isVictory) return false;
    for (final entry in state.userSolution.entries) {
      if (entry.key != house && entry.value[category] == value) return false;
    }

    final newUserSolution = Map<String, Map<String, String>>.from(
      state.userSolution.map((k, v) => MapEntry(k, Map<String, String>.from(v)))
    );

    newUserSolution[house]![category] = value;

    state = state.copyWith(userSolution: newUserSolution);
    _checkVictory();
    return true;
  }

  void _checkVictory() {
    if (_engine.checkVictory(state.userSolution, state.actualSolution)) {
      state = state.copyWith(isVictory: true);
    }
  }
}
