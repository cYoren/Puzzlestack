import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import '../../../../../providers/user_providers.dart';
import '../../../../../utils/haptic_feedback.dart';
import '../../../core/juice/game_scaffold.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../widgets/tangible.dart';
import '../../../../utils/design_system.dart';
import '../../../core/board/puzzle_board.dart';
import 'akari_provider.dart';

class AkariScreen extends ConsumerStatefulWidget {
  const AkariScreen({super.key});

  @override
  ConsumerState<AkariScreen> createState() => _AkariScreenState();
}

class _AkariScreenState extends ConsumerState<AkariScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(akariNotifierProvider.notifier).initGame();
    });
  }

  void _showCompletionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameCompletionDialog(
        title: l10n.akariWinTitle,
        message: l10n.akariWinMessage,
        isVictory: true,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onPlayAgain: () {
          Navigator.of(context).pop();
          ref.read(akariNotifierProvider.notifier).initGame();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(akariNotifierProvider);
    final notifier = ref.read(akariNotifierProvider.notifier);

    ref.listen(akariNotifierProvider, (previous, next) {
      if (next.isVictory && !(previous?.isVictory ?? false)) {
        HapticFeedbackUtil.victory();
        ref.read(gameStreakNotifierProvider.notifier).completeGame('akari');
        _showCompletionDialog();
      }
    });

    if (state.isLoading) {
      return GameScaffold(
        title: l10n.akariTitle,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GameScaffold(
      title: l10n.akariTitle,
      subtitle: l10n.akariSubtitle,
      actions: [
        TangibleButton(
          color: colorScheme.surface,
          shadowColor: colorScheme.outline,
          padding: const EdgeInsets.all(12),
          onTap: () {
            notifier.hint();
          },
          child: Icon(
            Icons.lightbulb_outline_rounded,
            color: colorScheme.onSurface,
            size: 20,
          ),
        ),
      ],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignSystem.spaceLG),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.onSurface, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                final cellSize = constraints.maxWidth / state.grid.length;
                return Column(
                  children: List.generate(state.grid.length, (r) {
                    return Row(
                      children: List.generate(state.grid.length, (c) {
                        return _buildCell(state, notifier, r, c, cellSize);
                      }),
                    );
                  }),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(AkariState state, AkariNotifier notifier, int r, int c, double size) {
    final l10n = AppLocalizations.of(context)!;
    final palette = PuzzlePalette.of(context);
    final val = state.grid[r][c];
    final isBulb = state.bulbs[r][c];
    final isLit = state.lit[r][c];
    final isBad = state.conflicts.contains(r * state.grid.length + c);

    if (val >= -1) {
      // Wall. `onSurface` is near-white in dark mode, which turned every wall
      // into a lamp; the palette's structure colour is a mid-tone in both
      // themes, so the grid reads without glaring.
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isBad ? DesignSystem.error : palette.structure,
          border: Border.all(color: palette.line, width: 0.5),
        ),
        child: val >= 0
            ? Center(
                child: Text(
                  val.toString(),
                  style: TextStyle(
                    color: palette.surface,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.42,
                  ),
                ),
              )
            : null,
      );
    }

    // White cell.
    return GestureDetector(
      onTap: () {
        notifier.toggleBulb(r, c);
        if (state.conflicts.contains(r * state.grid.length + c)) {
          HapticFeedbackUtil.error();
        }
      },
      onLongPress: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 3),
              content: Text(l10n.akariHowToPlay),
            ),
          );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isBad
              ? DesignSystem.error.withValues(alpha: 0.18)
              : isLit
                  ? DesignSystem.accentAmber.withValues(alpha: 0.22)
                  : palette.surface,
          border: Border.all(color: palette.line, width: 0.5),
        ),
        child: Center(
          child: isBulb
              ? Icon(
                  Icons.lightbulb,
                  color: isBad ? DesignSystem.error : DesignSystem.accentAmber,
                  size: size * 0.66,
                )
              : null,
        ),
      ),
    );
  }
}
