import 'dart:math';

import 'package:puzzle/ui/features/games/mathrax/mathrax_engine.dart';
import 'package:puzzle/ui/features/games/mathrax/mathrax_puzzle.dart';

void main() {
  const engine = MathraxEngine();
  for (final size in MathraxSize.values) {
    final times = <int>[];
    final clueCounts = <int>[];
    var level = <int, int>{};
    for (var i = 0; i < 12; i++) {
      final watch = Stopwatch()..start();
      final puzzle = engine.generate(size, random: Random(100 + i));
      watch.stop();
      times.add(watch.elapsedMilliseconds);
      clueCounts.add(puzzle.clues.where((c) => c != null).length);
      final l = engine.levelOf(puzzle) ?? -1;
      level[l] = (level[l] ?? 0) + 1;
    }
    times.sort();
    clueCounts.sort();
    // ignore: avoid_print
    print('${size.name} ${size.n}x${size.n}: median ${times[times.length ~/ 2]} ms, '
        'max ${times.last} ms, clues ${clueCounts.first}..${clueCounts.last}, '
        'levels $level');
  }
}
