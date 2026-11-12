import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// One game's local record: how often it has been solved and how long the
/// solves took.
///
/// Deliberately local and small. "Faster than 62% of your solves" is a true
/// statement about this player's own history; inventing a global population
/// would be a lie the app cannot back up.
@immutable
class GameStat {
  const GameStat({
    this.solves = 0,
    this.assisted = 0,
    this.times = const <int>[],
  });

  final int solves;

  /// Solves that came from the solve button. Counted, never hidden.
  final int assisted;

  /// Milliseconds per solve, most recent last, capped at [maxTimes].
  final List<int> times;

  static const int maxTimes = 30;

  int? get bestMs =>
      times.isEmpty ? null : times.reduce((a, b) => a < b ? a : b);

  /// The share of this player's solves this game's best time beats, 0..100.
  int? get fasterThan {
    final best = bestMs;
    if (best == null || times.length < 3) return null;
    final beaten = times.where((time) => time > best).length;
    return (beaten * 100 / times.length).round();
  }

  GameStat record(int milliseconds, {bool assisted = false}) {
    final next = [...times, milliseconds];
    return GameStat(
      solves: solves + 1,
      assisted: this.assisted + (assisted ? 1 : 0),
      times: next.length > maxTimes
          ? next.sublist(next.length - maxTimes)
          : next,
    );
  }

  Map<String, dynamic> toJson() => {
        'solves': solves,
        'assisted': assisted,
        'times': times,
      };

  /// Reads a stored record, dropping anything that does not make sense. A
  /// corrupt row must never stop the app from counting the next solve.
  static GameStat fromJson(Object? value) {
    if (value is! Map) return const GameStat();
    final times = <int>[];
    final raw = value['times'];
    if (raw is List) {
      for (final item in raw) {
        if (item is int && item > 0 && item < 24 * 60 * 60 * 1000) {
          times.add(item);
        }
      }
    }
    return GameStat(
      solves: value['solves'] is int ? (value['solves'] as int).clamp(0, 1 << 30) : 0,
      assisted:
          value['assisted'] is int ? (value['assisted'] as int).clamp(0, 1 << 30) : 0,
      times: times.length > maxTimes
          ? times.sublist(times.length - maxTimes)
          : times,
    );
  }
}

/// The stats and first-play store.
///
/// A plain Hive box of JSON strings rather than a typed adapter: adding a field
/// here must not require a build_runner pass over the whole app, and a bad row
/// must not break startup.
class GameStatsRepository {
  GameStatsRepository._();

  static final GameStatsRepository instance = GameStatsRepository._();

  static const String _boxName = 'game_stats';
  static const String _seenKey = '_seen_games';
  static const String _statsKey = '_stats';

  Map<String, GameStat> _stats = const {};
  Set<String> _seen = <String>{};
  bool _loaded = false;

  bool get isReady => _loaded;

  Future<void> init() async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      _stats = _decodeStats(box.get(_statsKey));
      _seen = _decodeSeen(box.get(_seenKey));
      _loaded = true;
    } catch (error) {
      // No Hive (a widget test, a first run that failed to open storage): the
      // app still works, it just cannot remember.
      debugPrint('GameStatsRepository init error: $error');
      _stats = const {};
      _seen = <String>{};
      _loaded = false;
    }
  }

  Map<String, GameStat> get stats => Map.unmodifiable(_stats);

  GameStat statFor(String gameId) => _stats[gameId] ?? const GameStat();

  bool hasSeen(String gameId) => _seen.contains(gameId);

  Future<void> markSeen(String gameId) async {
    if (!_seen.add(gameId)) return;
    await _write(_seenKey, _seen.toList());
  }

  Future<GameStat> record(
    String gameId,
    Duration elapsed, {
    bool assisted = false,
  }) async {
    final milliseconds = elapsed.inMilliseconds;
    if (milliseconds <= 0) return statFor(gameId);
    final next = statFor(gameId).record(milliseconds, assisted: assisted);
    _stats = {..._stats, gameId: next};
    await _write(_statsKey, {
      for (final entry in _stats.entries) entry.key: entry.value.toJson(),
    });
    return next;
  }

  Future<void> _write(String key, Object value) async {
    if (!_loaded) return;
    try {
      final box = Hive.box<dynamic>(_boxName);
      await box.put(key, jsonEncode(value));
    } catch (error) {
      debugPrint('GameStatsRepository write error: $error');
    }
  }

  Map<String, GameStat> _decodeStats(Object? raw) {
    if (raw is! String || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String) entry.key as String: GameStat.fromJson(entry.value),
      };
    } catch (_) {
      return const {};
    }
  }

  Set<String> _decodeSeen(Object? raw) {
    if (raw is! String || raw.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return {
        for (final item in decoded)
          if (item is String) item,
      };
    } catch (_) {
      return <String>{};
    }
  }
}
