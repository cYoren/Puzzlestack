import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_engine.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_provider.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_screen.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';

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

Widget _app(Widget child) => ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(_FakeRepository()),
      ],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  _monkeyTests();

  testWidgets('replaying Inertia does not throw', (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const InertiaScreen()));
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(InertiaScreen)));
    final notifier = container.read(inertiaNotifierProvider.notifier);

    for (var round = 0; round < 3; round++) {
      // Solve, let the transition and the win dialog run, then replay.
      notifier.solve();
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'after solve $round');

      // The win must actually offer its dialog, or this test is not testing
      // the thing the player taps.
      expect(find.byType(GameCompletionDialog), findsOneWidget,
          reason: 'round $round never reached the result card');
      final Finder playAgain = find.descendant(
        of: find.byType(GameCompletionDialog),
        matching: find.byIcon(Icons.refresh_rounded),
      );
      expect(playAgain, findsOneWidget);
      await tester.tap(playAgain);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.byType(GameCompletionDialog), findsNothing);
      expect(tester.takeException(), isNull, reason: 'after replay $round');
      expect(container.read(inertiaNotifierProvider).isSolved, isFalse);
    }
  });
}

// A small monkey: the game has five verbs and a difficulty switch, and every
// one of them can be pressed in any order, including while the win cascade is
// still running. A crash the player can reach with two taps has to be reachable
// here first.

void _monkeyTests() {
  testWidgets('every Inertia action in any order leaves the screen alive',
      (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const InertiaScreen()));
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(InertiaScreen)));
    final notifier = container.read(inertiaNotifierProvider.notifier);
    final random = Random(11);

    for (var step = 0; step < 120; step++) {
      switch (random.nextInt(7)) {
        case 0:
          notifier.slide(InertiaDirection
              .values[random.nextInt(InertiaDirection.values.length)]);
        case 1:
          notifier.hint();
        case 2:
          notifier.retry();
        case 3:
          notifier.solve();
        case 4:
          notifier.newGame();
        case 5:
          notifier.setDifficulty(InertiaDifficulty.values[random.nextInt(3)]);
        case 6:
          notifier.setDifficulty(InertiaDifficulty.medium);
      }
      // Half a frame is the cruel case: replay while the win cascade runs.
      await tester.pump(Duration(milliseconds: random.nextInt(80)));
      if (tester.takeException() case final error?) {
        fail('step $step threw: $error');
      }
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
