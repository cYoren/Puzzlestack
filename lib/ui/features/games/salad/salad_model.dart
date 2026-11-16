/// Salad as a deduction board.
///
/// A cell's mask says which symbols it can still hold: bit `0` is a hole, bit
/// `k` is the letter `k`. Three ideas do all the work a player does with a
/// pencil — a letter cannot repeat in its line, every letter needs a home in
/// every line, and a border clue says the cells before its letter are holes.
/// The last rule is exact: [SaladForced] searches for every complete answer
/// behind a cell, so "one answer" and "finishable without a guess" are the same
/// claim for this game.
///
/// Masks are `int` bits and the largest board is 7x7, so the widest mask is
/// eight bits: safe on every target, including the web build that truncates
/// bitwise integers to 32 bits.
library;

import '../../../../core/deduction.dart';
import 'salad_puzzle.dart';

/// The bit for [symbol] (0 for a hole, 1..nums for a letter).
int saladBit(int symbol) => 1 << symbol;

/// Every symbol a cell can hold, as a mask: the hole bit and every letter.
int saladFullMask(SaladPuzzle puzzle) => (1 << (puzzle.nums + 1)) - 1;

/// Every letter bit, without the hole: what a rule means by "a letter".
int saladLetterMask(SaladPuzzle puzzle) => saladFullMask(puzzle) & ~1;

int _popCount(int mask) {
  var count = 0;
  while (mask != 0) {
    mask &= mask - 1;
    count++;
  }
  return count;
}

/// The symbol of a single-bit mask.
int _symbolOf(int mask) => mask.bitLength - 1;

class SaladModel implements DeductionModel<SaladModel> {
  SaladModel({
    required this.puzzle,
    required this.masks,
    this.broken = false,
  });

  /// A fresh board: every cell allows every symbol, the hole included.
  factory SaladModel.fresh(SaladPuzzle puzzle) => SaladModel(
        puzzle: puzzle,
        masks: List<int>.filled(puzzle.cellCount, saladFullMask(puzzle)),
      );

  final SaladPuzzle puzzle;

  /// Per cell, the symbols it can still hold. A single bit is a decided cell.
  final List<int> masks;

  bool broken;

  int get n => puzzle.n;

  int get nums => puzzle.nums;

  int get cellCount => puzzle.cellCount;

  int get fullMask => saladFullMask(puzzle);

  @override
  SaladModel copy() => SaladModel(
        puzzle: puzzle,
        masks: List<int>.from(masks),
        broken: broken,
      );

  @override
  bool get isComplete {
    if (broken) return false;
    for (final mask in masks) {
      if (_popCount(mask) != 1) return false;
    }
    // Decided and correct are two questions, and the counter trusts this one: a
    // board can be complete and wrong.
    return puzzle.isSolution(values);
  }

  @override
  Choice? get choice {
    var best = -1;
    var bestCount = 99;
    for (var cell = 0; cell < cellCount; cell++) {
      final count = _popCount(masks[cell]);
      if (count < 2 || count >= bestCount) continue;
      best = cell;
      bestCount = count;
    }
    if (best < 0) return null;
    final values = <int>[];
    for (var symbol = 0; symbol <= nums; symbol++) {
      if (masks[best] & saladBit(symbol) != 0) values.add(symbol);
    }
    return Choice(best, values);
  }

  @override
  SaladModel assume(int slot, int value) {
    final next = copy();
    if (next.set(slot, value) < 0) next.broken = true;
    return next;
  }

  /// The board as symbols, with [kSaladBlank] where nothing is decided.
  ///
  /// Only a complete board is all symbols; asking an open board for its values
  /// is asking a question with no answer, which is why the counter checks
  /// [isComplete] first.
  List<int> get values => [
        for (final mask in masks)
          _popCount(mask) == 1 ? _symbolOf(mask) : kSaladBlank,
      ];

  /// The symbol of [cell], or null when it is not decided.
  ///
  /// Null rather than a sentinel: with a hole at zero and a clue at minus one, a
  /// third "nothing" number is a third chance to read the wrong one.
  int? symbolAt(int cell) =>
      _popCount(masks[cell]) == 1 ? _symbolOf(masks[cell]) : null;

  bool isDecided(int cell) => _popCount(masks[cell]) == 1;

  List<int> candidates(int cell) => [
        for (var symbol = 0; symbol <= nums; symbol++)
          if (masks[cell] & saladBit(symbol) != 0) symbol,
      ];

  /// Writes [symbol] in [cell] and propagates. -1 on a contradiction, otherwise
  /// the number of cells this settled.
  int set(int cell, int symbol) {
    final bit = saladBit(symbol);
    if (masks[cell] & bit == 0) {
      broken = true;
      return -1;
    }
    var news = 0;
    if (masks[cell] != bit) {
      masks[cell] = bit;
      news++;
    }
    final pushed = _propagate();
    if (pushed < 0) return -1;
    return news + pushed;
  }

  /// Removes [symbols] from [cell], as a mask of bits. Does not propagate;
  /// [set] does.
  int eliminate(int cell, int symbols) {
    if (masks[cell] & symbols == 0) return 0;
    final left = masks[cell] & ~symbols;
    if (left == 0) {
      broken = true;
      return -1;
    }
    masks[cell] = left;
    return 1;
  }

  /// Every decided **letter** takes itself away from the rest of its row and
  /// column, until nothing moves. A hole takes nothing: holes repeat freely.
  ///
  /// This is the one place that propagation lives, so [SaladPeers] and [set]
  /// cannot disagree about it.
  int _propagate() {
    var news = 0;
    var moved = true;
    while (moved) {
      moved = false;
      for (var cell = 0; cell < cellCount; cell++) {
        final symbol = symbolAt(cell);
        if (symbol == null || symbol == kSaladHole) continue;
        final bit = saladBit(symbol);
        final row = cell ~/ n;
        final col = cell % n;
        for (var i = 0; i < n; i++) {
          for (final peer in [row * n + i, i * n + col]) {
            if (peer == cell) continue;
            if (masks[peer] & bit == 0) continue;
            if (masks[peer] == bit) {
              broken = true;
              return -1;
            }
            final changed = eliminate(peer, bit);
            if (changed < 0) return -1;
            news += changed;
            moved = true;
          }
        }
      }
    }
    return news;
  }
}

/// A letter cannot repeat in its row or its column. Level 1: the first thing
/// anyone learns about a Latin square.
class SaladPeers implements DeductionRule<SaladModel> {
  const SaladPeers();

  @override
  int get level => 1;

  @override
  String get name => 'a letter once in its row and column';

  @override
  int apply(SaladModel model) {
    if (model.broken) return -1;
    final news = model._propagate();
    if (news < 0) return -1;
    return model.broken ? -1 : news;
  }
}

/// Every letter needs exactly one home in every line, and every line has room
/// for exactly `n - nums` holes. Level 1: still counting, not yet reading the
/// border.
class SaladLines implements DeductionRule<SaladModel> {
  const SaladLines();

  @override
  int get level => 1;

  @override
  String get name => 'the only home left in a line';

  @override
  int apply(SaladModel model) {
    if (model.broken) return -1;
    var news = 0;
    // Rows and columns are the same question asked twice, so the same code
    // walks both: `left` reads a row, `top` reads a column.
    for (final dir in [SaladClueDir.left, SaladClueDir.top]) {
      for (var index = 0; index < model.n; index++) {
        final cells = model.puzzle.line(dir, index);
        for (var letter = 1; letter <= model.nums; letter++) {
          final bit = saladBit(letter);
          final homes = [
            for (final cell in cells)
              if (model.masks[cell] & bit != 0) cell
          ];
          if (homes.isEmpty) return -1;
          if (homes.length > 1) continue;
          if (model.isDecided(homes.single)) continue;
          final changed = model.set(homes.single, letter);
          if (changed < 0) return -1;
          news += changed;
        }
        // Letters and holes fill the line between them. Two directions, and a
        // board needs both: once only `holes` cells can still be a hole, all of
        // them are; once `holes` of them already are, no other cell can be.
        final holes = model.puzzle.holes;
        var decided = 0;
        final candidates = <int>[];
        for (final cell in cells) {
          final symbol = model.symbolAt(cell);
          if (symbol == kSaladHole) decided++;
          if (model.masks[cell] & saladBit(kSaladHole) != 0) {
            candidates.add(cell);
          }
        }
        if (decided > holes || candidates.length < holes) return -1;
        if (candidates.length == holes) {
          for (final cell in candidates) {
            if (model.isDecided(cell)) continue;
            final changed = model.set(cell, kSaladHole);
            if (changed < 0) return -1;
            news += changed;
          }
        } else if (decided == holes) {
          for (final cell in cells) {
            if (model.isDecided(cell)) continue;
            if (model.masks[cell] & saladBit(kSaladHole) == 0) continue;
            final changed = model.eliminate(cell, saladBit(kSaladHole));
            if (changed < 0) return -1;
            news += changed;
          }
        }
      }
    }
    return news;
  }
}

/// A border clue, read inwards. Level 2: it is the one rule specific to this
/// game, and the one that makes the border worth printing.
///
/// Three moves, all of them the same sentence read three ways. A clue `L` says
/// `L` is the first letter the line shows, so:
///
///  * only holes can sit in front of `L`, and a line has room for `holes` of
///    them — so `L` cannot be further in than that. This is the opening of
///    every board.
///  * every cell in front of the first cell that can still be `L` is a hole;
///  * the first cell that is not a hole is either a hole or `L` itself, so no
///    other letter can sit there.
///
/// If `L` is already decided on the line, everything before it is a hole. If no
/// cell on the line can hold `L`, the board contradicts itself.
class SaladClues implements DeductionRule<SaladModel> {
  const SaladClues();

  @override
  int get level => 2;

  @override
  String get name => 'what the clue leaves before it';

  @override
  int apply(SaladModel model) {
    if (model.broken) return -1;
    var news = 0;
    for (final dir in SaladClueDir.values) {
      for (var index = 0; index < model.n; index++) {
        final wanted = model.puzzle.clue(dir, index);
        if (wanted == kSaladNoClue) continue;
        final bit = saladBit(wanted);
        final cells = model.puzzle.line(dir, index);

        // If the clue letter sits at position `j`, the `j` cells before it are
        // all holes, and the line only has room for `holes` of those. So the
        // clue letter cannot be further in than that — and this is the whole
        // opening of a Salad board, the deduction that makes the border worth
        // reading.
        final reach = model.puzzle.holes;
        for (var j = reach + 1; j < cells.length; j++) {
          if (model.masks[cells[j]] & bit == 0) continue;
          final changed = model.eliminate(cells[j], bit);
          if (changed < 0) return -1;
          news += changed;
        }

        // A decided clue letter is the end of the question: everything before it
        // is a hole, whatever else those cells could have been.
        var stop = -1;
        for (var j = 0; j < cells.length; j++) {
          if (model.isDecided(cells[j]) && model.masks[cells[j]] == bit) {
            stop = j;
            break;
          }
        }
        if (stop < 0) {
          for (var j = 0; j < cells.length; j++) {
            if (model.masks[cells[j]] & bit != 0) {
              stop = j;
              break;
            }
          }
        }
        // No cell on the line can hold the clue letter: the clue is false.
        if (stop < 0) return -1;

        // The first cell that is not a known hole is either a hole or the clue
        // letter, and nothing else: if it were another letter, that letter would
        // be the first one the line shows.
        for (var j = 0; j < cells.length; j++) {
          if (model.isDecided(cells[j]) &&
              model.masks[cells[j]] == saladBit(kSaladHole)) {
            continue;
          }
          final others =
              model.masks[cells[j]] & saladLetterMask(model.puzzle) & ~bit;
          if (others != 0) {
            final changed = model.eliminate(cells[j], others);
            if (changed < 0) return -1;
            news += changed;
          }
          break;
        }
        for (var j = 0; j < stop; j++) {
          if (model.isDecided(cells[j]) &&
              model.masks[cells[j]] != saladBit(kSaladHole)) {
            // A letter sits before the clue's letter, which the clue forbids.
            model.broken = true;
            return -1;
          }
          if (model.isDecided(cells[j])) continue;
          final changed = model.set(cells[j], kSaladHole);
          if (changed < 0) return -1;
          news += changed;
        }
      }
    }
    return news;
  }
}

/// The exact rule: a cell is only written when a search proves every other
/// symbol impossible. Level 3, so a board finished by it is not "solvable by
/// logic" — and because it also counts, it is what makes the generator's
/// promise ("exactly one answer") true.
class SaladForced implements DeductionRule<SaladModel> {
  const SaladForced({this.limit = 4096, this.budget = 40000});

  final int limit;
  final int budget;

  @override
  int get level => 3;

  @override
  String get name => 'searching every other symbol';

  @override
  int apply(SaladModel model) {
    if (model.broken) return -1;
    final found = SaladSearch(
      puzzle: model.puzzle,
      masks: List<int>.from(model.masks),
      limit: limit,
      budget: budget,
    ).run();
    if (found.truncated) return 0;
    // Never write a cell the search did not finish proving: agreement among the
    // first few answers says nothing about the rest.
    if (!found.exhausted) return 0;
    if (found.solutions == 0) return -1;
    var news = 0;
    for (var cell = 0; cell < model.cellCount; cell++) {
      final forced = found.forced[cell];
      if (forced == null) continue;
      if (model.isDecided(cell)) continue;
      final changed = model.set(cell, forced);
      if (changed < 0) return -1;
      news += changed;
    }
    return news;
  }
}

/// Every rule, easiest first, ending with the exact one.
const List<DeductionRule<SaladModel>> saladRules = [
  SaladPeers(),
  SaladLines(),
  SaladClues(),
  SaladForced(),
];

/// The rules a player can be expected to use, without the search.
const List<DeductionRule<SaladModel>> saladPlayerRules = [
  SaladPeers(),
  SaladLines(),
  SaladClues(),
];

/// What a search over [SaladModel] found.
class SaladCount {
  const SaladCount({
    required this.solutions,
    required this.truncated,
    required this.exhausted,
    required this.first,
    required this.forced,
  });

  /// Answers found, capped at the limit asked for.
  final int solutions;

  /// True when the budget ran out. A truncated count proves nothing.
  final bool truncated;

  /// True when the search finished: no budget ran out and the limit was not
  /// reached. Only then is [forced] a proof.
  final bool exhausted;

  /// The first answer the search completed, per cell, or empty.
  final List<int> first;

  /// Per cell, the symbol every answer agrees on, or null when they disagree.
  /// All null unless [exhausted]: a symbol is only a proof if the search
  /// finished.
  final List<int?> forced;

  bool get isUnique => solutions == 1 && !truncated;
}

/// The search behind [SaladForced]: fill the board, counting answers.
class SaladSearch {
  SaladSearch({
    required this.puzzle,
    required this.masks,
    this.limit = 2,
    this.budget = 40000,
  });

  final SaladPuzzle puzzle;
  final List<int> masks;
  final int limit;
  final int budget;

  int _nodes = 0;
  int _solutions = 0;
  bool _truncated = false;
  List<int>? _first;
  late final List<int> _seen =
      List<int>.filled(puzzle.cellCount, saladFullMask(puzzle));

  SaladCount run() {
    _search(SaladModel(puzzle: puzzle, masks: List<int>.from(masks)));
    // Stopping at the limit is not finishing: the answers beyond it were never
    // looked at, so nothing is proved about them.
    final exhausted = !_truncated && _solutions < limit;
    final forced = List<int?>.filled(puzzle.cellCount, null);
    if (exhausted && _solutions > 0) {
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        forced[cell] =
            _popCount(_seen[cell]) == 1 ? _symbolOf(_seen[cell]) : null;
      }
    }
    return SaladCount(
      solutions: _solutions,
      truncated: _truncated,
      exhausted: exhausted,
      first: _first ?? const [],
      forced: forced,
    );
  }

  int _search(SaladModel model) {
    if (_truncated) return 0;
    if (_nodes++ > budget) {
      _truncated = true;
      return 0;
    }
    final outcome = deduce(model, saladPlayerRules);
    if (!outcome.consistent) return 0;
    if (model.isComplete) {
      final values = model.values;
      _first ??= values;
      for (var cell = 0; cell < puzzle.cellCount; cell++) {
        _seen[cell] &= saladBit(values[cell]);
      }
      _solutions++;
      return 1;
    }
    final choice = model.choice;
    if (choice == null) return 0;
    var found = 0;
    for (final value in choice.values) {
      found += _search(model.assume(choice.slot, value));
      // The limit is global: `found` is this node's subtotal, so a deep branch
      // that already reached the limit must stop the whole walk, not just this
      // loop.
      if (_solutions >= limit || _truncated) break;
    }
    return found;
  }
}
