/// Not a test: a measuring tool, run by hand.
///
///     flutter test -j 4 test/board/game_audit.dart
///
/// It pumps every game in the registry at 320dp and counts the ones that
/// overflow or throw. The file is deliberately not named `_test.dart` so it
/// stays out of the suite: it reports a number rather than asserting one, and
/// the number is currently bad enough that a red suite would only say what this
/// already says. Run it after a batch of fixes to see whether the count moved.
///
/// One game at a time, with the full dump (file and line of the offending
/// widget):
///
///     AUDIT_ONLY=collatz flutter test test/board/game_audit.dart
///
/// Why one `testWidgets` per game rather than one loop: the binding keeps the
/// *first* exception of a test and counts the rest, so a single loop reported
/// "Multiple exceptions (N) were detected" for every game after the first leak
/// and the `threw` list was really one bug plus its shadow. A test per game
/// resets that bookkeeping, so each line below names the game that broke.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/utils/design_system.dart';

Widget _app(Widget child) => ProviderScope(
      overrides: [userRepositoryProvider.overrideWithValue(_FakeRepository())],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        darkTheme: DesignSystem.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

class _FakeRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}
}

/// The overflow amount plus the widget that owns the offending flex, which is
/// the two facts needed to fix it.
String _reason(String details) {
  final amount = RegExp(r'overflowed by [^\n]+').firstMatch(details)?.group(0);
  final where =
      RegExp(r'(lib/[^\s]+\.dart:\d+):\d+').firstMatch(details)?.group(1);
  return [amount ?? 'overflow', if (where != null) 'at $where'].join(' ');
}

/// game id -> first line of the error it produced.
final _overflowed = <String, String>{};
final _threw = <String, String>{};
final _checked = <String>{};

void main() {
  final only = Platform.environment['AUDIT_ONLY']
      ?.split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();

  final games = only == null
      ? allGamesMetadata
      : allGamesMetadata.where((g) => only.contains(g.id)).toList();

  tearDownAll(() {
    // ignore: avoid_print
    print('AUDIT checked=${_checked.length} '
        'overflow=${_overflowed.length} threw=${_threw.length}');
    // One line per broken game, with the reason, so the list is a worklist
    // rather than a count. `flutter test ... | grep AUDIT` is the whole tool.
    _overflowed.forEach((id, why) => print('AUDIT overflow $id: $why'));
    _threw.forEach((id, why) => print('AUDIT threw $id: $why'));
  });

  for (final meta in games) {
    testWidgets('audit ${meta.id}', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      _checked.add(meta.id);

      // Capture the details rather than `takeException`: when a game reports
      // more than one error the tester hands back a summary object ("Multiple
      // exceptions (N) were detected") instead of the errors themselves, and
      // the summary loses the widget that caused them.
      final previousOnError = FlutterError.onError;
      final captured = <FlutterErrorDetails>[];
      FlutterError.onError = captured.add;

      try {
        await tester.pumpWidget(_app(Builder(builder: (c) => meta.builder(c))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      } catch (e) {
        _threw[meta.id] = e.toString().split('\n').first;
        return;
      } finally {
        FlutterError.onError = previousOnError;
      }

      final overflow = <String>[];
      final other = <String>[];
      for (final details in captured) {
        final text = details.toString();
        (text.contains('overflowed') ? overflow : other).add(text);
      }

      if (other.isNotEmpty) {
        _threw[meta.id] = other.first.split('\n').first.trim();
        if (only != null) print('AUDIT detail ${meta.id}\n${other.first}');
      } else if (overflow.isNotEmpty) {
        _overflowed[meta.id] = _reason(overflow.first);
        if (only != null) print('AUDIT detail ${meta.id}\n${overflow.first}');
      }

      // Dispose the tree inside the test so a game's timers cannot fail the
      // run before the summary is printed.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
