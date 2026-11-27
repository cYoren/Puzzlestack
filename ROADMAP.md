# Puzzlestack roadmap

## Current priority (2026-11-27)

The release work starts from 1.1.1 build 17. Close the proof gates in this order. New puzzles
and optional ports are parked until after the release review.

1. G2: play and verify every Deck candidate, moving anything that fails to Library or archive.
2. G5: record feed-size medians for every Deck game.
3. G6: complete the cheap-Android and iPhone device pass.
4. G9: complete Plus purchase, restore, refund, and entitlement revocation on both stores.
5. G11: build signed Play and App Store binaries from one commit and open the iOS build from
   TestFlight.
6. Submit only after the Play data-safety form, store metadata, and final site links are
   generated from the released registry.

The goal: **a feed of real puzzles, where every card dealt is good.** Why and for whom:
[docs/PRODUCT.md](docs/PRODUCT.md). What "good" means: [docs/PUZZLE-BAR.md](docs/PUZZLE-BAR.md).

Play and the App Store ship together after the gates pass.

The earlier roadmap (Phases 0 to 6: the rename, the board contract, the upstream merge, the
Tatham ports, the rebuilt classics) is finished work. It is in git at `36aebc2:ROADMAP.md`.
What those phases taught is in [papercuts.md](papercuts.md).

## The release gate

The release ships when every line is true. Each gate names the evidence it needs.

| # | Gate | How it is checked |
| --- | --- | --- |
| G1 | The Deck holds at least 100 verified games, and no room is more than 40% of it | `test/content/game_profiles_test.dart` checks the count and room share; G2 supplies verification |
| G2 | Every Deck game passes the ten checks | its row in `docs/CATALOG.md` is marked verified, with a PR |
| G3 | Every kept game has a test against its own rule (each room's `rule-tests` list in `docs/TRIAGE-*`) | `test/content/` plus a registry sweep that fails on an untested id |
| G4 | No game can be dealt unwinnable, or with two answers where one is implied | generator and pool tests |
| G5 | Every Deck game has a feed size with a measured median of 30 to 120 s | timings in the PR; size table in code |
| G6 | Cold start to a playable card under 2 s; the deal holds 60 fps on a low-end Android | device pass, recorded in the release PR |
| G7 | Every visible game lays out at 320dp in both themes with no overflow | `test/board/game_audit.dart` standalone and with `AUDIT_FEED=1`, in each case in light and with `AUDIT_DARK=1` |
| G8 | Store copy, screenshots and in-app counts all read the visible count from the registry | `registry_test` |
| G9 | Plus can be bought, restored and refunded-then-revoked on both stores | sandbox purchase on each |
| G10 | Zero open PRs older than the release branch | `gh pr list` |
| G11 | Signed release builds for Play and the App Store come from one commit, built on the Mac (not GitHub Actions), and the iOS one has been opened from TestFlight | build ids in the release PR |
| G12 | Nothing reachable is unfinished: no stub, no "coming soon", no empty room, no setting that does nothing (Gus, 2026-11-15) | a registry sweep test plus the device pass |

## How the release work was run

Added 2026-11-15 and finished 2026-11-23. Kept only so nobody repeats it. The workers were
DeepSeek V4.1 Flash agents through the Command Code provider, in six waves, one branch and one PR
per wave, one worktree and one file set per agent.

| Wave | PRs | What it landed |
| --- | --- | --- |
| 1 | #75, #77, #80 | lab-hide, the room rule tests, uniqueness and the two dry pools |
| 2 | #78 | the semantics pass that lets a machine read and play a board |
| 3 | #79 | Plus, the daily picks and the stack chooser |
| 4 | #81 | feed size, the deal order, the first ten cards, Daily Five, the card UX |
| 5 | #82 | plain names, curated word wheels, crossword supply, l10n |
| 6 | #83 | 1.1.0+16, the regenerated site, the triage docs, the G12 sweep |
| after | #84 | anonymous usage analytics, off in Settings |

Two rules from those waves still hold for any later PR: tests run one at a time
(`flock ~/.cache/flutter-test.lock env TMPDIR=$HOME/.cache/tmp flutter test -j 4`), and a job
merges complete, with its test, or it does not merge.

## The work

Nothing below the gate table is open except "Remaining". Every job this file used to describe as
pending has landed; the table says where, so nobody starts it again.

### Landed

| Job | PR | What it covers | Gate row it closes |
| --- | --- | --- | --- |
| `lab-hide` | #75 | 102 lab ids archived in all: 24 Deck and 26 Library ids left the visible set, which went 234 to 184, and the other 52 were already archived | G1 |
| `rule-tests` (`untested-sweep`) | #77, #80 | a test against its own rule for every kept game, with the registry held to the list | G3 |
| `uniqueness` | #80 | Deck family probes and an explicit list of the families still missing proof | G4, partly |
| `feed-size` | #77, #81 | one feed size per game through one mechanism; Ghost Tap and Rhythm Master got pools | G5 (mechanism; the medians are still owed) |
| `accessibility-boards` | #78 | the board contract gained a text form read from the same tap path a finger uses; 29 of the 324 game folders render through it today | G2, partly (the rest is Remaining (c)) |
| `plain-names` | #82 | plain titles, subtitles and goal lines for all 184 kept games | G2 (check 9) |
| `l10n-kept-games` | #82 | missing keys for kept games across 23 locales; guides translate objective and controls | G12 |
| `crossword-supply` | #82 | enough hand-clued 5x5 minis to deal | G2 |
| `word-wheel-curated` | #82 | 30 hand-made wheels, no generated ones from the wide dictionary | G2 |
| `plus-purchase` | #79 | one non-consumable, one local entitlement row, restore, and a refund that takes it back | G9 (code; the sandbox is still owed) |
| `picks` | #79 | three picks and three hints a day free, the first play of a game never counts | G12 |
| `stack-chooser` | #79 | size and difficulty asked once before the board and remembered | G2 (check 1) |
| `deal-order` | #81 | the order in FEED.md as a pure function with tests | none; FEED.md is the contract |
| `first-ten` | #81 | the fixed first session | G6 (the person plays it in the device pass) |
| `daily-five` | #81 | seeded generators, the five-card daily, the streak and the plain text share | none; product |
| `card-teaches` | #81 | goal line on the card, idle nudge, guide behind `?`, no rules page first | G2 (check 3) |
| `card-result` | #81 | one result line and NEXT, no dialog over the board | G12 |
| `swipe-rules` | #81 | header and footer always deal, board drags stay on the board, one card back | G12 |
| `hints-deck` | #81 | every Think card has a hint that marks one deducible step | G2 (check 8) |
| `store-copy` | #62 | both listings, the web shell, the Pages site and the README lead with the feed and the visible count | G8 |
| `store-shots` | #52 | eight composed shots per store, each one a board mid solve, held by `test/content/store_images_test.dart` | G8 |
| `readme-docs` | #83 | README, PUZZLE_STYLE, GAME_DEV_GUIDE and CONTENT-AUDIT brought in line with PRODUCT.md | none; docs |
| `posthog` | #84 | anonymous usage events, gated on the installed version, off in Settings | none; the Data Safety answers are in RELEASE.md |

**Release-proof evidence (#92):** At 320dp in light and dark, 103 Deck cards and 323 standalone
games mounted without overflow or exceptions (G7). The largest room holds 41 of 103 Deck
candidates, below 40%. G1 still depends on play verification in G2.

### Remaining

In order. Nothing here is a wave, and nothing here is a job for a Flash agent alone.

**(a) G4, fairness evidence is incomplete.** `test/content/deal_uniqueness_test.dart`
checks every Deck id is assigned to a family. Four families run probes; six document why proof
is missing and are skipped. The [triage reports](docs/CATALOG.md) identify the individual games
and distinguish missing proof from an observed unwinnable deal.

**(b) G2, the play pass: no game is verified.** None of the 184 games is marked verified in
`docs/CATALOG.md`, and all six `docs/TRIAGE-*.md` say the play pass is still owed. The machine
half is done in every room, including the checks a machine can decide. The checks that need a
person (a decision, a five-second read, about a minute) are `needs-play` everywhere. A game is
verified by playing it on a built app and writing the verdict into CATALOG.md in a PR.

**(c) G2 and G12, accessibility: most boards are outside the shared text contract.** A source
scan finds 29 game folders using `PuzzleBoardView`. Audit the remaining controls and boards for
screen-reader play, port custom boards where needed and verify the focus order and actions.
Full screen-reader coverage is still unverified.

**(d) G5, the feed-size medians.** The mechanism and the size table are in code. No timing is
recorded anywhere, and the gate asks for a measured median of 30 to 120 s per Deck game. Take the
timings from the play pass, write them into the PR, and do not make a number up.
`mirror_maze` was the one known thin pool and is no longer one: a 5x5 board gives 160 distinct
two-mirror deals, counted by enumeration, which is enough for check 5. Do not try to buy depth
instead. A deal cannot need three mirrors: an odd number of turns leaves the board on the other
axis, at a row one mirror would have reached, and four or more turns must come back up the column
the detour started in, where the mirror that started it is waiting.

**(e) G6, the device pass.** A person plays fifty dealt cards on a cheap Android and on an iPhone,
times the cold start to a playable card, and looks at the deal holding 60 fps. Every stumble
becomes a fix before the build. Nothing in the repo can stand in for this.

**(f) G9, the Plus sandbox.** Buy, restore, and refund then revoke, on both stores, with a real
sandbox account. The code handles all of it and the purchase funnel has tests, but no purchase has
been made in a store sandbox.

**(g) G11, the signed builds.** Signed builds for Play and the App Store from one commit, built on
the Mac, and the iOS build opened from TestFlight. See RELEASE.md for the signing inputs.

**(h) `ship`.** Submit the Play Data Safety answers in the console (prepared in RELEASE.md),
verify the `puzzlestack_plus` listing in Play, and confirm the final store metadata.

**(i) After the release is live.** Set `PLAY_ANDROID` and `PLAY_IOS` in `tool/gen_site.py`, regenerate
the site, and verify the Google Search Console property. The `gsc` token currently carries only
the `webmasters` scope and lacks `siteVerification`, so verification needs one re-consent.

## After the release

Not started until the release is out. In this order.

1. **Sound**: five sounds for the five verbs, off by default.
2. **New puzzles from open sources**, in the order set in [docs/SOURCES.md](docs/SOURCES.md):
   Tatham's remaining and unreleased puzzles first, then Nikoli types proven by a solver.
3. **Rebuilds from the Archive**: the candidates listed at the end of CATALOG.md.
4. **Word content in a second language** (Portuguese first), curated, so Word cards deal there.
5. **Web, built for search** (Gus, 2026-11-15). It is built and published: one page per game
   (the game playable in the browser), a page per room, a hub, and the guides as the unique text
   on each page, generated from the repo's own data (`game_guides.dart`, 323 guides, the registry,
   `docs/CATALOG.md`) with sitemap, robots, canonical URLs, JSON-LD and internal links. What is
   left after the release is (i) above: flip the store links and verify Search Console.

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
