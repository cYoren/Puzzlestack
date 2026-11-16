import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../shared/board_game_scaffold.dart';
import 'mathrax_board.dart';
import 'mathrax_provider.dart';
import 'mathrax_puzzle.dart';

class MathraxScreen extends ConsumerWidget {
  const MathraxScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    MathraxNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakProvider.notifier)
        .completeGame('mathrax', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.mathraxWinTitle,
        message: l10n.mathraxWinMessage,
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
    final state = ref.watch(mathraxProvider);
    final notifier = ref.read(mathraxProvider.notifier);

    return BoardGameScaffold(
      title: l10n.mathraxTitle,
      subtitle: l10n.mathraxSubtitle,
      actions: [
        BoardGameActions(onHint: notifier.hint, onReset: notifier.newGame),
      ],
      toolbar: BoardGameChipRow(
        chips: [
          for (final size in MathraxSize.values)
            BoardGameChip(
              label: switch (size) {
                MathraxSize.small => l10n.difficultyEasy,
                MathraxSize.medium => l10n.difficultyMedium,
                MathraxSize.large => l10n.difficultyHard,
              },
              selected: size == state.size,
              onTap: () => notifier.setSize(size),
            ),
        ],
      ),
      hud: [
        GameStat(
          label: l10n.mathraxFilled.toUpperCase(),
          value: '${state.written}/${state.n * state.n}',
          color: DesignSystem.primary,
        ),
        GameStat(
          label: l10n.mathraxDepth.toUpperCase(),
          value: '${notifier.level ?? '-'}',
          color: DesignSystem.gameIndigo,
        ),
      ],
      board: PuzzleBoardView<MathraxState>(
        board: MathraxBoard(state: state),
        onMove: (move) =>
            notifier.cycle(move.source.a * state.n + move.source.b),
        onSolved: () => _onSolved(context, ref, notifier),
      ),
    );
  }
}
