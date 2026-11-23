// G4 (release gate): "No game can be dealt unwinnable, or with two answers
// where one is implied."
//
// One table, one case per family, never a second solver. A family either has a
// probe that drives the game's **own** generator and the game's **own** prover
// (a solution counter, a rating, or a solver the game itself ships), or it
// carries a finding: the property is not proved, and the reason is named.
//
// The probe signature is deliberately narrow: a family reports failures, it
// does not own assertions. The test file decides how a failure is shown.

import 'dart:math';

import 'package:puzzle/core/deduction.dart';
import 'package:puzzle/ui/features/games/akari/akari_engine.dart';
import 'package:puzzle/ui/features/games/cube/cube_engine.dart';
import 'package:puzzle/ui/features/games/dominosa/dominosa_engine.dart';
import 'package:puzzle/ui/features/games/futoshiki/futoshiki_engine.dart';
import 'package:puzzle/ui/features/games/galaxies/galaxies_engine.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_engine.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_engine.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_engine.dart';
import 'package:puzzle/ui/features/games/magnets/magnets_engine.dart';
import 'package:puzzle/ui/features/games/map/map_engine.dart';
import 'package:puzzle/ui/features/games/minesweeper/minesweeper_engine.dart';
import 'package:puzzle/ui/features/games/mirror_maze/mirror_maze_engine.dart';
import 'package:puzzle/ui/features/games/netslide/netslide_engine.dart';
import 'package:puzzle/ui/features/games/nonogram/nonogram_engine.dart';
import 'package:puzzle/ui/features/games/nonogram/nonogram_model.dart';
import 'package:puzzle/ui/features/games/norinori/norinori_engine.dart';
import 'package:puzzle/ui/features/games/pegs/pegs_engine.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_engine.dart';
import 'package:puzzle/ui/features/games/skyscrapers/skyscrapers_engine.dart';
import 'package:puzzle/ui/features/games/tents_and_trees/tents_and_trees_engine.dart';
import 'package:puzzle/ui/features/games/tower_of_london/tower_of_london_engine.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_engine.dart';

/// Reports one game's violation. The family supplies the game id, so a
/// violation always names a Deck id.
typedef DealFailure = void Function(String game, String why);

/// Runs one seed of a family. Every board is created inside the probe, with
/// `Random(seed)`, so a failure is reproducible by seed alone.
typedef DealProbe = void Function(int seed, DealFailure fail);

/// A group of Deck games that share one way of proving a deal.
class DealFamily {
  const DealFamily({
    required this.id,
    required this.label,
    required this.games,
    this.probe,
    this.seeds = 3,
    this.finding,
  });

  /// Finding id when [probe] is null, or the family's own id.
  final String id;

  final String label;

  /// Every Deck id this family answers for. The test's sweep checks that these
  /// sets partition `deckIds` exactly.
  final Set<String> games;

  final DealProbe? probe;

  /// How many deterministic deals the probe checks. A generator that cannot
  /// seed still gets [seeds] independent calls.
  final int seeds;

  /// Set only when the property is not proved. The reason is part of the
  /// deliverable, not an excuse.
  final String? finding;

  List<String> run() {
    final probe = this.probe;
    if (probe == null) return const [];
    final failures = <String>[];
    for (var seed = 0; seed < seeds; seed++) {
      void fail(String game, String why) =>
          failures.add('$game seed=$seed: $why');
      try {
        probe(seed, fail);
      } on Object catch (error) {
        fail('<${id}_seed>', 'threw $error');
      }
    }
    return failures;
  }
}

// ---------------------------------------------------------------------------
// Probes
// ---------------------------------------------------------------------------

/// Latin-square puzzles whose engine exposes its own solution count and rating.
void _latinClue(int seed, DealFailure fail) {
  final rng = Random(seed);

  final futoshiki = const FutoshikiEngine().generate(
    FutoshikiDifficulty.easy,
    random: rng,
  );
  final futoshikiCount = const FutoshikiEngine().count(futoshiki);
  if (!futoshikiCount.isUnique) {
    fail('futoshiki', '$futoshikiCount');
  }
  final futoshikiRating = const FutoshikiEngine().rating(futoshiki);
  if (futoshikiRating.verdict != PuzzleVerdict.solved) {
    fail('futoshiki', 'not proved: $futoshikiRating');
  } else if (futoshikiRating.level > 3) {
    fail('futoshiki', 'finishable only at level ${futoshikiRating.level}');
  }

  final skyscrapers = const SkyscrapersEngine().generate(
    SkyscrapersDifficulty.easy,
    random: rng,
  );
  final skyscrapersCount = const SkyscrapersEngine().count(skyscrapers);
  if (!skyscrapersCount.isUnique) {
    fail('skyscrapers', '$skyscrapersCount');
  }
  final skyscrapersRating = const SkyscrapersEngine().rating(skyscrapers);
  if (skyscrapersRating.verdict != PuzzleVerdict.solved) {
    fail('skyscrapers', 'not proved: $skyscrapersRating');
  } else if (skyscrapersRating.level > 3) {
    fail('skyscrapers', 'finishable only at level ${skyscrapersRating.level}');
  }
}

/// Deduction boards whose engine exports a solution count and a solving level.
///
/// One answer where the genre implies one, and the deal falls to the game's own
/// rules at level 2 or easier.
void _deductionCount(int seed, DealFailure fail) {
  final rng = Random(seed);

  final dominosa = const DominosaEngine().generate(
    DominosaDifficulty.easy,
    random: rng,
  );
  final tilings = const DominosaEngine().countTilings(dominosa);
  if (tilings != 1) fail('dominosa', '$tilings tilings, expected 1');

  final galaxies = const GalaxiesEngine().generate(
    difficulty: GalaxiesDifficulty.medium,
    random: rng,
  );
  final galaxiesRating = rateGalaxies(galaxies);
  if (galaxiesRating.verdict != PuzzleVerdict.solved) {
    fail('galaxies', 'not proved: $galaxiesRating');
  } else if (galaxiesRating.level > 2) {
    fail('galaxies', 'finishable only at level ${galaxiesRating.level}');
  }

  final kurodoko = const KurodokoEngine().generate(
    difficulty: KurodokoDifficulty.easy,
    random: rng,
  );
  final kurodokoRating = rate(KurodokoModel.blank(kurodoko), kurodokoRules);
  if (kurodokoRating.verdict != PuzzleVerdict.solved) {
    fail('kurodoko', 'not proved: $kurodokoRating');
  } else if (kurodokoRating.level > 2) {
    fail('kurodoko', 'finishable only at level ${kurodokoRating.level}');
  }

  final magnets = const MagnetsEngine().generate(
    MagnetsDifficulty.easy,
    random: rng,
  );
  final magnetsSolutions = const MagnetsEngine().harnessSolutions(magnets);
  if (magnetsSolutions != 1) {
    fail('magnets', '$magnetsSolutions solutions, expected 1');
  }
  final magnetsLevel = const MagnetsEngine().levelOf(magnets);
  if (magnetsLevel == null) {
    fail('magnets', 'the rules do not finish it');
  } else if (magnetsLevel > 2) {
    fail('magnets', 'finishable only at level $magnetsLevel');
  }

  final nonogram = NonogramEngine().generatePuzzle(6);
  final nonogramCount = countNonogramSolutions(
    rowClues: nonogram.rowClues,
    colClues: nonogram.colClues,
  );
  if (!nonogramCount.isUnique) fail('nonogram', '$nonogramCount');
  final nonogramRating = rate(
    NonogramModel(
      cells: List.generate(
        6,
        (_) => List<int>.filled(6, NonogramModel.unknown),
      ),
      rowClues: nonogram.rowClues,
      colClues: nonogram.colClues,
    ),
    nonogramRules,
  );
  if (nonogramRating.verdict != PuzzleVerdict.solved) {
    fail('nonogram', 'not proved: $nonogramRating');
  } else if (nonogramRating.level > 2) {
    fail('nonogram', 'finishable only at level ${nonogramRating.level}');
  }

  final norinori = const NorinoriEngine().generate(random: rng);
  final norinoriSolutions = const NorinoriEngine().countSolutions(norinori);
  if (norinoriSolutions != 1) {
    fail('norinori', '$norinoriSolutions solutions, expected 1');
  }
  if (const NorinoriEngine().solve(norinori) == null) {
    fail('norinori', 'its own solver cannot finish the board');
  }

  final signpost = const SignpostEngine().generate(
    SignpostDifficulty.medium,
    random: rng,
  );
  final signpostRating = const SignpostEngine().rateBoard(signpost);
  if (signpostRating.verdict != PuzzleVerdict.solved) {
    fail('signpost', 'not proved: $signpostRating');
  } else if (signpostRating.level > 2) {
    fail('signpost', 'finishable only at level ${signpostRating.level}');
  }

  final tents = const TentsEngine().generate(TentsDifficulty.easy, random: rng);
  final tentSolutions = const TentsEngine().harnessSolutions(tents);
  if (tentSolutions != 1) {
    fail('tents_and_trees', '$tentSolutions solutions, expected 1');
  }
  final tentsLevel = const TentsEngine().levelOf(tents);
  if (tentsLevel == null) {
    fail('tents_and_trees', 'the rules do not finish it');
  } else if (tentsLevel > 2) {
    fail('tents_and_trees', 'finishable only at level $tentsLevel');
  }
}

/// Games whose answer is a procedure, not a clue set: the property is that the
/// deal can be won, proved by the game's own solver or stored answer.
void _winnableBySearch(int seed, DealFailure fail) {
  final rng = Random(seed);

  final akariGrid = AkariEngine().generateLevel()['grid'] as List<List<int>>;
  if (AkariEngine.solve(akariGrid) == null) {
    fail('akari', 'its own solver finds no bulb layout');
  }

  final cube = const CubeEngine().generate(CubeDifficulty.easy, random: rng);
  if (const CubeEngine().solve(cube, const CubeEngine().startOf(cube)) ==
      null) {
    fail('cube', 'its own solver finds no line');
  }

  final inertia = const InertiaEngine().generate(
    InertiaDifficulty.easy,
    random: rng,
  );
  if (const InertiaEngine().solve(inertia) == null) {
    fail('inertia', 'its own solver finds no line');
  }

  final lightsOut = const LightsOutEngine().generate(
    LightsOutDifficulty.easy,
    random: rng,
  );
  final presses = const LightsOutEngine().countSolutions(
    lightsOut.start,
    lightsOut.size,
  );
  if (presses != 1) {
    fail('lights_out', '$presses press sets, expected 1');
  }
  var grid = [...lightsOut.start];
  for (final index in lightsOut.solution) {
    grid = const LightsOutEngine().press(grid, lightsOut.size, index);
  }
  if (!const LightsOutEngine().isSolved(grid)) {
    fail('lights_out', 'the stored presses do not clear the board');
  }

  final map = const MapEngine().generate(MapDifficulty.easy, random: rng);
  if (!const MapEngine().isSolved(map, map.solution)) {
    fail('map', 'the stored colouring does not solve the board');
  }

  final sweeper = MinesweeperEngine(
    rows: 6,
    cols: 6,
    mineCount: 5,
    random: rng,
  );
  final minesweeper = sweeper.generateBoard(startRow: 0, startCol: 0);
  if (!sweeper.isSolvableWithoutGuess(minesweeper, 0, 0)) {
    fail('minesweeper', 'the deal needs a guess');
  }

  final net = const NetEngine().generate(NetDifficulty.easy, random: rng);
  if (!const NetEngine().isSolved(net, net.solvedMasks)) {
    fail('netslide', 'the stored answer does not solve the board');
  }

  final pegs =
      const PegsEngine().generate(difficulty: PegsDifficulty.easy, random: rng);
  if (const PegsEngine().solve(pegs.start, pegs.rows, pegs.cols) == null) {
    fail('pegs', 'its own solver finds no line');
  }

  final tower = TowerOfLondonEngine().generatePuzzle();
  if (TowerOfLondonEngine().solve(tower['start']!, tower['target']!) < 0) {
    fail('tower_of_london', 'its own solver finds no line');
  }

  final twiddle = const TwiddleEngine().generate(
    difficulty: TwiddleDifficulty.easy,
    random: rng,
  );
  var tiles = [...twiddle.start];
  for (final move in twiddle.solution) {
    tiles = const TwiddleEngine().apply(
      tiles,
      twiddle.size,
      move,
      twiddle.block,
    );
  }
  if (!const TwiddleEngine().isSolved(tiles)) {
    fail('twiddle', 'the stored moves do not solve the board');
  }
}

/// Beam deals whose generator ships a prover that enumerates the cheaper
/// layouts.
///
/// The property is the one this game actually has: the deal cannot be won with
/// fewer than two mirrors, and the layout the deal was built from does win it.
/// Several two-mirror layouts win too, and that is not a violation: the win
/// condition is the exit, so any of them is a legal answer and none costs the
/// player more than the other.
void _beamDepth(int seed, DealFailure fail) {
  final deal = MirrorMazeGenerator(random: Random(seed)).next();
  if (deal.depth != MirrorMazeGenerator.mirrorMazeDealDepth) {
    fail('mirror_maze', 'dealt a ${deal.depth}-mirror deal (${deal.key})');
  }
  if (!mirrorMazeDealIsFair(deal)) {
    fail('mirror_maze', 'a cheaper layout wins this deal (${deal.key})');
  }
  if (!mirrorMazeLayoutWins(deal, deal.answer)) {
    fail('mirror_maze', 'the stored answer does not win (${deal.key})');
  }
  if (mirrorMazeLayouts(deal, 1).isNotEmpty) {
    fail('mirror_maze', 'one mirror wins it (${deal.key})');
  }
  if (mirrorMazeLayouts(deal, 2).isEmpty) {
    fail('mirror_maze', 'two mirrors do not win it (${deal.key})');
  }
}

// ---------------------------------------------------------------------------
// The table
// ---------------------------------------------------------------------------

/// Every Deck id, in exactly one family.
const List<DealFamily> dealFamilies = [
  DealFamily(
    id: 'G4-latin',
    label:
        'Latin-line puzzles rate themselves unique and finishable by line deduction',
    games: {'futoshiki', 'skyscrapers'},
    probe: _latinClue,
    seeds: 3,
  ),
  DealFamily(
    id: 'G4-deduction',
    label:
        'Deduction boards count one answer and fall to their own rules at level 2',
    games: {
      'dominosa',
      'galaxies',
      'kurodoko',
      'magnets',
      'nonogram',
      'norinori',
      'signpost',
      'tents_and_trees',
    },
    probe: _deductionCount,
    seeds: 3,
  ),
  DealFamily(
    id: 'G4-winnable',
    label: 'Procedure games deal a board their own solver can finish',
    games: {
      'akari',
      'cube',
      'inertia',
      'lights_out',
      'map',
      'minesweeper',
      'netslide',
      'pegs',
      'tower_of_london',
      'twiddle',
    },
    probe: _winnableBySearch,
    seeds: 3,
  ),

  DealFamily(
    id: 'G4-beam',
    label:
        'Beam deals prove no layout with fewer than two mirrors wins, and their answer wins',
    games: {'mirror_maze'},
    probe: _beamDepth,
    seeds: 5,
  ),

  // Findings: the property is not proved. Each family names what is missing;
  // the test skips with the id, so G4 cannot read green on a shrug.
  DealFamily(
    id: 'G4-F1',
    label: 'Logic: no proof reachable from a test',
    games: {
      'binary_puzzle',
      'block_escape',
      'bridges',
      'color_flood',
      'crown',
      'fillomino',
      'gokigen_naname',
      'heyawake',
      'hitori',
      'kakurasu_sums',
      'kakuro',
      'lighthouses',
      'masyu',
      'nurikabe',
      'pipes',
      'same_game',
      'shikaku',
      'slitherlink',
      'sudoku',
      'tangle_fix',
      'tapa',
      'tenner_grid',
      'water_sort',
      'yajilin',
    },
    finding: 'G4-F1 no uniqueness counter or solver is reachable from outside '
        'the engine. Some guards are private (sudoku, bridges, crown, '
        'lighthouses, nurikabe, slitherlink count inside the generator); the '
        'rest generate without exposing a prover. Proving them here would mean '
        'copying a solver into the test, which the job forbids.',
  ),
  DealFamily(
    id: 'G4-F2',
    label: 'Math: answer ships with the card, no prover',
    games: {
      'arithmetic_chain',
      'balance_scale',
      'countdown_math',
      'crypto_arithmetic',
      'digit_swap_eq',
      'fibonacci_merge',
      'game_2048',
      'kenken',
      'magic_squares',
      'math_guess',
      'math_maze',
      'math_path',
      'missing_operator',
      'number_bonds',
      'quick_math',
      'sequence_sleuth',
      'sum_pyramid',
      'sum_snake',
      'target_10',
    },
    finding: 'G4-F2 the game computes its own answer at deal time and exposes '
        'no prover. Uniqueness is not implied by the genre (several valid '
        'moves can reach a target), but "not unwinnable" is also unproved from '
        'a test: there is no public solver or answer accessor to drive.',
  ),
  DealFamily(
    id: 'G4-F3',
    label: 'Memory: hidden state, judged by play',
    games: {
      'simon_sequence',
    },
    finding:
        'G4-F3 lab tasks whose answer is the sequence or layout the screen '
        'hides. The uniqueness clause does not apply; fairness is check 1 and 4, '
        'judged by play. No pool or prover is exported for a test to assert.',
  ),
  DealFamily(
    id: 'G4-F4',
    label: 'Attention: hidden target, judged by play',
    games: {
      'change_blindness',
      'color_match',
      'schulte_table',
      'shell_game',
      'visual_search',
    },
    finding: 'G4-F4 lab tasks whose target is generated and then hidden or '
        'timed. The uniqueness clause does not apply; fairness is judged by '
        'play, and no answer/pool accessor is exported for a test.',
  ),
  DealFamily(
    id: 'G4-F5',
    label: 'Word: fixed pools, whole-pool solvability unproved',
    games: {
      'chain_reaction',
      'compound_connect',
      'conundrum_anagram',
      'crossword',
      'cryptogram',
      'find_word',
      'homophone_hunt',
      'letter_bridge',
      'letter_grid_swapper',
      'missing_vowels',
      'one_letter_shift',
      'pangram_sprint',
      'portmanteau_split',
      'rhyme_master',
      'sentence_unscramble',
      'spoonerism_solver',
      'verbal_analogies',
      'word_grid_connection',
      'word_ladder',
      'word_mastermind',
      'word_scramble',
      'word_search',
      'word_snake_trail',
      'word_wheel',
    },
    finding: 'G4-F5 pool/fixed-content games. The property is "every entry is '
        'solvable", not "one answer", and the pools live inside each screen or '
        'its private content file with no exported accessor. A whole-pool '
        'assertion is not possible from a test without copying the pool.',
  ),
  DealFamily(
    id: 'G4-F6',
    label: 'Spatial: no public finishability prover',
    games: {
      'block_count_3d',
      'classic_maze',
      'compass_maze',
      'cross_section_slice',
      'cube_net_fold',
      'gear_rotation',
      'hue_sort',
      'klotski',
      'laser_link',
      'mental_rotation',
      'mirror_image',
      'paper_folding',
      'path_intersect',
      'perspective_taking',
      'polyomino_tiling',
      'rotating_maze',
      'silhouette_match',
      'slide_puzzle',
      'symmetry',
      'tangram',
      'topology',
    },
    finding: 'G4-F6 generators build a board or a target but expose no '
        'finishability or uniqueness prover. Where a stored answer exists '
        '(mazes, tiling) it is not reachable through a public accessor, so a '
        'test can only assert that the generator returned something.',
  ),
];
