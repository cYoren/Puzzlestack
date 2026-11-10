/// The machinery behind the Phase 3 bar: prove a board has one solution, and
/// say how hard it is to reach it by reasoning.
///
/// A puzzle that is "solvable by construction" (Pegs, Twiddle) needs none of
/// this — its generator ships the line that solves it. A deduction puzzle does
/// not work that way: the board is a set of clues, and whether those clues pin
/// down exactly one answer is a property of the clues, not of how they were
/// made. So it has to be counted.
///
/// The shape every deduction puzzle shares is small:
///
///  * a board, which can be copied so a guess can be thrown away;
///  * an ordered list of rules, easy idea first;
///  * a place to guess when the rules run out.
///
/// Everything else — what a cell is, what a value means — belongs to the
/// puzzle. This file only runs the rules and counts the answers.
library;

import 'dart:math' as math;

/// A board a deduction solver can work on.
///
/// Implementations are mutable: a rule edits the board in place, and
/// [copy] is how a guess is undone.
abstract class DeductionModel<M extends DeductionModel<M>> {
  /// An independent copy. Mutating the copy must not touch this board.
  M copy();

  /// True when every decision has been made — the board is a finished answer,
  /// not necessarily a correct one.
  bool get isComplete;

  /// Somewhere the rules have run out, or null when the board is complete.
  ///
  /// The solver picks the choice that looks cheapest; a puzzle that has a
  /// better idea of where to guess can say so here.
  Choice? get choice;

  /// This board with [slot] decided as [value]. Used only for guessing.
  M assume(int slot, int value);
}

/// A place where reasoning stops and a guess is needed.
class Choice {
  const Choice(this.slot, this.values);

  /// Puzzle-defined index of the thing being decided.
  final int slot;

  /// The values still open to it. At least two, by definition.
  final List<int> values;

  @override
  String toString() => 'Choice($slot, $values)';
}

/// One deduction rule.
///
/// [level] orders the rules by how hard the idea is: level 1 is what a player
/// does without thinking, the top level is the clever one. That ordering is
/// what turns "solvable by logic" into a difficulty, instead of one bucket
/// called easy.
abstract class DeductionRule<M> {
  /// 1 is the easiest idea. Higher is harder.
  int get level;

  /// For diagnostics and for naming the rule in a failure message.
  String get name;

  /// Applies the rule as far as it goes, editing [model] in place.
  ///
  /// Returns how many decisions it settled — 0 when it learned nothing, which
  /// is how the fixed-point loop knows to stop — or -1 when the board
  /// contradicts itself.
  int apply(M model);
}

/// What running the rules achieved.
class DeductionOutcome {
  const DeductionOutcome({
    required this.consistent,
    required this.complete,
    required this.settled,
    required this.highestLevel,
    required this.rounds,
  });

  /// False when a rule found a contradiction.
  final bool consistent;

  /// True when the board ended up fully decided.
  final bool complete;

  /// Total decisions made across every rule and round.
  final int settled;

  /// The highest rule level that ever fired. 0 when nothing was needed.
  final int highestLevel;

  /// How many passes over the rule list it took to reach a fixed point.
  final int rounds;

  @override
  String toString() => 'DeductionOutcome(consistent: $consistent, '
      'complete: $complete, settled: $settled, '
      'highestLevel: $highestLevel, rounds: $rounds)';
}

/// How many solutions a board has, and whether the count is trustworthy.
class SolutionCount {
  const SolutionCount(this.count, {this.truncated = false});

  /// Solutions found, capped at the limit that was asked for.
  final int count;

  /// True when the search ran out of budget before it could finish. A
  /// truncated count proves nothing, so callers must not read it as unique.
  final bool truncated;

  bool get isUnique => count == 1 && !truncated;

  @override
  String toString() =>
      'SolutionCount($count${truncated ? ', truncated' : ''})';
}

/// What a board is, once the rules have had a go at it.
enum PuzzleVerdict {
  /// The clues contradict each other.
  impossible,

  /// More than one answer fits the clues.
  ambiguous,

  /// Exactly one answer, but the rules cannot reach it — a guess is needed.
  unfinished,

  /// Exactly one answer, and the rules at [PuzzleRating.level] reach it.
  solved,
}

/// A board's grade.
class PuzzleRating {
  const PuzzleRating(this.verdict, {this.level = 0, this.solutions = 0});

  final PuzzleVerdict verdict;

  /// The lowest rule level that finishes the board. 0 unless [verdict] is
  /// [PuzzleVerdict.solved].
  final int level;

  /// Solutions found, capped at the limit that was asked for.
  final int solutions;

  bool get isPlayable =>
      verdict == PuzzleVerdict.solved || verdict == PuzzleVerdict.unfinished;

  @override
  String toString() => 'PuzzleRating(${verdict.name}'
      '${verdict == PuzzleVerdict.solved ? ' at level $level' : ''}, '
      '$solutions solution${solutions == 1 ? '' : 's'})';
}

/// Runs [rules] over [model] until nothing more can be learned.
///
/// Rules run in the order given, so an easy rule gets its chance before a
/// hard one. A contradiction stops the run immediately.
DeductionOutcome deduce<M extends DeductionModel<M>>(
  M model,
  List<DeductionRule<M>> rules,
) {
  var settled = 0;
  var highestLevel = 0;
  var rounds = 0;

  while (true) {
    var changed = false;
    for (final rule in rules) {
      final n = rule.apply(model);
      if (n < 0) {
        return DeductionOutcome(
          consistent: false,
          complete: false,
          settled: settled,
          highestLevel: highestLevel,
          rounds: rounds,
        );
      }
      if (n > 0) {
        changed = true;
        settled += n;
        highestLevel = math.max(highestLevel, rule.level);
      }
    }
    if (!changed) break;
    rounds++;
  }

  return DeductionOutcome(
    consistent: true,
    complete: model.isComplete,
    settled: settled,
    highestLevel: highestLevel,
    rounds: rounds,
  );
}

/// Counts the solutions to [model], stopping once [limit] are found.
///
/// Reasoning first, guessing only where reasoning stops — so a well-made board
/// is counted without ever branching, which is what makes this cheap enough to
/// run two hundred times in a test.
SolutionCount countSolutions<M extends DeductionModel<M>>(
  M model,
  List<DeductionRule<M>> rules, {
  int limit = 2,
  int maxNodes = 50000,
}) {
  var nodes = 0;
  var truncated = false;

  int search(M board) {
    if (truncated) return 0;
    if (nodes++ > maxNodes) {
      truncated = true;
      return 0;
    }

    final outcome = deduce(board, rules);
    if (!outcome.consistent) return 0;
    if (board.isComplete) return 1;

    final choice = board.choice;
    // A board that is neither complete nor has a choice cannot be finished:
    // the rules are too weak to see the remaining freedom.
    if (choice == null) return 0;

    var found = 0;
    for (final value in choice.values) {
      found += search(board.assume(choice.slot, value));
      if (found >= limit) break;
    }
    return found;
  }

  final count = search(model.copy());
  return SolutionCount(
    math.min(count, limit),
    truncated: truncated,
  );
}

/// The lowest rule level whose rules alone finish [model].
///
/// Returns 0 when the board is already finished, and null when no level is
/// enough — which means a guess is needed. This is the measure the roadmap
/// means by "three difficulties that differ in solving depth": a board that
/// only needs level 1 is easy, one that needs level 3 is not.
int? solvingLevel<M extends DeductionModel<M>>(
  M model,
  List<DeductionRule<M>> rules,
) {
  if (model.isComplete) return 0;

  final levels = rules.map((rule) => rule.level).toSet().toList()..sort();
  for (final level in levels) {
    final easy = rules.where((rule) => rule.level <= level).toList();
    final board = model.copy();
    final outcome = deduce(board, easy);
    if (!outcome.consistent) return null;
    if (outcome.complete) return level;
  }
  return null;
}

/// Grades a board: does it have one answer, and how hard is it to reason to?
///
/// This is the function the Phase 3 bar is written against. A board that comes
/// back [PuzzleVerdict.ambiguous] or [PuzzleVerdict.impossible] must not ship.
PuzzleRating rate<M extends DeductionModel<M>>(
  M model,
  List<DeductionRule<M>> rules, {
  int limit = 2,
  int maxNodes = 50000,
}) {
  final solutions = countSolutions(
    model,
    rules,
    limit: limit,
    maxNodes: maxNodes,
  );
  if (solutions.truncated) {
    // Not a verdict about the board, a verdict about the search. Callers that
    // need to know must ask for a bigger budget.
    throw StateError(
      'countSolutions gave up before finding $limit solutions; '
      'the board is too big for the budget, not for the rules',
    );
  }
  if (solutions.count == 0) {
    return const PuzzleRating(PuzzleVerdict.impossible);
  }
  if (solutions.count > 1) {
    return PuzzleRating(PuzzleVerdict.ambiguous, solutions: solutions.count);
  }

  final level = solvingLevel(model, rules);
  if (level == null) {
    return const PuzzleRating(PuzzleVerdict.unfinished, solutions: 1);
  }
  return PuzzleRating(PuzzleVerdict.solved, level: level, solutions: 1);
}
