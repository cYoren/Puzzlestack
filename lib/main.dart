import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:puzzle/l10n/app_localizations.dart';

import 'data/models/user_data.dart';
import 'data/models/game_streak.dart';
import 'data/key_value_store.dart';
import 'data/game_tiers.dart';
import 'data/picks/pick_ledger.dart';
import 'data/purchase/plus_store.dart';
import 'data/repositories/game_stats_repository.dart';
import 'data/repositories/user_repository.dart';
import 'providers/pick_providers.dart';
import 'providers/game_tier_provider.dart';
import 'providers/plus_providers.dart';
import 'providers/user_providers.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'ui/features/main_shell/main_shell.dart';
import 'core/posthog.dart';
import 'data/game_registry.dart';
import 'utils/deep_link.dart';
import 'utils/design_system.dart';
import 'widgets/error_boundary.dart';

/// Puzzlestack's own license, shown alongside the dependency licenses in the
/// in-app Licenses page. GPL-3.0 requires that a modified work carry notice of
/// the modification and preserve attribution to the original.
void registerAppLicense() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Puzzlestack'],
      'Puzzlestack\n'
      'Copyright (C) 2026 Gustavo Marcelino and the Puzzlestack authors\n'
      '\n'
      'This program is free software: you can redistribute it and/or modify '
      'it under the terms of the GNU General Public License as published by '
      'the Free Software Foundation, either version 3 of the License, or (at '
      'your option) any later version.\n'
      '\n'
      'This program is distributed in the hope that it will be useful, but '
      'WITHOUT ANY WARRANTY; without even the implied warranty of '
      'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU '
      'General Public License for more details.\n'
      '\n'
      'Puzzlestack is a modified derivative of "Puzzle" by Sidhant Khatkar '
      '(https://github.com/sidhant947/Puzzle), also licensed under GPL-3.0. '
      'Source for this version is available at '
      'https://github.com/cYoren/Puzzlestack.',
    );
  });
}

void main() async {
  final stopwatch = Stopwatch()..start();

  WidgetsFlutterBinding.ensureInitialized();

  registerAppLicense();

  // Usage analytics, before the first frame so the Settings switch reads its
  // saved value and the launch is counted once. Anonymous events only; a build
  // with an empty key, or a player who switched it off, sends nothing.
  // Bounded on purpose: analytics may never delay the first frame, and a step
  // that times out simply reports nothing (the module fails closed).
  await postHog
      .start(
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        locale:
            WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
      )
      .timeout(const Duration(seconds: 2), onTimeout: () {});

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(800, 600),
      center: true,
      title: "Puzzlestack",
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Performance monitoring
  if (kDebugMode) {
    FlutterError.onError = (details) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    };
  }

  await Hive.initFlutter();

  Hive.registerAdapter(UserDataAdapter());
  Hive.registerAdapter(GameStreakAdapter());

  final userRepository = UserRepository();
  await userRepository.init();

  // Per-game times and the first-play flag. Storage failure is not fatal: the
  // app falls back to a session without a memory.
  await GameStatsRepository.instance.init();

  // The Plus row. Opened before the first frame because the pick gate reads it
  // while a screen builds; a device whose storage will not open still runs,
  // with Plus off and nothing remembered.
  final KeyValueStore plusStore =
      await HiveKeyValueStore.open(PlusStore.boxName) ?? MemoryKeyValueStore();

  // Today's picks. The gate reads it before a screen builds, so it is opened
  // here; a device that cannot store anything gets three free picks every
  // launch rather than none.
  final KeyValueStore pickStore =
      await HiveKeyValueStore.open(PickLedger.boxName) ?? MemoryKeyValueStore();

  // The size last chosen per game. The rows share the stats box, which is
  // already open, so this reads synchronously while a board builds; a device
  // that cannot store anything still plays, at each game's default size.
  final GameTierStore gameTierStore = GameTierStore(
    await HiveKeyValueStore.open(GameTierStore.boxName) ??
        MemoryKeyValueStore(),
  );

  // Log app startup time
  stopwatch.stop();
  debugPrint('App startup time (sync): ${stopwatch.elapsedMilliseconds}ms');

  // A page on the website names one puzzle, so a browser launch can open on it
  // (`?game=nonogram`). On a phone `Uri.base` carries no query and this is null,
  // which is the same launch the app always had.
  final String? startGameId = gameIdFromUri(
    Uri.base,
    knownIds: allGamesMetadata.map((game) => game.id),
  );

  runApp(
    ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepository),
        plusStoreProvider.overrideWithValue(plusStore),
        pickStoreProvider.overrideWithValue(pickStore),
        gameTierStoreProvider.overrideWithValue(gameTierStore),
      ],
      child: ErrorBoundary(child: MyApp(startGameId: startGameId)),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key, this.startGameId});

  /// The puzzle the launch URL named, if any (`lib/utils/deep_link.dart`).
  final String? startGameId;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // After the first frame on purpose: the store check is a network call, and
    // the first card must never wait for it. The local row is already read, so
    // a purchase made yesterday works before this finishes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(plusProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appThemeMode = ref.watch(themeNotifierProvider);
    final appLocale = ref.watch(localeNotifierProvider);

    ThemeMode themeMode;
    switch (appThemeMode) {
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        themeMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
        break;
    }

    return MaterialApp(
      title: 'Puzzlestack',
      debugShowCheckedModeBanner: false,
      theme: DesignSystem.lightTheme,
      darkTheme: DesignSystem.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: appLocale,
      supportedLocales: [
        const Locale('en'),
        ...AppLocalizations.supportedLocales.where(
          (l) => l.languageCode != 'en',
        ),
      ],
      localeListResolutionCallback: (locales, supportedLocales) {
        if (locales != null) {
          for (var locale in locales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
          }
        }
        return const Locale('en');
      },
      home: MainShell(startGameId: widget.startGameId),
    );
  }
}
