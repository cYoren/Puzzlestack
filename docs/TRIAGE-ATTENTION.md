# Triage: Attention

Mechanical pass over every game in the room against [PUZZLE-BAR.md](PUZZLE-BAR.md), by
`tool/triage_room.py`. Regenerate with:

```bash
python3 tool/triage_room.py attention
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
| Games | 5 | 0 | 47 |

**Origin tags** in this room, which is what the uniqueness column above turns on:

| Origin | Games |
| --- | --- |
| lab | 52 |

**Check 6 evidence.** `AUDIT_ONLY=<room ids> flutter test test/board/game_audit.dart`,
light and `AUDIT_DARK=1`:

- light: `AUDIT checked=52 overflow=0 threw=0`
- dark: `AUDIT checked=52 overflow=0 threw=0`

## Per game

| Game | Title | Tier | 2 fair | 5 fresh | 6 app | 7 tap | 8 ends | 9 name | 10 rule |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `ab_reversal_oddball` | A-B Reversal | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `attentional_blink` | Attentional Blink | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `attentional_blink_probe` | Blink Probe | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `blink_detector` | Blink Detector | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `chalk_and_talk` | Chalk & Talk | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `change_blindness` | Change Blindness | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `choice_reaction_time` | Choice Reaction Time | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `color_match` | Colour Match | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `color_maze_nav` | Color Maze Nav | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `color_word_match_up` | Color Match-Up | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `counting_sheep` | Counting Sheep | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `d2_attention` | d2 Attention | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `divided_attention` | Divided Attention | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `double_trouble` | Double Trouble | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `dual_mirror` | Dual Mirror Nav | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `dynamic_salience` | Dynamic Salience | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `flanker_test` | FLANKER TEST | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `focus_tunnel` | Focus Tunnel | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `frequency_tap` | Frequency Tap | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `ghost_tap` | Ghost Tap | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `go_no_go` | Go / No-Go | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `letter_cancellation` | Letter Cancel | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `multi_track_counter` | Multi-Track Counter | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `multiple_object_tracking` | Object Tracker | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `navon_hierarchical` | Navon Global | archive | fair-by-play | pass | audit-clean | pass | pass | fail | fail |
| `odd_even_flash` | Odd-Even Flash | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `odd_one_out` | Odd One Out | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `orbit_tap` | Orbit Tap | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `peripheral_focus` | Peripheral Focus | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `posner_spatial_cueing` | Spatial Cue | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `reflex_tap` | Reflex Tap | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `reverse_stroop` | Reverse Stroop | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `rhythm_master` | Rhythm Master | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `rule_switcher` | Rule Switcher | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `schulte_table` | Schulte Table | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `sdmt` | Sdmt Test | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `shape_shifter` | Shape Shifter | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `shell_game` | Shell Game | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `simon_command` | Simon Command | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `spatial_conflict` | Spatial Conflict | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `spotlight_track` | Spotlight Track | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `stop_signal` | Stop Signal | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `stroop_number_size` | Size Stroop | archive | fair-by-play | pass | audit-clean | pass | pass | fail | fail |
| `stroop_test` | Stroop Test | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `subitizing_rush` | Subitize Rush | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `switch_task` | Switch Task | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `symbolic_flanker` | Symbolic Flanker | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `temporal_order_judgment` | Time Order | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `trail_making` | Trail Making | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `vigilance_task` | Vigilance Task | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `visual_crowding_acuity` | Visual Crowd | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `visual_search` | Visual Search | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |

## What needs a fix job

PUZZLE-BAR.md's working procedure keeps fixes out of the triage PR: each of these is
its own change with its own test. Grouped by the job that fixes it, because the fix is
usually one mechanism and not N edits.

- **`rule-tests` — a test that fails if the content breaks the game (check 10)** — 22: `ab_reversal_oddball`, `attentional_blink_probe`, `blink_detector`, `chalk_and_talk`, `color_maze_nav`, `color_word_match_up`, `double_trouble`, `dynamic_salience`, `focus_tunnel`, `frequency_tap`, `multi_track_counter`, `multiple_object_tracking`, `navon_hierarchical`, `odd_even_flash`, `peripheral_focus`, `posner_spatial_cueing`, `shape_shifter`, `simon_command`, `stroop_number_size`, `subitizing_rush`, `temporal_order_judgment`, `visual_crowding_acuity`
- **`plain-names` — sentence case, no lab vocabulary (check 9)** — 17: `attentional_blink`, `choice_reaction_time`, `d2_attention`, `dual_mirror`, `flanker_test`, `navon_hierarchical`, `reflex_tap`, `reverse_stroop`, `sdmt`, `simon_command`, `spatial_conflict`, `spotlight_track`, `stroop_number_size`, `stroop_test`, `switch_task`, `symbolic_flanker`, `vigilance_task`

Every game here has a how-to-play guide (`lib/data/game_guides.dart`). The card's
own goal line is still owed to `card-teaches` (check 3), for the room as a whole.

## What the play pass has to answer

5 games. Play five times at phone size, write the first thing that
confused you, then confirm or move the id in `docs/CATALOG.md` with one line of reason:

`change_blindness`, `color_match`, `schulte_table`, `shell_game`, `visual_search`
