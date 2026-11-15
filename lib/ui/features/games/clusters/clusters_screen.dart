import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../shared/board_game_scaffold.dart';
import 'clusters_board.dart';
import 'clusters_engine.dart';
import 'clusters_provider.dart';

class ClustersScreen extends ConsumerWidget {
  const ClustersScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    ClustersNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('clusters', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.clustersWinTitle,
        message: l10n.clustersWinMessage,
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
    final state = ref.watch(clustersNotifierProvider);
    final notifier = ref.read(clustersNotifierProvider.notifier);

    return BoardGameScaffold(
      title: l10n.clustersTitle,
      subtitle: l10n.clustersSubtitle,
      actions: [
        BoardGameActions(onHint: notifier.hint, onReset: notifier.newGame),
      ],
      toolbar: BoardGameChipRow(
        chips: [
          for (final size in ClustersSize.values)
            BoardGameChip(
              label: switch (size) {
                ClustersSize.small => l10n.difficultyEasy,
                ClustersSize.medium => l10n.difficultyMedium,
                ClustersSize.large => l10n.difficultyHard,
              },
              selected: size == state.size,
              onTap: () => notifier.setSize(size),
            ),
        ],
      ),
      hud: [
        GameStat(
          label: l10n.clustersDots.toUpperCase(),
          value: '${state.puzzle.clueCount()}',
          color: DesignSystem.primary,
        ),
        GameStat(
          label: l10n.clustersDepth.toUpperCase(),
          value: '${notifier.level ?? '-'}',
          color: DesignSystem.gameIndigo,
        ),
      ],
      board: PuzzleBoardView<ClustersState>(
        board: ClustersBoard(state: state),
        onMove: (move) =>
            notifier.cycle(move.source.a * state.n + move.source.b),
        onSolved: () => _onSolved(context, ref, notifier),
      ),
    );
  }
}
