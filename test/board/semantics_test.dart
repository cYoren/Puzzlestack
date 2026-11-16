/// The proof that every board has a text form: a screen reader can read the
/// cells, the values and what a tap does, and an agent can play a board by
/// activating a semantics node.
///
/// The contract itself is a toy board below (so a change to a game cannot hide
/// a broken default), then three real games of different shapes: a `GridBoard`,
/// a board painted through `PuzzleMarks`, and a board with its own painter and
/// non-cell elements. Every shape is played through the semantics tree, not
/// through a finger: a finger already has its own tests.
library;

import 'dart:math';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/core/board/puzzle_board_view.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_board.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_engine.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_provider.dart';
import 'package:puzzle/ui/features/games/seismic/seismic_board.dart';
import 'package:puzzle/ui/features/games/seismic/seismic_engine.dart';
import 'package:puzzle/ui/features/games/seismic/seismic_provider.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_board.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_engine.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_provider.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_board.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_provider.dart';
import 'package:puzzle/utils/design_system.dart';

// ---------------------------------------------------------------- the default

class _ToyState extends PuzzleState {
  const _ToyState();
}

/// A board that overrides nothing but the four required members, to prove the
/// text form a board gets for free.
class _ToyBoard extends PuzzleBoard<_ToyState> {
  static const ElementRef cell = ElementRef('cell', 2, 3);
  static const ElementRef dot = ElementRef('vertex', 1);

  @override
  _ToyState get state => const _ToyState();

  @override
  List<ElementRef> get elements => const [cell, dot];

  @override
  Rect? boundsOf(ElementRef element) => element == cell
      ? const Rect.fromLTWH(0, 0, 0.5, 1)
      : const Rect.fromLTWH(0.5, 0, 0.5, 1);

  @override
  List<PuzzleMove<_ToyState>> movesFor(ElementRef element) => const [];

  @override
  PuzzleMove<_ToyState>? tapMove(ElementRef element) => element == cell
      ? PuzzleMove<_ToyState>(
          kind: MoveKind.select,
          source: cell,
          apply: (current) => current,
        )
      : null;

  @override
  bool get isSolved => false;

  @override
  void paint(PuzzleCanvas canvas, _ToyState state) {}

  @override
  void paintElement(PuzzleCanvas canvas, _ToyState state, ElementRef element) {}
}

// -------------------------------------------------------------------- the host

Widget _host<S extends PuzzleState>(
  PuzzleBoard<S> board,
  ValueChanged<PuzzleMove<S>> onMove,
) {
  return MaterialApp(
    theme: DesignSystem.lightTheme,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          height: 320,
          child: PuzzleBoardView<S>(board: board, onMove: onMove),
        ),
      ),
    ),
  );
}

/// The semantics node a listener lands on for [label].
SemanticsNode _node(WidgetTester tester, String label) =>
    tester.getSemantics(find.bySemanticsLabel(label));

void _expectTappable(SemanticsNode node) {
  expect(
    node.getSemanticsData().hasAction(SemanticsAction.tap),
    isTrue,
    reason: '"${node.label}" offers no tap',
  );
}

void _expectNotTappable(SemanticsNode node) {
  expect(
    node.getSemanticsData().hasAction(SemanticsAction.tap),
    isFalse,
    reason: '"${node.label}" claims a tap it does not have',
  );
}

/// Activate [node] the way a screen reader does, not with a finger.
///
/// `pipelineOwner` is deprecated in favour of a `SemanticsBinding` API that this
/// Flutter version does not expose to a test; the owner is the same tree the
/// finders read, so this is the action a listener would take.
void _activate(WidgetTester tester, SemanticsNode node) {
  // ignore: deprecated_member_use
  tester.binding.pipelineOwner.semanticsOwner!.performAction(
    node.id,
    SemanticsAction.tap,
  );
}

// ------------------------------------------------------------------- fixtures

KurodokoPuzzle get _kurodokoPuzzle => KurodokoPuzzle(
      rows: 1,
      cols: 3,
      clues: const [0, 3, 0],
      solution: const [
        KurodokoCell.white,
        KurodokoCell.white,
        KurodokoCell.white
      ],
    );

KurodokoState _kurodoko() => KurodokoState(
      puzzle: _kurodokoPuzzle,
      grid: List<KurodokoCell>.filled(3, KurodokoCell.unknown),
      difficulty: KurodokoDifficulty.easy,
    );

/// 9x9 with a given 5 at the top-left and a written 3 in the middle.
SudokuState _sudoku() {
  List<List<int>> blank() => List.generate(9, (_) => List.filled(9, 0));
  final initial = blank();
  initial[0][0] = 5;
  final current = blank();
  current[0][0] = 5;
  current[2][2] = 3;
  return SudokuState(
    initialBoard: initial.map((row) => row.lock).toIList(),
    currentBoard: current.map((row) => row.lock).toIList(),
    solvedBoard: blank().map((row) => row.lock).toIList(),
    selectedRow: 2,
    selectedCol: 2,
  );
}

SlitherlinkState _slitherlink({bool drawn = false}) {
  const size = 2;
  return SlitherlinkState(
    level: SlitherlinkLevel(
      size: size,
      clues: List.generate(size, (_) => List<int?>.filled(size, null)),
      solutionHEdges: List.generate(size + 1, (_) => List.filled(size, false)),
      solutionVEdges: List.generate(size, (_) => List.filled(size + 1, false)),
    ),
    currentHEdges: [
      for (var row = 0; row <= size; row++)
        [for (var col = 0; col < size; col++) row == 0 && col == 0 && drawn],
    ],
    currentVEdges: List.generate(size, (_) => List.filled(size + 1, false)),
  );
}

void main() {
  group('the default text form', () {
    test('names any element by coordinate, with no board edit', () {
      final board = _ToyBoard();
      expect(board.describeElement(_ToyBoard.cell), 'row 3, column 4');
      expect(board.describeElement(_ToyBoard.dot), 'corner 2');
      expect(board.semanticsShape, 'board of 2 elements');
      expect(board.semanticsSummary, 'board of 2 elements');
    });

    test('says nothing a board has not told it', () {
      final board = _ToyBoard();
      expect(board.valueOf(_ToyBoard.cell), isNull);
      expect(board.isFixed(_ToyBoard.cell), isFalse);
    });

    test('derives the tap verb from the move, not from prose', () {
      final board = _ToyBoard();
      expect(board.describeTap(_ToyBoard.cell), 'select');
      expect(board.describeTap(_ToyBoard.dot), isNull);
    });

    test('a grid says its rows and columns', () {
      final board = KurodokoBoard(state: _kurodoko());
      expect(board.semanticsShape, '1 by 3 grid');
    });
  });

  group('a grid board', () {
    testWidgets('reads every cell, its value and its tap', (tester) async {
      final handle = tester.ensureSemantics();

      final moves = <PuzzleMove<KurodokoState>>[];
      await tester.pumpWidget(
        _host(KurodokoBoard(state: _kurodoko()), moves.add),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel('1 by 3 grid'),
        findsOneWidget,
        reason: 'the summary line is missing',
      );
      expect(find.bySemanticsLabel('row 1, column 1'), findsOneWidget);
      expect(find.bySemanticsLabel('row 1, column 3'), findsOneWidget);

      final editable = _node(tester, 'row 1, column 1');
      _expectTappable(editable);
      expect(editable.hint, 'tap to place');
      expect(editable.value, isEmpty);

      final clue = _node(tester, 'row 1, column 2');
      expect(clue.value, '3, fixed');
      _expectNotTappable(clue);

      _activate(tester, editable);
      await tester.pump();
      expect(moves, hasLength(1));
      expect(moves.single.source, const ElementRef('cell', 0, 0));
      handle.dispose();
    });
  });

  group('a board with values and a tray', () {
    testWidgets('a given reads fixed, a written digit does not', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_host(SudokuBoard(state: _sudoku()), (_) {}));
      await tester.pump();

      expect(
        find.bySemanticsLabel('9 by 9 grid with a digit tray'),
        findsOneWidget,
      );
      expect(_node(tester, 'row 1, column 1').value, '5, fixed');
      expect(_node(tester, 'row 3, column 3').value, '3');
      expect(_node(tester, 'digit 5').hint, 'tap to place');
      _expectTappable(_node(tester, 'digit 5'));
      handle.dispose();
    });
  });

  group('a marks board', () {
    testWidgets('a written digit is its own value', (tester) async {
      final handle = tester.ensureSemantics();

      final puzzle = const SeismicEngine().generate(
        SeismicSize.small,
        random: Random(1),
      );
      final values = List<int>.filled(puzzle.cellCount, kSeismicBlank);
      values[0] = puzzle.solution[0];
      final board = SeismicBoard(
        state: SeismicState(
          puzzle: puzzle,
          values: values,
          size: SeismicSize.small,
        ),
      );

      await tester.pumpWidget(_host(board, (_) {}));
      await tester.pump();

      expect(find.bySemanticsLabel(board.semanticsSummary), findsOneWidget);
      expect(_node(tester, 'row 1, column 1').value, '${puzzle.solution[0]}');
      _expectTappable(_node(tester, 'row 1, column 1'));

      final given = puzzle.givens.indexWhere((v) => v != kSeismicNoClue);
      if (given >= 0) {
        final label =
            'row ${given ~/ puzzle.n + 1}, column ${given % puzzle.n + 1}';
        expect(_node(tester, label).value, '${puzzle.givens[given]}, fixed');
      }
      handle.dispose();
    });
  });

  group('a board with its own painter', () {
    testWidgets('edges read as lines and play by tap', (tester) async {
      final handle = tester.ensureSemantics();

      final moves = <PuzzleMove<SlitherlinkState>>[];
      await tester.pumpWidget(
        _host(SlitherlinkBoard(state: _slitherlink(drawn: true)), moves.add),
      );
      await tester.pump();

      final edge = _node(tester, 'horizontal edge at row 1, column 1');
      expect(edge.value, 'line');
      expect(edge.hint, 'tap to erase line');
      _expectTappable(edge);

      final corner = _node(tester, 'corner at row 1, column 1');
      expect(corner.value, isEmpty);
      expect(corner.hint, isEmpty);
      _expectNotTappable(corner);

      // An undrawn edge is still playable from the semantics tree.
      final empty = _node(tester, 'horizontal edge at row 1, column 2');
      expect(empty.value, isEmpty);
      expect(empty.hint, 'tap to draw line');
      _activate(tester, empty);
      await tester.pump();
      expect(moves, hasLength(1));
      expect(moves.single.source, SlitherlinkBoard.hEdge(0, 1));
      handle.dispose();
    });
  });
}
