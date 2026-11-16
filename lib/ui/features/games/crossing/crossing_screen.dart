import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../shared/board_game_scaffold.dart';
import 'crossing_board.dart';
import 'crossing_provider.dart';
import 'crossing_puzzle.dart';

class CrossingScreen extends ConsumerWidget {
  const CrossingScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    CrossingNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('crossing', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.crossingWinTitle,
        message: l10n.crossingWinMessage,
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
    final state = ref.watch(crossingNotifierProvider);
    final notifier = ref.read(crossingNotifierProvider.notifier);

    return BoardGameScaffold(
      title: l10n.crossingTitle,
      subtitle: l10n.crossingSubtitle,
      actions: [
        BoardGameActions(onHint: notifier.hint, onReset: notifier.newGame),
      ],
      toolbar: BoardGameChipRow(
        chips: [
          for (final size in CrossingSize.values)
            BoardGameChip(
              label: '${size.n}x${size.n}',
              selected: size == state.size,
              onTap: () => notifier.setSize(size),
            ),
        ],
      ),
      hud: [
        // The list, not the grid: this game is done when every number is placed.
        GameStat(
          label: l10n.crossingPlaced.toUpperCase(),
          value: '${state.satisfied.length}/${state.puzzle.numbers.length}',
          color: DesignSystem.primary,
        ),
      ],
      board: PuzzleBoardView<CrossingState>(
        board: CrossingBoard(state: state),
        onMove: (move) => notifier.tap(move.source.a * state.n + move.source.b),
        onSolved: () => _onSolved(context, ref, notifier),
      ),
    );
  }
}
