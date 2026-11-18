import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_tiers.dart';
import '../data/key_value_store.dart';
import '../data/repositories/game_stats_repository.dart';
import '../ui/features/feed/feed_session.dart';
import 'game_stats_provider.dart';

/// Where the remembered tier lives. Overridden in `main` with the stats box,
/// which is opened before the first frame; the memory default keeps widget
/// tests and a device whose storage will not open working.
final Provider<GameTierStore> gameTierStoreProvider = Provider<GameTierStore>(
  (ref) => GameTierStore(MemoryKeyValueStore()),
);

/// Target solve time (120 seconds) under which two solves step a game up one
/// feed tier (`docs/FEED.md`).
const int feedStepUpTargetMs = 120 * 1000;

/// Bumped for one game when a size is chosen for a board that is about to open.
final StateProviderFamily<int, String> tierRevisionProvider =
    StateProvider.family<int, String>((ref, gameId) => 0);

/// The tier [gameId] should open at.
///
/// Inside the feed (`FeedSession.inFeed`), a game opens at its easiest feed
/// tier (`tiers.first`) and steps up one rung after two timed solves at or
/// under [feedStepUpTargetMs] (unless `fixedFeedSize` is set for Daily Five).
/// Outside the feed, it opens at the player's remembered Stack tier.
T _startTier<T>(
  GameTierStore store,
  GameStat stat,
  String gameId,
  List<T> tiers,
  T fallback,
  String Function(T tier) key,
) {
  final FeedSession? feed = FeedSession.current;
  if (feed != null && tiers.isNotEmpty) {
    if (feed.fixedFeedSize) return tiers.first;
    final int fastSolves =
        stat.times.where((int ms) => ms > 0 && ms <= feedStepUpTargetMs).length;
    if (fastSolves >= 2 && tiers.length > 1) {
      return tiers[math.min(1, tiers.length - 1)];
    }
    return tiers.first;
  }

  final String? wanted = store.startFor(gameId);
  if (wanted != null) {
    for (final T tier in tiers) {
      if (key(tier) == wanted) return tier;
    }
  }
  return fallback;
}

extension GameTierRef on Ref {
  T startTier<T>(
    String gameId,
    List<T> tiers,
    T fallback,
    String Function(T tier) key,
  ) {
    watch(tierRevisionProvider(gameId));
    final GameStat stat = read(gameStatsProvider)[gameId] ??
        GameStatsRepository.instance.statFor(gameId);
    return _startTier(
      read(gameTierStoreProvider),
      stat,
      gameId,
      tiers,
      fallback,
      key,
    );
  }

  Future<void> rememberTier(String gameId, String tierId) =>
      read(gameTierStoreProvider).remember(gameId, tierId);
}

// ignore: deprecated_member_use
extension GameTierNotifierRef on AutoDisposeNotifierProviderRef<dynamic> {
  T startTier<T>(
    String gameId,
    List<T> tiers,
    T fallback,
    String Function(T tier) key,
  ) {
    watch(tierRevisionProvider(gameId));
    final GameStat stat = read(gameStatsProvider)[gameId] ??
        GameStatsRepository.instance.statFor(gameId);
    return _startTier(
      read(gameTierStoreProvider),
      stat,
      gameId,
      tiers,
      fallback,
      key,
    );
  }

  Future<void> rememberTier(String gameId, String tierId) =>
      read(gameTierStoreProvider).remember(gameId, tierId);
}

extension GameTierWidgetRef on WidgetRef {
  T startTier<T>(
    String gameId,
    List<T> tiers,
    T fallback,
    String Function(T tier) key,
  ) {
    watch(tierRevisionProvider(gameId));
    final GameStat stat = read(gameStatsProvider)[gameId] ??
        GameStatsRepository.instance.statFor(gameId);
    return _startTier(
      read(gameTierStoreProvider),
      stat,
      gameId,
      tiers,
      fallback,
      key,
    );
  }

  Future<void> rememberTier(String gameId, String tierId) =>
      read(gameTierStoreProvider).remember(gameId, tierId);
}
