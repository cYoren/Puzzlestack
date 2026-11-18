import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../data/game_categories.dart';
import '../../../data/game_metadata.dart';
import '../../../data/game_profiles.dart';
import 'deal_order.dart';

/// The order the feed deals puzzles in.
///
/// Every pass deals each eligible puzzle once before reshuffling, ordered in
/// the `Think Word Think Snap` rhythm from [deal_order.dart] so adjacent cards
/// vary kind and family while keeping the "n / total" counter exact.
class FeedDeck {
  FeedDeck({
    this.categoryId,
    Set<String> hidden = const {},
    Random? random,
    DealHistory? history,
    this.includeFirstTen = false,
    this.pinnedFirstId,
    SeedHistoryStore? seedStore,
    DateTime Function()? now,
  })  : _random = random ?? Random(),
        _hidden = hidden,
        _history = history ?? const DealHistory(),
        _seedStore = seedStore,
        _now = now ?? DateTime.now {
    _pool = _buildPool();
    _refill(firstPass: true);
  }

  /// When set, the deck deals only from this category.
  final String? categoryId;

  /// When true and `history.cardsSeen == 0` with `categoryId == null`, the
  /// first pass leads with [firstTenIds].
  final bool includeFirstTen;

  /// Optional game pinned to slot 0 (`FeedScreen.startGameId`) so slots 1..N
  /// never collide with slot 0.
  final String? pinnedFirstId;

  final Random _random;
  final Set<String> _hidden;
  DealHistory _history;
  final SeedHistoryStore? _seedStore;
  final DateTime Function() _now;

  late List<GameMetadata> _pool;

  /// Cards left in the current pass, popped from the end.
  final List<GameMetadata> _bag = [];

  /// Dealt cards, by feed index.
  final Map<int, GameMetadata> _dealt = {};

  /// Per-card deterministic seeds keyed by `index:gameId` so revisiting a card
  /// or previewing upcoming cards deals the exact same board per slot, and new
  /// deals avoid 30-day repeats.
  final Map<String, int> _seeds = {};

  List<GameMetadata> _buildPool() {
    final Set<String> combinedHidden = <String>{
      ..._hidden,
      ..._history.blocked,
    };
    List<GameMetadata> source = GameFeed.feedPool(exclude: combinedHidden);
    if (!_history.supportsWordCards && categoryId != 'WORD') {
      final List<GameMetadata> nonWord = source
          .where((g) => cardKindOf(g.id) != CardKind.word)
          .toList(growable: false);
      if (nonWord.isNotEmpty) source = nonWord;
    }
    final List<GameMetadata> filtered = categoryId == null
        ? source
        : source.where((g) => g.category == categoryId).toList(growable: false);
    if (filtered.isNotEmpty) return filtered;

    // Hiding is a preference, not a way to empty the app.
    final List<GameMetadata> fallback = categoryId == null
        ? GameFeed.feedPool()
        : GameFeed.feedPool()
            .where((g) => g.category == categoryId)
            .toList(growable: false);
    return fallback.isEmpty ? GameFeed.feedPool() : fallback;
  }

  /// Updates history weights, locale eligibility, and blocked games.
  ///
  /// When the eligible language or blocked set changes, rebuilds `_pool`, drops
  /// any pre-dealt future slots above [keepThroughIndex], and refills `_bag` so
  /// disallowed cards (such as English Word cards on a non-English locale) never
  /// appear.
  void updateHistory(DealHistory next, {int keepThroughIndex = -1}) {
    final bool poolChanged =
        next.supportsWordCards != _history.supportsWordCards ||
            !setEquals(next.blocked, _history.blocked);
    _history = next;
    if (!poolChanged) return;

    _pool = _buildPool();
    _dealt.removeWhere((int idx, _) => idx > keepThroughIndex);
    _refill(firstPass: _dealt.isEmpty);
  }

  /// The size of one full pass, for the "n / total" counter.
  int get deckSize => _pool.length;

  /// The card at [index], dealing further cards lazily.
  GameMetadata gameAt(int index) {
    if (index < 0) return _pool.first;
    while (_dealt.length <= index) {
      _deal();
    }
    return _dealt[index]!;
  }

  /// Deterministic seed for the card at [index], avoiding 30-day repeats when a
  /// [SeedHistoryStore] is attached.
  int seedAt(int index, String gameId) {
    final int safeIndex = index < 0 ? 0 : index;
    final String key = '$safeIndex:$gameId';
    return _seeds.putIfAbsent(key, () {
      final SeedHistoryStore? store = _seedStore;
      if (store != null) {
        return store.nextSeed(
          gameId: gameId,
          today: _now(),
          random: _random,
        );
      }
      return _random.nextInt(0x7fffffff - 1) + 1;
    });
  }

  /// Drops the cached seed for [index] so an explicit replay in the Deal draws
  /// a fresh puzzle instance.
  void rerollSeed(int index, String gameId) {
    final int safeIndex = index < 0 ? 0 : index;
    _seeds.remove('$safeIndex:$gameId');
  }

  /// Where this card sits in its pass (1-based), for the "042 / 115" counter.
  int positionInDeck(int index) => index.abs() % deckSize + 1;

  void _refill({bool firstPass = false}) {
    final String? lastId =
        _dealt.isEmpty ? null : _dealt[_dealt.length - 1]?.id;
    final bool leadFirstTen = firstPass &&
        includeFirstTen &&
        pinnedFirstId == null &&
        categoryId == null &&
        _history.cardsSeen == 0;
    final List<String> leadingIds = leadFirstTen
        ? firstTenIds
        : (firstPass && pinnedFirstId != null
            ? <String>[pinnedFirstId!]
            : const <String>[]);
    final List<GameMetadata> ordered = orderPassByRhythm<GameMetadata>(
      pool: _pool,
      idOf: (g) => g.id,
      history: _history,
      random: _random,
      previousLastId: lastId,
      leadingIds: leadingIds,
    );
    // `_bag.removeLast()` deals from the end, so store reversed.
    _bag
      ..clear()
      ..addAll(ordered.reversed);
  }

  void _deal() {
    if (_bag.isEmpty) _refill();
    _dealt[_dealt.length] = _bag.removeLast();
  }
}
