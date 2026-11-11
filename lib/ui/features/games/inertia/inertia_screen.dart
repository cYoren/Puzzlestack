import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../utils/design_system.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../widgets/game_hud.dart';
import '../../../../widgets/tangible.dart';
import '../../../core/board/board_verb.dart';
import '../../../core/board/puzzle_board.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../../../core/juice/game_scaffold.dart';
import 'inertia_board.dart';
import 'inertia_engine.dart';
import 'inertia_provider.dart';

class InertiaScreen extends ConsumerWidget {
  const InertiaScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    InertiaNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('inertia', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.inertiaWinTitle,
        message: l10n.inertiaWinMessage,
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
    final state = ref.watch(inertiaNotifierProvider);
    final notifier = ref.read(inertiaNotifierProvider.notifier);

    return GameScaffold(
      title: l10n.inertiaTitle,
      subtitle: l10n.inertiaSubtitle,
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
                  label: l10n.inertiaGems.toUpperCase(),
                  value: '${state.puzzle.gemCount - _collected(state)}'
                      '/${state.puzzle.gemCount}',
                  color: DesignSystem.success,
                ),
                _Stat(
                  label: l10n.inertiaMoves.toUpperCase(),
                  value: '${state.moves}/${state.puzzle.minMoves}',
                  color: DesignSystem.gameTeal,
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
              child: PuzzleBoardView<InertiaState>(
                board: InertiaBoard(state: state),
                onMove: (move) {
                  final target = move.target;
                  if (target == null) return;
                  final direction = _directionFor(state, move.source, target);
                  if (direction != null) notifier.slide(direction);
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

int _collected(InertiaState state) {
  var count = 0;
  for (var i = 0; i < state.puzzle.gemCount; i++) {
    if (state.position.collected & (1 << i) != 0) count++;
  }
  return count;
}

/// The board's moves already name their landing square, so the direction is
/// whichever one lands there.
InertiaDirection? _directionFor(InertiaState state, ElementRef source, ElementRef target) {
  const engine = InertiaEngine();
  for (final direction in InertiaDirection.values) {
    if (engine.landing(state.puzzle, state.position, direction) ==
        target.a * state.cols + target.b) {
      return direction;
    }
  }
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

  final InertiaDifficulty selected;
  final ValueChanged<InertiaDifficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      InertiaDifficulty.easy: l10n.difficultyEasy,
      InertiaDifficulty.medium: l10n.difficultyMedium,
      InertiaDifficulty.hard: l10n.difficultyHard,
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
          for (final difficulty in InertiaDifficulty.values)
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
