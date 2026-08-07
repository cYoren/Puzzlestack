# Mindstack

A cross-platform suite of **161 minimalist brain puzzles**, built with Flutter. Logic, math, memory, spatial, attention and word games, all in one clean, authoritative app, on Android, iOS, web, Windows, macOS and Linux.

Two ideas sit at the heart of Mindstack:

1. **Shuffle feed (the "I'm bored" mode).** A full-screen, vertical, TikTok-style feed. Swipe up and you drop straight into a fresh random puzzle. No menus, no friction, just one more.
2. **Discovery home instead of a long list.** 161 games is a lot. The home is a calm discovery surface: a Shuffle hero, a Daily Pick, a Quick Play (under 2 min) row, "jump back in" recents, and the full catalog tucked into six category rooms.

---

## The 161 games, by category

- **Logic (33):** Sudoku, Slitherlink, Kakuro, Nonogram, Minesweeper, Akari, Hitori, Bridges, Water Sort, Lights Out and more.
- **Math (35):** 2048, KenKen, Magic Squares, Prime Hunter, Fraction Match, Quick Math, Sum Pyramid and more.
- **Memory (25):** Memory Matrix, Corsi Blocks, N-Back, Memory Palace, Digit Span, Face/Name and more.
- **Spatial (20):** Mental Rotation, Paper Folding, Cube Net Fold, Classic Maze, Mirror Image and more.
- **Attention (31):** Stroop, Flanker, Schulte Table, Trail Making, Go/No-Go, Visual Search and more.
- **Word (17):** Find Word, Crossword, Word Search, Word Ladder, Cryptogram, Word Scramble and more.

## Architecture

Cross-platform by design: a single Flutter/Dart codebase runs on Android, iOS, web, Windows, macOS and Linux.

- **State:** Riverpod (with codegen) + Hive for local persistence.
- **Game registry:** every game is one entry in `lib/data/game_data.dart` (`title`, `id`, `category`, `icon`, `color`, `builder`). Adding a game is adding one entry plus its `*_screen.dart`.
- **Discovery layer:**
  - `lib/data/game_catalog.dart` — catalog helpers (by category, random game, quick-play set, deterministic daily pick).
  - `lib/ui/features/shuffle/shuffle_feed_screen.dart` — the vertical Shuffle feed.
  - `lib/ui/features/home/discovery_home_screen.dart` — the discovery home.
  - `lib/ui/features/home/category_room_screen.dart` — a single category's puzzles.

## Build & run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.g.dart / *.freezed.dart
flutter run                                                 # or: flutter run -d chrome
```

The internal Dart package name stays `puzzle` (it is referenced by ~126 files and is invisible to users); the user-facing branding is Mindstack.

## Releasing

See [RELEASE.md](RELEASE.md) for build and signing, the Play Data Safety
answers, and the store listing assets. [PRIVACY.md](PRIVACY.md) is the privacy
policy; [SCREENSHOTS.md](SCREENSHOTS.md) covers regenerating store screenshots.

## License

GPL-3.0. See [LICENSE](LICENSE).

Mindstack is a modified derivative of [Puzzle](https://github.com/sidhant947/Puzzle)
by Sidhant Khatkar, also GPL-3.0. See [NOTICE](NOTICE) for the attribution and
the list of modifications.
