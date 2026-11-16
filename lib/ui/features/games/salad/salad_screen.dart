import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../shared/board_game_scaffold.dart';
import 'salad_board.dart';
import 'salad_provider.dart';
import 'salad_puzzle.dart';

class SaladScreen extends ConsumerWidget {
  const SaladScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    SaladNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('salad', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.saladWinTitle,
        message: l10n.saladWinMessage,
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
    final state = ref.watch(saladNotifierProvider);
    final notifier = ref.read(saladNotifierProvider.notifier);

    return BoardGameScaffold(
      title: l10n.saladTitle,
      subtitle: l10n.saladSubtitle,
      actions: [
        BoardGameActions(onHint: notifier.hint, onReset: notifier.newGame),
      ],
      toolbar: BoardGameChipRow(
        chips: [
          for (final size in SaladSize.values)
            BoardGameChip(
              label: '${size.n}x${size.n}',
              selected: size == state.size,
              onTap: () => notifier.setSize(size),
            ),
        ],
      ),
      hud: [
        GameStat(
          label: l10n.saladWritten.toUpperCase(),
          value: '${state.written}/${state.n * state.n}',
          color: DesignSystem.primary,
        ),
      ],
      board: PuzzleBoardView<SaladState>(
        board: SaladBoard(state: state),
        onMove: (move) => notifier.tap(move.source.a * state.n + move.source.b),
        onSolved: () => _onSolved(context, ref, notifier),
      ),
    );
  }
}
