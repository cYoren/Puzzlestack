import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../shared/board_game_scaffold.dart';
import 'bricks_board.dart';
import 'bricks_provider.dart';
import 'bricks_puzzle.dart';

class BricksScreen extends ConsumerWidget {
  const BricksScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    BricksNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('bricks', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.bricksWinTitle,
        message: l10n.bricksWinMessage,
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
    final state = ref.watch(bricksNotifierProvider);
    final notifier = ref.read(bricksNotifierProvider.notifier);

    return BoardGameScaffold(
      title: l10n.bricksTitle,
      subtitle: l10n.bricksSubtitle,
      actions: [
        BoardGameActions(onHint: notifier.hint, onReset: notifier.newGame),
      ],
      toolbar: BoardGameChipRow(
        chips: [
          for (final size in BricksSize.values)
            BoardGameChip(
              label: '${size.rows}x${size.cols}',
              selected: size == state.size,
              onTap: () => notifier.setSize(size),
            ),
        ],
      ),
      hud: [
        GameStat(
          label: l10n.bricksShaded.toUpperCase(),
          value: '${state.shaded}',
          color: DesignSystem.primary,
        ),
        GameStat(
          label: l10n.bricksDepth.toUpperCase(),
          value: '${notifier.level ?? '-'}',
          color: DesignSystem.gameIndigo,
        ),
      ],
      board: PuzzleBoardView<BricksState>(
        board: BricksBoard(state: state),
        onMove: (move) => notifier.tap(move.source.a),
        onSolved: () => _onSolved(context, ref, notifier),
      ),
    );
  }
}
