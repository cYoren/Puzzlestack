import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/posthog.dart';
import 'plus_entitlement.dart';
import 'plus_gateway.dart';
import 'plus_store.dart';

/// What just happened, in the player's words rather than the store's.
///
/// One notice at a time, and [none] means "nothing to say", which is different
/// from every one of these.
enum PlusNotice {
  none,
  purchased,
  alreadyOwned,
  cancelled,
  pending,
  restored,
  nothingToRestore,
  revoked,
  unavailable,
  failed,
}

/// Everything a surface needs to draw Plus. Immutable, so a widget can compare
/// two of these and know whether to repaint.
@immutable
class PlusState {
  const PlusState({
    this.entitlement = const PlusEntitlement.free(),
    this.busy = false,
    this.notice = PlusNotice.none,
    this.price,
    this.storeReachable = true,
  });

  final PlusEntitlement entitlement;

  /// A store call is in flight. The buttons are off, not disabled-looking.
  final bool busy;

  final PlusNotice notice;

  /// The localised price the store quoted, or null when it could not be read.
  final String? price;

  /// False once the store has said it is not there (a desktop build). The sheet
  /// then says where Plus is sold instead of showing a button that cannot work.
  final bool storeReachable;

  bool get ownsPlus => entitlement.ownsPlus;

  PlusState copyWith({
    PlusEntitlement? entitlement,
    bool? busy,
    PlusNotice? notice,
    String? price,
    bool? storeReachable,
  }) =>
      PlusState(
        entitlement: entitlement ?? this.entitlement,
        busy: busy ?? this.busy,
        notice: notice ?? this.notice,
        price: price ?? this.price,
        storeReachable: storeReachable ?? this.storeReachable,
      );

  @override
  bool operator ==(Object other) =>
      other is PlusState &&
      other.entitlement == entitlement &&
      other.busy == busy &&
      other.notice == notice &&
      other.price == price &&
      other.storeReachable == storeReachable;

  @override
  int get hashCode =>
      Object.hash(entitlement, busy, notice, price, storeReachable);
}

/// Buys Plus, restores it, and takes it back when the store says it is gone.
///
/// The whole purchase story is this class: a paywall or a settings row asks for
/// an action and reads the state, and never decides for itself what an answer
/// from the store means. It has no widgets and no Riverpod in it, so every path
/// — bought, cancelled, restored, refunded — is tested without a store login.
class PlusController {
  PlusController({
    required PlusStore store,
    required PlusGateway Function() gateway,
    DateTime Function()? now,
  })  : _store = store,
        _gateway = gateway,
        _now = now ?? DateTime.now {
    _state = PlusState(entitlement: _store.read());
  }

  final PlusStore _store;
  final PlusGateway Function() _gateway;
  final DateTime Function() _now;

  PlusGateway? _storeConnection;
  StreamSubscription<PurchaseEvent>? _events;
  bool _inFlight = false;
  late PlusState _state;

  PlusState get state => _state;

  /// Called on every change, including one that arrives from the store while no
  /// screen asked for anything.
  void Function(PlusState state)? onChanged;

  void _set(PlusState next) {
    if (next == _state) return;
    _state = next;
    onChanged?.call(next);
  }

  /// Starts listening, and re-checks a purchase this device already has.
  ///
  /// Runs once, after the first frame, so it can never slow the first card down
  /// and can never put a store dialog in front of a player who just opened the
  /// app. The subscription comes first and happens whether or not this device
  /// owns Plus: a purchase that completed while the app was closed — an Ask to
  /// Buy approval, an interrupted payment, a promo code — is delivered on the
  /// store's stream without the player tapping anything, and this is the only
  /// place it is caught. It is kept for the app's lifetime and cancelled in
  /// [dispose].
  Future<void> start() async {
    _listen();
    if (_state.ownsPlus) {
      await verifyOnLaunch();
    }
    await ensurePrice();
  }

  void _listen() {
    if (_events != null) return;
    final PlusGateway gateway = _connection();
    _events = gateway.events.listen(
      (PurchaseEvent event) => unawaited(_onEvent(event)),
      onError: (Object error) {
        // The stream itself failed, not a purchase. Nothing changes: the local
        // row stands, and the next buy, restore or launch check retries.
        debugPrint('Purchase events error: $error');
      },
    );
  }

  /// One purchase update, as it arrives: no button started it, and none is
  /// needed. Every status is handled, the entitlement is written down, and
  /// whatever the store is waiting on is completed.
  Future<void> _onEvent(PurchaseEvent event) async {
    switch (event.status) {
      case PurchaseEventStatus.purchased:
      case PurchaseEventStatus.restored:
        await _grant(PlusNotice.purchased);
      case PurchaseEventStatus.pending:
        _tell(PlusNotice.pending);
      case PurchaseEventStatus.canceled:
        _tell(PlusNotice.cancelled);
      case PurchaseEventStatus.error:
        if (event.alreadyOwned) {
          await _grant(PlusNotice.alreadyOwned);
        } else {
          _tell(PlusNotice.failed);
        }
    }
    // Deliver first, then tell the store it can forget the purchase: an
    // uncompleted purchase is re-delivered on every launch, and a failed one
    // blocks the next. Completing is owed whenever the store is waiting,
    // whatever the outcome was.
    if (event.pendingComplete) {
      await _connection().completePurchase(event);
    }
  }

  PlusGateway _connection() => _storeConnection ??= _gateway();

  /// The store's price, read once while the store stays reachable.
  ///
  /// When a later buy hits a transient outage ([PlusState.storeReachable] false
  /// while [PlusState.price] is already cached), asking again re-probes the
  /// store so reopening the sheet brings the buttons back without a restart.
  Future<void> ensurePrice() async {
    if (_state.price != null && _state.storeReachable) return;
    final String? price = await _connection().price();
    if (price == null) {
      _set(_state.copyWith(storeReachable: false));
      return;
    }
    _set(_state.copyWith(price: price, storeReachable: true));
  }

  Future<PlusNotice> buy() async {
    if (_inFlight || _state.busy) return _state.notice;
    _inFlight = true;
    _set(_state.copyWith(busy: true, notice: PlusNotice.none));
    postHog.capture('purchase_started', <String, Object?>{'product': 'plus'});

    final PurchaseAnswer answer;
    try {
      answer = await _connection().buy();
    } finally {
      _inFlight = false;
    }

    switch (answer) {
      case PurchaseAnswer.purchased:
        return _grant(PlusNotice.purchased);
      case PurchaseAnswer.alreadyOwned:
        return _grant(PlusNotice.alreadyOwned);
      case PurchaseAnswer.cancelled:
        return _tell(PlusNotice.cancelled);
      case PurchaseAnswer.pending:
        return _tell(PlusNotice.pending);
      case PurchaseAnswer.storeUnavailable:
        _set(
          _state.copyWith(
            busy: false,
            notice: PlusNotice.unavailable,
            storeReachable: false,
          ),
        );
        return PlusNotice.unavailable;
      case PurchaseAnswer.failed:
        return _tell(PlusNotice.failed);
    }
  }

  /// Asks the store what this account owns, and follows the answer.
  ///
  /// The player presses this when they changed phone or reinstalled; the launch
  /// check uses the same path, which is why a refund behaves the same however
  /// it comes in.
  Future<PlusNotice> restore() async {
    if (_inFlight || _state.busy) return _state.notice;
    _inFlight = true;
    _set(_state.copyWith(busy: true, notice: PlusNotice.none));

    final RestoreAnswer answer;
    try {
      answer = await _connection().restore();
    } finally {
      _inFlight = false;
    }

    switch (answer) {
      case RestoreAnswer.owned:
        return _grant(PlusNotice.restored);
      case RestoreAnswer.nothingOwned:
        // A definitive answer that lists nothing. If this device thought it
        // owned Plus, the purchase has been refunded or revoked, and Plus goes
        // with it. If it did not, there was simply nothing to restore.
        if (!_state.ownsPlus) return _tell(PlusNotice.nothingToRestore);
        await _revoke();
        return PlusNotice.revoked;
      case RestoreAnswer.noAnswer:
        // The store could not be reached, or did not answer in time. Keeping
        // Plus is the only safe reading: a failed request is not a refund. The
        // player is told it failed, and a retry can still resolve it.
        return _tell(PlusNotice.failed);
    }
  }

  /// The launch check. Silent unless something changed, because a purchase
  /// re-checked every morning is not news.
  Future<PlusNotice> verifyOnLaunch() async {
    if (!_state.ownsPlus) return PlusNotice.none;
    final RestoreAnswer answer = await _connection().restore();
    switch (answer) {
      case RestoreAnswer.owned:
        final PlusEntitlement confirmed = _state.entitlement.verifiedAtTime(
          _now(),
        );
        _state = _state.copyWith(entitlement: confirmed);
        await _store.write(confirmed);
        notify();
        return PlusNotice.none;
      case RestoreAnswer.nothingOwned:
        await _revoke();
        return PlusNotice.revoked;
      case RestoreAnswer.noAnswer:
        return PlusNotice.none;
    }
  }

  Future<PlusNotice> _grant(PlusNotice notice) async {
    final PlusEntitlement entitlement = PlusEntitlement.owned(
      since: _state.entitlement.since ?? _now(),
      verifiedAt: _now(),
    );
    await _store.write(entitlement);
    _trackNotice(notice);
    _state = _state.copyWith(
      entitlement: entitlement,
      busy: _inFlight,
      notice: notice,
      storeReachable: true,
    );
    notify();
    return notice;
  }

  Future<void> _revoke() async {
    await _store.clear();
    _state = _state.copyWith(
      entitlement: const PlusEntitlement.free(),
      busy: _inFlight,
      notice: PlusNotice.revoked,
      storeReachable: true,
    );
    notify();
  }

  PlusNotice _tell(PlusNotice notice) {
    _trackNotice(notice);
    // A pending stream update arrives while `buy()` is still waiting on the
    // store; keeping `busy` tied to `_inFlight` shows the pending notice
    // without unlocking the buttons for an overlapping store call.
    _set(_state.copyWith(busy: _inFlight, notice: notice));
    return notice;
  }

  /// The purchase funnel in one place: every outcome the sheet can show passes
  /// through [_tell] or [_grant], so no store path is missed.
  void _trackNotice(PlusNotice notice) {
    switch (notice) {
      case PlusNotice.purchased:
      case PlusNotice.alreadyOwned:
        postHog.capture('purchase_completed', <String, Object?>{
          'product': 'plus',
          'result': notice.name,
        });
      case PlusNotice.restored:
        postHog.capture('purchase_restored', <String, Object?>{
          'product': 'plus',
        });
      case PlusNotice.failed:
      case PlusNotice.unavailable:
      case PlusNotice.cancelled:
        postHog.capture('purchase_failed', <String, Object?>{
          'product': 'plus',
          'result': notice.name,
        });
      case PlusNotice.none:
      case PlusNotice.pending:
      case PlusNotice.nothingToRestore:
      case PlusNotice.revoked:
        break;
    }
  }

  void notify() => onChanged?.call(_state);

  /// Forgets what the sheet said last time it was open. Opening the sheet must
  /// not replay a cancel from an hour ago.
  void clearNotice() {
    if (_state.notice == PlusNotice.none) return;
    _set(_state.copyWith(notice: PlusNotice.none));
  }

  Future<void> dispose() async {
    await _events?.cancel();
    _events = null;
    final PlusGateway? gateway = _storeConnection;
    _storeConnection = null;
    await gateway?.dispose();
  }
}
