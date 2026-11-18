import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/yajilin/yajilin_engine.dart';

void main() {
  group('YajilinEngine', () {
    test('generatePuzzle yields varied unique-solution 5x5 boards', () {
      final rng = Random(42);
      final clueSignatures = <String>{};
      for (int i = 0; i < 15; i++) {
        final puzzle = YajilinEngine.generatePuzzle(random: rng);
        expect(puzzle.size, 5);
        expect(
          YajilinEngine.countSolutions(puzzle.grid, puzzle.size),
          1,
          reason: 'Board $i must have a unique solution',
        );
        final sig = [
          for (int r = 0; r < puzzle.size; r++)
            for (int c = 0; c < puzzle.size; c++)
              if (puzzle.grid[r][c].clue != null)
                '$r,$c:${puzzle.grid[r][c].clue!.dir.name}:${puzzle.grid[r][c].clue!.count}',
        ].join('|');
        clueSignatures.add(sig);
      }
      expect(clueSignatures.length, greaterThan(5));
    });

    test('isSolved rejects disjoint loops and edges through black or clue cells', () {
      // 4x4 grid: row 0 has 0-count clue cells, rows 1..3 have non-black loop cells,
      // except we form two disjoint loops or touch a black cell.
      final grid = List.generate(
        4,
        (r) => List.generate(
          4,
          (c) => YajilinCell(
            r: r,
            c: c,
            clue: r == 0 ? YajilinClue(ArrowDirection.down, 0) : null,
          ),
        ),
      );
      // Disjoint two-component test on 4x4 without clues: put two 2x2 loops
      // separated cleanly with black cells? Better: 4x4 with no clues, all 16 cells
      // covered by two 2x2 loops: top 2 rows left/right or (0..1,0..1) and (2..3,2..3)
      // Wait: adjacent corners aren't edges! Make 4x4 all non-clue, split into
      // two 2x4 loops on left 2 cols and right 2 cols.
      final noClueGrid = List.generate(
        4,
        (r) => List.generate(4, (c) => YajilinCell(r: r, c: c)),
      );
      final twoLoops = <YajilinEdge>{
        // Loop 1: cols 0..1
        YajilinEdge(0, 0, 0, 1),
        YajilinEdge(0, 1, 1, 1),
        YajilinEdge(1, 1, 2, 1),
        YajilinEdge(2, 1, 3, 1),
        YajilinEdge(3, 1, 3, 0),
        YajilinEdge(3, 0, 2, 0),
        YajilinEdge(2, 0, 1, 0),
        YajilinEdge(1, 0, 0, 0),
        // Loop 2: cols 2..3
        YajilinEdge(0, 2, 0, 3),
        YajilinEdge(0, 3, 1, 3),
        YajilinEdge(1, 3, 2, 3),
        YajilinEdge(2, 3, 3, 3),
        YajilinEdge(3, 3, 3, 2),
        YajilinEdge(3, 2, 2, 2),
        YajilinEdge(2, 2, 1, 2),
        YajilinEdge(1, 2, 0, 2),
      };
      expect(YajilinEngine.isSolved(noClueGrid, twoLoops, 4), isFalse);

      // Valid single Hamiltonian loop on rows 1..3 (12 cells), clues on row 0
      final validEdges = <YajilinEdge>{
        YajilinEdge(1, 0, 1, 1),
        YajilinEdge(1, 1, 2, 1),
        YajilinEdge(2, 1, 2, 2),
        YajilinEdge(2, 2, 1, 2),
        YajilinEdge(1, 2, 1, 3),
        YajilinEdge(1, 3, 2, 3),
        YajilinEdge(2, 3, 3, 3),
        YajilinEdge(3, 3, 3, 2),
        YajilinEdge(3, 2, 3, 1),
        YajilinEdge(3, 1, 3, 0),
        YajilinEdge(3, 0, 2, 0),
        YajilinEdge(2, 0, 1, 0),
      };
      expect(YajilinEngine.isSolved(grid, validEdges, 4), isTrue);

      // Edge through a clue cell (degree 2 on clue cell) must still be rejected.
      final edgeThroughClue = {
        ...twoLoops,
      };
      expect(YajilinEngine.isSolved(grid, edgeThroughClue, 4), isFalse);

      // Adjacent black cells must be rejected even if loop looks valid otherwise.
      noClueGrid[0][0].state = YajilinCellState.black;
      noClueGrid[0][1].state = YajilinCellState.black;
      expect(YajilinEngine.isSolved(noClueGrid, twoLoops, 4), isFalse);
    });
  });
}
