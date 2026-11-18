import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/data/key_value_store.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/feed/deal_order.dart';
import 'package:puzzle/ui/features/feed/feed_deck.dart';
import 'package:puzzle/ui/features/feed/feed_screen.dart';
import 'package:puzzle/utils/design_system.dart';

class _FakeUserRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}
}

void main() {
  group('firstTenIds', () {
    test('has 10 unique verified Deck games alternating kinds', () {
      expect(firstTenIds.length, 10);
      expect(firstTenIds.toSet().length, 10);
      for (final String id in firstTenIds) {
        expect(deckIds.contains(id), isTrue, reason: '$id must be in deckIds');
      }
      for (int i = 0; i < firstTenIds.length; i++) {
        expect(
          cardKindOf(firstTenIds[i]),
          dealRhythm[i % dealRhythm.length],
          reason: 'slot $i (${firstTenIds[i]}) follows dealRhythm',
        );
      }
    });

    test('leads the very first session when cardsSeen is 0', () {
      final List<String> dealt = dealSequence(
        deck: deckIds,
        history: const DealHistory(cardsSeen: 0, localeCode: 'en'),
        random: Random(42),
        count: 15,
        includeFirstTen: true,
      );
      expect(dealt.take(10).toList(), firstTenIds);

      final FeedDeck feedDeck = FeedDeck(
        random: Random(42),
        includeFirstTen: true,
      );
      expect(
        [for (int i = 0; i < 10; i++) feedDeck.gameAt(i).id],
        firstTenIds,
      );
    });
  });

  group('dealSequence rhythm, spacing, family, locale, and weights', () {
    test('follows Think Word Think Snap rhythm and 20-card spacing', () {
      final List<String> dealt = dealSequence(
        deck: deckIds,
        history: const DealHistory(cardsSeen: 10, localeCode: 'en'),
        random: Random(7),
        count: 64,
      );
      expect(dealt.length, 64);

      for (int i = 0; i < dealt.length; i++) {
        final CardKind expected = dealRhythm[(10 + i) % dealRhythm.length];
        final CardKind actual = cardKindOf(dealt[i]);
        // Every slot matches the beat or falls back to Think if exhausted.
        expect(
          actual == expected || actual == CardKind.think,
          isTrue,
          reason: 'card $i (${dealt[i]}) expected $expected, got $actual',
        );

        // No repeat within 20 cards.
        for (int prev = max(0, i - minRepeatSpacing); prev < i; prev++) {
          expect(
            dealt[i],
            isNot(dealt[prev]),
            reason: 'card $i repeated card $prev within 20 cards',
          );
        }

        // No two adjacent games from the same family.
        if (i > 0) {
          expect(
            dealFamilyOf(dealt[i]),
            isNot(dealFamilyOf(dealt[i - 1])),
            reason: 'cards ${i - 1} and $i share family',
          );
        }
      }
    });

    test('replaces Word cards with Think cards when locale is not English', () {
      final List<String> dealt = dealSequence(
        deck: deckIds,
        history: const DealHistory(cardsSeen: 0, localeCode: 'pt'),
        random: Random(99),
        count: 40,
        includeFirstTen: true,
      );
      for (final String id in dealt) {
        expect(
          cardKindOf(id),
          isNot(CardKind.word),
          reason: '$id is a Word card dealt in non-English locale',
        );
      }
    });

    test('computes weights per FEED.md specification', () {
      const DealHistory early = DealHistory(
        liked: {'akari'},
        solved: {'bridges', 'futoshiki'},
        quickSkips: {'futoshiki': 2, 'dominosa': 5},
        seen: {'akari', 'bridges', 'futoshiki', 'dominosa'},
        cardsSeen: 20,
      );
      // Liked seen: 3.0
      expect(dealWeightFor('akari', early), closeTo(3.0, 1e-9));
      // Solved and never quick-skipped: 1.5
      expect(dealWeightFor('bridges', early), closeTo(1.5, 1e-9));
      // Solved but quick-skipped twice: 0.5^2 = 0.25 (not given 1.5x)
      expect(dealWeightFor('futoshiki', early), closeTo(0.25, 1e-9));
      // Quick-skipped 5 times: floored at 0.1
      expect(dealWeightFor('dominosa', early), closeTo(0.1, 1e-9));
      // Never seen in first 100 cards: 2.0
      expect(dealWeightFor('sudoku', early), closeTo(2.0, 1e-9));

      const DealHistory veteran = DealHistory(cardsSeen: 150);
      // Never seen after 100 cards: 1.2
      expect(dealWeightFor('sudoku', veteran), closeTo(1.2, 1e-9));
    });
  });

  group('SeedHistoryStore 30-day no-repeat', () {
    test('avoids recent seeds within 30 days and expires older ones', () {
      final MemoryKeyValueStore backing = MemoryKeyValueStore();
      final SeedHistoryStore seeds = SeedHistoryStore(backing);
      final DateTime day1 = DateTime(2026, 11, 1);

      final Set<int> seen = <int>{};
      for (int d = 0; d < 25; d++) {
        final int s = seeds.nextSeed(
          gameId: 'futoshiki',
          today: day1.add(Duration(days: d)),
          random: Random(d + 1),
        );
        expect(seen.add(s), isTrue, reason: 'seed repeated within 30 days');
      }

      // A deterministic 2-seed fake RNG colliding with day1's seed must pick a
      // different seed while within 30 days, and may reuse it on day 32.
      final MemoryKeyValueStore smallStore = MemoryKeyValueStore();
      final SeedHistoryStore tracked = SeedHistoryStore(smallStore);
      final int first = tracked.nextSeed(
        gameId: 'sudoku',
        today: day1,
        random: Random(777),
      );
      final int withinWindow = tracked.nextSeed(
        gameId: 'sudoku',
        today: day1.add(const Duration(days: 10)),
        random: Random(777),
      );
      expect(withinWindow, isNot(first));

      final int after31Days = tracked.nextSeed(
        gameId: 'sudoku',
        today: day1.add(const Duration(days: 31)),
        random: Random(777),
      );
      expect(after31Days, first);
    });
  });

  group('card-teaches and swipe-rules on FeedScreen', () {
    testWidgets(
        'shows goal line <= 60 chars, pulses nudge after 6s idle, and header swipe deals',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
          ],
          child: MaterialApp(
            theme: DesignSystem.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const FeedScreen(startGameId: 'pegs'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final Finder goalFinder =
          find.byKey(const ValueKey<String>('feed_goal_pegs'));
      expect(goalFinder, findsOneWidget);
      final Text goalWidget = tester.widget<Text>(goalFinder);
      expect((goalWidget.data ?? '').length, lessThanOrEqualTo(60));

      // Before 6s idle, no nudge box is active.
      expect(
          find.byKey(const ValueKey<String>('feed_idle_nudge')), findsNothing);

      // At 6s + mid-animation (300ms), the one-time idle nudge pulses.
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey<String>('feed_idle_nudge')),
        findsOneWidget,
      );

      // Settle pulse back to rest.
      await tester.pump(const Duration(milliseconds: 500));
      expect(
          find.byKey(const ValueKey<String>('feed_idle_nudge')), findsNothing);

      // Dragging up on the card header deals card 002.
      final Finder header0 =
          find.byKey(const ValueKey<String>('feed_card_header_0'));
      await tester.drag(header0, const Offset(0, -140));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('002'), findsOneWidget);

      // Dragging down on the card header steps one card back to 001.
      final Finder header1 =
          find.byKey(const ValueKey<String>('feed_card_header_1'));
      await tester.drag(header1, const Offset(0, 140));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('001'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
        'non-English launch builds eligible pool without English Word cards',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
          ],
          child: MaterialApp(
            locale: const Locale('pt'),
            theme: DesignSystem.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const FeedScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final int nonWordDeckCount =
          deckIds.where((id) => cardKindOf(id) != CardKind.word).length;
      expect(find.text(' / $nonWordDeckCount'), findsOneWidget);

      // Card 002 in English firstTenIds is find_word (WORD); in Portuguese it
      // must NOT be a WORD card.
      final Finder header0 =
          find.byKey(const ValueKey<String>('feed_card_header_0'));
      await tester.drag(header0, const Offset(0, -140));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('WORD \u00b7'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
