# Puzzlestack

A cross-platform suite of **304 minimalist brain puzzles**, built with Flutter. Logic, math, memory, spatial, attention and word games, all in one clean, authoritative app, on Android, iOS, web, Windows, macOS and Linux.

Two ideas sit at the heart of Puzzlestack:

1. **Shuffle feed (the "I'm bored" mode).** A full-screen, vertical, TikTok-style feed. Swipe up and you drop straight into a fresh random puzzle. No menus, no friction, just one more.
2. **Discovery home instead of a long list.** 304 games is a lot. The home is a calm discovery surface: a Shuffle hero, a Daily Pick, a Quick Play (under 2 min) row, "jump back in" recents, and the full catalog tucked into six category rooms.

---

## The 304 games, by category

- **Logic (44):** Sudoku, Slitherlink, Kakuro, Nonogram, Minesweeper, Akari, Hitori, Bridges, Water Sort, Lights Out and more.
- **Math (63):** 2048, KenKen, Magic Squares, Prime Hunter, Fraction Match, Quick Math, Sum Pyramid and more.
- **Memory (54):** Memory Matrix, Corsi Blocks, N-Back, Memory Palace, Digit Span, Face/Name and more.
- **Spatial (38):** Mental Rotation, Paper Folding, Cube Net Fold, Classic Maze, Mirror Image and more.
- **Attention (54):** Stroop, Flanker, Schulte Table, Trail Making, Go/No-Go, Visual Search and more.
- **Word (51):** Find Word, Crossword, Word Search, Word Ladder, Cryptogram, Word Scramble and more.

## Architecture

Cross-platform by design: a single Flutter/Dart codebase runs on Android, iOS, web, Windows, macOS and Linux.

- **State:** Riverpod (with codegen) + Hive for local persistence.
- **Game registry:** `lib/data/game_registry.dart`, one `*_metadata.dart` per game (`id`, `category`, `icon`, `color`, `builder`, localized title and subtitle, popularity). Adding a game is adding a screen, its metadata file, and one line in the registry.
- **Board contract (Phase 1):** `lib/ui/core/board/` — one `PuzzleBoard` interface, one drag engine, five motion moves, five verbs. A puzzle is rules, geometry and paint; it owns no gestures.
- **Discovery layer:**
  - `lib/data/game_categories.dart` — the six rooms, plus derived feeds (quick play, deterministic daily pick, shuffle order).
  - `lib/ui/features/shuffle/shuffle_feed_screen.dart` — the vertical Shuffle feed.
  - `lib/ui/features/home/discovery_home_screen.dart` — the discovery home.
  - `lib/ui/features/home/category_room_screen.dart` — a single category's puzzles.

## Build & run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.g.dart / *.freezed.dart
flutter run                                                 # or: flutter run -d chrome
```

The internal Dart package name stays `puzzle` (it is referenced by ~126 files and is invisible to users); the user-facing branding is Puzzlestack.

## Releasing

See [RELEASE.md](RELEASE.md) for build and signing, the Play Data Safety
answers, and the store listing assets. [PRIVACY.md](PRIVACY.md) is the privacy
policy; [SCREENSHOTS.md](SCREENSHOTS.md) covers regenerating store screenshots.

## License

GPL-3.0. See [LICENSE](LICENSE).

Puzzlestack is a modified derivative of [Puzzle](https://github.com/sidhant947/Puzzle)
by Sidhant Khatkar, also GPL-3.0. See [NOTICE](NOTICE) for the attribution and
the list of modifications.
