import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'data/models/user_data.dart';
import 'data/models/game_streak.dart';
import 'data/repositories/game_stats_repository.dart';
import 'data/repositories/user_repository.dart';
import 'providers/user_providers.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'ui/features/main_shell/main_shell.dart';
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
      ],
      child: ErrorBoundary(
        child: MyApp(startGameId: startGameId),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key, this.startGameId});

  /// The puzzle the launch URL named, if any (`lib/utils/deep_link.dart`).
  final String? startGameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        ...AppLocalizations.supportedLocales
            .where((l) => l.languageCode != 'en'),
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
      home: MainShell(startGameId: startGameId),
    );
  }
}
