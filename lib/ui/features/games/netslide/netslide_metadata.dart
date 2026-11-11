import 'package:flutter/material.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/utils/design_system.dart';
import 'netslide_screen.dart';

final netslideMetadata = GameMetadata(
  id: 'netslide',
  category: 'LOGIC',
  icon: Icons.cable_rounded,
  color: DesignSystem.gameCyan,
  builder: (context) => const NetslideScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.low,
);

String _title(BuildContext context) => AppLocalizations.of(context)!.netslideTitle;
String _subtitle(BuildContext context) => AppLocalizations.of(context)!.netslideSubtitle;
