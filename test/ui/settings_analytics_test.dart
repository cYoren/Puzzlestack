import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    final LocalizationsDelegate<AppLocalizations> delegate =
        AppLocalizations.delegate;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(_FakeRepository()),
          analyticsConsentProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
          theme: DesignSystem.lightTheme,
          localizationsDelegates: [
            delegate,
            ...AppLocalizations.localizationsDelegates
                .where((LocalizationsDelegate<dynamic> d) => d != delegate),
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder switchFinder =
        find.byType(Switch).last; // the usage row is the last toggle
    expect(switchFinder, findsOneWidget);

    final BuildContext context = tester.element(switchFinder);
    final String label = AppLocalizations.of(context)!.shareUsageData;
    expect(find.text(label), findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
