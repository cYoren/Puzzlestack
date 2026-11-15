# Triage: Logic

Mechanical pass over every game in the room against [PUZZLE-BAR.md](PUZZLE-BAR.md), by
`tool/triage_room.py`. Regenerate with:

```bash
python3 tool/triage_room.py logic
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
| Games | 44 | 13 | 0 |

**Origin tags** in this room, which is what the uniqueness column above turns on:

| Origin | Games |
| --- | --- |
| puzzle | 57 |

**Check 6 evidence.** `AUDIT_ONLY=<room ids> flutter test test/board/game_audit.dart`,
light and `AUDIT_DARK=1`:

- light: `AUDIT checked=57 overflow=0 threw=0`
- dark: `AUDIT checked=57 overflow=0 threw=0`

## Per game

| Game | Title | Tier | 2 fair | 5 fresh | 6 app | 7 tap | 8 ends | 9 name | 10 rule |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `abcd` | ABCD | library | pass | pass | audit-clean | pass | pass | shouting | pass |
| `akari` | Akari | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `ascent` | Number Path | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `binary_puzzle` | BINARY PUZZLE | deck | unproven | pass | audit-clean | pass | pass | shouting | pass |
| `block_escape` | BLOCK ESCAPE | deck | unproven | pass | audit-clean | pass | pass | shouting | pass |
| `boats` | Boats | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `bridges` | BRIDGES | deck | pass-named-unique | pass | audit-clean | pass | pass | shouting | pass |
| `clusters` | Clusters | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `color_flood` | Color Flood | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `crown` | CROWN | deck | pass-named-unique | pass | audit-clean | pass | pass | shouting | pass |
| `cube` | CUBE | deck | unproven | pass | audit-clean | pass | pass | shouting | pass |
| `dominosa` | DOMINOSA | deck | unproven | pass | audit-clean | pass | pass | shouting | pass |
| `einstein_riddle` | EINSTEIN RIDDLE | library | pass-named-unique | pass | audit-clean | pass | pass | shouting | pass |
| `fillomino` | FILLOMINO | deck | unproven | pass | audit-clean | pass | pass | shouting | pass |
| `futoshiki` | Futoshiki | deck | pass | pass | audit-clean | pass | pass | shouting | pass |
| `galaxies` | Galaxies | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `gokigen_naname` | Gokigen Naname | deck | unproven | pass | audit-clean | pass | pass | pass | fail |
| `heyawake` | Heyawake | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `hitori` | HITORI | deck | unproven | pass | audit-clean | pass | pass | shouting | pass |
| `inertia` | INERTIA | deck | unproven | pass | audit-clean | pass | pass | shouting | pass |
| `kakurasu_sums` | Kakurasu Sums | deck | unproven | pass | audit-clean | pass | pass | pass | fail |
| `kakuro` | Kakuro | deck | unproven | pass | audit-clean | pass | pass | shouting | pass |
| `kurodoko` | Kurodoko | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `lighthouses` | LIGHTHOUSES | deck | pass-named-unique | pass | audit-clean | pass | pass | shouting | pass |
| `lights_out` | LIGHTS OUT | deck | pass-named-unique | pass | audit-clean | pass | pass | shouting | pass |
| `lock_pattern` | Lock Pattern | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `logical_syllogisms` | Logical Syllogisms | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `magnets` | MAGNETS | deck | pass | pass | audit-clean | pass | pass | shouting | pass |
| `map` | MAP | deck | unproven | pass | audit-clean | pass | pass | shouting | pass |
| `masyu` | Masyu Loop | deck | unproven | pass | audit-clean | pass | pass | pass | fail |
| `matrix_reasoning` | Matrix Reasoning | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `minesweeper` | Minesweeper | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `netslide` | NETSLIDE | deck | unproven | pass | audit-clean | pass | pass | shouting | pass |
| `nonogram` | Nonogram | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `norinori` | Norinori | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `nurikabe` | NURIKABE | deck | pass-named-unique | pass | audit-clean | pass | pass | shouting | pass |
| `path_finder` | Path Finder | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `pegs` | Pegs | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `pipes` | Pipes | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `same_game` | Same Game | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `seismic` | Ripple Effect | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `shikaku` | Shikaku | deck | unproven | pass | audit-clean | pass | pass | shouting | fail |
| `signpost` | SIGNPOST | deck | pass | pass | audit-clean | pass | pass | shouting | pass |
| `skyscrapers` | SKYSCRAPERS | deck | pass | pass | audit-clean | pass | pass | shouting | pass |
| `slitherlink` | Slitherlink | deck | pass-named-unique | pass | audit-clean | pass | pass | shouting | pass |
| `sudoku` | Sudoku | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `symbol_logic` | Symbol Logic | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `tangle_fix` | Tangle Fix | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `tapa` | Tapa | deck | unproven | pass | audit-clean | pass | pass | pass | fail |
| `tenner_grid` | Tenner Grid | deck | unproven | pass | audit-clean | pass | pass | pass | fail |
| `tents_and_trees` | Tents & Trees | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `tower_of_london` | Tower of London | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `triplets_logic` | Triplets Trio | library | unproven | pass | audit-clean | pass | pass | pass | fail |
| `twiddle` | Twiddle | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `water_sort` | Water Sort | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `wisconsin_card_sorting` | Wisconsin Card Sort | library | unproven | pass | audit-clean | pass | pass | fail | pass |
| `yajilin` | Yajilin | deck | unproven | pass | audit-clean | pass | pass | pass | fail |

## What needs a fix job

PUZZLE-BAR.md's working procedure keeps fixes out of the triage PR: each of these is
its own change with its own test. Grouped by the job that fixes it, because the fix is
usually one mechanism and not N edits.

- **`uniqueness` — the generator must prove its deal (check 2)** — 33: `binary_puzzle`, `block_escape`, `color_flood`, `cube`, `dominosa`, `fillomino`, `gokigen_naname`, `heyawake`, `hitori`, `inertia`, `kakurasu_sums`, `kakuro`, `lock_pattern`, `logical_syllogisms`, `map`, `masyu`, `matrix_reasoning`, `netslide`, `path_finder`, `pegs`, `pipes`, `same_game`, `shikaku`, `symbol_logic`, `tangle_fix`, `tapa`, `tenner_grid`, `tower_of_london`, `triplets_logic`, `twiddle`, `water_sort`, `wisconsin_card_sorting`, `yajilin`
- **`plain-names` — sentence case, no lab vocabulary (check 9)** — 24: `abcd`, `binary_puzzle`, `block_escape`, `bridges`, `crown`, `cube`, `dominosa`, `einstein_riddle`, `fillomino`, `futoshiki`, `hitori`, `inertia`, `kakuro`, `lighthouses`, `lights_out`, `magnets`, `map`, `netslide`, `nurikabe`, `shikaku`, `signpost`, `skyscrapers`, `slitherlink`, `wisconsin_card_sorting`
- **`rule-tests` — a test that fails if the content breaks the game (check 10)** — 8: `gokigen_naname`, `kakurasu_sums`, `masyu`, `shikaku`, `tapa`, `tenner_grid`, `triplets_logic`, `yajilin`

**The `uniqueness` job, in two passes.** A test that shows a generated deal has a
solution does not show it is the only one, but it does mean the deal is not unwinnable:

- winnable, not unique (18): `binary_puzzle`, `block_escape`, `color_flood`, `cube`, `dominosa`, `fillomino`, `heyawake`, `hitori`, `inertia`, `map`, `netslide`, `pegs`, `pipes`, `same_game`, `tangle_fix`, `tower_of_london`, `twiddle`, `water_sort`

- neither proven (15): `gokigen_naname`, `kakurasu_sums`, `kakuro`, `lock_pattern`, `logical_syllogisms`, `masyu`, `matrix_reasoning`, `path_finder`, `shikaku`, `symbol_logic`, `tapa`, `tenner_grid`, `triplets_logic`, `wisconsin_card_sorting`, `yajilin`

Every game here has a how-to-play guide (`lib/data/game_guides.dart`). The card's
own goal line is still owed to `card-teaches` (check 3), for the room as a whole.

## What the play pass has to answer

57 games. Play five times at phone size, write the first thing that
confused you, then confirm or move the id in `docs/CATALOG.md` with one line of reason:

`abcd`, `akari`, `ascent`, `binary_puzzle`, `block_escape`, `boats`, `bridges`, `clusters`, `color_flood`, `crown`, `cube`, `dominosa`, `einstein_riddle`, `fillomino`, `futoshiki`, `galaxies`, `gokigen_naname`, `heyawake`, `hitori`, `inertia`, `kakurasu_sums`, `kakuro`, `kurodoko`, `lighthouses`, `lights_out`, `lock_pattern`, `logical_syllogisms`, `magnets`, `map`, `masyu`, `matrix_reasoning`, `minesweeper`, `netslide`, `nonogram`, `norinori`, `nurikabe`, `path_finder`, `pegs`, `pipes`, `same_game`, `seismic`, `shikaku`, `signpost`, `skyscrapers`, `slitherlink`, `sudoku`, `symbol_logic`, `tangle_fix`, `tapa`, `tenner_grid`, `tents_and_trees`, `tower_of_london`, `triplets_logic`, `twiddle`, `water_sort`, `wisconsin_card_sorting`, `yajilin`
