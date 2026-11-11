import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/core/board/puzzle_board_view.dart';
import 'package:puzzle/ui/features/games/dominosa/dominosa_screen.dart';
import 'package:puzzle/ui/features/games/futoshiki/futoshiki_screen.dart';
import 'package:puzzle/ui/features/games/magnets/magnets_screen.dart';
import 'package:puzzle/ui/features/games/tents_and_trees/tents_and_trees_screen.dart';
import 'package:puzzle/ui/features/games/galaxies/galaxies_screen.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_screen.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_screen.dart';
import 'package:puzzle/ui/features/games/pegs/pegs_screen.dart';
import 'package:puzzle/ui/features/games/same_game/same_game_screen.dart';
import 'package:puzzle/ui/features/games/skyscrapers/skyscrapers_screen.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_screen.dart';
import 'package:puzzle/utils/design_system.dart';

/// Every game added in Phase 3, pumped at the sizes the gate names: a 320dp
/// phone and a tablet. A board that overflows or throws only shows up
/// once it is actually laid out.
class _FakeRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}
}

Widget _app(Widget child) => ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(_FakeRepository()),
      ],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        darkTheme: DesignSystem.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

final Finder _boardFinder =
    find.byWidgetPredicate((widget) => widget is PuzzleBoardView);

void _sizeTo(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width * 2, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

void main() {
  final screens = <String, Widget>{
    'Pegs': const PegsScreen(),
    'Twiddle': const TwiddleScreen(),
    'Galaxies': const GalaxiesScreen(),
    'Kurodoko': const KurodokoScreen(),
    'Same Game': const SameGameScreen(),
    'Lights Out': const LightsOutScreen(),
    'Skyscrapers': const SkyscrapersScreen(),
    'Futoshiki': const FutoshikiScreen(),
    'Dominosa': const DominosaScreen(),
    'Magnets': const MagnetsScreen(),
    'Tents & Trees': const TentsAndTreesScreen(),
  };

  for (final entry in screens.entries) {
    for (final width in [320.0, 800.0]) {
      testWidgets('${entry.key} lays out at ${width.toInt()}dp',
          (tester) async {
        _sizeTo(tester, width);

        await tester.pumpWidget(_app(entry.value));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(_boardFinder, findsOneWidget);
      });
    }
  }

  testWidgets('the difficulty buttons swap the board', (tester) async {
    _sizeTo(tester, 400);
    await tester.pumpWidget(_app(const PegsScreen()));
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(PegsScreen)),
    )!;

    expect(find.text(l10n.difficultyMedium), findsOneWidget);
    await tester.tap(find.text(l10n.difficultyHard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(_boardFinder, findsOneWidget);
  });
}
