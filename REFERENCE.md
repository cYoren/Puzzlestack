# Reference material

The work in the roadmap is porting. Porting needs a source to read and a source to test
against. Both are **outside this repository** on purpose: they are reference material, not
the product, and keeping them out of the tree keeps the repo about the app.

They live at `~/Projects/puzzlestack-reference/` (not in `~/Downloads`, where the original
zip sat and could have been swept away).

| Path | What it is | Licence | How we may use it |
| --- | --- | --- | --- |
| `tatham-c/` | Simon Tatham's Portable Puzzle Collection, C | **MIT** | Port from it. Copy, modify, ship. |
| `invariant/` | Godot 4 port of the same collection, 35 puzzles, GDScript | **ours** (Gus's own project) | Copy freely. |
| `invariant-main.zip` | the original archive the above came from | — | provenance |
| `invariant/invariant_flutter/` | Flutter scaffold, 1 puzzle (`galaxies`) | ours | Copy freely. |

## Licences

`invariant/` is ours, so its GDScript can be copied and translated into this repo without a
second thought. It ships no `LICENSE` file only because it was never published; that is a
housekeeping gap, not a permission problem.

`tatham-c/` is MIT, which is compatible with our GPL-3.0: we may copy, modify and ship it as
long as the copyright notice travels with it.

**Which one to port from is therefore a quality question, not a legal one.** Phase 3 still
ports from `tatham-c/`, for one reason: Tatham's generators guarantee a unique solution, and
only 3 of the 35 Godot generators mention uniqueness at all. The Godot code is the faster read
and the better map of how a puzzle decomposes into state / generator / validator / renderer;
the C is the correctness bar. Use both, in that order.

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
`d4d5d09` with **161 games** — which is exactly what we had, and confirms the fork point.
Upstream's `game_data.dart` still lists 205 games; that file is legacy. The registry they ship
from has 304, and Phase 2 merged all of them; Phase 3 adds the Tatham ports on top.

| | Value |
| --- | --- |
| Fork base | `d4d5d09` (2026-06-07), 161 games |
| Registry | `lib/data/game_registry.dart`, one `_metadata.dart` per game, 307 entries |
| Upstream HEAD when audited | `3a0928d` (2026-11-08), **304** registered games |
| Commits we never received | **100** |

Phase 2 merges from that base, so the diff is bounded and reviewable.

## Re-fetching

```bash
tool/fetch-reference.sh          # clones Tatham's collection at the pinned commit
```

The invariant archive has no remote, so the zip is the only copy of that work. Keep
`~/Projects/puzzlestack-reference/invariant-main.zip`; if it is lost, the Godot port is gone
too. Worth pushing to a private repo at some point.
