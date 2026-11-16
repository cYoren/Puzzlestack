import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../shared/board_game_scaffold.dart';
import 'boats_board.dart';
import 'boats_engine.dart';
import 'boats_provider.dart';

class BoatsScreen extends ConsumerWidget {
  const BoatsScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    BoatsNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakProvider.notifier)
        .completeGame('boats', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.boatsWinTitle,
        message: l10n.boatsWinMessage,
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
    final state = ref.watch(boatsProvider);
    final notifier = ref.read(boatsProvider.notifier);

    return BoardGameScaffold(
      title: l10n.boatsTitle,
      subtitle: l10n.boatsSubtitle,
      actions: [
        BoardGameActions(
          onHint: notifier.hint,
          onReset: notifier.newGame,
        ),
      ],
      toolbar: BoardGameChipRow(
        chips: [
          for (final size in BoatsSize.values)
            BoardGameChip(
              label: switch (size) {
                BoatsSize.small => l10n.difficultyEasy,
                BoatsSize.medium => l10n.difficultyMedium,
                BoatsSize.large => l10n.difficultyHard,
              },
              selected: size == state.size,
              onTap: () => notifier.setSize(size),
            ),
        ],
      ),
      hud: [
        GameStat(
          label: l10n.boatsShipsFound.toUpperCase(),
          value:
              '${state.ships}/${state.puzzle.solution.where((v) => v == kBoatShip).length}',
          color: DesignSystem.primary,
        ),
        GameStat(
          label: l10n.tentsAndTreesDepth.toUpperCase(),
          value: '${notifier.level ?? '-'}',
          color: DesignSystem.gameIndigo,
        ),
      ],
      board: PuzzleBoardView<BoatsState>(
        board: BoatsBoard(state: state),
        onMove: (move) {
          notifier.cycle(move.source.a * state.cols + move.source.b);
        },
        onSolved: () => _onSolved(context, ref, notifier),
      ),
      footer: BoatsFleetStrip(state: state),
    );
  }
}
