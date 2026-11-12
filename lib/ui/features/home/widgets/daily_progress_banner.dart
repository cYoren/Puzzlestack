import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/game_providers.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/deck.dart';

class DailyProgressBanner extends ConsumerWidget {
  const DailyProgressBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final solvedToday = ref.watch(solvedTodayCountProvider);

    final encouragement = switch (solvedToday) {
      0 => l10n.readyForWorkout,
      < 3 => l10n.greatStartKeepGoing,
      < 7 => l10n.onFireToday,
      _ => l10n.incredibleSolvingToday,
    };

    return DeckCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DesignSystem.hairline(context)),
            ),
            child: Center(
              child: DeckNumber(
                '$solvedToday',
                size: 24,
                color: solvedToday > 0
                    ? DesignSystem.accent(context)
                    : DesignSystem.muted(context),
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.solvedToday.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: DesignSystem.muted(context),
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  encouragement.toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 18.0,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
