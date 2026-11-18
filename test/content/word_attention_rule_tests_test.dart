import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/games/cognate_catch/cognate_catch_provider.dart';
import 'package:puzzle/ui/features/games/conundrum_anagram/conundrum_anagram_engine.dart';
import 'package:puzzle/ui/features/games/conundrum_anagram/conundrum_anagram_screen.dart';
import 'package:puzzle/ui/features/games/letter_grid_swapper/letter_grid_swapper_screen.dart';
import 'package:puzzle/ui/features/games/missing_vowels/missing_vowels_engine.dart';
import 'package:puzzle/ui/features/games/missing_vowels/missing_vowels_provider.dart';
import 'package:puzzle/ui/features/games/shell_game/shell_game_screen.dart';
import 'package:puzzle/ui/features/games/word_wheel/word_wheel_screen.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';

/// Missing rule tests for Word (5) and Attention (1) rooms (release gate G3).
void main() {
  group('conundrum_anagram', () {
    test(
        'every generated round preserves the 9-letter multiset of its solution',
        () {
      for (int seed = 0; seed < 20; seed++) {
        final ConundrumRound round =
            ConundrumAnagramEngine.generateRound(random: Random(seed));
        expect(round.solution.length, 9);
        expect(round.letterPool.length, 9);
        final List<String> poolSorted = List<String>.from(round.letterPool)
          ..sort();
        final List<String> solSorted = round.solution.split('')..sort();
        expect(poolSorted, solSorted,
            reason: 'scrambled pool must be a valid anagram of solution');
      }
    });

    testWidgets(
      'spelling the valid 9-letter solution scores; a wrong permutation is rejected',
      (tester) async {
        await _pump(tester, const ConundrumAnagramScreen());
        final List<String> pool = _conundrumPool(tester);
        expect(pool.length, 9);

        final String target = _conundrumSolutionFor(pool);
        // Build a wrong permutation by swapping two distinct letters.
        final List<int> rightOrder = _indicesForWord(pool, target);
        final List<int> wrongOrder = List<int>.from(rightOrder);
        final int swapWith =
            wrongOrder.firstWhere((int j) => pool[j] != pool[wrongOrder[0]]);
        final int pos = wrongOrder.indexOf(swapWith);
        final int tmp = wrongOrder[0];
        wrongOrder[0] = wrongOrder[pos];
        wrongOrder[pos] = tmp;

        for (final int idx in wrongOrder) {
          await _tapConundrumPoolTile(tester, idx);
        }
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.textContaining('0 / 5'), findsOneWidget,
            reason: 'wrong 9-letter permutation must not advance score');

        for (final int idx in rightOrder) {
          await _tapConundrumPoolTile(tester, idx);
        }
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.textContaining('1 / 5'), findsOneWidget,
            reason: 'valid 9-letter solution advances score');

        await _teardown(tester);
      },
    );
  });

  group('letter_grid_swapper', () {
    testWidgets(
      'non-adjacent taps do not swap; adjacent swaps that form the target rows solve the round',
      (tester) async {
        await _pump(tester, const LetterGridSwapperScreen());
        expect(find.text('Score: 0 / 3'), findsOneWidget);

        final Finder gridFinder = find.byType(GridView);
        final Finder tiles = find.descendant(
          of: gridFinder,
          matching: find.byType(GestureDetector),
        );
        expect(tiles, findsNWidgets(9));

        final List<String> initial = _readGridLetters(tester, tiles);
        // Indices 0 (top-left) and 8 (bottom-right) are non-adjacent: tapping
        // them must re-select rather than swap.
        _tapGesture(tester, tiles.at(0));
        await tester.pump();
        _tapGesture(tester, tiles.at(8));
        await tester.pump();
        expect(_readGridLetters(tester, tiles), initial,
            reason: 'non-adjacent tiles cannot swap');
        // Deselect index 8 before solving.
        _tapGesture(tester, tiles.at(8));
        await tester.pump();

        final String target = _readSwapperTarget(tester);
        final List<(int, int)> plan =
            _solveAdjacentSwaps(initial.join(), target)!;
        for (final (int a, int b) in plan) {
          _tapGesture(tester, tiles.at(a));
          await tester.pump();
          _tapGesture(tester, tiles.at(b));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.text('Score: 1 / 3'), findsOneWidget,
            reason: 'matching all three target rows solves the round');

        await _teardown(tester);
      },
    );
  });

  group('missing_vowels', () {
    test(
        'hideVowels strips only AEIOU, and submitting the valid target solves while a wrong word fails',
        () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final MissingVowelsEngine engine = MissingVowelsEngine();
      expect(engine.hideVowels('ORANGE'), '_R_NG_');
      expect(engine.checkGuess('orange', 'ORANGE'), isTrue);
      expect(engine.checkGuess('ORANGX', 'ORANGE'), isFalse);

      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(missingVowelsNotifierProvider, (_, __) {});
      addTearDown(sub.close);
      final MissingVowelsNotifier notifier =
          container.read(missingVowelsNotifierProvider.notifier);
      await notifier.initGame();
      final MissingVowelsState ready =
          container.read(missingVowelsNotifierProvider);
      expect(ready.targetWord.length, greaterThanOrEqualTo(5));
      expect(ready.hiddenWord.contains('_'), isTrue);

      // Build a wrong guess of equal length.
      final String wrongChar = ready.targetWord[0] == 'Z' ? 'Q' : 'Z';
      final String wrongGuess = wrongChar + ready.targetWord.substring(1);
      for (final String ch in wrongGuess.split('')) {
        notifier.onLetterPressed(ch);
      }
      notifier.submitGuess();
      expect(container.read(missingVowelsNotifierProvider).isGameWon, isFalse);
      expect(
          container.read(missingVowelsNotifierProvider).isInvalidGuess, isTrue);

      for (int i = 0; i < wrongGuess.length; i++) {
        notifier.onBackspace();
      }
      for (final String ch in ready.targetWord.split('')) {
        notifier.onLetterPressed(ch);
      }
      notifier.submitGuess();
      expect(container.read(missingVowelsNotifierProvider).isGameWon, isTrue);
      expect(container.read(missingVowelsNotifierProvider).isGameOver, isTrue);
    });
  });

  group('word_wheel', () {
    test(
        'every curated wheel is solvable, requires the central letter, and rejects outside letters',
        () {
      expect(WordWheelScreen.puzzles, isNotEmpty);
      for (final WordWheelPuzzle puzzle in WordWheelScreen.puzzles) {
        expect(puzzle.letters.length, 7);
        expect(puzzle.letters.toSet().length, 7);
        expect(puzzle.letters.contains(puzzle.centralLetter), isTrue);
        expect(WordWheelScreen.isWordValid(puzzle, puzzle.pangram), isTrue,
            reason: '${puzzle.pangram} must be valid in its own wheel');

        // Strip central letter -> always invalid even if in dictionary.
        final String withoutCenter = puzzle.letters
            .where((String c) => c != puzzle.centralLetter)
            .take(4)
            .join();
        expect(
          WordWheelScreen.isWordValid(
            puzzle,
            withoutCenter,
            <String>{withoutCenter},
          ),
          isFalse,
          reason: 'a word missing the central letter must be rejected',
        );

        // Outside letter -> rejected.
        expect(
          WordWheelScreen.isWordValid(
            puzzle,
            '${puzzle.centralLetter}ZZZ',
            <String>{'${puzzle.centralLetter}ZZZ'},
          ),
          isFalse,
        );
      }
    });
  });

  group('cognate_catch', () {
    test(
        'selecting the true cognate verdict wins; selecting the opposite loses',
        () {
      final ProviderContainer winContainer = ProviderContainer();
      addTearDown(winContainer.dispose);
      final CognateCatchNotifier winNotifier =
          winContainer.read(cognateCatchNotifierProvider.notifier);
      winNotifier.initGame();
      final CognateCatchState task =
          winContainer.read(cognateCatchNotifierProvider);
      expect(task.word1, isNotEmpty);
      expect(task.word2, isNotEmpty);

      winNotifier.selectAnswer(task.isCognate);
      expect(
          winContainer.read(cognateCatchNotifierProvider).isGameOver, isTrue);
      expect(winContainer.read(cognateCatchNotifierProvider).isGameWon, isTrue,
          reason: 'matching the pair\'s cognate truth wins');

      final ProviderContainer loseContainer = ProviderContainer();
      addTearDown(loseContainer.dispose);
      final CognateCatchNotifier loseNotifier =
          loseContainer.read(cognateCatchNotifierProvider.notifier);
      loseNotifier.initGame();
      final CognateCatchState second =
          loseContainer.read(cognateCatchNotifierProvider);
      loseNotifier.selectAnswer(!second.isCognate);
      expect(
          loseContainer.read(cognateCatchNotifierProvider).isGameOver, isTrue);
      expect(
          loseContainer.read(cognateCatchNotifierProvider).isGameWon, isFalse,
          reason: 'inverting the cognate verdict loses');
    });
  });

  group('shell_game', () {
    testWidgets(
      'after shuffling, picking the ball-carrying cup wins and picking an empty cup loses',
      (tester) async {
        await _pump(tester, const ShellGameScreen());
        final AppLocalizations l10n =
            AppLocalizations.of(tester.element(find.byType(ShellGameScreen)))!;

        await tester.tap(find.text(l10n.btnShuffleCups));
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();

        // Cup 0 always carries the ball; cup 1 is always empty.
        final Finder cups = find.descendant(
          of: find.byType(AnimatedPositioned),
          matching: find.byType(GestureDetector),
        );
        expect(cups, findsNWidgets(3));

        _tapGesture(tester, cups.at(1));
        await tester.pumpAndSettle();
        expect(find.byType(GameCompletionDialog), findsOneWidget);
        expect(find.text(l10n.loseMissedIt.toUpperCase()), findsOneWidget);

        // Play again and pick cup 0 to verify the winning branch.
        tester
            .widget<GameCompletionDialog>(find.byType(GameCompletionDialog))
            .onPlayAgain();
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.btnShuffleCups));
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();

        _tapGesture(tester, cups.at(0));
        await tester.pumpAndSettle();
        expect(find.byType(GameCompletionDialog), findsOneWidget);
        expect(find.text(l10n.winFoundIt.toUpperCase()), findsOneWidget);

        await _teardown(tester);
      },
    );
  });
}

List<String> _conundrumPool(WidgetTester tester) {
  // The letter pool renders 9 TangibleButtons below the answer slots.
  final Finder poolWrap = find.byType(Wrap).last;
  return tester
      .widgetList<Text>(
          find.descendant(of: poolWrap, matching: find.byType(Text)))
      .map((Text t) => t.data ?? '')
      .where((String s) => s.length == 1)
      .toList(growable: false);
}

String _conundrumSolutionFor(List<String> pool) {
  final String sortedPool = (List<String>.from(pool)..sort()).join();
  return ConundrumAnagramEngine.words.firstWhere(
    (String cand) => (cand.split('')..sort()).join() == sortedPool,
  );
}

List<int> _indicesForWord(List<String> pool, String target) {
  final Set<int> used = <int>{};
  final List<int> order = <int>[];
  for (final String ch in target.split('')) {
    final int idx = List<int>.generate(pool.length, (int i) => i)
        .firstWhere((int i) => !used.contains(i) && pool[i] == ch);
    used.add(idx);
    order.add(idx);
  }
  return order;
}

Future<void> _tapConundrumPoolTile(WidgetTester tester, int index) async {
  final Finder poolWrap = find.byType(Wrap).last;
  final Finder buttons = find.descendant(
    of: poolWrap,
    matching: find.byType(GestureDetector),
  );
  _tapGesture(tester, buttons.at(index));
  await tester.pump();
}

List<String> _readGridLetters(WidgetTester tester, Finder tiles) {
  return List<String>.generate(9, (int i) {
    final Text text = tester.widget<Text>(
      find.descendant(of: tiles.at(i), matching: find.byType(Text)),
    );
    return text.data!;
  });
}

String _readSwapperTarget(WidgetTester tester) {
  final String raw = tester
      .widgetList<Text>(find.byType(Text))
      .map((Text t) => t.data ?? '')
      .firstWhere((String s) => s.contains('  •  '));
  return raw.split('  •  ').join();
}

List<(int, int)>? _solveAdjacentSwaps(String start, String goal) {
  if (start == goal) return const <(int, int)>[];
  const List<(int, int)> edges = <(int, int)>[
    (0, 1),
    (1, 2),
    (3, 4),
    (4, 5),
    (6, 7),
    (7, 8),
    (0, 3),
    (1, 4),
    (2, 5),
    (3, 6),
    (4, 7),
    (5, 8),
  ];
  final Queue<String> queue = Queue<String>()..add(start);
  final Map<String, (String prev, (int, int) move)> parent =
      <String, (String, (int, int))>{};
  final Set<String> seen = <String>{start};
  while (queue.isNotEmpty) {
    final String cur = queue.removeFirst();
    for (final (int a, int b) in edges) {
      final List<String> chars = cur.split('');
      final String tmp = chars[a];
      chars[a] = chars[b];
      chars[b] = tmp;
      final String next = chars.join();
      if (!seen.add(next)) continue;
      parent[next] = (cur, (a, b));
      if (next == goal) {
        final List<(int, int)> path = <(int, int)>[];
        String walk = goal;
        while (walk != start) {
          final (String prev, (int, int) move) = parent[walk]!;
          path.add(move);
          walk = prev;
        }
        return path.reversed.toList(growable: false);
      }
      queue.add(next);
    }
  }
  return null;
}

class _FakeRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}

  @override
  List<GameStreak> getAllGameStreaks() => const <GameStreak>[];

  @override
  Future<void> saveGameCompletion(UserData data, GameStreak streak) async {}
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        userRepositoryProvider.overrideWithValue(_FakeRepository()),
      ],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void _tapGesture(WidgetTester tester, Finder finder) {
  tester.widget<GestureDetector>(finder).onTap!();
}
