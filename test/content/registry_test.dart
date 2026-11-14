import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_guides.dart';
import 'package:puzzle/data/game_registry.dart';

/// The catalog is the product, and until this test existed nothing checked it
/// as a whole: six of the newest games had no guide (so their rules page was
/// blank and their first-play hint was burned), four games resolved to a
/// sibling's title because screens looked games up by localised title, and the
/// number 313 was typed by hand into five files.
///
/// These are the checks that would have caught all of it before it shipped.
void main() {
  final games = allGamesMetadata;
  final ids = games.map((game) => game.id).toList();

  test('the registry has no duplicate ids', () {
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every game has a guide', () {
    final missing = ids.where((id) => !gameGuides.containsKey(id)).toList();
    expect(missing, isEmpty, reason: 'no guide for: ${missing.join(', ')}');
  });

  test('every guide belongs to a game', () {
    final orphans =
        gameGuides.keys.where((key) => !ids.contains(key)).toList();
    expect(orphans, isEmpty, reason: 'guides for no game: ${orphans.join(', ')}');
  });

  test('every guide has the shape the rules page needs', () {
    for (final entry in gameGuides.entries) {
      final guide = entry.value;
      expect(guide.title.trim(), isNotEmpty, reason: entry.key);
      expect(guide.category.trim(), isNotEmpty, reason: entry.key);
      expect(guide.objective.trim(), isNotEmpty, reason: entry.key);
      expect(guide.controls.trim(), isNotEmpty, reason: entry.key);
      expect(guide.walkthrough, isNotEmpty, reason: entry.key);
      expect(guide.strategies, isNotEmpty, reason: entry.key);
    }
  });

  test('every store file says the number of games there are', () {
    final count = ids.length.toString();
    const files = [
      'README.md',
      'fastlane/metadata/android/en-US/title.txt',
      'fastlane/metadata/android/en-US/full_description.txt',
      'docs/index.html',
      'web/manifest.json',
    ];
    final wrong = <String>[];
    for (final path in files) {
      final text = File(path).readAsStringSync();
      if (!RegExp('\\b$count\\b').hasMatch(text)) {
        wrong.add('$path does not say $count');
      }
    }
    expect(wrong, isEmpty,
        reason: 'adding or removing a game means updating the copy:\n'
            '${wrong.join('\n')}');
  });
}
