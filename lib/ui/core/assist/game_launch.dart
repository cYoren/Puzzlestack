import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_guides.dart';
import '../../../data/game_metadata.dart';
import '../../../data/repositories/game_stats_repository.dart';
import '../../../utils/navigation_utils.dart';
import '../../../widgets/game_guide_screen.dart';

/// Opens a game, rules first if this is the first time.
///
/// "Show the rules first" has to happen before the game screen exists: a timed
/// game starts its clock in `initState`, so a guide painted on top of it would
/// cost the player time they never saw. The guide is therefore a page of its
/// own, and the game is built after it is dismissed.
Future<void> launchGame(
  BuildContext context,
  WidgetRef ref,
  GameMetadata game,
) async {
  final repository = GameStatsRepository.instance;
  final firstTime = repository.isReady && !repository.hasSeen(game.id);
  if (firstTime && gameGuides.containsKey(game.id)) {
    await repository.markSeen(game.id);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameGuideScreen(
          gameId: game.id,
          gameColor: game.color,
          withPlayButton: true,
        ),
      ),
    );
    if (!context.mounted) return;
  } else if (firstTime) {
    await repository.markSeen(game.id);
  }

  if (!context.mounted) return;
  Navigator.push(context, CustomPageRoute(page: game.builder(context)));
}
