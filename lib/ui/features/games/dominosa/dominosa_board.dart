import 'package:flutter/material.dart';

import '../../../core/board/grid_board.dart';
import '../../../core/board/puzzle_board.dart';
import 'dominosa_provider.dart';

/// Dominosa on the board contract.
///
/// Drag from a digit onto its neighbour and the domino lands between them.
/// Tapping works too: tap one cell, then an adjacent one.
class DominosaBoard extends GridBoard<DominosaState> {
  DominosaBoard({required this.state});

  @override
  final DominosaState state;

  @override
  int get rows => state.rows;

  @override
  int get cols => state.cols;

  @override
  bool get isSolved => state.isSolved;

  @override
  List<PuzzleMove<DominosaState>> movesFor(ElementRef element) {
    if (!isCell(element) || state.isSolved) return const [];
    final from = element.a * cols + element.b;
    if (state.placed.containsKey(from)) {
      final other = state.placed[from]!;
      return [
        PuzzleMove<DominosaState>(
          kind: MoveKind.clear,
          source: element,
          target: cell(other ~/ cols, other % cols),
          apply: (current) {
            final placed = {...current.placed};
            placed.remove(from);
            placed.remove(other);
            return current.copyWith(placed: placed, isSolved: false);
          },
        ),
      ];
    }

    final moves = <PuzzleMove<DominosaState>>[];
    for (final other in _freeNeighbours(from)) {
      final type = state.puzzleType(from, other);
      if (state.usedTypes.contains(type)) continue;
      moves.add(
        PuzzleMove<DominosaState>(
          kind: MoveKind.place,
          source: element,
          target: cell(other ~/ cols, other % cols),
          apply: (current) {
            final placed = {...current.placed};
            placed[from] = other;
            placed[other] = from;
            return current.copyWith(
              placed: placed,
              isSolved: placed.length == current.puzzle.cellCount,
            );
          },
        ),
      );
    }
    return moves;
  }

  List<int> _freeNeighbours(int cell) {
    final row = cell ~/ cols;
    final col = cell % cols;
    return [
      if (col + 1 < cols && !state.placed.containsKey(cell + 1)) cell + 1,
      if (col > 0 && !state.placed.containsKey(cell - 1)) cell - 1,
      if (row + 1 < rows && !state.placed.containsKey(cell + cols)) cell + cols,
      if (row > 0 && !state.placed.containsKey(cell - cols)) cell - cols,
    ];
  }

  @override
  PuzzleMove<DominosaState>? tapMove(ElementRef element) {
    if (!isCell(element) || state.isSolved) return null;
    final index = element.a * cols + element.b;
    final selected = state.selected;

    if (selected != null &&
        selected != index &&
        _freeNeighbours(selected).contains(index)) {
      final a = selected;
      final b = index;
      final type = state.puzzleType(a, b);
      if (!state.usedTypes.contains(type)) {
        return PuzzleMove<DominosaState>(
          kind: MoveKind.place,
          source: cell(a ~/ cols, a % cols),
          target: element,
          apply: (current) {
            final placed = {...current.placed};
            placed[a] = b;
            placed[b] = a;
            return current.copyWith(
              placed: placed,
              clearSelection: true,
              isSolved: placed.length == current.puzzle.cellCount,
            );
          },
        );
      }
    }

    return PuzzleMove<DominosaState>(
      kind: selected == index ? MoveKind.clear : MoveKind.select,
      source: element,
      apply: (current) => selected == index
          ? current.copyWith(clearSelection: true)
          : current.copyWith(selected: index),
    );
  }

  @override
  void paintCell(PuzzleCanvas canvas, DominosaState state, int row, int col) {
    final index = row * cols + col;
    final rect = cellRect(row, col);
    final palette = canvas.palette;
    final paired = state.placed.containsKey(index);
    final selected = state.selected == index;
    final hint = state.hintCell == index || state.hintPartner == index;

    canvas.cell(
      rect,
      fill: paired
          ? palette.primary.withValues(alpha: 0.12)
          : palette.surface,
      stroke: hint
          ? palette.success
          : selected
              ? palette.primary
              : palette.outline.withValues(alpha: 0.3),
      strokeWidth: hint || selected ? 2.5 : 1.5,
    );

    canvas.text(
      '${state.puzzle.grid[index]}',
      rect,
      color: paired ? palette.primary : palette.ink,
      fontSize: canvas.fontSizeFor(rect, 0.5),
      weight: FontWeight.w900,
    );
  }

  @override
  void paint(PuzzleCanvas canvas, DominosaState state) {
    super.paint(canvas, state);

    // A hairline between the two halves makes a placed domino read as one
    // object rather than two tinted cells.
    for (final entry in state.placed.entries) {
      if (entry.key > entry.value) continue;
      final a = entry.key;
      final b = entry.value;
      canvas.line(
        cellCenter(a ~/ cols, a % cols),
        cellCenter(b ~/ cols, b % cols),
        color: canvas.palette.primary.withValues(alpha: 0.35),
        width: 3,
      );
    }
  }
}
