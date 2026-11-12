import 'package:flutter/material.dart';

/// The bridge between the feed and the rest of the app.
///
/// A game screen is built by a registry entry and knows nothing about the feed;
/// a completion dialog is pushed on the root navigator and sits outside the
/// feed's widget subtree. Both still need to behave differently inside the
/// feed, so the active feed publishes itself here for the duration of its life.
///
/// Only one feed is ever mounted at a time (it is either a tab or a pushed
/// route), so a single static handle is honest rather than clever.
class FeedSession {
  FeedSession({
    required this.next,
    required this.restart,
    required this.close,
    required this.isRoute,
  });

  static FeedSession? _active;

  /// Non-null while a feed is on screen.
  static FeedSession? get current => _active;

  /// Whether a game is being played as a card in the feed.
  static bool get inFeed => _active != null;

  static void activate(FeedSession session) => _active = session;

  static void deactivate(FeedSession session) {
    if (identical(_active, session)) _active = null;
  }

  /// Deal the next card.
  final VoidCallback next;

  /// Re-deal the current card from scratch.
  final VoidCallback restart;

  /// Leave the feed (a no-op when the feed is a tab).
  final VoidCallback close;

  /// True when the feed was pushed as its own page and can be popped.
  final bool isRoute;
}
