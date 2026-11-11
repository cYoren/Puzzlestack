/// Not a test: a measuring tool, run by hand.
///
///     flutter test test/board/game_audit.dart
///
/// It pumps every game in the registry at 320dp and counts the ones that
/// overflow or throw. The file is deliberately not named `_test.dart` so it
/// stays out of the suite: it reports a number rather than asserting one, and
/// the number is currently bad enough that a red suite would only say what this
/// already says. Run it after a batch of ports to see whether the count moved.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/utils/design_system.dart';

Widget _app(Widget child) => ProviderScope(
      overrides: [userRepositoryProvider.overrideWithValue(_FakeRepository())],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        darkTheme: DesignSystem.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

class _FakeRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}
}

void main() {
  testWidgets('how many games overflow 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final broken = <String>[];
    final threw = <String>[];
    var checked = 0;

    for (final meta in allGamesMetadata) {
      checked++;
      try {
        await tester.pumpWidget(_app(Builder(builder: (c) => meta.builder(c))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final error = tester.takeException();
        if (error != null) {
          final text = error.toString();
          if (text.contains('overflowed')) {
            broken.add(meta.id);
          } else {
            threw.add('${meta.id}: ${text.split('\n').first}');
          }
        }
      } catch (e) {
        threw.add('${meta.id}: ${e.toString().split('\n').first}');
      }
    }
    // ignore: avoid_print
    print('AUDIT checked=$checked overflow=${broken.length} threw=${threw.length}');
    // ignore: avoid_print
    print('AUDIT overflow: ${broken.join(", ")}');
    // ignore: avoid_print
    print('AUDIT threw: ${threw.map((t) => t.split(":").first).join(", ")}');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
