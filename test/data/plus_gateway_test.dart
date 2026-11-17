import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
// The platform interface of the plugin the app already depends on: only the
// type of `getPlatformAddition` comes from here, nothing the app ships.
// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:puzzle/data/purchase/plus_entitlement.dart';
import 'package:puzzle/data/purchase/plus_gateway.dart';

/// The store SDK itself, faked.
///
/// The controller is tested against a scripted `PlusGateway`; this file tests
/// the other half — the real `InAppPurchaseGateway`, against a fake
/// `InAppPurchase`. The wiring that cannot be left to reading code lives here:
/// when the purchase stream is subscribed, what each kind of update becomes,
/// what completing a delivered purchase does, and what a silent or failing
/// restore is allowed to conclude.
class _FakeIap implements InAppPurchase {
  final StreamController<List<PurchaseDetails>> _purchases =
      StreamController<List<PurchaseDetails>>.broadcast();

  /// What the store was told it can forget, in the order it was told.
  final List<PurchaseDetails> completed = [];

  bool available = true;
  Object? restoreError;

  /// How many times the store was asked for product details, and what it
  /// answers. A throw here is a store that could not be reached.
  int productQueries = 0;
  Object? productError;
  List<ProductDetails> products = const <ProductDetails>[];

  /// A purchase the store delivers, with no button pressed by anyone.
  void deliver(List<PurchaseDetails> purchases) => _purchases.add(purchases);

  /// The purchase stream itself dies (a store process crash, a channel error).
  void failStream(Object error) => _purchases.addError(error);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchases.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    productQueries++;
    final Object? error = productError;
    if (error != null) throw error;
    return ProductDetailsResponse(
      productDetails: products,
      notFoundIDs: <String>[plusProductId],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      throw UnimplementedError();

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase);

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    final Object? error = restoreError;
    if (error != null) throw error;
  }

  @override
  T getPlatformAddition<T extends InAppPurchasePlatformAddition?>() =>
      throw UnimplementedError();

  @override
  Future<String> countryCode() => throw UnimplementedError();
}

/// One purchase the store would report for the Plus product.
PurchaseDetails _purchase(
  PurchaseStatus status, {
  bool pendingComplete = false,
  String id = plusProductId,
  IAPError? error,
}) {
  final PurchaseDetails details = PurchaseDetails(
    productID: id,
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: '',
      source: 'test',
    ),
    transactionDate: '0',
    status: status,
  )
    ..pendingCompletePurchase = pendingComplete
    ..error = error;
  return details;
}

void main() {
  late _FakeIap iap;

  setUp(() {
    iap = _FakeIap();
  });

  tearDown(() async {
    await iap._purchases.close();
  });

  InAppPurchaseGateway gateway(
          {Duration settle = const Duration(seconds: 2)}) =>
      InAppPurchaseGateway(purchases: iap, restoreSettle: settle);

  Future<List<PurchaseEvent>> collect(InAppPurchaseGateway g) async {
    final List<PurchaseEvent> received = <PurchaseEvent>[];
    final StreamSubscription<PurchaseEvent> subscription =
        g.events.listen(received.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);
    return received;
  }

  test('the purchase stream is subscribed from construction', () async {
    final InAppPurchaseGateway g = gateway();
    addTearDown(g.dispose);
    final List<PurchaseEvent> received = await collect(g);

    // No buy was started and no restore was asked: an Ask to Buy approval, an
    // interrupted payment or a promo code redeemed while the app was closed is
    // delivered exactly like this.
    iap.deliver([
      _purchase(PurchaseStatus.purchased, pendingComplete: true),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1),
        reason: 'a purchase with no buy or restore open must still arrive');
    expect(received.single.status, PurchaseEventStatus.purchased);
    expect(received.single.pendingComplete, isTrue);

    // The store is told it can forget the transaction once, and only by the
    // event it is waiting on.
    await g.completePurchase(received.single);
    expect(iap.completed, hasLength(1));
    await g.completePurchase(received.single);
    expect(iap.completed, hasLength(1),
        reason: 'a transaction already completed is not completed twice');
  });

  test('a purchase the store is still processing is reported as pending',
      () async {
    final InAppPurchaseGateway g = gateway();
    addTearDown(g.dispose);
    final List<PurchaseEvent> received = await collect(g);

    iap.deliver([_purchase(PurchaseStatus.pending)]);
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single.status, PurchaseEventStatus.pending);
    expect(received.single.pendingComplete, isFalse,
        reason: 'a pending purchase is not completed; the store is not done');
  });

  test('a cancelled update is reported, not swallowed', () async {
    final InAppPurchaseGateway g = gateway();
    addTearDown(g.dispose);
    final List<PurchaseEvent> received = await collect(g);

    iap.deliver([_purchase(PurchaseStatus.canceled)]);
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single.status, PurchaseEventStatus.canceled);
  });

  test('an error that says the account already owns it is not a failure',
      () async {
    final InAppPurchaseGateway g = gateway();
    addTearDown(g.dispose);
    final List<PurchaseEvent> received = await collect(g);

    iap.deliver([
      _purchase(
        PurchaseStatus.error,
        pendingComplete: true,
        error: IAPError(
          source: 'test',
          code: 'itemAlreadyOwned',
          message: 'You already own this item',
        ),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single.status, PurchaseEventStatus.error);
    expect(received.single.alreadyOwned, isTrue);
    expect(received.single.pendingComplete, isTrue);
  });

  test('a purchase for another product is not Plus news', () async {
    final InAppPurchaseGateway g = gateway();
    addTearDown(g.dispose);
    final List<PurchaseEvent> received = await collect(g);

    iap.deliver([
      _purchase(PurchaseStatus.purchased, id: 'some_other_product'),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
  });

  test('dispose stops the subscription and closes the door', () async {
    final InAppPurchaseGateway g = gateway();
    final List<PurchaseEvent> received = await collect(g);
    await g.dispose();

    iap.deliver([
      _purchase(PurchaseStatus.purchased, pendingComplete: true),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
  });

  group('restore', () {
    test('a receipt delivered during the window answers owned', () async {
      final InAppPurchaseGateway g =
          gateway(settle: const Duration(milliseconds: 200));
      addTearDown(g.dispose);

      final Future<RestoreAnswer> answer = g.restore();
      await Future<void>.delayed(Duration.zero);
      iap.deliver([_purchase(PurchaseStatus.restored, pendingComplete: true)]);

      expect(await answer, RestoreAnswer.owned);
    });

    test('a store that answers nothing is no answer, never "nothing owned"',
        () async {
      final InAppPurchaseGateway g =
          gateway(settle: const Duration(milliseconds: 50));
      addTearDown(g.dispose);

      expect(await g.restore(), RestoreAnswer.noAnswer,
          reason: 'silence is not the store confirming the account owns '
              'nothing; only an explicit answer may take Plus away');
    });

    test('a restore whose stream errors is no answer, never "nothing owned"',
        () async {
      final InAppPurchaseGateway g =
          gateway(settle: const Duration(milliseconds: 200));
      addTearDown(g.dispose);

      final Future<RestoreAnswer> answer = g.restore();
      await Future<void>.delayed(Duration.zero);
      iap.failStream(Exception('the store died mid-restore'));

      expect(await answer, RestoreAnswer.noAnswer);
    });

    test('a restore the store call itself throws for is no answer', () async {
      iap.restoreError = Exception('no connection');
      final InAppPurchaseGateway g = gateway();
      addTearDown(g.dispose);

      expect(await g.restore(), RestoreAnswer.noAnswer);
    });

    test('a restore the store answers with an empty list is nothing owned',
        () async {
      final InAppPurchaseGateway g =
          gateway(settle: const Duration(milliseconds: 200));
      addTearDown(g.dispose);
      final List<PurchaseEvent> received = await collect(g);

      final Future<RestoreAnswer> answer = g.restore();
      await Future<void>.delayed(Duration.zero);
      // What every store sends when a restore finished and the account owns
      // nothing: StoreKit's empty end-of-restore list, StoreKit 2's empty
      // entitlements, Play's empty ownership query.
      iap.deliver(const <PurchaseDetails>[]);

      expect(await answer, RestoreAnswer.nothingOwned,
          reason: 'a refunded purchase must be revocable, which needs one '
              'explicit store answer that lists nothing');
      expect(received, isEmpty,
          reason: 'the empty list is an answer to a restore, not a purchase');
    });

    test('an empty list with no restore open changes nothing', () async {
      final InAppPurchaseGateway g =
          gateway(settle: const Duration(milliseconds: 50));
      addTearDown(g.dispose);
      final List<PurchaseEvent> received = await collect(g);

      iap.deliver(const <PurchaseDetails>[]);
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
      expect(await g.restore(), RestoreAnswer.noAnswer,
          reason: 'a list that arrived on its own is not this restore\'s '
              'answer; only the store finishing the restore it was asked for '
              'may revoke');
    });

    test('a store that is not there is no answer, and asks nothing', () async {
      iap.available = false;
      final InAppPurchaseGateway g = gateway();
      addTearDown(g.dispose);

      expect(await g.restore(), RestoreAnswer.noAnswer);
      expect(iap.completed, isEmpty);
    });
  });

  group('product details', () {
    test('a lookup that failed is asked again instead of remembered', () async {
      iap.productError = Exception('no connection');
      final InAppPurchaseGateway g = gateway();
      addTearDown(g.dispose);

      expect(await g.price(), isNull);
      expect(iap.productQueries, 1);

      // The connection came back: the next price reads the store, without the
      // app being restarted.
      iap.productError = null;
      iap.products = <ProductDetails>[
        ProductDetails(
          id: plusProductId,
          title: 'Puzzlestack Plus',
          description: 'One purchase',
          price: 'R\$ 29,90',
          rawPrice: 29.9,
          currencyCode: 'BRL',
        ),
      ];

      expect(await g.price(), 'R\$ 29,90');
      expect(iap.productQueries, 2);
    });

    test('a product the store did answer is kept', () async {
      iap.products = <ProductDetails>[
        ProductDetails(
          id: plusProductId,
          title: 'Puzzlestack Plus',
          description: 'One purchase',
          price: 'R\$ 29,90',
          rawPrice: 29.9,
          currencyCode: 'BRL',
        ),
      ];
      final InAppPurchaseGateway g = gateway();
      addTearDown(g.dispose);

      expect(await g.price(), 'R\$ 29,90');
      expect(await g.price(), 'R\$ 29,90');
      expect(iap.productQueries, 1, reason: 'the store is asked once');
    });
  });
}
