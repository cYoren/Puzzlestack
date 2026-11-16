// Dumps the site's source data: every game the app can open, with the English
// copy the app already ships, so `tool/gen_site.py` can build pages without
// scraping the Dart or guessing a title.
//
//   dart run tool/site_export.dart            # writes tool/site/games.json
//
// Why a tool and not the generator: only Dart can read `gameGuides` (the guide
// text is Dart maps), and only the catalog knows which games are playable. The
// Python side owns the HTML; this side owns the truth.

import 'dart:convert';
import 'dart:io';

import 'package:puzzle/data/game_guides.dart';

/// `docs/CATALOG.md` in four blocks per room. Deck and library are the app;
/// merge keeps the keeper and archives the absorbed one; archive is material.
///
/// The catalog is the source of truth for tiers — `lib/data/game_profiles.dart`
/// is generated from it — so the site reads the document, not the generated
/// table, exactly as `test/content/game_profiles_test.dart` does.
Map<String, String> _tiers(String catalog) {
  final Map<String, String> tiers = {};
  final Map<String, String> rooms = {};
  String room = '';
  String block = '';
  final List<String> buffer = [];

  void flush() {
    if (block.isEmpty) return;
    final List<String> ids = buffer
        .join(' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((id) => id.isNotEmpty)
        .toList();
    buffer.clear();
    for (final String id in ids) {
      // The guide's own `category` is legacy (it says "math & logic",
      // "visual spatial"); the room is what the app files the game under, and
      // the catalog's headings are the six rooms.
      if (room.isNotEmpty) rooms[id] = room.toLowerCase();
      switch (block) {
        case 'deck':
        case 'library':
          tiers[id] = block;
        case 'merge':
          // `keeper <- absorbed absorbed`: the keeper is already in a block of
          // its own, the absorbed games are archived twins.
          final int arrow = ids.indexOf('<-');
          if (arrow >= 0 && ids.indexOf(id) > arrow) {
            tiers.putIfAbsent(id, () => 'merge');
          }
        case 'archive':
          tiers.putIfAbsent(id, () => 'archive');
      }
    }
    block = '';
  }

  for (final String raw in const LineSplitter().convert(catalog)) {
    final String line = raw.trim();
    if (line.startsWith('```')) {
      if (block.isEmpty) {
        block = line.substring(3).trim();
        buffer.clear();
      } else {
        flush();
      }
      continue;
    }
    if (block.isNotEmpty) {
      buffer.add(line);
      continue;
    }
    final RegExpMatch? room_ = RegExp(r'^##\s+(\w+)').firstMatch(line);
    if (room_ != null) room = room_.group(1)!;
  }
  assert(tiers.length > 300,
      'only ${tiers.length} ids read; is the catalog format different?');
  for (final MapEntry<String, String> entry in tiers.entries) {
    final String? room = rooms[entry.key];
    if (room != null) _rooms[entry.key] = room;
  }
  return tiers;
}

/// Room per id, filled by [_tiers]. A top-level map keeps the parser a single
/// pass without returning a record from a function the tests also call.
final Map<String, String> _rooms = {};

/// The English title and subtitle the app ships, straight from the ARB file.
///
/// Subtitles carry placeholders (`{maxTries}`), which are for the app to fill in;
/// a page wants the sentence without them, so they are stripped here rather than
/// in five templates.
Map<String, Map<String, String>> _copy(String arbPath) {
  final Map<String, dynamic> arb =
      jsonDecode(File(arbPath).readAsStringSync()) as Map<String, dynamic>;
  final Map<String, Map<String, String>> copy = {};
  final RegExp key = RegExp(r'^([A-Za-z0-9]+)Title$');
  for (final String name in arb.keys) {
    if (name.startsWith('@')) continue;
    final RegExpMatch? match = key.firstMatch(name);
    if (match == null) continue;
    final String id = _snake(match.group(1)!);
    final String subtitle = (arb['${match.group(1)}Subtitle'] as String?) ?? '';
    copy[id] = {
      'title': arb[name] as String,
      'subtitle': subtitle
          .replaceAll(RegExp(r'\{[a-zA-Z]+\}'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    };
  }
  return copy;
}

/// `SPOT THE CHANGING ITEM` -> `Spot the changing item`. Only touches a line that
/// is shouting: a mixed-case string is already a sentence.
String sentenceCase(String text) {
  final String trimmed = text.trim();
  if (trimmed.isEmpty) return '';
  final bool shouting =
      trimmed == trimmed.toUpperCase() && RegExp(r'[A-Z]').hasMatch(trimmed);
  if (!shouting) return trimmed;
  final String lower = trimmed.toLowerCase();
  return lower.isEmpty ? lower : lower[0].toUpperCase() + lower.substring(1);
}

/// A slug is the search term, not the code name. Only what a person would type
/// differs from the id; everything else is the id with dashes.
const Map<String, String> slugOverrides = {
  'game_2048': '2048',
  'sdmt': 'symbol-digit',
  'd2_attention': 'attention-d2',
};

/// `nBack` -> `n_back`, `findWord` -> `find_word`, `wordSearch` -> `word_search`.
String _snake(String camel) => camel
    .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
    .toLowerCase();

void main(List<String> args) {
  final String catalog = File('docs/CATALOG.md').readAsStringSync();
  final Map<String, String> tiers = _tiers(catalog);
  final Map<String, Map<String, String>> copy = _copy('lib/l10n/app_en.arb');

  final List<Map<String, Object?>> games = [];
  final List<String> missing = [];
  for (final MapEntry<String, GameGuide> entry in gameGuides.entries) {
    final String id = entry.key;
    final GameGuide guide = entry.value;
    final String? tier = tiers[id];
    // Only what a player can open. The archive is not published: a page per lab
    // task would be 89 pages about games the app refuses to deal.
    if (tier != 'deck' && tier != 'library') continue;
    final Map<String, String> text = copy[id] ?? const {};
    // 85 ids still ship an ALL-CAPS title (`BINARY PUZZLE`), which is the
    // `plain-names` job in ROADMAP.md. A page title is what a search result
    // shows, so the site sentence-cases it now instead of waiting.
    final String title = sentenceCase((text['title'] ?? guide.title).trim());
    if (title.isEmpty) missing.add(id);
    // Four games ship no subtitle key, and 42 ship one in shouting capitals
    // (the bar in PUZZLE-BAR.md says a card's line is plain sentence case). The
    // page takes the app's line when it reads, otherwise the guide's objective.
    final String card = sentenceCase(text['subtitle'] ?? '');
    final String line = card.isNotEmpty ? card : sentenceCase(guide.objective);
    games.add({
      'id': id,
      'slug': slugOverrides[id] ?? id.replaceAll('_', '-'),
      'title': title,
      'subtitle': line,
      'category': _rooms[id] ?? 'logic',
      'tier': tier,
      'objective': guide.objective.trim(),
      'controls': guide.controls.trim(),
      'walkthrough': guide.walkthrough,
      'strategies': guide.strategies,
    });
  }

  games.sort((a, b) {
    final int byRoom =
        (a['category']! as String).compareTo(b['category']! as String);
    return byRoom != 0
        ? byRoom
        : (a['title']! as String).compareTo(b['title']! as String);
  });

  final Map<String, Object?> payload = {
    'generatedFrom':
        'docs/CATALOG.md, lib/data/game_guides.dart, lib/l10n/app_en.arb',
    'count': games.length,
    'games': games,
  };

  final Directory out = Directory('tool/site')..createSync(recursive: true);
  File('${out.path}/games.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(payload));

  stdout.writeln('${games.length} playable games -> ${out.path}/games.json');
  if (missing.isNotEmpty) {
    stderr.writeln('no title for: ${missing.join(', ')}');
    exitCode = 1;
  }
}
