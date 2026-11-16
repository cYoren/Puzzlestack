/// The one rule these games live or die by: a tap lands in the same frame.
///
/// The owner's words: "the games being magical is instant feedback, fast — no
/// lag — but still with our smooth animations", with Signpost as the reference
/// ("the arrow appears the moment you move"). So a tap must have written its
/// state before the next frame is painted. Motion is allowed to decorate a move
/// after the state has landed; it is never allowed to delay it.
///
/// Before this file existed the engine ran a 160ms snap spring on a tap that
/// had a target and only committed the move when the spring ended, so tapping a
/// cell and waiting one frame showed nothing had happened. Every game below is
/// played through the real screen, the real board and the real notifier: the
/// assertion is that the state object the board holds is a different one after
/// `pump()`, not after `pumpAndSettle()`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/core/board/puzzle_board_view.dart';
import 'package:puzzle/utils/design_system.dart';

class _FakeRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}
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

/// The board inside the view, without naming its type parameter.
PuzzleBoard<PuzzleState> _board(WidgetTester tester) =>
    (tester.widget(_boardFinder) as dynamic).board as PuzzleBoard<PuzzleState>;

Offset _centreOf(WidgetTester tester, Rect bounds) {
  final rect = tester.getRect(_boardFinder);
  return Offset(
    rect.left + rect.width * bounds.center.dx,
    rect.top + rect.height * bounds.center.dy,
  );
}

/// The first element whose tap does something, skipping [avoid].
ElementRef? _firstTap(PuzzleBoard<PuzzleState> board, {ElementRef? avoid}) {
  for (final element in board.elements) {
    if (element == avoid) continue;
    if (board.tapMove(element) == null) continue;
    if (board.boundsOf(element) == null) continue;
    return element;
  }
  return null;
}

/// The first element whose tap lands a *spatial* move: a link, a pour, a digit
/// onto a cell. These are the moves that used to wait for the snap spring.
ElementRef? _firstSpatial(PuzzleBoard<PuzzleState> board) {
  for (final element in board.elements) {
    final move = board.tapMove(element);
    if (move == null || move.target == null) continue;
    if (board.boundsOf(element) == null) continue;
    return element;
  }
  return null;
}

/// One game's plan: how many taps to land, and whether one of them must be a
/// move with a destination.
///
/// A tap that lands a digit, a link or a pour is the case the old engine
/// delayed behind its snap spring, so those games must exercise one. A game
/// whose taps all resolve in place (a cycle, a turn) has nothing spatial to
/// reach, and only owes the same-frame rule.
class _Plan {
  const _Plan(this.taps, {this.landsSpatial = false});

  final int taps;
  final bool landsSpatial;
}

/// Taps [plan.taps] times, letting exactly one frame go by after each tap.
///
/// Every step must have changed the state in that frame. A spatial move is
/// preferred whenever one is on offer, and when it is not the walk moves on to
/// the next element that accepts a tap, so a plan never depends on knowing one
/// game's geometry.
Future<void> _walkBoard(WidgetTester tester, String id, _Plan plan) async {
  ElementRef? previous;
  var spatial = 0;

  for (var step = 0; step < plan.taps; step++) {
    final board = _board(tester);
    final element = _firstSpatial(board) ?? _firstTap(board, avoid: previous);
    if (element == null) {
      fail('$id: nothing left to tap at step ${step + 1}');
    }
    final move = board.tapMove(element)!;
    if (move.target != null) spatial++;

    final before = board.state;
    await tester.tapAt(_centreOf(tester, board.boundsOf(element)!));
    // One frame. No settle and no `pumpAndSettle`: if the move needs an
    // animation to finish before the state moves, this is where it shows up.
    await tester.pump();
    final after = _board(tester).state;
    expect(
      identical(before, after),
      isFalse,
      reason: '$id: step ${step + 1} (tap $element) did not land in one frame',
    );
    previous = element;
  }

  if (plan.landsSpatial) {
    expect(spatial, greaterThan(0),
        reason: '$id: the plan never exercised a move with a target');
  }
}

/// The games this file guards, and what a tap on each one proves.
///
/// Four are named by the job (signpost, salad, mathrax, sudoku) and three are
/// picked to be representative: water_sort pours onto a tube (a spatial move
/// with its own transition), kurodoko cycles a cell through two colours, and
/// twiddle turns a square (a move *and* a transition running together, the case
/// where motion must not gate the state).
final _plans = <String, _Plan>{
  // Signpost is the reference: select a cell, then tap where its arrow goes.
  'signpost': _Plan(2, landsSpatial: true),
  'salad': _Plan(2),
  'mathrax': _Plan(2),
  // A clue cannot take a digit, so the walk may need a second cell before the
  // tray offers one; four taps always reaches an editable cell.
  // Sudoku's tray only offers a target once a cell is selected, so a step can
  // legitimately be a plain select; signpost and water_sort carry the spatial
  // proof instead of a coin-flip on which cell the walk lands on first.
  'sudoku': _Plan(4),
  'water_sort': _Plan(2, landsSpatial: true),
  'kurodoko': _Plan(2),
  // A tap that turns a square: the move carries a transition as well, so this
  // is the game where the old settle used to run *before* the rotation.
  'twiddle': _Plan(2),
};

/// The games whose first board is built in a background isolate.
///
/// `compute` is real async, and a widget test's fake clock never delivers its
/// reply: these three need `runAsync` before their board exists at all. Every
/// other game in the list above is ready after one frame.
const _buildsInAnIsolate = {'sudoku'};

void main() {
  for (final id in _plans.keys) {
    final metadata = allGamesMetadata.firstWhere((game) => game.id == id);

    testWidgets('$id lands every tap in one frame', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      if (_buildsInAnIsolate.contains(id)) {
        await tester.runAsync(() async {
          await tester.pumpWidget(_app(Builder(builder: metadata.builder)));
          // Generation is not the subject here: wait for the isolate that
          // builds the first board, then play. Polled rather than a fixed
          // sleep so the file stays inside its two-second budget.
          for (var i = 0; i < 80 && _boardFinder.evaluate().isEmpty; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await tester.pump();
          }
        });
      } else {
        await tester.pumpWidget(_app(Builder(builder: metadata.builder)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pump();

      expect(_boardFinder, findsOneWidget, reason: '$id has no board');

      await _walkBoard(tester, id, _plans[id]!);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
