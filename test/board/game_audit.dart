/// Not a test: a measuring tool, run by hand.
///
///     flutter test -j 4 test/board/game_audit.dart
///
/// It pumps every game in the registry at 320dp and counts the ones that
/// overflow or throw. The file is deliberately not named `_test.dart` so it
/// stays out of the suite. Mounting the full registry is a separate check.
/// It still **fails** when a board
/// overflows or throws: the count is asserted at the end, because a check that
/// only prints a number is a check nobody reads. Run it on a batch, and on a
/// game you just touched (below).
///
/// One game at a time, with the full dump (file and line of the offending
/// widget):
///
///     AUDIT_ONLY=collatz flutter test test/board/game_audit.dart
///
/// Set AUDIT_FEED=1 to mount Deck games in the actual Deal instead of opening
/// them standalone. Combine it with AUDIT_DARK=1 for the dark Deal.
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
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/core/juice/game_scope.dart';
import 'package:puzzle/ui/features/feed/feed_screen.dart';
import 'package:puzzle/utils/design_system.dart';

Widget _app(Widget child) => ProviderScope(
  overrides: [userRepositoryProvider.overrideWithValue(_FakeRepository())],
  child: MaterialApp(
    theme: DesignSystem.lightTheme,
    darkTheme: DesignSystem.darkTheme,
    // AUDIT_DARK=1 runs the same sweep in the dark theme, which is where a
    // hardcoded near-black used to disappear.
    themeMode: Platform.environment['AUDIT_DARK'] == '1'
        ? ThemeMode.dark
        : ThemeMode.light,
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
  final where = RegExp(r'(lib/[^\s]+\.dart:\d+):\d+')
      .firstMatch(details)
      ?.group(1);
  return [amount ?? 'overflow', if (where != null) 'at $where'].join(' ');
}

/// game id -> first line of the error it produced.
final _overflowed = <String, String>{};
final _threw = <String, String>{};
final _checked = <String>{};

void main() {
  final inFeed = Platform.environment['AUDIT_FEED'] == '1';
  final only = Platform.environment['AUDIT_ONLY']
      ?.split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();

  final eligible = inFeed
      ? allGamesMetadata.where((g) => deckIds.contains(g.id))
      : allGamesMetadata;
  final games = eligible.where((g) => only?.contains(g.id) ?? true).toList();

  // An id that names no card audits nothing and reports `checked=0 overflow=0`,
  // which reads exactly like a clean room. A typo must fail, not reassure.
  final unknown = only == null
      ? const <String>{}
      : only.difference({for (final game in eligible) game.id});

  tearDownAll(() {
    // ignore: avoid_print
    print(
      'AUDIT checked=${_checked.length} '
      'overflow=${_overflowed.length} threw=${_threw.length}',
    );
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
        await tester.pumpWidget(
          _app(
            inFeed
                ? FeedScreen(startGameId: meta.id)
                : Builder(builder: (c) => meta.builder(c)),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        if (inFeed) {
          expect(
            find.byWidgetPredicate(
              (widget) => widget is GameScope && widget.gameId == meta.id,
            ),
            findsOneWidget,
            reason: 'the Deal did not mount ${meta.id}',
          );
        }
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
  // Registered after the loop, so it runs after every card has been pumped. The
  // coverage assertion is what stops this from silently checking an empty map:
  // a test that runs before the sweep passes for the wrong reason, and that is
  // exactly how this assertion was first written.
  test('no card overflows and none throws', () {
    expect(
      unknown,
      isEmpty,
      reason: 'AUDIT_ONLY named ids outside this sweep: $unknown',
    );
    expect(
      _checked,
      hasLength(games.length),
      reason: 'the sweep did not reach every card',
    );
    expect(_overflowed, isEmpty, reason: 'overflowing cards: $_overflowed');
    expect(_threw, isEmpty, reason: 'cards that threw: $_threw');
  });
}
