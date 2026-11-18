import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/key_value_store.dart';
import '../data/picks/pick_gate.dart';
import '../data/picks/pick_ledger.dart';
import 'plus_providers.dart';

/// Where today's picks and the "ever opened" list live. Overridden in `main`
/// with the opened Hive box; the memory default keeps tests and a broken disk
/// working.
final Provider<KeyValueStore> pickStoreProvider = Provider<KeyValueStore>(
  (ref) => MemoryKeyValueStore(),
);

/// The one gate every "open a game" passes through.
///
/// Plus is read at the moment of the question, not cached: a purchase made two
/// seconds ago must lift the limit on the next pick.
final Provider<PickGate> pickGateProvider = Provider<PickGate>(
  (ref) => PickGate(
    ledger: PickLedger(ref.watch(pickStoreProvider)),
    hasPlus: () => ref.read(plusProvider).ownsPlus,
  ),
);
