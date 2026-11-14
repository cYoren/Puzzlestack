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
| G1 | The Deck holds at least 100 verified games, and no room is more than 40% of it | `test/curation_test.dart` |
| G2 | Every Deck game passes the ten checks | its row in `docs/CATALOG.md` is marked verified, with a PR |
| G3 | Every registry game has a test against its own rule (today 112 have none) | `test/content/` plus a registry sweep that fails on an untested id |
| G4 | No game can be dealt unwinnable, or with two answers where one is implied | generator and pool tests |
| G5 | Every Deck game has a feed size with a measured median of 30 to 120 s | timings in the PR; size table in code |
| G6 | Cold start to a playable card under 2 s; the deal holds 60 fps on a low-end Android | device pass, recorded in the release PR |
| G7 | Every registry game lays out at 320dp in both themes with no overflow | the existing audit run (`AUDIT_DARK=1` too) |
| G8 | Store copy, screenshots and in-app counts all read from the registry | `registry_test` |
| G9 | Plus can be bought, restored and refunded-then-revoked on both stores | sandbox purchase on each |
| G10 | Zero open PRs older than the release branch | `gh pr list` |

## The work

In order. A job is one PR unless it says otherwise. Take the first job whose dependencies are
merged; say which job id in the PR title.

### A. Land what is open

| Job | What | Depends on |
| --- | --- | --- |
| `land-fixes` | Review and merge #47, #48, #49, #50, #52, #51, in that order | none |
| `land-deck` | Rebase #40 (the deck look and the real feed) on main, resolve, merge. `DESIGN.md` arrives with it | `land-fixes` |

### B. The Deck

| Job | What | Depends on |
| --- | --- | --- |
| `deck-allowlist` | `lib/data/curation.dart`: replace `feedBlocklist` with `deckIds`, seeded from the Deck lists in CATALOG.md. `GameFeed.feedPool` = Deck minus hidden. Add `kind` (think, word, snap) and `family` to `GameMetadata`. Test: ids are real, Deck matches CATALOG.md, G1 | `land-deck` |
| `triage-logic` `triage-math` `triage-memory` `triage-attention` `triage-word` `triage-spatial` | Play every game in the room against the bar. Confirm or move each id in CATALOG.md with a one-line reason, mark it verified. Six PRs. Fix nothing here; open a fix job per game that needs one | `deck-allowlist` |
| `merge-families` | Fold each `merge` line: add the absorbed game as a mode of the keeper only if it plays differently, then delete it. One PR per room | its `triage-*` |
| `retire` | Tag `archive/pre-retire`, then remove the Retire list from the registry with its screens, l10n keys, guides and tests | all `triage-*` |
| `plain-names` | Titles, subtitles and goal lines in `app_en.arb` for every kept game: plain words, sentence case, 60 characters. No lab names, no ALL CAPS | `retire` |

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
| `nonogram-uniqueness` | Nonogram proves one answer before it is dealt |
| `crossword-supply` | A 5x5 mini with clues written for it, and enough of them |
| `word-wheel-curated` | Hand-made wheels; no generated ones from the wide dictionary |
| `minesweeper-no-guess` | First tap opens an area and the board is solvable without a guess |
| `accessibility-boards` | Semantics on the board contract |
| `untested-sweep` | A test against its own rule for every kept game that has none (G3) |
| `l10n-kept-games` | Missing keys for kept games in the 22 other locales; guides translate `objective` and `controls` only |

Pool jobs for games on the Retire or merged-away lists are cancelled. Do not grow a table for a
game that is leaving.

### G. Release

| Job | What |
| --- | --- |
| `store-copy` | Lead with the feed, not the count: "One good puzzle, then another." The number comes from the registry |
| `store-shots` | Eight shots, every board mid-solve, the first one the Deal. Play 1080x1920, App Store 1290x2796 |
| `readme-docs` | README, PUZZLE_STYLE header, GAME_DEV_GUIDE and CONTENT-AUDIT rule 2 brought in line with docs/PRODUCT.md; delete what is finished |
| `device-pass` | A person plays 50 dealt cards on a cheap Android and an iPhone; every stumble becomes a fix before the build (G6) |
| `ship` | Data Safety form, both store builds from one commit, version 1.1.0. Shorebird stays off |

## After 1.1.0

Not started until the release is out. In this order.

1. **Sound**: five sounds for the five verbs, off by default.
2. **The Deck's gaps** (CATALOG.md, last section): Black Box, Undead, Tracks, Mosaic, Palisade,
   then Hat and Spectre.
3. **Word content in a second language** (Portuguese first), curated, so Word cards deal there.
4. **Web**: the Deal as a playable page, as the store listing's best advert.

Notes kept from the old roadmap for the three optional Tatham ports, all of which need
`lib/core/deduction.dart`: Black Box needs half-cell ray entry and deflection or it collapses
to "first ball in each row"; Undead needs mirror ray-tracing before its counts mean anything;
Tracks needs a railway solver before its clues do. Worked examples to copy: Signpost,
Galaxies, Kurodoko.

## Rules

1. **The Deck is earned.** A game is dealt only after its PR shows the ten checks. Adding an
   id to `deckIds` without that is a revert.
2. **Fair or gone.** A game that can be dealt unwinnable, or with two answers, is fixed with a
   test, moved out of the Deck the same day, or retired.
3. **Quality sets the count.** Never keep, pad or add a game to hold a number.
4. **One mechanism, not N.** Feed size, kind, hints, the result line: each lives in one place
   that every game uses. A change that edits 100 screens the same way is the wrong change.
5. **No puzzle owns its gestures.** Input through the board contract, haptics through the five
   verbs, motion through the five moves (`PUZZLE_STYLE.md`).
6. **Every fix ships with the test that would have caught it.**
7. **Keep the names people search for.** `Akari` and `Slitherlink`, not `Light Up` and `Loopy`;
   and never a lab name.
8. **The registry is the source of truth** for what exists and for every number in copy.
9. **Upstream still merges.** A new upstream game enters as Library and is triaged like any
   other; a retired game stays retired.
10. **One job per branch, one PR per job**, in its own worktree, with before and after in the
    PR. Nothing is pushed to `main`.
