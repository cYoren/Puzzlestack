import 'package:flutter/material.dart';

import '../../../../utils/design_system.dart';
import '../../../../widgets/game_hud.dart';
import '../../../../widgets/tangible.dart';
import '../../../core/board/board_verb.dart';
import '../../../core/juice/game_scaffold.dart';

/// The chrome every board game shares: title, actions, one stat strip, an
/// optional chip row, the board, and nothing else.
///
/// Two hundred game screens each assembled this by hand out of a `Column`, a
/// `Padding`, a `GameHud` and a `ConstrainedBox`, with the paddings copied from
/// whichever screen was written first. That is not a design; it is 200 chances
/// to drift. A screen now supplies what is actually *this game's* and the shell
/// decides spacing, board width, safe-area behaviour and chrome.
///
/// It is a plain widget, not a provider consumer: the screen owns its state and
/// hands the finished board in. That keeps the scaffold usable by a card in the
/// feed and by the Stack without a second seam.
class BoardGameScaffold extends StatelessWidget {
  const BoardGameScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.board,
    this.actions = const [],
    this.hud = const [],
    this.toolbar,
    this.footer,
    this.maxBoardWidth = 460,
  });

  final String title;
  final String subtitle;

  /// The board widget, already built and wired by the screen.
  final Widget board;

  /// The buttons the shell renders at the top right.
  final List<Widget> actions;

  /// Stat chips, one per number worth showing.
  final List<Widget> hud;

  /// A chip row under the hud: size or difficulty.
  final Widget? toolbar;

  /// A chip row under the board.
  final Widget? footer;

  final double maxBoardWidth;

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: title,
      subtitle: subtitle,
      actions: actions,
      body: Column(
        children: [
          if (toolbar != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: DesignSystem.spaceXS),
              child: toolbar,
            ),
          if (hud.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
              child: GameHud(children: hud),
            ),
          const Spacer(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBoardWidth),
              child: board,
            ),
          ),
          const Spacer(),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: DesignSystem.spaceSM),
              child: footer,
            ),
        ],
      ),
    );
  }
}

/// One number in the stat strip.
class GameStat extends StatelessWidget {
  const GameStat({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
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
              color: onSurface.withValues(alpha: 0.55),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: DesignSystem.fontSizeMD,
              fontWeight: FontWeight.w900,
              color: color ?? onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// One choice in a chip row: a difficulty, a board size.
class BoardGameChip extends StatelessWidget {
  const BoardGameChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return TangibleButton(
      color: selected
          ? DesignSystem.primary
          : Theme.of(context).colorScheme.surface,
      shadowColor: Theme.of(context).colorScheme.outline,
      depth: selected ? 2 : 3,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSystem.spaceMD,
        vertical: DesignSystem.spaceXS,
      ),
      onTap: () {
        emitVerb(BoardVerb.select);
        onTap();
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: DesignSystem.fontSizeXS,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: selected ? Colors.white : onSurface,
        ),
      ),
    );
  }
}

/// A row of [BoardGameChip]s that wraps instead of overflowing at 320dp.
class BoardGameChipRow extends StatelessWidget {
  const BoardGameChipRow({super.key, required this.chips});

  final List<BoardGameChip> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: DesignSystem.spaceXS,
      children: chips,
    );
  }
}

/// The three buttons every board game has, in the order the shell expects.
class BoardGameActions extends StatelessWidget {
  const BoardGameActions({
    super.key,
    this.onHint,
    this.onReset,
    this.extra = const [],
  });

  final VoidCallback? onHint;
  final VoidCallback? onReset;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    Widget button(IconData icon, VoidCallback? tap) => TangibleButton(
          color: Theme.of(context).colorScheme.surface,
          shadowColor: Theme.of(context).colorScheme.outline,
          onTap: tap == null
              ? null
              : () {
                  emitVerb(BoardVerb.select);
                  tap();
                },
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 20, color: onSurface),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...extra,
        if (onHint != null) button(Icons.lightbulb_outline_rounded, onHint),
        if (onHint != null && onReset != null) const SizedBox(width: 8),
        if (onReset != null) button(Icons.refresh_rounded, onReset),
      ],
    );
  }
}
