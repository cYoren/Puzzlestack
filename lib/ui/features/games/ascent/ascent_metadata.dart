import 'package:flutter/material.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/design_system.dart';

import 'ascent_screen.dart';

final ascentMetadata = GameMetadata(
  id: 'ascent',
  category: 'LOGIC',
  icon: Icons.timeline_rounded,
  color: DesignSystem.gameBlue,
  builder: (context) => const AscentScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.default_,
);

String _title(BuildContext context) =>
    AppLocalizations.of(context)!.ascentTitle;
String _subtitle(BuildContext context) =>
    AppLocalizations.of(context)!.ascentSubtitle;
