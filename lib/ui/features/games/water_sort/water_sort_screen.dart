import 'package:puzzle/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'water_sort_provider.dart';
import 'water_sort_board.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../utils/design_system.dart';
import '../../../../utils/haptic_feedback.dart';
import '../../../../widgets/tangible.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../../../core/juice/game_scaffold.dart';
import '../../../../providers/user_providers.dart';

class WaterSortScreen extends ConsumerWidget {
  const WaterSortScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(waterSortNotifierProvider);
    final notifier = ref.read(waterSortNotifierProvider.notifier);

    return GameScaffold(
      title: 'WATER SORT',
      subtitle: l10n.waterSortSubtitle,
      actions: [
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
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
        ),
      ],
      body: Column(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: PuzzleBoardView<WaterSortState>(
                board: WaterSortBoard(state: state),
                onMove: notifier.applyMove,
                onSolved: () async {
                  await ref
                      .read(gameStreakNotifierProvider.notifier)
                      .completeGame('water_sort', xpAmount: 30);
                  if (!context.mounted) return;
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => GameCompletionDialog(
                      onHome: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(dialogContext).pop();
                      },
                      onPlayAgain: () {
                        notifier.reset();
                        Navigator.of(dialogContext).pop();
                      },
                      title: l10n.waterSortTitle.toUpperCase(),
                      message: 'You sorted all the colors perfectly!',
                    ),
                  );
                },
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
