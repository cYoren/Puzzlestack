import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/core/deduction.dart';

/// A deliberately tiny puzzle: every cell must end up holding the same value.
///
/// It exists to test the harness, not to be a game. The constraint lives in
/// [isComplete] rather than in a rule, so a board can be fully decided and
/// still be wrong — which is what "impossible" has to mean.
class ChainModel implements DeductionModel<ChainModel> {
  ChainModel(this.cells);

  final List<int?> cells;

  @override
  ChainModel copy() => ChainModel([...cells]);

  @override
  bool get isComplete =>
      cells.every((cell) => cell != null) && cells.toSet().length == 1;

  @override
  Choice? get choice {
    final slot = cells.indexWhere((cell) => cell == null);
    if (slot < 0) return null;
    return Choice(slot, const [0, 1]);
  }

  @override
  ChainModel assume(int slot, int value) {
    final next = copy();
    next.cells[slot] = value;
    return next;
  }

  @override
  String toString() => 'ChainModel($cells)';
}

/// Level 1: a decided cell decides the rest, and two disagreeing cells are a
/// contradiction.
class PropagateRule implements DeductionRule<ChainModel> {
  const PropagateRule({this.level = 1});

  @override
  final int level;

  @override
  String get name => 'propagate';

  @override
  int apply(ChainModel model) {
    final decided = model.cells.whereType<int>().toSet();
    if (decided.length > 1) return -1;
    if (decided.isEmpty) return 0;

    final value = decided.single;
    var settled = 0;
    for (var i = 0; i < model.cells.length; i++) {
      if (model.cells[i] == null) {
        model.cells[i] = value;
        settled++;
      }
    }
    return settled;
  }
}

/// A rule that knows nothing, so a test can prove the harness really does try
/// the next level instead of stopping at the first.
class NoopRule implements DeductionRule<ChainModel> {
  const NoopRule({this.level = 1});

  @override
  final int level;

  @override
  String get name => 'noop';

  @override
  int apply(ChainModel model) => 0;
}

void main() {
  group('deduce', () {
    test('runs to a fixed point and reports what it settled', () {
      final model = ChainModel([0, null, null]);
      final outcome = deduce(model, const [PropagateRule()]);

      expect(outcome.consistent, isTrue);
      expect(outcome.complete, isTrue);
      expect(outcome.settled, 2);
      expect(outcome.highestLevel, 1);
      expect(outcome.rounds, 1);
      expect(model.cells, [0, 0, 0]);
    });

    test('a rule that learns nothing stops the loop', () {
      final model = ChainModel([null, null]);
      final outcome = deduce(model, const [PropagateRule()]);

      expect(outcome.consistent, isTrue);
      expect(outcome.complete, isFalse);
      expect(outcome.settled, 0);
      expect(outcome.rounds, 0);
    });

    test('a contradiction stops the run', () {
      final outcome = deduce(ChainModel([0, 1]), const [PropagateRule()]);

      expect(outcome.consistent, isFalse);
      expect(outcome.complete, isFalse);
    });

    test('reports the hardest rule that fired', () {
      final outcome = deduce(
        ChainModel([0, null]),
        const [NoopRule(), PropagateRule(level: 3)],
      );

      expect(outcome.complete, isTrue);
      expect(outcome.highestLevel, 3);
    });
  });

  group('countSolutions', () {
    test('counts one solution', () {
      final count = countSolutions(
        ChainModel([0, null, null]),
        const [PropagateRule()],
      );

      expect(count.count, 1);
      expect(count.truncated, isFalse);
      expect(count.isUnique, isTrue);
    });

    test('counts two and stops at the limit', () {
      final count = countSolutions(
        ChainModel([null, null]),
        const [PropagateRule()],
      );

      expect(count.count, 2);
      expect(count.isUnique, isFalse);
    });

    test('a board that cannot be finished has no solutions', () {
      final count = countSolutions(
        ChainModel([0, 1]),
        const [PropagateRule()],
      );

      expect(count.count, 0);
    });

    test('a board with a free cell and no rules gives up honestly', () {
      // Neither cell is decided and no rule can decide one, so the search has
      // to guess. It finds two answers, which is the truth about this board.
      final count = countSolutions(
        ChainModel([null, null]),
        const [NoopRule()],
      );

      expect(count.count, 2);
    });

    test('says so when it runs out of budget', () {
      final count = countSolutions(
        ChainModel([null, null, null, null, null, null, null, null]),
        const [NoopRule()],
        maxNodes: 2,
      );

      expect(count.truncated, isTrue);
      expect(count.isUnique, isFalse);
    });
  });

  group('solvingLevel', () {
    test('level 1 when the easy rule is enough', () {
      expect(
        solvingLevel(ChainModel([0, null]), const [PropagateRule()]),
        1,
      );
    });

    test('level 3 when only the hard rule gets there', () {
      expect(
        solvingLevel(
          ChainModel([0, null]),
          const [NoopRule(), PropagateRule(level: 3)],
        ),
        3,
      );
    });

    test('0 when the board is already finished', () {
      expect(
        solvingLevel(ChainModel([0, 0]), const [PropagateRule()]),
        0,
      );
    });

    test('null when no rule can finish it', () {
      expect(
        solvingLevel(ChainModel([0, null]), const [NoopRule()]),
        isNull,
      );
    });
  });

  group('rate', () {
    test('solved, with the level it needed', () {
      final rating = rate(ChainModel([0, null]), const [PropagateRule()]);

      expect(rating.verdict, PuzzleVerdict.solved);
      expect(rating.level, 1);
      expect(rating.solutions, 1);
      expect(rating.isPlayable, isTrue);
    });

    test('ambiguous when two answers fit', () {
      final rating = rate(ChainModel([null, null]), const [PropagateRule()]);

      expect(rating.verdict, PuzzleVerdict.ambiguous);
      expect(rating.solutions, 2);
      expect(rating.isPlayable, isFalse);
    });

    test('impossible when the clues contradict', () {
      final rating = rate(ChainModel([0, 1]), const [PropagateRule()]);

      expect(rating.verdict, PuzzleVerdict.impossible);
      expect(rating.isPlayable, isFalse);
    });

    test('unfinished when one answer exists but needs a guess', () {
      final rating = rate(ChainModel([0, null]), const [NoopRule()]);

      expect(rating.verdict, PuzzleVerdict.unfinished);
      expect(rating.solutions, 1);
      expect(rating.isPlayable, isTrue);
    });

    test('refuses to guess when the search ran out', () {
      expect(
        () => rate(
          ChainModel(List<int?>.filled(12, null)),
          const [NoopRule()],
          maxNodes: 5,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
