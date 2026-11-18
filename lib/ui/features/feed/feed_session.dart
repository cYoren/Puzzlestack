import 'dart:math';

import 'package:flutter/material.dart';

/// The bridge between the feed (or Daily Five) and the rest of the app.
///
/// A game screen is built by a registry entry and knows nothing about the feed;
/// a completion dialog is pushed on the root navigator and sits outside the
/// feed's widget subtree. Both still need to behave differently inside the
/// feed, so active feed surfaces push themselves onto [_stack] for the duration
/// of their active life.
class FeedSession {
  FeedSession({
    required this.next,
    required this.restart,
    required this.close,
    required this.isRoute,
    this.seedFor,
    this.fixedFeedSize = false,
    this.onSolved,
    this.onReplay,
  });

  static final List<FeedSession> _stack = <FeedSession>[];
  static int _suspensions = 0;

  /// Non-null while an unsuspended feed or Daily Five card is on screen.
  static FeedSession? get current =>
      _suspensions > 0 || _stack.isEmpty ? null : _stack.last;

  /// Whether a game is being played as a card in the feed or Daily Five.
  static bool get inFeed => current != null;

  /// Deterministic RNG for [gameId] when the active session carries a seed
  /// (Daily Five and 30-day non-repeating deals), or null otherwise.
  static Random? randomFor(String gameId) {
    final int? seed = seedOf(gameId);
    return seed == null ? null : Random(seed);
  }

  /// Deterministic integer seed for [gameId] when the active session supplies
  /// one.
  static int? seedOf(String gameId) => current?.seedFor?.call(gameId);

  static void activate(FeedSession session) {
    _stack.remove(session);
    _stack.add(session);
  }

  static void deactivate(FeedSession session) {
    _stack.remove(session);
  }

  /// Suspends any background feed session while a Stack game route is open, so
  /// a game launched from the Stack never inherits chrome or feed sizing from a
  /// tab kept alive behind an `IndexedStack`.
  static VoidCallback suspend() {
    _suspensions += 1;
    bool released = false;
    return () {
      if (released) return;
      released = true;
      if (_suspensions > 0) _suspensions -= 1;
    };
  }

  /// Deal the next card.
  final VoidCallback next;

  /// Re-deal the current card from scratch.
  final VoidCallback restart;

  /// Leave the feed (a no-op when the feed is a tab).
  final VoidCallback close;

  /// True when the feed was pushed as its own page and can be popped.
  final bool isRoute;

  /// Optional seed provider for deterministic deals (Daily Five and seed
  /// history).
  final int Function(String gameId)? seedFor;

  /// When true (Daily Five), every player gets the baseline feed size regardless
  /// of personal solve history.
  final bool fixedFeedSize;

  /// Optional hook notified when the current card completes in the feed.
  final void Function(String? detail)? onSolved;

  /// Optional hook notified before replaying a card in the Deal so the card can
  /// draw a fresh seed while Daily Five (`fixedFeedSize == true`) keeps its
  /// fixed daily seed.
  final VoidCallback? onReplay;
}
