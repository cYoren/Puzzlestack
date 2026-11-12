import 'dart:math';

import '../../../data/game_categories.dart';
import '../../../data/game_metadata.dart';
import '../../../data/game_registry.dart';

/// The order the feed deals puzzles in.
///
/// A feed is not a random number generator. Drawing `random()` on every page
/// means the same puzzle can come back three cards later while 300 never
/// appear, and it means the counter on screen is a lie. Instead the feed deals
/// a real shuffled deck: every puzzle in the pool once, then it reshuffles and
/// deals again. Infinite, because the deck refills; never repetitive inside a
/// deck, because nothing repeats until the bag is empty.
///
/// Pages are built lazily by index, so the deck grows only as far as the player
/// actually scrolls. Hidden games are dropped before the first shuffle, and a
/// pool that filters down to nothing falls back to the whole registry rather
/// than handing back a blank card.
class FeedDeck {
  FeedDeck({
    this.categoryId,
    Set<String> hidden = const {},
    Random? random,
  })  : _random = random ?? Random(),
        _hidden = hidden {
    _pool = _buildPool();
    _refill();
  }

  /// When set, the deck deals only from this category.
  final String? categoryId;

  final Random _random;
  final Set<String> _hidden;

  late final List<GameMetadata> _pool;

  /// The cards left in the current pass through the deck, drawn from the end.
  final List<GameMetadata> _bag = [];

  /// Dealt cards, by feed index. Grows only when the player scrolls.
  final Map<int, GameMetadata> _dealt = {};

  List<GameMetadata> _buildPool() {
    final List<GameMetadata> source = categoryId == null
        ? allGamesMetadata
        : GameCategories.inCategory(categoryId!).toList(growable: false);
    final List<GameMetadata> filtered =
        source.where((g) => !_hidden.contains(g.id)).toList(growable: false);
    // Hiding is a preference, not a way to empty the app.
    return filtered.isEmpty ? allGamesMetadata : filtered;
  }

  /// The size of one full pass, for the "n / total" counter.
  int get deckSize => _pool.length;

  /// The card at [index], dealing further cards when the feed asks for a page
  /// it has not reached yet.
  GameMetadata gameAt(int index) {
    if (index < 0) return _pool.first;
    while (_dealt.length <= index) {
      _deal();
    }
    return _dealt[index]!;
  }

  /// Where this card sits in its pass (1-based), for the "042 / 313" counter.
  ///
  /// Every pass deals exactly [deckSize] cards, so the position is the index
  /// modulo the deck: the counter restarts with each new deal instead of
  /// climbing to 314, which is the honest version of "infinite".
  int positionInDeck(int index) => index.abs() % deckSize + 1;

  void _refill() {
    _bag
      ..clear()
      ..addAll(_pool);
    _shuffleAwayFromLast();
  }

  /// Keeps the seam between two passes invisible: the first card of a fresh
  /// bag must not be the card that was just on screen.
  void _shuffleAwayFromLast() {
    _bag.shuffle(_random);
    final GameMetadata? last =
        _dealt.isEmpty ? null : _dealt[_dealt.length - 1];
    if (_bag.length > 1 && last != null && _bag.last.id == last.id) {
      final GameMetadata swap = _bag.first;
      _bag[0] = _bag.last;
      _bag[_bag.length - 1] = swap;
    }
  }

  void _deal() {
    if (_bag.isEmpty) _refill();
    _dealt[_dealt.length] = _bag.removeLast();
  }
}
