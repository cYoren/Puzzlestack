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
generator proves its own deal. `unproven` means the game generates content and nothing
proves the deal is winnable, or has one answer where the genre implies one:
the `uniqueness` job. `pool-fairness` means a fixed content pool, where the proof is
"every row is solvable", i.e. check 10. `fair-by-play` means a lab task, worksheet or
quiz, whose answer is the task's own and not deduced from clues, so fairness is judged
by playing.

| | Deck | Library | Archive |
| --- | --- | --- | --- |
| Games | 12 | 17 | 9 |

**Origin tags** in this room, which is what the uniqueness column above turns on:

| Origin | Games |
| --- | --- |
| lab | 38 |

**Check 6 evidence.** `AUDIT_ONLY=<room ids> flutter test test/board/game_audit.dart`,
light and `AUDIT_DARK=1`:

- light: `AUDIT checked=38 overflow=0 threw=0`
- dark: `AUDIT checked=38 overflow=0 threw=0`

## Per game

| Game | Title | Tier | 2 fair | 5 fresh | 6 app | 7 tap | 8 ends | 9 name | 10 rule |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `action_sequence_recall` | Action Recall | library | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `associative_pairs` | Associative Pairs | library | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `card_counting_memory` | Card Counter | deck | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `chimp_test` | Chimp Test | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `continuous_recognition` | Continuous Recog | library | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `corsi_blocks` | CORSI BLOCKS | deck | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `delayed_match_sample` | Delayed Match | library | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `digit_span_reverse` | Reverse Span | library | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `directions_recall` | Directions Recall | library | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `distractor_matrix` | Distractor Matrix | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `dual_coding` | Dual Coding | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `dual_task_memory` | Dual-Task Memory | archive | fair-by-play | pass | audit-clean | pass | pass | fail | fail |
| `event_timeline_memory` | Event Timeline | library | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `face_name_association` | Face-Name | library | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `feature_matrix_recall` | Feature Matrix | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `grocery_list` | Grocery List | library | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `mandala_recall` | Mandala Recall | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `memory_matrix` | Memory Matrix | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `memory_palace` | Memory Palace | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `n_back` | N-Back Test | library | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `object_displacement` | Object Displacement | library | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `object_shuffle` | Object Shuffle | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `operation_span` | Operation Span | library | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `path_recall` | Path Recall | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `pattern_sequence_draw` | Pattern Recall | deck | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `pixel_mimic` | Pixel Mimic | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `room_inspector` | Room Inspector | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `sequence_stack` | Sequence Stack | deck | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `simon_sequence` | Sequence | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `sopt` | Self-Ordered Pointing | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `source_monitoring` | Source Monitoring | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `spatial_cabinet_memory` | Spatial Cabinets | library | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `staircase_memory` | Staircase Memory | library | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `sternberg_task` | Sternberg Task | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `story_builder` | Story Builder | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `symbol_digit_assoc` | Symbol-Digit Assoc | library | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `temporal_order` | Temporal Order | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `visual_statistical_learning` | Visual Stats Learning | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |

## What needs a fix job

PUZZLE-BAR.md's working procedure keeps fixes out of the triage PR: each of these is
its own change with its own test. Grouped by the job that fixes it, because the fix is
usually one mechanism and not N edits.

- **`plain-names` — sentence case, no lab vocabulary (check 9)** — 24: `associative_pairs`, `chimp_test`, `continuous_recognition`, `corsi_blocks`, `digit_span_reverse`, `distractor_matrix`, `dual_coding`, `dual_task_memory`, `face_name_association`, `grocery_list`, `mandala_recall`, `n_back`, `object_displacement`, `object_shuffle`, `operation_span`, `path_recall`, `pixel_mimic`, `simon_sequence`, `source_monitoring`, `spatial_cabinet_memory`, `staircase_memory`, `sternberg_task`, `temporal_order`, `visual_statistical_learning`
- **`rule-tests` — a test that fails if the content breaks the game (check 10)** — 16: `action_sequence_recall`, `card_counting_memory`, `chimp_test`, `continuous_recognition`, `delayed_match_sample`, `directions_recall`, `dual_task_memory`, `event_timeline_memory`, `feature_matrix_recall`, `mandala_recall`, `object_displacement`, `pattern_sequence_draw`, `sequence_stack`, `sopt`, `spatial_cabinet_memory`, `symbol_digit_assoc`

Every game here has a how-to-play guide (`lib/data/game_guides.dart`). The card's
own goal line is still owed to `card-teaches` (check 3), for the room as a whole.

## What the play pass has to answer

29 games. Play five times at phone size, write the first thing that
confused you, then confirm or move the id in `docs/CATALOG.md` with one line of reason:

`action_sequence_recall`, `associative_pairs`, `card_counting_memory`, `chimp_test`, `continuous_recognition`, `corsi_blocks`, `delayed_match_sample`, `digit_span_reverse`, `directions_recall`, `event_timeline_memory`, `face_name_association`, `grocery_list`, `mandala_recall`, `memory_matrix`, `memory_palace`, `n_back`, `object_displacement`, `object_shuffle`, `operation_span`, `path_recall`, `pattern_sequence_draw`, `pixel_mimic`, `room_inspector`, `sequence_stack`, `simon_sequence`, `spatial_cabinet_memory`, `staircase_memory`, `story_builder`, `symbol_digit_assoc`
