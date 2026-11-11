import 'package:flutter/material.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/design_system.dart';

import 'same_game_screen.dart';

final sameGameMetadata = GameMetadata(
  id: 'same_game',
  category: 'LOGIC',
  icon: Icons.grid_view_rounded,
  color: DesignSystem.gameIndigo,
  builder: (context) => const SameGameScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.default_,
);

String _title(BuildContext context) => AppLocalizations.of(context)!.sameGameTitle;
String _subtitle(BuildContext context) =>
    AppLocalizations.of(context)!.sameGameSubtitle;
