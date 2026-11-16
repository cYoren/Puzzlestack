import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../shared/board_game_scaffold.dart';
import 'rome_board.dart';
import 'rome_provider.dart';
import 'rome_puzzle.dart';

class RomeScreen extends ConsumerWidget {
  const RomeScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    RomeNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('rome', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.romeWinTitle,
        message: l10n.romeWinMessage,
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
    final state = ref.watch(romeNotifierProvider);
    final notifier = ref.read(romeNotifierProvider.notifier);

    return BoardGameScaffold(
      title: l10n.romeTitle,
      subtitle: l10n.romeSubtitle,
      actions: [
        BoardGameActions(onHint: notifier.hint, onReset: notifier.newGame),
      ],
      toolbar: BoardGameChipRow(
        chips: [
          for (final size in RomeSize.values)
            BoardGameChip(
              label: '${size.n}x${size.n}',
              selected: size == state.size,
              onTap: () => notifier.setSize(size),
            ),
        ],
      ),
      hud: [
        GameStat(
          label: l10n.romeWritten.toUpperCase(),
          value: '${state.written}/${state.arrowCells}',
          color: DesignSystem.primary,
        ),
      ],
      board: PuzzleBoardView<RomeState>(
        board: RomeBoard(state: state),
        onMove: (move) => notifier.tap(move.source.a * state.n + move.source.b),
        onSolved: () => _onSolved(context, ref, notifier),
      ),
    );
  }
}
