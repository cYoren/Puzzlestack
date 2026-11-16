# Porting notes

A game that resists gets one entry here instead of a silent downgrade: what was tried, why it
stopped, and the next step. Nothing is deleted from the list when it lands; the entry says so.

## `sticks` (Tatebo-Yokobo) — parked 2026-11-15

**An entry in [SOURCES.md](SOURCES.md) order 1, parked, not dropped.** The rules are readable
and the reference builds; what is missing is a model, not an idea.

What the puzzle is (from `sticks.c` in `x-sheep/puzzles-unreleased`, MIT): every white cell holds
a straight stick — horizontal or vertical — through its centre. A maximal run of sticks pointing
the same way is one stick, its **length** is the number of cells it crosses, and a number written
in a white cell is that length. A stick may carry at most one number. A black cell's number is how
many sticks point into it.

Why it stopped: the object being decided is a *stick*, and its length is bounded by the run of
cells that could still join it, not by a local count. A cell-domain model has to rebuild the
run-length bound (`sticks_max_size_horizontal`/`_vertical` in the C) every pass, and the exact
rule has to enumerate whole stick layouts, not cell colourings. That is a bigger model than
Boats, and doing it in the last hour of a batch would have produced exactly the "good enough"
port the house rules forbid.

Next step, in one go: a model whose slot is the cell with three values (black, horizontal,
vertical), a level-1 rule that reads a white number as "this run is exactly N cells" (so both
ends stop), a level-2 rule that counts a black cell's incoming sticks, and as the last rule a
search that enumerates stick layouts rather than cells and keeps only what every layout agrees
on. The generator already has a shape that fits it: lay a random stick layout, read every number
off it, then remove clues while the rules still finish the board.

## The six remaining games in SOURCES group 1

Each is a different model, so the Mathrax pattern does not transfer whole. These are the design
sketches I would start from, in the order I would take them, with the part that will actually bite.

### `salad` (ABC End View) — the next one, and the closest to what is already built

A Latin square of order `o` where values above `nums` are holes: each row and column holds every
letter `A..nums` exactly once and `o - nums` holes. Four border clues per line (top, left, bottom,
right) say which letter you meet first looking in, skipping holes. For `o < 8` the C ships **no**
grid clues at all, only the border — which is exactly the shape that is easy to get wrong.

Model: a domain of `{hole, 1..nums}` per cell, so a cell is three kinds of thing at once and the
zero-means-two-things trap is live (`0` must be hole and nothing else). Rules: no repeated letter in
a row or column; a border clue forbids letters in front of the first possible clue letter, and
forces holes there; a decided letter at position `j` forces every cell before `j` to be a hole. The
exact search is the generator's proof and the clue-stripper's test. Reuse Mathrax's Latin-square
generator with a different value mapping — that part is the same problem.

Risk: the search space is `(nums+1)^(o²)`, so the proof needs the border rules to do real work
before it branches. Measure with `nums = o - 1` (one hole per line) first; loosen only if it is
fast.

### `rome` (Nikoli Rome)

Every cell holds an arrow (up, down, left, right). Each outlined area contains no repeated arrow,
and following the arrows from any cell must arrive at a circled goal without looping.

Model: a 4-value domain per cell. Three rules, and the third is the interesting one:
1. an area's arrows are all different;
2. an arrow that points off the grid is impossible;
3. walk the chain from a cell through decided arrows: a cycle that contains no goal is a
   contradiction, and a cell whose every chain leads into decided cells is decided by elimination.

The C generator grows areas around a random arrow field and then places the minimum number of goals
(`w*h/25`), which is the part worth copying: one goal per area is a different, easier game.

Risk: rule 3 is a global property (a functional graph), not a local one. It has to be written as a
per-cell reachability check, and the exact search needs it inside the propagation or the count will
be wrong in exactly the way `clusters` was wrong before `isComplete` asked "decided and legal".

### `bricks` (Tawamurenga) — hexagonal grid

Shade cells: every shaded cell has a shaded cell below it (unless it is on the bottom row), no
three shaded cells in a row, a number counts shaded cells around it, and a numbered cell is never
shaded.

Risk: the grid is hexagonal, so this is the first port that needs new **geometry** rather than a
new model: a hex neighbourhood (`6` neighbours, two rows offset), and `GridBoard` assumes squares.
Either add a small `HexBoard` base (six-neighbour adjacency + offset painting) or park it until the
board contract grows one. Do not fake a hex grid by drawing a square grid at a slant.

### `crossing` (Nansuke / Number Skeleton)

Place every number from the list into the grid, horizontally or vertically, each exactly once, with
one digit per cell.

Model: this is a placement puzzle, not a fill. The objects are the *numbers*, so a model over cells
is the wrong shape: it needs `List<List<Placement>>` — every position and direction each number can
still occupy — with the grid as the shared constraint. Deduction is "a number with one placement
left is placed" and "a cell covered by placements that all carry the same digit is that digit".
This is the `sticks` lesson again: the object is not a cell, so the board must model the object.

Risk: the win test is not "the grid is filled" but "every listed number appears exactly once",
which is a different predicate from every other game here and needs its own test.

### `spokes`

Connect every hub into one group by drawing lines between points on hubs; a hub's number is its
connection count; diagonal lines may not cross.

Risk: the object is an **edge between two ports**, with a non-crossing constraint over the whole
board — the most geometric of the six, and the one I would do last. It also needs the most new
board plumbing (ports per hub, hit-testing a diagonal, drawing a crossing check).

### `subsets` (Inaba Naoki) — last

Place each given set of cells into the grid exactly once; a horseshoe points from a superset to a
subset, and every horseshoe is given.

Risk: the objects are whole shapes with containment relations, so the model is a set-placement
search with an "all horseshoes are given" completeness claim. That completeness is a property of the
*generator*, not the solver, and it is the kind of thing that is easy to believe and hard to prove:
budget a full session for the generator alone.

### Order I would take them

`salad` → `rome` → `crossing` → `bricks` → `spokes` → `subsets`. The first two reuse machinery that
already exists (Latin squares, four-value domains); the middle two need new board plumbing; the last
two need their object model built from scratch.
