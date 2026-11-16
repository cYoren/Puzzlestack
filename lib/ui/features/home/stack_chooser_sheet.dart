import 'package:flutter/material.dart';

import '../../../data/game_tiers.dart';
import '../../../utils/design_system.dart';
import '../../../widgets/deck.dart';

/// Whether opening [gameId] asks for a size first.
///
/// One question, asked in one place, so a game with a single size is opened the
/// way it always was and never sees a sheet with one option in it.
bool offersTierChoice(String gameId) => gameLadders.containsKey(gameId);

/// The size chooser, offered before the board.
///
/// Returns the tier the player chose, or null when they closed it without
/// choosing, in which case no game is opened and no pick is spent.
Future<GameTier?> showStackChooserSheet(
  BuildContext context, {
  required GameLadder ladder,
  required String gameTitle,
  required String currentTierId,
}) {
  return showModalBottomSheet<GameTier>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _StackChooserSheet(
      ladder: ladder,
      gameTitle: gameTitle,
      currentTierId: currentTierId,
    ),
  );
}

class _StackChooserSheet extends StatelessWidget {
  const _StackChooserSheet({
    required this.ladder,
    required this.gameTitle,
    required this.currentTierId,
  });

  final GameLadder ladder;
  final String gameTitle;
  final String currentTierId;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color muted = DesignSystem.muted(context);
    final Color accent = DesignSystem.accent(context);
    final Color hair = DesignSystem.hairline(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignSystem.spaceMD,
          0,
          DesignSystem.spaceMD,
          DesignSystem.spaceMD,
        ),
        child: DeckCard(
          padding: const EdgeInsets.fromLTRB(
            DesignSystem.spaceLG,
            DesignSystem.spaceLG,
            DesignSystem.spaceLG,
            DesignSystem.spaceSM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DeckMark(size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      gameTitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Bebas Neue',
                        fontSize: DesignSystem.fontSizeLG,
                        letterSpacing: 1.4,
                        height: 1,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignSystem.spaceMD),
              Text(
                'Choose a size',
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: DesignSystem.fontSize3XL,
                  height: 1,
                  letterSpacing: 0.4,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: DesignSystem.spaceSM),
              Text(
                'Bigger boards take longer and ask more of you. Puzzlestack '
                'remembers your pick for next time.',
                style: TextStyle(
                  fontSize: DesignSystem.fontSizeSM,
                  height: 1.45,
                  color: muted,
                ),
              ),
              const SizedBox(height: DesignSystem.spaceSM),
              for (int i = 0; i < ladder.tiers.length; i++)
                _tierRow(
                  context,
                  tier: ladder.tiers[i],
                  first: i == 0,
                  hair: hair,
                  accent: accent,
                  muted: muted,
                ),
              const SizedBox(height: DesignSystem.spaceXS),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Not now',
                    style: TextStyle(
                      fontSize: DesignSystem.fontSizeXS,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tierRow(
    BuildContext context, {
    required GameTier tier,
    required bool first,
    required Color hair,
    required Color accent,
    required Color muted,
  }) {
    final bool selected = tier.id == currentTierId;

    return InkWell(
      onTap: () => Navigator.of(context).pop(tier),
      child: Semantics(
        button: true,
        selected: selected,
        label: '${tier.label}, ${tier.detail}',
        child: Container(
          decoration: BoxDecoration(
            border:
                first ? null : Border(top: BorderSide(color: hair, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(vertical: DesignSystem.spaceMD),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.label,
                      style: TextStyle(
                        fontFamily: 'Bebas Neue',
                        fontSize: DesignSystem.fontSizeXL,
                        letterSpacing: 0.8,
                        height: 1,
                        color: selected
                            ? accent
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tier.detail,
                      style: TextStyle(
                        fontSize: DesignSystem.fontSizeXS,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 20, color: accent)
              else
                SizedBox(width: 20, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
