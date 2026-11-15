import 'package:flutter/material.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/design_system.dart';

import 'clusters_screen.dart';

final clustersMetadata = GameMetadata(
  id: 'clusters',
  category: 'LOGIC',
  icon: Icons.grid_on_rounded,
  color: DesignSystem.gameGreen,
  builder: (context) => const ClustersScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.default_,
);

String _title(BuildContext context) =>
    AppLocalizations.of(context)!.clustersTitle;
String _subtitle(BuildContext context) =>
    AppLocalizations.of(context)!.clustersSubtitle;
