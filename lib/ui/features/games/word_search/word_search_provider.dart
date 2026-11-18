import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../providers/game_tier_provider.dart';
import '../../feed/feed_session.dart';
import 'word_search_engine.dart';
import 'package:flutter/services.dart';

part 'word_search_provider.g.dart';

class WordSearchState {
  final WordSearchBoard? board;
  final List<Point<int>> selection;
  final bool isSolved;
  final Set<String> foundWords;

  WordSearchState({
    this.board,
    this.selection = const [],
    this.isSolved = false,
    this.foundWords = const {},
  });

  WordSearchState copyWith({
    WordSearchBoard? board,
    List<Point<int>>? selection,
    bool? isSolved,
    Set<String>? foundWords,
  }) {
    return WordSearchState(
      board: board ?? this.board,
      selection: selection ?? this.selection,
      isSolved: isSolved ?? this.isSolved,
      foundWords: foundWords ?? this.foundWords,
    );
  }
}

@riverpod
class WordSearchNotifier extends _$WordSearchNotifier {
  @override
  WordSearchState build() {
    ref.watch(tierRevisionProvider('word_search'));
    return WordSearchState();
  }

  Future<void> initGame() async {
    final bool inFeed = FeedSession.inFeed;
    final int targetSize =
        inFeed ? WordSearchEngine.feedBoardSize : WordSearchEngine.boardSize;
    final int targetWords = inFeed ? WordSearchEngine.feedMaxWords : 8;
    final int? seed = FeedSession.seedOf('word_search');
    final Random rng = seed == null ? Random() : Random(seed);

    List<String> selectedWords = [];

    try {
      final String response =
          await rootBundle.loadString('assets/word_search_words.txt');

      final List<String> allWords = response
          .split('\n')
          .map((w) => w.trim().toUpperCase())
          .where((w) => w.length >= 4 && w.length <= targetSize)
          .toList();

      if (allWords.isNotEmpty) {
        allWords.shuffle(rng);
        selectedWords = allWords.take(15).toList();
      }
    } catch (e) {
      // Fallback handled below
    }

    if (selectedWords.isEmpty) {
      selectedWords = [
        'APPLE',
        'BANANA',
        'CHERRY',
        'DRAGON',
        'ELDER',
        'FLOWER',
        'GALAXY',
        'HONEY',
        'ISLAND',
        'JUNGLE',
      ].where((w) => w.length <= targetSize).toList();
    }

    final config = WordSearchConfig(
      candidates: selectedWords,
      size: targetSize,
      maxWords: targetWords,
      seed: seed == null ? null : seed ^ 0x3C91,
    );
    final board = inFeed
        ? WordSearchEngine.generateWithConfig(config)
        : await compute(WordSearchEngine.generateWithConfig, config);
    state = WordSearchState(board: board);
  }

  void startSelection(int x, int y) {
    if (state.isSolved) return;
    state = state.copyWith(selection: [Point(x, y)]);
  }

  void updateSelection(int x, int y) {
    if (state.isSolved || state.selection.isEmpty) return;
    
    final start = state.selection.first;
    if (start.x == x && start.y == y) return;

    // Word search selection must be linear (Horizontal, Vertical, or Diagonal)
    int dx = (x - start.x).abs();
    int dy = (y - start.y).abs();

    if (dx == 0 || dy == 0 || dx == dy) {
      // It's a valid direction
      List<Point<int>> newSelection = [];
      int steps = max(dx, dy);
      int stepX = x == start.x ? 0 : (x - start.x) ~/ dx;
      int stepY = y == start.y ? 0 : (y - start.y) ~/ dy;

      for (int i = 0; i <= steps; i++) {
        newSelection.add(Point(start.x + (i * stepX), start.y + (i * stepY)));
      }
      state = state.copyWith(selection: newSelection);
    }
  }

  void endSelection() {
    if (state.isSolved || state.selection.isEmpty) return;

    String selectedWord = state.selection
        .map((p) => state.board!.grid[p.y][p.x])
        .join();
    
    String reversedWord = selectedWord.split('').reversed.join();

    bool found = false;
    String matchedWord = "";

    for (var w in state.board!.words) {
      if (!w.isFound && (w.word == selectedWord || w.word == reversedWord)) {
        w.isFound = true;
        found = true;
        matchedWord = w.word;
        break;
      }
    }

    if (found) {
      final newFound = Set<String>.from(state.foundWords)..add(matchedWord);
      bool allFound = state.board!.words.every((w) => w.isFound);
      state = state.copyWith(
        selection: [],
        foundWords: newFound,
        isSolved: allFound,
      );
    } else {
      state = state.copyWith(selection: []);
    }
  }
}
