# Reference material

The work in the roadmap is porting. Porting needs a source to read and a source to test
against. Both are **outside this repository** on purpose: they are reference material, not
the product, and keeping them out of the tree keeps the repo about the app.

They live at `~/Projects/puzzlestack-reference/` (not in `~/Downloads`, where the original
zip sat and could have been swept away). The pins are in
[`tool/reference-pins.tsv`](tool/reference-pins.tsv), one line per source named in
[docs/SOURCES.md](docs/SOURCES.md), and are the single place a port cites from.

**Nothing here has been ported yet.** What has been *adapted* into the app is the Tatham
collection (`tatham-c/`): nine puzzle ports and the Logic room's base. Everything else is
pinned, licence-checked and readable; the ports are the jobs in ROADMAP.md, starting with the
thirteen unreleased Tatham puzzles and the five new card types in SOURCES.md §5.

## Code and data sources — 85 pinned

Every commit below was cloned and its licence file read on 2026-11-14, not taken from a
GitHub label. Where the file says "or later" it says so; a bare `GPL-3.0` or `GPL-2.0` means the
COPYING is that version and **the file headers must be read before copying code**, per
SOURCES.md.

| Path | Commit | Licence at that commit | What it is for |
| --- | --- | --- | --- |
| `Bram-Hub_LEGUP/` | `448413841d5e` | GPL-3.0 | explain a solving step as a rule |
| `ConorSheehan1_spelling-bee/` | `56e0e1a4e5ea` | MIT | Hive: make words from seven letters |
| `Crossword-Nexus_collaborative-word-list/` | `b51b2ad6876c` | MIT | fill words for crosswords |
| `Enigma-Game_Enigma/` | `6f0c51b26cc0` | GPL-2.0-or-later | marble puzzle ideas only: the levels are authored content |
| `GNOME_atomix/` | `a135504eaa11` | GPL-2.0-or-later | Atomix: slide atoms until they form the molecule |
| `GNOME_five-or-more/` | `3ab38fec52df` | LGPL-2.0-or-later | reference for same_game |
| `GNOME_gnome-klotski/` | `9ad01368116a` | GPL-3.0-or-later | Klotski's classic layouts |
| `GNOME_gnome-mines/` | `c6d92db76ea8` | GPL-3.0-or-later | second opinion on minesweeper |
| `GNOME_gnome-sudoku/` | `6eb04b4c8362` | GPL-3.0-or-later | graded Sudoku generation for the clue tiers |
| `GNOME_gnome-taquin/` | `976a09db5ed3` | GPL-3.0-or-later | second opinion on sliding puzzles |
| `GNOME_gnome-tetravex/` | `95c138b00025` | LGPL-2.0-or-later | Tetravex: edge-matching tiles, a type the Deck lacks |
| `GNOME_hitori/` | `94cefada12cf` | GPL-2.0-or-later | second opinion on hitori |
| `GNOME_lightsoff/` | `6e1606fa9a4f` | LGPL-2.0-or-later | reference for lights_out |
| `GNOME_swell-foop/` | `be83f038e419` | LGPL-2.0-or-later | reference for same_game |
| `Hugo0_wordle/` | `7b2466fcb43d` | MIT | guess-the-word; word data licensed per language |
| `Izaron_Nonograms/` | `a867083d1197` | MIT | nonogram solver |
| `KDE_knetwalk/` | `08ff65d476af` | GPL-2.0-or-later | a pipes game |
| `KDE_ksudoku/` | `22b4006485e4` | GPL-2.0-or-later | Sudoku variants |
| `KDE_kubrick/` | `b113e1c23883` | GPL-2.0-or-later | a cube |
| `KDE_picmi/` | `ba591463dd0a` | GPL-2.0-or-later | a Nonogram |
| `MichaelWehar_Crossword-Layout-Generator/` | `ff5ff36b223d` | MIT | crossword layout from a word list |
| `PseudoFish_Hodoku/` | `c37fe90bf1da` | GPL-3.0 | Sudoku grading and hints |
| `SmilingWayne_puzzlekit/` | `9ef8ebbb2620` | MIT | 100+ solvers over 130 types; their boards are not shippable |
| `SteffenBauer_PocketPuzzles/` | `8cb6d0054153` | MIT | tap-only controls for Tatham puzzles |
| `SteffenBauer_sgtpuzzles-extended/` | `aaba49f620c5` | MIT | flow.c, walls.c and friends on Tatham's framework |
| `SudokuMonster_SukakuExplainer/` | `362854eea4e9` | LGPL-2.1 | name the next Sudoku technique for a hint |
| `WellyZhang_RAVEN/` | `77927ba3fe26` | GPL-3.0 | matrix patterns, generated |
| `arcprize_ARC-AGI-2/` | `f3283f727488` | Apache-2.0 | Rule grids tasks, second set |
| `begoon_sokoban-maps/` | `7aacdd777e38` | none: permission lane | 60 Sokoban maps (permission lane) |
| `boxoban/` | `78011d8c86ad` | Apache-2.0 | generated Sokoban levels in three difficulty sets, for Push boxes |
| `brain-workshop_brainworkshop/` | `3476f724eb62` | GPL-2.0-or-later | study: the reference n-back |
| `century-arcade_xd/` | `9b6d3381f341` | MIT | crossword corpus tooling; the clues are not ours to ship |
| `charlesreid1_five-letter-words/` | `0b8e26034d23` | MIT | Knuth's 5,757 five-letter words, a connected graph |
| `chrisboyle_sgtpuzzles/` | `d1e10eb57dd8` | MIT | Android port of Tatham's collection: how each puzzle was made thumb-usable |
| `cmusphinx_cmudict/` | `74790861f652` | BSD-2-Clause (CMU) | rhymes and homophones from pronunciation, not spelling |
| `davecom_chess.dart/` | `6f9e93ba7ac7` | MIT | chess move legality, if the chess card happens |
| `dimitri_sudoku/` | `f71352458f14` | none: permission lane | Sudoku solver write-up (permission lane) |
| `dmackinnon1_inspectorCraig/` | `db370e9cb4b1` | none: permission lane | Knights and knaves generators |
| `dwyl_english-words/` | `20f5cc9b3f0c` | Unlicense | 479k words: validator of last resort, too wide for answers |
| `emieks_pencil-puzzles/` | `5339049b842f` | MIT | rate a puzzle by its hardest technique, generate to a level |
| `enz_german-wordlist/` | `1071d87d9535` | CC0-1.0 | German word list |
| `erthium_hashiwokakero/` | `2a566964925e` | GPL-3.0 | Bridges generator and solver, second opinion |
| `fchollet_ARC-AGI/` | `399030444e0a` | Apache-2.0 | Rule grids tasks; hand-pick the small clean ones |
| `fserb_pt-br/` | `93ba2a6f3b2f` | MIT | Portuguese word list |
| `gabrielecirulli_2048/` | `478b6ec346e3` | MIT | reference behaviour for game_2048 |
| `gitars_queens-generator/` | `74bdd520eff1` | MIT | Queens / Star Battle generator |
| `gottcode_connectagram/` | `7f47019e36e2` | GPL-3.0 | Connectagram: unscramble words laid out as a crossword |
| `gottcode_hexalate/` | `1b8b3b9c0650` | GPL-3.0 | Hexalate: rotate hex tiles until colours match |
| `gottcode_peg-e/` | `49b5d466f644` | GPL-3.0 | peg solitaire boards |
| `gottcode_tanglet/` | `501706a8c4f2` | GPL-3.0 | Word grid: find words among adjacent letters |
| `halfburnttoast_Dungeon-Cross/` | `2abaa08e797d` | LGPL-2.0-or-later | Dungeon walls: the rules, generate our own boards |
| `hermitdave_FrequencyWords/` | `525f9b560de4` | MIT | frequency lists for languages beyond English |
| `increpare_PuzzleScript/` | `e5a9c5a2ece4` | MIT | push-block mechanics ideas, not levels |
| `jbzdarkid_witness-puzzles/` | `1df3750a0d6d` | BSD | Line panels: editor and solver |
| `jsnell_linjat/` | `915d2db10bbe` | MIT | Linjat: generated, graded, made for a phone |
| `kevinychen_nikoli-puzzle-solver/` | `b02b40153393` | MIT | solvers for 100+ types with unique-answer checking |
| `lendl_quiet-grid/` | `75aba674e59b` | GPL-3.0 | study: privacy-first logic puzzle app, no ads, no account |
| `lexica_lexica/` | `4a71963b78e3` | GPL-3.0 (game) + Apache-2.0 (dictionary) | Word grid, plus a dictionary trie |
| `lksj_einstein-puzzle/` | `db34f7a51c17` | LGPL-2.0-or-later | Clue grid as an icon grid instead of a wall of text |
| `loethen_freefocusgames/` | `5f82e124f0f9` | none: permission lane | study: lab tasks presented as games |
| `lucasnlm_antimine-android/` | `86400370a7b7` | GPL-3.0 | no-guess Minesweeper, second reference |
| `lynn_hello-wordl/` | `835db051e78d` | MIT | guess-the-word in 80+ languages |
| `medmunds_puzzles-web/` | `28b1b76e4f82` | MIT | tap-only controls for Tatham puzzles |
| `mpSchrader_gym-sokoban/` | `8e06e44e8bf3` | MIT | generates more Push boxes levels |
| `murfffi_zebra4j/` | `b03c86d2fb58` | LGPL-3.0 | Clue grid generator with unique answers |
| `obijywk_grilops/` | `18a664122a19` | MIT | grid-logic solver library, for writing a prover in a few lines |
| `oprypin_sixcells/` | `ab014c73cb4a` | GPL-3.0 | Hex mines: level format and player |
| `philshem_open-spelling-bee/` | `ee10f53e86d6` | MIT | Hive word data |
| `puzzles-unreleased/` | `b09e5a752d64` | MIT | thirteen more puzzles on the same framework: Boats, Ascent, Seismic and the rest |
| `pythonprobr_palavras/` | `775e1c656d5a` | MPL-2.0 | Portuguese word list |
| `riverrun_genxword/` | `5442cb3e32f7` | GPL-3.0 | crossword layout |
| `robx_pzprjs/` | `ba714a265515` | MIT | 188 Nikoli types: rules and answer checking, the catalogue for new types |
| `ruppde_crypto_puzzles/` | `415592383265` | GPL-3.0 | cipher puzzles beyond the substitution cryptogram |
| `rush/` | `3e3b8396891d` | MIT | sliding-car solver, generator and graded board database for block_escape |
| `semiexp_cspuz/` | `53b97cbfcbaa` | MIT | constraint solver built for pencil puzzles |
| `shlomif_PySolFC/` | `6f9658d06201` | GPL-3.0 | solitaire rules (not now) |
| `shlomif_fc-solve/` | `9e55e0a3f7cf` | MIT | solitaire solver (not now) |
| `sigma144_witness-randomizer/` | `2f6b08da579b` | MIT | Line panels: a generator for every symbol type |
| `swaroopg92_penpa-edit/` | `34e3fe97804e` | MIT | puzzle editor, to draw and check a board by hand |
| `t-dillon_tdoku/` | `af426180dc53` | BSD | fast Sudoku generation |
| `tatham-c/` | `616da16f25da` | MIT | Simon Tatham's Portable Puzzle Collection: the Logic room's base, and the no-guess Mines generator |
| `thomasahle_numberlink/` | `541c30cf23db` | AGPL-3.0 | Numberlink generator and solver (connect the pairs) |
| `tsionyx_nonogrid/` | `aaf7f9a4f703` | MIT | nonogram solver |
| `wordlist/` | `1e5b7d3a72f4` | permissive, own notice (SCOWL) | English words in size tiers; answer lists come from the small tiers |
| `wordnik_wordlist/` | `46e6215d0f90` | MIT | a word list made for games: the guess validator |

## Source art, pinned but not checked out — 4

Picture nonograms need images, and these repositories are gigabytes of them. They are pinned to
a commit without a checkout: `git -C <dir> show <commit>:<path>` reads a single file when one is
needed. Fetch them with `tool/fetch-reference.sh --assets`.

| Path | Commit | Licence at that commit | What it is for |
| --- | --- | --- | --- |
| `google_material-design-icons/` | `10ecc1479061` | Apache-2.0 | picture nonogram source art |
| `googlefonts_noto-emoji/` | `99701e07d3d1` | OFL-1.1 | picture nonogram source art |
| `lichess-org_lila/` | `4a427ef69b93` | AGPL-3.0 | puzzle selection and rating, if the chess card happens |
| `twitter_twemoji/` | `bad3bceeafc9` | MIT + CC-BY-4.0 | picture nonogram source art (CC BY 4.0: attribute) |

## Ours, with no upstream

| Path | What it is | Licence | How we may use it |
| --- | --- | --- | --- |
| `invariant/` | Godot 4 port of Tatham's collection, 35 puzzles, GDScript | **ours** (Gus's own project) | Copy freely. |
| `invariant-main.zip` | the archive the above came from, and the only copy of it | — | Keep it; if it is lost the Godot port is gone too. |
| `invariant/invariant_flutter/` | Flutter scaffold, 1 puzzle (`galaxies`) | ours | Copy freely. |

`invariant/` ships no `LICENSE` file only because it was never published; that is a housekeeping
gap, not a permission problem. Worth pushing to a private repo at some point.

## Licences

`tatham-c/` is MIT, which is compatible with our GPL-3.0: we may copy, modify and ship it as
long as the copyright notice travels with it. `invariant/` is ours.

**Which one to port from is a quality question, not a legal one.** Phase 3 ported from
`tatham-c/`, for one reason: Tatham's generators guarantee a unique solution, and only 3 of the
35 Godot generators mention uniqueness at all. The Godot code is the faster read and the better
map of how a puzzle decomposes into state / generator / validator / renderer; the C is the
correctness bar. Use both, in that order.

Four repositories below carry **no licence file** (`loethen_freefocusgames`, `begoon_sokoban-maps`,
`dimitri_sudoku`, `dmackinnon1_inspectorCraig`). They are not free to copy: by default the author
keeps all rights. They are readable material and a permission-lane candidate; see SOURCES.md.

## What the licence pass corrected in SOURCES.md

The licence column there was read from repository labels on 2026-11-14; reading the files at the
pinned commit changed four claims:

| Source | SOURCES.md said | The file says |
| --- | --- | --- |
| `GNOME/gnome-tetravex`, `swell-foop`, `lightsoff`, `five-or-more` | GPL-2.0, check headers | **LGPL-2.0-or-later** |
| `halfburnttoast/Dungeon-Cross` | GPL-2.0, check headers | **LGPL-2.0-or-later** |
| `lksj/einstein-puzzle` | GPL-2.0, check headers | **LGPL-2.0-or-later** |
| `GNOME/gnome-hitori`, `GNOME/atomix` | `GNOME/...` on GitHub | GitHub has no such repository: they are on **gitlab.gnome.org** |

`pythonprobr/palavras` is MPL-2.0 as the doc said (its tree also contains a bundled AGPL notice for
a dependency, which is not the word list's licence). `KDE/picmi`, `knetwalk` and `kubrick` carry
`LICENSES/GPL-2.0-or-later.txt`, so they are GPL-2.0-**or-later**, not bare 2.0.

## The upstream fork base

Our repo forked from `sidhant947/Puzzle` on **2026-06-07**. That day upstream was at
`d4d5d09` with **161 games** — which is exactly what we had, and confirms the fork point.
Upstream's `game_data.dart` still lists 205 games; that file is legacy. The registry they ship
from has 304, and Phase 2 merged all of them; Phase 3 adds the Tatham ports on top.

| | Value |
| --- | --- |
| Fork base | `d4d5d09` (2026-06-07), 161 games |
| Registry | `lib/data/game_registry.dart`, one `_metadata.dart` per game, 313 entries, 224 visible |
| Upstream HEAD when audited | `3a0928d` (2026-11-08), **304** registered games |
| Commits we never received | **100** |

Phase 2 merges from that base, so the diff is bounded and reviewable.

## Re-fetching

```bash
tool/fetch-reference.sh            # every code source, at its pinned commit
tool/fetch-reference.sh --assets   # also the image repos, un-checked-out
tool/fetch-reference.sh --check    # what is present, at which commit, and what is off its pin
```

Each clone is pinned, and the script prints the commit it landed on, so a port written from it
can cite the same commit. Adding a source means adding a line to `tool/reference-pins.tsv` with
its licence read from the repository at that commit, a row in SOURCES.md, and nothing else.
