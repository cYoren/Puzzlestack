# Puzzlestack roadmap

The goal is not "more games". It is **the best-built puzzle app on the stores**: every
puzzle has exactly one solution, every puzzle can be solved by logic alone, and every
board looks like it belongs in this app.

Four sources feed it. They are ranked by what they buy us, not by how easy they are.
Where each one lives, its licence, and its pinned commit are in [REFERENCE.md](REFERENCE.md).

---

## Open work

What is left, in the order it should be picked up. Everything here is a self-contained job
someone can take without reading the rest of this file.

| # | Job | Size | Where |
| --- | --- | --- | --- |
| 1 | ~~Port the Tatham puzzles we lack~~ **Done**: Signpost was the twelfth and last on the critical path (2026-11-11). The three still unported are marked optional, below. | — | [Phase 3](#phase-3--port-the-tatham-puzzles-we-lack) |
| 2 | ~~14 classics rebuilt for uniqueness~~ **Done**: six rebuilt, ten skipped by decision (2026-11-11). | — | [Phase 4](#phase-4--rebuild-the-14-classics-we-already-have) |
| 3 | **Four invariant never ported** (Mosaic, Palisade, Hat, Spectre). | small, then two large | [Phase 5](#phase-5--the-four-invariant-never-ported) |
| 4 | **Release.** Nothing blocks it: the licence is settled, the copy and the privacy page are done. The screenshots are the last pass, and they need a device. | one pass | [Phase 6](#phase-6--release) |
| — | **Optional: three Tatham puzzles** (Black Box, Undead, Tracks). Nice to have, not release blockers, and nothing else in the plan depends on them. | 1.6k–3.5k lines of C each | [Phase 3](#phase-3--port-the-tatham-puzzles-we-lack) |

Dropping the three optional ports does not shrink the shipping app: 313 games is what the
store copy is set from, and 316 was only ever what the full Tatham sweep would have reached.

The three optional ports, with what each one needs:

| Puzzle | Tatham file | Lines | Needs the solver? |
| --- | --- | --- | --- |
| Black Box | `blackbox.c` | 1587 | yes, deduction |
| Undead | `undead.c` | 3049 | yes, deduction |
| Tracks | `tracks.c` | 3159 | yes, deduction |

All three need `lib/core/deduction.dart`, and each has a design decision to make before the
code is worth writing:

- **Black Box** needs the off-centre ray geometry. With axis-aligned rays only, every ball is
  an absorber and the puzzle collapses to "the first ball in each row", so it needs
  half-cell entry points and deflection.
- **Undead** needs mirror ray-tracing before the counts mean anything.
- **Tracks** needs a railway solver before its clues mean anything.

Signpost was the fourth of that four and is done, so the worked examples to copy are now
Signpost itself, Galaxies and Kurodoko; Magnets and Tents & Trees are the two most recent.

Blocked on a human, not on an agent:

- **Codex review is out of credits.** PRs are self-reviewed and merged. See
  [papercuts.md](papercuts.md) for what that costs.

---

## Decided: this ships on the App Store too

Puzzlestack is **GPL-3.0**, because it is a derivative of `sidhant947/Puzzle`, which is
GPL-3.0. The FSF's position is that Apple's App Store terms conflict with the GPL: the store's
usage restrictions are further restrictions the licence does not permit. Google Play has no such
conflict.

**The upstream author was asked for permission and gave it.** Email sent 2026-11-10; reply
received and confirmed by Gus. Permission to distribute the derived work through the App Store
covers the one thing the licence alone could not, and keeps iOS in the release along with the
GPL history intact. The email is held by the authors, and the permission is recorded in
[NOTICE](NOTICE).

So iOS ships with Android, from the same version and the same copy. Nothing here is waiting on
anybody any more.

---

## Inventory (verified 2026-11-10)

| Source | What it is | Size | What we take |
| --- | --- | --- | --- |
| **Puzzlestack** (this repo) | our fork, 161 games at the fork point, **313** after Phases 2 and 3 | 78,131 LOC game code | the base |
| **sidhant947/Puzzle** (upstream) | the app we forked from, **100 commits** ahead of our fork base `d4d5d09` | **304 registered games** | all of them, merged in Phase 2 |
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
| Games at the fork point | 161 |
| + upstream games we never received | **+143 → 304** (Phase 2, landed) |
| + Tatham puzzles we actually lack (see Phase 3) | **+12** → 316 |
| + Tatham puzzles invariant never ported | +4 → 320 |

The 44 in the first draft of this table came from upstream's `game_data.dart`, which lists 205
games. That file is legacy: the registry they actually ship from (`game_registry.dart`, one
`_metadata.dart` per game) has **304**. Phase 2 merged the registry, so the real number is 304
and the porting phases add to that.

Tatham's **42**, accounted for: 25 we already cover (14 rebuilt in Phase 4, plus
`Minesweeper` = Mines, `Nonogram` = Pattern, `Sudoku` = Solo, and the eight the Phase 2 merge
brought in under other names), 13 ported in Phase 3, 4 hand-ported in Phase 5 (`Mosaic`,
`Palisade`, `Hat`, `Spectre`).

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

**Landed.** `lib/ui/core/board/` (contract, engine, motion, verbs) plus `sudoku_board.dart`,
`slitherlink_board.dart` and `water_sort_board.dart`. The three screens lost 780 lines between
them and gained 196: the boards own rules, geometry and paint, the engine owns touch. `flutter
analyze` is clean and 38 tests cover the contract, the drag engine and each board's rules.

One deliberate call: the Sudoku digit pad is **part of the board**, not chrome beside it, so
picking a digit is a board tap and carrying a digit onto a cell is a declared move. That is
what keeps the puzzle free of gestures rather than merely almost free.

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

**Landed, at 304 games rather than 205.** See the coverage math above: `game_data.dart` was
the stale list. What the merge actually took:

- the 100 upstream commits, with real ancestry: our repository had a fresh history, so a
  graft commit put our tree on top of the fork point `d4d5d09` and the merge became a
  three-way one instead of 100 commits of conflicts;
- **one registry.** `game_registry.dart` (304 `_metadata.dart` files, localized titles,
  popularity) replaces our `game_catalog.dart` and upstream's legacy `game_data.dart`. Both
  are deleted, along with the five home widgets only the old upstream home used;
- **the guides**: 305 entries in `game_guides.dart`, now reachable from the info button on
  every game screen instead of only from a tile we no longer render;
- our branding survived the merge: bundle ids, store links, brand colours, the discovery home
  and the Shuffle feed. Upstream's `app_de.arb` was invalid JSON on their main; fixed here.

Two things the merge forced, both worth knowing:

1. Upstream had deleted the unused `final l10n = …` locals in nine screens and then started
   using them again. Our tree had deleted the same lines for the analyzer. Taking their
   version of those nine files was the whole fix.
2. `analysis_options.yaml` merged into a file with two `analyzer:` keys, which made
   `dart format` (and therefore `flutter gen-l10n`) fail. One block now.

---

## Phase 3 — Port the Tatham puzzles we lack

Ported **from Tatham's C** (`~/Projects/puzzlestack-reference/tatham-c/`, MIT, pinned at
`616da16`), reading our own Godot port first as the map of where each algorithm lives, then
taking the generator from the C because it guarantees a unique solution. Restyled to the
house style.

Take the **generator, validator and solver**. Do not take the renderer: ours is the house
style and theirs is Godot.

**Start here: [Open work](#open-work) names the nine puzzles left, with file sizes and
whether each one needs the solver.**

**Per puzzle, the bar is:**
1. Generator guarantees a unique solution, and the test proves it by counting solutions.
2. Solver can finish it with logic only (no guessing), or the puzzle is regenerated.
3. Three difficulty levels that actually differ in solving depth, not just board size.
4. Hint reveals one logical step, not the answer.
5. Board renders at 60fps on a mid-range Android, and taps are forgiving at phone size.
6. It passes the house-style gate in [PUZZLE_STYLE.md](PUZZLE_STYLE.md) §6.

### The list was 21 before the merge; it is 12 now

Eight of those twenty-one arrived with Phase 2 under other names. Checked one by one against
the registry rather than guessed from the name:

| Tatham | We already have it as |
| --- | --- |
| Filling | `fillomino` |
| Pearl | `masyu` (Masyu *is* Pearl) |
| Rectangles | `shikaku` |
| Slant | `gokigen_naname` |
| Sixteen | `slide_puzzle` (rebuilt for uniqueness in Phase 4) |
| Unruly | `binary_puzzle` (Takuzu) |
| Untangle | `tangle_fix` |
| Guess | `word_mastermind` (same Mastermind deduction, word content) |

**Left to port: 3, all optional.** Kurodoko is Tatham's Range and arrived with the merge too,
so the 13 became 12, and nine of those are done — Signpost was the last one on the release
path. The three that remain (Black Box, Undead, Tracks) are optional: nothing in Phase 6 needs
them. Two names were checked rather than assumed: `cube_net_fold` is a cube-net puzzle but not
`cube.c`, and `mental_mapping` is a follow-the-arrows memory game, nothing to do with `map.c`.

### Landed so far: 9 of 12, plus one rebuilt

`lib/ui/core/board/grid_board.dart` — the arithmetic every cell puzzle would otherwise
repeat: normalised cell rectangles, `cellAt(point)`, cell refs, and a `paintCell` hook so a
grid puzzle only writes rules and paint.

`lib/core/deduction.dart` — **the uniqueness harness.** This is the piece the rest of Phase 3
depends on, and it exists because "solvable by construction" does not apply to a deduction
puzzle: whether a set of clues pins down exactly one answer is a property of the clues, not of
how they were made, so it has to be counted. The harness is small:

```text
DeductionModel   copy()  isComplete  choice  assume(slot, value)
DeductionRule    level (1 = easiest)  apply(model) -> settled | -1 for contradiction
countSolutions   reason first, guess only where reasoning stops, stop at 2
solvingLevel     the lowest rule level whose rules alone finish the board
rate             one answer? which level?  -> impossible | ambiguous | unfinished | solved
```

Two properties make it worth having rather than each puzzle writing its own:

1. **The rule levels *are* the difficulty scale.** A board is "hard" because the easy rules
   cannot finish it, not because it is bigger. That is roadmap bar 3, made measurable.
2. **`countSolutions` refuses to guess.** When the search runs out of budget it returns
   `truncated`, and `rate` throws rather than report a verdict it did not earn. A test that
   counts solutions must fail loudly, never pass quietly.

| Puzzle | Interaction it proves | Correctness |
| --- | --- | --- |
| **Pegs** | drag a peg onto the square it lands on | reverse play from one peg, so solvable by construction; the test replays the recorded line over 200 boards |
| **Twiddle** | drag a tile onto the square the turn would move it to | scrambled from solved, so the solution is the scramble backwards |
| **Galaxies** | drag a dot onto a cell; the cell it reflects onto joins too | **counted**: 200 easy + 200 medium boards, each proven to have exactly one solution, and the solver's count checked against a brute force that ignores the rules |
| **Kurodoko** (rebuilt, not added) | tap a cell to blacken it, again to mark it white | **counted**: 600 boards across three tiers, each proven unique; the rules are also proved sound cell by cell against the answer |
| **Same Game** | tap a group of two or more | **constructed**: Tatham's reverse generator, ported whole, with every insertion checked to be a legal inverse move; 600 boards across three tiers, all fully covered and all with a legal move |

### Landed: Netslide, where the fallback was the bug

A net of pipes on a grid. Slide a whole row or column one square, the tiles shuttle round, and
the pipes never rotate — position is the only thing you can change. A wall across a line stops
it sliding, which is what turns the grid into a set of shuttles instead of one big puzzle.
Tatham's `netslide.c`, a cross between Net and Sixteen courtesy of Richard Boulton.

**Generation is by construction.** A solved board is built first — a loop through every cell,
with walls on the edges the loop does not use — and then scrambled by legal slides. A slide is a
cyclic shift, so it is exactly invertible, and the puzzle carries the scramble it used. The test
undoes that scramble and lands back on the solved board: the proof that a player can finish is a
replay, not a hope.

The bug was in the safety net. The solved loop wants a Hamiltonian cycle, which exists only when
the cell count is even (the grid is bipartite, so every cycle is even); every tier is even, and
a random walk finds a cycle in milliseconds. The fallback for when it does not was a
**serpentine sweep**, and a serpentine does not close: its two ends are diagonally opposite, so
the cell at the join came out with one pipe instead of two. The generator's own test caught it
on 5x6. The fallback is now **ladders** — two adjacent columns form a loop, down one and up the
other — which cannot fail and covers every cell exactly twice.

### Landed: Inertia, where the ball cannot stop halfway

A ball on a grid of walls, gems and mines. Pick a direction and it slides until a wall stops
it — it cannot stop halfway. Collect every gem without touching a mine. Tatham's
`inertia.c`, rules and generator idea by Ben Olmstead.

Turn-based and four-directional, where Tatham's animates and uses eight. The physics is the
same puzzle; removing the diagonals costs nothing but ambiguity about which square a swipe is
aiming at. Mines are a loss rather than a stop, so the run has a real failure state and a
retry that restores the gems.

The bug worth keeping is about where a gem may sit. A ball never stops in the open middle of a
room — it stops against a wall — so a gem placed there is **unreachable and the board is
dead**. The first generator scattered gems over every floor cell and could not build a single
5x5 board in three thousand tries. It now asks the slide graph for the cells where a slide can
actually end, and draws gems from those; the hit rate goes from 0% to about 90% on the same
terrain, and generation takes 30ms for twenty boards.

### Landed: Map, where the answer is not unique and should not be

Five-colouring's little brother: a board cut into regions, four colours, no two touching regions
may match. Tatham's `map.c`, minus the clues and the difficulty machinery around its solver.

**This is the one puzzle here that is supposed to have many answers.** Any valid colouring wins,
so there is nothing to count and no solver in the engine: the test proves the stored answer is
legal, and a second test proves a *different* legal colouring (the stored one rotated by one)
also wins. That is the opposite of every other puzzle in Phase 3, and it is the point — colouring
a map should feel like colouring a map.

Regions are grown as multi-source breadth-first blobs from random seeds, which is what gives a
map its blobby shapes instead of Voronoi slivers. The generator rejects maps with an isolated
region (a free colour, and a boring cell) or a disconnected adjacency graph (two easy puzzles on
one board), then four-colours by backtracking with the most-constrained region first. It also
insists the answer uses all four colours, or the palette would be lying.

Cheap to build and cheap to run: 20 boards per tier generate in under 50ms total.

### Landed: Cube, where the solver and the rules disagreed

The fourth Tatham port, and the first with no deduction in it: you roll a cube over a grid,
and landing on a square **swaps** the cube's bottom face with that square's colour. Collect
the six blue squares; the board is done when all six faces are blue.

That last sentence is an invariant rather than a rule. A swap moves a colour between a face
and a square and never creates or destroys one, and the board starts with six blues, so
"all six faces blue" and "no blue squares left" are the same statement.

Tatham places six blue squares anywhere and trusts that a cube can always collect them. This
generator does not trust: a board ships only when a breadth-first walk finds a line that
clears it, and the shortest such line **is** the difficulty. 4x4 boards that clear in 7–9
moves, 5x5 in 10–13, and 5x5 boards that need 14 or more.

Two mistakes worth recording:

1. **The roll was written twice and the two copies drifted.** One on lists, for the game; one
   on packed ints, for the solver. Five of fifteen replayed boards ended a move short, which
   reads as "this board cannot be solved" and is really "two rolls disagree". The fix was to
   delete one: the game now decodes the solver's packed move, so there is exactly one
   definition of rolling in the codebase.
2. **Packing the state was not a micro-optimisation.** The first solver hashed a `CubePosition`
   with its whole 25-element grid per state and took twenty seconds a board. The same search
   over one int takes under a millisecond. When you write a state as "the position *and* every
   square", say so in the type and hash accordingly — or pack it.

### Landed: Signpost, where the numbers are not the board

Every cell carries an arrow, and the arrow points *along a ray* rather than at a neighbour:
the cell holding `k` must point at the cell holding `k+1`, wherever that is on the line. Every
number from 1 to N is used once, and a few are given. Tatham's `signpost.c` (Janko's "arrow
path"), the twelfth and last Phase 3 port on the release path.

**The player's board is the links, not the numbers.** `links[cell]` is the cell that follows
it, and the numbers are read off the chains. Three things fall out of that, and they are the
whole design:

1. A link can be rewired without rewriting anything. Nothing the player worked out is thrown
   away by extending a chain or splitting one.
2. A chain that has not met a given number yet shows **no numbers at all**. It has none: it
   could sit anywhere in the sequence, and printing a guess would be the app lying to the
   player in the one place where the deduction matters.
3. Uniqueness is a property of the arrows and the given numbers, so it is counted like every
   other deduction puzzle here — over the links, which is a Hamiltonian path count.

Tatham's board numbers those floating chains too, in colours, to keep them out of each other's
way. That is a packing convention, not a fact, and it is what a port should drop first: it
makes the board look solved where it is only provisionally numbered. Blank is the same
information without the claim.

**Generation is Tatham's, whole.** Grow a full path from the head and the tail at once, taking
any unclaimed cell along a ray; keep `1` and `N`, add given numbers at random until the rules
can finish the board, then take them back out again while they still can. The given count *is*
the difficulty, exactly as Tatham's own presets have it, and the removal loop is what turns the
count into three tiers.

**Three strengths, because one forced link is not a difficulty scale.** The generator's rule
(the forced link, Tatham's whole solver) is the easy tier. The second strength assumes a link
and lets the forced rule work over it: a dead end two steps away, which no single-move rule can
see. The third does the same with both cheaper strengths underneath, and is what finishes the
boards where nothing is locally forced. That is the harness's level 1 / 2 / 3, asserted per
board: easy 4x4, medium 5x5 pinned to the corners, hard 5x5 with free ends.

Two measurements changed the plan rather than the code:

- **The hard tier cannot be 6x6.** A 6x6 board that genuinely needs the lookahead took about
  twenty seconds to find, because every candidate link runs a propagation before it can be
  doubted. Restricting the refutation to cells with exactly two candidates — the only ones a
  single refutation can turn into a link — brought a 5x5 hard board down to a few hundred
  milliseconds, which is the difference between a tier and a hang.
- **The tier test counts 25 hard boards, not 200.** Everything else is at the bar; a hard board
  costs a fraction of a second to build and the uniqueness proof is the same one, so 25 is the
  honest sample rather than a slower test that proves the same thing.

The last run: the 200 easy and 200 medium boards are generated and counted in under two
seconds together, and the 25 hard ones add a few seconds. Worth re-measuring before it is quoted
anywhere else.

### What Galaxies cost, and what it taught

Galaxies is the first puzzle here whose correctness is a *count*, and it took four wrong
generators to get one that works. The lessons are worth more than the puzzle:

1. **A dot pinned in place cannot tile a board.** The first generator fixed each dot and grew
   its region in mirror pairs. It never finished: a handful of cells always ended up with
   their reflections spoken for. The fix is Tatham's — the dot moves to wherever the region's
   centre of symmetry now is, so a region can grow into a shape its original dot could not
   have owned.
2. **Symmetry at every step is too strong an invariant.** Even with a moving dot, insisting
   the region is symmetric *right now* jams the growth. The working invariant is weaker:
   every cell's reflection must be **ours or still free**. A region is allowed to be lopsided
   while it grows. Once the board is full there are no free cells, so the invariant becomes
   symmetry on its own — and the generator checks that at the end rather than assuming it.
3. **"No options" is not a dead end.** The same mistake as the Pegs stranded-peg prune, in a
   different costume: a cell no region can take *yet* may become takeable once a neighbour's
   centre shifts. Only a board where nothing anywhere can move is stuck.
4. **Dots belong on edges and vertices too.** Restricting dots to cell centres was the first
   simplification, and it is what made tiling impossible. A dot on an edge owns an even number
   of cells; a dot on a vertex owns four around it. All three are real Galaxies dots.
5. **The third depth tier is real but rare.** Measured over hundreds of boards: the mirror
   rule alone finishes most 6×6 boards, connectivity is needed at 8×8, and the look-ahead rule
   is needed at 9×9 with 14 dots — roughly one board in ten proposals. That is why the three
   difficulties are 6×6/6 dots, 8×8/12 dots and 9×9/14 dots: those are the sizes and
   densities that actually produce each level, not sizes chosen for looks.

### Kurodoko was already here, and the list was wrong again

The plan said "port Range". Range is Tatham's name for Nikoli's **Kurodoko**, also sold as
Kuromasu, and it arrived with the Phase 2 merge as `kurodoko`. So the count was wrong twice
over: 21 became 13, and 13 is really **12**.

Two more names needed checking rather than assuming. `cube_net_fold` is a cube-net puzzle but
not Tatham's `cube.c` (fold 27 cubes into a 3x3x3), and `mental_mapping` is a follow-the-arrows
memory game, nothing to do with `map.c` (four-colouring). Both stay on the missing list.

**What was here was not worth keeping.** The shipped engine gave every board `size * 1.5` clues
on a `size²` grid and never checked whether the answer was unique — so it could, and did, ship
ambiguous boards — with no solver, no difficulty and one fixed size. It is now rebuilt on the
harness, which makes this a replacement rather than a new game: the game count does not move.

That rebuild is where the interesting bugs were, and all four were mine rather than Tatham's:

1. **Four runs per direction, not three.** A clue's reach needs white, then undecided, then
   *already-white beyond*, and then a fourth run of "anything not black" past that. Dropping the
   fourth made the room a clue has too small, so the rule forced cells that were not forced.
2. **"Beyond" has to mean already white.** The "this direction would overshoot" test only holds
   if the cells past the gap are white already: then filling the gap would carry the run into
   them. If they were merely undecided, the cut could happen out there instead and blaming the
   gap is wrong. Using "not black" there produced boards the solver called impossible.
3. **A rule must report news, not success.** `settle` returned true when a cell already had the
   colour asked for, so the fixed-point loop never terminated. It now returns 1 for news, 0 for
   "already knew", -1 for contradiction.
4. **A split not-black graph is not a contradiction.** I added a check that Tatham does not
   have, reasoning that cells only leave the not-black set. True, and irrelevant: the *white*
   cells are free to be one piece with the rest going black. Removing it fixed 80 refusals.

The lesson from all four is the same one the Galaxies generator taught, in a new costume: when
a port disagrees with the C, the C is usually right, and "this looks redundant" is a reason to
work out *why* it is there before deleting it.

### The bar, as it stands

| | |
| --- | --- |
| 200 boards, one solution each | Pegs, Twiddle (replayed), Galaxies easy + medium, Kurodoko all three tiers (counted) |
| hard tier | 50 boards, not 200: a hard Galaxies takes ~0.5 s to find because the generator throws away boards that come back easier than asked for. 200 would add two minutes to every test run. |
| logic-only solver | Galaxies and Kurodoko ship only boards the rules can finish; a board that needs a guess is discarded |
| rules proved sound | Kurodoko: 936 one-cell assumptions, no rule ever contradicts a valid board or settles a wrong cell |
| three difficulties by depth | rule level 1 / 2 / 3, asserted per board |
| hint reveals one step | one cell the rules can prove, from the solver, not from the stored answer |

**Done when:** 313 games with the three optional ports left out (316 with them), and each
ported puzzle has a test that generates 200 boards and
asserts one solution each. Same Game is the exception to the wording, not the bar: its board is
built by legal inverse moves, so the test asserts the construction held and the board is full.

---

## Phase 4 — Rebuild the 14 classics we already have

These exist but were written without a uniqueness guarantee. They are the ones users can
tell are wrong: ambiguous Sudoku, Nonogram that accepts a second picture, Slitherlink with
two loops.

**Scope narrowed (Gus, 2026-11-11): skip the very famous ones.** Sudoku, Nonogram, Slitherlink,
Akari, KenKen, Bridges, Slide Puzzle, Color Flood, Pipes and Hitori stay as they are. They are
the puzzles every other app already has, so rebuilding them is the most work for the least
differentiation — and a player who knows Sudoku is the player most likely to notice a wrong
board, which makes them the worst place to spend a week.

What is left to rebuild, all of it obscure enough that a correct board is a differentiator:

**Phase 4 is closed.** Six rebuilt — Lights Out, Skyscrapers, Futoshiki, Dominosa, Magnets and
Tents & Trees — and the ten famous ones skipped by the decision above. Nothing is left in this
phase.

### Landed: Skyscrapers, and a Latin base four puzzles can share

The old generator built a cyclic Latin square, shuffled its rows and columns, and published
**every clue** — sixteen on a 4x4 — without ever checking that the clues pin down one answer.
Two Latin squares can show the same skyline from all four sides, so that board could ship
ambiguous.

The rebuild starts from a full clue set, then **removes clues one at a time**, keeping a removal
only while the board stays unique *and* the rules can still finish it. That is the Phase 3 bar
applied to a classic that never had it, and it turns the clue count into the difficulty: 4x4
down to 8 clues, 5x5 to 10, 6x6 to 12.

The rules are not hand-written visibility tricks. `lib/core/latin.dart` holds the Latin-square
model, elimination, hidden singles, and a **line filter** that enumerates the line's legal
arrangements (at most 720 for n=6) and keeps only the values that appear in one. A puzzle
supplies one predicate per line — Skyscrapers checks the two skyline clues, Futoshiki will check
its inequalities — and the filter does the rest. It is deduction, not search: nothing is
assumed, the line is filtered against a constraint the puzzle already stated.

That base is why Futoshiki, and later KenKen or Sudoku if the scope ever reopens, cost a
predicate rather than a solver.

### Landed: Futoshiki, which is Skyscrapers with a different predicate

The old generator sprinkled inequalities at a fixed 30% chance and then added givens until a
brute-force count said "one solution". That is a uniqueness check but not a *reasoning* check —
a board can be unique and still need a guess — and the givens were never minimised.

The rebuild starts from **every** inequality and removes them one at a time, keeping a removal
only while the board stays unique and the line filter can still finish it. Most boards end up
with no givens at all: the inequalities alone pin the square down, which is what a good
Futoshiki looks like. Easy keeps 60% of the edges, medium 45%, hard removes everything it can.

It cost one predicate and one board file, because `lib/core/latin.dart` already had the rest.
That is the payoff the base was built for.

### Landed: Dominosa, where the order of the search was the bug

The old generator laid a **fixed** tiling over the grid — the same ten placements on every
board — and filled it with shuffled dominoes. Nothing checked that the numbers pinned that
tiling down, so a board could have two coverings and accept the wrong one.

The rebuild tiles at random and **counts** the coverings, shipping only a board with exactly
one. The interesting part was the first version, which searched for the tiling and the domino
values at the same time. It worked on 4x5 but could not find a unique 5x6 or 6x7 board in 200
attempts. Splitting the problem — random matching first, then a random bijection from the
placements to the domino set — took the same sizes to 20/20 in under 100ms. The search was
biasing itself towards a handful of shapes, and those shapes were the ambiguous ones.

### Landed: Magnets, which needed a solver, not a counter

Magnets had a uniqueness check already, so the obvious repair was to keep it and add
difficulty. That would have been wrong for a reason worth writing down.

The first version of this rebuild measured "how much deduction does this board need" by
asking, for each domino, whether exactly one of its three states still admits a completion.
Every domino came back forced, on every board, at every size — which looked like a great
result and was actually a tautology. In a board with one answer, *every* domino has exactly
one state consistent with that answer. The measure was reading the answer, not the rules.

So the rebuild ports Tatham's solver instead (`solve_state` and the functions it calls) onto
`lib/core/deduction.dart`: cells carry a mask of `blank`/`+`/`-`, and five rules narrow it —
row and column counts, the odd-length run, polarised dominoes filling a line, the last blank,
and empty dominoes needing poles. The rule level a board needs is now the difficulty, and it
is measured, not asserted.

Three things came out of the port:

1. **Propagation belongs in the model, not in a rule.** Tatham's `solve_set` updates the
   domino's other half the moment a cell is decided. Written as a separate rule that runs
   later in the round, a line rule could act on a half-decided domino and conclude the
   opposite of the truth. The test that caught it compares the harness's solution count with
   the engine's independent, rule-free counter — two implementations disagreeing is the only
   cheap way to find an unsound rule.
2. **"Empty dominoes need poles" counts slots, not dominoes.** A domino lying along the line
   takes one slot; a domino crossing it leaves one cell, which is also one slot. Counting only
   in-line dominoes made the rule fire when a crossing cell could still have taken the pole,
   and it removed the truth on 257 of 40 boards.
3. **The old screen never drew the dominoes.** The player tapped a cell and toggled a pair
   they could not see. The board now outlines every domino, which is the puzzle's actual
   shape, and taps cycle the whole domino.

Difficulty is 4x4, 5x6 and 6x6, gated on the rule level each tier must reach (1, 2 and 3).
Level-3 boards are about one in two hundred random boards, so a hard board takes ~260ms to
find — in line with a hard Galaxies, and the worst case is bounded by the attempt limit.

### Landed: Tents & Trees, which closes the phase

The old engine placed trees and tents and never asked whether the numbers pinned the tents
down, so a board could accept a second arrangement. The rebuild builds a legal arrangement,
reads the numbers off it, and hands the clues to the harness.

Two things are worth keeping. The first is a bug that would have shipped: every rule filtered
"cells that could still be a tent" by the tent bit alone, which **includes cells already
settled as tents**. A rule that then marked the rest of the line as grass tried to turn a tent
into grass and reported a contradiction — on every board, immediately. The filter has to be
"undecided and could be a tent".

The second is the difficulty scale. The three tiers are gated on the rule level a board
*needs*, exactly: 5x5 boards the basic rules finish, 6x6 boards that need the counts, and 7x7
boards that need the line filter. That last rule enumerates every arrangement a row's
remaining tents can take — at most 35 for a row of seven — and keeps the cells that agree
across all of them. It is the same idea as the Latin line filter, and it is what makes a 7x7
board decidable without guessing: about one board in seventy-five needs it, which is why a
hard board takes ~90ms to find.

### Landed: Lights Out, where uniqueness is linear algebra

The old game was 5x5. On 5x5 the toggle matrix has rank 23 of 25, so **every solvable board has
four solutions** and "solved" was whichever one the player stumbled into. On 4x4 it is worse:
sixteen.

The rebuild picks sizes where the matrix is invertible — 3x3 (rank 9/9), 6x6 (36/36) and 8x8
(64/64) — and builds the board forwards from a chosen press set, so the presses that made it are
the only presses that clear it. The test counts solutions by Gaussian elimination over GF(2)
rather than trusting the construction: 200 boards per tier, each exactly one. The engine also
asserts the two sizes that are *not* invertible (4x4 → 16, 5x5 → 4), so the table in its
comment cannot rot.

Difficulty is size and press count together: 3x3 needing 2–4 presses, 6x6 needing 8–12, 8x8
needing 14–20. The hint is exact and free: the presses still to make are `solution XOR pressed`,
so it reveals one press, not the answer.

Same bar as Phase 3. This phase adds no games and is the most valuable one in the document:
it is the difference between "307 puzzles" and "307 puzzles that are actually correct".

### Landed: every game fits a phone

Measured, not guessed, with `test/board/game_audit.dart`, five runs in a row:

```
flutter test -j 4 test/board/game_audit.dart
AUDIT checked=308 overflow=0 threw=0
```

The first run of this tool said **119** broken: 85 overflow and 34 throw. The 34 were an
artifact. The test binding keeps the *first* exception of a test and counts the rest, so one
game that overflowed made every later game report "Multiple exceptions (N) were detected" and
land in the `threw` list. A test per game, capturing `FlutterErrorDetails` instead of
`takeException`, showed the truth: no game throws at 320dp, and 117 overflowed.

Getting from 117 to 0 was four shapes, in this order:

1. **The stat strip.** About fifty screens drew score/timer/trial as a
   `Row(mainAxisAlignment: spaceBetween)` of chips. A `Row` gives every chip its intrinsic
   width and then overflows; `lib/widgets/game_hud.dart` is that strip as a `Wrap`. 66 screens
   converted, 33 fixed outright.
2. **Chip content wider than its `Expanded`.** A `FittedBox(fit: scaleDown)` around the chip's
   content, so the label shrinks a few percent instead of clipping.
3. **Display rows too wide for 320dp.** Equations, word splits, legends, number pads. Read-only
   rows scale down; rows of buttons wrap, because a tap target must not shrink.
4. **Columns taller than the body.** 578dp of body is not much. A column with no flex is a
   `SingleChildScrollView`; a column that uses `Spacer` to centre itself is the
   `LayoutBuilder` + `ConstrainedBox(minHeight)` + `IntrinsicHeight` recipe, so it still centres
   when it fits and scrolls when it does not. Four screens had a lazy viewport inside, which
   `IntrinsicHeight` cannot measure; those drop the `Spacer`s for fixed gaps and scroll plainly.

The lesson from the last one is worth keeping: `IntrinsicHeight` is the right tool for a
centred column that must also scroll, but it refuses to measure a `ListView` or `GridView`, and
the failure is a layout assertion at runtime, not a compile error. The audit caught all four in
one run.

### Landed: the 29 timers that outlived their screen

The audit's first clean run also caught a bug nobody was looking for. Twenty-nine games left a
timer running after the widget tree was disposed:

```
A Timer is still pending even after the widget tree was disposed.
```

A periodic timer that outlives its screen is a battery bug, not a test annoyance: the callback
keeps firing (and can keep the device awake) after the player has gone home. Twenty-four games
had the timer field but no `ref.onDispose`; three used `Future.delayed`, which cannot be
cancelled at all; one stored a `Timer` nowhere. All twenty-nine now cancel on dispose, and
`simon_sequence` awaits a cancellable delay instead of `Future.delayed` so leaving mid-sequence
unwinds instead of firing into a dead notifier.

The audit run is clean of timer failures now, which means a red run means overflow and nothing
else.

**Done when:** the audit reports `overflow=0 threw=0`, and both lists are empty.

---

## Phase 5 — The four invariant never ported

`Mosaic`, `Palisade`, `Hat`, `Spectre`, straight from Tatham's C. The first two are small.
`Hat` and `Spectre` are the aperiodic monotile tilings, they are newer than the public page,
and they are the kind of puzzle nobody else on the store has. They close the collection at
**42/42**.

---

## Phase 6 — Release

Audited and cleared on **2026-11-11**. The registry has **313** games (Logic 53, Math 63,
Memory 54, Spatial 38, Attention 54, Word 51). Every Phase 3 port lays out at 320dp and on a
tablet in the screen test, and `flutter analyze` reports nothing but the four `avoid_print`
infos in the developer-only audit tool.

### What was cleared

| Item | What happened |
| --- | --- |
| **App Store licence** | **Settled.** The upstream author replied and gave permission for the derived work to ship through the App Store. Recorded in [NOTICE](NOTICE). iOS is in the release. |
| **Play listing copy** | **Rewritten at 313.** The 161 count is gone from title, short and full description. The exhaustive game list was dropped: 313 names do not fit Play's 4000-character limit, so the copy names the six rooms and a set of highlights instead. |
| **Web copy** | `web/index.html` and `web/manifest.json` said 161; both say 313 now. |
| **Stale images** | **Deleted.** The eight phone screenshots still said MINDSTACK and 161, and so did the feature graphic. The graphic is regenerated from the app's own fonts and palette by `tool/feature_graphic.py`; the screenshots will be recaptured. |
| **Privacy policy URL** | **Hosted** at <https://cyoren.github.io/Puzzlestack/privacy.html>, with terms at <https://cyoren.github.io/Puzzlestack/terms.html>. The in-app Privacy Policy and Terms links point there, and the two `TODO`s in the settings screen are gone. |
| **Linux app id** | Was still `com.medhub.puzzlebox`. Now `com.medhub.puzzlestack`, like every other platform. |

### What is left

| Item | Status | Needs |
| --- | --- | --- |
| **Store screenshots** | Removed, not yet recaptured. The pipeline is fixed and self-contained first: it used to call a `compose.py` that lived outside the repo and no longer exists, and it shipped one 1290x2796 set to both stores although Play refuses anything past 2:1. It now composes two canvases from one capture. | A capture run on a device: `tool/screenshots.sh <device>`. |
| **Play Data Safety form** | Answers ready and verified against the source in [RELEASE.md](RELEASE.md): no data collected, nothing transmitted. | A human, in the console. |
| **Shorebird `app_id`** | Still the pre-rename id. Harmless: no shipped build bundles the updater. | An agent, with the Shorebird CLI, only if OTA is wanted at launch. |
| **Android + iOS together** | Same version, same copy, same listing assets. | The release build itself. |
| **SDK skew** | One info-level deprecation (`cacheExtent` → `scrollCacheExtent`) that only clears on a deliberate Flutter upgrade. | An agent, separately. |

### Playability audit

Gus's 30-item playability list lives in [docs/PLAYABILITY-AUDIT.md](docs/PLAYABILITY-AUDIT.md).
The list is closed and verified by `test/board/solve_button_test.dart`,
`test/board/transitions_test.dart`, `test/engines/norinori_engine_test.dart`, and the 313-game
audit in both themes (`AUDIT_DARK=1`).

Its **Still open** section is the handoff for the next agent. Three items are deliberate, not
loose ends, and none gates the release:

- **Population percentile.** The app compares a player to their own solve history. A global
  "faster than X%" needs a backend that does not exist; a number invented locally would be a lie.
- **Solve buttons on timed quizzes.** A reaction test has no answer to fill. A tutorial hint is a
  new feature, not a missing button.
- **A Norinori difficulty ladder.** The generator is 4x4 with 3-5 rooms and counts for exactly one
  answer. Bigger, tiered boards are new content, so they belong in Phase 5, not in a fix.

Figures from the pass: 4,993 tests, and `AUDIT checked=313 overflow=0 threw=0` at 320dp in both
themes.

Phases 3, 4 and 5 do not gate the release: Phase 4 is closed, the three Tatham ports left in
Phase 3 are optional, and Phase 5 is new content rather than a fix.

### Decided for after release: the paywall

The app will sell access, and the rule is narrow enough to write down now so the release build
does not paint us into a corner:

- **Every puzzle can be played at least once by everyone.** The free tier is not a teaser of
  three games; the whole catalogue is reachable.
- **Some puzzles are free forever**, and what makes a puzzle paid is decided per puzzle, not by
  category or position in the feed.
- So the paywall gates **replays and volume**, not first contact. Nothing in the release work
  may put a locked tile in front of a game the player has never opened, and the Shuffle feed
  must not be able to hand out only locked puzzles.

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
5. **The registry is the source of truth.** If a game is not in `game_registry.dart` with a
   category, it does not exist, no matter how good the screen is.
6. **No puzzle owns its gestures.** Input goes through the board contract, haptics through the
   five verbs, motion through the five moves. A puzzle that wires its own `GestureDetector`
   is a fork of the app inside the app.
7. **Read the Godot port, port from the C.** Our GDScript is the faster read and the better
   map; Tatham's C is the correctness bar. When they disagree, the C wins.
8. **Stop at the gate.** Each phase ends with a number we can check, not a feeling.
