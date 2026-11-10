# Puzzlestack roadmap

The goal is not "more games". It is **the best-built puzzle app on the stores**: every
puzzle has exactly one solution, every puzzle can be solved by logic alone, and every
board looks like it belongs in this app.

Four sources feed it. They are ranked by what they buy us, not by how easy they are.
Where each one lives, its licence, and its pinned commit are in [REFERENCE.md](REFERENCE.md).

---

## Inventory (verified 2026-11-10)

| Source | What it is | Size | What we take |
| --- | --- | --- | --- |
| **Puzzlestack** (this repo) | our fork, 161 games | 78,131 LOC game code | the base |
| **sidhant947/Puzzle** (upstream) | the app we forked from, **100 commits** ahead of our fork base `d4d5d09` | 205 games | 44 games we are missing |
| **invariant** | our own Godot 4 port of Simon Tatham's collection | 35 puzzles, 32,107 LOC GDScript | the map, and code we own |
| **Simon Tatham's collection** | the reference implementation, MIT, pinned at `616da16` | 42 games, 74 `.c` + the shared solver core | the correctness bar, and the code we port from |

### The invariant archive is Godot, not Flutter

`invariant_flutter/` inside that zip is an empty `flutter create` scaffold: 8 files,
1,097 LOC, one puzzle (`galaxies`). The real work is `INVARIANT/` in GDScript, with a
clean per-puzzle split that maps almost 1:1 onto our Dart layout:

```
<puzzle>_state.gd       ->  <puzzle>_engine.dart     (board model)
<puzzle>_generator.gd   ->  <puzzle>_engine.dart     (generation)
<puzzle>_validator.gd   ->  <puzzle>_engine.dart     (rules + win check)
<puzzle>_renderer.gd    ->  <puzzle>_screen.dart     (painting)
<puzzle>_controller.gd  ->  <puzzle>_provider.dart   (state machine)
<puzzle>_settings.gd    ->  settings sheet
```

GDScript is close enough to Dart that this is translation, not archaeology.

**What the zip actually contains** (audited file by file):

| Path | What it is | Size |
| --- | --- | --- |
| `INVARIANT/` | Godot 4 port, 35 puzzles | 32,107 LOC GDScript |
| `invariant_flutter/` | Flutter scaffold, **one** puzzle ported (`galaxies`) | 8 `.dart` files, 1,087 LOC |
| `Puzzle inspirations/puzzles-master/` | an **old copy** of Tatham's C source | 65 `.c`, 214 files |
| `Full context/` | porting methodology (`TASKS.md`), failure modes, per-puzzle requirements | ~18 KB |

The Flutter folder is a proof of concept, not a port: `main.dart`, one `galaxies`
puzzle split into `domain/` `logic/` `ui/`, and a theme. It is still worth reading, because
its Dart structure is the one we want.

It is our own project, so its code can be translated into this repo freely. The one caveat is
quality, not permission: only 3 of its 35 generators mention uniqueness at all (`singles`,
`unruly`, `untangle`), and its test suite covers the framework (undo/redo, seeded RNG), not
per-puzzle equivalence against the C. It gives structure and a fast read, not a proven
correctness bar.

So Phase 3 reads the Godot code first (it is the better map of how a puzzle decomposes) and
ports the generator from Tatham's C, which guarantees unique solutions. The bundled C copy in
the zip is from 2014; the pinned clone in `tatham-c/` is current and has 42 games, including
`hat` and `spectre`, which the public page does not list yet.

### Coverage math

| | Count |
| --- | --- |
| Games today | 161 |
| + upstream games we never received | +44 → 205 |
| + Tatham puzzles invariant has that we lack | +21 → 226 |
| + Tatham puzzles invariant never ported | +4 → 230 |

Tatham's **42**, accounted for: 17 we already cover (14 rebuilt in Phase 4, plus
`Minesweeper` = Mines, `Nonogram` = Pattern, `Sudoku` = Solo), 21 ported in Phase 3, 4
hand-ported in Phase 5 (`Mosaic`, `Palisade`, `Hat`, `Spectre`).

---

## Phase 0 — Land the rename

**PR #1.** Mindstack → Puzzlestack, bundle ids, store title, NOTICE history.

Done when merged. Nothing else starts before this, because every later branch would
otherwise need rebasing across 87 files.

---

## Phase 1 — Build the house feel (the interaction layer)

**This phase exists because of a measurement.** Today 19 of 161 games paint their board with
`CustomPainter` and 142 use widget grids; **zero** have a drag interaction; 7 have any
animation. Colour and haptics are shared, feel is not. Porting 67 more puzzles first would
bake that inconsistency in 67 more times.

So before any port: one **board contract** (`PuzzleBoard`: state, `movesFor`, `apply`,
`isSolved`, `paint`), one **drag engine** built on the Declarative Dragging model
(Horowitz, Blinn & Heer, UIST 2026 — <https://declarative-dragging.github.io/>), five motion
moves, five verbs. Full spec in [PUZZLE_STYLE.md](PUZZLE_STYLE.md).

The point of the D2 model here: a puzzle declares *which future states a drag can reach* and
the engine synthesizes float, drop zones, snapping and settle. Every puzzle gets the same
tactile feel without writing gesture code, and a port becomes generator + rules + paint.

**Prove it on three puzzles that cover the three shapes of interaction:**

| Puzzle | Interaction it proves |
| --- | --- |
| Sudoku | tap a cell, pick a digit |
| Slitherlink | drag a line between edges |
| Water Sort | drag a column onto another |

**Done when:** those three run on the contract with no `GestureDetector` of their own, the
five motion moves and five verbs are the only ones in the codebase, and a tap-only player can
finish all three.

---

## Phase 2 — Pull the 44 upstream games

We forked on 2026-06-07, when upstream was at `d4d5d09` with **161 games** — the exact count
we still have, which confirms the fork base. Since then: **100 commits**, 44 new games
(mostly word and language: Affix Factory, Anagram Definition, Etymology Origin, Homophone
Hunt, Spoonerism Solver, and so on), per-game guide text, a `_metadata.dart` per game, and
fixes we never got.

**Work:** merge upstream into a branch from `d4d5d09`, keep our Shuffle feed and discovery
home on top, resolve the registry difference (`game_data.dart` vs their `game_registry.dart`),
and take the guides. Bounding the merge to a known base is what keeps it reviewable instead
of a 100-commit avalanche.

**Watch out:** their games ship `_metadata.dart` and guide entries we do not have. Take the
whole pattern, not just the screens, or the registry will fight us later.

**Done when:** 205 games in the registry, `flutter analyze` clean, tests green, Shuffle feed
and discovery home still work, and every new game appears in the right category room.

---

## Phase 3 — Port the 21 Tatham puzzles we lack

Ported **from Tatham's C** (`~/Projects/puzzlestack-reference/tatham-c/`, MIT, pinned at
`616da16`), reading our own Godot port first as the map of where each algorithm lives, then
taking the generator from the C because it guarantees a unique solution. Restyled to the
house style:

`Black Box, Cube, Filling, Galaxies, Guess, Inertia, Map, Netslide, Pearl, Pegs, Range,
Rectangles, Same Game, Signpost, Sixteen, Slant, Tracks, Twiddle, Undead, Unruly, Untangle`

Take the **generator, validator and solver**. Do not take the renderer: ours is the house
style and theirs is Godot.

**Per puzzle, the bar is:**
1. Generator guarantees a unique solution, and the test proves it by counting solutions.
2. Solver can finish it with logic only (no guessing), or the puzzle is regenerated.
3. Three difficulty levels that actually differ in solving depth, not just board size.
4. Hint reveals one logical step, not the answer.
5. Board renders at 60fps on a mid-range Android, and taps are forgiving at phone size.
6. It passes the house-style gate in [PUZZLE_STYLE.md](PUZZLE_STYLE.md) §6.

**Done when:** 226 games, and each ported puzzle has a test that generates 200 boards and
asserts one solution each.

---

## Phase 4 — Rebuild the 14 classics we already have

These exist but were written without a uniqueness guarantee. They are the ones users can
tell are wrong: ambiguous Sudoku, Nonogram that accepts a second picture, Slitherlink with
two loops.

`Bridges, Dominosa, Slide Puzzle, Lights Out, Color Flood, KenKen, Akari, Slitherlink,
Magnets, Pipes, Hitori, Tents & Trees, Skyscrapers, Futoshiki`

Same bar as Phase 3. This phase adds no games and is the most valuable one in the document:
it is the difference between "161 puzzles" and "161 puzzles that are actually correct".

**Done when:** all 14 pass the 200-board uniqueness test, and the Sudoku engine no longer
strips clues to a count without checking.

---

## Phase 5 — The four invariant never ported

`Mosaic`, `Palisade`, `Hat`, `Spectre`, straight from Tatham's C. The first two are small.
`Hat` and `Spectre` are the aperiodic monotile tilings, they are newer than the public page,
and they are the kind of puzzle nobody else on the store has. They close the collection at
**42/42**.

---

## Phase 6 — Release

- Store title and copy: the number in "161 Brain Puzzles" changes every phase, so it is set
  once, at the end, from the real registry count.
- Regenerate screenshots only if the home or a hero game changed visually (the house-style
  pipeline draws headlines, not the app name, so the rename did not need it).
- Data safety form, privacy policy, Shorebird `app_id` re-registered for
  `com.medhub.puzzlestack` (see RELEASE.md).
- Android + iOS together, same version, same copy.

---

## Rules that keep us from losing ourselves

1. **One phase per branch, one PR per phase.** No phase starts before the previous one is
   merged and green.
2. **A game is not done until its uniqueness test passes.** No exceptions for "it looks
   fine".
3. **Never take a renderer from another project.** Generators and solvers are portable;
   visuals are ours.
4. **Keep our names, not Tatham's.** `Akari` and `Slitherlink` are what people search for;
   `Light Up` and `Loopy` are not.
5. **The registry is the source of truth.** If a game is not in `game_data.dart` with a
   category, it does not exist, no matter how good the screen is.
6. **No puzzle owns its gestures.** Input goes through the board contract, haptics through the
   five verbs, motion through the five moves. A puzzle that wires its own `GestureDetector`
   is a fork of the app inside the app.
7. **Read the Godot port, port from the C.** Our GDScript is the faster read and the better
   map; Tatham's C is the correctness bar. When they disagree, the C wins.
8. **Stop at the gate.** Each phase ends with a number we can check, not a feeling.
