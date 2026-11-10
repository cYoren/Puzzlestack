import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/core/board/puzzle_board_view.dart';

/// A board with two cells and one rule, used to test the contract itself
/// rather than any real puzzle.
class ToyState extends PuzzleState {
  const ToyState({this.left = 0, this.right = 0, this.selected = false});

  final int left;
  final int right;
  final bool selected;

  ToyState copyWith({int? left, int? right, bool? selected}) => ToyState(
        left: left ?? this.left,
        right: right ?? this.right,
        selected: selected ?? this.selected,
      );
}

class ToyBoard extends PuzzleBoard<ToyState> {
  ToyBoard({required this.state, this.solved = false});

  final bool solved;

  static const ElementRef left = ElementRef('cell', 0);
  static const ElementRef right = ElementRef('cell', 1);

  @override
  final ToyState state;

  @override
  List<ElementRef> get elements => [left, right];

  @override
  Rect? boundsOf(ElementRef element) => element == left
      ? const Rect.fromLTWH(0, 0, 0.5, 1)
      : const Rect.fromLTWH(0.5, 0, 0.5, 1);

  @override
  List<PuzzleMove<ToyState>> movesFor(ElementRef element) {
    if (element != left) return const [];
    return [
      PuzzleMove<ToyState>(
        kind: MoveKind.place,
        source: left,
        target: right,
        apply: (current) => current.copyWith(right: current.left + 1),
      ),
    ];
  }

  @override
  PuzzleMove<ToyState>? tapMove(ElementRef element) => PuzzleMove<ToyState>(
        kind: MoveKind.select,
        source: element,
        apply: (current) => current.copyWith(selected: !current.selected),
      );

  @override
  bool get isSolved => solved;

  @override
  void paint(PuzzleCanvas canvas, ToyState state) {}

  @override
  void paintElement(PuzzleCanvas canvas, ToyState state, ElementRef element) {}
}

void main() {
  group('contract', () {
    test('hit test finds the element under a normalised point', () {
      final board = ToyBoard(state: const ToyState());
      expect(board.hitTest(const Offset(0.25, 0.5)), ToyBoard.left);
      expect(board.hitTest(const Offset(0.75, 0.5)), ToyBoard.right);
    });

    test('a move is the only thing that changes state', () {
      final board = ToyBoard(state: const ToyState(left: 4));
      final move = board.movesFor(ToyBoard.left).single;
      final next = board.apply(board.state, move);
      expect(next.right, 5);
      expect(board.state.right, 0, reason: 'state is a value, not a mutation');
    });

    test('every draggable move names a target that the board can locate', () {
      final board = ToyBoard(state: const ToyState());
      for (final element in board.elements) {
        for (final move in board.movesFor(element)) {
          if (!move.isDraggable) continue;
          expect(board.boundsOf(move.target!), isNotNull);
        }
      }
    });
  });

  group('engine', () {
    Future<void> pumpBoard(
      WidgetTester tester,
      ToyBoard board,
      List<PuzzleMove<ToyState>> moves,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: PuzzleBoardView<ToyState>(
                  board: board,
                  onMove: moves.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Offset centreOf(WidgetTester tester, double x) {
      final box = tester.getRect(find.byType(PuzzleBoardView<ToyState>));
      return Offset(box.left + box.width * x, box.center.dy);
    }

    testWidgets('a tap resolves immediately', (tester) async {
      final moves = <PuzzleMove<ToyState>>[];
      await pumpBoard(tester, ToyBoard(state: const ToyState()), moves);

      await tester.tapAt(centreOf(tester, 0.25));
      await tester.pumpAndSettle();

      expect(moves, hasLength(1));
      expect(moves.single.kind, MoveKind.select);
    });

    testWidgets('a drag onto a legal target commits that move', (tester) async {
      final moves = <PuzzleMove<ToyState>>[];
      await pumpBoard(tester, ToyBoard(state: const ToyState()), moves);

      final gesture = await tester.startGesture(centreOf(tester, 0.25));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(moves, hasLength(1));
      expect(moves.single.kind, MoveKind.place);
      expect(moves.single.target, ToyBoard.right);
    });

    testWidgets('a drag onto nothing is refused, not applied', (tester) async {
      final moves = <PuzzleMove<ToyState>>[];
      await pumpBoard(tester, ToyBoard(state: const ToyState()), moves);

      final gesture = await tester.startGesture(centreOf(tester, 0.25));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveBy(const Offset(0, -120));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(moves, isEmpty);
    });

    testWidgets('the win cascade runs before the dialog is allowed',
        (tester) async {
      var solvedCalls = 0;
      Widget frame(ToyBoard board) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  child: PuzzleBoardView<ToyState>(
                    board: board,
                    onMove: (_) {},
                    onSolved: () => solvedCalls++,
                  ),
                ),
              ),
            ),
          );

      await tester.pumpWidget(frame(ToyBoard(state: const ToyState())));
      expect(solvedCalls, 0);

      await tester.pumpWidget(
        frame(ToyBoard(state: const ToyState(), solved: true)),
      );
      expect(solvedCalls, 0, reason: 'the celebration comes first');

      await tester.pumpAndSettle();
      expect(solvedCalls, 1);
    });

    testWidgets('a tap on an element with no tap move emits nothing',
        (tester) async {
      final moves = <PuzzleMove<ToyState>>[];
      final board = _SilentBoard(state: const ToyState());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: PuzzleBoardView<ToyState>(
                  board: board,
                  onMove: moves.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tapAt(centreOf(tester, 0.25));
      await tester.pumpAndSettle();
      expect(moves, isEmpty);
    });
  });
}

class _SilentBoard extends ToyBoard {
  _SilentBoard({required super.state});

  @override
  PuzzleMove<ToyState>? tapMove(ElementRef element) => null;
}
