/// A drag must land its move in the frame the finger lifts.
///
/// A tap already does (see `instant_input_test.dart`). A drag did not: the
/// engine ran the 160ms snap spring first and only called `onMove` when the
/// spring ended, so the board was 160ms (plus the transition that followed)
/// behind the finger. The owner's words: "not decrease animations, animations
/// are untouched, I mean latency in the game". So this measures the moment the
/// *state* changes, not the animation: the spring, its duration and its feel
/// stay exactly where they were, only the model moves first.
///
/// The stopwatch is the test binding's clock (`tester.binding.clock`), i.e. the
/// same clock frames are pumped with, not a wall-clock estimate.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/core/board/puzzle_board_view.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_provider.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_screen.dart';
import 'package:puzzle/utils/design_system.dart';

class _FakeRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}

  @override
  List<GameStreak> getAllGameStreaks() => const [];

  @override
  Future<void> saveGameCompletion(UserData userData, GameStreak streak) async {}
}

Widget _app(Widget child) => ProviderScope(
      overrides: [userRepositoryProvider.overrideWithValue(_FakeRepository())],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

/// `find.byType(PuzzleBoardView)` never matches: Dart erases the type argument
/// (papercuts.md).
final Finder _boardFinder =
    find.byWidgetPredicate((widget) => widget is PuzzleBoardView);

PuzzleBoard<PuzzleState> _board(WidgetTester tester) =>
    (tester.widget(_boardFinder) as dynamic).board as PuzzleBoard<PuzzleState>;

Offset _centreOf(WidgetTester tester, Rect bounds) {
  final rect = tester.getRect(_boardFinder);
  return Offset(
    rect.left + rect.width * bounds.center.dx,
    rect.top + rect.height * bounds.center.dy,
  );
}

/// Drags the first draggable element of [board] onto its first target and
/// returns how long after the finger lifted the state took to change.
///
/// One frame is the bar. The loop pumps 16ms at a time, so the returned
/// duration is measured by the same clock the frames run on.
Future<({int frames, Duration elapsed, bool moved, ElementRef? target})>
    _dragAndTime(WidgetTester tester, PuzzleBoard<PuzzleState> board) async {
  final element = board.elements.firstWhere(
    (element) =>
        board.movesFor(element).any((move) => move.target != null) &&
        board.boundsOf(element) != null,
    orElse: () => throw StateError('this board has no draggable element'),
  );
  final move =
      board.movesFor(element).firstWhere((move) => move.target != null);
  final target = move.target!;

  final start = _centreOf(tester, board.boundsOf(element)!);
  final end = _centreOf(tester, board.boundsOf(target)!);
  final before = board.state;

  final gesture = await tester.startGesture(start);
  await tester.pump();
  // Cross the pan slop so the engine lifts, then follow to the target.
  await gesture.moveBy(const Offset(0, 20));
  await tester.pump();
  await gesture.moveTo(end);
  await tester.pump();

  final stopwatch = tester.binding.clock.stopwatch()..start();
  await gesture.up();

  // The frame of the finger-up itself: no clock advance, like the tap test.
  var frames = 1;
  await tester.pump();
  while (identical(_board(tester).state, before) && frames < 120) {
    await tester.pump(const Duration(milliseconds: 16));
    frames++;
  }
  stopwatch.stop();

  return (
    frames: frames,
    elapsed: stopwatch.elapsed,
    moved: !identical(_board(tester).state, before),
    target: target,
  );
}

void main() {
  testWidgets('a drag lands its move in the frame the finger lifts',
      (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const InertiaScreen()));
    await tester.pumpAndSettle();

    final board = _board(tester);
    final measured = await _dragAndTime(tester, board);

    // The record, not an estimate: the number this job is about.
    // ignore: avoid_print
    print('inertia drag commit: ${measured.elapsed.inMilliseconds}ms '
        '(${measured.frames} frame(s))');

    expect(measured.moved, isTrue,
        reason: 'the drag never changed the game state');
    expect(
      measured.elapsed,
      lessThan(const Duration(milliseconds: 17)),
      reason: 'the state landed ${measured.elapsed.inMilliseconds}ms after the '
          'finger lifted (${measured.frames} frames); a drag must commit in '
          'the frame of the finger-up, like a tap',
    );

    // The move really happened: the ball is on the landing square the drag
    // aimed at, not back where it started.
    final state = _board(tester).state as InertiaState;
    expect(state.position.cell,
        measured.target!.a * state.cols + measured.target!.b);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
      'a landed drag stops painting its lifted copy when the transition starts',
      (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const InertiaScreen()));
    await tester.pumpAndSettle();

    final board = _board(tester);
    final measured = await _dragAndTime(tester, board);
    expect(measured.moved, isTrue, reason: 'the drag never moved the board');

    // The state has landed and Inertia's own transition now owns the painting:
    // the carried copy must be gone, or the marble is drawn twice on the way
    // to its destination.
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .where((painter) =>
            painter != null &&
            painter.runtimeType.toString().startsWith('_BoardPainter'))
        .toList();
    expect(painters, isNotEmpty, reason: 'no board painter on screen');
    for (final painter in painters) {
      expect((painter as dynamic).liftedState, isNull,
          reason:
              'the lifted copy is still painted after the transition took over');
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a tap still lands in one frame after the drag change',
      (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const InertiaScreen()));
    await tester.pumpAndSettle();

    final board = _board(tester);
    final element = board.elements.firstWhere(
      (element) => board.tapMove(element)?.target != null,
      orElse: () => throw StateError('inertia offers no spatial tap'),
    );

    final before = board.state;
    final stopwatch = tester.binding.clock.stopwatch()..start();
    await tester.tapAt(_centreOf(tester, board.boundsOf(element)!));
    await tester.pump();
    stopwatch.stop();

    // ignore: avoid_print
    print('inertia tap commit: ${stopwatch.elapsed.inMilliseconds}ms');
    expect(identical(_board(tester).state, before), isFalse);
    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 17)),
        reason: 'a tap must still land in the frame of the tap');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
