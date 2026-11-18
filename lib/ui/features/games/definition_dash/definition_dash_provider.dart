import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'definition_dash_engine.dart';

part 'definition_dash_provider.g.dart';

class DefinitionDashState {
  final DefinitionDashPuzzle? puzzle;
  final bool isGameOver;
  final String? selectedDefinition;
  final bool? isCorrect;

  DefinitionDashState({
    this.puzzle,
    this.isGameOver = false,
    this.selectedDefinition,
    this.isCorrect,
  });

  DefinitionDashState copyWith({
    DefinitionDashPuzzle? puzzle,
    bool? isGameOver,
    String? selectedDefinition,
    bool? isCorrect,
  }) {
    return DefinitionDashState(
      puzzle: puzzle ?? this.puzzle,
      isGameOver: isGameOver ?? this.isGameOver,
      selectedDefinition: selectedDefinition ?? this.selectedDefinition,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

@riverpod
class DefinitionDashNotifier extends _$DefinitionDashNotifier {
  final _engine = DefinitionDashEngine();
  bool _disposed = false;
  int _epoch = 0;

  @override
  DefinitionDashState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return DefinitionDashState();
  }

  void startGame() {
    _epoch++;
    final puzzle = _engine.generatePuzzle();
    state = DefinitionDashState(
      puzzle: puzzle,
      isGameOver: false,
    );
  }

  void selectOption(String definition) {
    if (state.isGameOver || state.selectedDefinition != null) return;
    
    final isCorrect = definition == state.puzzle!.correctDefinition;
    state = state.copyWith(
      selectedDefinition: definition,
      isCorrect: isCorrect,
    );

    final callEpoch = _epoch;
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_disposed || callEpoch != _epoch) return;
      state = state.copyWith(isGameOver: true);
    });
  }
}
