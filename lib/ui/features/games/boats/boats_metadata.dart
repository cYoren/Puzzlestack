import 'package:flutter/material.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/design_system.dart';

import 'boats_screen.dart';

final boatsMetadata = GameMetadata(
  id: 'boats',
  category: 'LOGIC',
  icon: Icons.sailing_rounded,
  color: DesignSystem.gameBlue,
  builder: (context) => const BoatsScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.default_,
);

String _title(BuildContext context) => AppLocalizations.of(context)!.boatsTitle;
String _subtitle(BuildContext context) =>
    AppLocalizations.of(context)!.boatsSubtitle;
