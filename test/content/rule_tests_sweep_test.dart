import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_profiles.dart';

/// Release gate G3: every kept game (Deck and Library) has a test against its
/// own rule, and a newly kept game without one fails here.
///
/// Matches the exact rule in `tool/triage_room.py`: either a dedicated test
/// file named after the game (`<id>_test.dart`, `<id>_engine_test.dart`) or a
/// `group('<id>', ...)` inside a room `*_rule_tests_test.dart` file, asserting
/// gameplay rather than only rendering.
void main() {
  test('every kept game has a rule test (G3)', () {
    const Set<String> skipFiles = <String>{
      'game_audit.dart',
      'screen_test.dart',
      'new_games_screen_test.dart',
      'rule_tests_sweep_test.dart',
      'deal_families.dart',
      'deal_uniqueness_test.dart',
    };
    final RegExp playAssertion = RegExp(
      r'unique|solv|generat|valid|winnable|expect\(.*(count|length)',
    );

    final List<({String name, String stem, String text})> files =
        Directory('test')
            .listSync(recursive: true)
            .whereType<File>()
            .where((File f) => f.path.endsWith('.dart'))
            .map((File f) {
              final String name = f.uri.pathSegments.last;
              final String stem = name.substring(0, name.length - 5);
              return (
                name: name,
                stem: stem,
                text: f.readAsStringSync(),
              );
            })
            .where((entry) => !skipFiles.contains(entry.name))
            .toList(growable: false);

    final List<String> missing = <String>[];
    final List<String> sortedVisible = visibleIds.toList()..sort();
    for (final String gameId in sortedVisible) {
      final RegExp groupPattern = RegExp("group\\(\\s*['\"]$gameId['\"]");
      final bool covered = files.any((entry) {
        final bool named = entry.stem.contains(gameId) ||
            (entry.stem.endsWith('_rule_tests_test') &&
                groupPattern.hasMatch(entry.text));
        if (!named) return false;
        return playAssertion.hasMatch(entry.text);
      });
      if (!covered) missing.add(gameId);
    }

    expect(
      missing,
      isEmpty,
      reason: 'Kept games without a rule test (${missing.length}):\n'
          '${missing.join('\n')}',
    );
  });
}
