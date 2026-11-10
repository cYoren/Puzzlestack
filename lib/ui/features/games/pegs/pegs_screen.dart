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
import 'pegs_board.dart';
import 'pegs_engine.dart';
import 'pegs_provider.dart';

class PegsScreen extends ConsumerWidget {
  const PegsScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    PegsNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('pegs', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.wellDone,
        message: l10n.pegsCongrats,
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
    final state = ref.watch(pegsNotifierProvider);
    final notifier = ref.read(pegsNotifierProvider.notifier);

    return GameScaffold(
      title: l10n.pegsTitle,
      subtitle: l10n.pegsSubtitle,
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
        const SizedBox(width: 8),
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: PuzzleBoardView<PegsState>(
                board: PegsBoard(state: state),
                onMove: notifier.applyMove,
                onSolved: () => _onSolved(context, ref, notifier),
              ),
            ),
          ),
          const SizedBox(height: DesignSystem.spaceMD),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: DesignSystem.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${state.pegsLeft}',
                style: TextStyle(
                  fontSize: DesignSystem.fontSizeSM,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.selected, required this.onSelected});

  final PegsDifficulty selected;
  final ValueChanged<PegsDifficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      PegsDifficulty.easy: l10n.difficultyEasy,
      PegsDifficulty.medium: l10n.difficultyMedium,
      PegsDifficulty.hard: l10n.difficultyHard,
    };

    return Padding(
      padding: const EdgeInsets.only(
        top: DesignSystem.spaceSM,
        bottom: DesignSystem.spaceSM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final difficulty in PegsDifficulty.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TangibleButton(
                color: difficulty == selected
                    ? DesignSystem.primary
                    : Theme.of(context).colorScheme.surface,
                shadowColor: Theme.of(context).colorScheme.outline,
                depth: difficulty == selected ? 2 : 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignSystem.spaceMD,
                  vertical: DesignSystem.spaceXS,
                ),
                onTap: () => onSelected(difficulty),
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
      ),
    );
  }
}
