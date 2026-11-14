# The bar

What a game must be to be dealt in the feed. This is the gate for the Deck, the brief for any
agent fixing or adding a game, and the checklist for review. Direction: [PRODUCT.md](PRODUCT.md).

**It supersedes** the rule in `CONTENT-AUDIT.md` that a game is never deleted. A game that
cannot reach the Library floor below is archived: hidden from the app, kept in the repo.

## Tiers

| Tier | Where it appears | Must pass |
| --- | --- | --- |
| **Deck** | the feed, Daily Five, the Library | all ten checks |
| **Library** | its room and search only | the Library floor |
| **Archive** | nowhere in the app; code, tests and strings stay in the repo | it compiles and its tests pass |

Nothing is deleted. An archived game is raw material: it can come back as a mode of another
game, be rebuilt into a real puzzle, or stay on the shelf. It costs a compile and nothing else.

## Tags

Every game carries one **origin** tag, so an agent can find the lab tasks and worksheets in
one query, whatever tier they are in.

| Tag | Meaning |
| --- | --- |
| `puzzle` | has a solution reached by reasoning, or is a real game with decisions |
| `lab` | a cognitive psychology task (span, Stroop, n-back, cueing) |
| `worksheet` | school arithmetic or coursework with a timer |
| `quiz` | pick-one questions about knowledge or vocabulary |

Archived games also carry a **reason**: `twin` (absorbed by a keeper), `no-game` (no decision
to make), `broken-concept` (cannot work in this app, for example needs audio).

A `lab`, `worksheet` or `quiz` game may be in the Deck only as a Snap or Word card that passes
all ten checks. Most will not; that is what the tag is for.

The verdict for each of the 313 is in [CATALOG.md](CATALOG.md). `lib/data/curation.dart` is
the code copy of the Deck list and a test keeps the two honest.

## The ten checks (Deck)

Each is yes or no. Nine out of ten is Library.

1. **There is a decision.** A player who thinks does better than one who taps everything. A
   four-option quiz with random distractors fails. A pure reaction test passes only as a Snap
   card (below).
2. **It is fair.** Solvable from what is on screen. Where the genre implies one answer
   (Sudoku, Nonogram, Slitherlink, every Nikoli type) the generator proves exactly one with
   `lib/core/deduction.dart`. No step requires a guess. Word answers are common words; the
   accepted-guess list may be wide, the answer list is curated.
3. **Five-second read.** The goal fits in 60 characters of plain language and is true. The
   first legal move can be found by touching the board. No term from a psychology paper, no
   ALL CAPS subtitle, no rules page needed.
4. **About a minute.** At feed size a first-timer finishes in 30 to 120 seconds. Hard cap 180.
   Quiz-style games are a **run** of 5 to 8 rounds with one result, never a single answer.
5. **It stays fresh.** Generated, or a pool of at least 200 rounds and 30 distinct sessions.
   The same puzzle is never dealt twice within 30 days on one device.
6. **It is this app.** Tokens from `DesignSystem`, the five verbs for haptics, the five motion
   moves, 44dp targets, no overflow at 320dp, correct in light and AMOLED dark. New and rebuilt
   boards use the board contract (`PUZZLE_STYLE.md`); an old widget-grid game may stay if it
   passes everything else and looks native.
7. **It does not fight the swipe.** Vertical swipes on the card header and footer always deal.
   Drags that start on the board belong to the board. Fully playable by tap alone.
8. **It ends well.** Undo and restart always work. A mistake is shown when it is made, or the
   game has no mistakes. Solved state is unmistakable, the result is one line, then NEXT.
   There is no state from which the puzzle cannot be finished.
9. **It has an honest name.** What a stranger would call it or search for: "Rule Finder", not
   "Wisconsin Card Sorting". The id may stay; the title may not.
10. **It is tested against its own rule.** A test that fails if the content breaks the game:
    solver agrees with generator, every pool row is winnable, no duplicate answers. Plus the
    320dp and dark smoke test every game already has.

## The Library floor

A game stays visible in the app only if all of these hold; otherwise it is archived:

- it can always be won or finished (check 8, last sentence);
- it has a test against its own rule (check 10);
- it is not a twin of a game that does the same thing better;
- it has an honest name and a guide;
- it lays out at 320dp in both themes.

## Card kinds

Every Deck game declares one. The deal uses it for rhythm ([FEED.md](FEED.md)).

| Kind | What | Target time | Share of a deal |
| --- | --- | --- | --- |
| **Think** | logic, number and spatial puzzles with a solution | 60 to 120 s | about half |
| **Word** | word puzzles; dealt only in a language the game has content for | 30 to 90 s | about a quarter |
| **Snap** | reflex and memory micro-games, scored runs | 20 to 45 s | at most a quarter, never two in a row |

## Feed size

The feed size is the smallest board on which the puzzle still has its idea. Starting points:

| Game type | Feed size | Library sizes |
| --- | --- | --- |
| Sudoku | 4x4 and 6x6 | 9x9 at three clue tiers |
| Nonogram | 5x5 | 8, 10, 12, 15 |
| Latin-square types (Futoshiki, Skyscrapers, KenKen) | 4x4 | 5, 6, 7 |
| Region and loop types (Slitherlink, Masyu, Nurikabe, Hitori, Shikaku, Tapa, Yajilin) | 5x5 | 7, 8, 10 |
| Minesweeper | 6x6, 5 mines, first tap opens an area, no forced guess | 8x8, 12x10, 16x12 |
| Crossword | 5x5 mini | 9x9, 13x13 |
| Word Search | 6x6, 4 words | 10x10, 14x14 |
| Sliding and sorting (Klotski, Water Sort, Slide) | solvable in 15 moves or fewer | longer |
| Snap runs | 5 to 8 rounds | endless, with a personal best |

Measure it: time three cold plays at the chosen size and write the median in the PR. If it is
over 120 seconds, the size is wrong, not the player.

## Slop tells

If a game shows one of these it is not Deck, and the PR that fixes it says which one it fixed.

- a title only a psychologist recognises
- "which of these four" with distractors drawn at random
- arithmetic the player already knows how to do, with a timer as the only difficulty
- a second game that differs from its twin by one parameter
- a pool a player exhausts in one sitting
- winnable by tapping every cell
- a wall of text before the first move
- a score with no unit and no comparison
- a board that could be dealt unwinnable, or with two answers
- a rule the screen does not show (hidden timing, hidden penalty)
- knowledge from outside the puzzle: trivia, etymology, jargon

## Working a game through the bar

One game or one family per PR.

1. Play it five times on a phone-sized window. Write down the first thing that confused you.
2. Mark the ten checks. Fix what is fixable in the same PR; a test for check 10 comes first.
3. Set the feed size and record the three timings.
4. Rewrite title, subtitle and goal line to pass checks 3 and 9, in `app_en.arb`.
5. Move the id to its tier in `CATALOG.md` and `lib/data/curation.dart`. A non-Deck verdict
   gets one line of reason in the catalog.
6. Screenshot the card mid-solve, light and dark, and put both in the PR.

## Adding a new game

Only when it adds a puzzle idea the Deck lacks. Follow `GAME_DEV_GUIDE.md` for the mechanics
and this file for whether it should exist. Unique-solution logic puzzles from Tatham's
collection or the Nikoli canon are the preferred source. A new game enters as Library and is
promoted by the procedure above.
