import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/utils/haptic_feedback.dart';
import 'package:puzzle/utils/l10n_game_helpers.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';
import '../../../core/juice/game_scaffold.dart';
import 'ghost_tap_engine.dart';

class GhostTapScreen extends ConsumerStatefulWidget {
  const GhostTapScreen({super.key});

  @override
  ConsumerState<GhostTapScreen> createState() => _GhostTapScreenState();
}

class _GhostTapScreenState extends ConsumerState<GhostTapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  /// This game's pulse length and ghost delay. Drawn when a game starts, so two
  /// games are two different exercises.
  GhostTapSession _session = GhostTapSession.random(Random());

  bool _isGhostMode =
      false; // When true, pulse circle becomes completely invisible
  int _completedCycles = 0;
  DateTime? _theoreticalPeakTime;

  int _score = 0;
  final int _targetScore = 10;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    // Pulse animation cycle runs at 1.5 seconds per pulse
    // The pulse length is the session's, not a constant: see GhostTapSession.
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _session.periodMs),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completedCycles++;
        _theoreticalPeakTime = DateTime.now();
        _pulseController.forward(from: 0.0);

        if (_completedCycles >= _session.visibleCycles && !_isGhostMode) {
          // Go invisible (Ghost Mode)
          setState(() {
            _isGhostMode = true;
          });
        }
      }
    });

    _startNewGame();
  }

  void _startNewGame() {
    final random = Random();
    // A new game is a new rhythm, not the same one again.
    _session = GhostTapSession.random(random);
    _pulseController.duration = Duration(milliseconds: _session.periodMs);
    _score = 0;
    _isGameOver = false;
    _isGhostMode = false;
    _completedCycles = 0;
    _pulseController.forward(from: 0.0);
  }

  void _onTapGhost() {
    if (_isGameOver) return;

    if (!_isGhostMode) {
      // Tapping when it is visible shouldn't score or penalize, just warn
      HapticFeedbackUtil.lightImpact();
      return;
    }

    // Evaluate timing accuracy:
    // How close is the tap to the expected periodic peak? Peaks are at
    // _theoreticalPeakTime + N * period, and the period is this session's.
    final now = DateTime.now();
    if (_theoreticalPeakTime == null) return;

    final diffMs = now.difference(_theoreticalPeakTime!).inMilliseconds.abs();

    setState(() {
      // A window of tolerance around the peak, in the session's own units.
      if (_session.isOnBeat(diffMs)) {
        _score++;
        HapticFeedbackUtil.success();
        if (_score >= _targetScore) {
          _isGameOver = true;
          _onGameComplete();
        } else {
          // Return to visible mode for 3 cycles to sync again
          _isGhostMode = false;
          _completedCycles = 0;
        }
      } else {
        _score = max(0, _score - 2);
        HapticFeedbackUtil.error();
        // Return to visible mode to sync again
        _isGhostMode = false;
        _completedCycles = 0;
      }
    });
  }

  void _onGameComplete() async {
    _pulseController.stop();
    HapticFeedbackUtil.victory();
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('ghost_tap');
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameCompletionDialog(
        title: AppLocalizations.of(context)!.wellDone.toUpperCase(),
        message: AppLocalizations.of(context)!.completed,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _startNewGame();
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: L10nGameHelpers.getGameTitle(context, 'ghost_tap'),
      subtitle: L10nGameHelpers.getGameSubtitle(context, 'ghost_tap'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            HapticFeedbackUtil.lightImpact();
            setState(() {
              _startNewGame();
            });
          },
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignSystem.spaceMD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _isGhostMode
                        ? 'TAP AT PEAK (INVISIBLE)'
                        : 'MEMORIZE THE RHYTHM',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          _isGhostMode ? Colors.orange : DesignSystem.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: DesignSystem.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSM),
                  ),
                  child: Text(
                    'Score: $_score / $_targetScore',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.primary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTapDown: (_) => _onTapGhost(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      // Sine scale curve representing circle breathing pulse
                      final double scale =
                          0.3 + 0.6 * sin(_pulseController.value * pi);

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _isGhostMode ? 0.0 : 1.0,
                        child: Container(
                          width: 250 * scale,
                          height: 250 * scale,
                          decoration: BoxDecoration(
                            color: DesignSystem.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: DesignSystem.primary, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    DesignSystem.primary.withValues(alpha: 0.2),
                                blurRadius: 20 * scale,
                                spreadRadius: 5 * scale,
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _isGhostMode
                                ? Icons.lens_blur_rounded
                                : Icons.radar_rounded,
                            color: DesignSystem.primary,
                            size: 48 * scale,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text(
              'TAP THE SCREEN TO RECORD THE PEAK TAP EVENT',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
