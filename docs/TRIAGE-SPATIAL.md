# Triage: Spatial

Mechanical pass over every game in the room against [PUZZLE-BAR.md](PUZZLE-BAR.md), by
`tool/triage_room.py`. Regenerate with:

```bash
python3 tool/triage_room.py spatial
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
| Games | 22 | 9 | 1 |

**Origin tags** in this room, which is what the uniqueness column above turns on:

| Origin | Games |
| --- | --- |
| puzzle | 32 |

**Check 6 evidence.** `AUDIT_ONLY=<room ids> flutter test test/board/game_audit.dart`,
light and `AUDIT_DARK=1`:

- light: `AUDIT checked=32 overflow=0 threw=0`
- dark: `AUDIT checked=32 overflow=0 threw=0`

## Per game

| Game | Title | Tier | 2 fair | 5 fresh | 6 app | 7 tap | 8 ends | 9 name | 10 rule |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `block_count_3d` | 3D Block Count | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `block_stacking_physics` | Block Stacking | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `classic_maze` | Classic Maze | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `compass_maze` | Compass Maze | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `cross_section_slice` | Cross-Section Slice | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `cube_net_fold` | Cube Net Fold | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `gear_rotation` | Gear Rotation | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `hue_sort` | Hue Sort | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `interlock_puzzle` | Interlock Puzzle | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `klotski` | Klotski Escape | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `laser_link` | Laser Link | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `maze_nav_3d` | 3D Maze Nav | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `mental_mapping` | Mental Mapping | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `mental_rotation` | Mental Rotation | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `mirror_image` | Mirror Image | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `mirror_maze` | Mirror Maze | deck | pass-fair-not-unique | deal-space(96) | audit-clean | pass | pass | pass | pass |
| `mirror_tracing` | Mirror Tracing | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `negative_space_detection` | Negative Space | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `paper_folding` | Paper Folding | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `path_intersect` | Path Intersect | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `perspective_shift_view` | Perspective Shift | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `perspective_taking` | Perspective Taking | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `polyomino_tiling` | Polyomino | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `rotating_maze` | Rotating Maze | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `shadow_pivot` | Shadow Pivot | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `silhouette_match` | Silhouette Match | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `slide_puzzle` | Slide Puzzle | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `symmetry` | Symmetry | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `tangram` | Tangram Puzzle | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `topology` | Topology | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `trace_path` | Trace Path | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `vector_grid_alignment` | Vector Alignment | archive | unproven | pass | audit-clean | pass | pass | pass | fail |

**Measured deal spaces.** Check 5 reads "a generator" as fresh. These generators were
counted instead of assumed, by enumerating the whole space rather than sampling it:

- `mirror_maze`: 96 distinct boards, from 4x4, every start cell and direction x every layout of 0 to 3 mirrors, traced: 232 reachable, 136 of them winnable with fewer than two mirrors. One a day for 30 days is 30 deals, so freshness cannot hold as written.

## What needs a fix job

PUZZLE-BAR.md's working procedure keeps fixes out of the triage PR: each of these is
its own change with its own test. Grouped by the job that fixes it, because the fix is
usually one mechanism and not N edits.

- **`uniqueness` — the generator must prove its deal (check 2)** — 31: `block_count_3d`, `block_stacking_physics`, `classic_maze`, `compass_maze`, `cross_section_slice`, `cube_net_fold`, `gear_rotation`, `hue_sort`, `interlock_puzzle`, `klotski`, `laser_link`, `maze_nav_3d`, `mental_mapping`, `mental_rotation`, `mirror_image`, `mirror_tracing`, `negative_space_detection`, `paper_folding`, `path_intersect`, `perspective_shift_view`, `perspective_taking`, `polyomino_tiling`, `rotating_maze`, `shadow_pivot`, `silhouette_match`, `slide_puzzle`, `symmetry`, `tangram`, `topology`, `trace_path`, `vector_grid_alignment`
- **`feed-size` — too few distinct deals for check 5 (counted, not estimated)** — 1: `mirror_maze`
- **`rule-tests` — a test that fails if the content breaks the game (check 10)** — 1: `vector_grid_alignment`

**The `uniqueness` job, in two passes.** A test that shows a generated deal has a
solution does not show it is the only one, but it does mean the deal is not unwinnable:

- winnable, not unique (25): `block_count_3d`, `block_stacking_physics`, `classic_maze`, `compass_maze`, `cross_section_slice`, `cube_net_fold`, `gear_rotation`, `hue_sort`, `klotski`, `laser_link`, `maze_nav_3d`, `mental_rotation`, `mirror_image`, `negative_space_detection`, `paper_folding`, `path_intersect`, `perspective_shift_view`, `perspective_taking`, `polyomino_tiling`, `rotating_maze`, `silhouette_match`, `slide_puzzle`, `symmetry`, `tangram`, `topology`

- neither proven (6): `interlock_puzzle`, `mental_mapping`, `mirror_tracing`, `shadow_pivot`, `trace_path`, `vector_grid_alignment`

Every game here has a how-to-play guide (`lib/data/game_guides.dart`). The card's
own goal line is still owed to `card-teaches` (check 3), for the room as a whole.

## What the play pass has to answer

31 games. Play five times at phone size, write the first thing that
confused you, then confirm or move the id in `docs/CATALOG.md` with one line of reason:

`block_count_3d`, `block_stacking_physics`, `classic_maze`, `compass_maze`, `cross_section_slice`, `cube_net_fold`, `gear_rotation`, `hue_sort`, `interlock_puzzle`, `klotski`, `laser_link`, `maze_nav_3d`, `mental_mapping`, `mental_rotation`, `mirror_image`, `mirror_maze`, `mirror_tracing`, `negative_space_detection`, `paper_folding`, `path_intersect`, `perspective_shift_view`, `perspective_taking`, `polyomino_tiling`, `rotating_maze`, `shadow_pivot`, `silhouette_match`, `slide_puzzle`, `symmetry`, `tangram`, `topology`, `trace_path`
