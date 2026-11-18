import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'word_surge_engine.dart';

part 'word_surge_provider.g.dart';

class WordSurgeState {
  final WordSurgeChallenge? currentChallenge;
  final int score;
  final int targetScore;
  final int timeLeft; // in seconds
  final bool isGameOver;
  final bool isLoading;
  final String? selectedOption;
  final bool? isCorrect;

  WordSurgeState({
    this.currentChallenge,
    this.score = 0,
    this.targetScore = 15,
    this.timeLeft = 30,
    this.isGameOver = false,
    this.isLoading = true,
    this.selectedOption,
    this.isCorrect,
  });

  WordSurgeState copyWith({
    WordSurgeChallenge? currentChallenge,
    int? score,
    int? targetScore,
    int? timeLeft,
    bool? isGameOver,
    bool? isLoading,
    String? selectedOption,
    bool? isCorrect,
  }) {
    return WordSurgeState(
      currentChallenge: currentChallenge ?? this.currentChallenge,
      score: score ?? this.score,
      targetScore: targetScore ?? this.targetScore,
      timeLeft: timeLeft ?? this.timeLeft,
      isGameOver: isGameOver ?? this.isGameOver,
      isLoading: isLoading ?? this.isLoading,
      selectedOption: selectedOption,
      isCorrect: isCorrect,
    );
  }
}

@riverpod
class WordSurgeNotifier extends _$WordSurgeNotifier {
  final _engine = WordSurgeEngine();
  Timer? _timer;
  bool _disposed = false;
  int _epoch = 0;

  @override
  WordSurgeState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
    });
    return WordSurgeState();
  }

  void initGame() {
    _epoch++;
    _timer?.cancel();
    state = WordSurgeState(
      currentChallenge: _engine.getRandomChallenge(),
      isLoading: false,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        timer.cancel();
        state = state.copyWith(isGameOver: true);
      }
    });
  }

  void selectOption(String option) {
    if (state.isGameOver || state.selectedOption != null) return;

    final isCorrect = option == state.currentChallenge!.answer;
    final newScore = isCorrect ? state.score + 1 : state.score;
    
    state = state.copyWith(
      selectedOption: option,
      isCorrect: isCorrect,
      score: newScore,
    );

    if (newScore >= state.targetScore) {
      _timer?.cancel();
      state = state.copyWith(isGameOver: true);
    } else {
      final callEpoch = _epoch;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_disposed || callEpoch != _epoch || state.isGameOver) return;
        state = state.copyWith(
          currentChallenge: _engine.getRandomChallenge(),
          selectedOption: null,
          isCorrect: null,
        );
      });
    }
  }
}
