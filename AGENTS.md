# Working on Puzzlestack

Puzzlestack is a feed of real puzzles: one good puzzle, then another. Your job is to make the
next card dealt better, not to make the catalog bigger.

## Read in this order

1. [docs/PRODUCT.md](docs/PRODUCT.md): what the app is, who it is for, the business model.
2. [docs/PUZZLE-BAR.md](docs/PUZZLE-BAR.md): the ten checks a game passes to be dealt.
3. [ROADMAP.md](ROADMAP.md): the release gate and the ordered jobs. Take the first job whose
   dependencies are merged.
4. Then only what the job touches:
   - a game's tier: [docs/CATALOG.md](docs/CATALOG.md)
   - feed behaviour: [docs/FEED.md](docs/FEED.md)
   - look and motion of surfaces: `DESIGN.md`
   - look and feel of boards: [PUZZLE_STYLE.md](PUZZLE_STYLE.md)
   - known content defects: [docs/CONTENT-AUDIT.md](docs/CONTENT-AUDIT.md) and its JSONL
   - how a game is wired: [docs/GAME_DEV_GUIDE.md](docs/GAME_DEV_GUIDE.md), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
   - traps on this codebase and this machine: [papercuts.md](papercuts.md)
   - release mechanics: [RELEASE.md](RELEASE.md)

If two docs disagree, PRODUCT.md wins, then PUZZLE-BAR.md, then ROADMAP.md. Fix the loser in
your PR.

## Hard rules

- **Never add a game to the Deck without showing the ten checks in the PR.**
- **Never grow, pad or keep a game to hold a count.** Merge twins, retire filler.
- **Never ship a board that can be unwinnable or have two answers.** Prove it in a test.
- **Every fix carries the test that would have caught it.**
- **One mechanism, not N edits.** If you are about to make the same change in many game
  screens, stop and put it in the shared layer.
- **No ads, no analytics, no accounts, no network calls.** "No data collected" must stay true.
- **You judge by playing.** Run the game at phone size and play it before you rule on it.
  A verdict from reading code is a guess; label it as one.

## Mechanics

- One job, one branch, one worktree under `~/Projects/`, one PR against `cYoren/Puzzlestack`
  (`gh ... -R cYoren/Puzzlestack`; plain `gh` resolves to upstream). Never push to `main`.
- `TMPDIR=$HOME/.cache/tmp flutter test -j 4`, one test run at a time on this machine.
- `dart format <file>`, never a directory.
- The Dart package is `puzzle`; the product is Puzzlestack.
- PR body: the job id, what a player sees differently, before and after (screenshots for
  anything visible, timings for a feed size), and what you did not do.
