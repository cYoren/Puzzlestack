import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_tiers.dart';
import '../data/key_value_store.dart';

/// Where the remembered tier lives. Overridden in `main` with the stats box,
/// which is opened before the first frame; the memory default keeps widget
/// tests and a device whose storage will not open working.
final Provider<GameTierStore> gameTierStoreProvider = Provider<GameTierStore>(
  (ref) => GameTierStore(MemoryKeyValueStore()),
);

/// Bumped when a size is chosen for a board that is about to open.
///
/// The remembered row in [gameTierStoreProvider] is what every later launch
/// reads, and a stored row cannot tell a live board that it changed. A board's
/// provider is built once, and the Deal keeps the current card mounted behind
/// its tabs, so a game opened from the Stack can find its provider already
/// alive with the board built at the old size. Watching this counter is how
/// that board hears about the choice: [GameTierRef.startTier] reads the row on
/// every build, so one bump rebuilds the boards at the size just chosen.
///
/// Only a launch bumps it. A player changing the size inside a game is already
/// building the new board in `setDifficulty`; bumping there as well would deal
/// the puzzle a second time under them.
final StateProvider<int> tierRevisionProvider = StateProvider<int>((ref) => 0);

/// The tier [gameId] should open at, read once from storage.
///
/// [tiers] is the game's own enum values and [key] reads the stored id from one
/// (`.name` for the ports, `.label` for `kurodoko`, whose three tiers are static
/// constants rather than an enum). [fallback] is used only when nothing stored
/// matches, which on a fresh install is the ladder default.
T _startTier<T>(
  GameTierStore store,
  String gameId,
  List<T> tiers,
  T fallback,
  String Function(T tier) key,
) {
  final String? wanted = store.startFor(gameId);
  if (wanted != null) {
    for (final T tier in tiers) {
      if (key(tier) == wanted) return tier;
    }
  }
  return fallback;
}

/// How a game learns and remembers its size.
///
/// Two calls, one mechanism, no per-game copies: `startTier(...)` in `build` and
/// `rememberTier(...)` when the player changes it. A game that is not in
/// [gameLadders] reads its own default and never writes a row.
///
/// Riverpod's ref types do not share one base class, so the same two methods are
/// exposed on the three shapes the app uses (`Ref` in a provider body,
/// `AutoDisposeNotifierProviderRef` in a `@riverpod` notifier, `WidgetRef` in a
/// screen). Each one is a two-line delegation; the decision lives above.
extension GameTierRef on Ref {
  /// The tier this board should open at.
  T startTier<T>(
    String gameId,
    List<T> tiers,
    T fallback,
    String Function(T tier) key,
  ) {
    watch(tierRevisionProvider);
    return _startTier(read(gameTierStoreProvider), gameId, tiers, fallback, key);
  }

  /// Remembers the tier the player just chose, for every later launch.
  ///
  /// Deliberately not awaited at the call sites: the board appears either way,
  /// and a failed write costs one remembered choice, not the game.
  Future<void> rememberTier(String gameId, String tierId) =>
      read(gameTierStoreProvider).remember(gameId, tierId);
}

/// The same two calls inside a `@riverpod` notifier, whose `ref` is not a [Ref].
///
/// Riverpod 2.6 types that field as `AutoDisposeNotifierProviderRef`, which is
/// deprecated in favour of `Ref` only from 3.0; this package is on 2.6.1, so the
/// ignore is the version, not a shortcut.
// ignore: deprecated_member_use
extension GameTierNotifierRef on AutoDisposeNotifierProviderRef<dynamic> {
  /// The tier this board should open at.
  T startTier<T>(
    String gameId,
    List<T> tiers,
    T fallback,
    String Function(T tier) key,
  ) {
    watch(tierRevisionProvider);
    return _startTier(read(gameTierStoreProvider), gameId, tiers, fallback, key);
  }

  /// Remembers the tier the player just chose, for every later launch.
  Future<void> rememberTier(String gameId, String tierId) =>
      read(gameTierStoreProvider).remember(gameId, tierId);
}

/// The same two calls from a screen, where `ref` is a [WidgetRef].
extension GameTierWidgetRef on WidgetRef {
  /// The tier this board should open at.
  T startTier<T>(
    String gameId,
    List<T> tiers,
    T fallback,
    String Function(T tier) key,
  ) {
    watch(tierRevisionProvider);
    return _startTier(read(gameTierStoreProvider), gameId, tiers, fallback, key);
  }

  /// Remembers the tier the player just chose, for every later launch.
  Future<void> rememberTier(String gameId, String tierId) =>
      read(gameTierStoreProvider).remember(gameId, tierId);
}
