import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_guides.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/data/purchase/plus_entitlement.dart';

/// Gate G12 + Wave 6 release sweep (`ROADMAP.md`):
/// - Every room in the Stack is non-empty and populated with kept games.
/// - No visible UI string or guide contains unfinished stub markers ("coming soon",
///   "not implemented", "under construction", "placeholder").
/// - Store changelogs, privacy pages, and `pubspec.yaml` agree on 1.1.0, Plus,
///   and zero em/en dashes in store release notes.
void main() {
  test('Gate G12: every category room has kept games and deck representation',
      () {
    expect(GameCategories.all.length, 6);
    for (final room in GameCategories.all) {
      final inRoom = GameCategories.visible
          .where((g) => g.category == room.id)
          .toList(growable: false);
      expect(
        inRoom,
        isNotEmpty,
        reason: 'Room ${room.id} is empty',
      );
    }
    expect(deckIds.length, greaterThanOrEqualTo(100));
  });

  test('Gate G12: no visible l10n copy or guide contains unfinished stub text',
      () {
    final Map<String, Object?> arb =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, Object?>;
    final RegExp stubPattern = RegExp(
      r'\b(coming soon|under construction|not implemented|lorem ipsum)\b',
      caseSensitive: false,
    );
    final List<String> offenders = <String>[];
    for (final entry in arb.entries) {
      if (entry.key.startsWith('@') || entry.value is! String) continue;
      final String text = entry.value! as String;
      if (stubPattern.hasMatch(text)) {
        offenders.add('app_en.arb:${entry.key} -> "$text"');
      }
    }
    for (final String id in visibleIds) {
      final guide = gameGuides[id];
      expect(guide, isNotNull, reason: 'missing guide for $id');
      for (final String text in <String>[
        guide!.title,
        guide.objective,
        guide.controls,
        ...guide.walkthrough,
        ...guide.strategies,
      ]) {
        if (stubPattern.hasMatch(text)) {
          offenders.add('guide:$id -> "$text"');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('Wave 6 ship contract: version 1.1.0, privacy parity, and Plus notes',
      () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: 1.1.0+16'));
    expect(pubspec, contains('${visibleIds.length} minimalist brain puzzles'));

    final String privacyMd = File('PRIVACY.md').readAsStringSync();
    final String privacyHtml = File('docs/privacy.html').readAsStringSync();
    expect(privacyMd, contains('Last updated: 23 November 2026'));
    expect(privacyHtml, contains('Last updated: 23 November 2026'));
    // The lede of both copies says the same thing, including the update check.
    expect(privacyMd, contains('and an update check once a release carries the updater'));
    expect(privacyHtml, contains('and an update check once a release carries the updater'));
    expect(privacyMd, contains('Puzzlestack Plus'));
    expect(privacyHtml, contains('Puzzlestack Plus'));
    // The usage analytics paragraph ships in both copies, in the same words,
    // and it points at the switch that turns it off.
    for (final String copy in <String>[privacyMd, privacyHtml]) {
      final String flat = copy.replaceAll(RegExp(r'\s+'), ' ');
      expect(flat, contains('PostHog'));
      expect(flat, contains('EU Standard Contractual Clauses'));
      expect(flat, contains('You can turn this off in Settings'));
      // And so does the update disclosure, because from 1.1.0 the released
      // build asks Shorebird for a patch at launch and users must be told.
      expect(flat, contains('Shorebird'));
      expect(flat, contains('update service'));
      // And the install id the updater sends is described, not denied.
      expect(flat, contains('install id'));
      expect(flat, isNot(contains('no identifier stored on your device')));
    }
    expect(plusProductId, 'puzzlestack_plus');

    final String playLog =
        File('fastlane/metadata/android/en-US/changelogs/16.txt')
            .readAsStringSync()
            .trim();
    final String iosNotes =
        File('fastlane/metadata/ios/en-US/release_notes.txt')
            .readAsStringSync()
            .trim();
    expect(playLog.length, lessThanOrEqualTo(500));
    expect(iosNotes.length, lessThanOrEqualTo(4000));
    for (final String notes in <String>[playLog, iosNotes]) {
      expect(notes.contains('\u2014'), isFalse);
      expect(notes.contains('\u2013'), isFalse);
      expect(notes.contains(r'$'), isFalse);
      expect(notes, contains('Puzzlestack Plus'));
    }
  });
}
