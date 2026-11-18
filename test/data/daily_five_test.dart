import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/daily/daily_five.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/data/key_value_store.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/purchase/plus_gateway.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/daily_five_providers.dart';
import 'package:puzzle/providers/pick_providers.dart';
import 'package:puzzle/providers/plus_providers.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/daily/daily_five_screen.dart';
import 'package:puzzle/ui/features/feed/deal_order.dart';
import 'package:puzzle/ui/features/feed/feed_screen.dart';
import 'package:puzzle/ui/features/feed/feed_session.dart';
import 'package:puzzle/ui/features/games/futoshiki/futoshiki_provider.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_provider.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';

class _ScriptedPlusGateway implements PlusGateway {
  _ScriptedPlusGateway({this.buyAnswer = PurchaseAnswer.purchased});

  PurchaseAnswer buyAnswer;
  final StreamController<PurchaseEvent> _events =
      StreamController<PurchaseEvent>.broadcast();

  @override
  Stream<PurchaseEvent> get events => _events.stream;

  @override
  Future<String?> price() async => 'US\$4.99';

  @override
  Future<PurchaseAnswer> buy() async => buyAnswer;

  @override
  Future<RestoreAnswer> restore() async => RestoreAnswer.nothingOwned;

  @override
  Future<void> completePurchase(PurchaseEvent event) async {}

  @override
  Future<void> dispose() async => _events.close();
}

class _FakeUserRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}
}

void main() {
  group('dailyFiveForDate and seeded determinism', () {
    test('deals Think, Word, Think, Snap, Think identically for the same date',
        () {
      final List<String> a = dailyFiveForDate('2026-11-17', localeCode: 'en');
      final List<String> b = dailyFiveForDate('2026-11-17', localeCode: 'en');
      final List<String> nextDay =
          dailyFiveForDate('2026-11-18', localeCode: 'en');

      expect(a, b);
      expect(a.length, 5);
      expect(a.toSet().length, 5);
      for (final String id in a) {
        expect(deckIds.contains(id), isTrue);
      }
      expect(
        [for (final String id in a) cardKindOf(id)],
        [
          CardKind.think,
          CardKind.word,
          CardKind.think,
          CardKind.snap,
          CardKind.think,
        ],
      );
      expect(a, isNot(nextDay));

      // Non-English turns slot 1 into Think.
      final List<String> pt = dailyFiveForDate('2026-11-17', localeCode: 'pt');
      expect(cardKindOf(pt[1]), CardKind.think);
    });

    test('same dailySeedFor produces identical puzzle boards across containers',
        () {
      final int seed = dailySeedFor('2026-11-17', 0, 'lights_out');
      final FeedSession s1 = FeedSession(
        next: () {},
        restart: () {},
        close: () {},
        isRoute: true,
        fixedFeedSize: true,
        seedFor: (_) => seed,
      );
      FeedSession.activate(s1);
      final ProviderContainer c1 = ProviderContainer();
      final ProviderContainer c2 = ProviderContainer();
      addTearDown(c1.dispose);
      addTearDown(c2.dispose);
      addTearDown(() => FeedSession.deactivate(s1));

      final List<bool> grid1 = c1.read(lightsOutNotifierProvider).grid;
      final List<bool> grid2 = c2.read(lightsOutNotifierProvider).grid;
      expect(grid1, grid2);
    });
  });

  group('DailyFiveStore streak and plain-text share', () {
    test('counts consecutive finished Daily Five days and nothing else',
        () async {
      final MemoryKeyValueStore rows = MemoryKeyValueStore();
      final DailyFiveStore store = DailyFiveStore(rows);

      Future<void> finishDay(String key) async {
        for (int slot = 0; slot < 5; slot++) {
          await store.recordSlot(
            dayKey: key,
            slot: slot,
            elapsedMs: (slot + 1) * 20000,
          );
        }
      }

      await finishDay('2026-11-15');
      await finishDay('2026-11-16');
      // Partially completing 17 Nov (only 3/5) keeps yesterday's 2-day streak.
      for (int slot = 0; slot < 3; slot++) {
        await store.recordSlot(
          dayKey: '2026-11-17',
          slot: slot,
          elapsedMs: 15000,
        );
      }
      expect(store.streakAt(DateTime(2026, 11, 17, 12)), 2);

      // Finishing all 5 on 17 Nov extends the streak to 3.
      await store.recordSlot(dayKey: '2026-11-17', slot: 3, elapsedMs: 15000);
      await store.recordSlot(dayKey: '2026-11-17', slot: 4, elapsedMs: 15000);
      expect(store.streakAt(DateTime(2026, 11, 17, 18)), 3);

      // Skipping 18 Nov resets streak on 19 Nov to 0.
      expect(store.streakAt(DateTime(2026, 11, 19, 9)), 0);
    });

    test('formats plain-text share without links or dashes', () {
      final String shared = formatDailyFiveShare(
        dayKey: '2026-11-14',
        results: const <DailySlotResult>[
          DailySlotResult(gameId: 'sudoku', title: 'Sudoku', elapsedMs: 41000),
          DailySlotResult(
            gameId: 'find_word',
            title: 'Find Word',
            elapsedMs: 62000,
            badge: '3/6',
          ),
          DailySlotResult(gameId: 'hitori', title: 'Hitori', elapsedMs: 72000),
          DailySlotResult(
            gameId: 'schulte_table',
            title: 'Schulte',
            elapsedMs: 19000,
          ),
          DailySlotResult(gameId: 'game_2048', title: '2048', elapsedMs: 63000),
        ],
      );
      expect(
        shared,
        'Puzzlestack 14 Nov\n'
        'Sudoku 0:41 \u00b7 Find Word 3/6 \u00b7 Hitori 1:12 \u00b7 Schulte 0:19 \u00b7 2048 1:03\n'
        'Total 4:17',
      );
      expect(shared.contains(RegExp('[\u2013\u2014]')), isFalse);
      expect(shared.contains('http'), isFalse);
    });
  });

  group('Daily Five Plus archive gate', () {
    testWidgets(
        'today is free; selecting a past day opens PlusSheet and unlocks after purchase',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final MemoryKeyValueStore pickRows = MemoryKeyValueStore();
      final MemoryKeyValueStore plusRows = MemoryKeyValueStore();
      final _ScriptedPlusGateway gateway = _ScriptedPlusGateway(
        buyAnswer: PurchaseAnswer.cancelled,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
            pickStoreProvider.overrideWithValue(pickRows),
            plusStoreProvider.overrideWithValue(plusRows),
            dailyFiveClockProvider
                .overrideWithValue(() => DateTime(2026, 11, 17, 10)),
            plusGatewayProvider.overrideWithValue(() => gateway),
          ],
          child: MaterialApp(
            theme: DesignSystem.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DailyFiveScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Today (17 NOV) is open and free.
      expect(find.text('17 NOV'), findsOneWidget);
      expect(find.text('1 / 5'), findsOneWidget);

      // Open archive and tap yesterday (2026-11-16) as a free player.
      await tester.tap(
        find.byKey(const ValueKey<String>('daily_five_archive_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('PAST DAYS ARE PLUS'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('daily_archive_2026-11-16')),
      );
      await tester.pumpAndSettle();

      // PlusSheet opens with the Daily Five archive headline.
      expect(
        find.text('Play any Daily Five in the archive.'),
        findsOneWidget,
      );

      // Cancel purchase -> stays on 17 NOV.
      await tester.tap(find.text('GET PLUS'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('17 NOV'), findsOneWidget);

      // Now allow purchase -> tapping 2026-11-16 unlocks 16 NOV immediately!
      gateway.buyAnswer = PurchaseAnswer.purchased;
      await tester.tap(
        find.byKey(const ValueKey<String>('daily_five_archive_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('daily_archive_2026-11-16')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('GET PLUS'));
      await tester.pumpAndSettle();

      expect(find.text('16 NOV'), findsOneWidget);
      expect(find.text('1 / 5'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
        'isolates Daily Five game state from a live Deal card and stays free across midnight',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      DateTime now = DateTime(2026, 11, 17, 23, 59);
      // Find a date whose slot 0 is futoshiki so both Deal and Daily Five mount
      // futoshiki at the same time.
      String targetDay = '2026-11-18';
      for (int d = 18; d <= 45; d++) {
        final String candidate = DateTime(2026, 11, 1)
            .add(Duration(days: d - 1))
            .toIso8601String()
            .substring(0, 10);
        if (dailyFiveForDate(candidate).first == 'futoshiki') {
          targetDay = candidate;
          break;
        }
      }

      final ProviderContainer root = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
          dailyFiveClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(root.dispose);

      // Prime dailyFiveProvider before midnight (2026-11-17).
      expect(root.read(dailyFiveProvider).todayKey, '2026-11-17');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: root,
          child: MaterialApp(
            theme: DesignSystem.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const FeedScreen(startGameId: 'futoshiki'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final FutoshikiState dealBefore = root.read(futoshikiNotifierProvider);

      // Advance clock to targetDay without restarting the app or container,
      // verify dailyFiveProvider.todayKey updates immediately, and open Daily
      // Five from the Deal header chip.
      now = DateTime.parse('${targetDay}T08:00:00');
      expect(root.read(dailyFiveProvider).todayKey, targetDay);
      await tester
          .tap(find.byKey(const ValueKey<String>('feed_daily_five_chip')));
      await tester.pumpAndSettle();

      // Today's new date is free (not locked behind the archive gate).
      expect(find.text('UNLOCK ARCHIVE WITH PLUS'), findsNothing);
      expect(find.text('1 / 5'), findsOneWidget);

      // Trigger a hint in Daily Five and verify the background Deal's
      // futoshiki state in root was NOT mutated.
      final Finder dailyHint =
          find.byIcon(Icons.lightbulb_outline_rounded).last;
      await tester.tap(dailyHint);
      await tester.pump();
      expect(
          identical(root.read(futoshikiNotifierProvider), dealBefore), isTrue);

      // Showing a loss dialog (isVictory: false) and tapping NEXT PUZZLE
      // advances to slot 2 WITHOUT marking slot 0 solved.
      final BuildContext dailyCtx =
          tester.element(find.byType(DailyFiveScreen));
      showDialog<void>(
        context: dailyCtx,
        builder: (_) => GameCompletionDialog(
          isVictory: false,
          title: 'Game over',
          message: 'Hit a mine.',
          onHome: () {},
          onPlayAgain: () {},
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('NEXT PUZZLE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('2 / 5'), findsOneWidget);
      expect(
        root
            .read(dailyFiveProvider)
            .progressFor(targetDay)
            .timesMs
            .containsKey(0),
        isFalse,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
