import 'package:flutter/material.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/design_system.dart';

import 'salad_screen.dart';

final saladMetadata = GameMetadata(
  id: 'salad',
  category: 'LOGIC',
  icon: Icons.abc_rounded,
  color: DesignSystem.gameEmerald,
  builder: (context) => const SaladScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.default_,
);

String _title(BuildContext context) => AppLocalizations.of(context)!.saladTitle;
String _subtitle(BuildContext context) =>
    AppLocalizations.of(context)!.saladSubtitle;
