import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/repositories/game_stats_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/game_stats_provider.dart';
import 'package:puzzle/ui/features/feed/feed_session.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/utils/game_clock.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';

class _SeededGameStatsNotifier extends GameStatsNotifier {
  _SeededGameStatsNotifier(this._seeded);
  final Map<String, GameStat> _seeded;

  @override
  Map<String, GameStat> build() => _seeded;
}

/// Solving a puzzle in the feed must cost one tap and land on the next card.
/// The bridge that makes that work is [FeedSession], which the dialog reads
/// from outside the feed's subtree, so this test pins the contract.
void main() {
  tearDown(() {
    final FeedSession? live = FeedSession.current;
    if (live != null) FeedSession.deactivate(live);
  });

  Widget app(Widget child) => ProviderScope(
        child: MaterialApp(
          theme: DesignSystem.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: child)),
        ),
      );

  testWidgets('in the feed, solving offers the next card and nothing else',
      (tester) async {
    var dealt = 0;
    var replayed = 0;
    FeedSession.activate(FeedSession(
      next: () => dealt++,
      restart: () {},
      close: () {},
      isRoute: false,
    ));

    await tester.pumpWidget(app(Builder(
      builder: (context) => GameCompletionDialog(
        onHome: () {},
        onPlayAgain: () => replayed++,
        title: 'Solved',
        message: 'Every number in its place.',
        isVictory: true,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('NEXT PUZZLE'), findsOneWidget);
    // The full app's dialog offers Home and Play Next; the feed's offers one
    // way forward, because there is nowhere else to go.
    expect(find.text('HOME'), findsNothing);

    await tester.tap(find.text('NEXT PUZZLE'));
    await tester.pumpAndSettle();

    expect(dealt, 1);
    expect(replayed, 0);
  });

  testWidgets('the replay action stays on the same card', (tester) async {
    var dealt = 0;
    var replayed = 0;
    FeedSession.activate(FeedSession(
      next: () => dealt++,
      restart: () {},
      close: () {},
      isRoute: false,
    ));

    await tester.pumpWidget(app(Builder(
      builder: (context) => GameCompletionDialog(
        onHome: () {},
        onPlayAgain: () => replayed++,
        title: 'Solved',
        message: 'Done.',
      ),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();

    expect(replayed, 1);
    expect(dealt, 0);
  });

  testWidgets(
      'non-victory feed result shows failure title instead of solve time',
      (tester) async {
    FeedSession.activate(FeedSession(
      next: () {},
      restart: () {},
      close: () {},
      isRoute: false,
    ));
    GameClock.start('minesweeper');

    await tester.pumpWidget(ProviderScope(
      overrides: [
        gameStatsProvider.overrideWith(
          () => _SeededGameStatsNotifier(const <String, GameStat>{
            'minesweeper': GameStat(solves: 2, times: <int>[14000, 9000]),
          }),
        ),
      ],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: GameCompletionDialog(
              onHome: () {},
              onPlayAgain: () {},
              title: 'Game over',
              message: 'Hit a mine.',
              isVictory: false,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('GAME OVER'), findsOneWidget);
    expect(find.textContaining('BEST'), findsNothing);
    expect(find.text('0:09'), findsNothing);
  });
}
