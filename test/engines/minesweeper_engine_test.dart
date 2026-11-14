import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/minesweeper/minesweeper_engine.dart';

void main() {
  group('MinesweeperEngine', () {
    late MinesweeperEngine engine;

    setUp(() {
      engine = MinesweeperEngine(rows: 5, cols: 5, mineCount: 5);
    });

    group('generateBoard', () {
      test('returns board with correct dimensions', () {
        final board = engine.generateBoard();
        expect(board.length, equals(5));
        for (final row in board) {
          expect(row.length, equals(5));
        }
      });

      test('board contains correct number of mines', () {
        final board = engine.generateBoard();
        int mineCount = 0;
        for (final row in board) {
          for (final cell in row) {
            if (cell.isMine) mineCount++;
          }
        }
        expect(mineCount, equals(5));
      });

      test('all cells are initially hidden', () {
        final board = engine.generateBoard();
        for (final row in board) {
          for (final cell in row) {
            expect(cell.state, equals(CellState.hidden));
          }
        }
      });

      test('neighbor counts are correct', () {
        final board = engine.generateBoard();
        for (int r = 0; r < 5; r++) {
          for (int c = 0; c < 5; c++) {
            int expected = 0;
            for (int dr = -1; dr <= 1; dr++) {
              for (int dc = -1; dc <= 1; dc++) {
                int nr = r + dr, nc = c + dc;
                if (nr >= 0 && nr < 5 && nc >= 0 && nc < 5) {
                  if (board[nr][nc].isMine) expected++;
                }
              }
            }
            expect(board[r][c].neighborMines, equals(expected),
                reason: 'Wrong count at ($r,$c)');
          }
        }
      });

      test('avoids mines near start position', () {
        final board = engine.generateBoard(startRow: 2, startCol: 2);
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            expect(board[2 + dr][2 + dc].isMine, isFalse,
                reason: 'Mine near start at (${2 + dr},${2 + dc})');
          }
        }
      });
    });

    group('revealEmptyCells', () {
      test('reveals the target cell', () {
        final board = engine.generateBoard();
        // Find a cell with 0 neighbor mines
        for (int r = 0; r < 5; r++) {
          for (int c = 0; c < 5; c++) {
            if (!board[r][c].isMine && board[r][c].neighborMines == 0) {
              engine.revealEmptyCells(board, r, c);
              expect(board[r][c].state, equals(CellState.revealed));
              return;
            }
          }
        }
      });

      test('does not reveal mine cells', () {
        final board = engine.generateBoard();
        for (int r = 0; r < 5; r++) {
          for (int c = 0; c < 5; c++) {
            if (board[r][c].isMine) {
              engine.revealEmptyCells(board, r, c);
              expect(board[r][c].state, equals(CellState.hidden));
            }
          }
        }
      });

      test('flood fill reveals connected empty cells', () {
        final board = engine.generateBoard();
        // Find a 0-cell and reveal
        for (int r = 0; r < 5; r++) {
          for (int c = 0; c < 5; c++) {
            if (!board[r][c].isMine && board[r][c].neighborMines == 0) {
              engine.revealEmptyCells(board, r, c);
              // At least the target cell should be revealed
              expect(board[r][c].state, equals(CellState.revealed));
              // Adjacent cells with 0 should also be revealed
              bool foundRevealed = false;
              for (int dr = -1; dr <= 1; dr++) {
                for (int dc = -1; dc <= 1; dc++) {
                  int nr = r + dr, nc = c + dc;
                  if (nr >= 0 && nr < 5 && nc >= 0 && nc < 5) {
                    if (board[nr][nc].state == CellState.revealed) {
                      foundRevealed = true;
                    }
                  }
                }
              }
              expect(foundRevealed, isTrue);
              return;
            }
          }
        }
      });
    });

    group('checkWin', () {
      test('returns true when all non-mine cells are revealed', () {
        final board = engine.generateBoard();
        for (int r = 0; r < 5; r++) {
          for (int c = 0; c < 5; c++) {
            if (!board[r][c].isMine) {
              board[r][c] = board[r][c].copyWith(state: CellState.revealed);
            }
          }
        }
        expect(engine.checkWin(board), isTrue);
      });

      test('returns false when some non-mine cells are hidden', () {
        final board = engine.generateBoard();
        expect(engine.checkWin(board), isFalse);
      });

      test('returns false when all cells are hidden', () {
        final board = engine.generateBoard();
        expect(engine.checkWin(board), isFalse);
      });
    });

    group('the first tap is always fair', () {
      // The guarantee the deck depends on: from the first tap on, a player who only reads the
      // numbers never has to guess. Checked by replaying that reasoning on the dealt board, so
      // this fails if the generator starts dealing ambiguous boards again.
      for (final spec in [
        (rows: 5, cols: 5, mines: 5),
        (rows: 6, cols: 6, mines: 5),
        (rows: 8, cols: 8, mines: 10),
        (rows: 10, cols: 8, mines: 12),
      ]) {
        test('${spec.rows}x${spec.cols} with ${spec.mines} mines, thirty deals',
            () {
          final engine = MinesweeperEngine(
            rows: spec.rows,
            cols: spec.cols,
            mineCount: spec.mines,
          );
          final startRow = spec.rows ~/ 2;
          final startCol = spec.cols ~/ 2;
          for (var deal = 0; deal < 30; deal++) {
            final board =
                engine.generateBoard(startRow: startRow, startCol: startCol);
            expect(
              engine.isSolvableWithoutGuess(board, startRow, startCol),
              isTrue,
              reason: 'deal $deal at ${spec.rows}x${spec.cols} needs a guess',
            );
          }
        });
      }

      test('the first tap opens an area, not one cell', () {
        final engine = MinesweeperEngine(rows: 6, cols: 6, mineCount: 5);
        for (var deal = 0; deal < 20; deal++) {
          final board = engine.generateBoard(startRow: 3, startCol: 3);
          final opened = engine.revealEmptyCells(board, 3, 3);
          final revealed = opened
              .expand((row) => row)
              .where((cell) => cell.state == CellState.revealed)
              .length;
          expect(revealed, greaterThanOrEqualTo(9),
              reason:
                  'the 3x3 around the first tap is mine-free, so it all opens');
        }
      });

      test('the solver is not a rubber stamp', () {
        // A solver that answers yes to everything would pass the guarantee above. This shows it
        // answers no: the same size with the start block left unprotected deals guessing
        // boards most of the time.
        final engine = MinesweeperEngine(rows: 8, cols: 8, mineCount: 10);
        var unsolvable = 0;
        for (var deal = 0; deal < 40; deal++) {
          final board = engine.generateBoard();
          if (!engine.isSolvableWithoutGuess(board, 3, 3)) unsolvable++;
        }
        expect(unsolvable, greaterThan(0));
      });

      test('a tap with no room around it is refused', () {
        final engine = MinesweeperEngine(rows: 3, cols: 3, mineCount: 8);
        expect(
          () => engine.generateBoard(startRow: 1, startCol: 1),
          throwsArgumentError,
        );
      });

      test('a density with no fair deal is refused, not dealt', () {
        // Over half the board mined: nothing a player can deduce finishes that, so the engine
        // says so instead of dealing a game that needs luck. The sizes the app deals (5x5 up
        // to 10x8) are far below this and are covered by the group above.
        final engine = MinesweeperEngine(rows: 16, cols: 12, mineCount: 90);
        expect(
          () => engine.generateBoard(startRow: 8, startCol: 6),
          throwsStateError,
        );
      });
    });

    group('MinesweeperCell', () {
      test('copyWith preserves fields', () {
        final cell = MinesweeperCell(
          row: 1,
          col: 2,
          isMine: true,
          neighborMines: 3,
          state: CellState.hidden,
        );
        final copy = cell.copyWith(state: CellState.revealed);
        expect(copy.row, equals(1));
        expect(copy.col, equals(2));
        expect(copy.isMine, isTrue);
        expect(copy.neighborMines, equals(3));
        expect(copy.state, equals(CellState.revealed));
      });
    });
  });
}
