import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../widgets/tangible.dart';
import '../../../core/board/board_verb.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../../../core/juice/game_scaffold.dart';
import 'kurodoko_board.dart';
import 'kurodoko_engine.dart';
import 'kurodoko_provider.dart';

class KurodokoScreen extends ConsumerWidget {
  const KurodokoScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    KurodokoNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('kurodoko', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.wellDone,
        message: l10n.kurodokoCongrats,
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
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(kurodokoNotifierProvider);
    final notifier = ref.read(kurodokoNotifierProvider.notifier);

    return GameScaffold(
      title: l10n.kurodokoTitle,
      subtitle: l10n.kurodokoSubtitle,
      actions: [
        TangibleButton(
          color: Theme.of(context).colorScheme.surface,
          shadowColor: Theme.of(context).colorScheme.outline,
          onTap: () {
            emitVerb(BoardVerb.select);
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
            emitVerb(BoardVerb.select);
            notifier.newGame();
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
          const SizedBox(height: DesignSystem.spaceSM),
          _DifficultyRow(
            selected: state.difficulty,
            onSelected: (difficulty) {
              emitVerb(BoardVerb.select);
              notifier.setDifficulty(difficulty);
            },
          ),
          const Spacer(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: PuzzleBoardView<KurodokoState>(
                board: KurodokoBoard(state: state),
                onMove: notifier.applyMove,
                onSolved: () => _onSolved(context, ref, notifier),
              ),
            ),
          ),
          const SizedBox(height: DesignSystem.spaceMD),
          Text(
            l10n.kurodokoTapHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: DesignSystem.spaceLG),
        ],
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.selected, required this.onSelected});

  final KurodokoDifficulty selected;
  final ValueChanged<KurodokoDifficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      KurodokoDifficulty.easy: l10n.difficultyEasy,
      KurodokoDifficulty.medium: l10n.difficultyMedium,
      KurodokoDifficulty.hard: l10n.difficultyHard,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final difficulty in KurodokoDifficulty.values)
          Padding(
            // Four, not a design token: three buttons plus their padding have
            // to fit a 320dp phone, and the tokens are too generous for that.
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TangibleButton(
              color: difficulty == selected
                  ? DesignSystem.primary
                  : Theme.of(context).colorScheme.surface,
              shadowColor: Theme.of(context).colorScheme.outline,
              onTap: () => onSelected(difficulty),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignSystem.spaceMD,
                vertical: DesignSystem.spaceXS,
              ),
              child: Text(
                labels[difficulty]!,
                style: TextStyle(
                  fontSize: DesignSystem.fontSizeXS,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: difficulty == selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
