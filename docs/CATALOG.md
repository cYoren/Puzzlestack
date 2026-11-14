# The catalog: a verdict for every game

All 313 registry ids, each in exactly one list. Tiers and the checks behind them:
[PUZZLE-BAR.md](PUZZLE-BAR.md).

**This is a first pass (2026-11-14), made from ids, subtitles and the two audits, not from
playing each game.** Nothing here is final until its room's triage job
(`triage-<room>` in [ROADMAP.md](../ROADMAP.md)) has played the game and confirmed or moved it.
A game leaves the Archive if play shows a real decision in it. A game leaves Deck if it fails any
of the ten checks.

| | Deck | Library | Archive: twin | Archive: other | Total |
| --- | --- | --- | --- | --- | --- |
| Logic | 44 | 8 | 1 | 0 | 53 |
| Math | 19 | 25 | 10 | 9 | 63 |
| Memory | 12 | 17 | 16 | 9 | 54 |
| Attention | 18 | 9 | 16 | 11 | 54 |
| Word | 24 | 17 | 8 | 2 | 51 |
| Spatial | 22 | 9 | 6 | 1 | 38 |
| **All** | **139** | **85** | **57** | **32** | **313** |

Visible in the app after this pass: **224**. The other 89 are archived: hidden, tagged, still in
the repo. The store copy takes its number from the visible registry, never from this file.

## Format

Each room has four blocks. Ids are separated by spaces.

- `deck` is dealt in the feed once verified.
- `library` stays in its room only.
- `merge` lines read `keeper <- absorbed absorbed`. The keeper gains the absorbed game as a
  mode only if it plays differently; either way the absorbed game is then archived with reason `twin`. The keeper
  is also listed under `deck` or `library`.
- `archive` is hidden from the app and kept in the repo, reason `no-game` unless a note says
  otherwise.

**Origin tags** (see PUZZLE-BAR.md) by default: every Memory and Attention game is `lab`; Math
`library` and `archive` games are `worksheet`; Word `library` games are `quiz`; everything else
is `puzzle`. Notes list the exceptions. Triage corrects the tag along with the tier.

When triage moves an id, add one line under the room's **Notes** saying why.

## Logic (53)

The strongest room and the core of the Deck. Nearly all are unique-solution puzzles from the
Tatham and Nikoli canon.

```deck
akari binary_puzzle block_escape bridges color_flood crown cube dominosa fillomino futoshiki
galaxies gokigen_naname heyawake hitori inertia kakurasu_sums kakuro kurodoko lighthouses
lights_out magnets map masyu minesweeper netslide nonogram norinori nurikabe pegs pipes
same_game shikaku signpost skyscrapers slitherlink sudoku tangle_fix tapa tenner_grid
tents_and_trees tower_of_london twiddle water_sort yajilin
```

```library
einstein_riddle lock_pattern logical_syllogisms matrix_reasoning path_finder symbol_logic
triplets_logic wisconsin_card_sorting
```

```merge
sudoku <- alphabet_sudoku
```

```archive
```

Notes
- `matrix_reasoning` and `einstein_riddle` are promotion candidates: both are real puzzles, the
  first needs a run of rounds, the second needs a 3-house feed size that reads without a wall
  of clues.
- `wisconsin_card_sorting` is a good hidden-rule game under a bad name. Rename "Rule Finder".
- `minesweeper` is Deck only with a no-guess generator.
- `nonogram` is Deck only once `nonogram-uniqueness` lands.

## Math (63)

Split between number puzzles (Deck) and school drills (Library or out). A drill becomes a
puzzle when the player chooses a route to the answer rather than recalling it.

```deck
arithmetic_chain balance_scale countdown_math crypto_arithmetic digit_swap_eq fibonacci_merge
game_2048 kenken magic_squares math_guess math_maze math_path missing_operator number_bonds
quick_math sequence_sleuth sum_pyramid sum_snake target_10
```

```library
algebraic_balance angle_finder area_perimeter_match base_shift binary_code calculation_sprint
collatz common_denominator divisibility_dash exponent_tower factor_finder fraction_match
fractional_pizza inequality_dash mental_abacus mental_calendar modulo_clock
numerical_estimation percentage_peak prime_factor_trees prime_hunter roman_arithmetic
set_theory_venn unit_converter_pro venn_numbers
```

```merge
countdown_math <- target_number
balance_scale <- binary_scale_balance
fraction_match <- fraction_matcher
modulo_clock <- modular_clock_arithmetic modulo_path
base_shift <- base_conversion_run
inequality_dash <- algebraic_inequality_solver inequality_balance_ops
prime_hunter <- prime_gap_hunt
percentage_peak <- percentage_shopping
```

```archive
binary_matrix_rank binomial_match graph_coordinate_plot matrix_multiplier
matrix_multiplier_match pythagorean_triple_builder radical_roots vector_dot_product
vektor_vector
```

Notes
- `quick_math` is the one arithmetic sprint in the Deck, as a Snap card. The other sprints are
  Library.
- The Archive list is coursework (linear algebra, binomials, radicals). Nobody opens a puzzle
  feed to multiply matrices.

## Memory (54)

Mostly working-memory span tasks from the lab, many of them the same task with a different
stimulus. The Deck keeps the ones that are a game on sight.

```deck
card_counting_memory chimp_test corsi_blocks mandala_recall memory_matrix object_shuffle
path_recall pattern_sequence_draw pixel_mimic room_inspector sequence_stack simon_sequence
```

```library
action_sequence_recall associative_pairs continuous_recognition delayed_match_sample
digit_span_reverse directions_recall event_timeline_memory face_name_association grocery_list
memory_palace n_back object_displacement operation_span spatial_cabinet_memory
staircase_memory story_builder symbol_digit_assoc
```

```merge
corsi_blocks <- corsi_backward_span
n_back <- double_n_back
digit_span_reverse <- probe_digit_span running_memory_span
delayed_match_sample <- dnms
operation_span <- reading_span counting_span symmetry_span
object_displacement <- grid_displacement
continuous_recognition <- continuous_paired_associate
face_name_association <- face_trait_association
associative_pairs <- word_pair_associate_memory word_association_recall relational_memory fact_binder
story_builder <- narrative_recall
```

```archive
distractor_matrix dual_coding dual_task_memory feature_matrix_recall sopt source_monitoring
sternberg_task temporal_order visual_statistical_learning
```

Notes
- Every Memory card is a Snap card. Every kept game needs a plain name: "Digit Span",
  "Match After a Pause", "Span".

## Attention (54)

Reaction and attention tasks. Good as Snap cards between puzzles, in small doses, with one game
per idea rather than five.

```deck
change_blindness color_match color_maze_nav counting_sheep double_trouble
multiple_object_tracking odd_one_out orbit_tap reflex_tap rhythm_master rule_switcher
schulte_table shell_game simon_command stroop_test subitizing_rush trail_making visual_search
```

```library
attentional_blink divided_attention flanker_test frequency_tap ghost_tap go_no_go
letter_cancellation sdmt shape_shifter
```

```merge
stroop_test <- reverse_stroop stroop_number_size color_word_match_up spatial_conflict
flanker_test <- symbolic_flanker
attentional_blink <- attentional_blink_probe blink_detector
visual_search <- visual_search_conjunction conjunction_search
rule_switcher <- switch_task ab_reversal_oddball
go_no_go <- stop_signal
multiple_object_tracking <- multi_track_counter spotlight_track
letter_cancellation <- d2_attention
reflex_tap <- choice_reaction_time
```

```archive
chalk_and_talk dual_mirror dynamic_salience focus_tunnel navon_hierarchical odd_even_flash
peripheral_focus posner_spatial_cueing temporal_order_judgment vigilance_task
visual_crowding_acuity
```

Notes
- `chalk_and_talk` was reframed because the app has no audio; a listening game without sound
  is not a game. Reason `broken-concept`; it returns if sound ships.
- `vigilance_task` is boring by design. That is the task.
- Plain names: "Colour Clash" (Stroop), "Number Hunt" (Schulte), "Connect in Order" (Trail
  Making), "Track the Dots", "Spot the Change".

## Word (51)

All content is English. A Word card is dealt only when the app language has content for it.
Answer lists are curated common words; guess validators may be wide.

```deck
chain_reaction compound_connect conundrum_anagram crossword cryptogram find_word
homophone_hunt letter_bridge letter_grid_swapper missing_vowels one_letter_shift
pangram_sprint portmanteau_split rhyme_master sentence_unscramble spoonerism_solver
verbal_analogies word_grid_connection word_ladder word_mastermind word_scramble word_search
word_snake_trail word_wheel
```

```library
affix_factory anagram_definition category_fluency cognate_catch context_clues definition_dash
etymology_origin grammar_police oxymoron_hunt palindrome_builder phonetic_guess semantic_link
silent_letter_search spelling_sprint syllable_stack typoglycemia_decoder word_surge
```

```merge
word_ladder <- word_ladder_step
missing_vowels <- vowel_reconstruct consonant_reconstruct
semantic_link <- semantic_association semantic_distance
grammar_police <- grammar_sort
etymology_origin <- etymon_oddball
definition_dash <- vocabulary_builder
```

```archive
letter_frequency_scan typing_speed
```

Notes
- `find_word` and `word_mastermind` look like the same guess-the-word game. Triage decides
  whether one absorbs the other.
- `crossword` is Deck only as a 5x5 mini with a clue set written for it (`crossword-supply`).
- `word_wheel` is Deck only with hand-made wheels; the shipped dictionaries accept `AAA`.
- `typing_speed` measures typing. It is not a puzzle.

## Spatial (38)

A good room. Sliding, tiling and beam puzzles are Think cards; the rotation and folding
questions are runs.

```deck
block_count_3d classic_maze compass_maze cross_section_slice cube_net_fold gear_rotation
hue_sort klotski laser_link mental_rotation mirror_image mirror_maze paper_folding
path_intersect perspective_taking polyomino_tiling rotating_maze silhouette_match slide_puzzle
symmetry tangram topology
```

```library
block_stacking_physics interlock_puzzle maze_nav_3d mental_mapping mirror_tracing
negative_space_detection perspective_shift_view shadow_pivot trace_path
```

```merge
gear_rotation <- gear_train_direction
silhouette_match <- silhouette_match_ortho
cube_net_fold <- complex_folding_nets box_completion
mental_rotation <- wireframe_3d_rotation odd_rotation
```

```archive
vector_grid_alignment
```

Notes
- `laser_link` and `mirror_maze` may be one puzzle. Triage decides.
- `mirror_tracing` and `trace_path` are motor tasks; Library unless play says otherwise.

## Rebuilds from the Archive

Archived games are material. These are the ones with a real puzzle inside; each is a rebuild
job after 1.1.0, and each comes back through the bar like a new game.

| Archived | Could become |
| --- | --- |
| `vektor_vector`, `vector_dot_product` | **Vector Golf**: a few arrows, reach the target point by choosing and scaling them. Already close to a puzzle |
| `binary_matrix_rank` | a Lights Out variant: toggle rows to clear the grid (the same XOR arithmetic, as a board) |
| `graph_coordinate_plot` | a coordinate hunt: deduce hidden points from distance clues |
| `pythagorean_triple_builder`, `radical_roots` | number-fit puzzles: place given lengths so every triangle closes |
| `matrix_multiplier*`, `binomial_match` | nothing found yet; stay archived |
| `navon_hierarchical` | a round type inside Colour Clash (big letter made of small letters) |
| `sternberg_task`, `sopt`, `dnms` and the span twins | round types inside one Memory run, so the run varies |
| `posner_spatial_cueing`, `vigilance_task`, `visual_crowding_acuity` | nothing; these measure, they do not play |
| `chalk_and_talk` | a listening game, once sound exists |
| `typing_speed` | a Word Snap card only if the text is itself a puzzle (type the sentence with its vowels missing) |

## What the Deck still lacks

New puzzles come from [SOURCES.md](SOURCES.md), which lists the open-source collections we may
port from and the order to take them in. Add a game only after the triage is done, and only
when it brings a puzzle idea the Deck does not have.
