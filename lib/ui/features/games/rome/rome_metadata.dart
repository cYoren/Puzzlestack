import 'package:flutter/material.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/design_system.dart';

import 'rome_screen.dart';

final romeMetadata = GameMetadata(
  id: 'rome',
  category: 'LOGIC',
  icon: Icons.rotate_right_rounded,
  color: DesignSystem.gameAmber,
  builder: (context) => const RomeScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.default_,
);

String _title(BuildContext context) => AppLocalizations.of(context)!.romeTitle;
String _subtitle(BuildContext context) =>
    AppLocalizations.of(context)!.romeSubtitle;
