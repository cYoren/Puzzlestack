# Content audit — 313 games, what is broken, thin, or missing

Measured against `main` at `e7c2475`, 2026-11-13. Every number here came from a script run on that
tree, and the rule that produced it is stated with it. Re-run the rule, get the number; if you get
something else, the tree moved and this file is stale.

This is a **work list, not a report**. 64 jobs in five severity bands. `docs/content-audit-tasks.jsonl`
is the same list machine-readable, one JSON object per line, so an orchestrator can assign a job
without pasting prose, and `docs/CONTENT-AUDIT.md` §"Suggested order" says which to take first.

Two rules for whoever picks these up:

1. **Every fix ships with a test that would have failed before it.** Every band-1 defect is content
   that was never checked against the game's own rules. A test is the only thing that stops the
   next one.
2. **Never fix thin content by deleting the game.** Grow the table. The number 313 is written into
   five files (`number-313-drift`) and the store copy is set from it.

---

## Status — 2026-11-13

The bands below are the work list as measured at `e7c2475`; this table is what has landed since,
so a reader can tell an open job from a fixed one. Every landed row shipped with the test the
job asked for, in `test/content/`.

| Job | PR | What changed |
| --- | --- | --- |
| `letter-bridge-table`, `word-ladder-unreachable`, `pangram-unwinnable`, `lighthouses-dead-fallback`, `nonogram-uniqueness`, `rhyme-master-nonrhymes`, `one-letter-shift-rule`, `chalk-and-talk-audio` | #47 | All eight band-1 defects. Seven got data or a generator that respects the rule; `chalk_and_talk` was reframed, because the app has no audio at all and the screen said YOU HEAR. |
| `content-invariants`, `guides-six-missing`, `game-id-resolution`, `number-313-drift` | #48 | The invariant family in `test/content/`; the six missing guides; `GameScope` so the shell resolves a game by id rather than by its localised title (four pairs collide, and those games recorded no time at all); the five store files are now held to the registry length. |
| `daily-pick-determinism`, `quick-play-pool`, `code-that-lies` | #49 | The daily pick is a hash order over the whole registry, so it no longer runs 23 MATH days in a row or depends on who is asking; quick play went from 12 games to 40; four engines lost a `languageCode` they never read. |
| `word-search-supply`, `find-word-dictionary`, `typing-speed-phrases`, `pool-word-surge`, `pool-cryptogram`, `pool-category-fluency` | #50 | 800 word-search words (was 105, with 16 unreachable), a curated 3,913-word answer list for `find_word` and friends, 46 typing phrases (one of the eight used to be about Flutter), 60 word-surge pairs, 24 cryptogram quotes, 11 categories. |
| `play-screenshots`, `ios-metadata` | #51 | Eight Play screenshots at 1080×1920 and eight App Store screenshots at 1290×2796, captured with `tool/screenshots.sh` on an emulator; `fastlane/metadata/ios/en-US/` exists for the first time. Sizes and the game count are asserted in `test/content/store_images_test.dart`. |

Two rows in the pool band are **not** thin content and should not be "fixed": `pool-tenner-grid`
and `pool-chimp-test` generate their boards, so the "2 baked items" and "1 baked item" the counter
reported are list literals, not puzzles. Re-run the counter with a generated-board exclusion before
working the rest of that band.

Still open, in the order this document suggests: the other 25 `pool-*` rows (verify each against
the same false-positive risk first), `crossword-supply`, `difficulty-ladder` +
`difficulty-persistence`, `one-answer-games`, `accessibility-boards`, `curation-list`,
`no-content-progress`, `hint-coverage-word-games`, `l10n-56-keys` + `l10n-de-orphan-keys`,
`shorebird-decision`, `paywall-decision`, and the 112 games with no test at all.

---

## 0. The failure pattern, in one paragraph

313 games, 229 test files, and **112 games with no test that mentions them (36%)**. The games that
*are* tested are the ones that came through the Tatham porting pipeline, because that pipeline
demanded a counted unique solution before a board could ship (`lib/core/deduction.dart`,
`countSolutions`, `test/engines/*`). The games that are **not** tested are the ones written
content-first: a hand-typed list in a `_pool`, a `nextInt()`, done. Every band-1 defect lives there.
The fix is not "write more tables" — it is "make each table declare its own invariant and check it in
a test", which is what a puzzle game should have had from the start (`content-invariants`).

---

## Band 1 — Broken: a player loses, or cannot win, through no fault of their own

### 1. `letter_bridge` — 31 of 61 puzzles are unguessable — `letter_bridge_engine.dart:5`

<sub>job id: `letter-bridge-table`</sub>

Rule: word1 + bridge = a word, and bridge + word2 = a word. **31/61 (51%) fail it.**

```
{'first': 'SUN',  'second': 'OWN', 'bridge': 'D'}   SUN+D = SUND  ✗
{'first': 'HAND', 'second': 'LE',  'bridge': 'Y'}   Y+LE  = YLE   ✗
{'first': 'BAR',  'second': 'K',   'bridge': 'K'}   K+K   = KK    ✗
{'first': 'CAR',  'second': 'RED', 'bridge': 'D'}   D+RED = DRED  ✗
```

Rule to reproduce: every entry, `(first+bridge)` and `(bridge+second)`, both must be in
`assets/chain_words.txt ∪ assets/find_word_words.txt`. 31 fail.

The file still contains **30 abandoned inline comments** of the form `// SUND, DOWN? No.` — the
author's working notes, shipped. That is why half the table is wrong: it was never finished.

**Fix:** rebuild the table from the app's dictionary, or delete the 31 broken rows; delete the
abandoned comments. Test: for every entry, both constructions are in the dictionary.
**Related:** one letter ends the run (`letter_bridge_provider.dart:68`), so the working half is the
game's entire lifetime — see `one-answer-games`.

### 2. `word_ladder` — one puzzle is impossible — `word_ladder_engine.dart:3934`

<sub>job id: `word-ladder-unreachable`</sub>

`{'start': 'GOOD', 'end': 'EVIL'}`. `EVIL` has **zero one-letter neighbours** in the game's own
3,894-entry dictionary. BFS from `GOOD` reaches 3,762 of the 3,888 plain 4-letter words; `EVIL` sits
in a component of size 1. A player can type valid words forever and never finish, and "reset" deals
the same puzzle.

The other 44 puzzles are solvable (same BFS; shortest solutions 1–7 steps). This is one bad row, not
a design flaw — but it is unrecoverable from inside the game.

**Fix:** delete the row. Test: BFS every `start → end` over the same dictionary, fail on any
unreachable pair.
**Also:** 7 dictionary entries are not words (`BLDG`, `BLVD`, `FTPS`, `PSST`, `PWNS`, `TBSP`, `XXXV`)
and 6 contain accented characters (`ABBÉ`, `CAFÉ`, `ÉLAN`, `ÉPÉE`, `FÊTE`, `ROUÉ`) that the on-screen
keyboard cannot emit (`word_ladder_screen.dart` rows are A–Z only), so they are unreachable cells.
Normalise to ASCII or drop.

### 3. `pangram_sprint` — one of five boards can never be won — `pangram_sprint_engine.dart:18`

<sub>job id: `pangram-unwinnable`</sub>

Win is `letters.length == 26` (`pangram_sprint_provider.dart`, `_updateState`). Board 4,
*"How vexingly quick balthazar bolden jumps gazing"*, has **25 distinct letters** — no `f`. Arrange
every word correctly and the game will not acknowledge it.

```
WINNABLE   26  The quick brown fox jumps over the lazy dog
WINNABLE   26  Pack my box with five dozen liquor jugs
WINNABLE   26  Sphinx of black quartz judge my vow
UNWINNABLE 25  How vexingly quick balthazar bolden jumps gazing
WINNABLE   26  Two driven jocks help fax my big quiz
```

`PangramSprintEngine.isPangram` already exists and is **never called**.

**Fix:** replace the board; call `isPangram` as a filter in `getRandomTask` and assert it for every
task in a test.

### 4. `lighthouses` — the hardcoded fallback board is dead — `lighthouses_engine.dart:77`

<sub>job id: `lighthouses-dead-fallback`</sub>

When generation fails 200 times the engine returns a fixed 5×5 clue grid. Under the game's own rules
(a ship may not touch a lighthouse, orthogonally or diagonally, and `_canPlaceShip` enforces it)
that board has **0 solutions** — exhaustive search over all subsets of its 20 free cells. Most of its
clue cells are boxed in, so their counts cannot be satisfied.

The fallback is not commonly reached (0 in 200 simulated games), but it is the *safety net*: the one
code path that exists for failure is the one that is certainly wrong. Note the module already has
`_hasUniqueSolution` (line ~100) — it is applied to generated boards only, never to the fallback.

**Fix:** compute the fallback with the solver and assert it, or retry generation with a relaxed
target. Test: 200 generated boards are unique *and* solver-completable.

### 5. `nonogram` — no uniqueness check; ~20% of boards have more than one answer

<sub>job id: `nonogram-uniqueness`</sub>

`nonogram_engine.dart:16` + `nonogram_provider.dart:39`

`generatePuzzle` fills an 8×8 grid with `random > 0.45`, derives row/col clues, ships. Nothing counts
solutions. **8 of 40 boards at the only size the game has are ambiguous**, confirmed by brute force
over the row-pattern cross-product (a pruned solver I also wrote agreed with the brute force on
40/40 cases, so the number is not an artefact of pruning).

Not a trap — the win check compares clues, not the original grid, so any valid answer wins. But it
breaks the house rule in `ROADMAP.md` ("every puzzle has exactly one solution") and a player can
"finish" a picture the generator never drew.

**Fix:** propose → `countSolutions` → ship only exactly-1, using the harness in `lib/core/deduction.dart`.
Test: 200 boards × 3 sizes, all unique.

### 6. `rhyme_master` — 8 of 56 given words do not rhyme — `rhyme_master_engine.dart:8,10,13`

<sub>job id: `rhyme-master-nonrhymes`</sub>

```
LIGHT: WHITE                      ✗
BLUE : VIEW, NEW, TWO, ZOO        ✗ (4 of its 8)
COOL : RULE, FUEL, MULE           ✗ (3 of its 8)
```

`isRhyme` only checks membership of the hand-written list, so the game confidently accepts a wrong
answer. 3 of the 7 sets are affected. 4 sets are clean (`CAT`, `PLAY`, `SING`, `BOLD`).

**Fix:** replace the non-rhymes; test phoneme tails rather than eyeballing. If a set cannot be filled
with real rhymes from the app dictionary, drop it — 4 honest sets beat 7 with 3 that lie.

### 7. `one_letter_shift` — the stated rule is false for 24 of 26 puzzles

<sub>job id: `one-letter-shift-rule`</sub>

`one_letter_shift_engine.dart:4`, subtitle in `app_en.arb` (`oneLetterShiftSubtitle`)

The subtitle promises "Transform one word into another with **one letter change**". Measured against
the table, **24 of 26 pairs are not a one-letter change** — only `BREAD→TREAD` and `TRAIN→BRAIN` are:

```
HEART → STARE   H/S  E/T  A/A  R/R  T/E    3 positions differ
PLANE → LEARN   4 positions differ
STORE → OTHER   4 positions differ
```

Of the 24, two are pure rotations (`EARTH→HEART`, `SWING→WINGS`) and 22 are plain rearrangements.
So a player who follows the rule as written changes one letter, is told they are wrong, and has no
way to know a rearrangement is expected — the only real clue is the hint text.

Two entries carry abandoned working notes, the same tell as `letter_bridge`:

```dart
{'start': 'STORE', 'end': 'ROSET', 'hint': 'A decorative knot'}, // No, ROSETTE?
{'start': 'SWING', 'hint': 'To move to and fro', 'end': 'WINGS'}, // No, 5 to 5.
```

`ROSET` is Scrabble-only (in the app dictionary, not in a standard word list) and the author's own
comment doubts it. The `SWING` entry is also written with a **different field order**
(`start, hint, end`) from every other row, so any parser or refactor that assumes one order silently
drops it.

**Fix:** decide what the game is. Either make every pair a true one-letter change (then the subtitle
is honest and the puzzle is what it says), or rename it and rewrite the subtitle as "find the word
hidden in this one's letters". Delete the two abandoned comments, replace `ROSET`, and normalise the
field order. Test: every pair satisfies the rule the subtitle states, and every row parses with one
field order.

### 8. `chalk_and_talk` — the premise is a lie; the app has no audio at all

<sub>job id: `chalk-and-talk-audio`</sub>

`chalk_and_talk_screen.dart:165`

The screen says `YOU HEAR: "CAT"` and asks you to type it past a distractor word on a chalkboard.
It is a Stroop-by-subtitle. `pubspec.yaml` has **no** audio/TTS/sound dependency and
`grep -rn "SystemSound|audioplayers|just_audio|flutter_tts|soundpool" lib` returns **0 hits
app-wide**. The only feedback channel in Puzzlestack is haptics (278 game files use
`HapticFeedbackUtil`).

This one is a product decision, not a bug. Three honest exits:

- **Ship audio** — `flutter_tts`, or bundle ~20 one-word clips (≈10 KB each). The only option that
  delivers what the copy promises.
- **Re-frame** — rename and rewrite as a visual interference task, which is what the code does.
- **Retire** — 20 words, one answer ends the run (`one-answer-games`).

Precedent to copy if audio is off the table: `dual_coding` already encodes pitch as three distinct
haptic patterns (`_triggerPitchHaptic`) plus a visual indicator, and is honest about being non-audio.

---

## Band 2 — Thin: pools a player exhausts

Counted as **top-level elements of each literal** (brace/bracket matching with a trailing-comma
guard, then spot-checked against the file). `target` is how many rounds one run consumes.

### 9. Pools one run consumes

<sub>job ids: `pool-tenner-grid` … `pool-chimp-test` (28 jobs, band 2)</sub>

| Game | Items | One run | File |
| --- | --- | --- | --- |
| `tenner_grid` | **2** | 1 | `tenner_grid_screen.dart:32` |
| `story_builder` | **3** | **3** (`_targetScore = 3`) | `story_builder_screen.dart:27,54` |
| `word_surge` | **15** | **15** (`targetScore = 15`) | `word_surge_engine.dart:_wordPairs` |
| `set_theory_venn` | **8** | **8** (`targetScore = 8`) | `set_theory_venn_engine.dart:_templates` |
| `chimp_test` | 1 layout | 3 rounds | `chimp_test_screen.dart` (fixed 4×4, 9 numbers) |
| `pangram_sprint` | 5 (4 winnable) | 1 | `pangram_sprint_engine.dart:_tasks` |
| `rhyme_master` | 7 (4 valid) | 1 | `rhyme_master_engine.dart:_rhymeSets` |
| `word_wheel` | 6 | 1 | `word_wheel_screen.dart:puzzles` |
| `cryptogram` | 6 | 1 | `cryptogram_engine.dart:_quotes` |
| `semantic_association` | 8 | 4 | `semantic_association_screen.dart:_puzzlePool` |
| `room_inspector` | 8 | 1 | `room_inspector_screen.dart:_roomPool` |
| `binary_matrix_rank` | 8 | 1 | `binary_matrix_rank_engine.dart:samples` |
| `typing_speed` | **8** | 1 | `typing_speed_engine.dart:_phrases` |

`story_builder` and `word_surge` and `set_theory_venn` are the worst shape: one run equals one
lifetime. `typing_speed` has 8 sentences, so you retype one inside three games, and one of them is
`"FLUTTER IS A POWERFUL FRAMEWORK FOR APPS"` — a developer placeholder shipped to players.

### 10. Pools in the 10–20 range

<sub>job ids: `pool-tenner-grid` … `pool-chimp-test` (28 jobs, band 2)</sub>

`anagram_definition` 10 · `definition_dash` 10 · `homophone_hunt` 11 · `affix_factory` 10 ·
`spoonerism_solver` 11 · `etymon_oddball` 11 · `cognate_catch` 13 · `palindrome_builder` 13 ·
`portmanteau_split` 14 · `compound_connect` 15 · `oxymoron_hunt` 18 (4 pairs per board → ~4 distinct
boards) · `category_fluency` 5 · `word_grid_connection` 12 categories × 8 words · `word_snake_trail`
10 · `typoglycemia_decoder` 10 · `chalk_and_talk` 20 · `one_letter_shift` 26 · `word_ladder_step` 8.

### 11. Healthy tables, listed so nobody measures them twice

`context_clues` 200 · `grammar_sort` 130 · `grammar_police` 99 · `semantic_link` 84 ·
`spelling_sprint` 50 · `memory_palace` 50 · `verbal_analogies` 50 · `semantic_distance` 31 ·
`silent_letter_search` 28 · `letter_bridge` 61 (30 valid — `letter-bridge-table`) · `word_ladder` 45 puzzles over a
3,888-word dictionary · `word_ladder_step` is 8 ladders but it is a single-round game.

### 12. `crossword` — board is 7–10 wide, longest word is 6, placer stalls at 8

<sub>job id: `crossword-supply`</sub>

`crossword_provider.dart:58`, `crossword_engine.dart`, `assets/crossword_data.json`

1,535 clues: **315 three-letter, 848 four, 358 five, 14 six** — and nothing longer. Board size is
random 7–10. The placer wants up to 15 words and breaks at 10. Reproducing its exact placement rules
in Python (10 boards per size):

```
7x7 : 6–8 words placed
8x8 : 8–9
9x9 : 9–11
10x10: 10–11
```

A 10×10 board is mostly empty and shows 8–11 clues where it asks for 15. Cause is the data, not the
placer: a 6-letter ceiling cannot build a big grid. 13 words are duplicated, 8 clues are duplicated.

**Fix:** grow the JSON with 7–12 letter entries; un-duplicate; have the placer report its word count
and retry below the board's expectation.

### 13. `word_search` — 5 boards before every word repeats; 16 words unreachable

<sub>job id: `word-search-supply`</sub>

`word_search_provider.dart:55`

105 words in `assets/word_search_words.txt`; filter `4 ≤ len ≤ 8` leaves **89 usable**; 15 per board
→ **5 boards** before the pool is dry.

16 words of 9–10 letters are permanently unreachable by that filter: `ADVENTURE, BUTTERFLY,
CHOCOLATE, DRAGONFLY, HAPPINESS, LIGHTNING, ORCHESTRA, PLAYGROUND, SEA SHELL, SNOWFLAKE, SPECTACLE,
STARLIGHT, TELEPHONE, TELESCOPE, WATERFALL, WONDERFUL`. Somebody wrote them intending them to be
used. `SEA SHELL` also contains a space and would corrupt a grid.

**Fix:** raise the filter to 10, confirm the generator handles it, fix or drop `SEA SHELL`, then grow
the list to a few hundred. Cheapest content win in the app — it is a text file.

### 14. `find_word` / `word_scramble` / `missing_vowels` — the dictionary is 74% obscure

<sub>job id: `find-word-dictionary`</sub>

All three load `assets/find_word_words.txt` (14,855 five-letter words) and pick a random target.

**74% of entries are not in a standard word list** (`/usr/share/dict/cracklib-small`). The first ten
a player can be handed:

```
aahed  aalii  aapas  aargh  aarti  abaca  abaci  aback  abacs  abaft
```

Six have no vowel under the usual set (`CRWTH`, `CWTCH`, `GRRLS`, `GRRRL`, `PFFTT`, `PHPHT`). This is
a Scrabble word list, not a player-facing dictionary. For a Wordle clone that is fatal in both
directions: the answer can be a word nobody has seen, and guess validation accepts junk while
rejecting nothing reasonable (the 24 everyday guesses I tried all pass, so the problem is the answer
pool, not the validator).

**Fix:** split the asset — `find_word_answers.txt` (curated ~2–3k common words) for targets and
`find_word_valid.txt` (the full list) for validation. See `code-that-lies` for the dead `languageCode`
parameter these engines carry.

---

## Band 3 — Missing: what the catalog promises and does not have

### 15. Six games have no guide, and they are the six newest

<sub>job id: `guides-six-missing`</sub>

`lib/data/game_guides.dart` has **307 keys for 313 games**. Missing:

```
cube   inertia   map   netslide   same_game   signpost
```

All six are the Tatham ports from `ROADMAP.md` Phase 3. The consequence is worse than a blank page:

- `GameScaffold`'s info button falls back to a generic dialog with a `detailedRules` map of 17 games
  (`game_scaffold.dart:307`, used at `:399`). None of the 17 is one of these six, so the dialog shows
  the subtitle under a "RULES & CONDITIONS:" heading with nothing beneath it.
- `launchGame` (`game_launch.dart:23`) only shows rules first when `gameGuides.containsKey(id)`; line
  38 marks the game "seen" regardless. So these six **never** get a first-play rules page, and the
  flag that would have shown it is burned silently.

**Fix:** add six entries. The header says `// THIS FILE IS AUTO-GENERATED. DO NOT EDIT MANUALLY.`
and **the generator is not in the repo** (it lived under `guide/`, deleted; last touched in
`3b9e4dd`). Either write them by hand and correct the header, or restore the generator. Do not leave
a file claiming "generated" with no generator — the next agent will not dare touch it, and these six
stay missing.

Content to write: `inertia` (gems/mines, slide until a wall), `map` (four-colouring — *say that any
valid colouring wins*, it is the one puzzle that is supposed to have many answers), `cube` (roll,
bottom face swaps with the square, six blues), `netslide` (slide rows/columns of pipes, walls block),
`signpost` (arrows point along a ray, not at a neighbour), `same_game` (tap 2+ connected same-colour
blocks).

### 16. 56 translation keys missing from every non-English locale

<sub>job id: `l10n-56-keys`</sub>

All 22 non-English `.arb` files miss the same 56 keys; `de` misses 72.

`app_en.arb` 1,823 keys (non-`@`) · every other locale 1,767 · `de` 1,753.

One extra, found while checking: **`de` carries 2 keys `en` does not have** — `kurodokoWinTitle` and
`kurodokoWinMessage`. `flutter gen-l10n` generates from `app_en.arb` only (see `papercuts.md`), so
those two German strings are unreachable: someone translated a key that was never added to English.
Either add the pair to `app_en.arb` (and every other locale) or delete the German orphans.

They are the titles, subtitles, win text, how-to-play and HUD labels for the twelve newest games:

```
cube 8   map 7   inertia 8   netslide 7   signpost 7   same_game 5
magnets 2  dominosa 2  skyscrapers 2  futoshiki 3  tents_and_trees 3  lights_out 2
```

The exact key list is in `docs/content-audit-tasks.jsonl` (`l10n-56-keys`) so nobody regenerates it.
Effect: those twelve show **English** in Portuguese, Spanish, Japanese, Arabic. `flutter gen-l10n`
falls back silently, so nothing breaks — it just looks unfinished exactly where it is newest.

### 17. Guides are English-only and have no localisation path

<sub>job id: `guides-i18n-decision`</sub>

`game_guides.dart` is 307 English guides in Dart string literals; the app has 23 locales; guide text
is the longest player-facing prose in the app and none of it goes through `.arb`. 22 lines contain
non-ASCII and all of them are `• ² √ —` in maths descriptions — evidence the text was authored once
and never touched.

**Decide and record the ladder** in `ROADMAP.md`: (a) move guides into `.arb` (307 × 5 fields × 23
locales — heavy), (b) accept English guides and say so in the store copy, or (c) translate
`objective` + `controls` only (2 fields, ~2 lines each) where comprehension actually fails.
Recommend (c).

### 18. Four games share a title, and screen→game resolution is by title

<sub>job id: `game-id-resolution`</sub>

`game_scaffold.dart:66` — `_resolveGame` matches
`game.titleGetter(context).toUpperCase() == widget.title`; screens do not pass their id.

| Locale | Title | Games | Resolves to |
| --- | --- | --- | --- |
| en | "Silhouette Match" | `silhouette_match`, `silhouette_match_ortho` | **`silhouette_match_ortho`** (index 28 of 313) |
| en | "Word Ladder" | `word_ladder`, `word_ladder_step` | **`word_ladder`** (index 154) |
| pt, es | "Combinação de cores" | `color_match`, `color_word_match_up` | `color_match` (index 147) |
| de | "Perspektivwechsel" | `perspective_taking`, `perspective_shift_view` | `perspective_taking` (index 73) |

So opening plain `silhouette_match` gets the *ortho* guide and the *ortho* assist buttons, and
`word_ladder_step` gets `word_ladder`'s. Worse and silent: `GameScaffold.initState` starts
`GameClock` under the **resolved** id, while the screen calls
`completeGame('silhouette_match')` / `completeGame('word_ladder_step')`. `GameClock.stop` returns
`null` for an id that was never started, so **those two games never record a time or a personal
best**. (`fr` and `it` are clean.)

**Fix:** pass the game id into `GameScaffold` (or an inherited widget) and resolve on id. Distinct
copy is only a stopgap — it does not survive the next translation.

---

## Band 4 — Structural: one fix, many games

### 19. 215 of 313 games have no difficulty control of any kind

<sub>job id: `difficulty-ladder`</sub>

18 games have any difficulty mechanism: the 16 Tatham ports (`cube dominosa futoshiki galaxies
inertia kurodoko lights_out magnets map netslide pegs same_game signpost skyscrapers tents_and_trees
twiddle`) plus `counting_sheep` and `mental_calendar`. Of those, **`mental_calendar` has a
`Difficulty` enum, reads it, and exposes no picker** (`grep -c "Difficulty.values"` → 0 in its
screen), so it is permanently Easy.

The classics are frozen at one size:

```
masyu        _size = 4
hitori       size = 5
nurikabe     size = 5
fillomino    size = 5
lighthouses  size = 5
heyawake     defaultSize = 5
tapa         defaultSize = 5
yajilin      defaultSize = 5
shikaku      gridSize = 6
nonogram     defaultSize = 8
sudoku       fixed 35 clues
minesweeper  10×8, 12 mines (15%), fixed
```

Cheap to fix because the generators already take the parameter and are only ever called with the
default: `generateLevel({int size = 5})` in `hitori`, `nurikabe`, `fillomino`, `lighthouses`.

**Do in this order:** (1) a shared `DifficultyChips` widget and wire size into the five puzzles that
already accept one; (2) a 3-tier ladder per classic — `masyu` 4→6→8, `shikaku` 6→8→10, `nonogram`
5→8→12 with `nonogram-uniqueness`'s uniqueness gate, `minesweeper` 8×8/12 · 12×10/25 · 16×12/45; (3) sudoku tiers as
clue counts 45/35/28 gated on `solvingLevel` from `lib/core/deduction.dart`.

### 20. Difficulty is never remembered

<sub>job id: `difficulty-persistence`</sub>

`grep -rn difficulty lib/data lib/providers` returns only guide prose. Every game resets to its
default tier on restart; a player who picks Hard is back on Easy next launch. Store the chosen tier
per game in the existing `game_stats` Hive box beside `hasSeen`.

### 21. Solve/hint covers 20 games

<sub>job id: `hint-coverage-word-games`</sub>

`lib/ui/core/assist/game_assist.dart` has 20 `case` arms. 19 games implement a `PuzzleBoard` and all
19 are covered, plus `akari` — the board-contract games are fine, and this is already documented in
`docs/PLAYABILITY-AUDIT.md`. But the word games (`word_ladder`, `letter_bridge`, `find_word`,
`word_search`, `word_wheel`) all have a checkable next step and none has a hint. Audit pass, not a
rewrite.

### 22. `Daily Pick` is not the same for everyone, and it streaks by category

<sub>job id: `daily-pick-determinism`</sub>

`game_categories.dart:136` — `dailyPick` seeds on the date and indexes the pool:
`pool[seed % pool.length]`. Two problems:

- `discovery_home_screen.dart:60` calls `dailyPick(exclude: hiddenSet)`, so the pool shrinks per
  player and the "same for everyone" promise in the doc comment is false the moment anyone hides a
  game.
- The pool is registry order, which is grouped by category: the first 14 entries are 3 LOGIC then
  11 MATH. Over the next 120 days the draw contains runs of **23 consecutive MATH days**, 16 MEMORY,
  12 MATH, 12 SPATIAL, 10 ATTENTION.

**Fix:** seed a *stable* shuffled order (or hash the id) instead of relying on registry order, and
draw the daily pick from the full registry so it is genuinely shared.

### 23. The reel has no curation at all

<sub>job id: `curation-list`</sub>

`lib/data/curation.dart` — `feedBlocklist` ships **empty** with `// Paste the curation list here.`,
so the Shuffle feed, Daily Pick, Quick Play fallback and `randomGame` all serve the whole 313,
including the 38 one-answer games in `one-answer-games` and the 113 games with no test. `test/curation_test.dart`
keeps typos out of a list that does not exist yet. Deciding the list is a human call (memory:
"Gus judges the puzzles, not me"); wiring it is done.

### 24. `Quick Play` is 12 games out of 313

<sub>job id: `quick-play-pool`</sub>

`game_categories.dart:102` — `_quickPlayIds` lists 12 ids, all valid. "Under 2 min" is a real promise
covered by 4% of the catalog. The 38 one-answer games (`one-answer-games`) are the natural pool; most are not on
the list.

### 25. Nothing is persisted about content progress

<sub>job id: `no-content-progress`</sub>

There is no completion state per puzzle anywhere (`game_stats` records solves/time per **game**, not
which puzzle index). Every pool repeats silently and a player cannot tell they have seen everything.
Combine with `pool-* (28 jobs)`: `story_builder` serves the same 3 stories forever with no signal.

---

## Band 5 — Platform, store, and the things that will bite the next agent

### 26. No accessibility at all: 3 `Semantics` in the whole app, none in a game

<sub>job id: `accessibility-boards`</sub>

`grep -rn "Semantics(" lib` → **3 occurrences, all in `lib/widgets/tangible.dart`** (they label
buttons). **0 of 313 game directories mention `Semantics` or `semanticLabel`.**

There is also a `DesignSystem.semanticLabel` helper at `lib/utils/design_system.dart:201` that is
**defined and never called** — the intent to label things existed and was never wired, which is the
same story as the guide text.

**50 screen files paint a `CustomPaint` board (150 `CustomPaint` sites)**, and every one is opaque to
a screen reader; `PuzzleBoardView` passes no semantics for a board or a cell.

`docs/GAME_DEV_GUIDE.md:275` tells contributors to "Add semantics: include `semanticsLabel` on
interactive elements" — advice the codebase itself does not follow. For an app whose entire premise
is "313 games that train your brain", being unusable with TalkBack/VoiceOver is a store-listing and a
moral problem, and Google Play's accessibility guidance now expects basic support.

**Do:** add a board-level `Semantics` to `PuzzleBoardView` (label = game + state summary), then either
per-cell labels for the 19 board games or an explicit, documented decision that drag-only boards are
excluded and each such game gets a text alternative. Start with the 19 board games; they share one
widget.

### 27. Play listing is missing required assets

<sub>job id: `play-screenshots`</sub>

`fastlane/metadata/android/en-US/images/` contains `icon.png` and `featureGraphic.png` and **no
`phoneScreenshots/` directory at all**. `RELEASE.md:92-101` describes files that do not exist:
`screenshots/aso-refresh/final/play/`, `.../ios/`, `.../framed/`, `screenshots/raw/`. Every one of
those paths is missing; `screenshots/` holds only `README.md`, which also describes the canonical
layout that is not there.

Play requires at least 2 phone screenshots. `tool/screenshots.sh` exists (1.9 KB) but has not been
run to produce them.

### 28. iOS has no store metadata whatsoever

<sub>job id: `ios-metadata`</sub>

`fastlane/metadata/` has `android/` only. No `ios/` directory, no listing text, no screenshots, no
`fastlane/Deliverfile`. iOS ships from the same version and copy per `RELEASE.md:124`, but there is
nothing in the repo to upload. If the App Store release is real, this is the largest gap in it.

### 29. `shorebird.yaml` points at a dead app id, and the updater is not a dependency

<sub>job id: `shorebird-decision`</sub>

`shorebird.yaml:8` has `app_id: bf46de55-01ce-4744-97e2-d4cf38e4d6cc`; `shorebird_code_push` is not in
`pubspec.yaml`, and `RELEASE.md` notes the id predates the rename. Content fixes in band 2 are
exactly what OTA is for (a dictionary grows, every install gets it without review). Either finish it
or delete the file; an inert config with a stale id is worse than none.

### 30. The paywall is decided and not built

<sub>job id: `paywall-decision`</sub>

Memory (2026-11-11): every puzzle playable once, some free forever, gate replays and volume, never
first contact. `pubspec.yaml` has **no** `in_app_purchase` / `purchases_flutter`. Nothing exists.
Not content, listed so nobody re-decides it.

### 31. `pubspec.yaml` is at `1.0.14+15` — coordinate with the open deck PR

<sub>job id: `sequence-deck-pr`</sub>

`feat/deck-feed` (PR #40, 4 commits, open) is 313-game parity plus the deck rebuild and edits
`game_scaffold.dart`, which `game-id-resolution` also edits. Land the deck first or branch content work from
`main` and rebase; do not start content work on top of it.

### 32. Docs drift

<sub>job id: `docs-drift`</sub>

- `docs/GAME_DEV_GUIDE.md:3` says "how to add a new puzzle game to **PUZZLE**" (Phase 0 renamed it);
  its file tree omits `*_board.dart`, now the recommended pattern for any grid puzzle.
- `ROADMAP.md:220` says "305 entries in `game_guides.dart`" — 307. `:217` says "304
  `_metadata.dart` files" — 313.
- `ROADMAP.md:25` says the store copy is set from 313, which is true; see `number-313-drift`.

### 33. The number 313 is hardcoded in five places

<sub>job id: `number-313-drift`</sub>

`README.md:3`, `fastlane/metadata/android/en-US/title.txt`,
`fastlane/metadata/android/en-US/full_description.txt`, `docs/index.html:7,28`,
`web/manifest.json`. Adding or removing a game means editing all five. Add a test asserting the
registry length matches those files, so it cannot drift and nobody is tempted to delete a thin game
to make a number tidy.

### 34. 38 games end the run on a single answer

<sub>job id: `one-answer-games`</sub>

Detected as: a provider that loads one task, sets `isGameOver`/`isGameWon` on the answer, has no
score and no next-round call:

```
affix_factory anagram_definition attentional_blink balance_scale category_fluency choice_reaction_time
cognate_catch collatz compound_connect double_n_back dual_mirror etymology_origin etymon_oddball
letter_bridge letter_frequency_scan magic_squares mandala_recall math_guess missing_vowels
object_shuffle odd_rotation one_letter_shift operation_span palindrome_builder path_recall
phonetic_guess pixel_mimic running_memory_span silent_letter_search sopt spoonerism_solver
symbol_logic target_10 target_number typing_speed visual_statistical_learning
wisconsin_card_sorting word_scramble
```

For a pool of 10–20 (the pool jobs) that is a 15-second game. Two cheap fixes, both already used
elsewhere in the codebase: a `targetScore` + next-round loop (`word_surge`, `verbal_analogies`,
`set_theory_venn` do it), or a timed run over the whole pool (`spelling_sprint`, `grammar_sort`).

### 35. Code that says one thing and does another

<sub>job id: `code-that-lies`</sub>

Cheap, and each one misleads the next agent:

- `find_word_engine.dart:20`, `word_scramble_engine.dart:19`, `missing_vowels_engine.dart:18`,
  `crossword_engine.dart:46` — take `[String languageCode = 'en']` and **ignore it**; `find_word`
  even keys a cache by it. Implement per-locale lists or delete the parameter.
- `lighthouses_engine.dart:22` — `clues[r][c] = 0; // Placeholder` on a value overwritten later
  (`lighthouses-dead-fallback`).
- `word_ladder` keyboard is A–Z while the dictionary holds six accented entries (`word-ladder-unreachable`).
- `word_grid_connection_screen.dart` writes the literal `'word_grid_connection'` into HUD variables
  in a debug path (6 occurrences).
- `nonogram_provider.dart:39` — `// Increased for more challenge` on a value nothing can change
  (`difficulty-ladder`).
- `pangram_sprint` ships `isPangram` unused (`pangram-unwinnable`).

---

## Suggested order of work

Each row is one PR-sized unit. Later rows do not depend on earlier ones except where noted.

| # | Job | Why first |
| --- | --- | --- |
| 1 | `letter_bridge` table + test (`letter-bridge-table`) | half a game is broken; ~20 lines of data |
| 2 | `word_ladder` bad row + BFS test (`word-ladder-unreachable`) | one row, one test, kills a class |
| 3 | `pangram_sprint` board + `isPangram` (`pangram-unwinnable`) | the function already exists |
| 4 | `lighthouses` dead fallback (`lighthouses-dead-fallback`) | the safety net is the broken part |
| 5 | Content-invariant test family (`content-invariants` below) | makes 1–4 permanent and sizes everything later |
| 6 | Title→id resolution (`game-id-resolution`) | fixes guides, assists and *timing* for 4 games |
| 7 | Six missing guides (`guides-six-missing`) | the last unguided games in the catalog |
| 8 | 56 l10n keys + 2 de orphans (`l10n-56-keys`, `l10n-de-orphan-keys`) | one mechanical pass across 22 files |
| 9 | `word_search` + `find_word` pools (`word-search-supply`, `find-word-dictionary`) | text files; biggest replay win |
| 10 | `crossword` data + placer (`crossword-supply`) | needs data before code |
| 11 | `nonogram` uniqueness (`nonogram-uniqueness`) | the only real solver job in band 1 |
| 12 | Thinnest pools (the 28 `pool-*` jobs) | removes the worst repeats |
| 13 | Difficulty ladder for the classics (`difficulty-ladder`, `difficulty-persistence`) | the largest single content gain |
| 14 | One-answer games (`one-answer-games`) | converts 38 15-second games into runs |
| 15 | Accessibility on the board contract (`accessibility-boards`) | one widget, 19 games |
| 16 | Daily Pick determinism + curation (`daily-pick-determinism`, `curation-list`, `quick-play-pool`) | the front door |
| 17 | Store assets, iOS metadata, Shorebird, paywall (`play-screenshots`, `ios-metadata`, `shorebird-decision`, `paywall-decision`) | release-critical |
| 18 | Hygiene and docs (`docs-drift`, `number-313-drift`, `code-that-lies`) | cheap; keeps the tree honest |

### The content-invariant test family — `content-invariants`

One `test/content/<topic>_test.dart` per kind of table, each asserting the game's own rule:

- **word tables are playable** — letters form words, ladders are reachable, pangrams are pangrams;
- **generated puzzles are solvable and unique** — the `lib/core/deduction.dart` harness;
- **every pool has ≥ 3× the rounds one run consumes, and no duplicate answers**;
- **every game has a title, a subtitle and a guide**, and `gameGuides` has no orphan keys;
- **the registry length equals the number in the five store files** (`number-313-drift`).

The last three would have caught `guides-six-missing`, `l10n-56-keys`, `game-id-resolution` and
`number-313-drift` before they shipped. This family is the single highest-leverage item in this
document.

---

## Reproduction

Everything above came from scripts run against `e7c2475`. The shapes, so each claim can be re-checked:

```bash
# registry, guides, categories, missing l10n keys
python3 - <<'PY'
import re, glob, json
reg = open('lib/data/game_registry.dart').read()
s = reg[reg.find('_buildGameList()'):]          # 313 entries, in display order
# ids via each lib/ui/features/games/*/*_metadata.dart "id:" field
PY

# letter_bridge playability: for each {'first','second','bridge'},
#   (first+bridge) and (bridge+second) must both be in
#   assets/chain_words.txt ∪ assets/find_word_words.txt

# word_ladder reachability: BFS over the '_dictionary' literal, edit distance 1,
#   for every {'start','end'} pair

# pangram winnability: len(set(letters of the concatenated words)) == 26

# nonogram uniqueness: row-pattern cross-product brute force, cap 2, 40 boards at 8x8

# lighthouses fallback: exhaustive subsets of the free cells of the hardcoded grid,
#   applying the no-touch rule and the clue counts

# thin pools: bracket-match each '_pool' / '_tasks' / '_puzzles' literal and count
#   top-level elements, guarding the trailing comma

# crossword supply: len(word) histogram of assets/crossword_data.json, then the
#   placement rules in crossword_engine.dart replayed in Python

# title collisions: per locale, title -> [ids]; flag any title with > 1 id and
#   report registry index order (first match wins in GameScaffold._resolveGame)
```

`docs/content-audit-tasks.jsonl` carries one JSON object per job:

```json
{"n": 1, "id": "letter-bridge-table", "severity": 1, "kind": "content-bug",
 "title": "letter_bridge: 31 of 61 puzzles are unguessable", "files": ["…"],
 "detail": "…", "fix": "…", "verify": "…", "skill": "tdd", "blocks": [], "estimate": "30m"}
```

`severity` is the band (1 = broken, 5 = hygiene). `verify` is the test that must exist. `blocks`
names jobs that should land after this one. `skill` names the local skill to load (`tdd`, `pr`,
`omarchy`). `estimate` is a rough size, not a commitment.
