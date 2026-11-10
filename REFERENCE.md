# Reference material

The work in the roadmap is porting. Porting needs a source to read and a source to test
against, and both are **outside this repository** on purpose: one of them is MIT and one of
them is unlicensed, and neither belongs in a GPL tree.

They live at `~/Projects/puzzlestack-reference/` (not in `~/Downloads`, where the original
zip sat and could have been swept away).

| Path | What it is | Licence | How we may use it |
| --- | --- | --- | --- |
| `tatham-c/` | Simon Tatham's Portable Puzzle Collection, C | **MIT** | Port from it. Copy, modify, ship. |
| `invariant/` | Godot 4 port of the same collection, 35 puzzles, GDScript | **none declared** | **Read only.** Never copy a line. |
| `invariant-main.zip` | the original archive the above came from | — | provenance |
| `invariant/invariant_flutter/` | Flutter scaffold, 1 puzzle (`galaxies`) | none declared | read only |

## The licence rule, and why it is not pedantic

`invariant/` ships no `LICENSE`, no `COPYING`, no licence header. Absent a licence, the
default is all rights reserved: we may read it to understand an algorithm, and we may not
copy its code into a GPL-3.0 project. Algorithms and rules are not copyrightable; the
GDScript expressing them is.

So Phase 3 ports **from `tatham-c/`**, which is MIT and compatible with our GPL-3.0, and uses
`invariant/` only as a map of where each algorithm sits and how a puzzle decomposes into
state / generator / validator / renderer. That is also the better source: Tatham's generators
guarantee a unique solution, and only 3 of the 35 Godot generators mention uniqueness at all.

## Pinned provenance

| | Value |
| --- | --- |
| Tatham commit | `616da16f25da428ccda805536209095bd062676e` (2026-09-23) |
| Tatham games | 41 (`hat` and `spectre` are newer than the 40 the site lists) |
| `invariant-main.zip` sha256 | `fa24eac01f1d6479faf578cc…` |
| Invariant puzzles | 35 |
| Invariant Flutter port | 1 puzzle, 8 `.dart` files, 1,087 LOC |

## The upstream fork base

Our repo forked from `sidhant947/Puzzle` on **2026-06-07**. That day upstream was at
`d4d5d09` with **161 games** — which is exactly what we have, and confirms the fork point.

| | Value |
| --- | --- |
| Fork base | `d4d5d09` (2026-06-07), 161 games |
| Upstream HEAD when audited | `3a0928d` (2026-11-08), 205 games |
| Commits we never received | **100** |

Phase 2 merges from that base, so the diff is bounded and reviewable.

## Re-fetching

```bash
tool/fetch-reference.sh          # clones Tatham's collection at the pinned commit
```

The invariant archive is not public: it came as a zip. Keep
`~/Projects/puzzlestack-reference/invariant-main.zip`; if it is ever lost, the Godot port is
gone too, since there is no upstream to clone it from.
