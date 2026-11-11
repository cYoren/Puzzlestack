import 'package:flutter/material.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/utils/design_system.dart';
import 'signpost_screen.dart';

final signpostMetadata = GameMetadata(
  id: 'signpost',
  category: 'LOGIC',
  icon: Icons.signpost_rounded,
  color: DesignSystem.gameViolet,
  builder: (context) => const SignpostScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.high,
);

String _title(BuildContext context) =>
    AppLocalizations.of(context)!.signpostTitle;
String _subtitle(BuildContext context) =>
    AppLocalizations.of(context)!.signpostSubtitle;
