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
| AGPL-3.0 | **yes** | GPL-3.0 section 13 allows the combination. The ported files stay AGPL: say so in their header and in `NOTICE`. The app has no server and its source is public, so nothing else changes |
| No licence file | **yes, through the permission lane** | see below |
| GPL-2.0-only, non-commercial, proprietary | **permission lane only** | same |

### The permission lane

A repository with no licence is not free to copy: by default its author keeps all rights. It is
still open to us, two ways, and Gus has said both are in scope (2026-11-14):

1. **Ask.** Gus contacts the author. Port on a branch meanwhile; the PR is labelled
   `needs-permission` and merges when the reply is recorded in `NOTICE`, the way the upstream
   author's App Store permission was. To start it, add a row to the table at the end of this
   file with the repo, the author and what we want.
2. **Make it new.** Take the idea, the rules and what the code taught you, and write our own
   implementation with our own boards, look and name. That is a new work and needs nobody's
   permission. Do not paste their code or their level data into it.

When unsure which applies, do 2. It is always allowed and it usually produces the better card.

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

## 5. New card types, and where each comes from

Second sweep, 2026-11-14. Organised by what the Deck gains, because that is how to choose.
The first five are the ones to build first: each is a kind of card the Deck does not have,
reads in five seconds, and has a generator or a large open supply behind it.

### Build these first

| Card | What the player does | Source | Licence |
| --- | --- | --- | --- |
| **Line panels** | Draw one line from the start dot to the exit so every symbol on the panel is satisfied (separate the colours, pass every dot, outline the shape) | `sigma144/witness-randomizer` (a generator for every symbol type), `jbzdarkid/witness-puzzles` (editor and solver, now at `jbzdarkid/jbzdarkid.github.io`) | MIT, BSD-3-Clause |
| **Picture nonograms** | A 5x5 to 10x10 nonogram that reveals a real picture when solved, which is the payoff random grids lack | Rasterise open icon sets, keep only boards the solver proves unique: `google/material-design-icons` (Apache-2.0), `googlefonts/noto-emoji` (OFL-1.1), `twitter/twemoji` (MIT code, CC BY 4.0 art: attribute). Solvers: `Izaron/Nonograms`, `tsionyx/nonogrid` | MIT |
| **Push boxes** | Sokoban on a 10x10 board | `google-deepmind/boxoban-levels`: generated levels in three difficulty sets, so no authored level sets are needed. `mpSchrader/gym-sokoban` generates more | Apache-2.0, MIT |
| **Linjat** | Cover every dot with straight lines of the right length; made for a phone, generated, graded | `jsnell/linjat` | MIT |
| **Rule grids** | See two or three before-and-after grids, work out the rule, paint the answer | `fchollet/ARC-AGI`, `arcprize/ARC-AGI-2`: hand-pick the small, clean tasks (10x10 or less) | Apache-2.0 |

Use our own names. "Line panels" must not be called after the game it comes from, and Sokoban
is "Push boxes" unless the name is confirmed free to use.

### More logic and number cards

| Card or use | Source | Licence |
| --- | --- | --- |
| **Numberlink** (connect the pairs, fill the grid), plus Walls and extended Undead, Unequal and Solo | `SteffenBauer/sgtpuzzles-extended`: `flow.c walls.c solo_plus.c undead_plus.c unequal_plus.c` on Tatham's framework. Prefer `flow.c` to the AGPL Numberlink repo: same puzzle, simpler licence, same porting pipeline | MIT (Tatham's text) |
| Tap-only controls for every Tatham puzzle | `SteffenBauer/PocketPuzzles` (e-reader port), `medmunds/puzzles-web` (PWA) | MIT text, MIT |
| **Dungeon walls**: place walls from row and column counts so every monster sits in a dead end and the treasure in a room | `halfburnttoast/Dungeon-Cross` for the rules; generate our own boards | GPL-2.0, check headers |
| **Hex mines**: hexagonal Minesweeper where every step is deducible | `oprypin/sixcells` (level format, player); generate our own | GPL-3.0 |
| **Hexalate**: rotate hex tiles until touching colours match | `gottcode/hexalate` | GPL-3.0 |
| **Clue grid**: the Einstein puzzle as an icon grid instead of a wall of text. Rebuilds `einstein_riddle` into a Deck card | `lksj/einstein-puzzle` (Sherlock-style), `murfffi/zebra4j` (generator with unique answers) | GPL-2.0 check headers, LGPL-3.0 |
| **Knights and knaves**: who is lying. Rebuilds `logical_syllogisms` | `dmackinnon1/inspectorCraig` (generators for Smullyan-style puzzles) | none: permission lane |
| **Matrix patterns**, generated. Makes `matrix_reasoning` a Deck run | `WellyZhang/RAVEN` | GPL-3.0 |
| **Queens / Star Battle** with hints in plain words | `gitars/queens-generator` | MIT |
| Bridges generator and solver, second opinion | `erthium/hashiwokakero` | GPL-3.0 |
| No-guess Minesweeper, second reference | `lucasnlm/antimine-android` | GPL-3.0 |
| Peg solitaire boards | `gottcode/peg-e` | GPL-3.0 |
| Cipher puzzles beyond the substitution cryptogram | `ruppde/crypto_puzzles` | GPL-3.0 |

### Difficulty and hints

The Library's tiers and every hint should come from how a person solves, not from grid size.

| Use | Source | Licence |
| --- | --- | --- |
| Rate a puzzle by the hardest technique it needs; generate to a requested level | `emieks/pencil-puzzles` | MIT |
| Sudoku: name the next technique for a hint, and grade a board | `SudokuMonster/SukakuExplainer`, `PseudoFish/Hodoku` | LGPL-2.1, GPL-3.0 |
| Sudoku: fast generation | `t-dillon/tdoku` | BSD-2-Clause |
| Explain a step as a rule ("this cell must be lit because...") | `Bram-Hub/LEGUP` | GPL-3.0 |
| 100+ solvers on OR-Tools and 41k collected boards over 130 types | `SmilingWayne/puzzlekit` and its dataset repo. The solvers are ours to use; the boards were collected from puzzle sites, so use them to test our solvers and do not ship them | MIT for the code |

### Word cards

| Card or use | Source | Licence |
| --- | --- | --- |
| **Word grid** (Boggle-style, find words by adjacent letters) | `gottcode/tanglet`; `lexica/lexica` | GPL-3.0; GPL-3 and Apache-2.0 files |
| **Connectagram**: unscramble words laid out as a crossword | `gottcode/connectagram` | GPL-3.0 |
| **Hive**: make words from seven letters, one compulsory | `ConorSheehan1/spelling-bee`, `philshem/open-spelling-bee` | MIT |
| Guess-the-word in 80+ languages | `lynn/hello-wordl` (MIT); `Hugo0/wordle` (word data licensed per language: check each) | MIT, mixed |
| Crossword layout from a word list | `MichaelWehar/Crossword-Layout-Generator`, `riverrun/genxword`; fill words from `Crossword-Nexus/collaborative-word-list` | MIT, GPL-3.0, MIT |
| Rhymes and homophones from pronunciation, not spelling | `cmusphinx/cmudict` | BSD-style |
| Word ladders over a connected graph of common words | `charlesreid1/five-letter-words` (Knuth's 5,757) | MIT |
| Portuguese word lists, for the second Word language | `fserb/pt-br`, `pythonprobr/palavras` | MIT, MPL-2.0 |
| German word list | `enz/german-wordlist` | CC0 |

### Siblings worth studying

Not for code. For how someone else answered the same questions.

- `lendl/quiet-grid` (GPL-3.0): a privacy-first logic puzzle app for Android, no ads, no
  account. The closest thing to us on the store.
- `brain-workshop/brainworkshop` (GPL-2.0): the reference n-back, and how it keeps a lab task
  playable for years.
- `loethen/freefocusgames` (no licence): lab tasks presented as games.

## More, now in scope

| Source | Licence | What is in it for us |
| --- | --- | --- |
| **thomasahle/numberlink** | AGPL-3.0 | Generator and solver for Numberlink (the connect-the-pairs puzzle). Portable directly; brings a type the Deck lacks |
| **lichess-org/lila** | AGPL-3.0 | Puzzle selection and rating logic, if the chess card happens |
| **begoon/sokoban-maps** | none: permission lane | 60 Sokoban maps. Ask, or generate our own |
| **dimitri/sudoku** | none: permission lane | A solver write-up; nothing here we cannot write ourselves |
| **KDE/katomic**, **palapeli**, **kshisen**, **klickety**, **killbots** | not detected on GitHub; KDE projects carry it in file headers | Atomix-style, jigsaw, Shisen-Sho, Clickomania. Read the headers, then treat as section 3 |

## Still do not take

- Puzzles copied from newspapers, KrazyDad, Conceptis, Nikoli's books or any puzzle site, and
  named level sets, unless their author has said yes in the permission lane.
- Anyone's artwork, sounds or renderer.

## Order

In 1.1.0, sources serve jobs already on the roadmap: Tatham's Mines for `minesweeper-no-guess`,
SCOWL tiers for every Word answer list, `fogleman/rush` for the `block_escape` pool.

After 1.1.0, new games in this order. Each is one PR, enters as Library, and is promoted
through the bar.

1. **The thirteen unreleased Tatham-framework puzzles**, starting with Boats, Ascent and
   Seismic. Same pipeline as the ports already done, so the cheapest good puzzles available.
2. **The five new card types** in section 5: Line panels, Picture nonograms, Push boxes,
   Linjat, Rule grids. These are what make the Deck unlike any other puzzle app.
3. **Tatham's remaining five**: Mosaic, Palisade, Black Box, Undead, Tracks.
4. **Nikoli types by offline-proved pools**: Star Battle, LITS, Suguru, Shakashaka first.
5. **Tetravex, Atomix, Hexalate, Dungeon walls, Hex mines.**
6. **Rebuilds from the Archive** (CATALOG.md): Vector Golf, Clue grid, Knights and knaves.
7. **Numberlink**, ported from `flow.c` in `SteffenBauer/sgtpuzzles-extended`.
8. **Mate in one**, if the licence check holds and a chess card passes the five-second read.

Anything else an agent finds is welcome: add it to the right table here with its licence, in
the same PR that uses it.

## Permissions asked

| Repo | Author | What we want | Asked | Answer |
| --- | --- | --- | --- | --- |
