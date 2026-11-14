import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
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

Widget _app(Widget child) => ProviderScope(
      overrides: [userRepositoryProvider.overrideWithValue(_FakeRepository())],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void _sizeTo(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('the counter starts on 001', (tester) async {
    _sizeTo(tester);
    await tester.pumpWidget(_app(const FeedScreen(startGameId: 'pegs')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('001'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
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

    await tester.pumpWidget(const SizedBox());
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

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a short pull puts the card back', (tester) async {
    _sizeTo(tester);
    await tester.pumpWidget(_app(const FeedScreen(startGameId: 'pegs')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.drag(find.byType(FeedScreen), const Offset(0, -24));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('001'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
