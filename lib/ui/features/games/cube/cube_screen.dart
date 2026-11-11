import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../widgets/game_hud.dart';
import '../../../../widgets/tangible.dart';
import '../../../core/board/board_verb.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../../../core/juice/game_scaffold.dart';
import 'cube_board.dart';
import 'cube_engine.dart';
import 'cube_provider.dart';

class CubeScreen extends ConsumerWidget {
  const CubeScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    CubeNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('cube', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.cubeWinTitle,
        message: l10n.cubeWinMessage,
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
    final state = ref.watch(cubeNotifierProvider);
    final notifier = ref.read(cubeNotifierProvider.notifier);

    return GameScaffold(
      title: l10n.cubeTitle,
      subtitle: l10n.cubeSubtitle,
      actions: [
        TangibleButton(
          color: Theme.of(context).colorScheme.surface,
          shadowColor: Theme.of(context).colorScheme.outline,
          onTap: () {
            emitVerb(BoardVerb.select);
            notifier.hint();
          },
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.lightbulb_outline_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        TangibleButton(
          color: Theme.of(context).colorScheme.surface,
          shadowColor: Theme.of(context).colorScheme.outline,
          onTap: () {
            emitVerb(BoardVerb.select);
            notifier.newGame();
          },
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.refresh_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
      body: Column(
        children: [
          _DifficultyRow(
            selected: state.difficulty,
            onSelected: (difficulty) {
              emitVerb(BoardVerb.select);
              notifier.setDifficulty(difficulty);
            },
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
            child: GameHud(
              children: [
                _Stat(
                  label: l10n.cubeFaces.toUpperCase(),
                  value: '${state.position.paintedFaces}/6',
                  color: DesignSystem.primary,
                ),
                _Stat(
                  label: l10n.cubeMoves.toUpperCase(),
                  value: '${state.moves}/${state.puzzle.minMoves}',
                  color: DesignSystem.gameIndigo,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: PuzzleBoardView<CubeState>(
                board: CubeBoard(state: state),
                onMove: (move) {
                  // The board works out which way the cube is rolling; the
                  // screen only needs the source and the square it landed on.
                  final from = move.source.a * state.cols + move.source.b;
                  final target = move.target;
                  if (target == null) return;
                  final to = target.a * state.cols + target.b;
                  final direction = _direction(from, to, state.cols);
                  if (direction != null) notifier.roll(direction);
                },
                onSolved: () => _onSolved(context, ref, notifier),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

CubeDirection? _direction(int from, int to, int cols) {
  if (to == from - cols) return CubeDirection.north;
  if (to == from + cols) return CubeDirection.south;
  if (to == from + 1) return CubeDirection.east;
  if (to == from - 1) return CubeDirection.west;
  return null;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TangibleContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: DesignSystem.fontSizeXS,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: DesignSystem.fontSizeMD,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.selected, required this.onSelected});

  final CubeDifficulty selected;
  final ValueChanged<CubeDifficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      CubeDifficulty.easy: l10n.difficultyEasy,
      CubeDifficulty.medium: l10n.difficultyMedium,
      CubeDifficulty.hard: l10n.difficultyHard,
    };

    return Padding(
      padding: const EdgeInsets.only(
        top: DesignSystem.spaceSM,
        bottom: DesignSystem.spaceSM,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          for (final difficulty in CubeDifficulty.values)
            TangibleButton(
              color: difficulty == selected
                  ? DesignSystem.primary
                  : Theme.of(context).colorScheme.surface,
              shadowColor: Theme.of(context).colorScheme.outline,
              depth: difficulty == selected ? 2 : 3,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignSystem.spaceMD,
                vertical: DesignSystem.spaceXS,
              ),
              onTap: () => onSelected(difficulty),
              child: Text(
                labels[difficulty]!,
                style: TextStyle(
                  fontSize: DesignSystem.fontSizeXS,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: difficulty == selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
