import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'wisconsin_card_sorting_engine.dart';

part 'wisconsin_card_sorting_provider.g.dart';

class WCSState {
  final List<WCSCard> stimulusCards;
  final WCSCard? currentCard;
  final WCSAttribute currentRule;
  final int consecutiveCorrect;
  final String lastFeedback;
  final int score;
  final int timeLeft;
  final bool isGameOver;
  final bool isLoading;

  /// Set for one card after the sorting rule changes, so the screen can say so.
  final bool ruleChanged;

  WCSState({
    this.stimulusCards = const [],
    this.currentCard,
    this.currentRule = WCSAttribute.color,
    this.consecutiveCorrect = 0,
    this.lastFeedback = '',
    this.score = 0,
    this.timeLeft = 60,
    this.isGameOver = false,
    this.isLoading = true,
    this.ruleChanged = false,
  });

  WCSState copyWith({
    List<WCSCard>? stimulusCards,
    WCSCard? currentCard,
    WCSAttribute? currentRule,
    int? consecutiveCorrect,
    String? lastFeedback,
    int? score,
    int? timeLeft,
    bool? isGameOver,
    bool? isLoading,
    bool? ruleChanged,
  }) {
    return WCSState(
      stimulusCards: stimulusCards ?? this.stimulusCards,
      currentCard: currentCard ?? this.currentCard,
      currentRule: currentRule ?? this.currentRule,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      score: score ?? this.score,
      timeLeft: timeLeft ?? this.timeLeft,
      isGameOver: isGameOver ?? this.isGameOver,
      isLoading: isLoading ?? this.isLoading,
      ruleChanged: ruleChanged ?? this.ruleChanged,
    );
  }
}

@riverpod
class WisconsinCardSortingNotifier extends _$WisconsinCardSortingNotifier {
  final _engine = WisconsinCardSortingEngine();
  Timer? _timer;

  @override
  WCSState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return WCSState();
  }

  void initGame() {
    _timer?.cancel();
    
    final stimulus = _engine.getStimulusCards();
    final firstCard = _engine.generateRandomCard();
    
    state = WCSState(
      stimulusCards: stimulus,
      currentCard: firstCard,
      isLoading: false,
    );
    
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft <= 0) {
        timer.cancel();
        state = state.copyWith(isGameOver: true);
      } else {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      }
    });
  }

  void sort(int stimulusIndex) {
    if (state.currentCard == null || state.isGameOver) return;

    final stimulus = state.stimulusCards[stimulusIndex];
    final isCorrect =
        _engine.isMatch(state.currentCard!, stimulus, state.currentRule);

    int newConsecutive = isCorrect ? state.consecutiveCorrect + 1 : 0;
    WCSAttribute newRule = state.currentRule;
    var ruleChanged = false;

    // Shift rule after 5 consecutive correct matches. The switch is announced:
    // a clinical test hides it, a game has to tell the player what changed or
    // it is just losing to an invisible referee.
    if (newConsecutive >= 5) {
      newRule = _engine.nextRule(state.currentRule);
      newConsecutive = 0;
      ruleChanged = true;
    }

    state = state.copyWith(
      score: state.score + (isCorrect ? 1 : 0),
      consecutiveCorrect: newConsecutive,
      currentRule: newRule,
      lastFeedback: isCorrect ? 'CORRECT' : 'NOT THIS ONE',
      currentCard: _engine.generateRandomCard(),
      ruleChanged: ruleChanged,
    );
  }

  void cleanUp() {
    _timer?.cancel();
  }
}
