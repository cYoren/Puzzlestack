import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'plus_entitlement.dart';

/// What the store said when the player asked to buy.
///
/// Six outcomes, because "not purchased" is six different situations and the
/// player is owed the right one: a cancel is not a failure, and a purchase the
/// store is still processing is not a cancel.
enum PurchaseAnswer {
  purchased,
  alreadyOwned,
  cancelled,
  pending,
  storeUnavailable,
  failed,
}

/// What the store said when asked what this account owns.
///
/// [noAnswer] is deliberately **not** [nothingOwned]. A request that failed, or
/// a store that never answered, must never take Plus away from someone who paid;
/// only a completed answer that lists nothing may revoke.
enum RestoreAnswer { owned, nothingOwned, noAnswer }

/// A purchase the store reported for this product, outside a buy the player
/// just started: a restore, another device, or a purchase that was interrupted
/// before it was completed.
enum PurchaseEvent { owned, failed }

/// The store, behind an interface.
///
/// This is the only place in the app that talks to a store SDK, and it is the
/// only network the app has. It is an interface so that buy, restore and the
/// revocation path can be tested without a store login, and so that no widget
/// ever decides what a purchase means.
abstract class PlusGateway {
  /// The localised price the store will charge, or null when it could not be
  /// read. Never a hardcoded price: the store owns pricing.
  Future<String?> price();

  Future<PurchaseAnswer> buy();

  Future<RestoreAnswer> restore();

  /// Purchases as they arrive, while the app is running.
  Stream<PurchaseEvent> get events;

  Future<void> dispose();
}

/// The real store: `in_app_purchase`, one non-consumable.
///
/// Every purchase the store reports is completed here, bought or restored, so
/// the store never replays a purchase the player already has. Nothing leaves
/// the device: the receipt is not sent anywhere, because there is no server to
/// send it to and no DRM to enforce.
class InAppPurchaseGateway implements PlusGateway {
  InAppPurchaseGateway({InAppPurchase? purchases})
      : _iap = purchases ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final StreamController<PurchaseEvent> _events =
      StreamController<PurchaseEvent>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Completer<PurchaseAnswer>? _buy;
  Completer<void>? _restored;
  ProductDetails? _product;
  bool _productLookedUp = false;

  @override
  Stream<PurchaseEvent> get events => _events.stream;

  /// How long a restore waits for the store to hand back a receipt after the
  /// restore call itself has returned. The call returning without an error is
  /// the store answering; this window only absorbs delivery.
  static const Duration _restoreSettle = Duration(seconds: 2);

  /// How long a buy may stay open before it is reported as pending. The store
  /// can take minutes when a bank asks for a step; the app does not block on it.
  static const Duration _buyWindow = Duration(minutes: 5);

  void _attach() {
    _subscription ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) {
        debugPrint('Purchase stream error: $error');
        _buy?.complete(PurchaseAnswer.failed);
        _buy = null;
      },
    );
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      // An empty id is an error that belongs to no product; it can still be a
      // failure of this one, so it is read rather than skipped.
      final String id = purchase.productID;
      if (id.isNotEmpty && id != plusProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Deliver the thing first, then tell the store it can forget it.
          _events.add(PurchaseEvent.owned);
          _restored?.complete();
          _restored = null;
          _buy?.complete(PurchaseAnswer.purchased);
          _buy = null;
          await _finish(purchase);
        case PurchaseStatus.canceled:
          _buy?.complete(PurchaseAnswer.cancelled);
          _buy = null;
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          final PurchaseAnswer answer = _readError(purchase.error);
          _events.add(PurchaseEvent.failed);
          _buy?.complete(answer);
          _buy = null;
          await _finish(purchase);
      }
    }
  }

  /// A store error, read once. "You already own this" is not a failure to
  /// charge twice, it is the account telling us the local row was missing.
  PurchaseAnswer _readError(IAPError? error) {
    final String code = error?.code ?? '';
    final String message = (error?.message ?? '').toLowerCase();
    if (code.contains('alreadyOwned') ||
        code.contains('itemAlreadyOwned') ||
        message.contains('already own')) {
      return PurchaseAnswer.alreadyOwned;
    }
    return PurchaseAnswer.failed;
  }

  Future<void> _finish(PurchaseDetails purchase) async {
    try {
      await _iap.completePurchase(purchase);
    } catch (error) {
      debugPrint('completePurchase failed: $error');
    }
  }

  Future<bool> _available() async {
    try {
      return await _iap.isAvailable();
    } catch (error) {
      // A desktop build has no store. That is not a failure of the app.
      debugPrint('Store unavailable: $error');
      return false;
    }
  }

  Future<ProductDetails?> _details() async {
    if (_productLookedUp) return _product;
    _productLookedUp = true;
    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails({plusProductId});
      _product = response.productDetails.isEmpty
          ? null
          : response.productDetails.first;
    } catch (error) {
      debugPrint('queryProductDetails failed: $error');
      _product = null;
    }
    return _product;
  }

  @override
  Future<String?> price() async {
    if (!await _available()) return null;
    final ProductDetails? details = await _details();
    return details?.price;
  }

  @override
  Future<PurchaseAnswer> buy() async {
    if (!await _available()) return PurchaseAnswer.storeUnavailable;
    final ProductDetails? details = await _details();
    if (details == null) return PurchaseAnswer.storeUnavailable;

    _attach();
    final Completer<PurchaseAnswer> answer = Completer<PurchaseAnswer>();
    _buy = answer;

    bool started;
    try {
      started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
    } catch (error) {
      debugPrint('buyNonConsumable failed: $error');
      _buy = null;
      return PurchaseAnswer.failed;
    }
    if (!started) {
      _buy = null;
      return PurchaseAnswer.failed;
    }

    try {
      return await answer.future.timeout(
        _buyWindow,
        onTimeout: () => PurchaseAnswer.pending,
      );
    } finally {
      if (identical(_buy, answer)) _buy = null;
    }
  }

  @override
  Future<RestoreAnswer> restore() async {
    if (!await _available()) return RestoreAnswer.noAnswer;
    _attach();

    final Completer<void> owned = Completer<void>();
    _restored = owned;

    try {
      await _iap.restorePurchases();
    } catch (error) {
      // The store did not answer. This is the one case that must not revoke.
      debugPrint('restorePurchases failed: $error');
      if (identical(_restored, owned)) _restored = null;
      return RestoreAnswer.noAnswer;
    }

    try {
      await owned.future.timeout(_restoreSettle);
      return RestoreAnswer.owned;
    } on TimeoutException {
      // The store answered and listed nothing this account owns.
      return RestoreAnswer.nothingOwned;
    } finally {
      if (identical(_restored, owned)) _restored = null;
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _buy = null;
    _restored = null;
    await _events.close();
  }
}

/// A store that is not there (a desktop build, a test that does not want one).
///
/// It answers honestly: no price, no purchase, no ownership, and a restore that
/// admits it did not ask.
class NoStoreGateway implements PlusGateway {
  const NoStoreGateway();

  @override
  Stream<PurchaseEvent> get events => const Stream<PurchaseEvent>.empty();

  @override
  Future<String?> price() async => null;

  @override
  Future<PurchaseAnswer> buy() async => PurchaseAnswer.storeUnavailable;

  @override
  Future<RestoreAnswer> restore() async => RestoreAnswer.noAnswer;

  @override
  Future<void> dispose() async {}
}
