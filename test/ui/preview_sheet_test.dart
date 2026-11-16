import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/ui/core/preview/game_preview.dart';
import 'package:puzzle/utils/design_system.dart';

/// Renders every game's preview onto one image, so the motifs can be reviewed
/// with eyes instead of through code.
///
///   PREVIEW_SHEET=1 flutter test test/ui/preview_sheet_test.dart
///   open docs/previews/previews.png
///
/// Off in a normal run: it writes a file, and a suite should not.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('contact sheet of every visible preview', () async {
    if (Platform.environment['PREVIEW_SHEET'] != '1') {
      return;
    }

    const double cell = 104;
    const int columns = 6;
    const double pad = 24;
    final List<GameMetadata> games =
        GameCategories.library(includeArchived: true);
    final int rows = (games.length / columns).ceil();
    final double width = columns * cell + pad * 2;
    final double height = rows * (cell + 20) + pad * 2;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = DesignSystem.paper,
    );

    for (int i = 0; i < games.length; i++) {
      final GameMetadata game = games[i];
      final double x = pad + (i % columns) * cell;
      final double y = pad + (i ~/ columns) * (cell + 20);

      final GamePreviewPainter painter = GamePreviewPainter(
        kind: previewKindFor(game.id, game.category),
        seed: previewSeedFor(game.id),
        letter: game.id.substring(0, 1).toUpperCase(),
        ink: DesignSystem.cardInk,
        hair: DesignSystem.hair,
        signal: DesignSystem.primary,
        dimmed: GameCategories.isArchived(game.id),
      );
      canvas.save();
      canvas.translate(x, y);
      painter.paint(canvas, Size(cell - 12, cell - 12));
      canvas.restore();

      final TextPainter label = TextPainter(
        text: TextSpan(
          text: game.id,
          style: const TextStyle(
            fontSize: 9,
            height: 1.1,
            color: DesignSystem.cardMuted,
            fontFamily: 'Geist',
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: cell - 8);
      label.paint(canvas, Offset(x + 4, y + cell - 6));
    }

    final ui.Image image =
        await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? png =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final Directory out = Directory('docs/previews')
      ..createSync(recursive: true);
    final File file = File('${out.path}/previews.png');
    file.writeAsBytesSync(png!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote ${file.path} (${games.length} previews)');
  });
}
