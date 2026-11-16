import 'package:flutter/foundation.dart';

import 'key_value_store.dart';
import 'repositories/game_stats_repository.dart';

/// One rung of a game's ladder: the word the player reads, and the board that
/// word means.
///
/// The [label] is the difficulty and the [detail] is the size, because on these
/// games the two are the same decision. A player chooses one thing, not two
/// dropdowns that can contradict each other.
@immutable
class GameTier {
  const GameTier({
    required this.id,
    required this.label,
    required this.detail,
  });

  /// What storage holds and what a provider matches on: the enum name the game
  /// already uses (`easy`, `medium`, `hard`). Stable, never shown.
  final String id;

  /// Shown: `Easy`.
  final String label;

  /// Shown under the label: `4 by 4`.
  final String detail;

  @override
  bool operator ==(Object other) =>
      other is GameTier &&
      other.id == id &&
      other.label == label &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(id, label, detail);

  @override
  String toString() => 'GameTier($id)';
}

/// The sizes one game can be played at.
@immutable
class GameLadder {
  const GameLadder({
    required this.gameId,
    required this.tiers,
    required this.defaultTier,
  });

  final String gameId;

  /// Smallest first. The sheet draws them in this order.
  final List<GameTier> tiers;

  /// The id a fresh install opens at, and the one a corrupt row falls back to.
  /// It is the tier the game opened at before this existed, so nothing about a
  /// first launch changed.
  final String defaultTier;

  bool has(String tierId) => tiers.any((GameTier tier) => tier.id == tierId);

  GameTier? tier(String tierId) {
    for (final GameTier tier in tiers) {
      if (tier.id == tierId) return tier;
    }
    return null;
  }
}

/// The games that have a ladder, and their rungs.
///
/// Only the sixteen ports whose engine already takes a difficulty argument.
/// A game absent from this map has one size, so the app does not ask: a chooser
/// with one option is a question with one answer.
///
/// Adding a ladder here is the whole wiring. The providers read the remembered
/// tier through `startTier`, so a game that is not listed never sees one.
final Map<String, GameLadder> gameLadders =
    Map<String, GameLadder>.unmodifiable(
  <String, GameLadder>{
    'cube': _ladder('cube', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '4 by 4'),
      GameTier(id: 'medium', label: 'Medium', detail: '5 by 5'),
      GameTier(id: 'hard', label: 'Hard', detail: '5 by 5, longer line'),
    ]),
    'dominosa': _ladder('dominosa', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: 'Numbers 0 to 3'),
      GameTier(id: 'medium', label: 'Medium', detail: 'Numbers 0 to 4'),
      GameTier(id: 'hard', label: 'Hard', detail: 'Numbers 0 to 5'),
    ]),
    'futoshiki': _ladder('futoshiki', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '4 by 4'),
      GameTier(id: 'medium', label: 'Medium', detail: '5 by 5'),
      GameTier(id: 'hard', label: 'Hard', detail: '6 by 6, fewer clues'),
    ]),
    'galaxies': _ladder('galaxies', defaultTier: 'easy', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '6 by 6'),
      GameTier(id: 'medium', label: 'Medium', detail: '8 by 8'),
      GameTier(id: 'hard', label: 'Hard', detail: '9 by 9'),
    ]),
    'inertia': _ladder('inertia', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '6 by 6'),
      GameTier(id: 'medium', label: 'Medium', detail: '7 by 7'),
      GameTier(id: 'hard', label: 'Hard', detail: '8 by 8'),
    ]),
    'kurodoko': _ladder('kurodoko', defaultTier: 'easy', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '6 by 8'),
      GameTier(id: 'medium', label: 'Medium', detail: '7 by 10'),
      GameTier(id: 'hard', label: 'Hard', detail: '8 by 10'),
    ]),
    'lights_out': _ladder('lights_out', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '3 by 3'),
      GameTier(id: 'medium', label: 'Medium', detail: '6 by 6'),
      GameTier(id: 'hard', label: 'Hard', detail: '8 by 8'),
    ]),
    'magnets': _ladder('magnets', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '4 by 4'),
      GameTier(id: 'medium', label: 'Medium', detail: '5 by 6'),
      GameTier(id: 'hard', label: 'Hard', detail: '6 by 6'),
    ]),
    'map': _ladder('map', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '5 by 5'),
      GameTier(id: 'medium', label: 'Medium', detail: '6 by 6'),
      GameTier(id: 'hard', label: 'Hard', detail: '7 by 7'),
    ]),
    'netslide': _ladder('netslide', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '4 by 4'),
      GameTier(id: 'medium', label: 'Medium', detail: '5 by 6'),
      GameTier(id: 'hard', label: 'Hard', detail: '6 by 6'),
    ]),
    'pegs': _ladder('pegs', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '7 by 7'),
      GameTier(id: 'medium', label: 'Medium', detail: '9 by 9'),
      GameTier(id: 'hard', label: 'Hard', detail: '11 by 11'),
    ]),
    'same_game': _ladder('same_game', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '8 by 8, 3 colours'),
      GameTier(id: 'medium', label: 'Medium', detail: '10 by 10, 4 colours'),
      GameTier(id: 'hard', label: 'Hard', detail: '12 by 12, 5 colours'),
    ]),
    'signpost': _ladder('signpost', defaultTier: 'easy', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '4 by 4'),
      GameTier(id: 'medium', label: 'Medium', detail: '5 by 5'),
      GameTier(id: 'hard', label: 'Hard', detail: '5 by 5, free ends'),
    ]),
    'skyscrapers': _ladder('skyscrapers', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '4 by 4'),
      GameTier(id: 'medium', label: 'Medium', detail: '5 by 5'),
      GameTier(id: 'hard', label: 'Hard', detail: '6 by 6, fewer clues'),
    ]),
    'tents_and_trees': _ladder('tents_and_trees', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '5 by 5'),
      GameTier(id: 'medium', label: 'Medium', detail: '6 by 6'),
      GameTier(id: 'hard', label: 'Hard', detail: '7 by 7'),
    ]),
    'twiddle': _ladder('twiddle', tiers: const [
      GameTier(id: 'easy', label: 'Easy', detail: '3 by 3'),
      GameTier(id: 'medium', label: 'Medium', detail: '4 by 4'),
      GameTier(id: 'hard', label: 'Hard', detail: '5 by 5'),
    ]),
  },
);

GameLadder _ladder(
  String gameId, {
  required List<GameTier> tiers,
  String defaultTier = 'medium',
}) =>
    GameLadder(gameId: gameId, tiers: tiers, defaultTier: defaultTier);

/// The remembered tier, one row per game id.
///
/// The rows live in the stats box, beside `hasSeen`: both are "what this player
/// did on this device", both are small, and a second box would be a second
/// thing to open before the first frame. The key is namespaced so a stats row
/// can never be mistaken for a tier.
class GameTierStore {
  GameTierStore(this._store);

  /// The same box as [GameStatsRepository], not a new one.
  static const String boxName = GameStatsRepository.boxName;

  final KeyValueStore _store;

  static String rowKey(String gameId) => 'tier.$gameId';

  /// The tier the player last chose for [gameId], or null on a fresh install.
  String? tierFor(String gameId) {
    final Object? raw = _store.read(rowKey(gameId));
    return raw is String && raw.isNotEmpty ? raw : null;
  }

  /// What a board should open at: the remembered tier when it is one this
  /// game still offers (a removed rung must not brick the launch), the
  /// ladder's default otherwise, and null for a game with no ladder.
  String? startFor(String gameId) {
    final GameLadder? ladder = gameLadders[gameId];
    final String? remembered = tierFor(gameId);
    if (ladder == null) return remembered;
    if (remembered != null && ladder.has(remembered)) return remembered;
    return ladder.defaultTier;
  }

  Future<void> remember(String gameId, String tierId) {
    final GameLadder? ladder = gameLadders[gameId];
    // Only a rung the game actually has is worth a row.
    if (ladder != null && !ladder.has(tierId)) return Future<void>.value();
    return _store.write(rowKey(gameId), tierId);
  }
}
