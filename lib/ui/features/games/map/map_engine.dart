/// Map: a rectangular board cut into regions. Colour every region with one of
/// four colours so that no two touching regions share a colour.
///
/// Ported from Tatham's `map.c`. The model is the board itself: the generator
/// grows regions, works out which ones touch, and four-colours the result by
/// backtracking. That colouring is the stored answer.
///
/// **This puzzle has many answers, on purpose.** Any valid four-colouring wins,
/// which is what makes it feel like colouring a map rather than solving a
/// Sudoku. So there is nothing to count: the test proves the stored answer is
/// valid, and the rules are the rules.
library;

import 'dart:math';

class MapPuzzle {
  const MapPuzzle({
    required this.rows,
    required this.cols,
    required this.regionOf,
    required this.regionCount,
    required this.adjacency,
    required this.solution,
  });

  final int rows;
  final int cols;

  /// One region index per cell, row-major.
  final List<int> regionOf;

  final int regionCount;

  /// Region -> the regions it shares an edge with.
  final List<Set<int>> adjacency;

  /// The colouring the generator found: one colour 0..3 per region.
  final List<int> solution;

  int get cellCount => rows * cols;

  /// How many neighbours each region has, for the HUD and for tests.
  int neighboursOf(int region) => adjacency[region].length;
}

enum MapDifficulty {
  easy(5, 5, 5),
  medium(6, 6, 8),
  hard(7, 7, 11);

  const MapDifficulty(this.rows, this.cols, this.regions);

  final int rows;
  final int cols;

  /// How many regions the board is cut into. More regions means a denser
  /// adjacency graph, and a denser graph is what makes four colours tight.
  final int regions;
}

/// Four colours, and no more: the four-colour theorem is the whole reason this
/// puzzle is a puzzle, so the count is not a coincidence.
const int mapColourCount = 4;

class MapEngine {
  const MapEngine();

  // --------------------------------------------------------------- generator

  MapPuzzle generate(MapDifficulty difficulty, {Random? random}) {
    final rng = random ?? Random();
    final rows = difficulty.rows;
    final cols = difficulty.cols;

    for (var attempt = 0; attempt < 500; attempt++) {
      final regionOf = _growRegions(rows, cols, difficulty.regions, rng);
      if (regionOf == null) continue;

      final adjacency = _adjacencyOf(regionOf, rows, cols, difficulty.regions);
      // A region that touches nothing is a free colour and a boring cell; a
      // graph that is in pieces is two easy puzzles on one board.
      if (adjacency.any((neighbours) => neighbours.isEmpty)) continue;
      if (!_isConnected(adjacency)) continue;

      final solution = _fourColour(adjacency, rng);
      if (solution == null) continue;

      // Every colour has to appear, or the palette is lying about being four.
      if (solution.toSet().length < mapColourCount) continue;

      return MapPuzzle(
        rows: rows,
        cols: cols,
        regionOf: regionOf,
        regionCount: difficulty.regions,
        adjacency: adjacency,
        solution: solution,
      );
    }
    throw StateError('could not cut a ${rows}x$cols map into '
        '${difficulty.regions} regions');
  }

  /// Multi-source breadth-first growth from random seeds: every cell joins the
  /// nearest seed, ties broken at random, which gives the blobby regions a map
  /// wants rather than stripes.
  List<int>? _growRegions(int rows, int cols, int regions, Random rng) {
    final regionOf = List<int>.filled(rows * cols, -1);
    final seeds = <int>[];
    while (seeds.length < regions) {
      final cell = rng.nextInt(rows * cols);
      if (seeds.contains(cell)) continue;
      seeds.add(cell);
      regionOf[cell] = seeds.length - 1;
    }

    var frontier = [...seeds];
    while (frontier.isNotEmpty) {
      final next = <int>[];
      for (final cell in frontier) {
        final region = regionOf[cell];
        for (final neighbour in _orthogonal(cell, rows, cols)) {
          if (regionOf[neighbour] != -1) continue;
          // Only the cell we came from may claim it in this round; ties inside
          // one round would make the shape depend on iteration order.
          regionOf[neighbour] = region;
          next.add(neighbour);
        }
      }
      if (next.isEmpty) break;
      next.shuffle(rng);
      frontier = next;
    }

    return regionOf.contains(-1) ? null : regionOf;
  }

  List<Set<int>> _adjacencyOf(
    List<int> regionOf,
    int rows,
    int cols,
    int regions,
  ) {
    final adjacency = List.generate(regions, (_) => <int>{});
    for (var cell = 0; cell < regionOf.length; cell++) {
      final region = regionOf[cell];
      final row = cell ~/ cols;
      final col = cell % cols;
      if (col + 1 < cols) {
        final other = regionOf[cell + 1];
        if (other != region) {
          adjacency[region].add(other);
          adjacency[other].add(region);
        }
      }
      if (row + 1 < rows) {
        final other = regionOf[cell + cols];
        if (other != region) {
          adjacency[region].add(other);
          adjacency[other].add(region);
        }
      }
    }
    return adjacency;
  }

  bool _isConnected(List<Set<int>> adjacency) {
    final seen = <int>{0};
    final queue = [0];
    while (queue.isNotEmpty) {
      final region = queue.removeLast();
      for (final neighbour in adjacency[region]) {
        if (seen.add(neighbour)) queue.add(neighbour);
      }
    }
    return seen.length == adjacency.length;
  }

  /// Four-colouring by backtracking, most-constrained region first.
  ///
  /// On graphs this small (eleven regions) plain backtracking is instant, and it
  /// beats a clever algorithm on the one thing that matters here: it is short
  /// enough to read and it cannot be subtly wrong.
  List<int>? _fourColour(List<Set<int>> adjacency, Random rng) {
    final colours = List<int>.filled(adjacency.length, -1);

    bool place() {
      var target = -1;
      var fewest = mapColourCount + 1;
      for (var region = 0; region < adjacency.length; region++) {
        if (colours[region] != -1) continue;
        final blocked = <int>{
          for (final neighbour in adjacency[region])
            if (colours[neighbour] != -1) colours[neighbour],
        };
        final free = mapColourCount - blocked.length;
        if (free < fewest) {
          fewest = free;
          target = region;
          if (free <= 1) break;
        }
      }
      if (target == -1) return true;

      final blocked = <int>{
        for (final neighbour in adjacency[target])
          if (colours[neighbour] != -1) colours[neighbour],
      };
      final options = [
        for (var colour = 0; colour < mapColourCount; colour++)
          if (!blocked.contains(colour)) colour,
      ]..shuffle(rng);

      for (final colour in options) {
        colours[target] = colour;
        if (place()) return true;
      }
      colours[target] = -1;
      return false;
    }

    return place() ? colours : null;
  }

  List<int> _orthogonal(int cell, int rows, int cols) {
    final row = cell ~/ cols;
    final col = cell % cols;
    return [
      if (row > 0) cell - cols,
      if (row + 1 < rows) cell + cols,
      if (col > 0) cell - 1,
      if (col + 1 < cols) cell + 1,
    ];
  }

  // ------------------------------------------------------------------- rules

  /// A colouring wins when every region has a colour and no two touching
  /// regions share one. Any such colouring is a win.
  bool isSolved(MapPuzzle puzzle, List<int> colours) {
    for (var region = 0; region < puzzle.regionCount; region++) {
      if (colours[region] < 0 || colours[region] >= mapColourCount) return false;
      for (final neighbour in puzzle.adjacency[region]) {
        if (colours[neighbour] == colours[region]) return false;
      }
    }
    return true;
  }

  /// The regions whose colour clashes with a neighbour — the ones to mark red.
  Set<int> conflicts(MapPuzzle puzzle, List<int> colours) {
    final out = <int>{};
    for (var region = 0; region < puzzle.regionCount; region++) {
      final colour = colours[region];
      if (colour < 0) continue;
      for (final neighbour in puzzle.adjacency[region]) {
        if (colours[neighbour] == colour) {
          out
            ..add(region)
            ..add(neighbour);
        }
      }
    }
    return out;
  }

  /// A region the player could colour next, and the colour, from the rules
  /// alone: the only colour left for it, or the only region that can take a
  /// colour in its neighbourhood.
  ({int region, int colour})? hint(MapPuzzle puzzle, List<int> colours) {
    // One colour left for a region.
    for (var region = 0; region < puzzle.regionCount; region++) {
      if (colours[region] != -1) continue;
      final blocked = {
        for (final neighbour in puzzle.adjacency[region]) colours[neighbour],
      };
      final free = [
        for (var colour = 0; colour < mapColourCount; colour++)
          if (!blocked.contains(colour)) colour,
      ];
      if (free.length == 1) return (region: region, colour: free.single);
    }

    // A colour that fits exactly one region anywhere.
    for (var colour = 0; colour < mapColourCount; colour++) {
      final candidates = <int>[];
      for (var region = 0; region < puzzle.regionCount; region++) {
        if (colours[region] != -1) continue;
        final blocked = {
          for (final neighbour in puzzle.adjacency[region]) colours[neighbour],
        };
        if (!blocked.contains(colour)) candidates.add(region);
      }
      if (candidates.length == 1) {
        return (region: candidates.single, colour: colour);
      }
    }

    // Nothing is forced: suggest a colour for an uncoloured region that does
    // not clash, so the player is never left with no move.
    for (var region = 0; region < puzzle.regionCount; region++) {
      if (colours[region] != -1) continue;
      final blocked = {
        for (final neighbour in puzzle.adjacency[region]) colours[neighbour],
      };
      for (var colour = 0; colour < mapColourCount; colour++) {
        if (!blocked.contains(colour)) return (region: region, colour: colour);
      }
    }
    return null;
  }
}
