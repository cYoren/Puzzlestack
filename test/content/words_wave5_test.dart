import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/ui/features/games/crossword/crossword_engine.dart';
import 'package:puzzle/ui/features/games/word_wheel/word_wheel_screen.dart';

const Set<String> _labWords = <String>{
  'n-back',
  'nback',
  'stroop',
  'wisconsin',
  'corsi',
  'sdmt',
  'posner',
  'sternberg',
  'flanker',
  'navon',
  'subitizing',
  'dichotic',
  'go/no-go',
  'priming',
  'span',
  'paradigm',
  'task',
};

String _camel(String snake) {
  final parts = snake.split('_');
  return parts.first +
      parts
          .skip(1)
          .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}')
          .join();
}

bool _isAllCaps(String text) {
  final letters = text.replaceAll(RegExp(r'[^A-Za-z]'), '');
  return letters.isNotEmpty && letters == letters.toUpperCase();
}

void main() {
  group('Wave 5: plain-names across kept games', () {
    test(
        'every kept game title and subtitle is plain, <= 60 chars, and unshouted',
        () {
      final Map<String, dynamic> arb = json.decode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;

      for (final String gameId in visibleIds) {
        final String base = _camel(gameId);
        final String? title = arb['${base}Title'] as String?;
        final String? subtitle = arb['${base}Subtitle'] as String?;
        if (title != null) {
          expect(
            _isAllCaps(title),
            isFalse,
            reason: '$gameId title shouts in ALL CAPS: $title',
          );
          final String lower = title.toLowerCase();
          for (final String slop in _labWords) {
            expect(
              lower.contains(slop),
              isFalse,
              reason: '$gameId title contains lab word "$slop": $title',
            );
          }
        }
        if (subtitle != null) {
          expect(
            _isAllCaps(subtitle),
            isFalse,
            reason: '$gameId subtitle shouts in ALL CAPS: $subtitle',
          );
          expect(
            subtitle.length,
            lessThanOrEqualTo(60),
            reason:
                '$gameId subtitle exceeds 60 chars (${subtitle.length}): $subtitle',
          );
          expect(
            subtitle.contains(RegExp('[\u2013\u2014]')),
            isFalse,
            reason: '$gameId subtitle contains em/en dash: $subtitle',
          );
          final String lower = subtitle.toLowerCase();
          for (final String slop in _labWords) {
            expect(
              lower.contains(slop),
              isFalse,
              reason: '$gameId subtitle contains lab word "$slop": $subtitle',
            );
          }
        }
      }
    });
  });

  group('Wave 5: word-wheel-curated', () {
    test('has at least 30 unique hand-curated 7-letter wheels', () {
      final puzzles = WordWheelScreen.puzzles;
      expect(puzzles.length, greaterThanOrEqualTo(30));

      final Set<String> pangrams = <String>{};
      for (final WordWheelPuzzle p in puzzles) {
        expect(pangrams.add(p.pangram), isTrue,
            reason: 'duplicate pangram ${p.pangram}');
        expect(p.letters.length, 7);
        expect(p.letters.toSet().length, 7);
        expect(p.letters.contains(p.centralLetter), isTrue);
        expect(p.validWords.length, greaterThanOrEqualTo(12));
        expect(p.validWords.contains(p.pangram), isTrue);

        final Set<String> allowed = p.letters.toSet();
        for (final String word in p.validWords) {
          expect(word.length, greaterThanOrEqualTo(3));
          expect(word.contains(p.centralLetter), isTrue);
          expect(
            word.split('').every(allowed.contains),
            isTrue,
            reason: '$word uses letters outside ${p.pangram}',
          );
          expect(WordWheelScreen.isWordValid(p, word), isTrue);
        }
      }
    });
  });

  group('Wave 5: crossword-supply', () {
    test(
        'crossword_data.json has no duplicate words or clues and fills 5..10 boards',
        () {
      final List<dynamic> raw = json.decode(
        File('assets/crossword_data.json').readAsStringSync(),
      ) as List<dynamic>;
      expect(raw.length, greaterThan(1600));

      final Set<String> words = <String>{};
      final Set<String> clues = <String>{};
      final List<Map<String, String>> data = <Map<String, String>>[];
      for (final dynamic item in raw) {
        final map = item as Map<String, dynamic>;
        final String w = (map['word'] as String).trim().toUpperCase();
        final String c = (map['clue'] as String).trim();
        expect(words.add(w), isTrue, reason: 'duplicate crossword word: $w');
        expect(
          clues.add(c.toLowerCase()),
          isTrue,
          reason: 'duplicate crossword clue: $c',
        );
        data.add({'word': w, 'clue': c});
      }

      for (final int size in <int>[5, 7, 8, 9, 10]) {
        for (int run = 0; run < 20; run++) {
          final CrosswordBoard board = CrosswordEngine.generateBoard(
              [data, size, 1000 + size * 31 + run]);
          expect(
            board.words.length,
            greaterThanOrEqualTo(size - 1),
            reason:
                'size $size run $run placed only ${board.words.length} words',
          );
        }
      }
    });
  });

  group('Wave 5: l10n key and placeholder parity across all 23 locales', () {
    test(
        'every locale matches app_en.arb keys and placeholders with no orphans',
        () {
      final Map<String, dynamic> en = json.decode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      final Set<String> enKeys =
          en.keys.where((k) => !k.startsWith('@')).toSet();
      final RegExp ph = RegExp(r'\{([A-Za-z0-9_]+)\}');

      final List<File> arbFiles = Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList();
      expect(arbFiles.length, 23);

      for (final File f in arbFiles) {
        final Map<String, dynamic> loc =
            json.decode(f.readAsStringSync()) as Map<String, dynamic>;
        final Set<String> locKeys =
            loc.keys.where((k) => !k.startsWith('@')).toSet();
        expect(locKeys, enKeys, reason: 'key mismatch in ${f.path}');
        for (final String k in enKeys) {
          final Set<String> expectedPh =
              ph.allMatches(en[k] as String).map((m) => m.group(1)!).toSet();
          final Set<String> actualPh =
              ph.allMatches(loc[k] as String).map((m) => m.group(1)!).toSet();
          expect(
            actualPh,
            expectedPh,
            reason: 'placeholder mismatch in ${f.path}:$k',
          );
        }
      }
    });
  });
}
