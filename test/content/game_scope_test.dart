import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/core/juice/game_scope.dart';
import 'package:puzzle/ui/features/games/silhouette_match/silhouette_match_screen.dart';
import 'package:puzzle/ui/features/games/silhouette_match_ortho/silhouette_match_ortho_screen.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/utils/game_clock.dart';

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

void main() {
  testWidgets('the scope decides which of two same-titled games is running',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(
      const GameScope(gameId: 'silhouette_match', child: SilhouetteMatchScreen()),
    ));
    await tester.pump();
    await tester.pump();

    // The clock is the observable: `completeGame` stops it by id, so a clock
    // under the wrong id is a game that records no time and no personal best.
    expect(GameClock.lastGameId, 'silhouette_match');
    expect(GameClock.stop('silhouette_match'), isNotNull);

    await tester.pumpWidget(_app(
      const GameScope(
          gameId: 'silhouette_match_ortho',
          child: SilhouetteMatchOrthoScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(GameClock.lastGameId, 'silhouette_match_ortho');
    expect(GameClock.stop('silhouette_match_ortho'), isNotNull);
  });

  testWidgets('without a scope the screen still resolves by its title',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const SilhouetteMatchOrthoScreen()));
    await tester.pump();
    await tester.pump();

    // No id in scope, so the title decides, as it did before the scope existed.
    expect(GameClock.lastGameId, isNotNull);
  });

  testWidgets('every registry id resolves to itself', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(_app(Builder(builder: (context) {
      captured = context;
      return const SizedBox();
    })));

    for (final entry in allGamesMetadata) {
      final resolved =
          resolveGame(captured, title: 'NOT A TITLE', gameId: entry.id);
      expect(resolved?.id, entry.id,
          reason: 'scope id ${entry.id} resolved to ${resolved?.id}');
    }
  });
}
