# The Puzzlestack look

Puzzlestack is **a deck of paper puzzle cards**. Everything on screen is either paper, ink, a
hairline, or the one live colour. This file is what keeps thirteen surfaces and 313 boards
from drifting into a different app.

The name is the mechanic: a stack of puzzles, dealt one card at a time. Home is the stack. The
feed is the deal. A solved card is the next card.

## The world

Warm paper bed, lighter paper cards, near-black ink, hairline rules. Numbers set in the display
face, like an index printed on a card. Exactly one colour is allowed on top of the paper:

| Token | Light | Dark | Used for |
| --- | --- | --- | --- |
| `paper` | `#EBE6D8` | `#08080A` | the bed behind the cards |
| `card` | `#FFFEFB` | `#141416` | a puzzle card |
| `hair` | `#D8D1BE` | `#26262A` | 1px rules, card edges, chips |
| `ink` | `#14130E` | `#F1EFE7` | text, glyphs |
| `muted` | `#6B6659` | `#9C988C` | secondary text (5.3:1 on card) |
| `signal` | `#4338CA` | `#9C97FF` | the live thing: selection, progress, the one primary action |

All of these live in `DesignSystem` (`paper`, `card`, `hair`, `cardInk`, `cardMuted`, `signal`,
plus `accent(context)`, `muted(context)`, `hairline(context)`, `cardOf(context)`,
`onAccent(context)`, `deckShadow(brightness)`).

**Colour is state, never category.** A category is a label and a count, not a hue. The pastel
per-category tiles the app shipped before are gone on purpose: twelve accents made the stack
look like six different apps. Indigo on an inactive element is a bug.

## Type

Two faces, two jobs:

- **Bebas Neue** — display only. Card indices (`042 / 313`), counts, game titles in the feed,
  section headings, the wordmark. Never body copy, never a button label longer than three words.
- **Geist** — everything else, including buttons and prose. Body 13–16, muted for secondary.

The old app put letterspaced micro-labels above every heading (`I'M BORED`, `DAILY PICK`).
Those are gone. A heading carries its own weight; a card carries its own label.

## The icon

`tool/icon.py` draws it: three cards on paper, the live one in indigo — the same mark as
`DeckMark`, at icon scale. Android's adaptive foreground is the mark inside the 66% safe zone on
a paper field, so a circular mask never cuts a card. Regenerate with
`uv run --with pillow python3 tool/icon.py` then `dart run flutter_launcher_icons`.

## The card

Every surface is a card from `lib/widgets/deck.dart`:

- radius 22 (16 for tiles), 1px hairline, paper shadow with a real offset and a soft blur,
  no coloured halo, no inner glow, no gradient.
- `pile: n` draws empty cards behind it. That is how the stack reads: the deal shows two cards
  under the live one, so the swipe has somewhere to go.
- A puzzle card has a **header** (category, then `042 / 313` in tabular Bebas), a **body** (the
  game, playable in place) and a **footer** (title, one-line subtitle, restart / guide / lock,
  and the one primary action: `NEXT`).

The wordmark is `PUZZLE` over `STACK`, with the deck mark to its left: three cards, the live
one filled in indigo. It is drawn (`DeckMark`), not iconified, because it is the shape the
whole app is built from.

## The deal

`FeedScreen` is the front door and one of three rooms (Deal, Stack, You).

- A vertical `PageView`, one puzzle per page, the game rendered in **embed mode**: full-bleed
  board, no game-owned app bar, no safe area of its own. `GameScaffold` switches to embed mode
  when `FeedSession.inFeed` is true, which is one file instead of 313.
- The deck is `FeedDeck`: a shuffled pass over every puzzle, refilled as a new shuffled pass
  when it runs out, never repeating a card across the seam, hidden games dropped before the
  first shuffle. Random-per-page was replaced because it repeats: the counter would be a lie
  and a third of the catalog would never appear.
- Scrolling works with a thumb, a mouse, a trackpad and a wheel (`scrollBehaviour` override);
  a few games own vertical drags, so the card footer carries a lock that pauses paging.
- Solving a card opens a one-action sheet: **NEXT PUZZLE**. Replay is the only other choice.
  No home, no store links, no tour. That is `FeedSession` + `GameCompletionDialog`.
- Restart re-deals the same card with a fresh board by bumping the page key, so no game needs
  a reset hook for the feed to work.

## Motion

- **The deal.** The stack on screen is the deck: the live card, then two cards behind it, inset
  and dropped so their edges show. Pulling the live card up is dealing it — it lifts, turns about
  a degree and washes back into the paper — and the card underneath *is* the next puzzle, so the
  deck steps up by one as you pull. What it uncovers is a card back (paper, hairline, the mark),
  not the next puzzle's footer: a half-dealt screen showing its buttons through the gap reads as
  two screens fighting. When the card lands, the back fades off over 220ms and the puzzle is
  already there underneath.
- The pull is 1:1 with the finger; the settle is 320ms `easeOutCubic`. Distance or a throw
  decides (16% of the card height, or a fast flick), and a short pull puts the card back.
- The recede is a wash of the bed colour, not an `Opacity` layer: a full-screen `saveLayer`
  every frame is the one thing that would stutter on a cheap phone.
- **Paging:** one card per gesture. No bounce, no overscroll flourishes.
- With reduced motion enabled, the card is simply moved.
- Press: 90ms scale 0.97; the app never waits for choreography (see `PUZZLE_STYLE.md`).
- Nothing loops. Nothing plays on load. A card that moves means the player learned something.

## The gate

A new surface is on brand when all of these are true:

1. It is a card on paper, or it is content on a card. No second container vocabulary.
2. Ink and one live colour. No category hue, no gradient, no glass.
3. Numbers in Bebas, prose in Geist. No letterspaced label above a heading.
4. Every interactive element has a default, pressed and disabled state.
5. It reads in light and AMOLED dark at 320dp and on a tablet.
6. It ships with a test or a screenshot that would catch it drifting.

## Width and height

- The feed card is capped at 560dp and centred; on a tablet an uncapped card turns a puzzle
  into a poster with a postage stamp of content in the middle.
- The stack is capped at 760dp; the room grid goes from two columns to three above 620dp and
  keeps its tiles between 88 and 104dp tall.
- On phones shorter than 720dp the deal drops the tab bar and keeps a grid button in its top
  bar; below 760dp the card footer loses the subtitle. The board is the product; chrome yields.
