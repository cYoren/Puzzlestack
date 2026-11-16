import '../key_value_store.dart';
import 'plus_entitlement.dart';

/// The Plus row, in storage.
///
/// One row, one key. Nothing else in the app writes it: the controller is the
/// only writer, so "does this device own Plus" can never have two answers.
class PlusStore {
  PlusStore(this._store);

  static const String boxName = 'plus';
  static const String rowKey = 'entitlement';

  final KeyValueStore _store;

  PlusEntitlement read() => PlusEntitlement.fromJson(_store.read(rowKey));

  Future<void> write(PlusEntitlement entitlement) =>
      _store.write(rowKey, entitlement.toJson());

  Future<void> clear() => _store.delete(rowKey);
}
