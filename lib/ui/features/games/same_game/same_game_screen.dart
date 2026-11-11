import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../widgets/game_hud.dart';
import '../../../../widgets/tangible.dart';
import '../../../core/board/board_verb.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../../../core/juice/game_scaffold.dart';
import 'same_game_board.dart';
import 'same_game_engine.dart';
import 'same_game_provider.dart';

class SameGameScreen extends ConsumerWidget {
  const SameGameScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    SameGameNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('same_game', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.wellDone,
        message: l10n.sameGameCongrats,
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
    final state = ref.watch(sameGameNotifierProvider);
    final notifier = ref.read(sameGameNotifierProvider.notifier);

    return GameScaffold(
      title: l10n.sameGameTitle,
      subtitle: l10n.sameGameSubtitle,
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
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
            child: GameHud(
              children: [
                _Stat(
                  label: l10n.score.toUpperCase(),
                  value: '${state.score}',
                  color: DesignSystem.primary,
                ),
                _Stat(
                  label: l10n.sameGameLeft.toUpperCase(),
                  value: '${state.squaresLeft}',
                  color: DesignSystem.gameIndigo,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: PuzzleBoardView<SameGameState>(
                board: SameGameBoard(state: state),
                onMove: notifier.applyMove,
                onSolved: () => _onSolved(context, ref, notifier),
              ),
            ),
          ),
          if (state.isStuck)
            Padding(
              padding: const EdgeInsets.only(top: DesignSystem.spaceMD),
              child: Text(
                l10n.sameGameStuck,
                style: TextStyle(
                  fontSize: DesignSystem.fontSizeSM,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TangibleContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: DesignSystem.fontSizeXS,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: DesignSystem.fontSizeMD,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.selected, required this.onSelected});

  final SameGameDifficulty selected;
  final ValueChanged<SameGameDifficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      SameGameDifficulty.easy: l10n.difficultyEasy,
      SameGameDifficulty.medium: l10n.difficultyMedium,
      SameGameDifficulty.hard: l10n.difficultyHard,
    };

    return Padding(
      padding: const EdgeInsets.only(
        top: DesignSystem.spaceSM,
        bottom: DesignSystem.spaceSM,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          for (final difficulty in SameGameDifficulty.values)
            TangibleButton(
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
        ],
      ),
    );
  }
}
