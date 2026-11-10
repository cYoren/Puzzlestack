# Puzzlestack roadmap

The goal is not "more games". It is **the best-built puzzle app on the stores**: every
puzzle has exactly one solution, every puzzle can be solved by logic alone, and every
board looks like it belongs in this app.

Three sources feed it. They are ranked by what they buy us, not by how easy they are.

---

## Inventory (verified 2026-11-10)

| Source | What it is | Size | What we take |
| --- | --- | --- | --- |
| **Puzzlestack** (this repo) | our fork, 161 games | 78,131 LOC game code | the base |
| **sidhant947/Puzzle** (upstream) | the app we forked from, 121 commits ahead of our fork point | 205 games | 44 games we are missing |
| **invariant** (`Downloads/memes/invariant-main.zip`) | a Godot 4 port of Simon Tatham's collection | 35 puzzles, 32,107 LOC GDScript | generators, validators, solvers |
| **Simon Tatham's collection** | the reference implementation | 40 games, MIT, C | the correctness bar |

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

GDScript is close enough to Dart that this is translation, not archaeology. The value is
the algorithms: generators that guarantee a unique solution and solvers that prove it.

### Coverage math

| | Count |
| --- | --- |
| Games today | 161 |
| + upstream games we never received | +44 → 205 |
| + Tatham puzzles invariant has that we lack | +21 → 226 |
| + Tatham puzzles invariant lacks (Mosaic, Palisade) | +2 → 228 |

Tatham's 40, accounted for: 14 we already have (rebuilt in Phase 3), 21 ported in Phase 2,
2 hand-ported, 3 we already cover under our own names (`Minesweeper` = Mines,
`Nonogram` = Pattern, `Sudoku` = Solo).

---

## Phase 0 — Land the rename

**PR #1.** Mindstack → Puzzlestack, bundle ids, store title, NOTICE history.

Done when merged. Nothing else starts before this, because every later branch would
otherwise need rebasing across 87 files.

---

## Phase 1 — Pull the 44 upstream games

The upstream app kept growing after we forked: 121 commits, 44 new games (mostly word and
language: Affix Factory, Anagram Definition, Etymology Origin, Homophone Hunt, Spoonerism
Solver, and so on), per-game guide text, a `_metadata.dart` per game, and fixes we never
got.

**Work:** merge upstream into a branch, keep our Shuffle feed and discovery home on top,
resolve the registry difference (`game_data.dart` vs their `game_registry.dart`), and take
the guides.

**Watch out:** their games ship `_metadata.dart` and guide entries we do not have. Take the
whole pattern, not just the screens, or the registry will fight us later.

**Done when:** 205 games in the registry, `flutter analyze` clean, tests green, Shuffle feed
and discovery home still work, and every new game appears in the right category room.

---

## Phase 2 — Port the 21 Tatham puzzles we lack

From `INVARIANT/puzzles/`, translated to Dart, restyled to our design system:

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

**Done when:** 226 games, and each ported puzzle has a test that generates 200 boards and
asserts one solution each.

---

## Phase 3 — Rebuild the 14 classics we already have

These exist but were written without a uniqueness guarantee. They are the ones users can
tell are wrong: ambiguous Sudoku, Nonogram that accepts a second picture, Slitherlink with
two loops.

`Bridges, Dominosa, Slide Puzzle, Lights Out, Color Flood, KenKen, Akari, Slitherlink,
Magnets, Pipes, Hitori, Tents & Trees, Skyscrapers, Futoshiki`

Same bar as Phase 2. This phase adds no games and is the most valuable one in the document:
it is the difference between "161 puzzles" and "161 puzzles that are actually correct".

**Done when:** all 14 pass the 200-board uniqueness test, and the Sudoku engine no longer
strips clues to a count without checking.

---

## Phase 4 — The two invariant never ported

`Mosaic` and `Palisade`, straight from Tatham's C. Small, and they close the collection at
40/40.

---

## Phase 5 — Release

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
6. **Stop at the gate.** Each phase ends with a number we can check, not a feeling.
