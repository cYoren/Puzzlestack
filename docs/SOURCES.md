# Sources: where good puzzles come from

We do not invent puzzle types. The good ones exist, are decades old, and many have open
implementations with generators and solvers that already prove one answer. Port those.
The bar a port must pass is [PUZZLE-BAR.md](PUZZLE-BAR.md); pinned commits and attributions go
in [REFERENCE.md](../REFERENCE.md) and `NOTICE` as before.

Licences below were read from each repository on 2026-11-14. Check again at the commit you pin.

## What we may take

Puzzlestack is GPL-3.0.

| From | Code | Notes |
| --- | --- | --- |
| MIT, BSD, Apache-2.0, Unlicense, CC0 | **yes** | keep the copyright notice in `NOTICE` |
| GPL-3.0, GPL-2.0-or-later, LGPL | **yes** | "or later" must be in the file header; GitHub's label does not say |
| GPL-2.0-only, AGPL, no licence, non-commercial | **no code** | read for ideas only |

- **Rules are free.** A puzzle's rules are not copyrightable. Any type can be rebuilt from its
  rules, whatever the licence of the program you learned it from.
- **Names may not be.** Use our own name where the common one is a brand (Rush Hour, Set,
  Mastermind, Flow, Wordle, Connections, Spelling Bee). Keep the traditional name where it is
  generic (Sudoku, Slitherlink, Akari, Nonogram).
- **Hand-made levels are content.** Named level sets, newspaper puzzles and crossword clues
  belong to their authors. Generate boards, or write our own.
- **Never take a renderer.** Generators, solvers and rules are portable. The look is ours
  (`PUZZLE_STYLE.md`).

## 1. Port the code: generators that prove one answer

| Source | Licence | What is in it for us |
| --- | --- | --- |
| **Simon Tatham's Portable Puzzle Collection** (pinned in REFERENCE.md) | MIT | Already the base of the Logic room. Still unported: Black Box, Undead, Tracks, Mosaic, Palisade. Its Mines generator guarantees a board solvable without guessing: use it for `minesweeper-no-guess` |
| **x-sheep/puzzles-unreleased** | MIT (Tatham's licence text) | Thirteen more puzzles on the same framework, so the same porting pipeline applies: `abcd ascent boats bricks clusters crossing mathrax rome salad seismic spokes sticks subsets`. Boats is solitaire battleships, Ascent is a number path (Hidato), Seismic is Ripple Effect |
| **chrisboyle/sgtpuzzles** | MIT (same text) | The Android port of the same collection. Not for code: for how each puzzle was made usable with a thumb |
| **fogleman/rush** | MIT | Solver, generator and a database of every interesting sliding-car board, graded by moves. A graded pool for `block_escape` |
| **gabrielecirulli/2048** | MIT | Reference behaviour for `game_2048` |

## 2. Take the rules and prove boards offline

These know the rules of far more puzzle types than we have, and can check a board has exactly
one answer. Most do not generate. The pattern: a script in `tool/` generates candidates, one of
these solvers proves uniqueness and grades difficulty, and the app ships the proved boards as
an asset pool of thousands. The app never needs the solver.

| Source | Licence | What is in it for us |
| --- | --- | --- |
| **robx/pzprjs** (puzz.link) | MIT | 188 puzzle-type files: the rules and answer checking for nearly the whole Nikoli canon. The catalogue to choose the next types from, and the reference when our rules disagree |
| **kevinychen/nikoli-puzzle-solver** | MIT | Solvers for 100+ types with unique-answer checking |
| **obijywk/grilops** | MIT | Grid-logic solver library (regions, loops, paths) for writing a prover in a few lines |
| **semiexp/cspuz** | MIT | Constraint solver built for pencil puzzles; fast enough to generate by search |
| **swaroopg92/penpa-edit** | MIT | Puzzle editor; useful for drawing and checking a board by hand |

Types from the Nikoli canon the Deck does not have yet, in rough order of how well they fit a
one-minute card: **Star Battle, LITS, Suguru, Shakashaka, Numberlink, Yin-Yang, Aqre, Country
Road**. Check the registry first; `crown` may already be Star Battle.

## 3. GPL desktop collections

Mature, well-tested games. Code may be taken where the header says GPL-3.0 or "2 or later".

| Source | Licence on GitHub | What is in it for us |
| --- | --- | --- |
| **GNOME/gnome-sudoku** | GPL-3.0 | Graded Sudoku generation, for the Library's clue tiers |
| **GNOME/gnome-mines**, **hitori**, **gnome-taquin**, **gnome-klotski** | GPL-3.0 | Second opinions on games we have; Klotski's classic layouts |
| **GNOME/gnome-tetravex** | GPL-2.0, "or later" in headers | **Tetravex**: edge-matching tiles. A type we lack, and a good card at 3x3 |
| **GNOME/atomix** | GPL-2.0, check headers | **Atomix**: slide atoms until they form the molecule. A type we lack |
| **GNOME/swell-foop**, **lightsoff**, **five-or-more** | GPL-2.0, check headers | References for `same_game` and `lights_out` |
| **KDE/ksudoku**, **picmi**, **knetwalk**, **kubrick** | GPL-2.0, check headers | Sudoku variants, a Nonogram, a pipes game, a cube |
| **Enigma-Game/Enigma** | GPL-2.0, "or later" in headers | Hundreds of marble puzzles. Ideas only: the levels are authored content |
| **shlomif/PySolFC**, **shlomif/fc-solve** | GPL-3.0, MIT | Solitaire rules and a solver. Not now: card solitaire is a different app |

## 4. Words and data

| Source | Licence | What is in it for us |
| --- | --- | --- |
| **en-wl/wordlist** (SCOWL) | permissive, own text; keep the notice | English words in size tiers. **Answer lists come from the small tiers**, which is the fix for answers nobody knows |
| **wordnik/wordlist** | MIT | A word list made for games: the guess validator |
| **dwyl/english-words** | Unlicense | 479k words. Too wide for answers (it is why `AAA` is accepted today); validator of last resort |
| **hermitdave/FrequencyWords** | MIT for the code; check the data licence | Frequency lists in many languages: the start of Word content beyond English |
| **century-arcade/xd** | MIT for the tools | Crossword corpus tooling. The clues in it belong to publishers: do not ship them. Our 5x5 clues are written by us |
| **Lichess puzzle database** (database.lichess.org) | the site states CC0; confirm before importing | Millions of rated chess puzzles. A "mate in one" Think card would be new to the Deck. `davecom/chess.dart` (MIT-style) gives move legality. A proposal, not a commitment |
| **increpare/PuzzleScript** | MIT for the engine | Thousands of small push-block games, each under its own licence. A source of mechanics, not of levels |

## Do not take

- `thomasahle/numberlink` and `lichess-org/lila`: AGPL. Read, do not copy.
- Repositories with no licence file (for example `begoon/sokoban-maps`, `dimitri/sudoku`).
- Puzzles from newspapers, KrazyDad, Conceptis, Nikoli's own books, or any puzzle site.
- Named Sokoban level sets. Sokoban joins the Deck only with generated levels.

## Order

In 1.1.0, sources serve jobs already on the roadmap: Tatham's Mines for `minesweeper-no-guess`,
SCOWL tiers for every Word answer list, `fogleman/rush` for the `block_escape` pool.

After 1.1.0, new games in this order. Each is one PR, enters as Library, and is promoted
through the bar.

1. **The thirteen unreleased Tatham-framework puzzles**, starting with Boats, Ascent and
   Seismic. Same pipeline as the ports already done, so the cheapest good puzzles available.
2. **Tatham's remaining five**: Mosaic, Palisade, Black Box, Undead, Tracks.
3. **Nikoli types by offline-proved pools**: Star Battle, LITS, Suguru, Shakashaka first.
4. **Tetravex and Atomix.**
5. **Rebuilds from the Archive** (CATALOG.md): Vector Golf first.
6. **Mate in one**, if the licence check holds and a chess card passes the five-second read.
