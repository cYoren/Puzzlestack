import 'package:flutter/material.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/utils/design_system.dart';
import 'cube_screen.dart';

final cubeMetadata = GameMetadata(
  id: 'cube',
  category: 'LOGIC',
  icon: Icons.view_in_ar_rounded,
  color: DesignSystem.gameIndigo,
  builder: (context) => const CubeScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.low,
);

String _title(BuildContext context) => AppLocalizations.of(context)!.cubeTitle;
String _subtitle(BuildContext context) => AppLocalizations.of(context)!.cubeSubtitle;
