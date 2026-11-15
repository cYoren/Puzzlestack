import 'package:flutter/material.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/design_system.dart';

import 'seismic_screen.dart';

final seismicMetadata = GameMetadata(
  id: 'seismic',
  category: 'LOGIC',
  icon: Icons.waves_rounded,
  color: DesignSystem.gameIndigo,
  builder: (context) => const SeismicScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.default_,
);

String _title(BuildContext context) =>
    AppLocalizations.of(context)!.seismicTitle;
String _subtitle(BuildContext context) =>
    AppLocalizations.of(context)!.seismicSubtitle;
