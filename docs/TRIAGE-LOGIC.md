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
| Games | 44 | 18 | 0 |

**Origin tags** in this room, which is what the uniqueness column above turns on:

| Origin | Games |
| --- | --- |
| puzzle | 62 |

**Check 6 evidence.** `AUDIT_ONLY=<room ids> flutter test test/board/game_audit.dart`,
light and `AUDIT_DARK=1`:

- light: `AUDIT checked=62 overflow=0 threw=0`
- dark: `AUDIT checked=62 overflow=0 threw=0`

## Per game

| Game | Title | Tier | 2 fair | 5 fresh | 6 app | 7 tap | 8 ends | 9 name | 10 rule |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `abcd` | Four Letters | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `akari` | Akari | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `ascent` | Number Path | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `binary_puzzle` | Binary Puzzle | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `block_escape` | Block Escape | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `boats` | Boats | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `bricks` | Bricks | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `bridges` | Bridges | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `clusters` | Clusters | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `color_flood` | Color Flood | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `crossing` | Number Crossing | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `crown` | Crowns | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `cube` | Cube | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `dominosa` | Dominosa | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `einstein_riddle` | House Logic | library | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `fillomino` | Fillomino | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `futoshiki` | Futoshiki | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `galaxies` | Galaxies | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `gokigen_naname` | Gokigen Naname | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `heyawake` | Heyawake | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `hitori` | Hitori | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `inertia` | Inertia | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `kakurasu_sums` | Kakurasu Sums | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `kakuro` | Kakuro | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `kurodoko` | Kurodoko | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `lighthouses` | Lighthouses | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `lights_out` | Lights Out | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `lock_pattern` | Lock Pattern | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `logical_syllogisms` | Logical Syllogisms | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `magnets` | Magnets | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `map` | Four Colours | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `masyu` | Masyu Loop | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `mathrax` | Mathrax | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `matrix_reasoning` | Matrix Reasoning | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `minesweeper` | Minesweeper | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `netslide` | Netslide | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `nonogram` | Nonogram | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `norinori` | Norinori | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `nurikabe` | Nurikabe | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `path_finder` | Path Finder | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `pegs` | Pegs | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `pipes` | Pipes | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `rome` | Rome | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `salad` | Salad | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `same_game` | Same Game | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `seismic` | Ripple Effect | library | pass | pass | audit-clean | pass | pass | pass | pass |
| `shikaku` | Shikaku | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `signpost` | Signpost | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `skyscrapers` | Skyscrapers | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `slitherlink` | Slitherlink | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `sudoku` | Sudoku | deck | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `symbol_logic` | Symbol Logic | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `tangle_fix` | Tangle Fix | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `tapa` | Tapa | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `tenner_grid` | Tenner Grid | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `tents_and_trees` | Tents & Trees | deck | pass | pass | audit-clean | pass | pass | pass | pass |
| `tower_of_london` | Tower of London | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `triplets_logic` | Triplets Trio | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `twiddle` | Twiddle | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `water_sort` | Water Sort | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `wisconsin_card_sorting` | Rule Finder | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `yajilin` | Yajilin | deck | unproven | pass | audit-clean | pass | pass | pass | pass |

## What needs a fix job

PUZZLE-BAR.md's working procedure keeps fixes out of the triage PR: each of these is
its own change with its own test. Grouped by the job that fixes it, because the fix is
usually one mechanism and not N edits.

- **`uniqueness` — the generator must prove its deal (check 2)** — 33: `binary_puzzle`, `block_escape`, `color_flood`, `cube`, `dominosa`, `fillomino`, `gokigen_naname`, `heyawake`, `hitori`, `inertia`, `kakurasu_sums`, `kakuro`, `lock_pattern`, `logical_syllogisms`, `map`, `masyu`, `matrix_reasoning`, `netslide`, `path_finder`, `pegs`, `pipes`, `same_game`, `shikaku`, `symbol_logic`, `tangle_fix`, `tapa`, `tenner_grid`, `tower_of_london`, `triplets_logic`, `twiddle`, `water_sort`, `wisconsin_card_sorting`, `yajilin`

**The `uniqueness` job, in two passes.** A test that shows a generated deal has a
solution does not show it is the only one, but it does mean the deal is not unwinnable:

- winnable, not unique (27): `binary_puzzle`, `block_escape`, `color_flood`, `cube`, `dominosa`, `fillomino`, `gokigen_naname`, `heyawake`, `hitori`, `inertia`, `kakurasu_sums`, `kakuro`, `map`, `masyu`, `netslide`, `pegs`, `pipes`, `same_game`, `shikaku`, `tangle_fix`, `tapa`, `tenner_grid`, `tower_of_london`, `triplets_logic`, `twiddle`, `water_sort`, `yajilin`

- neither proven (6): `lock_pattern`, `logical_syllogisms`, `matrix_reasoning`, `path_finder`, `symbol_logic`, `wisconsin_card_sorting`

Every game here has a how-to-play guide (`lib/data/game_guides.dart`). The card's
own goal line is still owed to `card-teaches` (check 3), for the room as a whole.

## What the play pass has to answer

62 games. Play five times at phone size, write the first thing that
confused you, then confirm or move the id in `docs/CATALOG.md` with one line of reason:

`abcd`, `akari`, `ascent`, `binary_puzzle`, `block_escape`, `boats`, `bricks`, `bridges`, `clusters`, `color_flood`, `crossing`, `crown`, `cube`, `dominosa`, `einstein_riddle`, `fillomino`, `futoshiki`, `galaxies`, `gokigen_naname`, `heyawake`, `hitori`, `inertia`, `kakurasu_sums`, `kakuro`, `kurodoko`, `lighthouses`, `lights_out`, `lock_pattern`, `logical_syllogisms`, `magnets`, `map`, `masyu`, `mathrax`, `matrix_reasoning`, `minesweeper`, `netslide`, `nonogram`, `norinori`, `nurikabe`, `path_finder`, `pegs`, `pipes`, `rome`, `salad`, `same_game`, `seismic`, `shikaku`, `signpost`, `skyscrapers`, `slitherlink`, `sudoku`, `symbol_logic`, `tangle_fix`, `tapa`, `tenner_grid`, `tents_and_trees`, `tower_of_london`, `triplets_logic`, `twiddle`, `water_sort`, `wisconsin_card_sorting`, `yajilin`
