import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/prime_factor_trees/prime_factor_trees_engine.dart';

void main() {
  group('PrimeFactorTreesEngine', () {
    test('every root can be completely solved without dropping valid factors', () {
      final probeEngine = PrimeFactorTreesEngine(random: Random(0));
      for (final root in probeEngine.puzzleRoots) {
        for (int seed = 0; seed < 5; seed++) {
          final engine = PrimeFactorTreesEngine(random: Random(seed));
          engine.generatePuzzle(root: root);
          for (int step = 0; step < 8 && !engine.isSolved(); step++) {
            final visibleUnsolved = engine.treeNodes.values
                .where((n) => n.isVisible && !n.isSolved)
                .toList();
            expect(visibleUnsolved, isNotEmpty);
            for (final node in visibleUnsolved) {
              final valid = engine.getValidFactors(node.index);
              expect(
                valid,
                isNotEmpty,
                reason: 'Node ${node.index} has no valid factors for root=$root',
              );
              expect(
                valid.any(engine.options.contains),
                isTrue,
                reason:
                    'Options ${engine.options} missed all valid factors $valid for root=$root',
              );
            }
            final target = visibleUnsolved.first;
            final valid = engine.getValidFactors(target.index);
            final choice = valid.firstWhere(engine.options.contains);
            expect(engine.submitAnswer(target.index, choice), isTrue);
          }
          expect(
            engine.isSolved(),
            isTrue,
            reason: 'Failed to solve root=$root (seed=$seed)',
          );
        }
      }
    });
  });
}
