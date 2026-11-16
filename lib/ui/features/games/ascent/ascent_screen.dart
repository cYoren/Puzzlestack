import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../shared/board_game_scaffold.dart';
import 'ascent_board.dart';
import 'ascent_engine.dart';
import 'ascent_provider.dart';

class AscentScreen extends ConsumerWidget {
  const AscentScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    AscentNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakProvider.notifier)
        .completeGame('ascent', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.ascentWinTitle,
        message: l10n.ascentWinMessage,
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
    final state = ref.watch(ascentProvider);
    final notifier = ref.read(ascentProvider.notifier);

    return BoardGameScaffold(
      title: l10n.ascentTitle,
      subtitle: l10n.ascentSubtitle,
      actions: [
        BoardGameActions(onHint: notifier.hint, onReset: notifier.newGame),
      ],
      toolbar: BoardGameChipRow(
        chips: [
          for (final size in AscentSize.values)
            BoardGameChip(
              label: switch (size) {
                AscentSize.small => l10n.difficultyEasy,
                AscentSize.medium => l10n.difficultyMedium,
                AscentSize.large => l10n.difficultyHard,
              },
              selected: size == state.size,
              onTap: () => notifier.setSize(size),
            ),
        ],
      ),
      hud: [
        GameStat(
          label: l10n.ascentNext.toUpperCase(),
          value: '${state.nextNumber}',
          color: DesignSystem.primary,
        ),
        GameStat(
          label: l10n.ascentDepth.toUpperCase(),
          value: '${notifier.level ?? '-'}',
          color: DesignSystem.gameIndigo,
        ),
      ],
      board: PuzzleBoardView<AscentState>(
        board: AscentBoard(state: state),
        onMove: (move) => notifier.tap(move.source.a * state.n + move.source.b),
        onSolved: () => _onSolved(context, ref, notifier),
      ),
    );
  }
}
