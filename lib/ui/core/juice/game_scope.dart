import 'package:flutter/material.dart';

import '../../../data/game_metadata.dart';
import '../../../data/game_registry.dart';

/// The game a screen is actually running.
///
/// Screens used to be identified by the title they display, and four pairs of
/// games share a localised title (`silhouette_match` / `silhouette_match_ortho`,
/// `word_ladder` / `word_ladder_step`, plus two pairs that collide only in
/// `pt`/`es` and `de`). The shell resolved the first match, so the wrong guide
/// and the wrong assist buttons loaded, and the clock started under an id the
/// screen never used — which meant those games recorded no time and no personal
/// best at all.
///
/// [launchGame] wraps the page it opens in this scope, so the id travels with
/// the screen and nothing has to be threaded through 313 widgets.
class GameScope extends InheritedWidget {
  const GameScope({
    super.key,
    required this.gameId,
    required super.child,
  });

  final String gameId;

  /// The id of the game this subtree is running. Registers a dependency, so
  /// call it from `build`; null when a screen was pushed outside `launchGame`.
  static String? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameScope>()?.gameId;

  /// The same answer without a dependency — safe in `initState` and in a
  /// post-frame callback, which is where the clock starts.
  static String? read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<GameScope>();
    final widget = element?.widget;
    return widget is GameScope ? widget.gameId : null;
  }

  @override
  bool updateShouldNotify(GameScope oldWidget) => oldWidget.gameId != gameId;
}

/// The registry entry behind a screen: by id when the scope knows it, by the
/// displayed title only as a fallback for screens opened outside [launchGame].
///
/// A miss is not an error: an unregistered screen simply gets no assist
/// buttons and no clock.
GameMetadata? resolveGame(
  BuildContext context, {
  required String title,
  String? gameId,
}) {
  final id = gameId ?? GameScope.read(context);
  if (id != null) {
    for (final game in allGamesMetadata) {
      if (game.id == id) return game;
    }
  }
  final upper = title.toUpperCase();
  for (final game in allGamesMetadata) {
    try {
      if (game.titleGetter(context).toUpperCase() == upper) return game;
    } catch (_) {
      // A game whose title needs localisation it does not have; skip it.
    }
  }
  return null;
}
