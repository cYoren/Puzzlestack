# Adding a New Game

This guide explains how to add a new puzzle game to Puzzlestack.

## Step 1: Create Game Directory

```
lib/ui/features/games/your_game/
├── your_game_engine.dart      # Pure Dart logic
├── your_game_provider.dart    # Riverpod state management
├── your_game_screen.dart      # Flutter UI
├── your_game_board.dart       # Optional: the CustomPaint board, for a grid game
└── your_game_metadata.dart    # Game registration
```

Then, before the game can ship: register it in `lib/data/game_registry.dart`, add guide text to
`lib/data/game_guides.dart`, add its keys to `lib/l10n/app_en.arb`, and add a
`test/content/<your_game>_test.dart` that asserts the game's own rule.
`test/content/registry_test.dart` fails until the guide and the store copy agree with the
registry.

**English is the source locale.** Add keys to `app_en.arb` and run `flutter gen-l10n`; every other
locale falls back to English for a key it does not have, so a new game does not open six
translation jobs. Do not hand-edit a generated `app_localizations_*.dart`.

**A new game enters as Library**, never as a Deck card (see PRODUCT.md: the Deck is the fixed
front of the product, the Library is where new work lands). Three files then have to agree with
`docs/CATALOG.md`, or `registry_test` fails: the catalog row, `lib/data/game_profiles.dart`
(regenerate with `python3 tool/gen_game_profiles.py`), and the visible count — which lives in
`README.md`, `docs/index.html`, `web/index.html`, `web/manifest.json`, six
`fastlane/metadata/*/en-US/*.txt`, and `docs/CATALOG.md`.

## Step 2: Implement the Engine

The engine contains pure Dart logic with no Flutter dependencies:

```dart
// your_game_engine.dart
import 'dart:math';

class YourGameEngine {
  // Generate a new puzzle
  YourGameState generatePuzzle() {
    // Implementation
  }
  
  // Check if the puzzle is solved
  bool isSolved(YourGameState state) {
    // Implementation
  }
  
  // Validate a move
  bool isValidMove(YourGameState state, int row, int col, int value) {
    // Implementation
  }
}
```

**Key principles:**
- No Flutter imports (no `package:flutter/`)
- Only `dart:math` for randomness
- Pure functions where possible
- Return new state objects, don't mutate

## Step 3: Create State Model

Define the game state using Freezed:

```dart
// your_game_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'your_game_state.freezed.dart';

@freezed
class YourGameState with _$YourGameState {
  const factory YourGameState({
    required List<List<int>> board,
    required bool isSolved,
    required int moves,
  }) = _YourGameState;
}
```

## Step 4: Implement the Provider

Use Riverpod with code generation:

```dart
// your_game_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'your_game_engine.dart';
import 'your_game_state.dart';

part 'your_game_provider.g.dart';

@riverpod
class YourGameNotifier extends _$YourGameNotifier {
  @override
  YourGameState build() {
    return YourGameEngine().generatePuzzle();
  }

  void makeMove(int row, int col, int value) {
    final engine = YourGameEngine();
    if (engine.isValidMove(state, row, col, value)) {
      // Update state
    }
  }

  void resetGame() {
    state = YourGameEngine().generatePuzzle();
  }
}
```

## Step 4a: Paint through the shared marks, and scaffold the screen

Two shared layers exist so that a design rework is one edit, not forty. Use both; a new board and
screen that hand-roll their own drawing or their own `Column` of paddings is the thing these
exist to stop.

- **`lib/ui/core/board/puzzle_marks.dart`** — `PuzzleMarks(canvas)` gives the house vocabulary for
  anything drawn inside a cell: `tile` (an empty cell), `block` (a solid object, with `join` so a
  run of them reads as one body), `dotMark`, `crossMark`, `ringMark`, `hatch`, `band`, `arrow`,
  `label` (numbers and letters), `hint` (the ring that points at a proved cell). Colours come from
  `MarkRole`, never from a raw `Color`, so light, AMOLED dark and any future palette land in one
  file. A board supplies the arrangement; the mark supplies the look.
- **`lib/ui/features/games/shared/board_game_scaffold.dart`** — `BoardGameScaffold(title,
  subtitle, board, actions, hud, toolbar, footer)`, plus `GameStat` for a number chip,
  `BoardGameChipRow` for a size or difficulty row, and `BoardGameActions` for hint + reset. A game
  screen becomes about forty lines: read the provider, hand the board in, wire `onSolved`.

Both are additive: the older boards keep their own paint and chrome until someone touches them.

## Step 5: Build the Screen

A board game screen is a `ConsumerWidget` of about forty lines: read the provider, hand the board
to `BoardGameScaffold`, wire `onSolved`. Nothing else — no gesture, no padding stack, no colour.

```dart
// your_game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_providers.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../core/board/puzzle_board_view.dart';
import '../shared/board_game_scaffold.dart';
import 'your_game_board.dart';
import 'your_game_provider.dart';

class YourGameScreen extends ConsumerWidget {
  const YourGameScreen({super.key});

  Future<void> _onSolved(BuildContext context, WidgetRef ref, YourGameNotifier notifier) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(gameStreakNotifierProvider.notifier).completeGame('your_game', xpAmount: 30);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.yourGameWinTitle,
        message: l10n.yourGameWinMessage,
        onHome: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(dialogContext).pop();
        },
        onPlayAgain: () {
          notifier.newGame();
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(yourGameNotifierProvider);
    final notifier = ref.read(yourGameNotifierProvider.notifier);

    return BoardGameScaffold(
      // The title as written, in sentence case. No toUpperCase: shouting is not a style.
      title: l10n.yourGameTitle,
      subtitle: l10n.yourGameSubtitle,
      actions: [BoardGameActions(onHint: notifier.hint, onReset: notifier.newGame)],
      toolbar: BoardGameChipRow(
        chips: [
          for (final size in YourGameSize.values)
            BoardGameChip(
              label: size.label,
              selected: state.size == size,
              onTap: () => notifier.setSize(size),
            ),
        ],
      ),
      hud: [
        GameStat(
          label: l10n.yourGameProgress.toUpperCase(),
          value: '${state.placed}',
          color: DesignSystem.primary,
        ),
      ],
      // A move is data, not a callback: the board says what can happen, the
      // view draws it, the notifier decides. `isSolved` comes from the state.
      board: PuzzleBoardView<YourGameState>(
        board: YourGameBoard(state: state),
        onMove: (move) => notifier.tap(move.source),
        onSolved: () => _onSolved(context, ref, notifier),
      ),
    );
  }
}
```

A hint applies its value — it never just outlines a cell. Anyone who taps hint twice must not get
the same outline twice, so the proved value goes into the state through the ordinary move path.

## Step 6: Create Metadata

Register the game with its metadata:

```dart
// your_game_metadata.dart
import 'package:flutter/material.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/utils/design_system.dart';
import 'your_game_screen.dart';

final yourGameMetadata = GameMetadata(
  id: 'your_game',
  category: 'LOGIC', // LOGIC, MATH, MEMORY, SPATIAL, ATTENTION, WORD
  icon: Icons.extension_rounded,
  color: DesignSystem.gameBlue,
  builder: (context) => YourGameScreen(),
  titleGetter: _title,
  subtitleGetter: _subtitle,
  popularity: Popularity.default_, // high, default_, low
);

String _title(BuildContext context) => AppLocalizations.of(context)!.yourGameTitle;
String _subtitle(BuildContext context) => AppLocalizations.of(context)!.yourGameSubtitle;
```

## Step 7: Register in Game Registry

Add ONE import to `lib/data/game_registry.dart`:

```dart
import '../ui/features/games/your_game/your_game_metadata.dart';
```

And add the metadata to the list:

```dart
final List<GameMetadata> allGamesMetadata = [
  // ... existing games
  yourGameMetadata,
];
```

## Step 8: Add Localization

Add entries to `lib/l10n/app_en.arb`:

```json
{
  "yourGameTitle": "Your Game",
  "yourGameSubtitle": "Description of your game",
  "@yourGameTitle": {
    "description": "Title of your game"
  }
}
```

## Step 9: Add Tests

Two files, and the second is the one that catches a wrong game.

1. `test/engines/your_game_engine_test.dart` — the deal is legal, its answer is legal, the clues are
   on the board (not hidden behind it), the clues pin down exactly one answer, the clues can be
   finished without guessing (`rate(model, rules).verdict == PuzzleVerdict.solved`), a hint writes a
   value the answer agrees with, and a board can be finished through the ordinary input path.
2. `test/content/your_game_test.dart` — the content rule: every dealt board obeys the game's own
   rule, and the clue set is exactly what the rule says it is.

Create `test/engines/your_game_engine_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/your_game/your_game_engine.dart';

void main() {
  group('YourGameEngine', () {
    late YourGameEngine engine;

    setUp(() {
      engine = YourGameEngine();
    });

    test('generates valid puzzle', () {
      final state = engine.generatePuzzle();
      expect(state, isNotNull);
    });

    test('validates moves correctly', () {
      final state = engine.generatePuzzle();
      expect(engine.isValidMove(state, 0, 0, 1), isTrue);
    });
  });
}
```

## Step 10: Run Verification

```bash
flutter analyze                                            # must be clean
TMPDIR=$HOME/.cache/tmp flutter test -j 4                  # the whole suite, one at a time
TMPDIR=$HOME/.cache/tmp AUDIT_ONLY=your_game flutter test test/board/game_audit.dart
TMPDIR=$HOME/.cache/tmp AUDIT_ONLY=your_game AUDIT_DARK=1 flutter test test/board/game_audit.dart
```

The audit mounts the board at phone size in both themes, prints
`AUDIT checked=1 overflow=0 threw=0` per theme and then **fails** if either count is not zero. It is
the only check that sees a board that builds and cannot be held; read the printed line too, because
it is the record of what was pumped.

`TMPDIR` is not optional: the default temp directory on a sandboxed Linux box makes the test runner
fail in ways that look like test failures. One `flutter test` at a time, `-j 4`.

If the game has Riverpod providers, regenerate their `.g.dart` with
`dart run build_runner build` (the repo commits them; a provider whose
`.g.dart` is stale fails at compile time, not at runtime).

## Best Practices

1. **Keep the engine pure**: no Flutter dependencies in `*_engine.dart`, so the generator and its
   proof can run in a plain Dart test.
2. **Use Freezed**: for immutable state models.
3. **Use code-gen**: for Riverpod providers (`@riverpod`), and commit the generated `.g.dart`.
4. **Add haptics**: call `HapticFeedbackUtil` on user interactions.
5. **Add semantics**: include `semanticsLabel` on interactive elements.
6. **Handle errors**: use try/catch in provider methods.
7. **Add tests**: cover the engine, and the content rule, with tests that would fail on a broken deal.
8. **Never let `0` mean two things.** A blank, an empty cell, "no clue" and "no value" are
   different states; a sentinel that doubles as an answer is a bug that hides in the win test.
9. **Never ship a game the generator cannot prove.** Retry, and throw rather than deal an unproved
   board: a wrong board is worse than a missing one.
