import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `tool/reference-pins.tsv` is what a port cites: one line per source named in
/// docs/SOURCES.md, with the commit it was read at and the licence read from the file at that
/// commit. It is data, so it can rot silently: a stale commit, a source the doc names and the
/// table forgot, a licence column left empty. These are the checks that catch that.
void main() {
  final pinFile = File('tool/reference-pins.tsv');
  final rows = pinFile.existsSync()
      ? pinFile
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.split('\t'))
          .toList()
      : <List<String>>[];

  test('the pin table exists and has rows', () {
    expect(pinFile.existsSync(), isTrue, reason: 'tool/reference-pins.tsv is missing');
    expect(rows.length, greaterThan(50));
  });

  test('every row is dir, url, commit, licence, purpose', () {
    for (final row in rows) {
      expect(row.length, 5, reason: 'wrong number of columns: ${row.join(" | ")}');
      final [dir, url, commit, licence, purpose] = row;
      expect(dir.trim(), isNotEmpty);
      expect(url, startsWith('https://'), reason: dir);
      expect(RegExp(r'^[0-9a-f]{40}$').hasMatch(commit), isTrue,
          reason: '$dir has "${commit}" for a commit');
      expect(licence.trim(), isNotEmpty, reason: '$dir has no licence read at the commit');
      expect(purpose.trim(), isNotEmpty, reason: '$dir has no purpose, so nobody knows why');
    }
  });

  test('no source is pinned twice', () {
    final dirs = rows.map((row) => row[0]).toList();
    expect(dirs.toSet(), hasLength(dirs.length));
  });

  test('every repository docs/SOURCES.md names is pinned', () {
    // A repo named in the doc but absent from the table is the failure this file exists for:
    // on 2026-11-14 the doc named 55 and only five had been fetched, so no port could say
    // which commit it was written from.
    final doc = File('docs/SOURCES.md').readAsStringSync();
    final named = RegExp(r'`([A-Za-z0-9_.\-]+/[A-Za-z0-9_.\-]+)`')
        .allMatches(doc)
        .map((match) => match.group(1)!)
        .toSet();
    // Not repositories: a licence file path inside a KDE tree, and the site the witness editor
    // moved to (the repo itself is pinned under its old name).
    const notRepos = {
      'LICENSES/GPL-2.0-or-later.txt',
      'jbzdarkid/jbzdarkid.github.io',
    };
    final urls = rows.map((row) => row[1].toLowerCase()).toList();
    final missing = named
        .where((repo) => !notRepos.contains(repo))
        .where((repo) => !urls.any((url) => url.contains(repo.toLowerCase())))
        .toList()
      ..sort();
    expect(missing, isEmpty,
        reason: 'named in docs/SOURCES.md but not in tool/reference-pins.tsv:\n'
            '${missing.join('\n')}');
  });

  test('the sources the roadmap needs first are pinned', () {
    // The five new card types in SOURCES.md §5, plus the pools they draw on.
    const first = [
      'sigma144/witness-randomizer',
      'jbzdarkid/witness-puzzles',
      'google/material-design-icons',
      'jsnell/linjat',
      'fchollet/ARC-AGI',
      'mpSchrader/gym-sokoban',
      'robx/pzprjs',
      'en-wl/wordlist',
    ];
    final urls = rows.map((row) => row[1]).join('\n');
    for (final repo in first) {
      expect(urls.contains(repo), isTrue, reason: '$repo is not pinned');
    }
  });
}
