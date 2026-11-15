import 'package:flutter/material.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/design_system.dart';

import 'abcd_screen.dart';

final abcdMetadata = GameMetadata(
  id: 'abcd',
  category: 'LOGIC',
  icon: Icons.abc_rounded,
  color: DesignSystem.gameIndigo,
  builder: (context) => const AbcdScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.default_,
);

String _title(BuildContext context) => AppLocalizations.of(context)!.abcdTitle;
String _subtitle(BuildContext context) =>
    AppLocalizations.of(context)!.abcdSubtitle;
