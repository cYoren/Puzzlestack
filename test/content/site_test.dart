import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/utils/deep_link.dart';

/// The website in `docs/` is generated, so it can drift from the app silently.
/// These tests are the contract: every game a player can open has a page, no
/// archived game does, every link on the site points at a file that exists, and
/// the sitemap and the pages agree.
void main() {
  final Map<String, Object?> payload =
      jsonDecode(File('tool/site/games.json').readAsStringSync())
          as Map<String, Object?>;
  final List<Map<String, Object?>> exported =
      (payload['games']! as List).cast<Map<String, Object?>>();
  final Set<String> exportedIds =
      exported.map((g) => g['id']! as String).toSet();

  final Directory docs = Directory('docs');

  test('the export is the catalogue, and the counts agree', () {
    final Set<String> visible = visibleIds;
    expect(exportedIds, visible);
    expect(exported.length, GameCategories.visible.length);
  });

  test('every playable game has a page, and no archived game does', () {
    final Set<String> pages = docs
        .listSync(recursive: false)
        .whereType<Directory>()
        .where((dir) => dir.path.endsWith('/games'))
        .expand((dir) => dir.listSync())
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last.replaceAll('.html', ''))
        .toSet();

    for (final Map<String, Object?> game in exported) {
      expect(pages, contains(game['slug']),
          reason: '${game['id']} has no page');
    }
    for (final String archived in archivedIds) {
      expect(pages, isNot(contains(slugFor(archived))),
          reason: 'the archive is not published, and $archived is archived');
    }
  });

  test('the sitemap lists every page and nothing else', () {
    final String sitemap = File('docs/sitemap.xml').readAsStringSync();
    final Set<String> listed = RegExp(r'<loc>([^<]+)</loc>')
        .allMatches(sitemap)
        .map((match) => match.group(1)!)
        .map((url) => Uri.parse(url).path.replaceFirst('/Puzzlestack/', ''))
        .toSet();

    final Set<String> expected = {
      'index.html',
      'games/index.html',
      ...exported.map((game) => 'games/${game['slug']}.html'),
      for (final CategoryInfo room in GameCategories.all)
        'rooms/${room.id.toLowerCase()}.html',
    };
    expect(listed, expected);
  });

  test('every internal link on the site resolves to a file', () {
    final List<String> broken = [];
    for (final File file in docs
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.html'))) {
      final String html = file.readAsStringSync();
      if (!html.contains('<h1')) continue; // legal pages have their own shape
      for (final RegExpMatch match
          in RegExp(r'href="([^"#][^"]*)"').allMatches(html)) {
        final String href = match.group(1)!;
        if (href.startsWith('http') || href.startsWith('mailto:')) continue;
        final String path = href.split('#').first.split('?').first;
        if (path.isEmpty) continue;
        final Uri target = file.uri.resolve(path);
        // The browser build lives in `app/` on the deployed branch, not in the
        // repo (`tool/deploy_pages.sh`), so a link into it is checked as a shape
        // and the deploy script checks the file.
        if (target.path.contains('/app/')) {
          if (!path.endsWith('app/index.html')) {
            broken
                .add('${file.path} -> $href (app links go to app/index.html)');
          }
          continue;
        }
        // `./` is a directory link: valid when it lands on a page.
        final bool exists = File.fromUri(target).existsSync() ||
            File.fromUri(target.resolve('index.html')).existsSync();
        if (!exists) broken.add('${file.path} -> $href');
      }
    }
    expect(broken, isEmpty, reason: broken.take(10).join('; '));
  });

  test('every game page offers the puzzle in the browser, by slug', () {
    for (final Map<String, Object?> game in exported) {
      final String html =
          File('docs/games/${game['slug']}.html').readAsStringSync();
      expect(html.contains('href="../app/index.html?game=${game['slug']}"'),
          isTrue,
          reason: '${game['id']} has no playable link');
    }
  });

  test('each page has a title, a description, a canonical and one h1', () {
    for (final Map<String, Object?> game in exported) {
      final String html =
          File('docs/games/${game['slug']}.html').readAsStringSync();
      expect(RegExp(r'<title>[^<]{10,}</title>').hasMatch(html), isTrue,
          reason: '${game['id']} title');
      expect(
          RegExp(r'<meta name="description" content="[^"]{40,}"')
              .hasMatch(html),
          isTrue,
          reason: '${game['id']} description');
      expect(html.contains('<link rel="canonical"'), isTrue,
          reason: '${game['id']} canonical');
      expect('<h1>'.allMatches(html).length, 1, reason: '${game['id']} h1');
      expect(html.contains('application/ld+json'), isTrue,
          reason: '${game['id']} structured data');
    }
  });

  test('no page is a stub: the guide text is on it', () {
    for (final Map<String, Object?> game in exported) {
      final String html =
          File('docs/games/${game['slug']}.html').readAsStringSync();
      final List<Object?> steps = game['walkthrough']! as List<Object?>;
      expect(html.contains('<h2>How to play</h2>'), isTrue,
          reason: '${game['id']} has no rules');
      expect(html.contains('<h2>Strategy</h2>'), isTrue,
          reason: '${game['id']} has no strategy');
      expect(html.contains('<li>'), isTrue,
          reason:
              '${game['id']} walkthrough (${steps.length}) is not rendered');
    }
  });
}

/// The registry ids the app can open, read once. Kept as a getter so a failure
/// names the missing game rather than the whole set.
Set<String> get visibleIds => {
      for (final GameMetadata game in GameCategories.visible) game.id,
    };

Set<String> get archivedIds => {
      for (final GameMetadata game
          in GameCategories.library(includeArchived: true))
        if (GameCategories.isArchived(game.id)) game.id,
    };
