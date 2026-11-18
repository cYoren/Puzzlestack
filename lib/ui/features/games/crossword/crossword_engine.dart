import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CrosswordWord {
  final String word;
  final String clue;
  int x;
  int y;
  bool isHorizontal;
  int number;

  CrosswordWord({
    required this.word,
    required this.clue,
    this.x = 0,
    this.y = 0,
    this.isHorizontal = true,
    this.number = 0,
  });
}

class CrosswordBoard {
  final int size;
  final List<List<String>> grid;
  final List<CrosswordWord> words;

  CrosswordBoard({
    required this.size,
    required this.grid,
    required this.words,
  });
}

class CrosswordEngine {
  static const int miniBoardSize = 5;
  static const int defaultBoardSize = 8;

  static List<Map<String, String>> _parseJson(String response) {
    final data = json.decode(response) as List<dynamic>;
    return data
        .map((item) => {
              'word': item['word'].toString().toUpperCase(),
              'clue': item['clue'].toString(),
            })
        .toList();
  }

  /// Clue text is English (`assets/crossword_data.json`).
  Future<List<Map<String, String>>> loadData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/crossword_data.json');
      return await compute(_parseJson, response);
    } catch (e) {
      return [
        {'word': 'ACE', 'clue': 'A top-ranking playing card'},
        {'word': 'BED', 'clue': 'A piece of furniture for sleep'},
        {'word': 'CAT', 'clue': 'A small domesticated carnivorous mammal'},
        {'word': 'DOG', 'clue': 'A domesticated carnivorous mammal'},
      ];
    }
  }

  static CrosswordBoard generateBoard(List<dynamic> args) {
    final List<Map<String, String>> allWords = (args[0] as List).map((item) {
      final map = item as Map;
      return {
        'word': map['word'].toString().toUpperCase(),
        'clue': map['clue'].toString(),
      };
    }).toList();
    final int size = args[1] as int;
    final int? seed = args.length > 2 ? args[2] as int? : null;
    final Random rng = seed == null ? Random() : Random(seed);

    final validWords =
        allWords.where((w) => w['word']!.length <= size).toList();

    if (validWords.isEmpty) {
      return CrosswordBoard(
        size: size,
        grid: List.generate(size, (_) => List.filled(size, ' ')),
        words: [],
      );
    }

    final int wantedWords = max(1, size - 1);
    final int capWords = min(15, size * 2);
    List<List<String>> bestGrid =
        List.generate(size, (_) => List.filled(size, ' '));
    List<CrosswordWord> bestPlacedWords = [];

    final List<Map<String, String>> spinePool = validWords
        .where(
          (w) =>
              w['word']!.length >= max(3, size - 2) &&
              w['word']!.length <= size,
        )
        .toList();

    for (int attempt = 0; attempt < 400; attempt++) {
      validWords.shuffle(rng);
      final List<List<String>> grid =
          List.generate(size, (_) => List.filled(size, ' '));
      final List<CrosswordWord> placedWords = [];

      final Map<String, String> seedEntry = spinePool.isNotEmpty
          ? spinePool[rng.nextInt(spinePool.length)]
          : validWords.first;

      final CrosswordWord first = CrosswordWord(
        word: seedEntry['word']!,
        clue: seedEntry['clue']!,
      );
      first.isHorizontal = attempt.isEven;
      final int slack = size - first.word.length;
      final int along = slack <= 0 ? 0 : rng.nextInt(slack + 1);
      // Vary the perpendicular row/col so vertical and horizontal crossings
      // have room on both sides across retries.
      final int acrossPos = size <= 3 ? 0 : (attempt % size);
      if (first.isHorizontal) {
        first.x = along;
        first.y = acrossPos;
      } else {
        first.x = acrossPos;
        first.y = along;
      }

      _place(grid, first);
      placedWords.add(first);

      // Prefer longer crossing words early so long lines do not get blocked by
      // tiny 3-letter stubs, then fill remaining lines with shorter words.
      final List<Map<String, String>> ordered = List.from(validWords)
        ..sort((a, b) {
          final int target = max(4, size - 2);
          final int da = (a['word']!.length - target).abs();
          final int db = (b['word']!.length - target).abs();
          return da.compareTo(db);
        });
      // Lightly permute within bands so boards stay fresh.
      for (int i = 0; i + 3 < ordered.length; i += 4) {
        final int j = i + rng.nextInt(4);
        final tmp = ordered[i];
        ordered[i] = ordered[j];
        ordered[j] = tmp;
      }

      for (int pass = 0; pass < 2 && placedWords.length < capWords; pass++) {
        for (int i = 0;
            i < ordered.length && placedWords.length < capWords;
            i++) {
          final String wText = ordered[i]['word']!;
          if (placedWords.any((pw) => pw.word == wText)) continue;

          final candidate = CrosswordWord(
            word: wText,
            clue: ordered[i]['clue']!,
          );
          _tryPlaceCandidate(grid, candidate, placedWords, size, rng);
        }
      }

      if (placedWords.length > bestPlacedWords.length) {
        bestPlacedWords = List.from(placedWords);
        bestGrid = List.generate(size, (y) => List<String>.from(grid[y]));
      }

      if (bestPlacedWords.length >= wantedWords + 1) break;
      if (attempt >= 80 && bestPlacedWords.length >= wantedWords) break;
    }

    _assignNumbers(bestPlacedWords);
    return CrosswordBoard(size: size, grid: bestGrid, words: bestPlacedWords);
  }

  static void _tryPlaceCandidate(
    List<List<String>> grid,
    CrosswordWord candidate,
    List<CrosswordWord> placedWords,
    int size,
    Random rng,
  ) {
    final List<CrosswordWord> targets = List.from(placedWords)..shuffle(rng);

    for (final target in targets) {
      for (int tIdx = 0; tIdx < target.word.length; tIdx++) {
        for (int cIdx = 0; cIdx < candidate.word.length; cIdx++) {
          if (target.word[tIdx] == candidate.word[cIdx]) {
            candidate.isHorizontal = !target.isHorizontal;
            if (candidate.isHorizontal) {
              candidate.x =
                  (target.isHorizontal ? target.x + tIdx : target.x) - cIdx;
              candidate.y = target.isHorizontal ? target.y : target.y + tIdx;
            } else {
              candidate.x = target.isHorizontal ? target.x + tIdx : target.x;
              candidate.y =
                  (target.isHorizontal ? target.y : target.y + tIdx) - cIdx;
            }

            if (_canPlaceSafely(grid, candidate, placedWords, size)) {
              _place(grid, candidate);
              placedWords.add(candidate);
              return;
            }
          }
        }
      }
    }
  }

  static bool _canPlaceSafely(
    List<List<String>> grid,
    CrosswordWord w,
    List<CrosswordWord> placedWords,
    int size,
  ) {
    if (w.x < 0 || w.y < 0) return false;
    if (w.isHorizontal && w.x + w.word.length > size) return false;
    if (!w.isHorizontal && w.y + w.word.length > size) return false;

    // At most one horizontal word per row and one vertical word per column
    // (`test/engines/crossword_engine_test.dart`).
    for (final existing in placedWords) {
      if (existing.isHorizontal == w.isHorizontal) {
        if (w.isHorizontal && existing.y == w.y) return false;
        if (!w.isHorizontal && existing.x == w.x) return false;
      }
    }

    int intersectionCount = 0;

    for (int i = 0; i < w.word.length; i++) {
      final int cx = w.isHorizontal ? w.x + i : w.x;
      final int cy = w.isHorizontal ? w.y : w.y + i;

      if (grid[cy][cx] != ' ' && grid[cy][cx] != w.word[i]) return false;

      if (grid[cy][cx] == w.word[i]) intersectionCount++;

      if (grid[cy][cx] == ' ') {
        if (w.isHorizontal) {
          if (cy > 0 && grid[cy - 1][cx] != ' ') return false;
          if (cy < size - 1 && grid[cy + 1][cx] != ' ') return false;
        } else {
          if (cx > 0 && grid[cy][cx - 1] != ' ') return false;
          if (cx < size - 1 && grid[cy][cx + 1] != ' ') return false;
        }
      }
    }

    if (intersectionCount < 1) return false;

    for (final existing in placedWords) {
      if (existing.isHorizontal != w.isHorizontal) {
        int sharedCells = 0;
        for (int i = 0; i < w.word.length; i++) {
          final int cx = w.isHorizontal ? w.x + i : w.x;
          final int cy = w.isHorizontal ? w.y : w.y + i;

          for (int j = 0; j < existing.word.length; j++) {
            final int ex = existing.isHorizontal ? existing.x + j : existing.x;
            final int ey = existing.isHorizontal ? existing.y : existing.y + j;

            if (cx == ex && cy == ey) {
              sharedCells++;
            }
          }
        }
        if (sharedCells > 1) return false;
      }
    }

    if (w.isHorizontal) {
      if (w.x > 0 && grid[w.y][w.x - 1] != ' ') return false;
      if (w.x + w.word.length < size && grid[w.y][w.x + w.word.length] != ' ') {
        return false;
      }
    } else {
      if (w.y > 0 && grid[w.y - 1][w.x] != ' ') return false;
      if (w.y + w.word.length < size && grid[w.y + w.word.length][w.x] != ' ') {
        return false;
      }
    }

    return true;
  }

  static void _place(List<List<String>> grid, CrosswordWord w) {
    for (int i = 0; i < w.word.length; i++) {
      final int cx = w.isHorizontal ? w.x + i : w.x;
      final int cy = w.isHorizontal ? w.y : w.y + i;
      grid[cy][cx] = w.word[i];
    }
  }

  static void _assignNumbers(List<CrosswordWord> words) {
    words.sort((a, b) {
      if (a.y != b.y) return a.y.compareTo(b.y);
      return a.x.compareTo(b.x);
    });

    int currentNum = 1;
    final Map<String, int> posToNum = {};
    for (final w in words) {
      final String key = '${w.x},${w.y}';
      if (posToNum.containsKey(key)) {
        w.number = posToNum[key]!;
      } else {
        w.number = currentNum;
        posToNum[key] = currentNum;
        currentNum++;
      }
    }
  }
}
