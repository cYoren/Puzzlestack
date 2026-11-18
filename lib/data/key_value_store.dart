import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Where a small store keeps its rows.
///
/// Three stores need one row each: the Plus entitlement, today's picks, and the
/// size tier remembered per game. Hive is the app's storage and a test needs a
/// map, so this interface is the whole seam between them: a store is written
/// once, tested without a device, and never learns about Hive.
abstract class KeyValueStore {
  /// The row stored under [key], or null when there is none. Synchronous on
  /// purpose: these rows are read while a screen is building, so they are
  /// hydrated by [HiveKeyValueStore.open] before the first frame.
  Object? read(String key);

  Future<void> write(String key, Object? value);

  Future<void> delete(String key);
}

/// A store in memory only. The default in tests, and the fallback when storage
/// could not be opened: the app still works, it just cannot remember.
class MemoryKeyValueStore implements KeyValueStore {
  MemoryKeyValueStore([Map<String, Object?>? seed]) : _rows = {...?seed};

  final Map<String, Object?> _rows;

  @override
  Object? read(String key) => _rows[key];

  @override
  Future<void> write(String key, Object? value) async => _rows[key] = value;

  @override
  Future<void> delete(String key) async => _rows.remove(key);
}

/// A Hive box as a [KeyValueStore].
///
/// A write that fails is logged and dropped: a full disk must never take the
/// screen down, and the next successful write puts the row back.
class HiveKeyValueStore implements KeyValueStore {
  HiveKeyValueStore(this._box);

  final Box<dynamic> _box;

  /// Opens [name], or returns null when storage is unavailable. A box that
  /// cannot be opened is not an error the player should ever see: the store
  /// behind it falls back to memory.
  static Future<HiveKeyValueStore?> open(String name) async {
    try {
      return HiveKeyValueStore(await Hive.openBox<dynamic>(name));
    } catch (error) {
      debugPrint('Hive could not open "$name": $error');
      return null;
    }
  }

  @override
  Object? read(String key) {
    try {
      return _box.get(key);
    } catch (error) {
      debugPrint('Hive could not read "$key": $error');
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? value) async {
    try {
      await _box.put(key, value);
    } catch (error) {
      debugPrint('Hive could not write "$key": $error');
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _box.delete(key);
    } catch (error) {
      debugPrint('Hive could not delete "$key": $error');
    }
  }
}
