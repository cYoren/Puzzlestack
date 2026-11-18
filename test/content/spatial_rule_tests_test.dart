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
    testWidgets(
      'an unreflected or misrouted beam stays unsolved; valid mirror angles solve the maze',
      (tester) async {
        await _pump(tester, const MirrorMazeScreen());
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

        // Identify which of the 3 puzzles was chosen by source icon position.
        final Offset boardTopLeft = tester.getTopLeft(cells.at(0));
        final Offset sourceTopLeft =
            tester.getTopLeft(find.byIcon(Icons.play_arrow_rounded));
        final double dx = sourceTopLeft.dx - boardTopLeft.dx;
        final double dy = sourceTopLeft.dy - boardTopLeft.dy;

        Future<void> setMirror(int r, int c, int type) async {
          for (int t = 0; t < type; t++) {
            _tapGesture(tester, cells.at(r * 4 + c));
            await tester.pump();
          }
        }

        if (dy < 0) {
          // Puzzle 3: enters (0,1) going Down, target (2,3) going Right.
          // Wrong mirror `/` (type 1) at (2,1) sends beam Left off-board.
          await setMirror(2, 1, 1);
          await tester.pumpAndSettle();
          expect(find.byType(GameCompletionDialog), findsNothing);
          // Cycling once more to `\` (type 2) sends beam Right to (2,3) -> solved!
          await setMirror(2, 1, 1);
        } else if (dx < 0 && dy > 50) {
          // Puzzle 1: enters (1,0) going Right, target (3,0) going Left.
          // Mirror `\` (2) at (1,0) alone exits Down at (3,0) instead of Left.
          await setMirror(1, 0, 2);
          await tester.pumpAndSettle();
          expect(find.byType(GameCompletionDialog), findsNothing);
          // Adding `/` (1) at (3,0) exits Left -> solved!
          await setMirror(3, 0, 1);
        } else {
          // Puzzle 2: enters (0,0) going Right, target (3,2) going Down.
          // `/` (1) at (0,2) sends beam Up off-board -> unsolved.
          await setMirror(0, 2, 1);
          await tester.pumpAndSettle();
          expect(find.byType(GameCompletionDialog), findsNothing);
          // Cycling once more to `\` (2) at (0,2) sends beam Down to (3,2) -> solved!
          await setMirror(0, 2, 1);
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

        final Finder dockPieces = find.ancestor(
          of: find.text('SELECT'),
          matching: find.byType(GestureDetector),
        );
        final int pieceCount = dockPieces.evaluate().length;
        expect(pieceCount, inInclusiveRange(2, 3));

        // The 16 grid cells precede the dock pieces under TangramScreen.
        final Finder allGestures = find.descendant(
          of: find.byType(TangramScreen),
          matching: find.byType(GestureDetector),
        );
        // Filter to the 4x4 board cells inside the 240x240 Container.
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
        expect(allGestures, findsWidgets);

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

        Finder dockAt(int idx) => find
            .descendant(
              of: find.byType(FittedBox).last,
              matching: find.byType(GestureDetector),
            )
            .at(idx);

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

        if (outline.length == 9) {
          // Puzzle 1: 3x3 square: 2x2 at (0,0), 1x3 rotated vertical at (0,2), 1x2 at (2,0).
          // First place piece 2 outside outline at (3,0) -> must not solve.
          await placePiece(0, 0, 0, 0);
          await placePiece(1, 1, 0, 2);
          await placePiece(2, 0, 3, 0);
          await tester.pumpAndSettle();
          expect(find.byType(GameCompletionDialog), findsNothing);
          // Piece 2 remains selected after placement; tap (2,0) -> exact 3x3 tiling!
          _tapGesture(tester, gridCells.at(2 * 4 + 0));
        } else if (outline.length == 6) {
          // Puzzle 2: stair {(0,0),(1,0),(1,1),(2,0),(2,1),(2,2)}:
          // L-shape {(0,0),(1,0),(1,1)} at (0,0), 1x2 at (2,0), 1x1 at (2,2).
          await placePiece(0, 0, 0, 0);
          await placePiece(1, 0, 2, 0);
          await placePiece(2, 0, 0, 3); // wrong cell outside outline
          await tester.pumpAndSettle();
          expect(find.byType(GameCompletionDialog), findsNothing);
          _tapGesture(tester, gridCells.at(2 * 4 + 2));
        } else {
          // Puzzle 3: cross {(0,1),(1,0),(1,1),(1,2),(2,1)}:
          // T-shape at (0,0), 1x1 at (2,1).
          await placePiece(0, 0, 0, 0);
          await placePiece(1, 0, 0, 0); // wrong cell outside outline
          await tester.pumpAndSettle();
          expect(find.byType(GameCompletionDialog), findsNothing);
          _tapGesture(tester, gridCells.at(2 * 4 + 1));
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

void _tapGesture(WidgetTester tester, Finder finder) {
  tester.widget<GestureDetector>(finder).onTap!();
}
