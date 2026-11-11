import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/map/map_engine.dart';

void main() {
  const engine = MapEngine();

  group('generator', () {
    for (final difficulty in MapDifficulty.values) {
      test('${difficulty.name}: 20 maps, each four-coloured', () {
        final rng = Random(difficulty.index + 37);
        for (var i = 0; i < 20; i++) {
          final puzzle = engine.generate(difficulty, random: rng);
          final where = '${difficulty.name} map $i';

          expect(puzzle.rows, difficulty.rows);
          expect(puzzle.cols, difficulty.cols);
          expect(puzzle.regionCount, difficulty.regions);
          expect(puzzle.regionOf.length, puzzle.cellCount);
          expect(puzzle.regionOf.toSet().length, difficulty.regions,
              reason: '$where: a region is empty');

          // Every region is one piece: cells of a region are connected.
          for (var region = 0; region < difficulty.regions; region++) {
            final cells = [
              for (var cell = 0; cell < puzzle.cellCount; cell++)
                if (puzzle.regionOf[cell] == region) cell,
            ];
            expect(cells, isNotEmpty, reason: '$where: region $region is empty');
            final seen = <int>{cells.first};
            final queue = [cells.first];
            while (queue.isNotEmpty) {
              final cell = queue.removeLast();
              final row = cell ~/ puzzle.cols;
              final col = cell % puzzle.cols;
              for (final other in [
                if (row > 0) cell - puzzle.cols,
                if (row + 1 < puzzle.rows) cell + puzzle.cols,
                if (col > 0) cell - 1,
                if (col + 1 < puzzle.cols) cell + 1,
              ]) {
                if (puzzle.regionOf[other] != region) continue;
                if (seen.add(other)) queue.add(other);
              }
            }
            expect(seen.length, cells.length,
                reason: '$where: region $region is in pieces');
          }

          // Adjacency is symmetric and never mentions a region itself.
          for (var region = 0; region < difficulty.regions; region++) {
            expect(puzzle.adjacency[region], isNotEmpty,
                reason: '$where: region $region touches nothing');
            expect(puzzle.adjacency[region].contains(region), isFalse);
            for (final neighbour in puzzle.adjacency[region]) {
              expect(puzzle.adjacency[neighbour].contains(region), isTrue,
                  reason: '$where: $region/$neighbour is one-way');
            }
          }

          // The stored answer is a legal colouring that uses all four colours.
          expect(engine.isSolved(puzzle, puzzle.solution), isTrue,
              reason: '$where: the stored answer clashes');
          expect(puzzle.solution.toSet().length, mapColourCount,
              reason: '$where: the answer does not use four colours');
          expect(engine.conflicts(puzzle, puzzle.solution), isEmpty);
        }
      });
    }
  });

  group('rules', () {
    test('a clash is found, and only where the clash is', () {
      final puzzle = engine.generate(MapDifficulty.easy, random: Random(4));
      final colouring = [...puzzle.solution];
      // Give region 0 the colour of one of its neighbours.
      final neighbour = puzzle.adjacency[0].first;
      colouring[0] = colouring[neighbour];

      expect(engine.isSolved(puzzle, colouring), isFalse);
      final conflicts = engine.conflicts(puzzle, colouring);
      expect(conflicts.contains(0), isTrue);
      expect(conflicts.contains(neighbour), isTrue);
      // Nothing unrelated is blamed.
      for (var region = 0; region < puzzle.regionCount; region++) {
        if (region == 0 || region == neighbour) continue;
        final clashes = puzzle.adjacency[region]
            .any((other) => colouring[other] == colouring[region]);
        expect(conflicts.contains(region), clashes,
            reason: 'region $region blamed wrongly');
      }
    });

    test('an uncoloured region is not a win', () {
      final puzzle = engine.generate(MapDifficulty.easy, random: Random(6));
      final colouring = [...puzzle.solution];
      colouring[0] = -1;
      expect(engine.isSolved(puzzle, colouring), isFalse);
    });

    test('every colouring that fits wins, not just the stored one', () {
      final puzzle = engine.generate(MapDifficulty.easy, random: Random(8));
      // Rotate the stored colouring: a different answer, equally valid.
      final rotated = [for (final colour in puzzle.solution) (colour + 1) % mapColourCount];
      expect(engine.isSolved(puzzle, rotated), isTrue,
          reason: 'Map must accept any valid colouring');
    });
  });

  group('hint', () {
    test('suggests a colour that does not clash', () {
      final puzzle = engine.generate(MapDifficulty.medium, random: Random(10));
      final colouring = List<int>.filled(puzzle.regionCount, -1);
      for (var i = 0; i < puzzle.regionCount; i++) {
        final hint = engine.hint(puzzle, colouring);
        expect(hint, isNotNull, reason: 'no hint with $i coloured');
        // The suggested colour must be legal for that region.
        expect(colouring[hint!.region], -1,
            reason: 'hint names an already-coloured region');
        for (final neighbour in puzzle.adjacency[hint.region]) {
          expect(colouring[neighbour], isNot(hint.colour),
              reason: 'hint suggests a clashing colour');
        }
        colouring[hint.region] = hint.colour;
      }
      expect(engine.isSolved(puzzle, colouring), isTrue,
          reason: 'following the hints must finish the map');
    });
  });
}
