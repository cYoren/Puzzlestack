import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/key_value_store.dart';
import '../data/purchase/plus_controller.dart';
import '../data/purchase/plus_gateway.dart';
import '../data/purchase/plus_store.dart';

/// Where the Plus row lives. Overridden in `main` with the opened Hive box; the
/// memory default keeps widget tests and a broken disk working.
final Provider<KeyValueStore> plusStoreProvider = Provider<KeyValueStore>(
  (ref) => MemoryKeyValueStore(),
);

/// Selects the store SDK only on platforms where the plugin is registered.
final Provider<PlusGateway Function()> plusGatewayProvider =
    Provider<PlusGateway Function()>((ref) {
      final bool storeSupported =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS);
      return storeSupported
          ? InAppPurchaseGateway.new
          : UnavailablePlusGateway.new;
    });

/// The app's only source of truth for "is Plus owned".
///
/// Every surface reads `ownsPlus` from here; nothing keeps its own copy, which
/// is what makes a revoked purchase revoke the feature the next time the app
/// asks.
class PlusNotifier extends Notifier<PlusState> {
  late final PlusController _controller;
  bool _disposed = false;

  @override
  PlusState build() {
    _controller = PlusController(
      store: PlusStore(ref.watch(plusStoreProvider)),
      gateway: ref.watch(plusGatewayProvider),
    );
    _controller.onChanged = (PlusState next) {
      if (_disposed) return;
      state = next;
    };
    ref.onDispose(() {
      _disposed = true;
      _controller.dispose();
    });
    return _controller.state;
  }

  /// Re-checks a purchase the device already has, and picks up a purchase that
  /// arrived while the app was closed. Called once, after the first frame.
  Future<void> start() => _controller.start();

  Future<PlusNotice> buy() => _controller.buy();

  Future<PlusNotice> restore() => _controller.restore();

  Future<PlusNotice> verifyOnLaunch() => _controller.verifyOnLaunch();

  Future<void> ensurePrice() => _controller.ensurePrice();

  void clearNotice() => _controller.clearNotice();
}

final NotifierProvider<PlusNotifier, PlusState> plusProvider =
    NotifierProvider<PlusNotifier, PlusState>(PlusNotifier.new);

/// Does this player have Plus? One line, one answer, read from the one row.
bool isPlus(Ref ref) => ref.watch(plusProvider).ownsPlus;
