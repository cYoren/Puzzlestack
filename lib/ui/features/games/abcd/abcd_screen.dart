import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../shared/board_game_scaffold.dart';
import 'abcd_board.dart';
import 'abcd_engine.dart';
import 'abcd_provider.dart';

class AbcdScreen extends ConsumerWidget {
  const AbcdScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    AbcdNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('abcd', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.abcdWinTitle,
        message: l10n.abcdWinMessage,
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
    final state = ref.watch(abcdNotifierProvider);
    final notifier = ref.read(abcdNotifierProvider.notifier);

    return BoardGameScaffold(
      title: l10n.abcdTitle,
      subtitle: l10n.abcdSubtitle,
      actions: [
        BoardGameActions(onHint: notifier.hint, onReset: notifier.newGame),
      ],
      toolbar: BoardGameChipRow(
        chips: [
          for (final size in AbcdSize.values)
            BoardGameChip(
              label: switch (size) {
                AbcdSize.small => l10n.difficultyEasy,
                AbcdSize.medium => l10n.difficultyMedium,
                AbcdSize.large => l10n.difficultyHard,
              },
              selected: size == state.size,
              onTap: () => notifier.setSize(size),
            ),
        ],
      ),
      hud: [
        GameStat(
          label: l10n.abcdFilled.toUpperCase(),
          value: '${state.filled}/${state.puzzle.cellCount}',
          color: DesignSystem.primary,
        ),
        GameStat(
          label: l10n.abcdDepth.toUpperCase(),
          value: '${notifier.level ?? '-'}',
          color: DesignSystem.gameIndigo,
        ),
      ],
      board: PuzzleBoardView<AbcdState>(
        board: AbcdBoard(state: state),
        onMove: (move) {
          notifier.cycle(move.source.a * state.cols + move.source.b);
        },
        onSolved: () => _onSolved(context, ref, notifier),
      ),
      footer: AbcdLegend(letters: state.letters),
    );
  }
}
