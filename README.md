# PuzzleBox

A cross-platform suite of **161 minimalist brain puzzles**, built with Flutter. Logic, math, memory, spatial, attention and word games, all in one clean app, on Android, iOS, web, Windows, macOS and Linux.

PuzzleBox is a friendly fork of [sidhant947/Puzzle](https://github.com/sidhant947/Puzzle) (GPL-3.0) with two ideas at its heart:

1. **Shuffle feed (the "I'm bored" mode).** A full-screen, vertical, TikTok-style feed. Swipe up and you drop straight into a fresh random puzzle. No menus, no friction, just one more.
2. **Discovery home instead of a long list.** 161 games is a lot. The home is a calm discovery surface: a Shuffle hero, a Daily Pick, a Quick Play (under 2 min) row, "jump back in" recents, and the full catalog tucked into six category rooms.

---

## Why Flutter (and not Kotlin)

The upstream project is already 100% Flutter/Dart, so it is cross-platform out of the box: a single codebase runs on Android, iOS, web, Windows, macOS and Linux. No need to rewrite anything in Kotlin. We kept Flutter and built on top of it.

## The 161 games, by category

- **Logic (33):** Sudoku, Slitherlink, Kakuro, Nonogram, Minesweeper, Akari, Hitori, Bridges, Water Sort, Lights Out and more.
- **Math (35):** 2048, KenKen, Magic Squares, Prime Hunter, Fraction Match, Quick Math, Sum Pyramid and more.
- **Memory (25):** Memory Matrix, Corsi Blocks, N-Back, Memory Palace, Digit Span, Face/Name and more.
- **Spatial (20):** Mental Rotation, Paper Folding, Cube Net Fold, Classic Maze, Mirror Image and more.
- **Attention (31):** Stroop, Flanker, Schulte Table, Trail Making, Go/No-Go, Visual Search and more.
- **Word (17):** Find Word, Crossword, Word Search, Word Ladder, Cryptogram, Word Scramble and more.

## Architecture

- **State:** Riverpod (with codegen) + Hive for local persistence.
- **Game registry:** every game is one entry in `lib/data/game_data.dart` (`title`, `id`, `category`, `icon`, `color`, `builder`). Adding a game is adding one entry plus its `*_screen.dart`.
- **New in PuzzleBox:**
  - `lib/data/game_catalog.dart` — catalog helpers (by category, random game, quick-play set, deterministic daily pick).
  - `lib/ui/features/shuffle/shuffle_feed_screen.dart` — the vertical Shuffle feed.
  - `lib/ui/features/home/discovery_home_screen.dart` — the new discovery home.
  - `lib/ui/features/home/category_room_screen.dart` — a single category's puzzles.

## Build & run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.g.dart / *.freezed.dart
flutter run                                                 # or: flutter run -d chrome
```

The internal Dart package name stays `puzzle` (it is referenced by ~126 files and is invisible to users); only the user-facing branding is PuzzleBox.

## License

GPL-3.0, inherited from the upstream project. See [LICENSE](LICENSE).
