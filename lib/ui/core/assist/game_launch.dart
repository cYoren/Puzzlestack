import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_guides.dart';
import '../../../data/game_metadata.dart';
import '../../../data/picks/pick_gate.dart';
import '../../../data/repositories/game_stats_repository.dart';
import '../../../providers/pick_providers.dart';
import '../../../utils/navigation_utils.dart';
import '../../../widgets/game_guide_screen.dart';
import '../../features/plus/plus_sheet.dart';
import '../juice/game_scope.dart';

/// Opens a game, asking the pick gate first and the rules second.
///
/// Every surface that opens a game from the Stack — a room, a search result,
/// the home screen — goes through here, which is what makes "three picks a day"
/// one rule instead of one per screen. The Deal never calls this: a dealt card
/// is free and always was.
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
  final PickDecision decision =
      await ref.read(pickGateProvider).request(game.id);
  if (!context.mounted) return;

  if (decision is PickRefused) {
    // The board is opened first, so the sheet sits over the game the player is
    // being asked to pay for rather than over a list. Declining closes it
    // again; there is no lock on the tile and nothing is lost.
    _open(context, game);
    final bool bought = await showPlusSheet(context);
    if (!context.mounted || bought) return;
    Navigator.of(context).maybePop();
    return;
  }

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
  _open(context, game);
}

/// The game itself. The id travels with the page: four games share a localised
/// title, and a screen that resolves to the wrong registry entry gets the wrong
/// guide, the wrong assists, and a clock that `completeGame` can never stop.
void _open(BuildContext context, GameMetadata game) {
  Navigator.push(
    context,
    CustomPageRoute(
      page: GameScope(gameId: game.id, child: game.builder(context)),
    ),
  );
}
