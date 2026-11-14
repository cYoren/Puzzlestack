import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/word_ladder/word_ladder_engine.dart';

/// A ladder is only a puzzle if the end word can be reached at all. The audit
/// found one row (`GOOD` → `EVIL`) where `EVIL` had no one-letter neighbour in
/// the game's own dictionary, so the game could never be won. This test BFSes
/// every row over the dictionary the game validates against.
void main() {
  final engine = WordLadderEngine();
  final puzzles = engine.puzzles;

  Set<String> neighbours(String word, Set<String> words) {
    final found = <String>{};
    for (var i = 0; i < word.length; i++) {
      for (var c = 'A'.codeUnitAt(0); c <= 'Z'.codeUnitAt(0); c++) {
        final candidate =
            word.substring(0, i) + String.fromCharCode(c) + word.substring(i + 1);
        if (candidate != word && words.contains(candidate)) found.add(candidate);
      }
    }
    return found;
  }

  /// Shortest path from [start] to [end], or null when there is none.
  int? steps(String start, String end, Set<String> words) {
    if (!words.contains(start) || !words.contains(end)) return null;
    final seen = <String>{start};
    var frontier = <String>{start};
    var depth = 0;
    while (frontier.isNotEmpty) {
      if (frontier.contains(end)) return depth;
      final next = <String>{};
      for (final word in frontier) {
        for (final candidate in neighbours(word, words)) {
          if (seen.add(candidate)) next.add(candidate);
        }
      }
      frontier = next;
      depth++;
      if (depth > 20) return null;
    }
    return null;
  }

  test('every ladder is reachable by changing one letter at a time', () {
    final unreachable = <String>[];
    for (final puzzle in puzzles) {
      final start = puzzle['start']!;
      final end = puzzle['end']!;
      if (steps(start, end, engine.dictionary) == null) {
        unreachable.add('$start -> $end');
      }
    }
    expect(unreachable, isEmpty,
        reason: 'these rows can never be won:\n${unreachable.join('\n')}');
  });

  test('the dictionary is plain A-Z four-letter words the keyboard can type', () {
    final untouchable = engine.dictionary
        .where((word) => !RegExp(r'^[A-Z]{4}$').hasMatch(word))
        .toList();
    expect(untouchable, isEmpty,
        reason: 'unreachable cells: ${untouchable.join(', ')}');
  });

  test('both ends of every ladder are in the dictionary', () {
    for (final puzzle in puzzles) {
      expect(engine.isValidWord(puzzle['start']!), isTrue,
          reason: '${puzzle['start']} is not playable');
      expect(engine.isValidWord(puzzle['end']!), isTrue,
          reason: '${puzzle['end']} is not playable');
    }
  });

  test('no ladder starts and ends on the same word', () {
    for (final puzzle in puzzles) {
      expect(puzzle['start'], isNot(puzzle['end']));
    }
  });
}
