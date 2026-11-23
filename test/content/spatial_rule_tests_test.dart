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
import 'package:puzzle/ui/features/games/block_stacking_physics/block_stacking_physics_screen.dart';
import 'package:puzzle/ui/features/games/gear_rotation/gear_rotation_screen.dart';
import 'package:puzzle/ui/features/games/maze_nav_3d/maze_nav_3d_screen.dart';
import 'package:puzzle/ui/features/games/mirror_image/mirror_image_engine.dart';
import 'package:puzzle/ui/features/games/mirror_image/mirror_image_provider.dart';
import 'package:puzzle/ui/features/games/mirror_maze/mirror_maze_engine.dart';
import 'package:puzzle/ui/features/games/mirror_maze/mirror_maze_screen.dart';
import 'package:puzzle/ui/features/games/negative_space_detection/negative_space_detection_engine.dart';
import 'package:puzzle/ui/features/games/negative_space_detection/negative_space_detection_provider.dart';
import 'package:puzzle/ui/features/games/perspective_shift_view/perspective_shift_view_screen.dart';
import 'package:puzzle/ui/features/games/tangram/tangram_screen.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';

/// Missing rule tests for the Spatial room (8 games, release gate G3).
void main() {
  group('mirror_image', () {
    test(
        'generated level marks a true reflection as valid, and selecting a wrong option does not solve',
        () {
      final MirrorImageEngine engine = MirrorImageEngine();
      for (int i = 0; i < 10; i++) {
        final MirrorImageLevel level = engine.generateLevel();
        expect(level.options.length, 4);
        expect(level.correctIndex, inInclusiveRange(0, 3));
        final MirrorShape answer = level.options[level.correctIndex];
        expect(_isExactMirror(level.question, answer), isTrue,
            reason: 'correctIndex must be a horizontal or vertical reflection');
      }

      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final MirrorImageState initial =
          container.read(mirrorImageNotifierProvider);
      final int wrong = (initial.level.correctIndex + 1) % 4;

      container.read(mirrorImageNotifierProvider.notifier).selectOption(wrong);
      expect(container.read(mirrorImageNotifierProvider).isSolved, isFalse);

      container
          .read(mirrorImageNotifierProvider.notifier)
          .selectOption(initial.level.correctIndex);
      expect(container.read(mirrorImageNotifierProvider).isSolved, isTrue);
    });
  });

  group('negative_space_detection', () {
    test(
        'generated options contain the target once, and only correctIndex solves',
        () {
      final NegativeSpaceDetectionEngine engine =
          NegativeSpaceDetectionEngine();
      for (int i = 0; i < 10; i++) {
        final NegativeSpaceLevel level = engine.generateLevel();
        expect(level.options.length, 4);
        expect(level.options.toSet().length, 4);
        expect(level.options[level.correctIndex], level.target);
      }

      final ProviderContainer win = ProviderContainer();
      addTearDown(win.dispose);
      win.read(negativeSpaceDetectionNotifierProvider.notifier).initGame();
      final int right =
          win.read(negativeSpaceDetectionNotifierProvider).correctIndex;
      win
          .read(negativeSpaceDetectionNotifierProvider.notifier)
          .selectOption(right);
      expect(
          win.read(negativeSpaceDetectionNotifierProvider).isVictory, isTrue);
      expect(
          win.read(negativeSpaceDetectionNotifierProvider).isFailed, isFalse);

      final ProviderContainer lose = ProviderContainer();
      addTearDown(lose.dispose);
      lose.read(negativeSpaceDetectionNotifierProvider.notifier).initGame();
      final int wrong =
          (lose.read(negativeSpaceDetectionNotifierProvider).correctIndex + 1) %
              4;
      lose
          .read(negativeSpaceDetectionNotifierProvider.notifier)
          .selectOption(wrong);
      expect(
          lose.read(negativeSpaceDetectionNotifierProvider).isVictory, isFalse);
      expect(
          lose.read(negativeSpaceDetectionNotifierProvider).isFailed, isTrue);
    });
  });

  group('gear_rotation', () {
    testWidgets(
      'alternating parity along the gear train determines the valid final direction',
      (tester) async {
        await _pumpNoSettle(tester, const GearRotationScreen());
        expect(find.text('0 / 5'), findsOneWidget);

        // Read first-gear direction and gear count from the custom painter.
        bool firstCw() => find.text('CLOCKWISE (CW)').evaluate().isNotEmpty;
        int gearsCount() {
          final CustomPaint paint = tester
              .widgetList<CustomPaint>(
                find.descendant(
                  of: find.byType(GearRotationScreen),
                  matching: find.byType(CustomPaint),
                ),
              )
              .firstWhere(
                (CustomPaint p) => p.painter.runtimeType
                    .toString()
                    .contains('GearChainPainter'),
              );
          final dynamic painter = paint.painter;
          return painter.gearsCount as int;
        }

        final bool startCw = firstCw();
        final int n = gearsCount();
        final bool validFinalCw = (n % 2 == 1) ? startCw : !startCw;

        // Answering the opposite parity does not advance score from 0.
        await tester.tap(
          find.text(validFinalCw ? 'COUNTER-CLOCKWISE' : 'CLOCKWISE'),
        );
        await tester.pump(const Duration(milliseconds: 1600));
        expect(find.text('0 / 5'), findsOneWidget,
            reason: 'wrong gear parity must not score');

        // Re-read the newly generated round and submit the valid parity.
        final bool nextCw = firstCw();
        final int nextN = gearsCount();
        final bool nextValidCw = (nextN % 2 == 1) ? nextCw : !nextCw;
        await tester.tap(
          find.text(nextValidCw ? 'CLOCKWISE' : 'COUNTER-CLOCKWISE'),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('1 / 5'), findsOneWidget,
            reason: 'correct gear parity advances score');
        await tester.pump(const Duration(milliseconds: 1300));

        await _teardown(tester);
      },
    );
  });

  group('mirror_maze', () {
    test(
        'every dealt board takes two mirrors and never one, proven over forty seeds',
        () {
      for (int seed = 0; seed < 40; seed++) {
        final MirrorMazeDeal deal =
            MirrorMazeGenerator(random: Random(seed)).next();
        final String why = 'seed $seed dealt ${deal.key}';
        expect(deal.depth, 2, reason: '$why must be a two-mirror deal');
        expect(deal.answer.length, 2, reason: '$why must deal two mirrors');
        expect(mirrorMazeLayoutWins(deal, deal.answer), isTrue,
            reason:
                '$why: the deal must be won by the layout it was built from');
        expect(mirrorMazeLayouts(deal, 0), isEmpty,
            reason: '$why must not be a straight shot through the board');
        expect(mirrorMazeLayouts(deal, 1), isEmpty,
            reason: '$why must not be winnable with a single mirror, of '
                'either kind, on any cell');
        expect(mirrorMazeDepth(deal), 2, reason: '$why solves in two');
        // The test's own reading of the rules, so the engine cannot agree with
        // itself and be wrong.
        expect(_mirrorMazeLayoutsWithin(deal, 1), isEmpty,
            reason:
                '$why: the test solver must also find no one-mirror answer');
        expect(_mirrorMazeLayoutsWithin(deal, 2), isNotEmpty,
            reason: '$why: the test solver must find a two-mirror answer');
      }
    });

    test('the fallback deal is a two-mirror deal too', () {
      final MirrorMazeDeal deal = MirrorMazeGenerator.fallback;
      expect(mirrorMazeLayoutWins(deal, deal.answer), isTrue);
      expect(mirrorMazeLayouts(deal, 0), isEmpty);
      expect(mirrorMazeLayouts(deal, 1), isEmpty);
      expect(mirrorMazeDepth(deal), 2);
      expect(_mirrorMazeLayoutsWithin(deal, 1), isEmpty);
      expect(_mirrorMazeLayoutsWithin(deal, 2), isNotEmpty);
    });

    test('a beam that loops never counts as leaving the board', () {
      // Four mirrors in a 2x2 block turn the beam back into its own path, so it
      // runs until the step limit. The last cell it reached is not an exit.
      final MirrorMazeTrace trace = traceBeam(
        mirrors: <Point<int>, int>{
          const Point<int>(1, 1): Mirror.slash,
          const Point<int>(1, 2): Mirror.backslash,
          const Point<int>(2, 2): Mirror.slash,
          const Point<int>(2, 1): Mirror.backslash,
        },
        start: const Point<int>(1, 1),
        startDir: const Point<int>(0, -1),
      );
      expect(trace.exited, isFalse,
          reason: 'a loop is not an exit, however far the beam got');
      expect(trace.exitCell, isNull);
    });

    testWidgets(
      'an unreflected or misrouted beam stays unsolved; two mirrors solve the maze',
      (tester) async {
        // A fixed seed: the same board every run, so this test can fail for a
        // reason and not for a coin toss.
        await _pump(tester, const MirrorMazeScreen(seed: 20261122));
        expect(find.byType(GameCompletionDialog), findsNothing);

        // Locate the 16 cell GestureDetectors inside the 300x300 board Container.
        final Finder boardBox = find.descendant(
          of: find.byType(MirrorMazeScreen),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is Container &&
                w.constraints?.maxWidth == 300 &&
                w.constraints?.maxHeight == 300,
          ),
        );
        final Finder cells = find.descendant(
          of: boardBox,
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is GestureDetector && w.behavior == HitTestBehavior.opaque,
          ),
        );
        expect(cells, findsNWidgets(16));

        // Determine source and target cell + direction directly from rendered UI icons.
        final Offset tl = tester.getTopLeft(cells.at(0));
        final Offset br = tester.getBottomRight(cells.at(15));
        final double cellSize = (br.dx - tl.dx) / 4;

        (Point<int>, Point<int>) readEdgeIcon(IconData icon, bool isSource) {
          final Offset center = tester.getCenter(find.byIcon(icon));
          if (center.dx < tl.dx) {
            final int r = ((center.dy - tl.dy) / cellSize).floor().clamp(0, 3);
            return (
              Point<int>(r, 0),
              isSource ? const Point<int>(0, 1) : const Point<int>(0, -1),
            );
          } else if (center.dx > br.dx) {
            final int r = ((center.dy - tl.dy) / cellSize).floor().clamp(0, 3);
            return (
              Point<int>(r, 3),
              isSource ? const Point<int>(0, -1) : const Point<int>(0, 1),
            );
          } else if (center.dy < tl.dy) {
            final int c = ((center.dx - tl.dx) / cellSize).floor().clamp(0, 3);
            return (
              Point<int>(0, c),
              isSource ? const Point<int>(1, 0) : const Point<int>(-1, 0),
            );
          } else {
            final int c = ((center.dx - tl.dx) / cellSize).floor().clamp(0, 3);
            return (
              Point<int>(3, c),
              isSource ? const Point<int>(-1, 0) : const Point<int>(1, 0),
            );
          }
        }

        final (Point<int> startCell, Point<int> startDir) =
            readEdgeIcon(Icons.play_arrow_rounded, true);
        final (Point<int> targetCell, Point<int> targetDir) =
            readEdgeIcon(Icons.gps_fixed_rounded, false);

        // The deal the widget is really showing, as the test solved it.
        final MirrorMazeDeal deal = MirrorMazeDeal(
          start: startCell,
          startDir: startDir,
          target: targetCell,
          targetDir: targetDir,
          answer: const <Point<int>, int>{},
          depth: 2,
        );

        // The ground this test stands on: no single mirror can win this board,
        // so a beam sent the wrong way cannot be knocked onto the receiver by
        // one lucky tap.
        expect(_mirrorMazeLayoutsWithin(deal, 1), isEmpty,
            reason: 'a dealt board must not be winnable with one mirror');
        expect(find.byType(GameCompletionDialog), findsNothing,
            reason: 'an empty board is not a solved board');

        Future<void> setMirror(int r, int c, int type) async {
          for (int t = 0; t < type; t++) {
            _tapGesture(tester, cells.at(r * 4 + c));
            await tester.pump();
          }
        }

        // One mirror anywhere leaves the beam off-target.
        await setMirror(0, 0, 1);
        await tester.pumpAndSettle();
        expect(find.byType(GameCompletionDialog), findsNothing,
            reason: 'a misrouted beam must stay unsolved');
        // Clear it rather than tapping through the other angle: one tap moves a
        // cell to the next state, so a route is never reached by accident.
        await setMirror(0, 0, 2);

        // A two-mirror route the deal allows solves the board.
        final List<Map<Point<int>, int>> routes =
            _mirrorMazeLayoutsWithin(deal, 2);
        expect(routes, isNotEmpty,
            reason: 'the board on screen must be solvable in two mirrors');
        final Map<Point<int>, int> route = routes.first;
        expect(route.length, 2);
        for (final MapEntry<Point<int>, int> entry in route.entries) {
          await setMirror(entry.key.x, entry.key.y, entry.value);
        }

        await tester.pumpAndSettle();
        expect(find.byType(GameCompletionDialog), findsOneWidget);
        await _teardown(tester);
      },
    );
  });

  group('tangram', () {
    testWidgets(
      'overlapping or out-of-outline placements stay unsolved; exact tiling of the outline solves',
      (tester) async {
        await _pump(tester, const TangramScreen());
        expect(find.byType(GameCompletionDialog), findsNothing);

        final Finder boardBox = find.descendant(
          of: find.byType(TangramScreen),
          matching: find.byWidgetPredicate(
            (Widget w) => w is Container && w.constraints?.maxWidth == 240,
          ),
        );
        final Finder gridCells = find.descendant(
          of: boardBox,
          matching: find.byType(GestureDetector),
        );
        expect(gridCells, findsNWidgets(16));

        // Read which of the 16 cells belong to _targetOutline (non-null border).
        final Set<Point<int>> outline = <Point<int>>{};
        for (int r = 0; r < 4; r++) {
          for (int c = 0; c < 4; c++) {
            final Container box = tester.widget<Container>(
              find.descendant(
                of: gridCells.at(r * 4 + c),
                matching: find.byType(Container),
              ),
            );
            final BoxDecoration? dec = box.decoration as BoxDecoration?;
            if (dec?.border != null) outline.add(Point<int>(r, c));
          }
        }
        expect(outline.length, greaterThanOrEqualTo(5));

        final Finder dockPieces = find.descendant(
          of: find.byType(FittedBox).last,
          matching: find.byType(GestureDetector),
        );
        final int pieceCount = dockPieces.evaluate().length;
        expect(pieceCount, greaterThanOrEqualTo(2));

        final List<List<Point<int>>> pieces = <List<Point<int>>>[];
        for (int i = 0; i < pieceCount; i++) {
          final Stack previewStack = tester.widget<Stack>(
            find.descendant(
              of: dockPieces.at(i),
              matching: find.byType(Stack),
            ),
          );
          pieces.add(
            previewStack.children
                .whereType<Positioned>()
                .map(
                  (Positioned p) => Point<int>(
                    ((p.top! - 6.0) / 12.0).round(),
                    ((p.left! - 6.0) / 12.0).round(),
                  ),
                )
                .toList(growable: false),
          );
        }

        final List<({int rot, int r, int c})>? plan =
            _solveTangram(outline, pieces);
        expect(plan, isNotNull,
            reason: 'generated Tangram puzzle must tile the outline');

        Finder dockAt(int idx) => dockPieces.at(idx);

        Future<void> placePiece(int idx, int rotations, int r, int c) async {
          for (int rot = 0; rot < rotations; rot++) {
            tester.widget<GestureDetector>(dockAt(idx)).onDoubleTap!();
            await tester.pump();
          }
          if (rotations == 0) {
            _tapGesture(tester, dockAt(idx));
            await tester.pump();
          }
          _tapGesture(tester, gridCells.at(r * 4 + c));
          await tester.pump();
        }

        // Place pieces 1..last cleanly.
        for (int i = 1; i < pieces.length; i++) {
          await placePiece(i, plan![i].rot, plan[i].r, plan[i].c);
        }

        // Place piece 0 at a different valid in-bounds coordinate -> overlaps or exits outline.
        final List<Point<int>> p0Cells = _rotatePiece(pieces[0], plan![0].rot);
        final int maxR = p0Cells.map((p) => p.x).reduce(max);
        final int maxC = p0Cells.map((p) => p.y).reduce(max);
        for (int r = 0; r + maxR < 4; r++) {
          bool testedInvalid = false;
          for (int c = 0; c + maxC < 4; c++) {
            if (r == plan[0].r && c == plan[0].c) continue;
            await placePiece(0, plan[0].rot, r, c);
            await tester.pumpAndSettle();
            expect(find.byType(GameCompletionDialog), findsNothing);
            // Piece 0 remains selected after placement; move directly to solution.
            _tapGesture(tester, gridCells.at(plan[0].r * 4 + plan[0].c));
            testedInvalid = true;
            break;
          }
          if (testedInvalid) break;
        }

        await tester.pumpAndSettle();
        expect(find.byType(GameCompletionDialog), findsOneWidget);
        await _teardown(tester);
      },
    );
  });

  group('block_stacking_physics', () {
    testWidgets(
      'dropping with overlap grows the stack to victory; dropping with zero overlap loses',
      (tester) async {
        await _pumpNoSettle(tester, const BlockStackingPhysicsScreen());
        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(find.byType(BlockStackingPhysicsScreen)),
        )!;
        expect(find.text('Stack Height: 0 / 8'), findsOneWidget);

        final Finder dropSurface = find
            .descendant(
              of: find.byType(BlockStackingPhysicsScreen),
              matching: find.byWidgetPredicate(
                (Widget w) => w is GestureDetector && w.onTapDown != null,
              ),
            )
            .last;

        // Initial base is [0.25, 0.75], active starts at [0.10, 0.50] -> immediate
        // drop overlaps [0.25, 0.50] (width 0.25) -> height 1.
        // Next block starts at left=0.0, width=0.25 -> immediate drop at t=0 has
        // overlapRight = min(0.25, 0.50) = 0.25, overlapLeft = max(0.0, 0.25) = 0.25
        // -> overlap 0.0 <= 0.01 -> GAME OVER!
        await tester.tapAt(tester.getCenter(dropSurface));
        await tester.pump();
        expect(find.text('Stack Height: 1 / 8'), findsOneWidget);

        await tester.tapAt(tester.getCenter(dropSurface));
        await tester.pump();
        expect(find.byType(GameCompletionDialog), findsOneWidget);
        expect(find.text(l10n.gameOver.toUpperCase()), findsOneWidget,
            reason: 'zero overlap topples the stack');

        // Restart and time each drop when the active block reaches left >= 0.25 so
        // all 8 drops overlap cleanly and win.
        tester
            .widget<GameCompletionDialog>(find.byType(GameCompletionDialog))
            .onPlayAgain();
        await tester.pump();
        double speed = 0.015;
        // Drop 1: active starts at 0.10 moving +0.015/tick; 10 ticks (200ms) -> 0.25!
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tapAt(tester.getCenter(dropSurface));
        await tester.pump();
        expect(find.text('Stack Height: 1 / 8'), findsOneWidget);

        for (int h = 2; h <= 8; h++) {
          speed += 0.002;
          // Active resets to 0.0 moving right at `speed` per 20ms tick; wait until
          // left is near 0.25.
          final int ticks = (0.25 / speed).round();
          await tester.pump(Duration(milliseconds: ticks * 20));
          await tester.tapAt(tester.getCenter(dropSurface));
          await tester.pump();
        }
        expect(find.text('VICTORY'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 200));

        await _teardown(tester);
      },
    );
  });

  group('maze_nav_3d', () {
    testWidgets(
      'walking into a wall is blocked; following a valid open path to the exit scores',
      (tester) async {
        await _pump(tester, const MazeNav3DScreen());
        expect(find.text('Exit Found: 0 / 3'), findsOneWidget);

        // Read the 4x4 minimap grid colors: wall is black12, exit is gameGreen,
        // player starts at (0,0) facing East (1).
        final Finder minimapTiles = find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Container),
        );
        expect(minimapTiles, findsNWidgets(16));

        final List<List<int>> grid = List<List<int>>.generate(
          4,
          (_) => List<int>.filled(4, 0),
        );
        Point<int>? exit;
        for (int idx = 0; idx < 16; idx++) {
          final int r = idx ~/ 4;
          final int c = idx % 4;
          final Container box = tester.widget<Container>(minimapTiles.at(idx));
          final Color? color = (box.decoration as BoxDecoration?)?.color;
          if (color == Colors.black12) {
            grid[r][c] = 1;
          } else if (color == DesignSystem.gameGreen) {
            grid[r][c] = 2;
            exit = Point<int>(c, r);
          }
        }
        exit ??= const Point<int>(0, 0);

        final Finder turnLeft = find.byIcon(Icons.rotate_left);
        final Finder forward = find.byIcon(Icons.arrow_upward_rounded);
        final Finder turnRight = find.byIcon(Icons.rotate_right);

        // Facing North (0) from (0,0) is out-of-bounds -> blocked, score stays 0.
        await tester.tap(turnLeft);
        await tester.pump();
        await tester.tap(forward);
        await tester.pump();
        expect(find.text('Exit Found: 0 / 3'), findsOneWidget,
            reason: 'stepping out of bounds / into a wall must be rejected');
        // Turn back East (1).
        await tester.tap(turnRight);
        await tester.pump();

        // BFS from (0,0) to exit over cells != 1.
        final List<Point<int>> path = _mazePath(grid, exit);
        int facing = 1; // East
        Point<int> pos = const Point<int>(0, 0);
        for (final Point<int> step in path.skip(1)) {
          final int dx = step.x - pos.x;
          final int dy = step.y - pos.y;
          final int want = dy == -1
              ? 0
              : dx == 1
                  ? 1
                  : dy == 1
                      ? 2
                      : 3;
          while (facing != want) {
            await tester.tap(turnRight);
            await tester.pump();
            facing = (facing + 1) % 4;
          }
          await tester.tap(forward);
          await tester.pump();
          pos = step;
        }
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Exit Found: 1 / 3'), findsOneWidget,
            reason: 'reaching the exit cell scores');

        await _teardown(tester);
      },
    );
  });

  group('perspective_shift_view', () {
    testWidgets(
      'misaligned angle or wrong letter fails; aligned target angle and matching letter solves the round',
      (tester) async {
        await _pump(tester, const PerspectiveShiftViewScreen());
        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(find.byType(PerspectiveShiftViewScreen)),
        )!;

        final CustomPaint blockPaint = tester
            .widgetList<CustomPaint>(
              find.descendant(
                of: find.byType(PerspectiveShiftViewScreen),
                matching: find.byType(CustomPaint),
              ),
            )
            .firstWhere(
              (CustomPaint p) => p.painter.runtimeType
                  .toString()
                  .contains('PerspectiveBlockPainter'),
            );
        final dynamic painter = blockPaint.painter;
        final double targetAngle = painter.targetAngle as double;
        final List<Point<int>> offsets =
            (painter.blockOffsets as List<dynamic>).cast<Point<int>>();
        final String letter = _letterForOffsets(offsets);

        // Set camera angle 90 degrees off targetAngle -> even the right letter must fail.
        final double wrongAngle = (targetAngle + pi / 2) % (2 * pi);
        final Slider slider = tester.widget<Slider>(find.byType(Slider));
        slider.onChanged!(wrongAngle);
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, letter));
        await tester.pump();
        expect(find.text(l10n.snackbarIncorrectPerspective), findsOneWidget);

        ScaffoldMessenger.of(
          tester.element(find.byType(PerspectiveShiftViewScreen)),
        ).clearSnackBars();
        await tester.pump();

        // Align camera angle to targetAngle, pick wrong letter -> fails.
        final Slider alignedSlider = tester.widget<Slider>(find.byType(Slider));
        alignedSlider.onChanged!(targetAngle);
        await tester.pump();
        final String wrongLetter = tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .map((ElevatedButton b) => (b.child as Text).data!)
            .firstWhere((String opt) => opt != letter);
        await tester.tap(find.widgetWithText(ElevatedButton, wrongLetter));
        await tester.pump();
        expect(find.text(l10n.snackbarIncorrectPerspective), findsOneWidget);

        ScaffoldMessenger.of(
          tester.element(find.byType(PerspectiveShiftViewScreen)),
        ).clearSnackBars();
        await tester.pump();

        // Aligned angle + valid letter -> snackbarAlignedCorrectly!
        await tester.tap(find.widgetWithText(ElevatedButton, letter));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text(l10n.snackbarAlignedCorrectly), findsOneWidget);

        await _teardown(tester);
      },
    );
  });
}

bool _isExactMirror(MirrorShape q, MirrorShape candidate) {
  if (q.points.length != candidate.points.length) return false;
  bool matches(bool vertical) {
    for (int i = 0; i < q.points.length; i++) {
      final double ex = vertical ? 1.0 - q.points[i].dx : q.points[i].dx;
      final double ey = vertical ? q.points[i].dy : 1.0 - q.points[i].dy;
      if ((candidate.points[i].dx - ex).abs() > 1e-9 ||
          (candidate.points[i].dy - ey).abs() > 1e-9) {
        return false;
      }
    }
    return true;
  }

  return matches(true) || matches(false);
}

List<Point<int>> _mazePath(List<List<int>> grid, Point<int> goal) {
  const Point<int> start = Point<int>(0, 0);
  if (goal == start) {
    // Step to any open neighbor and back onto (0,0).
    for (final Point<int> d in const <Point<int>>[
      Point<int>(1, 0),
      Point<int>(0, 1),
    ]) {
      if (grid[d.y][d.x] != 1) return <Point<int>>[start, d, start];
    }
  }
  final Queue<Point<int>> q = Queue<Point<int>>()..add(start);
  final Map<Point<int>, Point<int>> parent = <Point<int>, Point<int>>{};
  final Set<Point<int>> seen = <Point<int>>{start};
  while (q.isNotEmpty) {
    final Point<int> cur = q.removeFirst();
    for (final Point<int> d in const <Point<int>>[
      Point<int>(0, -1),
      Point<int>(1, 0),
      Point<int>(0, 1),
      Point<int>(-1, 0),
    ]) {
      final Point<int> nx = Point<int>(cur.x + d.x, cur.y + d.y);
      if (nx.x < 0 || nx.x >= 4 || nx.y < 0 || nx.y >= 4) continue;
      if (grid[nx.y][nx.x] == 1 || !seen.add(nx)) continue;
      parent[nx] = cur;
      if (nx == goal) {
        final List<Point<int>> out = <Point<int>>[];
        Point<int>? walk = goal;
        while (walk != null) {
          out.add(walk);
          walk = parent[walk];
        }
        return out.reversed.toList(growable: false);
      }
      q.add(nx);
    }
  }
  throw StateError('Generated 3D maze had no open path to $goal');
}

String _letterForOffsets(List<Point<int>> offsets) {
  switch (offsets.length) {
    case 4:
      return 'L';
    case 5:
      return offsets.contains(const Point<int>(2, 0)) ? 'T' : 'C';
    case 7:
      return 'H';
    default:
      return 'E';
  }
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
  await _pumpNoSettle(tester, child);
  await tester.pumpAndSettle();
}

Future<void> _pumpNoSettle(WidgetTester tester, Widget child) async {
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

/// Every layout of at most [maxMirrors] mirrors that wins [deal], found by
/// walking the beam and pinning every cell it visits — an empty cell included —
/// so the beam can never come back to a cell and decide it a second time.
///
/// Written from the rules rather than from [MirrorMazeGenerator], so the two can
/// disagree. A reading that can only say "yes" is worth nothing.
List<Map<Point<int>, int>> _mirrorMazeLayoutsWithin(
  MirrorMazeDeal deal,
  int maxMirrors,
) {
  Point<int> reflect(Point<int> dir, int mirror) {
    if (mirror == 1) return Point<int>(-dir.y, -dir.x);
    if (mirror == 2) return Point<int>(dir.y, dir.x);
    return dir;
  }

  final List<Map<Point<int>, int>> found = <Map<Point<int>, int>>[];

  void walk(
    Point<int> cell,
    Point<int> incoming,
    Map<Point<int>, int> pinned,
    Set<(Point<int>, Point<int>)> seen,
  ) {
    if (!seen.add((cell, incoming))) return;
    final int? pin = pinned[cell];
    final int used = pinned.values.where((int v) => v != 0).length;
    final List<int> choices = pin != null
        ? <int>[pin]
        : (used < maxMirrors ? const <int>[0, 1, 2] : const <int>[0]);

    for (final int mirror in choices) {
      final Point<int> out = reflect(incoming, mirror);
      final Point<int> next = Point<int>(cell.x + out.x, cell.y + out.y);
      final Map<Point<int>, int> nextPinned =
          pin != null ? pinned : (<Point<int>, int>{...pinned, cell: mirror});

      if (next.x < 0 || next.x >= 4 || next.y < 0 || next.y >= 4) {
        if (cell == deal.target && out == deal.targetDir) {
          final Map<Point<int>, int> layout = <Point<int>, int>{
            for (final MapEntry<Point<int>, int> e in nextPinned.entries)
              if (e.value != 0) e.key: e.value,
          };
          if (!found.any((Map<Point<int>, int> other) =>
              other.length == layout.length &&
              other.entries.every(
                  (MapEntry<Point<int>, int> e) => layout[e.key] == e.value))) {
            found.add(layout);
          }
        }
        continue;
      }
      if (seen.contains((next, out))) continue;
      walk(
        next,
        out,
        nextPinned,
        Set<(Point<int>, Point<int>)>.from(seen),
      );
    }
  }

  walk(
    deal.start,
    deal.startDir,
    <Point<int>, int>{},
    <(Point<int>, Point<int>)>{},
  );
  return found;
}

List<Point<int>> _rotatePiece(List<Point<int>> cells, int rotations) {
  List<Point<int>> result = cells;
  for (int r = 0; r < (rotations % 4); r++) {
    result = result.map((Point<int> p) => Point<int>(p.y, -p.x)).toList();
  }
  final int minR = result.map((Point<int> p) => p.x).reduce(min);
  final int minC = result.map((Point<int> p) => p.y).reduce(min);
  return result
      .map((Point<int> p) => Point<int>(p.x - minR, p.y - minC))
      .toList();
}

List<({int rot, int r, int c})>? _solveTangram(
  Set<Point<int>> outline,
  List<List<Point<int>>> pieces,
) {
  final Set<Point<int>> occupied = <Point<int>>{};
  final List<({int rot, int r, int c})?> chosen =
      List<({int rot, int r, int c})?>.filled(pieces.length, null);

  bool search(int idx) {
    if (idx == pieces.length) return occupied.length == outline.length;
    for (int rot = 0; rot < 4; rot++) {
      final List<Point<int>> rotated = _rotatePiece(pieces[idx], rot);
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          final List<Point<int>> shifted = <Point<int>>[
            for (final Point<int> p in rotated) Point<int>(r + p.x, c + p.y),
          ];
          if (shifted.every(
            (Point<int> pt) => outline.contains(pt) && !occupied.contains(pt),
          )) {
            occupied.addAll(shifted);
            chosen[idx] = (rot: rot, r: r, c: c);
            if (search(idx + 1)) return true;
            chosen[idx] = null;
            occupied.removeAll(shifted);
          }
        }
      }
    }
    return false;
  }

  if (!search(0)) return null;
  return chosen.cast<({int rot, int r, int c})>();
}

void _tapGesture(WidgetTester tester, Finder finder) {
  tester.widget<GestureDetector>(finder).onTap!();
}
