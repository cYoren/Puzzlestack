# Puzzlestack roadmap

The goal: **a feed of real puzzles, where every card dealt is good.** Why and for whom:
[docs/PRODUCT.md](docs/PRODUCT.md). What "good" means: [docs/PUZZLE-BAR.md](docs/PUZZLE-BAR.md).

Everything below ships in one release, **1.1.0**, the first store release, on Play and the App
Store on the same day. Nothing in it is optional and nothing outside it is in scope.

The earlier roadmap (Phases 0 to 6: the rename, the board contract, the upstream merge, the
Tatham ports, the rebuilt classics) is finished work. It is in git at `36aebc2:ROADMAP.md`.
What those phases taught is in [papercuts.md](papercuts.md).

## The release gate

1.1.0 ships when every line is true. Each is a number or a test, not a feeling.

| # | Gate | How it is checked |
| --- | --- | --- |
| G1 | The Deck holds at least 100 verified games, and no room is more than 40% of it | `test/content/game_profiles_test.dart` |
| G2 | Every Deck game passes the ten checks | its row in `docs/CATALOG.md` is marked verified, with a PR |
| G3 | Every kept game has a test against its own rule (79 have none today: each room's `rule-tests` list in `docs/TRIAGE-*`) | `test/content/` plus a registry sweep that fails on an untested id |
| G4 | No game can be dealt unwinnable, or with two answers where one is implied | generator and pool tests |
| G5 | Every Deck game has a feed size with a measured median of 30 to 120 s | timings in the PR; size table in code |
| G6 | Cold start to a playable card under 2 s; the deal holds 60 fps on a low-end Android | device pass, recorded in the release PR |
| G7 | Every visible game lays out at 320dp in both themes with no overflow | the existing audit run (`AUDIT_DARK=1` too) |
| G8 | Store copy, screenshots and in-app counts all read the visible count from the registry | `registry_test` |
| G9 | Plus can be bought, restored and refunded-then-revoked on both stores | sandbox purchase on each |
| G10 | Zero open PRs older than the release branch | `gh pr list` |
| G11 | Signed release builds for Play and the App Store come from one commit, built on the Mac (not GitHub Actions), and the iOS one has been opened from TestFlight | build ids in the release PR |
| G12 | Nothing reachable is unfinished: no stub, no "coming soon", no empty room, no setting that does nothing (Gus, 2026-11-15) | a registry sweep test plus the device pass |

## Running the release (head model)

Added 2026-11-15 by the project owner pass. Gus's whole instruction to the head model is "read the
docs and work on everything so we are ready for our release". This section is what that means here.
The workers are DeepSeek V4.1 Flash agents through the Command Code provider; never a Pro model.

**Nothing is half implemented.** A job merges complete, with its test, or it does not merge. A game
that cannot be finished for 1.1.0 is moved down a tier, never shipped unfinished.

### The decision that unblocks the release: who plays 230 games

The play pass was owed to "hands and eyes", which made the release wait on one person playing 230
games. It is now done in three layers, and all three are real play of the running app, never a
verdict from reading code:

1. **`accessibility-boards` moves to the front.** Semantics on the board contract give every board
   a text form (cells, values, what a tap does). That is the accessibility work the gate already
   owes, and it is also what lets an agent play.
2. **Flash agents play every Deck candidate** on the Linux release build through `agent-device`,
   reading the board from its semantics: start a deal, make real moves to a solve or to a dead end,
   time it. They record checks 1, 3 and 4 for each game in that room's `docs/TRIAGE-*.md` as
   `machine-played`, with the move list as evidence.
3. **The head model replays** every game a Flash agent marked fail or unsure, and a random 15% of
   the passes, looking at the screen. Its verdict replaces the machine one.
4. **Gus plays two things only:** the fixed first session (`first-ten`) and the fifty dealt cards of
   `device-pass`.

**Time box.** When every other gate row is green, a Deck game still not verified moves to Library
and a Library game below the Library floor is archived. G1 does not move: 100 verified or no release.

### Waves, not one PR per job

Jobs are grouped so the review quota lasts. One branch per wave; agents inside a wave own disjoint
files and run at the same time; the head model merges them into the wave branch and opens one PR.

| Wave | Branch | Jobs | How it splits |
| --- | --- | --- | --- |
| 1 | `release/1.1-fair` | `uniqueness`, `rule-tests` (`untested-sweep`), the two `feed-size` pools | six agents, one per room; each owns that room's game files and tests |
| 2 | `release/1.1-boards` | `accessibility-boards`, then the machine play pass | one agent on the board contract first; then six, one per room, writing only that room's triage file |
| 3 | `release/1.1-plus` | `plus-purchase`, `picks`, `stack-chooser` | one agent, in order |
| 4 | `release/1.1-feed` | `feed-size` mechanism, `runs`, `card-teaches`, `card-result`, `swipe-rules`, `hints-deck`, `deal-order`, `first-ten`, `daily-five` | the mechanism and `deal-order` first, one agent each; then one agent per remaining job |
| 5 | `release/1.1-words` | `plain-names`, `merge-families`, `l10n-kept-games`, `crossword-supply`, `word-wheel-curated` | one agent per `.arb` file or content table; never two on one file |
| 6 | `release/1.1-ship` | `store-shots`, `readme-docs`, `device-pass` fixes, `site` leftovers, `ship` | after waves 1 to 5 are merged |

Waves 1, 2 and 3 start together. Wave 4 starts when wave 1 is merged; wave 5 when wave 2 is.

### The loop

1. Read `AGENTS.md`, `docs/PRODUCT.md`, `docs/PUZZLE-BAR.md` and this file. `git log --oneline -15`,
   `gh pr list -R cYoren/Puzzlestack`.
2. Write under the gate table, once, what each row measures today (run the test it names).
3. For each wave that can start: branch from `origin/main`, one worktree per agent under
   `~/Projects/`, one Flash agent each with its job rows from "The work", the hard rules from
   `AGENTS.md`, and "write the files you will touch to `CLAIM.md` first":

   ```bash
   git worktree add ~/Projects/puzzlestack-w1-logic -b w1/logic release/1.1-fair
   cd ~/Projects/puzzlestack-w1-logic && nohup pi -p "$(cat ../w1-logic.prompt.md)" --no-session \
     --provider commandcode --model deepseek/deepseek-v4.1-flash > ../w1-logic.log 2>&1 &
   ```

4. **Tests run one at a time on this machine.** Two `flutter test` runs stall each other, so every
   agent runs them through one lock:
   `flock ~/.cache/flutter-test.lock env TMPDIR=$HOME/.cache/tmp flutter test -j 4 <paths>`.
   Agents run only the tests of the files they touched; the head model runs the full suite on the
   wave branch.
5. Refuse an agent's work if it touched an unclaimed file, added a game to the Deck without the ten
   checks, edited many screens where one mechanism was due, or left a fix without its test.
6. Audit the wave against its gate rows, mark what is proven, open the PR, answer every review
   comment, merge when clean.

**Stop points, one short question each:** a store login or 2FA; the Mac's keychain; the three
sandbox purchases (G9); the first-ten session and the fifty cards; the yes to submit and to publish.
Nothing else stops the work.

## The work

In order. A job is one PR unless it says otherwise. Take the first job whose dependencies are
merged; say which job id in the PR title.

### A. Landed: nothing is open here

`land-fixes` merged #47 to #53 in that order (the eight band-1 content defects, the shell
resolving a game by id, the selection fixes, the pools, the release assets). `land-deck` merged
#40 rebased on top: the deck look, the real deal, and `DESIGN.md`. Both are in `main`.

### A2. Already done, so nobody re-opens it

Three jobs that older sections of this file still described as open. Each has its code and its
test in `main`; they are named here so a reader does not start them again.

| Job | Where it landed | The proof |
| --- | --- | --- |
| `deck-allowlist` | `lib/data/game_profiles.dart`, generated from CATALOG.md by `tool/gen_game_profiles.py`; `GameFeed.feedPool` is the Deck minus hidden | `test/content/game_profiles_test.dart` re-parses the catalog; G1 |
| `archive` | `visibleIds` in the profile map; rooms, search, counts and the deal read it | `test/content/game_profiles_test.dart` (rooms, counts and search skip the archive), `test/content/feed_pool_test.dart` |
| `nonogram-uniqueness` | `nonogram_model.dart` is the board as a deduction problem; the generator retries up to 500 deals and throws rather than ship an ambiguous grid | `test/content/nonogram_test.dart`, and the Logic triage reads `nonogram` as `pass` |
| `game-previews` | `lib/ui/core/preview/game_preview.dart`: every game tile, quick-play card and search result draws a mini board of the game, not an icon; fifteen motifs, one per family, chosen by a rule list over ids | `test/ui/game_preview_test.dart`: all 319 ids resolve, every visible preview paints, the same id draws the same picture, no two ids share a seed; contact sheet `docs/previews/previews.png` |
| `archive-switch` | `showArchivedGames` on `UserData`, one switch in settings; `GameFeed.browse` is the single decider for rooms, search and the "next game" after a solve, so a lab task can no longer be dealt after a win | `test/content/archive_visibility_test.dart` |
| `minesweeper-no-guess` | `MinesweeperEngine.isSolvableWithoutGuess` plays out the deduction a player has from the first tap; the deal is accepted only if that finishes the board, so no deal can need a guess | `test/engines/minesweeper_engine_test.dart`: thirty deals at each of the app's four sizes, and a solver that answers no when the boards are not fair |

### B. The Deck

No game's tier changes in the machine pass: a verdict that needs play stays where CATALOG.md put
it. Triage that moves an id writes the reason in that room's Notes.

| Job | What | Depends on |
| --- | --- | --- |
| `triage-logic` `triage-math` `triage-memory` `triage-attention` `triage-word` `triage-spatial` | Play every game in the room against the bar. Confirm or move each id in CATALOG.md with a one-line reason, mark it verified. Six PRs. Fix nothing here; open a fix job per game that needs one. **The machine half is done for all six; the play list is what remains** (see B2) | `deck-allowlist` |
| `merge-families` | Fold each `merge` line: add the absorbed game as a mode of the keeper only if it plays differently, then archive it with reason `twin`. One PR per room | its `triage-*` |
| `plain-names` | Titles, subtitles and goal lines in `app_en.arb` for every kept game: plain words, sentence case, 60 characters. No lab names, no ALL CAPS. The ids are in each room's triage report (`plain-names`) | the machine `triage-*` |

### B2. Triage: the half a machine can do is done

Done, all six rooms (`docs/TRIAGE-<ROOM>.md`; `python3 tool/triage_room.py <room>`). Every
game was checked for what a machine can decide: layout at 320dp in both themes, whether the
generator proves its deal, whether it has a rule test, whether it has a guide, whether it can
be played by tap alone, whether undo and restart exist, whether the title shouts. **The list is
in the room docs, not here.** The checks that need a person (1 there is a decision, 3 five-second
read, 4 about a minute) are `needs-play` in all six.

What the machine pass leaves as real work, by job:

| Job | Games | Where |
| --- | --- | --- |
| `uniqueness` | 110 | Logic 33, Math 19, Word 26, Spatial 32: the generator does not prove the deal is winnable |
| `plain-names` | 85 | Logic 24, Math 13, Memory 24, Attention 13, Word 3, Spatial 8: ALL CAPS or lab vocabulary |
| `rule-tests` | 79 | Logic 8, Math 22, Memory 16, Attention 19, Word 5, Spatial 9: no test against the game's own rule (G3) |
| `feed-size` | 2 | Attention: `ghost_tap`, `rhythm_master` have no pool |

**The play pass is still owed: 234 games** (139 Deck + 95 Library; the archive is not played).
It needs hands and eyes, not an agent reading code. Each room's report ends with the list.

### C. Cards that work in a feed

| Job | What | Depends on |
| --- | --- | --- |
| `feed-size` | One mechanism, one place: a Deck game dealt in the feed starts at its feed size (table in PUZZLE-BAR.md). Wire the generators that already take a size; add the parameter where missing. One PR for the mechanism, then one per family | `deck-allowlist` |
| `runs` | The 38 one-answer games that stay become runs of 5 to 8 rounds with one result | `triage-*` |
| `card-teaches` | Goal line on the card, nudge after 6 s idle, no rules page first in the feed, guide behind `?` | `land-deck` |
| `card-result` | Solve = one result line and NEXT. No dialog over the board | `land-deck` |
| `swipe-rules` | Header and footer always deal; board drags stay on the board; one card back is restored. Remove the paging lock when no Deck game needs it | `land-deck` |
| `hints-deck` | Every Think card has a hint that marks one deducible step (`game_assist.dart` covers 20 today) | `feed-size` |

### D. The deal

| Job | What | Depends on |
| --- | --- | --- |
| `deal-order` | The order in FEED.md as a pure function with tests: rhythm, spacing, weights, difficulty step, 30-day no-repeat | `deck-allowlist` |
| `first-ten` | The fixed first session, confirmed by play | `feed-size` |
| `daily-five` | Seeded generators for the eligible games, the five-card daily, streak tied to it, plain-text share | `deal-order` |

### E. Plus

| Job | What | Depends on |
| --- | --- | --- |
| `plus-purchase` | `in_app_purchase`, one non-consumable, local entitlement plus restore. No DRM | none |
| `picks` | 3 picks and 3 hints a day free; the Plus sheet on the fourth; first play of any game never counts | `plus-purchase` |
| `stack-chooser` | Opening a game from the Stack offers size and difficulty and remembers them (`difficulty-ladder`, `difficulty-persistence` from the content audit) | `feed-size` |

### F. Content debt that the Deck depends on

Mostly from [docs/CONTENT-AUDIT.md](docs/CONTENT-AUDIT.md) and `docs/content-audit-tasks.jsonl`,
where the detail for the first two and for `accessibility-boards` lives. The rest are new here.

| Job | What |
| --- | --- |
| `crossword-supply` | A 5x5 mini with clues written for it, and enough of them |
| `word-wheel-curated` | Hand-made wheels; no generated ones from the wide dictionary |
| `accessibility-boards` | Semantics on the board contract |
| `untested-sweep` (the triage reports call it `rule-tests`) | A test against its own rule for every kept game that has none (G3). The ids are in each room's triage report |
| `uniqueness` | Every generator the triage marks `unproven` proves its deal: one answer where the genre implies one, always winnable elsewhere. `lib/core/deduction.dart` has the tools |
| `l10n-kept-games` | Missing keys for kept games in the 22 other locales; guides translate `objective` and `controls` only |

Pool jobs for archived games are cancelled. Do not grow a table for a game nobody can open.

### G. Release

`store-copy` is done (#61): both listings, the web shell, the Pages site and the README lead with
the feed and carry the visible count (234), and `test/content/registry_test.dart` fails if any of
them says the registry total again.

| Job | What |
| --- | --- |
| `store-shots` | Eight shots, every board mid-solve, the first one the Deal. Play 1080x1920, App Store 1290x2796 |
| `readme-docs` | README, PUZZLE_STYLE header, GAME_DEV_GUIDE and CONTENT-AUDIT rule 2 brought in line with docs/PRODUCT.md; delete what is finished |
| `device-pass` | A person plays 50 dealt cards on a cheap Android and an iPhone; every stumble becomes a fix before the build (G6) |
| `site` | Generated website in `docs/` (238 pages: one per puzzle, six rooms, an index, a hub) with `sitemap.xml`, `robots.txt` and JSON-LD. `dart run tool/site_export.dart` then `python3 tool/gen_site.py`; `test/content/site_test.dart` is the contract. `tool/deploy_pages.sh` publishes `docs/` plus the Flutter web build to the `gh-pages` branch, which Pages serves. **Left:** flip `PLAY_ANDROID`/`PLAY_IOS` when 1.1.0 is live, submit the sitemap in Search Console and Bing, and keep the page count in step with the catalog |
| `ship` | Data Safety form, both store builds from one commit, version 1.1.0. Shorebird stays off |

## After 1.1.0

Not started until the release is out. In this order.

1. **Sound**: five sounds for the five verbs, off by default.
2. **New puzzles from open sources**, in the order set in [docs/SOURCES.md](docs/SOURCES.md):
   Tatham's remaining and unreleased puzzles first, then Nikoli types proven by a solver.
3. **Rebuilds from the Archive**: the candidates listed at the end of CATALOG.md.
4. **Word content in a second language** (Portuguese first), curated, so Word cards deal there.
5. **Web, built for search** (Gus, 2026-11-15). Not a marketing page: a real site in the shape of
   <https://8puzzle.org/> — one page per game (`/games/<slug>`, the game playable in the browser),
   a page per room, a hub, and the guides we already wrote as the unique text on each page. Static
   HTML generated from the repo's own data, not hand-written: `game_guides.dart` (313 guides),
   the registry, `docs/CATALOG.md`. Plus sitemap/robots, canonical URLs, JSON-LD
   (`SoftwareApplication`, `FAQPage`, `BreadcrumbList`), internal linking between a game and its
   room and its neighbours, and the Flutter web build behind the playable routes. The repo being
   open and the catalogue being public is the feature: the code is the proof the game is real, and
   GPL-3.0 asks for it anyway. The store listing's best advert is the playable page, not a video.

Notes kept from the old roadmap for the three optional Tatham ports, all of which need
`lib/core/deduction.dart`: Black Box needs half-cell ray entry and deflection or it collapses
to "first ball in each row"; Undead needs mirror ray-tracing before its counts mean anything;
Tracks needs a railway solver before its clues do. Worked examples to copy: Signpost,
Galaxies, Kurodoko.

## Rules

1. **The Deck is earned.** A game is dealt only after its PR shows the ten checks. Adding an
   id to `deckIds` without that is a revert.
2. **Fair or gone.** A game that can be dealt unwinnable, or with two answers, is fixed with a
   test, moved out of the Deck the same day, or archived.
3. **Quality sets the count.** Never keep, pad or add a game to hold a number. The count is
   the games a player can open; archived games are not in it.
   **Nothing is deleted.** A game that leaves the app is archived, tagged, and stays in the repo.
4. **One mechanism, not N.** Feed size, kind, hints, the result line: each lives in one place
   that every game uses. A change that edits 100 screens the same way is the wrong change.
5. **No puzzle owns its gestures.** Input through the board contract, haptics through the five
   verbs, motion through the five moves (`PUZZLE_STYLE.md`).
6. **Every fix ships with the test that would have caught it.**
7. **Keep the names people search for.** `Akari` and `Slitherlink`, not `Light Up` and `Loopy`;
   and never a lab name.
8. **The registry is the source of truth** for what exists and for every number in copy.
9. **Upstream still merges.** A new upstream game enters as Library and is triaged like any
   other; an archived game stays archived until a rebuild PR passes the bar.
10. **One wave per branch, one PR per wave** (2026-11-15; it was one PR per job). Each agent works
    in its own worktree on its own files; the wave PR shows before and after. Docs and plans may go
    straight to `main`; anything a player can see or that touches money goes through the wave PR.
