import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'slitherlink_provider.dart';
import 'slitherlink_board.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../widgets/tangible.dart';
import '../../../../utils/design_system.dart';
import '../../../../utils/haptic_feedback.dart';
import '../../../../providers/user_providers.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../../../core/juice/game_scaffold.dart';

class SlitherlinkScreen extends ConsumerWidget {
  const SlitherlinkScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    SlitherlinkNotifier notifier,
  ) async {
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('slitherlink', xpAmount: 25);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: 'LOOP COMPLETED',
        message: 'Awesome! You successfully completed the loop puzzle.',
        onHome: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(dialogContext).pop();
        },
        onPlayAgain: () {
          notifier.newGame();
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(slitherlinkNotifierProvider);
    final notifier = ref.read(slitherlinkNotifierProvider.notifier);

    ref.listen(slitherlinkNotifierProvider, (previous, next) {
      final before = previous?.conflicts.length ?? 0;
      if (next.conflicts.length <= before) return;
      final broken = next.conflicts.last;
      HapticFeedbackUtil.error();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1800),
            content: Text(
              'That ${broken.clue} now has ${broken.drawn} lines around it. '
              'The clue allows exactly ${broken.clue}.',
            ),
          ),
        );
    });

    return GameScaffold(
      title: 'Slitherlink',
      subtitle: 'Tap edges to form a single continuous loop matching cell numbers.',
      actions: [
        TangibleButton(
          color: Theme.of(context).colorScheme.surface,
          shadowColor: Theme.of(context).colorScheme.outline,
          onTap: () {
            HapticFeedbackUtil.selection();
            notifier.hint();
          },
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.lightbulb_outline_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: DesignSystem.spaceSM),
        TangibleButton(
          color: Theme.of(context).colorScheme.surface,
          shadowColor: Theme.of(context).colorScheme.outline,
          onTap: () {
            HapticFeedbackUtil.mediumImpact();
            notifier.reset();
          },
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.refresh_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: DesignSystem.spaceSM),
            child: Text(
              state.conflicts.isEmpty
                  ? 'EVERY CLUE IS STILL HONEST'
                  : '${state.conflicts.length} CLUE${state.conflicts.length == 1 ? '' : 'S'} BROKEN',
              style: TextStyle(
                fontSize: DesignSystem.fontSizeXS,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: state.conflicts.isEmpty
                    ? Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45)
                    : DesignSystem.error,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: PuzzleBoardView<SlitherlinkState>(
                board: SlitherlinkBoard(state: state),
                onMove: notifier.applyMove,
                onSolved: () => _onSolved(context, ref, notifier),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
