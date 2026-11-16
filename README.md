# Puzzlestack

A cross-platform suite of **230 playable brain puzzles**, built with Flutter. Logic, math, memory, spatial, attention and word games, all in one clean, authoritative app, on Android, iOS, web, Windows, macOS and Linux.

Two ideas sit at the heart of Puzzlestack:

1. **The deal.** The app opens on a puzzle, not on a menu. One full-screen card, playable
   where it lands; swipe up and the next card is dealt. The deck is a real shuffled pass over
   every playable puzzle, so nothing repeats until the bag is empty and the counter on the card
   (`042 / 230`) is true. Solving a card offers one thing: the next card.
2. **The stack.** When you know what you want, the second room files every puzzle by
   category: six rooms, today's card, a row for when you have two minutes, and search.

The look is a deck of paper cards: warm paper, ink, hairlines, Bebas display numerals, and one
live colour (indigo) that only appears where something is active. See [DESIGN.md](DESIGN.md).

---

## The 230 games, by category

- **Logic (58):** Sudoku, Slitherlink, Kakuro, Nonogram, Minesweeper, Akari, Hitori, Bridges, Water Sort, Lights Out, Pegs, Twiddle, Galaxies, Ripple Effect, Mathrax and more.
- **Math (44):** 2048, KenKen, Magic Squares, Prime Hunter, Fraction Match, Quick Math, Sum Pyramid and more.
- **Memory (29):** Memory Matrix, Corsi Blocks, N-Back, Memory Palace, Digit Span, Face/Name and more.
- **Spatial (31):** Mental Rotation, Paper Folding, Cube Net Fold, Classic Maze, Mirror Image and more.
- **Attention (27):** Stroop, Flanker, Schulte Table, Trail Making, Go/No-Go, Visual Search and more.
- **Word (41):** Find Word, Crossword, Word Search, Word Ladder, Cryptogram, Word Scramble and more.

## Architecture

Cross-platform by design: a single Flutter/Dart codebase runs on Android, iOS, web, Windows, macOS and Linux.

- **State:** Riverpod (with codegen) + Hive for local persistence.
- **Game registry:** `lib/data/game_registry.dart`, one `*_metadata.dart` per game (`id`, `category`, `icon`, `color`, `builder`, localized title and subtitle, popularity). Adding a game is adding a screen, its metadata file, and one line in the registry.
- **Card shell:** `lib/widgets/deck.dart` — the mark, the wordmark, the paper card every
  surface is built from. `tool/icon.py` renders the same mark as the app icon
  (`dart run flutter_launcher_icons` writes the platform sets).
- **Board contract (Phase 1):** `lib/ui/core/board/` — one `PuzzleBoard` interface, one drag engine, five motion moves, five verbs. A puzzle is rules, geometry and paint; it owns no gestures.
- **Screen chrome (Phase 1):** `lib/ui/features/games/shared/board_game_scaffold.dart` — `BoardGameScaffold` with a board slot, hint/reset actions, a chip row and number chips. A board game screen is about forty lines.
- **Discovery layer:**
  - `lib/data/game_categories.dart` — the six rooms, plus derived feeds (quick play, deterministic daily pick, shuffle order).
  - `lib/ui/features/feed/feed_screen.dart` — the deal: one card per screen, swipe up.
  - `lib/ui/features/feed/feed_deck.dart` — the order cards are dealt in (a shuffled pass,
    never a repeat inside a pass, hidden games dropped first).
  - `lib/ui/features/feed/feed_session.dart` — the bridge that lets a game screen and its
    completion dialog behave as a card while the feed is on screen.
  - `lib/ui/features/home/discovery_home_screen.dart` — the stack: rooms, today, quick play.
  - `lib/ui/features/home/category_room_screen.dart` — a single category's puzzles, each
    tile drawn as a mini board of the game it opens (`lib/ui/core/preview/game_preview.dart`;
    contact sheet of every game in `docs/previews/previews.png`).
- **The archive:** `docs/CATALOG.md` files 89 games as lab tasks, worksheets and twins. They stay
  in the repo, they are not dealt, and one switch in settings (`Show archived puzzles`) is the
  only way to look at them. `GameFeed.browse` is the single decider for every list.

## Website

`docs/` is the website, served by GitHub Pages at <https://cyoren.github.io/Puzzlestack/>:
one page per puzzle (230), a page per room, an index and a hub, in the shape of a search-first
puzzle site. Every page carries the app's own guide text, the English title and one line, and
metadata (`canonical`, Open Graph, `BreadcrumbList`, `SoftwareApplication`, `FAQPage`).

It is generated, never hand-edited:

```bash
dart run tool/site_export.dart   # tool/site/games.json: the 230 playable games, from the repo
python3 tool/gen_site.py         # docs/: 238 pages, sitemap.xml, robots.txt, fonts
flutter test test/content/site_test.dart   # every game has a page, every link resolves
tool/deploy_pages.sh             # build the browser app, publish both to gh-pages
```

Pages serves the **`gh-pages`** branch: `docs/` plus `app/` (the Flutter web build, base href
`/Puzzlestack/app/`). The branch is force-pushed by `tool/deploy_pages.sh` and holds one commit,
so the 40 MB browser build never enters the history of the repo people clone. Every game page
offers `Play <game>` at `../app/index.html?game=<slug>`, and that query is what opens the named
puzzle (`lib/utils/deep_link.dart`).

`test/content/site_test.dart` is the contract: a game without a page fails, an archived game
with one fails, a broken internal link fails, a page without its playable link fails.
`PLAY_ANDROID` / `PLAY_IOS` in `tool/gen_site.py` are empty until 1.1.0 is on the stores, so a page
offers the browser build and the source instead of a dead store link.

## Build & run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.g.dart / *.freezed.dart
flutter run                                                 # or: flutter run -d chrome
```

The internal Dart package name stays `puzzle` (it is referenced by ~126 files and is invisible to users); the user-facing branding is Puzzlestack.

## Working on it

- **[ROADMAP.md](ROADMAP.md)** — what is left and in what order. Its **Open work** table at the
  top is the entry point: every remaining job is named, sized and linked.
- **[papercuts.md](papercuts.md)** — the friction. Test flags, Flutter traps that produced real
  bugs, and what porting from Tatham's C keeps teaching.
- **[PUZZLE_STYLE.md](PUZZLE_STYLE.md)** — the house style every board is held to.
- **[REFERENCE.md](REFERENCE.md)** — where each source lives, its licence and pinned commit.

## Releasing

See [RELEASE.md](RELEASE.md) for build and signing, the Play Data Safety
answers, and the store listing assets. [PRIVACY.md](PRIVACY.md) is the privacy
policy; [SCREENSHOTS.md](SCREENSHOTS.md) covers regenerating store screenshots.

## License

GPL-3.0. See [LICENSE](LICENSE).

Puzzlestack is a modified derivative of [Puzzle](https://github.com/sidhant947/Puzzle)
by Sidhant Khatkar, also GPL-3.0. See [NOTICE](NOTICE) for the attribution and
the list of modifications.
