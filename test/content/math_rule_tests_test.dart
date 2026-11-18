import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/games/algebraic_balance/algebraic_balance_screen.dart';
import 'package:puzzle/ui/features/games/area_perimeter_match/area_perimeter_match_screen.dart';
import 'package:puzzle/ui/features/games/binary_code/binary_code_screen.dart';
import 'package:puzzle/ui/features/games/countdown_math/countdown_math_screen.dart';
import 'package:puzzle/ui/features/games/crypto_arithmetic/crypto_arithmetic_screen.dart';
import 'package:puzzle/ui/features/games/digit_swap_eq/digit_swap_eq_screen.dart';
import 'package:puzzle/ui/features/games/exponent_tower/exponent_tower_engine.dart';
import 'package:puzzle/ui/features/games/exponent_tower/exponent_tower_screen.dart';
import 'package:puzzle/ui/features/games/fractional_pizza/fractional_pizza_screen.dart';
import 'package:puzzle/ui/features/games/math_maze/math_maze_screen.dart';
import 'package:puzzle/ui/features/games/missing_operator/missing_operator_engine.dart';
import 'package:puzzle/ui/features/games/missing_operator/missing_operator_provider.dart';
import 'package:puzzle/ui/features/games/modulo_clock/modulo_clock_screen.dart';
import 'package:puzzle/ui/features/games/number_bonds/number_bonds_screen.dart';
import 'package:puzzle/ui/features/games/prime_factor_trees/prime_factor_trees_engine.dart';
import 'package:puzzle/ui/features/games/set_theory_venn/set_theory_venn_engine.dart';
import 'package:puzzle/ui/features/games/set_theory_venn/set_theory_venn_screen.dart';
import 'package:puzzle/ui/features/games/unit_converter_pro/unit_converter_pro_screen.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';
import 'package:puzzle/widgets/tangible.dart';

/// Rule tests for the 15 Math games previously missing coverage (Gate G3).
void main() {
  group('countdown_math', () {
    testWidgets(
      'rejects non-integer division and completes when operations reach the target',
      (tester) async {
        await _pump(tester, const CountdownMathScreen());

        // Refresh until target is not already in the initial 5 numbers (almost always true).
        for (var guard = 0; guard < 10; guard++) {
          final state = _readCountdownState(tester);
          if (!state.numbers.contains(state.target)) break;
          await tester.tap(find.byIcon(Icons.refresh_rounded));
          await tester.pumpAndSettle();
        }

        final initial = _readCountdownState(tester);
        expect(initial.numbers.length, 5);

        // Pick a small number (index 0, value 2..10) divided by the large number
        // (index 4, value 25/50/75/100): n1 % n2 != 0, so division must be rejected.
        _tapCountdownNumber(tester, 0);
        await tester.pump();
        _tapCountdownOperator(tester, '÷');
        await tester.pump();
        _tapCountdownNumber(tester, 4);
        await tester.pump();

        expect(
          _readCountdownState(tester).numbers.length,
          5,
          reason: 'non-exact division must not consume numbers',
        );

        // Clear selection by finding a valid step sequence to target and playing it.
        // Note: index 0 is still selected as _selectedNumIndex1 with operator '÷';
        // re-Refresh for a clean board and solve it to target.
        await tester.tap(find.byIcon(Icons.refresh_rounded));
        await tester.pumpAndSettle();

        List<_CountdownStep>? plan;
        for (var attempt = 0; attempt < 15; attempt++) {
          final cur = _readCountdownState(tester);
          if (cur.numbers.contains(cur.target)) {
            await tester.tap(find.byIcon(Icons.refresh_rounded));
            await tester.pumpAndSettle();
            continue;
          }
          plan = _solveCountdown(cur.numbers, cur.target);
          if (plan != null) break;
          await tester.tap(find.byIcon(Icons.refresh_rounded));
          await tester.pumpAndSettle();
        }
        expect(plan, isNotNull,
            reason: 'generated Countdown board must be solvable');

        for (final step in plan!) {
          _tapCountdownNumber(tester, step.i);
          await tester.pump();
          _tapCountdownOperator(tester, step.op);
          await tester.pump();
          _tapCountdownNumber(tester, step.j);
          await tester.pumpAndSettle();
        }

        expect(find.byType(GameCompletionDialog), findsOneWidget);
        await _teardown(tester);
      },
    );
  });

  group('crypto_arithmetic', () {
    testWidgets(
      'wrong digit does not score; unique digit satisfying the cryptarithm scores',
      (tester) async {
        await _pump(tester, const CryptoArithmeticScreen());
        expect(find.textContaining('0 / 5'), findsOneWidget);

        final firstAns = _solveCryptoScreen(tester);
        final firstOptions = _elevatedIntOptions(tester);
        final wrong = firstOptions.firstWhere((v) => v != firstAns);
        await tester.tap(find.widgetWithText(ElevatedButton, '$wrong'));
        await tester.pumpAndSettle();
        expect(find.textContaining('0 / 5'), findsOneWidget);

        final secondAns = _solveCryptoScreen(tester);
        await tester.tap(find.widgetWithText(ElevatedButton, '$secondAns'));
        await tester.pumpAndSettle();
        expect(find.textContaining('1 / 5'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });

  group('digit_swap_eq', () {
    testWidgets(
      'swapping the displaced pair restores both 2-digit sums and scores',
      (tester) async {
        await _pump(tester, const DigitSwapEqScreen());
        expect(find.text('Score: 0 / 5'), findsOneWidget);

        final digits = _readDigitSwapDigits(tester);
        expect(digits.length, 12);
        final eq1 = digits.sublist(0, 6);
        final eq2 = digits.sublist(6, 12);
        expect(_digitEqHolds(eq1), isFalse);
        expect(_digitEqHolds(eq2), isFalse);

        // Find a non-solving swap first, apply it, verify score stays 0, and undo it.
        (int, int)? wrongSwap;
        (int, int)? rightSwap;
        for (var i = 0; i < 6; i++) {
          for (var j = 0; j < 6; j++) {
            final a = List<int>.from(eq1);
            final b = List<int>.from(eq2);
            final tmp = a[i];
            a[i] = b[j];
            b[j] = tmp;
            if (_digitEqHolds(a) && _digitEqHolds(b)) {
              rightSwap ??= (i, j);
            } else {
              wrongSwap ??= (i, j);
            }
          }
        }
        expect(rightSwap, isNotNull,
            reason: 'every deal is one swap from two valid sums');

        if (wrongSwap != null) {
          _tapDigitSwapBox(tester, wrongSwap.$1);
          await tester.pump();
          _tapDigitSwapBox(tester, 6 + wrongSwap.$2);
          await tester.pump();
          expect(find.text('Score: 0 / 5'), findsOneWidget);

          // Swap back to restore initial state.
          _tapDigitSwapBox(tester, wrongSwap.$1);
          await tester.pump();
          _tapDigitSwapBox(tester, 6 + wrongSwap.$2);
          await tester.pump();
        }

        _tapDigitSwapBox(tester, rightSwap!.$1);
        await tester.pump();
        _tapDigitSwapBox(tester, 6 + rightSwap.$2);
        await tester.pumpAndSettle();
        expect(find.text('Score: 1 / 5'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });

  group('math_maze', () {
    testWidgets(
      'ignores non-adjacent cells, supports step undo, and scores on a valid target path',
      (tester) async {
        await _pump(tester, const MathMazeScreen());
        expect(find.text('0 / 3'), findsOneWidget);

        final maze = _readMathMaze(tester);
        final startVal = int.parse(maze.grid[0][0]);

        // Tapping non-adjacent (2, 2) from (0, 0) must be ignored.
        _tapMathMazeCell(tester, 2, 2);
        await tester.pump();
        expect(find.text('0 / 3'), findsOneWidget);

        // Tapping adjacent (0, 1) then tapping (0, 1) again undoes the step.
        _tapMathMazeCell(tester, 0, 1);
        await tester.pump();
        _tapMathMazeCell(tester, 0, 1);
        await tester.pump();
        expect(startVal, greaterThan(0));

        final path = _solveMathMaze(maze.grid, maze.target);
        expect(path, isNotNull,
            reason: 'generated 3x3 math maze must have a valid path');

        for (final step in path!.skip(1)) {
          _tapMathMazeCell(tester, step.x, step.y);
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.text('1 / 3'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });

  group('missing_operator', () {
    test('respects operator precedence and rejects non-integer division', () {
      final engine = MissingOperatorEngine();
      // 2 + 3 * 4 = 14 (PEMDAS), not (2 + 3) * 4 = 20.
      expect(engine.check([2, 3, 4], ['+', '*'], 14), isTrue);
      expect(engine.check([2, 3, 4], ['+', '*'], 20), isFalse);
      // Non-exact division 5 / 2 + 1 must fail.
      expect(engine.check([5, 2, 1], ['/', '+'], 3), isFalse);

      for (var i = 0; i < 25; i++) {
        final p = engine.generateProblem();
        expect(p.result, inInclusiveRange(0, 100));
        expect(engine.check(p.operands, p.operators, p.result), isTrue);
      }
    });

    test('notifier marks wrong and right operator pairs accurately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(missingOperatorNotifierProvider.notifier);
      notifier.initGame();
      final problem = container.read(missingOperatorNotifierProvider).problem!;

      const ops = ['+', '-', '*', '/'];
      List<String>? wrongPair;
      for (final a in ops) {
        for (final b in ops) {
          if (!MissingOperatorEngine()
              .check(problem.operands, [a, b], problem.result)) {
            wrongPair = [a, b];
            break;
          }
        }
        if (wrongPair != null) break;
      }
      expect(wrongPair, isNotNull);
      notifier.setOperator(0, wrongPair![0]);
      notifier.setOperator(1, wrongPair[1]);
      final afterWrong = container.read(missingOperatorNotifierProvider);
      expect(afterWrong.isGameOver, isTrue);
      expect(afterWrong.isLastAnswerCorrect, isFalse);
      expect(afterWrong.score, 0);

      notifier.initGame();
      final nextProblem =
          container.read(missingOperatorNotifierProvider).problem!;
      notifier.setOperator(0, nextProblem.operators[0]);
      notifier.setOperator(1, nextProblem.operators[1]);
      final afterRight = container.read(missingOperatorNotifierProvider);
      expect(afterRight.isGameOver, isTrue);
      expect(afterRight.isLastAnswerCorrect, isTrue);
      expect(afterRight.score, 1);
    });
  });

  group('number_bonds', () {
    testWidgets(
      'deducing the hidden hierarchical bond node advances score while wrong values fail',
      (tester) async {
        await _pump(tester, const NumberBondsScreen());
        expect(find.textContaining('0 / 5'), findsOneWidget);

        final firstAns = _solveNumberBonds(tester);
        final firstOpts = _elevatedIntOptions(tester);
        final wrong = firstOpts.firstWhere((v) => v != firstAns);
        await tester.tap(find.widgetWithText(ElevatedButton, '$wrong'));
        await tester.pumpAndSettle();
        expect(find.textContaining('0 / 5'), findsOneWidget);

        final secondAns = _solveNumberBonds(tester);
        await tester.tap(find.widgetWithText(ElevatedButton, '$secondAns'));
        await tester.pumpAndSettle();
        expect(find.textContaining('1 / 5'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });

  group('algebraic_balance', () {
    testWidgets(
      '3-symbol system has a unique solution in 2..7 and only that value scores',
      (tester) async {
        await _pump(tester, const AlgebraicBalanceScreen());
        expect(find.textContaining('0 / 5'), findsOneWidget);

        final firstAns = _solveAlgebraicBalance(tester);
        final firstOpts = _elevatedIntOptions(tester);
        final wrong = firstOpts.firstWhere((v) => v != firstAns);
        await tester.tap(find.widgetWithText(ElevatedButton, '$wrong'));
        await tester.pumpAndSettle();
        expect(find.textContaining('0 / 5'), findsOneWidget);

        final secondAns = _solveAlgebraicBalance(tester);
        await tester.tap(find.widgetWithText(ElevatedButton, '$secondAns'));
        await tester.pumpAndSettle();
        expect(find.textContaining('1 / 5'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });

  group('area_perimeter_match', () {
    testWidgets(
      'stepping width and height to match both area and perimeter scores',
      (tester) async {
        await _pump(tester, const AreaPerimeterMatchScreen());
        expect(find.text('0 / 5'), findsOneWidget);

        // If initial deal happened to be 2x2 (area 4, perimeter 8), refresh until it needs moves.
        for (var guard = 0; guard < 15; guard++) {
          final (area, perim) = _readAreaPerimeterTargets(tester);
          if (area != 4 || perim != 8) break;
          await tester.tap(find.byIcon(Icons.refresh_rounded));
          await tester.pumpAndSettle();
        }

        final (targetArea, targetPerim) = _readAreaPerimeterTargets(tester);
        int? goalW;
        int? goalH;
        for (var w = 2; w <= 7; w++) {
          for (var h = 2; h <= 7; h++) {
            if (w * h == targetArea && 2 * (w + h) == targetPerim) {
              goalW = w;
              goalH = h;
              break;
            }
          }
          if (goalW != null) break;
        }
        expect(goalW, isNotNull);

        // Step width to 1 (cannot match since targets use 2..7) -> score stays 0 / 5.
        final removeButtons = find.byIcon(Icons.remove_circle_outline_rounded);
        await tester.tap(removeButtons.first);
        await tester.pump();
        expect(find.text('0 / 5'), findsOneWidget);

        // Now step width from 1 up to goalW, and height from 2 up to goalH.
        final addButtons = find.byIcon(Icons.add_circle_outline_rounded);
        for (var w = 1; w < goalW!; w++) {
          await tester.tap(addButtons.first);
          await tester.pump();
        }
        for (var h = 2; h < goalH!; h++) {
          await tester.tap(addButtons.last);
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.text('1 / 5'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });

  group('binary_code', () {
    testWidgets(
      'wrong decimal choice does not increment translated count; matching 4-bit value does',
      (tester) async {
        await _pumpWithPeriodicTimer(tester, const BinaryCodeScreen());
        expect(find.text('TRANSLATED: 0 / 10'), findsOneWidget);

        final firstVal = _readBinaryTarget(tester);
        final firstOpts = _tangibleIntOptions(tester);
        final wrong = firstOpts.firstWhere((v) => v != firstVal);
        _tapTangibleText(tester, '$wrong');
        await tester.pump();
        expect(find.text('TRANSLATED: 0 / 10'), findsOneWidget);

        final secondVal = _readBinaryTarget(tester);
        _tapTangibleText(tester, '$secondVal');
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('TRANSLATED: 1 / 10'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });

  group('exponent_tower', () {
    test('generateRound deals distinct power values and sorts ascending', () {
      for (var seed = 0; seed < 25; seed++) {
        final round = ExponentTowerEngine.generateRound(
          count: 4,
          random: Random(seed),
        );
        expect(round.items.length, 4);
        final values = round.items.map((e) => e.value).toSet();
        expect(values.length, 4);
        for (var i = 0; i < round.sortedItems.length - 1; i++) {
          expect(
            round.sortedItems[i].value,
            lessThan(round.sortedItems[i + 1].value),
          );
        }
      }
    });

    testWidgets(
      'descending tower order is rejected; ascending order advances score',
      (tester) async {
        await _pump(tester, const ExponentTowerScreen());
        expect(find.text('0 / 8'), findsOneWidget);

        final items = _readExponentPool(tester);
        expect(items.length, 3);

        // Tap in descending order (largest first -> bottom of tower is largest -> fails).
        final desc = List<_PoolPower>.from(items)
          ..sort((a, b) => b.value.compareTo(a.value));
        for (final item in desc) {
          _tapExponentPoolItem(tester, item.base, item.exp);
          await tester.pump();
        }
        expect(find.text('0 / 8'), findsOneWidget);

        // Remove all 3 items from the tower so we can stack them smallest-to-largest.
        for (var k = 0; k < 3; k++) {
          final towerBlock = find.textContaining('#').first;
          final detector = find.ancestor(
            of: towerBlock,
            matching: find.byType(GestureDetector),
          );
          tester.widget<GestureDetector>(detector.first).onTap!();
          await tester.pump();
        }

        final asc = List<_PoolPower>.from(items)
          ..sort((a, b) => a.value.compareTo(b.value));
        for (final item in asc) {
          _tapExponentPoolItem(tester, item.base, item.exp);
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('1 / 8'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });

  group('fractional_pizza', () {
    testWidgets(
      'submitting wrong slice count fails; selecting exact simplified fraction slices scores',
      (tester) async {
        await _pump(tester, const FractionalPizzaScreen());
        expect(find.textContaining('0 / 5'), findsOneWidget);

        // Submit with 0 slices selected -> rejected (targetNum >= 1).
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!();
        await tester.pumpAndSettle();
        expect(find.textContaining('0 / 5'), findsOneWidget);

        final (num, den, totalSlices) = _readPizzaFraction(tester);
        final requiredSlices = (num * totalSlices) ~/ den;

        final pizzaFinder = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PizzaPainter,
        );
        final rect = tester.getRect(pizzaFinder);
        final center = rect.center;
        final r = rect.width * 0.3;

        for (var i = 0; i < requiredSlices; i++) {
          final angle = (i + 0.5) * (2 * pi / totalSlices);
          final pos =
              Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
          await tester.tapAt(pos);
          await tester.pump();
        }
        expect(
          find.text('Selected: $requiredSlices / $totalSlices slices'),
          findsOneWidget,
        );

        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!();
        await tester.pumpAndSettle();
        expect(find.textContaining('1 / 5'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });

  group('modulo_clock', () {
    testWidgets(
      'computes 12-hour wraparound accurately and rejects wrong hours',
      (tester) async {
        await _pumpWithPeriodicTimer(tester, const ModuloClockScreen());
        expect(find.text('SOLVED: 0 / 10'), findsOneWidget);

        final firstHour = _readModuloExpectedHour(tester);
        final firstOpts = _readModuloOptionHours(tester);
        final wrong = firstOpts.firstWhere((h) => h != firstHour);
        _tapTangibleText(tester, '$wrong:00');
        await tester.pump();
        expect(find.text('SOLVED: 0 / 10'), findsOneWidget);

        final secondHour = _readModuloExpectedHour(tester);
        _tapTangibleText(tester, '$secondHour:00');
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('SOLVED: 1 / 10'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });

  group('prime_factor_trees', () {
    test('rejects invalid factors and decomposes every root into prime leaves',
        () {
      for (final root in [24, 30, 36, 40, 45]) {
        final engine = PrimeFactorTreesEngine(random: Random(root));
        engine.generatePuzzle(root: root);
        expect(engine.isSolved(), isFalse);

        // Cannot overwrite already-solved root node 1, nor submit a non-divisor 13.
        expect(engine.submitAnswer(1, 2), isFalse);
        expect(engine.submitAnswer(2, 13), isFalse);

        // Solve every visible unsolved node using getValidFactors until complete.
        var safety = 0;
        while (!engine.isSolved() && safety < 20) {
          safety++;
          final nextNode = engine.treeNodes.values
              .firstWhere((n) => n.isVisible && !n.isSolved);
          final valid = engine.getValidFactors(nextNode.index);
          expect(valid, isNotEmpty,
              reason:
                  'root $root node ${nextNode.index} must have valid factor');
          expect(engine.submitAnswer(nextNode.index, valid.first), isTrue);
        }
        expect(engine.isSolved(), isTrue);

        // Product of all prime leaves in the solved tree equals root.
        var leafProduct = 1;
        for (final node in engine.treeNodes.values.where((n) => n.isVisible)) {
          final hasVisibleChildren =
              engine.treeNodes[node.index * 2]?.isVisible ?? false;
          if (!hasVisibleChildren) {
            expect(engine.isPrime(node.value), isTrue);
            leafProduct *= node.value;
          }
        }
        expect(leafProduct, root);
      }
    });
  });

  group('set_theory_venn', () {
    test('every formula template maps to exact set-theoretic regions', () {
      final seenFormulas = <String>{};
      for (var seed = 0; seed < 80; seed++) {
        final q = SetTheoryVennEngine.generateQuestion(random: Random(seed));
        seenFormulas.add(q.formula);
        expect(q.correctRegions, _expectedVennRegions(q.formula));
      }
      expect(seenFormulas.length, 8);
    });

    testWidgets(
      'wrong region selection fails; exact formula regions advance score',
      (tester) async {
        await _pump(tester, const SetTheoryVennScreen());
        expect(find.text('0 / 8'), findsOneWidget);

        // Empty selection is never valid (every template has >= 1 region).
        _tapTangibleText(tester, 'SUBMIT SELECTION');
        await tester.pump();
        expect(find.text('0 / 8'), findsOneWidget);

        final formula = _readVennFormula(tester);
        final regions = _expectedVennRegions(formula);
        for (final region in regions) {
          _toggleVennRegion(tester, region);
          await tester.pump();
        }
        _tapTangibleText(tester, 'SUBMIT SELECTION');
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('1 / 8'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });

  group('unit_converter_pro', () {
    testWidgets(
      'wrong conversion does not score; exact unit conversion advances score',
      (tester) async {
        await _pump(tester, const UnitConverterProScreen());
        expect(find.textContaining('0 / 5'), findsOneWidget);

        final firstAns = _solveUnitConversion(tester);
        final buttons = tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .toList();
        expect(buttons.length, 4);
        final wrongBtn = buttons.firstWhere((b) {
          final txt = (b.child as Text).data!;
          return int.parse(txt.split(' ').first) != firstAns;
        });
        wrongBtn.onPressed!();
        await tester.pumpAndSettle();
        expect(find.textContaining('0 / 5'), findsOneWidget);

        final secondAns = _solveUnitConversion(tester);
        final nextButtons = tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .toList();
        final rightBtn = nextButtons.firstWhere((b) {
          final txt = (b.child as Text).data!;
          return int.parse(txt.split(' ').first) == secondAns;
        });
        rightBtn.onPressed!();
        await tester.pumpAndSettle();
        expect(find.textContaining('1 / 5'), findsOneWidget);

        await _teardown(tester);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

Future<void> _pumpWithPeriodicTimer(WidgetTester tester, Widget child) async {
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
  await tester.pump();
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

class _CountdownStep {
  const _CountdownStep(this.i, this.op, this.j);
  final int i;
  final String op;
  final int j;
}

({int target, List<int> numbers}) _readCountdownState(WidgetTester tester) {
  final targetFinder = find.descendant(
    of: find.byType(TangibleContainer),
    matching: find.byWidgetPredicate(
      (w) => w is Text && w.style?.fontSize == 48,
    ),
  );
  final target = int.parse(tester.widget<Text>(targetFinder).data!);

  final circleBoxes = find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.constraints?.maxWidth == 70 &&
        w.constraints?.maxHeight == 70,
  );
  final numbers = <int>[];
  for (final element in circleBoxes.evaluate()) {
    final txt = find.descendant(
      of: find.byElementPredicate((e) => identical(e, element)),
      matching: find.byType(Text),
    );
    numbers.add(int.parse(tester.widget<Text>(txt).data!));
  }
  return (target: target, numbers: numbers);
}

void _tapCountdownNumber(WidgetTester tester, int index) {
  final circleBoxes = find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.constraints?.maxWidth == 70 &&
        w.constraints?.maxHeight == 70,
  );
  final detector = find.ancestor(
    of: circleBoxes.at(index),
    matching: find.byType(GestureDetector),
  );
  tester.widget<GestureDetector>(detector.first).onTap!();
}

void _tapCountdownOperator(WidgetTester tester, String op) {
  final opBoxes = find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.constraints?.maxWidth == 55 &&
        w.constraints?.maxHeight == 55,
  );
  for (final element in opBoxes.evaluate()) {
    final boxFinder = find.byElementPredicate((e) => identical(e, element));
    final txt = find.descendant(of: boxFinder, matching: find.byType(Text));
    if (tester.widget<Text>(txt).data == op) {
      final detector = find.ancestor(
        of: boxFinder,
        matching: find.byType(GestureDetector),
      );
      tester.widget<GestureDetector>(detector.first).onTap!();
      return;
    }
  }
  throw StateError('Operator $op not found');
}

List<_CountdownStep>? _solveCountdown(List<int> nums, int target) {
  if (nums.contains(target)) return const [];
  if (nums.length < 2) return null;

  const ops = ['+', '-', '×', '÷'];
  for (var i = 0; i < nums.length; i++) {
    for (var j = 0; j < nums.length; j++) {
      if (i == j) continue;
      final n1 = nums[i];
      final n2 = nums[j];
      for (final op in ops) {
        int res;
        switch (op) {
          case '+':
            res = n1 + n2;
          case '-':
            res = n1 - n2;
          case '×':
            res = n1 * n2;
          case '÷':
            if (n2 == 0 || n1 % n2 != 0) continue;
            res = n1 ~/ n2;
          default:
            continue;
        }
        final next = <int>[
          for (var k = 0; k < nums.length; k++)
            if (k != i && k != j) nums[k],
          res,
        ];
        if (res == target) return [_CountdownStep(i, op, j)];
        if (next.length >= 2) {
          final tail = _solveCountdown(next, target);
          if (tail != null) return [_CountdownStep(i, op, j), ...tail];
        }
      }
    }
  }
  return null;
}

List<int> _elevatedIntOptions(WidgetTester tester) {
  return tester
      .widgetList<ElevatedButton>(find.byType(ElevatedButton))
      .map((b) => int.parse((b.child as Text).data!))
      .toList();
}

int _solveCryptoScreen(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .toList();
  final eq = texts.firstWhere(
    (s) => RegExp(r'^[A-Z]{2,} \+ [A-Z]{2,} = [A-Z]{2,}$').hasMatch(s),
  );
  final solveLine = texts.firstWhere((s) => s.startsWith('Solve for: '));
  final targetLetter = solveLine.split('Solve for: ')[1].split(' ').first;

  // Read legend pairs: single uppercase letter followed by ' = ' followed by single digit.
  final legend = <String, int>{};
  for (var i = 0; i + 2 < texts.length; i++) {
    if (RegExp(r'^[A-Z]$').hasMatch(texts[i]) &&
        texts[i + 1] == ' = ' &&
        RegExp(r'^[0-9]$').hasMatch(texts[i + 2])) {
      legend[texts[i]] = int.parse(texts[i + 2]);
    }
  }

  final parts = eq.split(' = ');
  final left = parts[0].split(' + ');
  final w1 = left[0];
  final w2 = left[1];
  final wSum = parts[1];

  int decode(String word, int candidate) {
    final buf = StringBuffer();
    for (final ch in word.split('')) {
      buf.write(ch == targetLetter ? candidate : legend[ch]!);
    }
    return int.parse(buf.toString());
  }

  for (final cand in _elevatedIntOptions(tester)) {
    if (legend.values.contains(cand)) continue;
    if (cand == 0 &&
        (w1.startsWith(targetLetter) ||
            w2.startsWith(targetLetter) ||
            wSum.startsWith(targetLetter))) {
      continue;
    }
    if (decode(w1, cand) + decode(w2, cand) == decode(wSum, cand)) {
      return cand;
    }
  }
  throw StateError('No valid digit for $eq ($legend, target=$targetLetter)');
}

List<int> _readDigitSwapDigits(WidgetTester tester) {
  final boxes = find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.constraints?.maxWidth == 44 &&
        w.constraints?.maxHeight == 52,
  );
  final out = <int>[];
  for (final el in boxes.evaluate()) {
    final txt = find.descendant(
      of: find.byElementPredicate((e) => identical(e, el)),
      matching: find.byType(Text),
    );
    out.add(int.parse(tester.widget<Text>(txt).data!));
  }
  return out;
}

void _tapDigitSwapBox(WidgetTester tester, int flatIndex) {
  final boxes = find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.constraints?.maxWidth == 44 &&
        w.constraints?.maxHeight == 52,
  );
  final detector = find.ancestor(
    of: boxes.at(flatIndex),
    matching: find.byType(GestureDetector),
  );
  tester.widget<GestureDetector>(detector.first).onTap!();
}

bool _digitEqHolds(List<int> d) =>
    (d[0] * 10 + d[1]) + (d[2] * 10 + d[3]) == (d[4] * 10 + d[5]);

({List<List<String>> grid, int target}) _readMathMaze(WidgetTester tester) {
  final board = find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.constraints?.maxWidth == 300 &&
        w.constraints?.maxHeight == 300,
  );
  final positioned =
      find.descendant(of: board, matching: find.byType(Positioned));
  final cells = <String>[];
  for (final el in positioned.evaluate()) {
    final txt = find.descendant(
      of: find.byElementPredicate((e) => identical(e, el)),
      matching: find.byType(Text),
    );
    cells.add(tester.widget<Text>(txt).data!);
  }
  final grid =
      List.generate(3, (r) => List.generate(3, (c) => cells[r * 3 + c]));

  // Header shows target first, runningTotal second, both using gameOrange / primary.
  final orangeTarget = find.byWidgetPredicate(
    (w) => w is Text && w.style?.color == DesignSystem.gameOrange,
  );
  final target = int.parse(tester.widget<Text>(orangeTarget.first).data!);
  return (grid: grid, target: target);
}

void _tapMathMazeCell(WidgetTester tester, int r, int c) {
  final board = find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.constraints?.maxWidth == 300 &&
        w.constraints?.maxHeight == 300,
  );
  final positioned =
      find.descendant(of: board, matching: find.byType(Positioned));
  final detector = find.descendant(
    of: positioned.at(r * 3 + c),
    matching: find.byType(GestureDetector),
  );
  tester.widget<GestureDetector>(detector).onTap!();
}

List<Point<int>>? _solveMathMaze(List<List<String>> grid, int target) {
  int evalPath(List<Point<int>> path) {
    var total = int.parse(grid[0][0]);
    for (var i = 2; i < path.length; i += 2) {
      final op = grid[path[i - 1].x][path[i - 1].y];
      final val = int.parse(grid[path[i].x][path[i].y]);
      switch (op) {
        case '+':
          total += val;
        case '-':
          total -= val;
        case '*':
          total *= val;
      }
    }
    return total;
  }

  List<Point<int>>? dfs(List<Point<int>> path, Set<Point<int>> seen) {
    final cur = path.last;
    if (cur == const Point(2, 2)) {
      return evalPath(path) == target ? List.from(path) : null;
    }
    for (final (dx, dy) in const [(0, 1), (1, 0), (0, -1), (-1, 0)]) {
      final nx = cur.x + dx;
      final ny = cur.y + dy;
      if (nx < 0 || nx >= 3 || ny < 0 || ny >= 3) continue;
      final next = Point(nx, ny);
      if (seen.contains(next)) continue;
      seen.add(next);
      path.add(next);
      final res = dfs(path, seen);
      if (res != null) return res;
      path.removeLast();
      seen.remove(next);
    }
    return null;
  }

  return dfs([const Point(0, 0)], {const Point(0, 0)});
}

int _solveNumberBonds(WidgetTester tester) {
  final circles = find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.constraints?.maxWidth == 52 &&
        w.constraints?.maxHeight == 52,
  );
  final vals = <int?>[];
  for (final el in circles.evaluate()) {
    final txt = find.descendant(
      of: find.byElementPredicate((e) => identical(e, el)),
      matching: find.byType(Text),
    );
    final s = tester.widget<Text>(txt).data!;
    vals.add(s == '?' ? null : int.parse(s));
  }
  // Order in Stack: V(0), L(1), R(2), LL(3), LR(4), RL(5), RR(6).
  final v = vals[0];
  final l = vals[1];
  final r = vals[2];
  final ll = vals[3];
  final lr = vals[4];
  final rl = vals[5];
  final rr = vals[6];
  if (v == null) return l! + r!;
  if (l == null) return v - r!;
  if (r == null) return v - l;
  if (ll == null) return l - lr!;
  if (lr == null) return l - ll;
  if (rl == null) return r - rr!;
  return r - rl;
}

int _solveAlgebraicBalance(WidgetTester tester) {
  // Card holds 3 FittedBox rows:
  // Row 0: a * star + b * heart = eq1
  // Row 1: c * star + d * sun = eq2
  // Row 2: e * heart + f * sun = eq3
  final card = find.byType(Card);
  final eqRows = find.descendant(of: card, matching: find.byType(FittedBox));
  expect(eqRows, findsNWidgets(3));

  (int, int, int) parseRow(
      Finder rowFinder, IconData firstIcon, IconData secondIcon) {
    final texts = tester
        .widgetList<Text>(
            find.descendant(of: rowFinder, matching: find.byType(Text)))
        .map((t) => t.data ?? '')
        .toList();
    // Last text is ' = <rhs>'.
    final rhs = int.parse(texts.last.split('=').last.trim());
    // Remaining texts before ' + ' and after ' + ' hold optional coefficient > 1.
    final plusIdx = texts.indexOf(' + ');
    final leftCoeff = plusIdx > 0 ? int.parse(texts[0]) : 1;
    final rightHasCoeff = plusIdx + 1 < texts.length - 1;
    final rightCoeff = rightHasCoeff ? int.parse(texts[plusIdx + 1]) : 1;
    expect(find.descendant(of: rowFinder, matching: find.byIcon(firstIcon)),
        findsOneWidget);
    expect(find.descendant(of: rowFinder, matching: find.byIcon(secondIcon)),
        findsOneWidget);
    return (leftCoeff, rightCoeff, rhs);
  }

  final (a, b, eq1) =
      parseRow(eqRows.at(0), Icons.star_rounded, Icons.favorite_rounded);
  final (c, d, eq2) =
      parseRow(eqRows.at(1), Icons.star_rounded, Icons.wb_sunny_rounded);
  final (e, f, eq3) =
      parseRow(eqRows.at(2), Icons.favorite_rounded, Icons.wb_sunny_rounded);

  // Question icon has size == 40.
  final questionIcon = tester.widget<Icon>(
    find.byWidgetPredicate((w) => w is Icon && w.size == 40),
  );

  int? answer;
  var solutions = 0;
  for (var s = 2; s <= 7; s++) {
    for (var h = 2; h <= 7; h++) {
      if (a * s + b * h != eq1) continue;
      for (var u = 2; u <= 7; u++) {
        if (c * s + d * u == eq2 && e * h + f * u == eq3) {
          solutions++;
          if (questionIcon.icon == Icons.star_rounded) {
            answer = s;
          } else if (questionIcon.icon == Icons.favorite_rounded) {
            answer = h;
          } else {
            answer = u;
          }
        }
      }
    }
  }
  expect(solutions, 1,
      reason: 'AlgebraicBalance deal must have unique solution');
  return answer!;
}

(int, int) _readAreaPerimeterTargets(WidgetTester tester) {
  final orangeTexts = tester
      .widgetList<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && w.style?.color == DesignSystem.gameOrange,
        ),
      )
      .map((t) => int.parse(t.data!))
      .toList();
  return (orangeTexts[0], orangeTexts[1]);
}

int _readBinaryTarget(WidgetTester tester) {
  final txt = tester.widgetList<Text>(find.byType(Text)).firstWhere(
        (t) => RegExp(r'^[01]{4}$').hasMatch(t.data ?? ''),
      );
  return int.parse(txt.data!, radix: 2);
}

List<int> _tangibleIntOptions(WidgetTester tester) {
  final out = <int>[];
  for (final el in find.byType(TangibleButton).evaluate()) {
    final txt = find.descendant(
      of: find.byElementPredicate((e) => identical(e, el)),
      matching: find.byType(Text),
    );
    if (txt.evaluate().length == 1) {
      final v = int.tryParse(tester.widget<Text>(txt).data ?? '');
      if (v != null) out.add(v);
    }
  }
  return out;
}

void _tapTangibleText(WidgetTester tester, String label) {
  for (final el in find.byType(TangibleButton).evaluate()) {
    final btnFinder = find.byElementPredicate((e) => identical(e, el));
    final txt = find.descendant(of: btnFinder, matching: find.text(label));
    if (txt.evaluate().isNotEmpty) {
      tester.widget<TangibleButton>(btnFinder).onTap!();
      return;
    }
  }
  throw StateError('TangibleButton("$label") not found');
}

class _PoolPower {
  const _PoolPower(this.base, this.exp);
  final int base;
  final int exp;
  int get value => pow(base, exp).toInt();
}

List<_PoolPower> _readExponentPool(WidgetTester tester) {
  final out = <_PoolPower>[];
  for (final el in find.byType(TangibleButton).evaluate()) {
    final btnFinder = find.byElementPredicate((e) => identical(e, el));
    final texts = tester
        .widgetList<Text>(
            find.descendant(of: btnFinder, matching: find.byType(Text)))
        .map((t) => t.data ?? '')
        .toList();
    if (texts.length == 2) {
      out.add(_PoolPower(int.parse(texts[0]), int.parse(texts[1])));
    }
  }
  return out;
}

void _tapExponentPoolItem(WidgetTester tester, int base, int exp) {
  for (final el in find.byType(TangibleButton).evaluate()) {
    final btnFinder = find.byElementPredicate((e) => identical(e, el));
    final texts = tester
        .widgetList<Text>(
            find.descendant(of: btnFinder, matching: find.byType(Text)))
        .map((t) => t.data ?? '')
        .toList();
    if (texts.length == 2 &&
        int.parse(texts[0]) == base &&
        int.parse(texts[1]) == exp) {
      tester.widget<TangibleButton>(btnFinder).onTap!();
      return;
    }
  }
  throw StateError('Pool item $base^$exp not found');
}

(int, int, int) _readPizzaFraction(WidgetTester tester) {
  final orangeNums = tester
      .widgetList<Text>(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.style?.color == DesignSystem.gameOrange &&
              w.style?.fontSize == 32,
        ),
      )
      .map((t) => int.parse(t.data!))
      .toList();
  final sliceInfo = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.startsWith('of a ') && s.endsWith('-slice pizza'));
  final total = int.parse(
    RegExp(r'of a (\d+)-slice pizza').firstMatch(sliceInfo)!.group(1)!,
  );
  return (orangeNums[0], orangeNums[1], total);
}

int _readModuloExpectedHour(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .toList();
  final startLine = texts.firstWhere((s) => s.startsWith('START TIME: '));
  final addLine =
      texts.firstWhere((s) => s.startsWith('+ ') && s.endsWith(' HOURS'));
  final startHour = int.parse(
    RegExp(r'START TIME: (\d+):00').firstMatch(startLine)!.group(1)!,
  );
  final added = int.parse(
    RegExp(r'\+ (\d+) HOURS').firstMatch(addLine)!.group(1)!,
  );
  final mod = (startHour + added) % 12;
  return mod == 0 ? 12 : mod;
}

List<int> _readModuloOptionHours(WidgetTester tester) {
  final out = <int>[];
  for (final el in find.byType(TangibleButton).evaluate()) {
    final txt = find.descendant(
      of: find.byElementPredicate((e) => identical(e, el)),
      matching: find.byType(Text),
    );
    if (txt.evaluate().length != 1) continue;
    final s = tester.widget<Text>(txt).data ?? '';
    final m = RegExp(r'^(\d+):00$').firstMatch(s);
    if (m != null) out.add(int.parse(m.group(1)!));
  }
  return out;
}

String _readVennFormula(WidgetTester tester) {
  final txt = tester.widgetList<Text>(find.byType(Text)).firstWhere(
        (t) => t.style?.fontSize == 28 && t.style?.fontFamily == 'Bebas Neue',
      );
  return txt.data!;
}

Set<VennRegion> _expectedVennRegions(String formula) {
  if (formula.startsWith('A ∩ B')) return {VennRegion.intersection};
  if (formula.startsWith('A ∪ B')) {
    return {VennRegion.onlyA, VennRegion.onlyB, VennRegion.intersection};
  }
  if (formula.startsWith(r'A \ B')) return {VennRegion.onlyA};
  if (formula.startsWith(r'B \ A')) return {VennRegion.onlyB};
  if (formula.startsWith("(A ∪ B)'")) return {VennRegion.outside};
  if (formula.startsWith("A'")) return {VennRegion.onlyB, VennRegion.outside};
  if (formula.startsWith("B'")) return {VennRegion.onlyA, VennRegion.outside};
  if (formula.startsWith('A Δ B')) return {VennRegion.onlyA, VennRegion.onlyB};
  throw StateError('Unknown Venn formula: $formula');
}

void _toggleVennRegion(WidgetTester tester, VennRegion region) {
  switch (region) {
    case VennRegion.outside:
      _tapTangibleText(tester, 'OUTSIDE (U)');
    case VennRegion.onlyA:
      _tapVennCard(tester, 'ONLY A');
    case VennRegion.intersection:
      _tapVennCard(tester, 'A ∩ B');
    case VennRegion.onlyB:
      _tapVennCard(tester, 'ONLY B');
  }
}

void _tapVennCard(WidgetTester tester, String label) {
  final txt = find.text(label);
  final detector = find.ancestor(
    of: txt,
    matching: find.byType(GestureDetector),
  );
  tester.widget<GestureDetector>(detector.first).onTap!();
}

int _solveUnitConversion(WidgetTester tester) {
  final prompt = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.startsWith('Convert '));

  RegExpMatch? m;
  if ((m = RegExp(r'Convert (\d+) meters to centimeters').firstMatch(prompt)) !=
      null) {
    return int.parse(m!.group(1)!) * 100;
  }
  if ((m = RegExp(r'Convert (\d+) kilometers to meters').firstMatch(prompt)) !=
      null) {
    return int.parse(m!.group(1)!) * 1000;
  }
  if ((m = RegExp(r'Convert (\d+) feet to inches').firstMatch(prompt)) !=
      null) {
    return int.parse(m!.group(1)!) * 12;
  }
  if ((m = RegExp(r'Convert (\d+) hours to minutes').firstMatch(prompt)) !=
      null) {
    return int.parse(m!.group(1)!) * 60;
  }
  if ((m = RegExp(r'Convert (\d+) minutes to seconds').firstMatch(prompt)) !=
      null) {
    return int.parse(m!.group(1)!) * 60;
  }
  if ((m = RegExp(r'Convert (\d+) days to hours').firstMatch(prompt)) != null) {
    return int.parse(m!.group(1)!) * 24;
  }
  if ((m = RegExp(r'Convert (\d+) kilograms to grams').firstMatch(prompt)) !=
      null) {
    return int.parse(m!.group(1)!) * 1000;
  }
  if ((m = RegExp(r'Convert (\d+) pounds to ounces').firstMatch(prompt)) !=
      null) {
    return int.parse(m!.group(1)!) * 16;
  }
  if ((m = RegExp(r'Convert (\d+) liters to milliliters').firstMatch(prompt)) !=
      null) {
    return int.parse(m!.group(1)!) * 1000;
  }
  if ((m = RegExp(r'Convert (\d+) gallons to quarts').firstMatch(prompt)) !=
      null) {
    return int.parse(m!.group(1)!) * 4;
  }
  if ((m = RegExp(r'Convert (\d+)°C to Fahrenheit').firstMatch(prompt)) !=
      null) {
    final c = int.parse(m!.group(1)!);
    return (c * 9 ~/ 5) + 32;
  }
  if ((m = RegExp(r'Convert (\d+)°F to Celsius').firstMatch(prompt)) != null) {
    final f = int.parse(m!.group(1)!);
    return (f - 32) * 5 ~/ 9;
  }
  throw StateError('Unhandled conversion prompt: $prompt');
}
