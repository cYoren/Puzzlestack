import 'package:puzzle/l10n/app_localizations.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../providers/user_providers.dart';
import '../../../../../utils/haptic_feedback.dart';
import '../../../core/juice/game_scaffold.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../widgets/tangible.dart';
import '../../../../utils/design_system.dart';
import 'vigilance_task_provider.dart';

class VigilanceTaskScreen extends ConsumerStatefulWidget {
  const VigilanceTaskScreen({super.key});

  @override
  ConsumerState<VigilanceTaskScreen> createState() => _VigilanceTaskScreenState();
}

class _VigilanceTaskScreenState extends ConsumerState<VigilanceTaskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vigilanceNotifierProvider.notifier).startGame();
    });
  }

  void _showCompletionDialog(bool isVictory, int hits, int misses, int falseAlarms) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameCompletionDialog(
        title: isVictory ? l10n.winStayVigilant : l10n.loseKeepWatch,
        message: AppLocalizations.of(context)!.vigilanceTaskMessage((hits).toString(), (misses).toString(), (falseAlarms).toString()),
        isVictory: isVictory,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onPlayAgain: () {
          Navigator.of(context).pop();
          ref.read(vigilanceNotifierProvider.notifier).startGame();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(vigilanceNotifierProvider);
    
    ref.listen(vigilanceNotifierProvider, (previous, next) async {
      if (next.misses > (previous?.misses ?? 0)) {
        HapticFeedbackUtil.error();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1200),
              backgroundColor: DesignSystem.error,
              content: Text('MISSED A SKIP', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          );
      } else if (next.falseAlarms > (previous?.falseAlarms ?? 0)) {
        HapticFeedbackUtil.vibrate();
      }
      if (next.phase == VigilancePhase.result && previous?.phase != VigilancePhase.result) {
        final isVictory = next.hits > next.misses;
        if (isVictory) {
          HapticFeedbackUtil.victory();
          await ref.read(gameStreakNotifierProvider.notifier).completeGame('vigilance_task');
        } else {
          HapticFeedbackUtil.vibrate();
        }
        if (!context.mounted) return;
        _showCompletionDialog(isVictory, next.hits, next.misses, next.falseAlarms);
      }
    });

    return GameScaffold(
      title: l10n.vigilanceTaskTitle.toUpperCase(),
      subtitle: l10n.vigilanceTaskSubtitle,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignSystem.spaceLG,
              DesignSystem.spaceSM,
              DesignSystem.spaceLG,
              0,
            ),
            child: Text(
              'THE MARKER MOVES ONE STEP A SECOND. WHEN IT SKIPS A STEP, TAP SKIP.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: DesignSystem.fontSize2XS,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: DesignSystem.spaceSM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _VigilanceStat(label: 'HITS', value: state.hits, colour: DesignSystem.success),
                const SizedBox(width: DesignSystem.spaceLG),
                _VigilanceStat(label: 'MISSES', value: state.misses, colour: DesignSystem.error),
                const SizedBox(width: DesignSystem.spaceLG),
                _VigilanceStat(label: 'FALSE', value: state.falseAlarms, colour: DesignSystem.warning),
              ],
            ),
          ),
          const SizedBox(height: DesignSystem.spaceSM),

          // Clock Face
          Expanded(
            flex: 3,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: ClockPainter(
                    currentPosition: state.currentPosition,
                    skippedPosition: state.skippedPosition,
                    outlineColor: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: DesignSystem.space2XL),
          
          // Action Button
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignSystem.space2XL),
              child: TangibleButton(
                onTap: () {
                  HapticFeedbackUtil.lightImpact();
                  ref.read(vigilanceNotifierProvider.notifier).onUserTap();
                },
                color: DesignSystem.primary,
                child: const Center(
                  child: Text(
                    'SKIP!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: DesignSystem.space2XL),
        ],
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final int currentPosition;
  final int? skippedPosition;
  final Color outlineColor;

  ClockPainter({
    required this.currentPosition,
    required this.skippedPosition,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const positions = 60;

    final ring = Paint()
      ..color = outlineColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, ring);

    // A dot per position: a jump of two is a visible gap, which a 6° hand
    // movement never was.
    for (var i = 0; i < positions; i++) {
      final angle = (i * 360 / positions - 90) * pi / 180;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final isActive = i == currentPosition;
      final isSkipped = i == skippedPosition;
      final dotRadius = isActive ? 8.0 : (isSkipped ? 7.0 : 2.4);

      final paint = Paint()
        ..color = isActive
            ? DesignSystem.primary
            : isSkipped
                ? DesignSystem.error
                : outlineColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, dotRadius, paint);
    }

    // A short tail behind the marker, so the direction of travel is readable.
    final tailAngle = ((currentPosition - 1) * 360 / positions - 90) * pi / 180;
    final tail = Offset(
      center.dx + radius * cos(tailAngle),
      center.dy + radius * sin(tailAngle),
    );
    canvas.drawLine(
      center,
      tail,
      Paint()
        ..color = DesignSystem.primary.withValues(alpha: 0.25)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 5, Paint()..color = DesignSystem.primary);
  }

  @override
  bool shouldRepaint(covariant ClockPainter oldDelegate) {
    return oldDelegate.currentPosition != currentPosition ||
        oldDelegate.skippedPosition != skippedPosition;
  }
}

class _VigilanceStat extends StatelessWidget {
  const _VigilanceStat({
    required this.label,
    required this.value,
    required this.colour,
  });

  final String label;
  final int value;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: colour,
          ),
        ),
      ],
    );
  }
}
