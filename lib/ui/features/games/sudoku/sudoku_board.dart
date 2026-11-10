import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';

import '../../../core/board/puzzle_board.dart';
import '../../../../utils/design_system.dart';
import 'sudoku_engine.dart';
import 'sudoku_provider.dart';

/// Sudoku on the board contract.
///
/// The grid and the digit tray are one board, so the pad is not chrome with its
/// own gestures: tapping a digit is a board tap, and dragging a digit onto a
/// cell is a declared move like any other.
class SudokuBoard extends PuzzleBoard<SudokuState> {
  SudokuBoard({required this.state});

  static const int _size = SudokuEngine.size;

  /// The grid is square, so the board box is taller than it is wide by exactly
  /// the tray it carries underneath.
  static const double gridHeight = 0.84;
  static const double trayTop = 0.875;
  static const double trayHeight = 0.105;

  @override
  final SudokuState state;

  @override
  double get aspectRatio => 1 / gridHeight;

  @override
  bool get isSolved => state.isSolved;

  // --------------------------------------------------------------- geometry

  Rect _cellRect(int row, int col) => Rect.fromLTWH(
        col / _size,
        row / _size * gridHeight,
        1 / _size,
        gridHeight / _size,
      );

  Rect _trayRect(int slot) =>
      Rect.fromLTWH(slot / 10, trayTop, 1 / 10, trayHeight);

  static ElementRef cell(int row, int col) => ElementRef('cell', row, col);

  static ElementRef digit(int value) => ElementRef('digit', value);

  static const ElementRef erase = ElementRef('erase', 0);

  @override
  List<ElementRef> get elements => [
        for (var row = 0; row < _size; row++)
          for (var col = 0; col < _size; col++) cell(row, col),
        for (var value = 1; value <= _size; value++) digit(value),
        erase,
      ];

  @override
  Rect? boundsOf(ElementRef element) {
    switch (element.kind) {
      case 'cell':
        return _cellRect(element.a, element.b);
      case 'digit':
        return _trayRect(element.a - 1);
      case 'erase':
        return _trayRect(9);
    }
    return null;
  }

  // ------------------------------------------------------------------- rules

  bool _isGiven(int row, int col) => state.initialBoard[row][col] != 0;

  static bool _editable(SudokuState state, int row, int col) =>
      state.initialBoard[row][col] == 0 && !state.isSolved;

  SudokuState _write(SudokuState current, int row, int col, int value) {
    if (!_editable(current, row, col)) return current;
    final board = [
      for (final line in current.currentBoard) line.toList(),
    ];
    board[row][col] = value;
    return current.copyWith(
      currentBoard: board.map((line) => line.lock).toIList(),
      selectedRow: row,
      selectedCol: col,
    );
  }

  PuzzleMove<SudokuState> _place(ElementRef source, int row, int col, int value) {
    return PuzzleMove<SudokuState>(
      kind: value == 0 ? MoveKind.clear : MoveKind.place,
      source: source,
      target: cell(row, col),
      apply: (current) {
        final existing = current.currentBoard[row][col];
        return _write(current, row, col, existing == value ? 0 : value);
      },
    );
  }

  @override
  List<PuzzleMove<SudokuState>> movesFor(ElementRef element) {
    if (element.kind == 'digit') {
      final value = element.a;
      return [
        for (var row = 0; row < _size; row++)
          for (var col = 0; col < _size; col++)
            if (_editable(state, row, col) && state.currentBoard[row][col] != value)
              _place(element, row, col, value),
      ];
    }
    if (element == erase) {
      return [
        for (var row = 0; row < _size; row++)
          for (var col = 0; col < _size; col++)
            if (_editable(state, row, col) && state.currentBoard[row][col] != 0)
              _place(element, row, col, 0),
      ];
    }
    return const [];
  }

  @override
  PuzzleMove<SudokuState>? tapMove(ElementRef element) {
    if (element.kind == 'cell') {
      final row = element.a;
      final col = element.b;
      return PuzzleMove<SudokuState>(
        kind: MoveKind.select,
        source: element,
        apply: (current) => current.copyWith(selectedRow: row, selectedCol: col),
      );
    }

    final row = state.selectedRow;
    final col = state.selectedCol;
    if (row == null || col == null || !_editable(state, row, col)) return null;

    if (element.kind == 'digit') {
      return _place(element, row, col, element.a);
    }
    if (element == erase) {
      return _place(element, row, col, 0);
    }
    return null;
  }

  // ------------------------------------------------------------------- paint

  @override
  void paint(PuzzleCanvas canvas, SudokuState state) {
    final palette = canvas.palette;
    canvas.bed();

    final grid = Rect.fromLTWH(0, 0, 1, gridHeight);
    canvas.cell(grid, fill: palette.surface, radius: DesignSystem.radiusMD);

    for (var row = 0; row < _size; row++) {
      for (var col = 0; col < _size; col++) {
        final element = cell(row, col);
        if (canvas.isHidden(element)) continue;
        _paintCell(canvas, state, row, col);
      }
    }

    // Box separators, the only 2.5dp strokes on the board.
    for (var i = 1; i < 3; i++) {
      final x = i * 3 / _size;
      final y = i * 3 / _size * gridHeight;
      canvas.line(Offset(x, 0), Offset(x, gridHeight),
          color: palette.ink, width: 2.5);
      canvas.line(Offset(0, y), Offset(1, y),
          color: palette.ink, width: 2.5);
    }

    for (var value = 1; value <= _size; value++) {
      final element = digit(value);
      if (!canvas.isHidden(element)) _paintDigit(canvas, state, value);
    }
    if (!canvas.isHidden(erase)) _paintErase(canvas);
  }

  void _paintCell(PuzzleCanvas canvas, SudokuState state, int row, int col) {
    final palette = canvas.palette;
    final rect = _cellRect(row, col);
    final value = state.currentBoard[row][col];
    final given = _isGiven(row, col);
    final selected =
        state.selectedRow == row && state.selectedCol == col;
    final selectedValue = _selectedValue(state);
    final sameDigit = selectedValue != 0 && value == selectedValue;
    final related = _isRelated(state, row, col);
    final conflict = value != 0 &&
        !given &&
        !SudokuEngine().isValid(state.currentBoard, row, col, value);

    final zone = canvas.highlight.targetAlpha(cell(row, col));

    // Two fills at most: the base, then one state.
    if (selected) {
      canvas.cell(rect, fill: palette.primary.withValues(alpha: 0.16));
    } else if (sameDigit) {
      canvas.cell(rect, fill: DesignSystem.accentAmber.withValues(alpha: 0.14));
    } else if (related) {
      canvas.cell(rect, fill: palette.outline.withValues(alpha: 0.45));
    }
    if (zone > 0) {
      canvas.cell(rect, fill: palette.primary.withValues(alpha: 0.08 * zone * 2));
    }
    if (conflict) {
      canvas.cell(
        rect.deflate(0.002),
        fill: palette.error.withValues(alpha: 0.12),
        stroke: palette.error.withValues(alpha: 0.85),
      );
    }

    if (value == 0) return;
    final cellSize = canvas.size.width / _size;
    canvas.text(
      '$value',
      rect,
      fontSize: cellSize * 0.52,
      weight: given ? FontWeight.w900 : FontWeight.w700,
      color: conflict
          ? palette.error
          : given
              ? palette.ink
              : palette.primary,
    );
  }

  int _selectedValue(SudokuState state) {
    final row = state.selectedRow;
    final col = state.selectedCol;
    if (row == null || col == null) return 0;
    return state.currentBoard[row][col];
  }

  bool _isRelated(SudokuState state, int row, int col) {
    final selectedRow = state.selectedRow;
    final selectedCol = state.selectedCol;
    if (selectedRow == null || selectedCol == null) return false;
    if (selectedRow == row && selectedCol == col) return false;
    return selectedRow == row ||
        selectedCol == col ||
        (row ~/ 3 == selectedRow ~/ 3 && col ~/ 3 == selectedCol ~/ 3);
  }

  void _paintDigit(PuzzleCanvas canvas, SudokuState state, int value) {
    final palette = canvas.palette;
    final rect = _trayRect(value - 1);
    final remaining = _remaining(state, value);
    final zone = canvas.highlight.targetAlpha(digit(value));
    final done = remaining == 0;

    canvas.cell(
      rect.deflate(0.008),
      fill: done
          ? palette.success.withValues(alpha: 0.12)
          : palette.surface,
      stroke: zone > 0
          ? palette.primary.withValues(alpha: 0.4 + 0.6 * zone)
          : palette.outline,
      strokeWidth: zone > 0 ? 2.5 : 1.5,
    );
    canvas.text(
      '$value',
      rect,
      fontSize: canvas.size.width * 0.052,
      weight: FontWeight.w700,
      color: done ? palette.success : palette.primary,
    );
  }

  int _remaining(SudokuState state, int value) {
    var count = 0;
    for (final line in state.currentBoard) {
      for (final entry in line) {
        if (entry == value) count++;
      }
    }
    return _size - count;
  }

  void _paintErase(PuzzleCanvas canvas) {
    final palette = canvas.palette;
    final rect = _trayRect(9).deflate(0.008);
    canvas.cell(rect, fill: palette.surface, stroke: palette.outline);
    final centre = rect.center;
    final arm = rect.width * 0.16;
    canvas.line(centre + Offset(-arm, -arm), centre + Offset(arm, arm),
        color: palette.muted, width: 2);
    canvas.line(centre + Offset(arm, -arm), centre + Offset(-arm, arm),
        color: palette.muted, width: 2);
  }

  @override
  void paintElement(PuzzleCanvas canvas, SudokuState state, ElementRef element) {
    switch (element.kind) {
      case 'cell':
        _paintCell(canvas, state, element.a, element.b);
      case 'digit':
        _paintDigit(canvas, state, element.a);
      case 'erase':
        _paintErase(canvas);
    }
  }
}
