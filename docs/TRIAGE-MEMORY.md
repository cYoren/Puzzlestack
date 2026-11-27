# Triage: Memory

Mechanical pass over every game in the room against [PUZZLE-BAR.md](PUZZLE-BAR.md), by
`tool/triage_room.py`. Regenerate with:

```bash
python3 tool/triage_room.py memory
```

**What this is, and is not.** The checks a machine can decide are decided here, from the
code and from a mounted board at 320dp in both themes. The checks that need a person at
the board (1 *there is a decision*, 3 *five-second read* beyond string length, 4 *about a
minute*) are marked `needs-play` and are **not** guesses dressed as verdicts. Nothing in
this file marks a game verified; that is the play pass.

**Check 2, by genre.** `pass` and `pass-named-unique` mean the code has a solver, so the
generator proves its own deal. `pass-fair-not-unique` means the code has a prover that
enumerates the cheaper layouts and proves the deal cannot be won with fewer mirrors than
it demands, while several answers of that size are legal and any of them wins: proved
finishable, not unique. `unproven` means the game generates content and nothing
proves the deal is winnable, or has one answer where the genre implies one:
the `uniqueness` job. `pool-fairness` means a fixed content pool, where the proof is
"every row is solvable", i.e. check 10. `fair-by-play` means a lab task, worksheet or
quiz, whose answer is the task's own and not deduced from clues, so fairness is judged
by playing.

| | Deck | Library | Archive |
| --- | --- | --- | --- |
| Games | 1 | 0 | 53 |

**Origin tags** in this room, which is what the uniqueness column above turns on:

| Origin | Games |
| --- | --- |
| lab | 54 |

**Check 6 evidence.** `AUDIT_ONLY=<room ids> flutter test test/board/game_audit.dart`,
light and `AUDIT_DARK=1`:

- light: `AUDIT checked=54 overflow=0 threw=0`
- dark: `AUDIT checked=54 overflow=0 threw=0`

## Per game

| Game | Title | Tier | 2 fair | 5 fresh | 6 app | 7 tap | 8 ends | 9 name | 10 rule |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `action_sequence_recall` | Action Recall | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `associative_pairs` | Associative Pairs | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `card_counting_memory` | Card Counter | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `chimp_test` | Chimp Test | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `continuous_paired_associate` | Pair Associate | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `continuous_recognition` | Continuous Recog | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `corsi_backward_span` | Corsi Backward | archive | fair-by-play | pass | audit-clean | pass | pass | fail | fail |
| `corsi_blocks` | CORSI BLOCKS | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `counting_span` | Counting Span | archive | fair-by-play | pass | audit-clean | pass | pass | fail | fail |
| `delayed_match_sample` | Delayed Match | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `digit_span_reverse` | Reverse Span | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `directions_recall` | Directions Recall | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `distractor_matrix` | Distractor Matrix | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `dnms` | Non-Matching Memory | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `double_n_back` | Double N-Back | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `dual_coding` | Dual Coding | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `dual_task_memory` | Dual-Task Memory | archive | fair-by-play | pass | audit-clean | pass | pass | fail | fail |
| `event_timeline_memory` | Event Timeline | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `face_name_association` | Face-Name | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `face_trait_association` | Face-Trait | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `fact_binder` | Fact Binder | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `feature_matrix_recall` | Feature Matrix | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `grid_displacement` | Grid Displacement | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `grocery_list` | Grocery List | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `mandala_recall` | Mandala Recall | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `memory_matrix` | Memory Matrix | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `memory_palace` | Memory Palace | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `n_back` | N-Back Test | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `narrative_recall` | Narrative Recall | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `object_displacement` | Object Displacement | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `object_shuffle` | Object Shuffle | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `operation_span` | Operation Span | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `path_recall` | Path Recall | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `pattern_sequence_draw` | Pattern Recall | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `pixel_mimic` | Pixel Mimic | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `probe_digit_span` | Digit Probe | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `reading_span` | Reading Span | archive | fair-by-play | pass | audit-clean | pass | pass | fail | fail |
| `relational_memory` | Relational Memory | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `room_inspector` | Room Inspector | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `running_memory_span` | Running Span | archive | fair-by-play | pass | audit-clean | pass | pass | fail | fail |
| `sequence_stack` | Sequence Stack | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `simon_sequence` | Sequence | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `sopt` | Self-Ordered Pointing | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `source_monitoring` | Source Monitoring | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `spatial_cabinet_memory` | Spatial Cabinets | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `staircase_memory` | Staircase Memory | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `sternberg_task` | Sternberg Task | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `story_builder` | Story Builder | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `symbol_digit_assoc` | Symbol-Digit Assoc | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `symmetry_span` | Symmetry Span | archive | fair-by-play | pass | audit-clean | pass | pass | fail | fail |
| `temporal_order` | Temporal Order | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `visual_statistical_learning` | Visual Stats Learning | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `word_association_recall` | Word Association | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `word_pair_associate_memory` | Word Pairs | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |

## What needs a fix job

PUZZLE-BAR.md's working procedure keeps fixes out of the triage PR: each of these is
its own change with its own test. Grouped by the job that fixes it, because the fix is
usually one mechanism and not N edits.

- **`plain-names` — sentence case, no lab vocabulary (check 9)** — 32: `associative_pairs`, `chimp_test`, `continuous_recognition`, `corsi_backward_span`, `corsi_blocks`, `counting_span`, `digit_span_reverse`, `distractor_matrix`, `double_n_back`, `dual_coding`, `dual_task_memory`, `face_name_association`, `fact_binder`, `grocery_list`, `mandala_recall`, `n_back`, `narrative_recall`, `object_displacement`, `object_shuffle`, `operation_span`, `path_recall`, `pixel_mimic`, `reading_span`, `relational_memory`, `running_memory_span`, `source_monitoring`, `spatial_cabinet_memory`, `staircase_memory`, `sternberg_task`, `symmetry_span`, `temporal_order`, `visual_statistical_learning`
- **`rule-tests` — a test that fails if the content breaks the game (check 10)** — 27: `action_sequence_recall`, `card_counting_memory`, `chimp_test`, `continuous_recognition`, `corsi_backward_span`, `counting_span`, `delayed_match_sample`, `directions_recall`, `dual_task_memory`, `event_timeline_memory`, `feature_matrix_recall`, `grid_displacement`, `mandala_recall`, `narrative_recall`, `object_displacement`, `pattern_sequence_draw`, `probe_digit_span`, `reading_span`, `relational_memory`, `running_memory_span`, `sequence_stack`, `sopt`, `spatial_cabinet_memory`, `symbol_digit_assoc`, `symmetry_span`, `word_association_recall`, `word_pair_associate_memory`

Every game here has a how-to-play guide (`lib/data/game_guides.dart`). The card's
own goal line is still owed to `card-teaches` (check 3), for the room as a whole.

## What the play pass has to answer

1 games. Play five times at phone size, write the first thing that
confused you, then confirm or move the id in `docs/CATALOG.md` with one line of reason:

`simon_sequence`
