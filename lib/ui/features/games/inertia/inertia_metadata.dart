import 'package:flutter/material.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/utils/design_system.dart';
import 'inertia_screen.dart';

final inertiaMetadata = GameMetadata(
  id: 'inertia',
  category: 'LOGIC',
  icon: Icons.sports_esports_rounded,
  color: DesignSystem.gameTeal,
  builder: (context) => const InertiaScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.low,
);

String _title(BuildContext context) => AppLocalizations.of(context)!.inertiaTitle;
String _subtitle(BuildContext context) => AppLocalizations.of(context)!.inertiaSubtitle;
