import 'package:flutter/material.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/design_system.dart';

import 'galaxies_screen.dart';

final galaxiesMetadata = GameMetadata(
  id: 'galaxies',
  category: 'LOGIC',
  icon: Icons.blur_circular_rounded,
  color: DesignSystem.gamePurple,
  builder: (context) => const GalaxiesScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.high,
);

String _title(BuildContext context) =>
    AppLocalizations.of(context)!.galaxiesTitle;
String _subtitle(BuildContext context) =>
    AppLocalizations.of(context)!.galaxiesSubtitle;
