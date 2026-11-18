import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/games/base_shift/base_shift_provider.dart';
import 'package:puzzle/ui/features/games/binary_code/binary_code_screen.dart';
import 'package:puzzle/ui/features/games/calculation_sprint/calculation_sprint_provider.dart';
import 'package:puzzle/ui/features/games/countdown_math/countdown_math_screen.dart';
import 'package:puzzle/ui/features/games/definition_dash/definition_dash_provider.dart';
import 'package:puzzle/ui/features/games/factor_finder/factor_finder_provider.dart';
import 'package:puzzle/ui/features/games/homophone_hunt/homophone_hunt_provider.dart';
import 'package:puzzle/ui/features/games/mirror_maze/mirror_maze_screen.dart';
import 'package:puzzle/ui/features/games/modulo_clock/modulo_clock_screen.dart';
import 'package:puzzle/ui/features/games/oxymoron_hunt/oxymoron_hunt_provider.dart';
import 'package:puzzle/ui/features/games/portmanteau_split/portmanteau_split_provider.dart';
import 'package:puzzle/ui/features/games/roman_arithmetic/roman_arithmetic_provider.dart';
import 'package:puzzle/ui/features/games/sentence_unscramble/sentence_unscramble_provider.dart';
import 'package:puzzle/ui/features/games/syllable_stack/syllable_stack_provider.dart';
import 'package:puzzle/ui/features/games/tangram/tangram_screen.dart';
import 'package:puzzle/ui/features/games/topology/topology_provider.dart';
import 'package:puzzle/ui/features/games/verbal_analogies/verbal_analogies_provider.dart';
import 'package:puzzle/ui/features/games/word_surge/word_surge_provider.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/tangible.dart';

class _FakeUserRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}

  @override
  List<GameStreak> getAllGameStreaks() => const [];

  @override
  Future<void> saveGameCompletion(UserData data, GameStreak streak) async {}
}

Future<void> _pumpScreen(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
      ],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('BinaryCodeScreen updates score immediately on option tap', (tester) async {
    await _pumpScreen(tester, const BinaryCodeScreen());
    final buttons = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(TangibleButton),
    );
    expect(buttons, findsNWidgets(4));

    final beforeBinary = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((s) => RegExp(r'^[01]{4}$').hasMatch(s));
    final decimal = int.parse(beforeBinary, radix: 2);

    await tester.tap(find.widgetWithText(TangibleButton, '$decimal'));
    await tester.pump();
    // Next frame immediately reflects updated progress (1 / 10), not stale.
    expect(find.textContaining('1 / 10'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('ModuloClockScreen updates score immediately on option tap', (tester) async {
    await _pumpScreen(tester, const ModuloClockScreen());
    final buttons = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(TangibleButton),
    );
    expect(buttons, findsNWidgets(4));

    final allTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .toList();
    final startText = allTexts.firstWhere((s) => s.startsWith('START TIME: '));
    final addText = allTexts.firstWhere((s) => s.startsWith('+ ') && s.endsWith(' HOURS'));
    final start = int.parse(RegExp(r'(\d+):00').firstMatch(startText)!.group(1)!);
    final add = int.parse(RegExp(r'\+\s*(\d+)\s*HOURS').firstMatch(addText)!.group(1)!);
    var answer = (start + add) % 12;
    if (answer == 0) answer = 12;

    await tester.tap(find.widgetWithText(TangibleButton, '$answer:00'));
    await tester.pump();
    expect(find.textContaining('1 / 10'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('CountdownMathScreen supports Undo and Reset without changing target', (tester) async {
    await _pumpScreen(tester, const CountdownMathScreen());
    final undoIcon = find.byIcon(Icons.undo_rounded);
    final resetIcon = find.byIcon(Icons.restart_alt_rounded);
    expect(undoIcon, findsOneWidget);
    expect(resetIcon, findsOneWidget);

    // Combine first two numbers using '+'.
    final numberWrap = find.byType(Wrap).last;
    final numberTiles = find.descendant(
      of: numberWrap,
      matching: find.byType(GestureDetector),
    );
    expect(numberTiles, findsNWidgets(5));

    await tester.tap(numberTiles.at(0));
    await tester.pump();
    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.tap(numberTiles.at(1));
    await tester.pump();

    expect(
      find.descendant(of: numberWrap, matching: find.byType(GestureDetector)),
      findsNWidgets(4),
    );

    await tester.tap(undoIcon);
    await tester.pump();
    expect(
      find.descendant(of: numberWrap, matching: find.byType(GestureDetector)),
      findsNWidgets(5),
    );

    // Perform op again then test Reset.
    await tester.tap(numberTiles.at(0));
    await tester.pump();
    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.tap(numberTiles.at(1));
    await tester.pump();
    expect(
      find.descendant(of: numberWrap, matching: find.byType(GestureDetector)),
      findsNWidgets(4),
    );

    await tester.tap(resetIcon);
    await tester.pump();
    expect(
      find.descendant(of: numberWrap, matching: find.byType(GestureDetector)),
      findsNWidgets(5),
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('MirrorMazeScreen and TangramScreen render procedural boards', (tester) async {
    await _pumpScreen(tester, const MirrorMazeScreen());
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.gps_fixed_rounded), findsOneWidget);

    await _pumpScreen(tester, const TangramScreen());
    expect(find.byType(GestureDetector), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  test('AutoDispose notifiers ignore pending Future.delayed after disposal', () async {
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
      ],
    );

    container.read(baseShiftNotifierProvider.notifier)
      ..initGame()
      ..submitAnswer('wrong');
    container.read(calculationSprintNotifierProvider.notifier)
      ..startGame()
      ..submitAnswer(-9999);
    container.read(definitionDashNotifierProvider.notifier)
      ..startGame()
      ..selectOption('nonexistent');
    container.read(factorFinderNotifierProvider.notifier)
      ..initGame()
      ..tapNumber(0);
    container.read(homophoneHuntNotifierProvider.notifier)
      ..startGame()
      ..checkAnswer('wrong');
    container.read(oxymoronHuntNotifierProvider.notifier).startGame();
    container.read(portmanteauSplitNotifierProvider.notifier).startGame();
    container.read(romanArithmeticNotifierProvider.notifier)
      ..startGame()
      ..submitAnswer(-9999);
    container.read(sentenceUnscrambleNotifierProvider.notifier).startGame();
    container.read(syllableStackNotifierProvider.notifier).startGame();
    container.read(topologyNotifierProvider.notifier)
      ..initGame()
      ..submitAnswer(false);
    container.read(verbalAnalogiesNotifierProvider.notifier)
      ..initGame()
      ..selectOption('wrong');
    container.read(wordSurgeNotifierProvider.notifier)
      ..initGame()
      ..selectOption('wrong');

    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  });
}
