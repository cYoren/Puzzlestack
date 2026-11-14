# The feed

How the Deal behaves. The look and the motion are in `DESIGN.md` (PR #40); this file is what
happens and in what order. Direction: [PRODUCT.md](PRODUCT.md). What may be dealt:
[PUZZLE-BAR.md](PUZZLE-BAR.md).

## The loop

```
open app -> a card, already playable
            | solve            | swipe up (any time)
            v                  v
        result line        next card
            | NEXT / swipe
            v
        next card
```

- **Cold start to a playable board: under 2 seconds.** No splash content, no tour, no sign-in,
  no permission prompt, no "what's new".
- **Swipe up deals the next card at any moment**, solved or not. No confirmation. Swipe down
  goes back one card and that card is as it was left. Only one card back is kept.
- **Solving** shows one line (time, and "best" if it is one) and a NEXT button. A swipe does
  the same. No dialog covering the board, no stars, no home button.
- **Leaving the app mid-card** and coming back within the day restores that card.

## The card

| Part | Holds |
| --- | --- |
| Header | kind and room, small; nothing tappable that a thumb hits by accident |
| Goal line | one sentence, 60 characters, from `app_en.arb` `<game>Goal` |
| Board | the game at feed size, full width |
| Footer | title, undo, restart, `?` (guide), heart (like), eye-off (block), NEXT |

- **The goal line is the tutorial.** The guide stays behind `?`. In the feed the rules page is
  never shown first.
- **Nudge.** If nothing valid has been played after 6 seconds on a game the player has never
  solved, the board pulses one cell or piece that has a legal move. Once per card.
- **Hint** fills or marks one deducible step. 3 a day free, unlimited with Plus.
- **Block** removes the game from this player's deal for good, with an undo snackbar.
  **Like** adds it to favourites and raises its weight.
- **Gestures.** A vertical drag that starts on the header or footer deals. A drag that starts
  on the board belongs to the board. The pause-paging lock in PR #40 is a stopgap; a Deck game
  that needs it fails check 7 and gets fixed.

## The deal order

A pure function of (Deck, player history, seed). No network, no model. It is tested.

1. **Pool** = Deck, minus blocked games, minus Word cards with no content in the app language.
2. **Rhythm.** Kinds follow a repeating bar of eight: `Think Word Think Snap Think Word Think
   Snap`. If a kind has no eligible card, Think fills the slot.
3. **Spacing.** No game twice within 20 cards. No two games of the same family in a row
   (two loop puzzles, two anagram games).
4. **Weight** inside a kind, multiplied together:
   - liked: x3
   - solved before and not skipped: x1.5
   - skipped within 5 seconds, each time: x0.5, floor x0.1
   - never seen: x2 for a player's first 100 cards, x1.2 after
5. **Difficulty.** A game the player has not solved is dealt at its easiest feed size. After
   two solves under the target time the next deal of that game steps up one feed tier, if it
   has one.
6. **Never the same puzzle instance twice in 30 days** on one device (seed or pool-row memory).

## The first session

The first ten cards are a fixed, hand-picked order: the easiest feed size of ten of the most
immediately readable Deck games, alternating kinds, starting with one that is solved in under
30 seconds. The list lives next to the Deck list in `lib/data/curation.dart`. After card ten
the normal deal takes over. There is no onboarding screen; these ten cards are the onboarding.

Starting proposal, to be confirmed by play: `water_sort`, `find_word`, `lights_out`,
`memory_matrix`, `sudoku` (4x4), `word_scramble`, `game_2048`, `schulte_table`, `nonogram`
(5x5), `word_ladder`.

## Daily Five

Five cards, the same for everyone on a given date, in a fixed order: Think, Word, Think, Snap,
Think. Drawn only from Deck games whose generator takes a seed; the seed is the date.

- Entry: a card at the top of the Stack and one chip in the Deal header. It is never forced.
- Finishing all five extends the streak. The streak counts days with a finished Daily Five and
  nothing else.
- Result: five times and a total. **Share** produces plain text, no link required:

  ```
  Puzzlestack 14 Nov
  Sudoku 0:41 · Find Word 3/6 · Hitori 1:12 · Schulte 0:19 · 2048 1:03
  Total 4:17
  ```

- Free players play today. Past days are Plus.
- Word cards in the Daily Five are dealt in English content only until another language has a
  curated pool; in other app languages the Word slot becomes a Think card.

## The Stack (Library)

- Six rooms, search, favourites, recents. A tile shows title and kind, nothing else.
- Opening a game from the Stack is a **pick**. It opens with a size and difficulty chooser
  that remembers the last choice per game.
- The first play of any game is free and is not counted as a pick.
- When picks run out the tile still opens, to the Plus sheet, with the game visible behind it.
  No lock icons on tiles.

## What the feed never does

Autoplay to the next card on a timer. Interstitials of any kind. A rating prompt mid-session
(ask once, after a finished Daily Five on day three or later). Sound on by default. A card
that needs landscape. A card that needs the keyboard before the player has chosen to type.
