import 'package:flutter/material.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/design_system.dart';

import 'crossing_screen.dart';

final crossingMetadata = GameMetadata(
  id: 'crossing',
  category: 'LOGIC',
  icon: Icons.border_style_rounded,
  color: DesignSystem.gameCyan,
  builder: (context) => const CrossingScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.default_,
);

String _title(BuildContext context) =>
    AppLocalizations.of(context)!.crossingTitle;
String _subtitle(BuildContext context) =>
    AppLocalizations.of(context)!.crossingSubtitle;
