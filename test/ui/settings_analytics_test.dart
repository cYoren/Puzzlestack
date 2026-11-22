import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/core/posthog.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/settings/settings_screen.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/deck.dart';

/// The usage switch is the only way a player can stop the analytics module, so
/// it must exist in Settings and be wired to it.
class _FakeRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}
}

Widget _app() => ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(_FakeRepository()),
        analyticsConsentProvider.overrideWith((ref) => true),
      ],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    );

void main() {
  setUp(() async {
    // The theme and locale notifiers open their own Hive boxes.
    final Directory dir = await Directory.systemTemp.createTemp('puzzlestack');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('Settings offers the usage switch and flipping it turns it off',
      (tester) async {
    final PostHog saved = PostHog.instance;
    PostHog.instance = PostHog(apiKey: '');
    addTearDown(() => PostHog.instance = saved);

    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final String label =
        AppLocalizations.of(tester.element(find.byType(SettingsScreen)))!
            .shareUsageData;
    expect(find.text(label), findsOneWidget);

    final Finder row = find
        .ancestor(of: find.text(label), matching: find.byType(DeckCard))
        .first;
    final Finder switchFinder =
        find.descendant(of: row, matching: find.byType(Switch));
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    expect(PostHog.instance.consent, isFalse);
    expect(tester.takeException(), isNull);
  });
}
