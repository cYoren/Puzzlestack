# Puzzlestack: the product

This file is the direction. When another doc disagrees with it, this one wins and the other
doc is stale. Read it before [PUZZLE-BAR.md](PUZZLE-BAR.md), [FEED.md](FEED.md),
[CATALOG.md](CATALOG.md) and [ROADMAP.md](../ROADMAP.md).

## What it is

**A feed of real puzzles.** You open the app and you are already playing. Swipe up, the next
puzzle is dealt. Each one takes about a minute, each one is fair, and none of them is filler.

One sentence for the store, the icon, and every decision: **one good puzzle, then another.**

## Who it is for

Someone with two minutes and a phone, who would otherwise open a video feed. They like the
feeling of working something out. They do not want a menu of 300 tiles, a rules page, an
account, an ad, or a "brain age".

They are not a Sudoku purist who wants a 40-minute expert grid. That player is welcome in the
Library, and is the one who pays, but the front door is not built for them.

## What was wrong (audit, 2026-11-14)

The project was run on two numbers, **313 games** and **one unique solution**, and the docs
enforced both. The second is right. The first is the problem.

- The roadmap's goal was "the best-built puzzle app", measured in ports and uniqueness tests.
  No doc described the player, the session, or what a good puzzle is.
- About 110 of the 313 are cognitive lab tasks under their lab names (`sternberg_task`,
  `sopt`, `dnms`, `posner_spatial_cueing`, `d2_attention`), and about 30 are school worksheets
  with a timer (`binomial_match`, `matrix_multiplier`, `radical_roots`). Around 60 are a twin
  of another game. They are not puzzles, and a feed that deals them at random is the slop.
- The content audit said "never fix thin content by deleting the game, the number 313 is
  written into five files". That rule protected the count, not the player.
- The reel was curated by a **blocklist that shipped empty**, so everything was dealt.
- 19 games are on the board contract. The house style gates 6% of the catalog.
- 215 games have one size. A 9x9 Sudoku and a 2-second reaction test were the same kind of
  card.
- The feed had a look (`DESIGN.md`, unmerged) and no behaviour spec: no order, no first
  session, no rule for how long a card may take.
- The paywall was three sentences.

## The five decisions

1. **The Deck is opt-in.** A game is dealt in the feed only after it passes
   [the bar](PUZZLE-BAR.md). The Deck is an allowlist. Everything else is Library or gone.
2. **Quality sets the number.** Twins are merged, lab tasks and worksheets are retired, and
   the store copy says whatever the registry then holds. First pass: 313 becomes about 224,
   with about 139 Deck candidates. See [CATALOG.md](CATALOG.md).
3. **A card is about a minute.** Every Deck game has a feed size that a first-timer solves in
   30 to 120 seconds. Full sizes and hard tiers live in the Library.
4. **The card teaches itself.** No rules page before play. A goal line a stranger understands,
   and a nudge if they stall.
5. **The deal is free. The choice is Plus.** One purchase, once. No ads, no subscription, no
   account, no data collected.

## Pillars

Use these to settle an argument. Earlier beats later.

1. **Fair.** Winnable by thinking about what is on the screen. Never a guess, never trivia.
2. **Instant.** Playing within two seconds of opening the app; understood within five seconds
   of seeing a card.
3. **One more.** Solving ends on NEXT. Skipping costs nothing. Nothing ever asks "are you sure".
4. **One app.** Paper, ink, one colour, one drag feel. A card that looks like a different app
   is a bug.
5. **Honest.** No fake percentile, no invented streak pressure, no dark pattern at the paywall,
   no name the player has to look up.

## The three rooms

| Room | What it is | Rule |
| --- | --- | --- |
| **Deal** | the feed, and the first screen | Deck games only, at feed size, in dealt order |
| **Stack** | the Library: every game, by room, searchable | choose a game, a size, a difficulty |
| **You** | streak, Daily Five history, solve times against yourself | only numbers that are true |

Look and motion for all three: `DESIGN.md` (lands with PR #40). Behaviour: [FEED.md](FEED.md).

## Business model

| | Free | Plus (one-time) |
| --- | --- | --- |
| The Deal: endless, feed size | yes | yes |
| Daily Five, streak, share | yes | yes |
| First play of every Library game | yes | yes |
| **Picks**: open a game you chose, any size or tier | 3 a day | unlimited |
| Daily Five archive (play past days) | no | yes |
| Hints | 3 a day | unlimited |

- **Price:** US$4.99 one-time, non-consumable, store regional pricing, restore button. Same
  price and same day on Play and the App Store.
- **Why this shape:** the free product is complete and never degrades, so reviews and word of
  mouth stay clean. What Plus sells is control (this game, this size, right now), which is
  exactly what the committed player wants and the casual one never misses.
- **The paywall appears in one place:** when a fourth pick is asked for in a day, as a sheet
  with the price and what it buys. Never in the Deal. Never before a first play. Never a
  countdown, never a fake discount.
- **No ads, ever.** No analytics SDK. "No data collected" is on the store page and is true.
- **No subscription.** There is no server and no recurring cost to justify one.
- The repo is GPL-3.0 and public. We sell the convenience of the store build, which the GPL
  allows. Entitlement is local plus the store receipt; do not build DRM.

This refines the 2026-11-11 rule (every puzzle playable once, some free forever, the gate is
replays and volume) into something a player can read in one line.

## What we do not build

Accounts, cloud sync, leaderboards, global percentiles, friends, chat, comments, ads,
subscriptions, "brain age" or any health claim, a level map, currencies, loot, energy timers,
notifications other than one optional daily reminder. Anything that needs moderation or a
backend is out.

## How we know it is good, without telemetry

- The release gate in [ROADMAP.md](../ROADMAP.md): numbers an agent can check.
- A device pass by a person on a cheap Android phone before every store build.
- Store reviews and the in-app "block this puzzle" count, which stays on the device and feeds
  the deal.

## Open decisions for Gus

Defaults are chosen; work proceeds on them. Say so to change one.

| Decision | Default |
| --- | --- |
| Plus price and shape | US$4.99 once; 3 picks and 3 hints a day free |
| Retiring games | the Retire list in CATALOG.md goes, after an archive tag |
