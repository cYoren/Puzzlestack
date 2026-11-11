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
import 'skyscrapers_board.dart';
import 'skyscrapers_engine.dart';
import 'skyscrapers_provider.dart';

class SkyscrapersScreen extends ConsumerWidget {
  const SkyscrapersScreen({super.key});

  Future<void> _onSolved(
    BuildContext context,
    WidgetRef ref,
    SkyscrapersNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('skyscrapers', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.skyscrapersWinTitle,
        message: l10n.skyscrapersWinMessage,
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
    final state = ref.watch(skyscrapersNotifierProvider);
    final notifier = ref.read(skyscrapersNotifierProvider.notifier);

    return GameScaffold(
      title: l10n.skyscrapersTitle,
      subtitle: l10n.skyscrapersSubtitle,
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
                  label: l10n.skyscrapersClues.toUpperCase(),
                  value: '${state.puzzle.clueCount}',
                  color: DesignSystem.primary,
                ),
                _Stat(
                  label: l10n.skyscrapersFilled.toUpperCase(),
                  value:
                      '${state.values.where((v) => v != 0).length}/${state.n * state.n}',
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: PuzzleBoardView<SkyscrapersState>(
                board: SkyscrapersBoard(state: state),
                onMove: (move) {
                  notifier.select(move.source.a * state.n + move.source.b);
                },
                onSolved: () => _onSolved(context, ref, notifier),
              ),
            ),
          ),
          const Spacer(),
          _ValuePad(
            n: state.n,
            onValue: (value) {
              emitVerb(BoardVerb.place);
              notifier.enter(value);
            },
            onErase: () {
              emitVerb(BoardVerb.select);
              notifier.erase();
            },
          ),
          const SizedBox(height: DesignSystem.spaceMD),
        ],
      ),
    );
  }
}

class _ValuePad extends StatelessWidget {
  const _ValuePad({
    required this.n,
    required this.onValue,
    required this.onErase,
  });

  final int n;
  final ValueChanged<int> onValue;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: DesignSystem.spaceSM,
      runSpacing: DesignSystem.spaceSM,
      children: [
        for (var value = 1; value <= n; value++)
          TangibleButton(
            color: scheme.surface,
            shadowColor: scheme.outline,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSystem.spaceMD,
              vertical: DesignSystem.spaceXS,
            ),
            onTap: () => onValue(value),
            child: Text(
              '$value',
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

  final SkyscrapersDifficulty selected;
  final ValueChanged<SkyscrapersDifficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      SkyscrapersDifficulty.easy: l10n.difficultyEasy,
      SkyscrapersDifficulty.medium: l10n.difficultyMedium,
      SkyscrapersDifficulty.hard: l10n.difficultyHard,
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
          for (final difficulty in SkyscrapersDifficulty.values)
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
