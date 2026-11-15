import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../widgets/tangible.dart';
import '../../../core/board/board_verb.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../shared/board_game_scaffold.dart';
import 'seismic_board.dart';
import 'seismic_engine.dart';
import 'seismic_provider.dart';

class SeismicScreen extends ConsumerWidget {
  const SeismicScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    SeismicNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('seismic', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.seismicWinTitle,
        message: l10n.seismicWinMessage,
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
    final state = ref.watch(seismicNotifierProvider);
    final notifier = ref.read(seismicNotifierProvider.notifier);

    return BoardGameScaffold(
      title: l10n.seismicTitle,
      subtitle: l10n.seismicSubtitle,
      actions: [
        BoardGameActions(onHint: notifier.hint, onReset: notifier.newGame),
      ],
      toolbar: BoardGameChipRow(
        chips: [
          for (final size in SeismicSize.values)
            BoardGameChip(
              label: switch (size) {
                SeismicSize.small => l10n.difficultyEasy,
                SeismicSize.medium => l10n.difficultyMedium,
                SeismicSize.large => l10n.difficultyHard,
              },
              selected: size == state.size,
              onTap: () => notifier.setSize(size),
            ),
        ],
      ),
      hud: [
        GameStat(
          label: l10n.seismicClues.toUpperCase(),
          value: '${state.puzzle.givenCount()}',
          color: DesignSystem.primary,
        ),
        GameStat(
          label: l10n.seismicDepth.toUpperCase(),
          value: '${notifier.level ?? '-'}',
          color: DesignSystem.gameIndigo,
        ),
      ],
      board: PuzzleBoardView<SeismicState>(
        board: SeismicBoard(state: state),
        onMove: (move) =>
            notifier.select(move.source.a * state.n + move.source.b),
        onSolved: () => _onSolved(context, ref, notifier),
      ),
      footer: _SeismicPad(
        maxDigit: state.maxDigit,
        onDigit: (digit) {
          emitVerb(BoardVerb.place);
          notifier.enter(digit);
        },
        onErase: () {
          emitVerb(BoardVerb.select);
          notifier.erase();
        },
      ),
    );
  }
}

/// The digits, then an eraser. The whole game is playable this way, which is
/// what a card in the feed needs.
class _SeismicPad extends StatelessWidget {
  const _SeismicPad({
    required this.maxDigit,
    required this.onDigit,
    required this.onErase,
  });

  final int maxDigit;
  final ValueChanged<int> onDigit;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: DesignSystem.spaceSM,
      runSpacing: DesignSystem.spaceSM,
      children: [
        for (var digit = 1; digit <= maxDigit; digit++)
          TangibleButton(
            color: scheme.surface,
            shadowColor: scheme.outline,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSystem.spaceMD,
              vertical: DesignSystem.spaceXS,
            ),
            onTap: () => onDigit(digit),
            child: Text(
              '$digit',
              style: TextStyle(
                fontSize: DesignSystem.fontSizeLG,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
          ),
        TangibleButton(
          color: scheme.surface,
          shadowColor: scheme.outline,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignSystem.spaceMD,
            vertical: DesignSystem.spaceXS,
          ),
          onTap: onErase,
          child: Icon(
            Icons.backspace_rounded,
            size: 18,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
