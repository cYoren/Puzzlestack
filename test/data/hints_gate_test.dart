import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/key_value_store.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/picks/hint_gate.dart';
import 'package:puzzle/data/picks/hint_ledger.dart';
import 'package:puzzle/data/purchase/plus_gateway.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/pick_providers.dart';
import 'package:puzzle/providers/plus_providers.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/core/assist/hint_request.dart';
import 'package:puzzle/ui/features/feed/feed_screen.dart';
import 'package:puzzle/utils/design_system.dart';

class _ScriptedPlusGateway implements PlusGateway {
  _ScriptedPlusGateway({this.buyAnswer = PurchaseAnswer.purchased});

  PurchaseAnswer buyAnswer;
  RestoreAnswer restoreAnswer = RestoreAnswer.nothingOwned;
  final StreamController<PurchaseEvent> _events =
      StreamController<PurchaseEvent>.broadcast();

  @override
  Stream<PurchaseEvent> get events => _events.stream;

  @override
  Future<String?> price() async => 'US\$4.99';

  @override
  Future<PurchaseAnswer> buy() async => buyAnswer;

  @override
  Future<RestoreAnswer> restore() async => restoreAnswer;

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
  late MemoryKeyValueStore rows;
  late DateTime now;
  bool plus = false;

  HintGate gate() => HintGate(
        ledger: HintLedger(rows, now: () => now),
        hasPlus: () => plus,
      );

  setUp(() {
    rows = MemoryKeyValueStore();
    now = DateTime(2026, 11, 17, 14, 0);
    plus = false;
  });

  group('HintGate and HintLedger', () {
    test('allows three free hints a day and refuses the fourth', () async {
      final HintGate hints = gate();

      expect(
          await hints.request(), const HintAllowed(HintReason.freeAllowance));
      expect(
          await hints.request(), const HintAllowed(HintReason.freeAllowance));
      expect(
          await hints.request(), const HintAllowed(HintReason.freeAllowance));
      expect(
        await hints.request(),
        const HintRefused(usedToday: 3, freePerDay: 3),
      );
      expect((await HintLedger(rows, now: () => now).today()).used, 3);
    });

    test('rolls over cleanly at midnight and ignores corrupt rows', () async {
      final HintGate hints = gate();
      for (int i = 0; i < 3; i++) {
        await hints.request();
      }
      expect(await hints.request(), isA<HintRefused>());

      now = DateTime(2026, 11, 18, 0, 1);
      expect(
          await hints.request(), const HintAllowed(HintReason.freeAllowance));
      expect((await HintLedger(rows, now: () => now).today()).used, 1);

      final corrupt = MemoryKeyValueStore({HintLedger.dayKey: 'bad_value'});
      expect((await HintLedger(corrupt, now: () => now).today()).used, 0);
    });

    test('Plus makes hints unlimited without spending free allowance',
        () async {
      final HintGate hints = gate();
      await hints.request();
      await hints.request();
      await hints.request();
      expect(await hints.request(), isA<HintRefused>());

      plus = true;
      for (int i = 0; i < 10; i++) {
        expect(await hints.request(), const HintAllowed(HintReason.plus));
      }
    });
  });

  group('requestHint and PlusSheet integration', () {
    testWidgets(
        'fourth hint opens PlusSheet with hints headline and unlocks on buy',
        (tester) async {
      final MemoryKeyValueStore pickRows = MemoryKeyValueStore();
      final MemoryKeyValueStore plusRows = MemoryKeyValueStore();
      final _ScriptedPlusGateway gateway = _ScriptedPlusGateway(
        buyAnswer: PurchaseAnswer.cancelled,
      );
      int hintsDelivered = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pickStoreProvider.overrideWithValue(pickRows),
            plusStoreProvider.overrideWithValue(plusRows),
            plusGatewayProvider.overrideWithValue(() => gateway),
          ],
          child: MaterialApp(
            theme: DesignSystem.lightTheme,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => Center(
                  child: TextButton(
                    onPressed: () =>
                        requestHint(context, ref, () => hintsDelivered++),
                    child: const Text('USE HINT'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Three free hints fire immediately without opening any paywall.
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('USE HINT'));
        await tester.pumpAndSettle();
      }
      expect(hintsDelivered, 3);
      expect(find.text('PUZZLESTACK PLUS'), findsNothing);

      // Fourth hint opens PlusSheet with the hints headline.
      await tester.tap(find.text('USE HINT'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unlimited hints, whenever you want one.'),
        findsOneWidget,
      );
      expect(hintsDelivered, 3);

      // Dismissing without buying leaves hint count at 3.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(hintsDelivered, 3);

      // Buying Plus on the next attempt delivers the 4th hint immediately.
      gateway.buyAnswer = PurchaseAnswer.purchased;
      await tester.tap(find.text('USE HINT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GET PLUS'));
      await tester.pumpAndSettle();

      expect(hintsDelivered, 4);

      // Fifth hint now runs directly with no sheet.
      await tester.tap(find.text('USE HINT'));
      await tester.pumpAndSettle();
      expect(hintsDelivered, 5);
    });

    testWidgets('feed card footer exposes gated hint button on Think cards',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final MemoryKeyValueStore pickRows = MemoryKeyValueStore();
      final MemoryKeyValueStore plusRows = MemoryKeyValueStore();
      final _ScriptedPlusGateway gateway = _ScriptedPlusGateway();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
            pickStoreProvider.overrideWithValue(pickRows),
            plusStoreProvider.overrideWithValue(plusRows),
            plusGatewayProvider.overrideWithValue(() => gateway),
          ],
          child: MaterialApp(
            theme: DesignSystem.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const FeedScreen(startGameId: 'lights_out'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final Finder hintBtn =
          find.byKey(const ValueKey<String>('feed_hint_lights_out'));
      expect(hintBtn, findsOneWidget);

      for (int i = 0; i < 3; i++) {
        await tester.tap(hintBtn);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('PUZZLESTACK PLUS'), findsNothing);

      // 4th tap opens the Plus sheet.
      await tester.tap(hintBtn);
      await tester.pumpAndSettle();
      expect(
        find.text('Unlimited hints, whenever you want one.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
