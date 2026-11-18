import 'dart:math';

class WordSearchWord {
  final String word;
  final List<Point<int>> positions;
  bool isFound;

  WordSearchWord({
    required this.word,
    required this.positions,
    this.isFound = false,
  });
}

class WordSearchBoard {
  final int size;
  final List<List<String>> grid;
  final List<WordSearchWord> words;

  WordSearchBoard({
    required this.size,
    required this.grid,
    required this.words,
  });
}

class WordSearchConfig {
  final List<String> candidates;
  final int size;
  final int maxWords;
  final int? seed;

  const WordSearchConfig({
    required this.candidates,
    this.size = WordSearchEngine.boardSize,
    this.maxWords = 8,
    this.seed,
  });
}

class WordSearchEngine {
  static const int boardSize = 10;
  static const int feedBoardSize = 6;
  static const int feedMaxWords = 4;

  static WordSearchBoard generateBoard(List<String> candidates) {
    return generateWithConfig(WordSearchConfig(candidates: candidates));
  }

  static WordSearchBoard generateWithConfig(WordSearchConfig config) {
    final int sz = config.size;
    final Random rng = config.seed == null ? Random() : Random(config.seed);
    final List<List<String>> grid =
        List.generate(sz, (_) => List.filled(sz, ''));
    final List<WordSearchWord> placedWords = [];

    for (final String word in config.candidates) {
      if (placedWords.length >= config.maxWords) break;
      _tryPlaceWord(grid, sz, word, placedWords, rng);
    }

    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int y = 0; y < sz; y++) {
      for (int x = 0; x < sz; x++) {
        if (grid[y][x] == '') {
          grid[y][x] = letters[rng.nextInt(letters.length)];
        }
      }
    }

    return WordSearchBoard(size: sz, grid: grid, words: placedWords);
  }

  static bool _tryPlaceWord(
    List<List<String>> grid,
    int sz,
    String word,
    List<WordSearchWord> placedWords,
    Random rng,
  ) {
    final directions = [
      [1, 0],
      [0, 1],
      [1, 1],
      [1, -1],
    ];
    directions.shuffle(rng);

    final List<int> starts = List.generate(sz * sz, (i) => i)..shuffle(rng);

    for (final dir in directions) {
      final int dx = dir[0];
      final int dy = dir[1];

      for (final startIndex in starts) {
        final int startX = startIndex % sz;
        final int startY = startIndex ~/ sz;

        if (_canPlace(grid, sz, word, startX, startY, dx, dy)) {
          final List<Point<int>> positions = [];
          for (int i = 0; i < word.length; i++) {
            final int x = startX + (i * dx);
            final int y = startY + (i * dy);
            grid[y][x] = word[i];
            positions.add(Point(x, y));
          }
          placedWords.add(WordSearchWord(word: word, positions: positions));
          return true;
        }
      }
    }
    return false;
  }

  static bool _canPlace(
    List<List<String>> grid,
    int sz,
    String word,
    int startX,
    int startY,
    int dx,
    int dy,
  ) {
    final int endX = startX + (word.length - 1) * dx;
    final int endY = startY + (word.length - 1) * dy;

    if (endX < 0 || endX >= sz || endY < 0 || endY >= sz) return false;

    for (int i = 0; i < word.length; i++) {
      final int x = startX + (i * dx);
      final int y = startY + (i * dy);
      if (grid[y][x] != '' && grid[y][x] != word[i]) return false;
    }
    return true;
  }
}
