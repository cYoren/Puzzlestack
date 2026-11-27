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
/// [noAnswer] is deliberately **not** [nothingOwned]. A request that failed,
/// a store that never answered, or a receipt that did not arrive in time must
/// never take Plus away from someone who paid; only an explicit answer that
/// lists nothing may revoke.
enum RestoreAnswer { owned, nothingOwned, noAnswer }

/// What one update on the purchase stream is, in the app's words.
enum PurchaseEventStatus { purchased, restored, pending, canceled, error }

/// A purchase the store reported, whether or not anything asked for one.
///
/// This is the whole contract of a purchase update: what happened, whether the
/// store is waiting to be told the purchase was delivered ([pendingComplete]),
/// and — for an error — whether the error was the account saying it already
/// owns this ([alreadyOwned]), which is not a failure at all.
@immutable
class PurchaseEvent {
  const PurchaseEvent({
    required this.status,
    this.pendingComplete = false,
    this.alreadyOwned = false,
  });

  const PurchaseEvent.purchased({bool pendingComplete = false})
      : this(
          status: PurchaseEventStatus.purchased,
          pendingComplete: pendingComplete,
        );

  const PurchaseEvent.restored({bool pendingComplete = false})
      : this(
          status: PurchaseEventStatus.restored,
          pendingComplete: pendingComplete,
        );

  const PurchaseEvent.pending() : this(status: PurchaseEventStatus.pending);

  const PurchaseEvent.canceled() : this(status: PurchaseEventStatus.canceled);

  const PurchaseEvent.error({
    bool pendingComplete = false,
    bool alreadyOwned = false,
  }) : this(
          status: PurchaseEventStatus.error,
          pendingComplete: pendingComplete,
          alreadyOwned: alreadyOwned,
        );

  /// What the store said about this purchase. Every status is handled, so no
  /// update is ever swallowed.
  final PurchaseEventStatus status;

  /// The store cannot forget this purchase until the app says it was delivered.
  /// False when there is nothing to complete (a pending or cancelled update).
  final bool pendingComplete;

  /// Only meaningful with [PurchaseEventStatus.error]: the store's answer was
  /// "this account already owns it", which grants rather than fails.
  final bool alreadyOwned;
}

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

  /// Purchases as they arrive, while the app is running. Subscribed once at
  /// start, and kept for the app's lifetime: a purchase can complete without
  /// anything asking for one (an Ask to Buy approval, an interrupted payment,
  /// a promo code redeemed on another device).
  Stream<PurchaseEvent> get events;

  /// Tells the store the purchase behind [event] was delivered, so it can
  /// forget the transaction. Called whenever the event said the store was
  /// waiting ([PurchaseEvent.pendingComplete]); an uncompleted purchase is
  /// re-sent on every launch and blocks the next one.
  Future<void> completePurchase(PurchaseEvent event);

  Future<void> dispose();
}

/// Some platforms have no store plugin. Keeping that fact behind the
/// same interface lets the app launch and lets a desktop test build render the
/// Plus surfaces without touching an uninitialised platform channel.
class UnavailablePlusGateway implements PlusGateway {
  @override
  Stream<PurchaseEvent> get events => const Stream<PurchaseEvent>.empty();

  @override
  Future<PurchaseAnswer> buy() async => PurchaseAnswer.storeUnavailable;

  @override
  Future<void> completePurchase(PurchaseEvent event) async {}

  @override
  Future<String?> price() async => null;

  @override
  Future<RestoreAnswer> restore() async => RestoreAnswer.noAnswer;

  @override
  Future<void> dispose() async {}
}

/// The real store: `in_app_purchase`, one non-consumable.
///
/// The purchase stream is subscribed in the constructor and kept until
/// [dispose], because the store delivers purchases that completed outside the
/// app — an Ask to Buy approved after a restart, an interrupted payment, a
/// promo code — on that stream, and only on it. Every purchase the app has
/// delivered is completed through [completePurchase], bought or restored, so
/// the store never replays a purchase the player already has. Nothing leaves
/// the device: the receipt is not sent anywhere, because there is no server to
/// send it to and no DRM to enforce.
class InAppPurchaseGateway implements PlusGateway {
  InAppPurchaseGateway({
    InAppPurchase? purchases,
    Duration restoreSettle = const Duration(seconds: 2),
  })  : _iap = purchases ?? InAppPurchase.instance,
        _restoreSettle = restoreSettle {
    _attach();
  }

  final InAppPurchase _iap;

  /// How long a restore waits for the store to hand back a receipt after the
  /// restore call itself has returned. A receipt that does not arrive in time
  /// is not proof of owning nothing; it is no answer, and a retry can still
  /// deliver it.
  final Duration _restoreSettle;

  final StreamController<PurchaseEvent> _events =
      StreamController<PurchaseEvent>.broadcast();

  /// Events the store is waiting on a [completePurchase] for, keyed by the
  /// event the app received. Only the event's own instance can complete it.
  final Map<PurchaseEvent, PurchaseDetails> _undelivered =
      <PurchaseEvent, PurchaseDetails>{};

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Completer<PurchaseAnswer>? _buy;
  Completer<RestoreAnswer>? _restored;
  ProductDetails? _product;
  Future<ProductDetails?>? _looking;

  @override
  Stream<PurchaseEvent> get events => _events.stream;

  /// How long a buy may stay open before it is reported as pending. The store
  /// can take minutes when a bank asks for a step; the app does not block on it.
  static const Duration _buyWindow = Duration(minutes: 5);

  /// Subscribes to the store's purchase stream, once, for the app's lifetime.
  void _attach() {
    _subscription ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) {
        // The stream itself failed, not a purchase. A buy that was open reads
        // as failed; a restore that was open reads as unanswered, which is the
        // one answer that cannot take Plus away.
        debugPrint('Purchase stream error: $error');
        _settleBuy(PurchaseAnswer.failed);
        _settleRestore(RestoreAnswer.noAnswer);
      },
    );
  }

  void _emit(PurchaseEvent event, PurchaseDetails purchase) {
    if (event.pendingComplete) _undelivered[event] = purchase;
    _events.add(event);
  }

  /// Answers the buy that is open, if one is. The app allows one store call at
  /// a time, so at most one of these is ever waiting.
  void _settleBuy(PurchaseAnswer answer) {
    final Completer<PurchaseAnswer>? buy = _buy;
    _buy = null;
    if (buy != null && !buy.isCompleted) buy.complete(answer);
  }

  /// Answers the restore that is open, if one is.
  void _settleRestore(RestoreAnswer answer) {
    final Completer<RestoreAnswer>? restored = _restored;
    _restored = null;
    if (restored != null && !restored.isCompleted) restored.complete(answer);
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    if (purchases.isEmpty) {
      // The end of a restore that found nothing, told by each store in its own
      // way: StoreKit 1 emits an empty list when the restore session finishes
      // without a transaction, StoreKit 2 sends the entitlements it found (an
      // empty list when there are none), and Google Play always reports the
      // result of the ownership query it ran. An empty list here is therefore
      // the store's own answer, not silence and not an error, so it is the one
      // thing allowed to say the account owns nothing.
      _settleRestore(RestoreAnswer.nothingOwned);
      return;
    }

    for (final PurchaseDetails purchase in purchases) {
      // An empty id is an error that belongs to no product; it can still be a
      // failure of this one, so it is read rather than skipped.
      final String id = purchase.productID;
      if (id.isNotEmpty && id != plusProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Report it first; the app delivers it, then completes it through
          // [completePurchase] once the entitlement is written down.
          _emit(
            PurchaseEvent(
              status: purchase.status == PurchaseStatus.purchased
                  ? PurchaseEventStatus.purchased
                  : PurchaseEventStatus.restored,
              pendingComplete: purchase.pendingCompletePurchase,
            ),
            purchase,
          );
          _settleRestore(RestoreAnswer.owned);
          _settleBuy(PurchaseAnswer.purchased);
        case PurchaseStatus.canceled:
          _emit(const PurchaseEvent.canceled(), purchase);
          _settleBuy(PurchaseAnswer.cancelled);
        case PurchaseStatus.pending:
          // The store is still processing; there is nothing to complete yet.
          _emit(const PurchaseEvent.pending(), purchase);
        case PurchaseStatus.error:
          final bool alreadyOwned = _errorSaysAlreadyOwned(purchase.error);
          _emit(
            PurchaseEvent.error(
              pendingComplete: purchase.pendingCompletePurchase,
              alreadyOwned: alreadyOwned,
            ),
            purchase,
          );
          _settleBuy(
            alreadyOwned ? PurchaseAnswer.alreadyOwned : PurchaseAnswer.failed,
          );
      }
    }
  }

  /// A store error, read once. "You already own this" is not a failure to
  /// charge twice, it is the account telling us the local row was missing.
  bool _errorSaysAlreadyOwned(IAPError? error) {
    final String code = error?.code ?? '';
    final String message = (error?.message ?? '').toLowerCase();
    return code.contains('alreadyOwned') ||
        code.contains('itemAlreadyOwned') ||
        message.contains('already own');
  }

  /// Tells the store this purchase is delivered and it can forget the
  /// transaction. Nothing happens for an event the store was not waiting on.
  @override
  Future<void> completePurchase(PurchaseEvent event) async {
    final PurchaseDetails? purchase = _undelivered.remove(event);
    if (purchase == null) return;
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

  /// The product, asked for until the store answers.
  ///
  /// A lookup that failed is not a fact about the product, so it is not
  /// remembered as one: a store that was unreachable when the app started is
  /// asked again the next time a price or a buy is needed, and buying Plus
  /// never needs the app restarted. Only an answer is kept.
  Future<ProductDetails?> _details() {
    final ProductDetails? known = _product;
    if (known != null) return Future<ProductDetails?>.value(known);

    // One lookup in flight at a time: a sheet and a buy can ask at once, and
    // the store should be asked once.
    final Future<ProductDetails?>? running = _looking;
    if (running != null) return running;

    final Future<ProductDetails?> lookup = _lookup();
    _looking = lookup;
    return lookup.whenComplete(() {
      if (identical(_looking, lookup)) _looking = null;
    });
  }

  Future<ProductDetails?> _lookup() async {
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
    final Completer<PurchaseAnswer>? active = _buy;
    if (active != null && !active.isCompleted) return active.future;

    if (!await _available()) return PurchaseAnswer.storeUnavailable;
    final ProductDetails? details = await _details();
    if (details == null) return PurchaseAnswer.storeUnavailable;

    final Completer<PurchaseAnswer>? startedElsewhere = _buy;
    if (startedElsewhere != null && !startedElsewhere.isCompleted) {
      return startedElsewhere.future;
    }

    final Completer<PurchaseAnswer> answer = Completer<PurchaseAnswer>();
    _buy = answer;

    bool started;
    try {
      started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
    } catch (error) {
      debugPrint('buyNonConsumable failed: $error');
      if (identical(_buy, answer)) _buy = null;
      return PurchaseAnswer.failed;
    }
    if (!started) {
      if (identical(_buy, answer)) _buy = null;
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
    final Completer<RestoreAnswer>? active = _restored;
    if (active != null && !active.isCompleted) return active.future;
    final Completer<PurchaseAnswer>? buying = _buy;
    if (buying != null && !buying.isCompleted) return RestoreAnswer.noAnswer;

    if (!await _available()) return RestoreAnswer.noAnswer;

    final Completer<RestoreAnswer>? startedElsewhere = _restored;
    if (startedElsewhere != null && !startedElsewhere.isCompleted) {
      return startedElsewhere.future;
    }

    final Completer<RestoreAnswer> settled = Completer<RestoreAnswer>();
    _restored = settled;

    try {
      await _iap.restorePurchases();
    } catch (error) {
      // The store did not answer. This is the one case that must not revoke.
      debugPrint('restorePurchases failed: $error');
      _settleRestore(RestoreAnswer.noAnswer);
      return RestoreAnswer.noAnswer;
    }

    try {
      return await settled.future.timeout(_restoreSettle);
    } on TimeoutException {
      // A restore that finished answers either with a receipt or with the
      // store's empty list, both of which settle this above; reaching the
      // timeout means the store never finished at all. Silence is not the
      // account owning nothing: the device keeps what it has, the player is
      // told the store could not be reached, and a retry can still deliver the
      // receipt.
      return RestoreAnswer.noAnswer;
    } finally {
      if (identical(_restored, settled)) _restored = null;
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _buy = null;
    _restored = null;
    _looking = null;
    _undelivered.clear();
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
  Future<void> completePurchase(PurchaseEvent event) async {}

  @override
  Future<String?> price() async => null;

  @override
  Future<PurchaseAnswer> buy() async => PurchaseAnswer.storeUnavailable;

  @override
  Future<RestoreAnswer> restore() async => RestoreAnswer.noAnswer;

  @override
  Future<void> dispose() async {}
}
