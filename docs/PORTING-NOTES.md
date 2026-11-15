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
