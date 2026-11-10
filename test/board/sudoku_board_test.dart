import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_board.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_provider.dart';

IList<IList<int>> _grid(List<List<int>> rows) =>
    rows.map((row) => row.lock).toIList();

List<List<int>> _blank() => List.generate(9, (_) => List.filled(9, 0));

SudokuState _state({int given = 5}) {
  final initial = _blank();
  initial[0][0] = given;
  final current = _blank();
  current[0][0] = given;
  return SudokuState(
    initialBoard: _grid(initial),
    currentBoard: _grid(current),
    solvedBoard: _grid(initial),
  );
}

void main() {
  group('SudokuBoard', () {
    test('the grid is square and the tray sits below it', () {
      final board = SudokuBoard(state: _state());
      expect(board.aspectRatio * SudokuBoard.gridHeight, closeTo(1, 1e-9));
      expect(SudokuBoard.gridHeight, lessThan(SudokuBoard.trayTop));
      expect(SudokuBoard.trayTop + SudokuBoard.trayHeight,
          lessThanOrEqualTo(1.0));
    });

    test('every element sits inside the board box', () {
      final board = SudokuBoard(state: _state());
      for (final element in board.elements) {
        final bounds = board.boundsOf(element)!;
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(1.0));
        expect(bounds.bottom, lessThanOrEqualTo(1.0));
      }
    });

    test('the grid and the digit tray are one board', () {
      final board = SudokuBoard(state: _state());
      expect(board.elements.where((e) => e.kind == 'cell'), hasLength(81));
      expect(board.elements.where((e) => e.kind == 'digit'), hasLength(9));
      expect(board.elements.contains(SudokuBoard.erase), isTrue);
    });

    test('tapping a cell selects it', () {
      final board = SudokuBoard(state: _state());
      final move = board.tapMove(SudokuBoard.cell(0, 1))!;
      expect(move.kind, MoveKind.select);

      final next = board.apply(board.state, move);
      expect(next.selectedRow, 0);
      expect(next.selectedCol, 1);
    });

    test('tapping a digit writes it into the selected cell', () {
      final board = SudokuBoard(state: _state());
      final selected = board.apply(
        board.state,
        board.tapMove(SudokuBoard.cell(0, 1))!,
      );
      final withSelection = SudokuBoard(state: selected);

      final move = withSelection.tapMove(SudokuBoard.digit(3))!;
      final next = withSelection.apply(selected, move);
      expect(next.currentBoard[0][1], 3);
    });

    test('a given clue cannot be overwritten', () {
      final board = SudokuBoard(state: _state());
      final move = board.tapMove(SudokuBoard.cell(0, 0))!;
      final selected = board.apply(board.state, move);
      final withSelection = SudokuBoard(state: selected);

      expect(withSelection.tapMove(SudokuBoard.digit(7)), isNull);
    });

    test('dragging a digit offers every empty cell as a target', () {
      final board = SudokuBoard(state: _state());
      final moves = board.movesFor(SudokuBoard.digit(3));
      expect(moves, hasLength(80), reason: '81 cells minus the given clue');
      for (final move in moves) {
        expect(move.target, isNotNull);
        expect(board.boundsOf(move.target!), isNotNull);
      }
    });

    test('the same digit twice clears the cell', () {
      final board = SudokuBoard(state: _state());
      final selected = board.apply(
        board.state,
        board.tapMove(SudokuBoard.cell(0, 1))!,
      );
      final withSelection = SudokuBoard(state: selected);

      final once = withSelection.apply(
        selected,
        withSelection.tapMove(SudokuBoard.digit(3))!,
      );
      final twice = SudokuBoard(state: once).apply(
        once,
        SudokuBoard(state: once).tapMove(SudokuBoard.digit(3))!,
      );
      expect(twice.currentBoard[0][1], 0);
    });
  });
}
