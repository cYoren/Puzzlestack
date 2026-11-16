import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_categories.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/core/preview/game_preview.dart';
import 'package:puzzle/ui/features/home/category_room_screen.dart';
import 'package:puzzle/utils/design_system.dart';

/// A room is a grid of game cards, and each card now carries a mini board. Two
/// things can break here and only here: a tile that overflows its cell at 320dp,
/// and the archive switch, which has to add the archived games without letting
/// them into a room the switch is off in.
class _FakeRepository extends UserRepository {
  _FakeRepository({this.showArchived = false});

  final bool showArchived;

  @override
  UserData getUserData() =>
      UserData.initial().copyWith(showArchivedGames: showArchived);

  @override
  Future<void> saveUserData(UserData data) async {}
}

Widget _app(String categoryId, {bool showArchived = false}) => ProviderScope(
      overrides: [
        userRepositoryProvider
            .overrideWithValue(_FakeRepository(showArchived: showArchived)),
      ],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CategoryRoomScreen(categoryId: categoryId),
      ),
    );

void _sizeTo(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width * 2, 1400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

void main() {
  for (final double width in [320, 360, 800]) {
    testWidgets('the Logic room lays out at ${width.toInt()}dp',
        (tester) async {
      _sizeTo(tester, width);
      await tester.pumpWidget(_app('LOGIC'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GameCardPreview), findsWidgets);

      // The grid is lazy: a tile that is one pixel too tall only throws once it
      // is built, so walk the whole room.
      for (int i = 0; i < 12; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'layout broke at scroll step $i, ${width.toInt()}dp');
      }
    });
  }

  testWidgets('the archive is not in a room until the switch is on',
      (tester) async {
    _sizeTo(tester, 400);
    await tester.pumpWidget(_app('MEMORY'));
    await tester.pumpAndSettle();

    final int playable = GameCategories.countIn('MEMORY');
    // Every visible game in the room is in the grid; no archived one is.
    expect(
      GameCategories.inCategory('MEMORY').length,
      playable,
    );
    expect(find.text('ARCHIVED'), findsNothing);
  });

  testWidgets('the switch adds archived games, labelled', (tester) async {
    _sizeTo(tester, 400);
    await tester.pumpWidget(_app('MEMORY', showArchived: true));
    await tester.pumpAndSettle();

    // Walk far enough to reach the archived block at the end of the room.
    for (int i = 0; i < 40; i++) {
      if (find.text('ARCHIVED').evaluate().isNotEmpty) break;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    expect(find.text('ARCHIVED'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
