import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_guides.dart';
import 'package:puzzle/data/game_profiles.dart';
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
    final orphans = gameGuides.keys.where((key) => !ids.contains(key)).toList();
    expect(orphans, isEmpty,
        reason: 'guides for no game: ${orphans.join(', ')}');
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

  test('every store file says the number of games a player can open', () {
    // The registry is not the number the player sees: the archive is hidden, and the store
    // page, the web shell, the Pages site and the README are about what a player can open.
    // This used to require the registry total, which is how the copy ended up advertising
    // 139 games the app no longer deals.
    final visible = visibleIds.length.toString();
    final total = '${allGamesMetadata.length}';
    // Files that must carry the number, and the one that must not carry the archived total
    // but has no room for a number (the App Store name is 30 characters).
    const withCount = [
      'README.md',
      'fastlane/metadata/android/en-US/title.txt',
      'fastlane/metadata/android/en-US/short_description.txt',
      'fastlane/metadata/android/en-US/full_description.txt',
      'fastlane/metadata/ios/en-US/subtitle.txt',
      'fastlane/metadata/ios/en-US/promotional_text.txt',
      'fastlane/metadata/ios/en-US/description.txt',
      'docs/index.html',
      'web/manifest.json',
      'web/index.html',
    ];
    const noStaleCount = ['fastlane/metadata/ios/en-US/name.txt', ...withCount];
    final missing = <String>[];
    final archived = <String>[];
    for (final path in withCount) {
      final text = File(path).readAsStringSync();
      if (!RegExp('\\b$visible\\b').hasMatch(text)) {
        missing.add('$path does not say $visible');
      }
    }
    for (final path in noStaleCount) {
      final text = File(path).readAsStringSync();
      if (visible != total && RegExp('\\b$total\\b').hasMatch(text)) {
        archived.add('$path still says $total, which counts the archive');
      }
    }
    expect(missing, isEmpty,
        reason: 'the copy must say how many games a player can open:\n'
            '${missing.join('\n')}');
    expect(archived, isEmpty,
        reason: 'the count in the copy is the visible one, not the registry:\n'
            '${archived.join('\n')}');
  });
}
