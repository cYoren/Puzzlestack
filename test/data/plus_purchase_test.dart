import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/posthog.dart';
import 'package:puzzle/data/key_value_store.dart';
import 'package:puzzle/data/purchase/plus_controller.dart';
import 'package:puzzle/data/purchase/plus_entitlement.dart';
import 'package:puzzle/data/purchase/plus_gateway.dart';
import 'package:puzzle/data/purchase/plus_store.dart';

/// A store with a script. The whole point of the gateway interface: every path
/// a real store can take — bought, cancelled, pending, restored, refunded, and
/// the one where it never answers — is played here, with no login and no money.
class _FakeStore implements PlusGateway {
  _FakeStore({
    this.restoreAnswer = RestoreAnswer.nothingOwned,
  });

  PurchaseAnswer buyAnswer = PurchaseAnswer.purchased;
  Future<PurchaseAnswer> Function()? onBuy;
  RestoreAnswer restoreAnswer;
  String? priceText = 'US\$4.99';

  int buyCalls = 0;
  int restoreCalls = 0;
  int priceCalls = 0;

  /// The events the app told the store it can forget, in that order.
  final List<PurchaseEvent> completed = [];

  final StreamController<PurchaseEvent> _events =
      StreamController<PurchaseEvent>.broadcast();

  @override
  Stream<PurchaseEvent> get events => _events.stream;

  void emit(PurchaseEvent event) => _events.add(event);

  @override
  Future<String?> price() async {
    priceCalls++;
    return priceText;
  }

  @override
  Future<PurchaseAnswer> buy() async {
    buyCalls++;
    final Future<PurchaseAnswer> Function()? handler = onBuy;
    if (handler != null) return handler();
    return buyAnswer;
  }

  @override
  Future<RestoreAnswer> restore() async {
    restoreCalls++;
    return restoreAnswer;
  }

  @override
  Future<void> completePurchase(PurchaseEvent event) async =>
      completed.add(event);

  @override
  Future<void> dispose() async => _events.close();
}

void main() {
  late MemoryKeyValueStore rows;
  late _FakeStore store;
  late PlusController plus;

  PlusController controller({
    DateTime? now,
    _FakeStore? gateway,
    KeyValueStore? storage,
  }) {
    final KeyValueStore backing = storage ?? rows;
    final _FakeStore fake = gateway ?? store;
    return PlusController(
      store: PlusStore(backing),
      gateway: () => fake,
      now: () => now ?? DateTime.utc(2026, 11, 16, 9),
    );
  }

  setUp(() {
    rows = MemoryKeyValueStore();
    store = _FakeStore();
    plus = controller();
  });

  group('a fresh device', () {
    test('owns nothing, and "free" is the only thing a missing row can mean',
        () {
      expect(plus.state.ownsPlus, isFalse);
      expect(plus.state.notice, PlusNotice.none);
      expect(plus.state.busy, isFalse);
    });

    test('a corrupt row reads as free rather than as owned', () {
      rows = MemoryKeyValueStore({PlusStore.rowKey: 'nonsense'});
      expect(controller().state.ownsPlus, isFalse);

      rows = MemoryKeyValueStore({
        PlusStore.rowKey: {'owns': true, 'product': 'some_other_product'},
      });
      expect(controller().state.ownsPlus, isFalse);

      rows = MemoryKeyValueStore({
        PlusStore.rowKey: {'owns': true, 'product': plusProductId},
      });
      expect(controller().state.ownsPlus, isFalse,
          reason: 'an owned row without a date is not a purchase');
    });
  });

  group('buying', () {
    test('a completed purchase unlocks Plus and is written down once',
        () async {
      final PlusNotice notice = await plus.buy();

      expect(notice, PlusNotice.purchased);
      expect(plus.state.ownsPlus, isTrue);
      expect(plus.state.busy, isFalse);
      expect(plus.state.entitlement.productId, plusProductId);
      expect(plus.state.entitlement.since, isNotNull);

      // The row is the only unlock: a new launch reads it back.
      expect(controller().state.ownsPlus, isTrue);
    });

    test('a cancelled purchase unlocks nothing and is not a failure', () async {
      store.buyAnswer = PurchaseAnswer.cancelled;
      final PlusNotice notice = await plus.buy();

      expect(notice, PlusNotice.cancelled);
      expect(plus.state.ownsPlus, isFalse);
      expect(rows.read(PlusStore.rowKey), isNull);
    });

    test('a purchase the store is still processing unlocks nothing', () async {
      store.buyAnswer = PurchaseAnswer.pending;
      expect(await plus.buy(), PlusNotice.pending);
      expect(plus.state.ownsPlus, isFalse);
    });

    test('an account that already owns it gets it, and is told so', () async {
      store.buyAnswer = PurchaseAnswer.alreadyOwned;
      expect(await plus.buy(), PlusNotice.alreadyOwned);
      expect(plus.state.ownsPlus, isTrue);
    });

    test('a failure leaves the device exactly as it was', () async {
      store.buyAnswer = PurchaseAnswer.failed;
      expect(await plus.buy(), PlusNotice.failed);
      expect(plus.state.ownsPlus, isFalse);
      expect(rows.read(PlusStore.rowKey), isNull);
    });

    test('a store that is not there says so instead of charging nothing',
        () async {
      store.buyAnswer = PurchaseAnswer.storeUnavailable;
      expect(await plus.buy(), PlusNotice.unavailable);
      expect(plus.state.storeReachable, isFalse);
      expect(plus.state.ownsPlus, isFalse);
    });
  });

  group('restoring', () {
    test('a restore that finds the purchase unlocks it on this device',
        () async {
      store.restoreAnswer = RestoreAnswer.owned;
      expect(await plus.restore(), PlusNotice.restored);
      expect(plus.state.ownsPlus, isTrue);
      expect(controller().state.ownsPlus, isTrue);
    });

    test('a definitive empty answer to a free player is not a revocation',
        () async {
      store.restoreAnswer = RestoreAnswer.nothingOwned;
      expect(await plus.restore(), PlusNotice.nothingToRestore);
      expect(plus.state.ownsPlus, isFalse);
      expect(plus.state.notice, isNot(PlusNotice.revoked));
    });

    test('a store that never answered keeps Plus, which is the whole point',
        () async {
      store.buyAnswer = PurchaseAnswer.purchased;
      await plus.buy();
      store.restoreAnswer = RestoreAnswer.noAnswer;

      expect(await plus.restore(), PlusNotice.failed);
      expect(plus.state.ownsPlus, isTrue,
          reason: 'a request that failed is not a refund');
    });
  });

  group('a refunded purchase is revoked', () {
    test('on the next launch, when the store lists nothing', () async {
      await plus.buy();
      expect(plus.state.ownsPlus, isTrue);

      // A new session: same storage, a store that no longer lists it.
      final _FakeStore storeAfterRefund = _FakeStore(
        restoreAnswer: RestoreAnswer.nothingOwned,
      );
      final PlusController nextLaunch = controller(gateway: storeAfterRefund);

      expect(nextLaunch.state.ownsPlus, isTrue, reason: 'local row first');
      expect(await nextLaunch.verifyOnLaunch(), PlusNotice.revoked);
      expect(nextLaunch.state.ownsPlus, isFalse);
      expect(rows.read(PlusStore.rowKey), isNull);

      // And it stays gone: the row is what a third launch reads.
      expect(controller().state.ownsPlus, isFalse);
    });

    test('the launch check asks the store exactly once', () async {
      await plus.buy();
      final _FakeStore next = _FakeStore(restoreAnswer: RestoreAnswer.owned);
      final PlusController nextLaunch = controller(gateway: next);

      await nextLaunch.verifyOnLaunch();
      expect(next.restoreCalls, 1);
      expect(nextLaunch.state.ownsPlus, isTrue);
      expect(nextLaunch.state.entitlement.verifiedAt, isNotNull);
    });

    test('a launch check that gets no answer changes nothing', () async {
      await plus.buy();
      final _FakeStore next = _FakeStore(restoreAnswer: RestoreAnswer.noAnswer);
      final PlusController nextLaunch = controller(gateway: next);

      expect(await nextLaunch.verifyOnLaunch(), PlusNotice.none);
      expect(nextLaunch.state.ownsPlus, isTrue);
      expect(nextLaunch.state.notice, PlusNotice.none);
    });

    test('a free player\'s launch never calls the store', () async {
      await plus.verifyOnLaunch();
      expect(store.restoreCalls, 0,
          reason: 'most launches have no purchase to check');
    });
  });

  group('a purchase that completes on its own', () {
    // Ask to Buy approved after a restart, an interrupted payment, a promo
    // code redeemed: the store delivers these with no buy or restore tap, so
    // the subscription that catches them is what makes them ever arrive.
    test(
        'a purchased update with no buy or restore tap unlocks Plus and is '
        'completed', () async {
      await plus.start();
      expect(plus.state.ownsPlus, isFalse);

      store.emit(const PurchaseEvent.purchased(pendingComplete: true));
      await Future<void>.delayed(Duration.zero);

      expect(plus.state.ownsPlus, isTrue);
      expect(plus.state.notice, PlusNotice.purchased);
      expect(store.completed, hasLength(1));
      expect(store.completed.single.status, PurchaseEventStatus.purchased);

      // The row is the unlock: a new launch reads it back.
      expect(controller().state.ownsPlus, isTrue);
    });

    test('a restored update with no buy or restore tap unlocks Plus too',
        () async {
      await plus.start();

      store.emit(const PurchaseEvent.restored(pendingComplete: true));
      await Future<void>.delayed(Duration.zero);

      expect(plus.state.ownsPlus, isTrue);
      expect(store.completed, hasLength(1));
    });

    test(
        'a purchase the store is still processing does not unlock, and the '
        'completed update after it does', () async {
      await plus.start();

      store.emit(const PurchaseEvent.pending());
      await Future<void>.delayed(Duration.zero);

      expect(plus.state.ownsPlus, isFalse);
      expect(plus.state.notice, PlusNotice.pending);
      expect(store.completed, isEmpty,
          reason: 'a pending purchase is not completed; the store is not done');

      store.emit(const PurchaseEvent.purchased(pendingComplete: true));
      await Future<void>.delayed(Duration.zero);

      expect(plus.state.ownsPlus, isTrue);
      expect(store.completed, hasLength(1));
    });

    test('a cancelled update unlocks nothing', () async {
      await plus.start();

      store.emit(const PurchaseEvent.canceled());
      await Future<void>.delayed(Duration.zero);

      expect(plus.state.ownsPlus, isFalse);
      expect(plus.state.notice, PlusNotice.cancelled);
      expect(store.completed, isEmpty);
    });

    test('an error the store reports is a failure, and is still completed',
        () async {
      await plus.start();

      store.emit(const PurchaseEvent.error(pendingComplete: true));
      await Future<void>.delayed(Duration.zero);

      expect(plus.state.ownsPlus, isFalse);
      expect(plus.state.notice, PlusNotice.failed);
      // A failed purchase that is never completed is re-delivered forever.
      expect(store.completed, hasLength(1));
    });

    test('an error that says the account already owns it grants Plus',
        () async {
      await plus.start();

      store.emit(
        const PurchaseEvent.error(pendingComplete: true, alreadyOwned: true),
      );
      await Future<void>.delayed(Duration.zero);

      expect(plus.state.ownsPlus, isTrue);
      expect(plus.state.notice, PlusNotice.alreadyOwned);
      expect(store.completed, hasLength(1));
    });

    test('an update the store is not waiting on completes nothing', () async {
      await plus.start();

      store.emit(const PurchaseEvent.purchased());
      await Future<void>.delayed(Duration.zero);

      expect(plus.state.ownsPlus, isTrue);
      expect(store.completed, isEmpty);
    });

    test('arrives even on a device that already owns Plus', () async {
      store.buyAnswer = PurchaseAnswer.purchased;
      await plus.buy();
      await plus.dispose();

      // A new session on a device that already owns Plus: the subscription is
      // still made, so a purchase that completed elsewhere still lands.
      final _FakeStore nextStore =
          _FakeStore(restoreAnswer: RestoreAnswer.owned);
      final PlusController next = controller(gateway: nextStore);
      await next.start();

      nextStore.emit(const PurchaseEvent.purchased(pendingComplete: true));
      await Future<void>.delayed(Duration.zero);

      expect(next.state.ownsPlus, isTrue);
      expect(nextStore.completed, hasLength(1));
    });
  });

  group('start', () {
    test('a purchase that arrives while the app is open is adopted', () async {
      await plus.start();
      expect(plus.state.ownsPlus, isFalse);

      store.emit(const PurchaseEvent.purchased());
      await Future<void>.delayed(Duration.zero);

      expect(plus.state.ownsPlus, isTrue);
      expect(controller().state.ownsPlus, isTrue);
    });

    test('the price comes from the store and is never invented', () async {
      await plus.start();
      expect(store.priceCalls, 1);
      expect(plus.state.price, 'US\$4.99');
    });

    test('a store with no price is marked unreachable, not priced at zero',
        () async {
      store.priceText = null;
      await plus.start();
      expect(plus.state.price, isNull);
      expect(plus.state.storeReachable, isFalse);
    });

    test(
        'ensurePrice rechecks reachability after a transient unavailable buy '
        'even when a price is cached', () async {
      await plus.start();
      expect(plus.state.price, 'US\$4.99');
      expect(plus.state.storeReachable, isTrue);
      expect(store.priceCalls, 1);

      store.buyAnswer = PurchaseAnswer.storeUnavailable;
      expect(await plus.buy(), PlusNotice.unavailable);
      expect(plus.state.storeReachable, isFalse);
      expect(plus.state.price, 'US\$4.99');

      // Reopening the sheet calls ensurePrice(): because storeReachable is
      // false, it re-probes the store and brings the buttons back.
      await plus.ensurePrice();
      expect(store.priceCalls, 2);
      expect(plus.state.storeReachable, isTrue);
    });

    test(
        'a pending stream update during an active buy keeps busy on and blocks '
        'overlapping store calls', () async {
      await plus.start();
      final Completer<PurchaseAnswer> inFlight = Completer<PurchaseAnswer>();
      store.onBuy = () => inFlight.future;

      final Future<PlusNotice> buying = plus.buy();
      await Future<void>.delayed(Duration.zero);
      expect(plus.state.busy, isTrue);
      expect(store.buyCalls, 1);

      // StoreKit / Play emits pending while the payment sheet is still open.
      store.emit(const PurchaseEvent.pending());
      await Future<void>.delayed(Duration.zero);

      expect(plus.state.notice, PlusNotice.pending);
      expect(plus.state.busy, isTrue,
          reason: 'busy must stay true until the buy itself settles');

      // Tapping buy or restore while pending does not start a second call.
      expect(await plus.buy(), PlusNotice.pending);
      expect(await plus.restore(), PlusNotice.pending);
      expect(store.buyCalls, 1);
      expect(store.restoreCalls, 0);

      inFlight.complete(PurchaseAnswer.purchased);
      expect(await buying, PlusNotice.purchased);
      expect(plus.state.ownsPlus, isTrue);
      expect(plus.state.busy, isFalse);
    });
  });

  /// The funnel events are sent from inside `PlusController`, which is the one
  /// place every store path passes through. A double count here would make the
  /// conversion rate in PostHog wrong, so this pins one event per outcome.
  group('the purchase funnel', () {
    late PostHog savedPostHog;
    late List<Map<String, Object?>> sent;

    setUp(() async {
      savedPostHog = PostHog.instance;
      sent = <Map<String, Object?>>[];
      PostHog.instance = PostHog(
        apiKey: 'phc_test',
        sender: (Uri endpoint, String body) async {
          final Map<String, Object?> decoded =
              jsonDecode(body) as Map<String, Object?>;
          for (final Object? event in decoded['batch'] as List<Object?>) {
            sent.add(event! as Map<String, Object?>);
          }
          return true;
        },
      );
      // A store build that may send: above `kLiveStoreVersion`.
      await PostHog.instance.start(
        platform: 'android',
        storage: MemoryPostHogStorage(),
        nativeVersion: '1.1.0+17',
      );
      sent.clear();
    });

    tearDown(() => PostHog.instance = savedPostHog);

    List<String> names() =>
        sent.map((Map<String, Object?> e) => e['event'] as String).toList();

    Map<String, Object?> propertiesOf(Map<String, Object?> event) =>
        event['properties'] as Map<String, Object?>;

    test('one completed purchase sends started once and completed once',
        () async {
      final PlusNotice notice = await plus.buy();

      expect(notice, PlusNotice.purchased);
      expect(names(), <String>['purchase_started', 'purchase_completed']);
      expect(propertiesOf(sent.last)['result'], 'purchased');
      // The envelope is intact on the funnel events too.
      expect(propertiesOf(sent.last)['app'], 'puzzlestack');
      expect(propertiesOf(sent.last)['app_version'], '1.1.0+17');
    });

    test('a cancel is a failed purchase, never a completed one', () async {
      store.buyAnswer = PurchaseAnswer.cancelled;

      await plus.buy();

      expect(names(), <String>['purchase_started', 'purchase_failed']);
      expect(propertiesOf(sent.last)['result'], 'cancelled');
    });

    test('a restore that finds Plus is purchase_restored, not a sale',
        () async {
      store.restoreAnswer = RestoreAnswer.owned;

      await plus.restore();

      expect(names(), <String>['purchase_restored']);
      expect(propertiesOf(sent.single)['product'], 'plus');
    });
  });
}
