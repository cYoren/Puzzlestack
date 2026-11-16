import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/ui/core/preview/game_preview.dart';
import 'package:puzzle/utils/design_system.dart';

/// The game tiles used to carry an icon and a title, and forty icons repeat
/// across the catalogue. These tests hold the replacement to its promise: every
/// game in the registry resolves to a motif, every motif actually draws, the
/// drawing is the same on every launch, and the catalogue does not collapse onto
/// one picture.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<GameMetadata> visible = GameCategories.visible;

  Future<ui.Image> render(GameMetadata game, {double side = 72}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final GamePreviewPainter painter = GamePreviewPainter(
      kind: previewKindFor(game.id, game.category),
      seed: previewSeedFor(game.id),
      letter: game.id.substring(0, 1).toUpperCase(),
      ink: DesignSystem.cardInk,
      hair: DesignSystem.hair,
      signal: DesignSystem.primary,
    );
    painter.paint(canvas, Size(side, side));
    return recorder.endRecording().toImage(side.toInt(), side.toInt());
  }

  Future<List<int>> renderBytes(GameMetadata game) async {
    final ui.Image image = await render(game);
    final ByteData? data = await image.toByteData();
    image.dispose();
    return data!.buffer.asUint8List();
  }

  test('every game in the registry resolves to a motif', () {
    for (final GameMetadata game in allGamesMetadata) {
      final GamePreviewKind kind = previewKindFor(game.id, game.category);
      expect(kind, isA<GamePreviewKind>(), reason: game.id);
    }
  });

  test('the catalogue does not collapse onto one picture', () {
    final Set<GamePreviewKind> kinds = {
      for (final GameMetadata game in visible)
        previewKindFor(game.id, game.category),
    };
    expect(kinds.length, greaterThanOrEqualTo(8),
        reason: 'a tile that is always the same grid says nothing: $kinds');

    // Each room must be able to show more than one thing, or the room tile and
    // the game tiles inside it read as the same picture repeated. A room the catalog
    // has cut to one game (Memory, after `lab-hide` 2026-11-16) cannot, and is skipped.
    for (final CategoryInfo room in GameCategories.all) {
      final List<GameMetadata> inRoom =
          visible.where((g) => g.category == room.id).toList();
      if (inRoom.length < 2) continue;
      final Set<GamePreviewKind> roomKinds = {
        for (final GameMetadata game in inRoom)
          previewKindFor(game.id, game.category),
      };
      expect(roomKinds.length, greaterThanOrEqualTo(2),
          reason: '${room.id} draws only ${roomKinds.map((k) => k.name)}');
    }
  });

  test('every visible preview draws something, and never throws', () async {
    final List<String> blank = [];
    for (final GameMetadata game in visible) {
      final List<int> bytes = await renderBytes(game);
      // Transparent background, so an empty painting is all zeroes. A motif is
      // at least a few hairlines' worth of pixels.
      int painted = 0;
      for (int i = 3; i < bytes.length; i += 4) {
        if (bytes[i] != 0) painted++;
      }
      if (painted < 40) blank.add('${game.id} ($painted)');
    }
    expect(blank, isEmpty, reason: 'these previews are (nearly) blank: $blank');
  });

  test('the same game draws the same picture twice', () async {
    for (final String id in [
      'sudoku',
      'inertia',
      'word_ladder',
      'n_back',
      'quick_math',
    ]) {
      final GameMetadata game = allGamesMetadata.firstWhere((g) => g.id == id);
      expect(await renderBytes(game), await renderBytes(game), reason: id);
    }
  });

  test('two different games do not draw the same picture', () async {
    final GameMetadata a = allGamesMetadata.firstWhere((g) => g.id == 'sudoku');
    final GameMetadata b = allGamesMetadata.firstWhere((g) => g.id == 'kenken');
    expect(await renderBytes(a), isNot(await renderBytes(b)));
  });

  test('the seed is stable and the ids do not collide', () {
    // The layout comes from this number, so it has to be the same on every
    // launch and every device: FNV-1a over the id, nothing time-dependent.
    expect(previewSeedFor('sudoku'), previewSeedFor('sudoku'));
    final List<String> ids = visible.map((g) => g.id).toList();
    final Set<int> seeds = ids.map(previewSeedFor).toSet();
    expect(seeds.length, ids.length,
        reason: 'two games share a layout seed, so one is a copy of the other');
  });
}
