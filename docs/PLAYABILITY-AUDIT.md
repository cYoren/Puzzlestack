# Playability audit — 2026-11-11

Gus played through the deck and wrote down what made it unfun. This is the work list.
Every line is a real complaint, kept in his words so the intent survives; the note under it
is what "fixed" means, and what actually landed on `fix/playability-audit` and its follow-up
`feat/audit-followup`.

Status key: `[x]` done in this branch · `[~]` done where it applies, with the reason it does
not apply everywhere · `[ ]` still open.

---

## 1. Cross-cutting: the things wrong in many games at once

- [~] **Make a solve button for every puzzle, and a hint where a hint means anything.**
      The shell now owns the button: `GameScaffold` resolves the game from its title and adds
      a solve action from `lib/ui/core/assist/game_assist.dart`, so all 19 board games plus
      Akari and Norinori get one without a line in their screens. Solve confirms first, fills
      the answer, and does **not** earn XP or extend a streak (`GameAssist` flag, consumed in
      `completeGame`). Hints stay on the games that already had a provable step (15 of them).
      Reaction tests and quizzes have no "answer", so they deliberately have no button.
      `test/board/solve_button_test.dart` proves every wired `solve()` reaches the game's own
      win state.
- [x] **Immediate feedback on mistakes.**
      Three patterns, all in place: a rule the tap would break is refused with a named reason
      (Norinori), a violation is painted red the moment it lands (Slitherlink clues, Akari
      walls and bulbs, Wisconsin's card sort), and the screen says what happened in a snackbar
      or banner with an error haptic.
- [x] **Show the rules first, the first time a game is opened.**
      `launchGame()` opens the written guide (with a PLAY button) before the game screen is
      built, so a timed game never starts its clock behind a rules page. The first-play flag
      is stored in the `game_stats` Hive box. Wired on the home screen, category rooms and
      search.
- [x] **Design legible in low light, and not blasted in high contrast.**
      `PuzzlePalette` grew `structure` (walls, filled cells, pipes) and `line` (grid lines),
      both mid-tones in either theme; Inertia, Kurodoko, Netslide, Akari, Cube and the shell
      paint with them. Dark-theme text is a soft white and dark outlines are visible on
      `#1E1E1E`. The static-colour sweep checked all 67 game files that name
      `DesignSystem.surface/outline` directly: every one was already a `isDark ? dark… : …`
      pair, so the sweep found exactly one real gap (`mental_calendar` painted a near-black
      label on a near-white card in dark mode), now fixed. No blanket rewrite was needed, and
      doing one would have churned 67 files for no visible change.
- [~] **Statistics that tell you where you stand.**
      Every solve is timed (clock started by `GameScaffold`) and stored per game: solves,
      best time, and "faster than N% of your solves" once there are three. Shown on the
      completion dialog and in Stats → YOUR PACE. It compares the player to their own history;
      there is no server population, and inventing one would be a lie.
- [x] **Infinite scroll** — the discovery home now ends in a lazy `ALL 313 PUZZLES` list
      (`SliverList.builder`), so the catalogue is one endless scroll instead of six rooms and
      a dead end. The Shuffle feed was already unbounded.
- [x] **Animation pass over every game.** The board contract gained an optional transition
      (`transitionFor` + `paintTransition`): the engine paints the in-between frames and only
      reports the win once the move has been seen. Wired for the five games where a move is a
      movement — Water Sort (a real pour: draining tube, rising tube, arcing stream), Twiddle
      (the block actually rotates 90°), Inertia (the ball slides between cells), Cube (rolls
      over the shared edge with a small lift) and Netslide (row/column shift with the wrap tile
      entering from the far edge). The shared tap-settle covers every other moving tap. The
      313-game audit runs in both themes (`AUDIT_DARK=1`): 313 checked, 0 overflow, 0 throws
      at 320dp.
- [x] **No coffee for someone else.** The upstream author's Ko-fi link is gone from the
      completion dialog.

---

## 2. Named games

- [x] **Signpost — drag and drop is bad.** A drag grabs from the point the finger went down
      (it used to jump by the 18dp pan slop), and a cell that already points somewhere can be
      dragged again to re-point it, which is how a wrong arrow is corrected in one gesture.
- [x] **Slitherlink — no mistakes shown, no guidance.** A clue that the loop has broken turns
      red with a ring and a snackbar naming the count; a hint draws the first missing edge of
      the answer; the screen shows "N clues broken".
- [x] **Futoshiki — numbers are invisible.** The digit size was `rect.height * 0.5` where
      `rect` is normalised (≈0.15), so every number was less than a pixel tall. All board
      fonts now go through `PuzzleCanvas.fontSizeFor`, which asserts a readable size. The
      inequality signs also got the contrast floor.
- [x] **Lock Pattern — the grid scrolls away from the answers.** Board, guess counter and
      answer history are one vertical scroll view now; guesses are rows with a small pattern
      and "n right / n misplaced" instead of a sideways strip.
- [x] **Matrix Reasoning — too obvious, and medium/hard reuse the same rules.** The missing
      cell is at a random position; distractors are one attribute away, so guessing is a real
      choice. Tiers: shape along rows (easy), shape × colour (medium), a Latin square of both
      (hard). The score feeds the tier during a run.
- [x] **Einstein Riddle — does not work.** The picker was a `Column(mainAxisSize: min)` with
      an `Expanded` list inside, which throws, so it never appeared. It is a bounded sheet
      now, marks values already used, and refuses a duplicate value with a message instead of
      silently blocking the win.
- [x] **Akari — does not win when every bulb is placed.** The win check was sound; the board
      never said *why* it had not fired. Numbered walls go red when overloaded, bulbs that see
      each other go red, and an engine solver powers both the hint (one bulb) and solve (all).
      Walls no longer use `onSurface`, which turned them into lamps in dark mode.
- [x] **Wisconsin Card Sorting — confusing without feedback.** Every sort now answers with a
      green "MATCH" or a red "NO MATCH" and a haptic, and the 5-correct rule change is
      announced by name. The streak to the next rule is on screen.
- [x] **Water Sort — audit the animation, and no identical colours in pipes.**
      A pour now drains the source tube, fills the destination and draws an arcing stream
      between them; a reset is not mistaken for a pour. The colour set is distinct, and the
      actual duplicate pair was in **Pipes** (`accentBerry` and `accentAmber` were both
      `#D97706`), now eight distinct hues.
- [x] **Kurodoko — almost invisible, much to improve.** The clues were sub-pixel fonts; black
      cells and grid lines now use `structure`/`line`, so an untouched board reads as a grid.
- [x] **Norinori — needs feedback, and should be playable without reading the rules.** A rule
      line sits above the board; a third cell in a room or a third cell in a domino is refused
      and the offending cell flashes red; hint and solve are on the screen. Boards are now
      generated (`norinori_engine.dart`): a random connected partition, then every shading is
      counted and a board ships only with exactly one answer. The three hand-made rooms are
      gone.
- [x] **Pegs — incomprehensible.** A peg is a disc, a hole is a ring, and selecting a peg
      paints the peg it would vault (red) and where it would land (ring) before the tap.
- [x] **Cube — bad implementation, needs real work.** The board no longer paints target and
      painted cells as two shades of the same blue: targets are solid blue squares, painted
      squares are ink-filled, and the cube is bigger with an extra swatch for the **bottom**
      face — the one a roll swaps, and the only face an isometric view cannot show. A roll now
      travels between the two squares and lifts over the edge between them. The engine
      (ported, counted, tested) was already correct and is unchanged.
- [x] **Netslide — bad UI for tapping.** Movement now lives in gutters: ⏴/⏵ per row, ⏶/⏷ per
      column, faint when a wall blocks the line. A cell tap no longer pushes a row east by
      surprise.
- [x] **Twiddle — bad implementation, bad animation, almost invisible.** Tile numbers were
      sub-pixel (same normalised-font bug); they are readable now, dragging outlines the block
      that will turn, and a turn rotates that block 90° in the direction it turned instead of
      swapping the numbers in one frame.
- [x] **Conjunction Search — the square should be more square.** Corner radius scales with the
      shape (6%) instead of a fixed 8dp on a 40dp square.
- [x] **Spotlight Track — the target is weird.** The target is a ring around a white core,
      sized from the board, with a fading spotlight instead of a hard circle. No fixed 8px dot
      and 16px glow.
- [x] **Vigilance Task — "wtf is vigilance".** One line above the board says the rule; the
      clock hand is now 60 dots with the active one large and the skipped one red, so a skip
      is visible; live hits/misses/false-alarm counters; a miss says "MISSED A SKIP". One tap
      counts once per second (it used to count a triple-tap as three false alarms).

---

## Still open — handoff for the next agent (deliberate, not release blockers)

- Statistics compare the player to themselves. A population percentile needs a backend that
  does not exist, and the app should not invent one. (Would need: an endpoint, a sample, and a
  privacy answer; out of scope for a fix.)
- The Norinori generator is 4x4 with 3-5 rooms; a size/difficulty ladder would be new content,
  not a fix. It belongs with the Phase 5 games in ROADMAP.md.
- Reaction tests and quizzes have no solve button because "the answer" is not a thing there.
  A hint on a timed test is a different feature (a tutorial), not a missing button.

ROADMAP.md → Phase 6 → "Playability audit" repeats this list, so an agent who starts from the
release plan sees it without opening this file.

## Notes

- Every fix ships behind the existing contracts (`PuzzleBoard`, `GameScaffold`,
  `GameCompletionDialog`) so 313 games keep one shell.
- Tests: `flutter test -j 4`; the widget sweep is `test/board/game_audit.dart` (not part of
  the suite, `AUDIT_DARK=1` for the dark pass). New coverage: `test/board/solve_button_test.dart`,
  `test/board/transitions_test.dart`, `test/engines/norinori_engine_test.dart`,
  `test/data/game_stats_test.dart`.
