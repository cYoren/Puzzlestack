import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/core/board/puzzle_board_view.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_board.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_engine.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_provider.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_board.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_provider.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_board.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_provider.dart';
import 'package:puzzle/utils/design_system.dart';

/// The gate says every board has to look right at 320dp and on a tablet, in
/// light and AMOLED dark. This renders all three at both sizes and both
/// themes, and fails on any layout exception.
IList<IList<int>> _grid(List<List<int>> rows) =>
    rows.map((row) => row.lock).toIList();

SudokuState _sudoku() {
  final blank = List.generate(9, (_) => List.filled(9, 0));
  blank[0][0] = 5;
  blank[4][4] = 9;
  return SudokuState(
    initialBoard: _grid(blank),
    currentBoard: _grid(blank),
    solvedBoard: _grid(blank),
    selectedRow: 4,
    selectedCol: 4,
  );
}

SlitherlinkState _slitherlink() {
  const size = 3;
  return SlitherlinkState(
    level: SlitherlinkLevel(
      size: size,
      clues: [
        [null, 2, null],
        [3, null, 1],
        [null, 2, null],
      ],
      solutionHEdges: List.generate(size + 1, (_) => List.filled(size, false)),
      solutionVEdges: List.generate(size, (_) => List.filled(size + 1, false)),
    ),
    currentHEdges: List.generate(size + 1, (_) => List.filled(size, false)),
    currentVEdges: List.generate(size, (_) => List.filled(size + 1, false)),
  );
}

WaterSortState _water() {
  const colours = [
    DesignSystem.gameBlue,
    DesignSystem.gameGreen,
    DesignSystem.gamePurple,
    DesignSystem.gameOrange,
    DesignSystem.gamePink,
  ];
  return WaterSortState(
    tubes: [
      for (final colour in colours) [for (var i = 0; i < 4; i++) colour],
      [],
      [],
    ],
    selectedTubeIndex: 0,
  );
}

Future<void> _render<S extends PuzzleState>(
  WidgetTester tester,
  PuzzleBoard<S> board,
  double width,
  Brightness brightness,
) async {
  tester.view.physicalSize = Size(width * 2, 1400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark
          ? DesignSystem.darkTheme
          : DesignSystem.lightTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: PuzzleBoardView<S>(board: board, onMove: (_) {}),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  for (final width in [320.0, 800.0]) {
    for (final brightness in Brightness.values) {
      final label = '${width.toInt()}dp ${brightness.name}';

      testWidgets('sudoku renders at $label', (tester) async {
        await _render(tester, SudokuBoard(state: _sudoku()), width, brightness);
      });

      testWidgets('slitherlink renders at $label', (tester) async {
        await _render(
          tester,
          SlitherlinkBoard(state: _slitherlink()),
          width,
          brightness,
        );
      });

      testWidgets('water sort renders at $label', (tester) async {
        await _render(
          tester,
          WaterSortBoard(state: _water()),
          width,
          brightness,
        );
      });
    }
  }
}
