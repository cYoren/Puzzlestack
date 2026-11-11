import 'package:flutter/material.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/utils/design_system.dart';
import 'map_screen.dart';

final mapMetadata = GameMetadata(
  id: 'map',
  category: 'LOGIC',
  icon: Icons.map_rounded,
  color: DesignSystem.gameGreen,
  builder: (context) => const MapScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.low,
);

String _title(BuildContext context) => AppLocalizations.of(context)!.mapTitle;
String _subtitle(BuildContext context) => AppLocalizations.of(context)!.mapSubtitle;
