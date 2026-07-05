// Automated store screenshots for PuzzleBox.
//
// Captures the discovery home plus a curated "hero set" of games, one PNG each.
// Raw PNGs are written by test_driver/integration_test.dart into screenshots/raw/.
// Run via tool/screenshots.sh (or the GitHub Actions workflow), then frame them
// with tool/frame_screenshots.py.
//
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_test.dart \
//     -d <device_id>
//
// Pick visually static games here; games with continuous animation never
// "settle" and would stall a pumpAndSettle (we use timed pumps instead).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

import 'package:puzzle/data/game_catalog.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/main.dart' show MyApp;
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/main_shell/main_shell.dart';
import 'package:puzzle/utils/navigation_utils.dart';

/// Curated hero set, in display order. Edit freely; unknown ids are skipped.
const List<String> kHeroGameIds = [
  'sudoku',
  'game_2048',
  'nonogram',
  'word_search',
  'crossword',
  'minesweeper',
  'kenken',
  'water_sort',
  'lights_out',
  'schulte_table',
];

Future<void> _settle(WidgetTester tester) async {
  // Timed pumps instead of pumpAndSettle, which can hang on animated screens.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _shoot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  // Android needs the surface converted to an image before each capture.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
  }
  await binding.takeScreenshot(name);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.initFlutter();
    // Registration throws if called twice; guard each adapter.
    try {
      Hive.registerAdapter(UserDataAdapter());
    } catch (_) {}
    try {
      Hive.registerAdapter(GameStreakAdapter());
    } catch (_) {}
  });

  testWidgets('capture PuzzleBox store screenshots', (tester) async {
    final repo = UserRepository();
    await repo.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [userRepositoryProvider.overrideWithValue(repo)],
        child: const MyApp(),
      ),
    );
    await _settle(tester);

    // 1. The discovery home.
    await _shoot(binding, tester, '00_home');

    // 2. Each hero game, pushed programmatically off the home navigator.
    final BuildContext context = tester.element(find.byType(MainShell));
    var index = 1;
    for (final id in kHeroGameIds) {
      final game = GameCatalog.find(id);
      if (game == null) continue;

      // ignore: use_build_context_synchronously
      Navigator.of(context).push(
        CustomPageRoute(page: game.buildScreen(context)),
      );
      await _settle(tester);

      final label = index.toString().padLeft(2, '0');
      await _shoot(binding, tester, '${label}_$id');

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
      await _settle(tester);
      index++;
    }
  });
}
