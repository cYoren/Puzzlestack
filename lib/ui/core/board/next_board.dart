import 'package:flutter/scheduler.dart';

/// One board made ahead of the one a player is looking at.
///
/// Generating a puzzle is the one thing in a game that can cost more than a
/// frame: Salad's 7x7 takes about 270ms and Signpost's hardest tier about
/// 230ms, and a game that calls its generator inside a tap makes the player pay
/// for it with a frozen screen, which is the opposite of the feel the boards are
/// going for.
///
/// So a board is made *after* the current one has been painted: the tap that
/// asks for the next board finds it already built, and the cost lands in the
/// gap a player spends looking at a fresh puzzle rather than between their
/// finger and the board.
///
/// Signpost does not use this yet. Its generator is budgeted (900ms) rather than
/// fixed, so a warm-up would move the same search onto the frame after a new
/// board appears; it wants its generation off the frame, in an isolate, before a
/// cache here would buy anything.
///
/// This runs on the main isolate on purpose. Moving generation to an isolate
/// would hide the cost completely, but it also moves the rules one step away
/// from the state they belong to, and a puzzle that takes 3ms (Mathrax) has
/// nothing to hide. The cache is about *where* the cost lands, not about
/// parallelism.
class NextBoard<K, V> {
  NextBoard(this._build);

  final V Function(K key) _build;

  final Map<K, V> _ready = {};
  final List<K> _queue = [];
  bool _closed = false;
  bool _scheduled = false;
  int _built = 0;

  /// How many boards this cache has built, warm-ups included.
  ///
  /// A tap that finds its board ready does not move this number, which is the
  /// promise of the class: generation never sits between the player and the
  /// board. It is also what a test can watch.
  int get built => _built;

  /// The board for [key]: the one made ahead when it is there, a fresh one when
  /// it is not.
  V take(K key) {
    final ready = _ready.remove(key);
    if (ready != null) return ready;
    _built++;
    return _build(key);
  }

  /// Builds a board for each of [keys] that has none, [first] (when given)
  /// before the rest.
  ///
  /// Called right after a board is set, so the frame that has to be painted is
  /// the one carrying the board the player just asked for.
  void fill(Iterable<K> keys, {K? first}) {
    if (_closed) return;
    for (final key in [
      if (first != null) first,
      ...keys,
    ]) {
      if (_ready.containsKey(key) || _queue.contains(key)) continue;
      _queue.add(key);
    }
    if (_queue.isEmpty || _scheduled) return;
    _scheduled = true;
    // After the frame, not before: the board on screen must be painted first,
    // or the generation this avoids lands in the same frame as the new board.
    //
    // Every pending key is built in this one callback rather than one per
    // frame. Spreading them would need a frame nobody asked for between each
    // two, and a size chip tapped before those frames arrive would generate
    // its own board — the one thing this class exists to prevent. One callback
    // means one gap of work, and after it every board is ready.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_closed) return;
      for (final key in _queue) {
        if (_ready.containsKey(key)) continue;
        _built++;
        _ready[key] = _build(key);
      }
      _queue.clear();
    });
  }

  /// Drops the cache. Called when the game leaves the screen so a queued
  /// warm-up cannot keep a notifier alive.
  void dispose() {
    _closed = true;
    _ready.clear();
    _queue.clear();
  }
}
