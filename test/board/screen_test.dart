import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/ui/core/board/puzzle_board_view.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_provider.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_screen.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_board.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_provider.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_screen.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_board.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_engine.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_provider.dart';
import 'package:puzzle/ui/features/games/slitherlink/slitherlink_screen.dart';
import 'package:puzzle/utils/design_system.dart';

IList<IList<int>> _grid(List<List<int>> rows) =>
    rows.map((row) => row.lock).toIList();

SudokuState _state() {
  final blank = List.generate(9, (_) => List.filled(9, 0));
  blank[0][0] = 5;
  return SudokuState(
    initialBoard: _grid(blank),
    currentBoard: _grid(blank),
    solvedBoard: _grid(blank),
  );
}

const Color red = Color(0xFFEF4444);
const Color blue = Color(0xFF3B82F6);

class _FixedSlitherlink extends SlitherlinkNotifier {
  _FixedSlitherlink(this.fixed);

  final SlitherlinkState fixed;

  @override
  SlitherlinkState build() => fixed;
}

class _FixedWater extends WaterSortNotifier {
  _FixedWater(this.fixed);

  final WaterSortState fixed;

  @override
  WaterSortState build() => fixed;
}

class _FixedSudoku extends SudokuNotifier {
  _FixedSudoku(this.fixed);

  final SudokuState fixed;

  @override
  Future<SudokuState> build() async => fixed;
}

void main() {
  testWidgets('the Sudoku screen plays: select a cell, tap a digit',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sudokuNotifierProvider.overrideWith(() => _FixedSudoku(_state())),
        ],
        child: MaterialApp(
          theme: DesignSystem.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SudokuScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PuzzleBoardView<SudokuState>), findsOneWidget);
    expect(tester.takeException(), isNull);

    final board = tester.getRect(find.byType(PuzzleBoardView<SudokuState>));
    // Cell (0,1): second column of the top row of a square grid that fills the
    // top 84% of the board box.
    final cell = Offset(
      board.left + board.width * (1.5 / 9),
      board.top + board.height * (0.5 / 9) * 0.84,
    );
    await tester.tapAt(cell);
    await tester.pumpAndSettle();

    // Digit 3 sits in the third slot of the ten-slot tray.
    final digit = Offset(
      board.left + board.width * (2.5 / 10),
      board.top + board.height * (0.875 + 0.105 / 2),
    );
    await tester.tapAt(digit);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(PuzzleBoardView<SudokuState>), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SudokuScreen)),
    );
    final played = container.read(sudokuNotifierProvider).value!;
    expect(played.currentBoard[0][1], 3,
        reason: 'the tap reached the notifier through the board');
  });

  testWidgets('the Water Sort screen pours by tap', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final start = WaterSortState(
      tubes: [
        [red, blue],
        [blue],
        [],
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          waterSortNotifierProvider.overrideWith(() => _FixedWater(start)),
        ],
        child: MaterialApp(
          theme: DesignSystem.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WaterSortScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final board = tester.getRect(find.byType(PuzzleBoardView<WaterSortState>));
    Offset tubeCentre(int index) {
      final column = index % WaterSortBoard.columns;
      final row = index ~/ WaterSortBoard.columns;
      return Offset(
        board.left + board.width * (WaterSortBoard.left +
            column * WaterSortBoard.gapX +
            WaterSortBoard.tubeWidth / 2),
        board.top + board.height * (WaterSortBoard.top +
            row * WaterSortBoard.gapY +
            WaterSortBoard.tubeHeight / 2),
      );
    }

    await tester.tapAt(tubeCentre(0));
    await tester.pumpAndSettle();
    await tester.tapAt(tubeCentre(1));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WaterSortScreen)),
    );
    final played = container.read(waterSortNotifierProvider);
    expect(played.tubes[0], [red]);
    expect(played.tubes[1], [blue, blue]);
  });

  testWidgets('the Slitherlink screen draws an edge on tap', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    const size = 3;
    final start = SlitherlinkState(
      level: SlitherlinkLevel(
        size: size,
        clues: List.generate(size, (_) => List<int?>.filled(size, null)),
        solutionHEdges:
            List.generate(size + 1, (_) => List.filled(size, false)),
        solutionVEdges:
            List.generate(size, (_) => List.filled(size + 1, false)),
      ),
      currentHEdges: List.generate(size + 1, (_) => List.filled(size, false)),
      currentVEdges: List.generate(size, (_) => List.filled(size + 1, false)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          slitherlinkNotifierProvider.overrideWith(
            () => _FixedSlitherlink(start),
          ),
        ],
        child: MaterialApp(
          theme: DesignSystem.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SlitherlinkScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final board = tester.getRect(
      find.byType(PuzzleBoardView<SlitherlinkState>),
    );
    final step = (1 - 2 * SlitherlinkBoard.margin) / size;
    final edge = Offset(
      board.left + board.width * (SlitherlinkBoard.margin + step / 2),
      board.top + board.height * SlitherlinkBoard.margin,
    );

    await tester.tapAt(edge);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SlitherlinkScreen)),
    );
    expect(container.read(slitherlinkNotifierProvider).currentHEdges[0][0],
        isTrue);
  });
}
