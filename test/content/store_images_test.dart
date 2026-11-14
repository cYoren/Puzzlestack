import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// A store listing is content too, and it was the one part of the product with
/// nothing in the repo: Play had no phone screenshots at all, and iOS had no
/// metadata directory. Both are now captured by `tool/screenshots.sh` and
/// checked here, so a rebrand or a UI change cannot silently leave the listing
/// pointing at screens that no longer exist.
void main() {
  Future<ui.Image> decode(String path) async {
    final bytes = File(path).readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    return (await codec.getNextFrame()).image;
  }

  final playShots = [
    for (var i = 1; i <= 8; i++)
      'fastlane/metadata/android/en-US/images/phoneScreenshots/$i.png',
  ];
  final iosShots = [
    for (var i = 1; i <= 8; i++) 'fastlane/screenshots/en-US/$i.png',
  ];

  test('Google Play has the phone screenshots it requires', () {
    // Play rejects a listing with fewer than two; eight is the maximum.
    expect(playShots.where((path) => File(path).existsSync()).length,
        greaterThanOrEqualTo(2));
  });

  test('every Play screenshot is 1080x1920', () async {
    for (final path in playShots) {
      final image = await decode(path);
      expect('${image.width}x${image.height}', '1080x1920', reason: path);
    }
  });

  test('every App Store screenshot is 1290x2796', () async {
    for (final path in iosShots) {
      final image = await decode(path);
      expect('${image.width}x${image.height}', '1290x2796', reason: path);
    }
  });

  test('the iOS metadata Apple reads is all there and within its limits', () {
    const limits = {
      'name.txt': 30,
      'subtitle.txt': 30,
      'keywords.txt': 100,
      'promotional_text.txt': 170,
      'description.txt': 4000,
    };
    for (final entry in limits.entries) {
      final file = File('fastlane/metadata/ios/en-US/${entry.key}');
      expect(file.existsSync(), isTrue, reason: '${entry.key} is missing');
      final text = file.readAsStringSync().trim();
      expect(text, isNotEmpty, reason: entry.key);
      expect(text.length, lessThanOrEqualTo(entry.value),
          reason: '${entry.key} is ${text.length} characters, '
              'Apple allows ${entry.value}');
    }
    // Keywords are comma-separated with no spaces, or Apple counts the spaces.
    final keywords =
        File('fastlane/metadata/ios/en-US/keywords.txt').readAsStringSync();
    expect(keywords.contains(', '), isFalse);
    // The links have to resolve to something, and they are the same pages the
    // app links to.
    for (final key in ['support_url.txt', 'marketing_url.txt', 'privacy_url.txt']) {
      final url =
          File('fastlane/metadata/ios/en-US/$key').readAsStringSync().trim();
      expect(url, startsWith('https://'));
      expect(url, contains('cyoren.github.io/Puzzlestack'));
    }
  });

  test('the two listings say the same number of games', () {
    // Adding a game means updating both stores; the count is the one number
    // that must never disagree between them.
    final android =
        File('fastlane/metadata/android/en-US/full_description.txt')
            .readAsStringSync();
    final ios =
        File('fastlane/metadata/ios/en-US/description.txt').readAsStringSync();
    final androidCount = RegExp(r'\b(\d{3}) minimalist').firstMatch(android);
    final iosCount = RegExp(r'\b(\d{3}) minimalist').firstMatch(ios);
    expect(androidCount, isNotNull);
    expect(iosCount, isNotNull);
    expect(iosCount!.group(1), androidCount!.group(1));
  });
}
