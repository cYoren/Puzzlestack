/// Store review prompts.
///
/// Both stores allow at most three prompts per user per year and silently drop
/// the extras — so the goal is never to ask more often, it is to spend each of
/// the three asks at the strongest possible moment.
///
/// Two levers do that:
///   1. Breadth. Every genuine success moment feeds one shared counter, so a
///      player who never touches the mode you happened to instrument is still
///      asked eventually.
///   2. Weight. A peak achievement is worth more than a routine win, so a
///      player who just did the hardest thing in the app is asked right then
///      rather than five ordinary rounds later.
///
/// Anything that could read as a bad experience — a loss, a low score, a
/// player who just sent negative feedback — either does not count or actively
/// suppresses the prompt. Asking straight after a failure is how apps earn the
/// one-star ratings they were trying to avoid.
///
/// PORTABILITY: this file is identical across every app in the portfolio. Only
/// the `ReviewMoment` weights handed to `record()` differ, and those live at
/// the call site. Copy it verbatim; do not fork it per game.
///
/// Canonical source: Games/shared-assets/review_prompt_service.dart
/// Reference design: medhub-apps/src/core/services/reviewPromptService.ts
library;

import 'dart:async';
import 'dart:convert';

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What a moment is worth toward [ReviewPromptService.requiredWeight].
///
/// Use [peak] for the single hardest or most satisfying thing a player can do
/// in the app — it is enough on its own. Use [routine] for ordinary wins, which
/// still have to stack up before the first ask.
class ReviewMoment {
  const ReviewMoment._(this.id, this.weight);

  /// A routine win: one solved puzzle, one completed round.
  static const routine = ReviewMoment._('routine', 1);

  /// A meaningful step up: a new difficulty, a chapter finished.
  static const progression = ReviewMoment._('progression', 2);

  /// The app's peak moment: a level advance, a campaign cleared, a long streak.
  static const peak = ReviewMoment._('peak', 3);

  final String id;
  final int weight;
}

/// Records positive moments and asks for a store review when one tips the
/// player over the threshold.
///
/// Every method fails silently. Losing the counter costs at most one prompt;
/// it must never cost a crash in the middle of a game.
class ReviewPromptService {
  ReviewPromptService._();

  static const _stateKey = 'reviews/prompt-state-v1';

  /// Accumulated weight required before the first ask. One [ReviewMoment.peak]
  /// clears it alone; three [ReviewMoment.routine] wins also do.
  static const requiredWeight = 3;

  /// 120 days ≈ three asks per year, which is the platform ceiling anyway.
  static const promptCooldown = Duration(days: 120);

  /// Below this, a scored result is not a moment worth asking on.
  static const minScorePercent = 70;

  /// Injection points for tests. Production leaves both null.
  static InAppReview? reviewApiOverride;
  static DateTime Function()? nowOverride;

  static DateTime get _now => (nowOverride ?? DateTime.now)();

  /// Stop asking for [days]. Call this the moment a player signals displeasure
  /// — a negative in-app feedback form, a bug report, a rage-quit dialog.
  static Future<void> suppress({int days = 30}) async {
    final state = await _read();
    state.suppressedUntil = _now.add(Duration(days: days));
    await _write(state);
  }

  /// Wipe all state. Only for tests and "reset progress" menu items.
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stateKey);
    } catch (_) {
      // Nothing to do — the next read falls back to a fresh state.
    }
  }

  /// Record a positive moment, and prompt if this one tips the player over.
  ///
  /// Pass [scorePercent] when the moment has a score attached; a mediocre
  /// result is not a moment to ask on, whatever produced it. Pass [dedupeKey]
  /// for milestones that get recomputed — a streak counter recalculated on
  /// every app foreground would otherwise credit day 7 again and again.
  ///
  /// Returns whether the store prompt was actually requested.
  static Future<bool> record(
    ReviewMoment moment, {
    int? scorePercent,
    String? dedupeKey,
  }) async {
    if (scorePercent != null && scorePercent < minScorePercent) return false;

    final state = await _read();

    if (dedupeKey != null) {
      if (state.creditedKeys.contains(dedupeKey)) return false;
      state.creditedKeys.add(dedupeKey);
    }

    state.weight += moment.weight;
    return _maybePrompt(state);
  }

  /// Shared gate: persist the new state, and ask only if every condition holds.
  static Future<bool> _maybePrompt(_ReviewState state) async {
    final now = _now;
    final cooledDown = state.lastPromptAt == null ||
        now.difference(state.lastPromptAt!) >= promptCooldown;
    final unsuppressed =
        state.suppressedUntil == null || now.isAfter(state.suppressedUntil!);

    if (state.weight < requiredWeight || !cooledDown || !unsuppressed) {
      await _write(state);
      return false;
    }

    try {
      final review = reviewApiOverride ?? InAppReview.instance;
      if (!await review.isAvailable()) {
        await _write(state);
        return false;
      }
      // Store guidelines prefer an automatic request right after a signature
      // success moment, not a custom button or a rating pre-screen.
      await review.requestReview();
      state.lastPromptAt = now;
      // Reset the accumulator so the next ask needs fresh evidence rather than
      // riding on credit earned before this prompt.
      state.weight = 0;
      await _write(state);
      return true;
    } catch (_) {
      await _write(state);
      return false;
    }
  }

  static Future<_ReviewState> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_stateKey);
      if (raw == null) return _ReviewState();
      return _ReviewState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return _ReviewState();
    }
  }

  static Future<void> _write(_ReviewState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stateKey, jsonEncode(state.toJson()));
    } catch (_) {
      // Losing the counter costs one prompt, never a crash.
    }
  }
}

class _ReviewState {
  _ReviewState({
    this.weight = 0,
    this.lastPromptAt,
    this.suppressedUntil,
    Set<String>? creditedKeys,
  }) : creditedKeys = creditedKeys ?? <String>{};

  /// Accumulated weight since the last prompt.
  int weight;
  DateTime? lastPromptAt;
  DateTime? suppressedUntil;

  /// Milestones already spent, so a recomputed value cannot double-count.
  final Set<String> creditedKeys;

  factory _ReviewState.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? v) =>
        v is String ? DateTime.tryParse(v) : null;
    return _ReviewState(
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      lastPromptAt: parse(json['lastPromptAt']),
      suppressedUntil: parse(json['suppressedUntil']),
      creditedKeys: (json['creditedKeys'] as List?)
              ?.whereType<String>()
              .toSet() ??
          <String>{},
    );
  }

  Map<String, dynamic> toJson() => {
        'weight': weight,
        if (lastPromptAt != null)
          'lastPromptAt': lastPromptAt!.toIso8601String(),
        if (suppressedUntil != null)
          'suppressedUntil': suppressedUntil!.toIso8601String(),
        'creditedKeys': creditedKeys.toList(),
      };
}
