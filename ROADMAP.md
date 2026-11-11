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
| 1 | **Eight Tatham puzzles to port.** Each is one PR: engine, provider, board, screen, metadata, 200-board test. | 1.6k–3.5k lines of C each | [Phase 3](#phase-3--port-the-tatham-puzzles-we-lack) |
| 2 | **14 classics rebuilt for uniqueness** (Sudoku, Nonogram, Slitherlink and 11 more). | one game at a time | [Phase 4](#phase-4--rebuild-the-14-classics-we-already-have) |
| 3 | **Four invariant never ported** (Mosaic, Palisade, Hat, Spectre). | small, then two large | [Phase 5](#phase-5--the-four-invariant-never-ported) |
| 4 | **Release.** Waiting on the upstream author's reply about the App Store licence (email sent 2026-11-10). Android, web and desktop are not blocked. | one pass | [Phase 6](#phase-6--release) |

The eight left in Phase 3, with what each one needs:

| Puzzle | Tatham file | Lines | Needs the solver? |
| --- | --- | --- | --- |
| Black Box | `blackbox.c` | 1587 | yes, deduction |
| Cube | `cube.c` | 1787 | no, folding |
| Netslide | `netslide.c` | 1889 | no, sliding |
| Inertia | `inertia.c` | 2246 | no, arcade |
| Signpost | `signpost.c` | 2568 | yes, deduction |
| Undead | `undead.c` | 3049 | yes, deduction |
| Tracks | `tracks.c` | 3159 | yes, deduction |
| Map | `map.c` | 3474 | yes, deduction |

Five need `lib/core/deduction.dart` (Black Box, Map, Signpost, Tracks, Undead); three need only
an interaction (Cube, Netslide, Inertia). **Start with Cube** if you want a fast win, or
**Signpost** if you want to exercise the harness again — Galaxies and Kurodoko are the two
worked examples to copy.

Blocked on a human, not on an agent:

- **The App Store licence question.** Email sent to the upstream author on 2026-11-10; now waiting
  on a reply nobody here can hurry. Blocks iOS release only — see the next section.
- **Codex review is out of credits.** PRs are self-reviewed and merged. See
  [papercuts.md](papercuts.md) for what that costs.

---

## Open decision: can this ship on the App Store at all?

This is the one thing that could invalidate half the plan, so it is decided before Phase 1,
not discovered at submission.

Puzzlestack is **GPL-3.0**, because it is a derivative of `sidhant947/Puzzle`, which is
GPL-3.0. The FSF's position is that Apple's App Store terms conflict with the GPL: the
store's usage restrictions are further restrictions the licence does not permit. VLC was
pulled over exactly this. Google Play has no such conflict.

The three ways out, in order of preference:

1. **Ask the upstream author for a licence exception** — permission to ship the derived work
   under the App Store terms. Costs an email, and the answer may well be yes. This is the
   only option that keeps iOS and the GPL history intact.
2. **Relicense to a permissive licence**, which needs the same permission plus our own
   consent as authors of the changes. Cleanest legally, loses the GPL guarantee.
3. **Ship Android, web and desktop; skip iOS.** Costs half the market.

**Status: option 1 is in motion.** The email to the upstream author went on **2026-11-10**.
Awaiting a reply, which may take weeks or never come.

Until an answer arrives, treat iOS as unconfirmed. Nothing in Phases 1–5 depends on it, which is
why the work continues — but Phase 6 cannot ship iOS without it, and **no iOS release work should
start before the reply**. If no reply comes, the fallback is option 3: ship Android, web and
desktop, and keep iOS out of the store listing rather than ship it in breach.

---

## Inventory (verified 2026-11-10)

| Source | What it is | Size | What we take |
| --- | --- | --- | --- |
| **Puzzlestack** (this repo) | our fork, 161 games at the fork point, **308** after Phases 2 and 3 | 78,131 LOC game code | the base |
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

**Left to port: 9.** Kurodoko is Tatham's Range and arrived with the merge too, so the 13
became 12 and three of those are done. Two more names were checked rather than assumed:
`cube_net_fold` is a cube-net puzzle but not `cube.c`, and `mental_mapping` is a
follow-the-arrows memory game, nothing to do with `map.c`.

### Landed so far: 4 of 12, plus one rebuilt

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

**Done when:** 316 games, and each ported puzzle has a test that generates 200 boards and
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

`Magnets, Tents & Trees` — **2 left**. Lights Out, Skyscrapers, Futoshiki and Dominosa are done.

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

- Store title and copy: the number in "307 Brain Puzzles" changes every phase, so it is set
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
5. **The registry is the source of truth.** If a game is not in `game_registry.dart` with a
   category, it does not exist, no matter how good the screen is.
6. **No puzzle owns its gestures.** Input goes through the board contract, haptics through the
   five verbs, motion through the five moves. A puzzle that wires its own `GestureDetector`
   is a fork of the app inside the app.
7. **Read the Godot port, port from the C.** Our GDScript is the faster read and the better
   map; Tatham's C is the correctness bar. When they disagree, the C wins.
8. **Stop at the gate.** Each phase ends with a number we can check, not a feeling.
