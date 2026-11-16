// GENERATED FILE -- do not edit by hand.
//
// One tier, kind, origin and family per game, read from docs/CATALOG.md by
// tool/gen_game_profiles.py. Edit the catalog, run the script, commit both.
// test/content/game_profiles_test.dart parses the markdown again and fails if
// this file and the document disagree.

import 'game_metadata.dart';

/// Which surface a game appears on.
enum GameTier {
  /// The deal, the Daily Five and the Library: passes all ten checks.
  deck,
  /// Its room and search only: passes the Library floor.
  library,
  /// Nowhere in the app. Hidden, tagged, still in the repo as material.
  archive,
}

/// What kind of card a game makes, for the rhythm of the deal.
enum CardKind { think, word, snap }

/// Where a game came from. A lab task and a worksheet can be a good card, but they
/// are tagged so they can be found in one query.
enum GameOrigin { puzzle, lab, worksheet, quiz }

/// Why a game is archived.
enum ArchiveReason {
  /// Absorbed by a keeper that does the same thing better.
  twin,
  /// There is no decision in it to make.
  noGame,
  /// It cannot work in this app as it stands (for example it needs audio).
  brokenConcept,
}

/// Everything the app needs to know about one game that is not the game itself.
class GameProfile {
  const GameProfile({
    required this.tier,
    required this.kind,
    required this.origin,
    this.family,
    this.reason,
  });

  final GameTier tier;
  final CardKind kind;
  final GameOrigin origin;

  /// The id of the game that absorbed this one, when the catalog merged a twin.
  final String? family;

  /// Only an archived game has one.
  final ArchiveReason? reason;
}

/// 319 games: 89 archive, 139 deck, 91 library.
const Map<String, GameProfile> gameProfiles = {
  'ab_reversal_oddball': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'rule_switcher', reason: ArchiveReason.twin),
  'abcd': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'action_sequence_recall': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'affix_factory': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'akari': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'algebraic_balance': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'algebraic_inequality_solver': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, family: 'inequality_dash', reason: ArchiveReason.twin),
  'alphabet_sudoku': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.puzzle, family: 'sudoku', reason: ArchiveReason.twin),
  'anagram_definition': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'angle_finder': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'area_perimeter_match': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'arithmetic_chain': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'ascent': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'associative_pairs': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'attentional_blink': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'attentional_blink_probe': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'attentional_blink', reason: ArchiveReason.twin),
  'balance_scale': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'base_conversion_run': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, family: 'base_shift', reason: ArchiveReason.twin),
  'base_shift': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'binary_code': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'binary_matrix_rank': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, reason: ArchiveReason.noGame),
  'binary_puzzle': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'binary_scale_balance': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, family: 'balance_scale', reason: ArchiveReason.twin),
  'binomial_match': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, reason: ArchiveReason.noGame),
  'blink_detector': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'attentional_blink', reason: ArchiveReason.twin),
  'block_count_3d': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'block_escape': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'block_stacking_physics': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'boats': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'box_completion': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.puzzle, family: 'cube_net_fold', reason: ArchiveReason.twin),
  'bridges': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'calculation_sprint': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'card_counting_memory': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'category_fluency': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'chain_reaction': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'chalk_and_talk': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.brokenConcept),
  'change_blindness': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'chimp_test': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'choice_reaction_time': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'reflex_tap', reason: ArchiveReason.twin),
  'classic_maze': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'clusters': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'cognate_catch': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'collatz': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'color_flood': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'color_match': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'color_maze_nav': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'color_word_match_up': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'stroop_test', reason: ArchiveReason.twin),
  'common_denominator': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'compass_maze': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'complex_folding_nets': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.puzzle, family: 'cube_net_fold', reason: ArchiveReason.twin),
  'compound_connect': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'conjunction_search': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'visual_search', reason: ArchiveReason.twin),
  'consonant_reconstruct': GameProfile(tier: GameTier.archive, kind: CardKind.word, origin: GameOrigin.puzzle, family: 'missing_vowels', reason: ArchiveReason.twin),
  'context_clues': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'continuous_paired_associate': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'continuous_recognition', reason: ArchiveReason.twin),
  'continuous_recognition': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'conundrum_anagram': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'corsi_backward_span': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'corsi_blocks', reason: ArchiveReason.twin),
  'corsi_blocks': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'countdown_math': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'counting_sheep': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'counting_span': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'operation_span', reason: ArchiveReason.twin),
  'cross_section_slice': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'crossword': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'crown': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'crypto_arithmetic': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'cryptogram': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'cube': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'cube_net_fold': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'd2_attention': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'letter_cancellation', reason: ArchiveReason.twin),
  'definition_dash': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'delayed_match_sample': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'digit_span_reverse': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'digit_swap_eq': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'directions_recall': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'distractor_matrix': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'divided_attention': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'divisibility_dash': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'dnms': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'delayed_match_sample', reason: ArchiveReason.twin),
  'dominosa': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'double_n_back': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'n_back', reason: ArchiveReason.twin),
  'double_trouble': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'dual_coding': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'dual_mirror': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'dual_task_memory': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'dynamic_salience': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'einstein_riddle': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'etymology_origin': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'etymon_oddball': GameProfile(tier: GameTier.archive, kind: CardKind.word, origin: GameOrigin.puzzle, family: 'etymology_origin', reason: ArchiveReason.twin),
  'event_timeline_memory': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'exponent_tower': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'face_name_association': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'face_trait_association': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'face_name_association', reason: ArchiveReason.twin),
  'fact_binder': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'associative_pairs', reason: ArchiveReason.twin),
  'factor_finder': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'feature_matrix_recall': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'fibonacci_merge': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'fillomino': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'find_word': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'flanker_test': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'focus_tunnel': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'fraction_match': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'fraction_matcher': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, family: 'fraction_match', reason: ArchiveReason.twin),
  'fractional_pizza': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'frequency_tap': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'futoshiki': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'galaxies': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'game_2048': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'gear_rotation': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'gear_train_direction': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.puzzle, family: 'gear_rotation', reason: ArchiveReason.twin),
  'ghost_tap': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'go_no_go': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'gokigen_naname': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'grammar_police': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'grammar_sort': GameProfile(tier: GameTier.archive, kind: CardKind.word, origin: GameOrigin.puzzle, family: 'grammar_police', reason: ArchiveReason.twin),
  'graph_coordinate_plot': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, reason: ArchiveReason.noGame),
  'grid_displacement': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'object_displacement', reason: ArchiveReason.twin),
  'grocery_list': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'heyawake': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'hitori': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'homophone_hunt': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'hue_sort': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'inequality_balance_ops': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, family: 'inequality_dash', reason: ArchiveReason.twin),
  'inequality_dash': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'inertia': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'interlock_puzzle': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'kakurasu_sums': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'kakuro': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'kenken': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'klotski': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'kurodoko': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'laser_link': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'letter_bridge': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'letter_cancellation': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'letter_frequency_scan': GameProfile(tier: GameTier.archive, kind: CardKind.word, origin: GameOrigin.puzzle, reason: ArchiveReason.noGame),
  'letter_grid_swapper': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'lighthouses': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'lights_out': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'lock_pattern': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'logical_syllogisms': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'magic_squares': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'magnets': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'mandala_recall': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'map': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'masyu': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'math_guess': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'math_maze': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'math_path': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'mathrax': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'matrix_multiplier': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, reason: ArchiveReason.noGame),
  'matrix_multiplier_match': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, reason: ArchiveReason.noGame),
  'matrix_reasoning': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'maze_nav_3d': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'memory_matrix': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'memory_palace': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'mental_abacus': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'mental_calendar': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'mental_mapping': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'mental_rotation': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'minesweeper': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'mirror_image': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'mirror_maze': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'mirror_tracing': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'missing_operator': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'missing_vowels': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'modular_clock_arithmetic': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, family: 'modulo_clock', reason: ArchiveReason.twin),
  'modulo_clock': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'modulo_path': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, family: 'modulo_clock', reason: ArchiveReason.twin),
  'multi_track_counter': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'multiple_object_tracking', reason: ArchiveReason.twin),
  'multiple_object_tracking': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'n_back': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'narrative_recall': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'story_builder', reason: ArchiveReason.twin),
  'navon_hierarchical': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'negative_space_detection': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'netslide': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'nonogram': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'norinori': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'number_bonds': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'numerical_estimation': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'nurikabe': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'object_displacement': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'object_shuffle': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'odd_even_flash': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'odd_one_out': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'odd_rotation': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.puzzle, family: 'mental_rotation', reason: ArchiveReason.twin),
  'one_letter_shift': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'operation_span': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'orbit_tap': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'oxymoron_hunt': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'palindrome_builder': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'pangram_sprint': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'paper_folding': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'path_finder': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'path_intersect': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'path_recall': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'pattern_sequence_draw': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'pegs': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'percentage_peak': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'percentage_shopping': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, family: 'percentage_peak', reason: ArchiveReason.twin),
  'peripheral_focus': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'perspective_shift_view': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'perspective_taking': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'phonetic_guess': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'pipes': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'pixel_mimic': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'polyomino_tiling': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'portmanteau_split': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'posner_spatial_cueing': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'prime_factor_trees': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'prime_gap_hunt': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, family: 'prime_hunter', reason: ArchiveReason.twin),
  'prime_hunter': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'probe_digit_span': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'digit_span_reverse', reason: ArchiveReason.twin),
  'pythagorean_triple_builder': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, reason: ArchiveReason.noGame),
  'quick_math': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'radical_roots': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, reason: ArchiveReason.noGame),
  'reading_span': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'operation_span', reason: ArchiveReason.twin),
  'reflex_tap': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'relational_memory': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'associative_pairs', reason: ArchiveReason.twin),
  'reverse_stroop': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'stroop_test', reason: ArchiveReason.twin),
  'rhyme_master': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'rhythm_master': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'roman_arithmetic': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'room_inspector': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'rotating_maze': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'rule_switcher': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'running_memory_span': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'digit_span_reverse', reason: ArchiveReason.twin),
  'same_game': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'schulte_table': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'sdmt': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'seismic': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'semantic_association': GameProfile(tier: GameTier.archive, kind: CardKind.word, origin: GameOrigin.puzzle, family: 'semantic_link', reason: ArchiveReason.twin),
  'semantic_distance': GameProfile(tier: GameTier.archive, kind: CardKind.word, origin: GameOrigin.puzzle, family: 'semantic_link', reason: ArchiveReason.twin),
  'semantic_link': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'sentence_unscramble': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'sequence_sleuth': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'sequence_stack': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'set_theory_venn': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'shadow_pivot': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'shape_shifter': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'shell_game': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'shikaku': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'signpost': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'silent_letter_search': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'silhouette_match': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'silhouette_match_ortho': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.puzzle, family: 'silhouette_match', reason: ArchiveReason.twin),
  'simon_command': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'simon_sequence': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'skyscrapers': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'slide_puzzle': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'slitherlink': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'sopt': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'source_monitoring': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'spatial_cabinet_memory': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'spatial_conflict': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'stroop_test', reason: ArchiveReason.twin),
  'spelling_sprint': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'spoonerism_solver': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'spotlight_track': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'multiple_object_tracking', reason: ArchiveReason.twin),
  'staircase_memory': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'sternberg_task': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'stop_signal': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'go_no_go', reason: ArchiveReason.twin),
  'story_builder': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'stroop_number_size': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'stroop_test', reason: ArchiveReason.twin),
  'stroop_test': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'subitizing_rush': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'sudoku': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'sum_pyramid': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'sum_snake': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'switch_task': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'rule_switcher', reason: ArchiveReason.twin),
  'syllable_stack': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'symbol_digit_assoc': GameProfile(tier: GameTier.library, kind: CardKind.snap, origin: GameOrigin.lab),
  'symbol_logic': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'symbolic_flanker': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'flanker_test', reason: ArchiveReason.twin),
  'symmetry': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'symmetry_span': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'operation_span', reason: ArchiveReason.twin),
  'tangle_fix': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'tangram': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'tapa': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'target_10': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'target_number': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, family: 'countdown_math', reason: ArchiveReason.twin),
  'temporal_order': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'temporal_order_judgment': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'tenner_grid': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'tents_and_trees': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'topology': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'tower_of_london': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'trace_path': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'trail_making': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'triplets_logic': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'twiddle': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'typing_speed': GameProfile(tier: GameTier.archive, kind: CardKind.word, origin: GameOrigin.puzzle, reason: ArchiveReason.noGame),
  'typoglycemia_decoder': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'unit_converter_pro': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'vector_dot_product': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, reason: ArchiveReason.noGame),
  'vector_grid_alignment': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.puzzle, reason: ArchiveReason.noGame),
  'vektor_vector': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.worksheet, reason: ArchiveReason.noGame),
  'venn_numbers': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.worksheet),
  'verbal_analogies': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'vigilance_task': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'visual_crowding_acuity': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'visual_search': GameProfile(tier: GameTier.deck, kind: CardKind.snap, origin: GameOrigin.lab),
  'visual_search_conjunction': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'visual_search', reason: ArchiveReason.twin),
  'visual_statistical_learning': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, reason: ArchiveReason.noGame),
  'vocabulary_builder': GameProfile(tier: GameTier.archive, kind: CardKind.word, origin: GameOrigin.puzzle, family: 'definition_dash', reason: ArchiveReason.twin),
  'vowel_reconstruct': GameProfile(tier: GameTier.archive, kind: CardKind.word, origin: GameOrigin.puzzle, family: 'missing_vowels', reason: ArchiveReason.twin),
  'water_sort': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
  'wireframe_3d_rotation': GameProfile(tier: GameTier.archive, kind: CardKind.think, origin: GameOrigin.puzzle, family: 'mental_rotation', reason: ArchiveReason.twin),
  'wisconsin_card_sorting': GameProfile(tier: GameTier.library, kind: CardKind.think, origin: GameOrigin.puzzle),
  'word_association_recall': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'associative_pairs', reason: ArchiveReason.twin),
  'word_grid_connection': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'word_ladder': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'word_ladder_step': GameProfile(tier: GameTier.archive, kind: CardKind.word, origin: GameOrigin.puzzle, family: 'word_ladder', reason: ArchiveReason.twin),
  'word_mastermind': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'word_pair_associate_memory': GameProfile(tier: GameTier.archive, kind: CardKind.snap, origin: GameOrigin.lab, family: 'associative_pairs', reason: ArchiveReason.twin),
  'word_scramble': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'word_search': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'word_snake_trail': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'word_surge': GameProfile(tier: GameTier.library, kind: CardKind.word, origin: GameOrigin.quiz),
  'word_wheel': GameProfile(tier: GameTier.deck, kind: CardKind.word, origin: GameOrigin.puzzle),
  'yajilin': GameProfile(tier: GameTier.deck, kind: CardKind.think, origin: GameOrigin.puzzle),
};

/// The profile for [id], or null when the id is not in the catalog at all.
GameProfile? profileOf(String id) => gameProfiles[id];

/// The profile, reachable from the game itself.
///
/// The fields live in one table instead of in 313 `_metadata.dart` files: adding a
/// required field to `GameMetadata` would mean editing every one of them, and three of
/// these (tier, family, reason) are the catalog's business, not the game's.
extension GameMetadataProfile on GameMetadata {
  GameProfile? get profile => profileOf(id);

  /// Not in the catalog means not dealt and not listed: a new game has to be given a
  /// verdict in docs/CATALOG.md before a player can see it.
  GameTier get tier => profile?.tier ?? GameTier.archive;
  CardKind get kind => profile?.kind ?? CardKind.think;
  GameOrigin get origin => profile?.origin ?? GameOrigin.puzzle;
  String? get family => profile?.family;
  ArchiveReason? get archiveReason => profile?.reason;
}

/// Every game in the registry that the catalog leaves out, which should be none.
List<GameMetadata> gamesWithoutVerdict(List<GameMetadata> registry) =>
    registry.where((game) => !gameProfiles.containsKey(game.id)).toList();

/// Every id the catalog puts in the deal.
Set<String> get deckIds => {
  for (final entry in gameProfiles.entries)
    if (entry.value.tier == GameTier.deck) entry.key,
};

/// Every id a player can open: the deal and the library, never the archive.
Set<String> get visibleIds => {
  for (final entry in gameProfiles.entries)
    if (entry.value.tier != GameTier.archive) entry.key,
};

/// The ids the catalog archived: lab tasks, worksheets and twins.
///
/// They stay in the app's registry so their code, tests and strings keep
/// compiling, and a player can still look at them behind the "show archived"
/// switch. Nothing deals them.
Set<String> get archivedIds => {
  for (final entry in gameProfiles.entries)
    if (entry.value.tier == GameTier.archive) entry.key,
};
