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
| Games | 18 | 9 | 11 |

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
| `attentional_blink` | Attentional Blink | library | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `chalk_and_talk` | Chalk & Talk | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `change_blindness` | Change Blindness | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `color_match` | COLOR MATCH | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `color_maze_nav` | Color Maze Nav | deck | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `counting_sheep` | Counting Sheep | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `divided_attention` | Divided Attention | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `double_trouble` | Double Trouble | deck | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `dual_mirror` | Dual Mirror Nav | archive | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `dynamic_salience` | Dynamic Salience | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `flanker_test` | FLANKER TEST | library | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `focus_tunnel` | Focus Tunnel | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `frequency_tap` | Frequency Tap | library | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `ghost_tap` | Ghost Tap | library | fair-by-play | check-pool | audit-clean | pass | pass | pass | fail |
| `go_no_go` | Go / No-Go | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `letter_cancellation` | Letter Cancel | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `multiple_object_tracking` | Object Tracker | deck | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `navon_hierarchical` | Navon Global | archive | fair-by-play | pass | audit-clean | pass | pass | fail | fail |
| `odd_even_flash` | Odd-Even Flash | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `odd_one_out` | Odd One Out | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `orbit_tap` | Orbit Tap | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `peripheral_focus` | Peripheral Focus | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `posner_spatial_cueing` | Spatial Cue | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `reflex_tap` | Reflex Tap | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `rhythm_master` | Rhythm Master | deck | fair-by-play | check-pool | audit-clean | pass | pass | pass | fail |
| `rule_switcher` | Rule Switcher | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `schulte_table` | Schulte Table | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | pass |
| `sdmt` | Sdmt Test | library | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `shape_shifter` | Shape Shifter | library | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `shell_game` | Shell Game | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `simon_command` | Simon Command | deck | fair-by-play | pass | audit-clean | pass | pass | shouting | fail |
| `stroop_test` | Stroop Test | deck | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `subitizing_rush` | Subitize Rush | deck | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `temporal_order_judgment` | Time Order | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `trail_making` | Trail Making | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `vigilance_task` | Vigilance Task | archive | fair-by-play | pass | audit-clean | pass | pass | fail | pass |
| `visual_crowding_acuity` | Visual Crowd | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `visual_search` | Visual Search | deck | fair-by-play | pass | audit-clean | pass | pass | pass | pass |

## What needs a fix job

PUZZLE-BAR.md's working procedure keeps fixes out of the triage PR: each of these is
its own change with its own test. Grouped by the job that fixes it, because the fix is
usually one mechanism and not N edits.

- **`rule-tests` — a test that fails if the content breaks the game (check 10)** — 19: `chalk_and_talk`, `color_maze_nav`, `double_trouble`, `dynamic_salience`, `focus_tunnel`, `frequency_tap`, `ghost_tap`, `multiple_object_tracking`, `navon_hierarchical`, `odd_even_flash`, `peripheral_focus`, `posner_spatial_cueing`, `rhythm_master`, `shape_shifter`, `shell_game`, `simon_command`, `subitizing_rush`, `temporal_order_judgment`, `visual_crowding_acuity`
- **`plain-names` — sentence case, no lab vocabulary (check 9)** — 13: `attentional_blink`, `change_blindness`, `color_match`, `dual_mirror`, `flanker_test`, `navon_hierarchical`, `reflex_tap`, `schulte_table`, `sdmt`, `shell_game`, `simon_command`, `stroop_test`, `vigilance_task`
- **`feed-size` / pool size (check 5)** — 2: `ghost_tap`, `rhythm_master`

Every game here has a how-to-play guide (`lib/data/game_guides.dart`). The card's
own goal line is still owed to `card-teaches` (check 3), for the room as a whole.

## What the play pass has to answer

27 games. Play five times at phone size, write the first thing that
confused you, then confirm or move the id in `docs/CATALOG.md` with one line of reason:

`attentional_blink`, `change_blindness`, `color_match`, `color_maze_nav`, `counting_sheep`, `divided_attention`, `double_trouble`, `flanker_test`, `frequency_tap`, `ghost_tap`, `go_no_go`, `letter_cancellation`, `multiple_object_tracking`, `odd_one_out`, `orbit_tap`, `reflex_tap`, `rhythm_master`, `rule_switcher`, `schulte_table`, `sdmt`, `shape_shifter`, `shell_game`, `simon_command`, `stroop_test`, `subitizing_rush`, `trail_making`, `visual_search`
