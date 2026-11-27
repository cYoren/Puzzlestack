import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/core/board/puzzle_board_view.dart';
import 'package:puzzle/ui/features/feed/feed_screen.dart';
import 'package:puzzle/utils/design_system.dart';

/// The deal is a state machine: pull the live card, commit it, step the deck.
/// The animation is the pretty part; this pins the part that must not break.
class _FakeRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}
}

Widget _app(Widget child, {ThemeMode themeMode = ThemeMode.light}) =>
    ProviderScope(
      overrides: [userRepositoryProvider.overrideWithValue(_FakeRepository())],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        darkTheme: DesignSystem.darkTheme,
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

/// Tear the feed down, and let a straggler timer fire before the test ends.
///
/// The card after the pinned one comes from the shuffled pool, so a run can deal
/// a game that schedules a timer in `initState` (Chain Reaction schedules a 50 ms
/// haptic). That timer outlives the test and fails it at teardown with "Pending
/// timers" after every assertion has passed - a test that fails at random tells
/// you nothing about anything. Pumping past it with the tree gone drains it.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
}

void _sizeTo(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('both Minesweeper modes are reachable in the 320dp Deal',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const FeedScreen(startGameId: 'minesweeper')));
    await tester.pump(const Duration(milliseconds: 300));

    for (final icon in [Icons.ads_click_rounded, Icons.flag_rounded]) {
      final control = find.byIcon(icon).hitTestable();
      expect(control, findsOneWidget);
      await tester.tap(control);
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await _teardown(tester);
  });

  for (final id in ['futoshiki', 'skyscrapers']) {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('$id fits the 320dp Deal in ${themeMode.name}',
          (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
            _app(FeedScreen(startGameId: id), themeMode: themeMode));
        await tester.pump(const Duration(milliseconds: 300));

        final board =
            find.byWidgetPredicate((widget) => widget is PuzzleBoardView);
        expect(board, findsOneWidget);
        expect(tester.getSize(board).shortestSide, greaterThan(0));
        expect(tester.takeException(), isNull);
        await _teardown(tester);
      });
    }
  }

  testWidgets('the counter starts on 001', (tester) async {
    _sizeTo(tester);
    await tester.pumpWidget(_app(const FeedScreen(startGameId: 'pegs')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('001'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('NEXT deals the next card and the counter follows',
      (tester) async {
    _sizeTo(tester);
    await tester.pumpWidget(_app(const FeedScreen(startGameId: 'pegs')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('001'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    // The settle is 360ms; give it room, then let the reveal finish.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('002'), findsOneWidget,
        reason: 'the deal stepped the deck and the card face says 002');
    expect(find.text('001'), findsNothing);

    await _teardown(tester);
  });

  testWidgets('a thumb-sized drag does not deal the next card', (tester) async {
    // Gus, 2026-11-16: on a desktop a board drag (Tangle, Inertia, Netslide all
    // take one) was dealing the next card. A card that leaves when you did not
    // mean it is worse than one that needs a deliberate flick.
    _sizeTo(tester);
    await tester.pumpWidget(_app(const FeedScreen(startGameId: 'pegs')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.drag(find.byType(FeedScreen), const Offset(0, -90));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('001'), findsOneWidget);

    await _teardown(tester);
  });

  testWidgets('pulling the card up past the threshold deals it',
      (tester) async {
    _sizeTo(tester);
    await tester.pumpWidget(_app(const FeedScreen(startGameId: 'pegs')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Drag the live card a third of the card height, then let go.
    await tester.drag(find.byType(FeedScreen), const Offset(0, -260));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('002'), findsOneWidget);

    await _teardown(tester);
  });

  testWidgets('a short pull puts the card back', (tester) async {
    _sizeTo(tester);
    await tester.pumpWidget(_app(const FeedScreen(startGameId: 'pegs')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.drag(find.byType(FeedScreen), const Offset(0, -24));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('001'), findsOneWidget);

    await _teardown(tester);
  });
}
