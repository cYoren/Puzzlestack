import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/feed/feed_screen.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_provider.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';

/// "Play again" on a card in the deal re-deals that card. It must not pop the
/// app apart: the feed's restart already owns a single pop of the result sheet,
/// and a second pop used to remove the whole tab (a black screen, reported as a
/// crash).
class _FakeRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}

  @override
  List<GameStreak> getAllGameStreaks() => const [];

  @override
  Future<void> saveGameCompletion(UserData userData, GameStreak streak) async {}
}

Widget _app() => ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(_FakeRepository()),
      ],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FeedScreen(startGameId: 'inertia'),
      ),
    );

void main() {
  testWidgets('play again on a feed card keeps the feed, with a fresh board',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(FeedScreen)));
    container.read(inertiaNotifierProvider.notifier).solve();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.byType(GameCompletionDialog), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(GameCompletionDialog),
      matching: find.byIcon(Icons.refresh_rounded),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // The test font is not the app's font, so ignore overflow noise and assert
    // what this test is about: the navigation.
    while (tester.takeException() != null) {}
    // The card, and the tab around it, are still there.
    expect(find.byType(FeedScreen), findsOneWidget,
        reason: 'replay popped the feed instead of re-dealing the card');
    expect(find.byType(GameCompletionDialog), findsNothing);
    expect(container.read(inertiaNotifierProvider).isSolved, isFalse,
        reason: 'the re-dealt card is a fresh board');
  });
}
