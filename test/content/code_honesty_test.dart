import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Signatures that promise something the code does not do.
///
/// Four word engines took a `languageCode` and ignored it — `find_word` even
/// cached the one English list under every language that asked, so a caller
/// passing `de` got English and no error. The word assets are English; the
/// honest signature says so. This test keeps the parameter from creeping back
/// in without a per-locale word list behind it.
void main() {
  test('no game engine accepts a language it does not use', () {
    final offenders = <String>[];
    final games = Directory('lib/ui/features/games');
    for (final entity in games.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('_engine.dart')) continue;
      final source = entity.readAsStringSync();
      if (RegExp(r'String\s+languageCode').hasMatch(source)) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty,
        reason: 'a language parameter with one English word list behind it:\n'
            '${offenders.join('\n')}');
  });
}
