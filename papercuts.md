# Papercuts

Small things that cost real time and are not worth a PR each. Written down so the next agent
does not pay for them again. Nothing here is a bug in the product; it is all friction in the
work.

Ordered by how much time it actually cost.

---

## Tooling

### `flutter test` with default parallelism stalls for about five minutes

The box has 14 GB of RAM and Flutter spawns one isolate per core. It thrashes, then gives up.

```
flutter test -j 4
```

Always pass `-j 4`. Nothing in the repo enforces it, so a fresh agent will hit this once.

### `find.byType(PuzzleBoardView)` matches nothing

Dart erases generic type arguments at runtime, so `PuzzleBoardView<PuzzleState>` is not
`PuzzleBoardView`. A widget test written the obvious way silently finds zero widgets and the
failure looks like "the board did not render".

```dart
final Finder _boardFinder =
    find.byWidgetPredicate((widget) => widget is PuzzleBoardView);
```

### `gh pr create` refuses to open PRs on this repo

It reports *"No commits between main and <branch>"* even when the branch is ahead. Nobody has
worked out why. Use the API directly, which works every time:

```bash
python3 -c "import json; print(json.dumps({'title': ..., 'head': ..., 'base': 'main', 'body': ...}))" > /tmp/pr.json
gh api repos/cYoren/Puzzlestack/pulls -X POST --input /tmp/pr.json
```

### `dart format` on a directory rewrites the whole repo

The SDK's formatter is the new "tall style" and this tree predates it. `dart format lib/ui`
reformatted **967 files** that had nothing to do with the change. Format the files you touched,
by name, or not at all.

### A widget test only remembers the first exception

`tester.takeException()` returns the first error and, once a second one arrives, starts
returning `FlutterError("Multiple exceptions (N) were detected")` instead of the errors. The
count is per test and never resets, so a loop over many games blames every game after the first
one that breaks. That is how the 320dp audit reported 34 games "throwing" when none did.

The fix, now in `test/board/game_audit.dart`: one `testWidgets` per game, and capture
`FlutterErrorDetails` by swapping `FlutterError.onError` for the duration of the pump. The
details carry the widget and its `file:line`, which `takeException` throws away.

### `flutter gen-l10n` prints a warning that is not a warning

> To use the command line arguments, delete the l10n.yaml file in the Flutter project

It appears on every successful run. Ignore it.

### `build_runner` takes about 75 seconds and rewrites 450 files

It has to run after adding a Riverpod notifier or touching an `.arb` file. Plan for it; do not
run it twice in a row hoping the second one is faster.

### A const constructor cannot assert on `list.length`

`assert(clues.length == rows * cols)` is not a constant expression, so a class with that assert
cannot have a `const` constructor. Either drop the assert or drop the `const`. Dropping the
assert is the worse trade — the assert catches a real class of bug (a clue list that does not
match the board).

---

## Flutter traps that produced real bugs

### A `continue` that skips an assignment

Three separate bugs in two puzzles came from this shape:

```dart
if (something) {
  if (!inBounds) continue;   // skips the line below
  usable[d] = white[d];      // never runs
  continue;
}
```

The direction then counted as having zero room, and the rule declared a valid board impossible.
When a loop body ends in `continue`, put every assignment that later code depends on *before*
the first `continue`.

### A rule that reports success instead of news

`deduce` loops until no rule reports progress. A rule that returns "I settled 3 cells" when it
re-settled cells that were already settled makes the loop run forever. The model method has to
distinguish "changed something" (1) from "already knew that" (0) from "contradiction" (-1).

This one hangs the test runner rather than failing it, which is much harder to read.

### A widget test that opens a random game

`home_smoke_test.dart` opened a different one of 307 games per run and failed about one run in
three, because some games overflow or leave timers. A test that fails a third of the time tells
you nothing about anything. Pin the random thing.

### Pending timers fail a widget test after it passes

If a game starts a timer in `initState`, the test fails at teardown with "Pending timers" even
though every assertion passed. Tear the tree down before the test ends:

```dart
await tester.pumpWidget(const SizedBox());
await tester.pump();
```

---

## Porting from Tatham's C

### The C is right and the comment is wrong

Four bugs in Kurodoko, and every one was me "improving" something that looked redundant:

- a mask that looked like a copy-paste error was load-bearing,
- a check that looked missing had been left out on purpose,
- a fourth counting run that looked like a duplicate was a different question.

When the port disagrees with the C, work out *why* the C does it before deleting it. The
`ROADMAP.md` Phase 3 section records all four in detail.

### `rectangles.c` does not exist in the pinned clone

`~/Projects/puzzlestack-reference/tatham-c` is pinned at `616da16` and has 74 `.c` files, but no
`rectangles.c`. Rectangles is covered by `shikaku`, which came from the merge, so this only
matters if you go looking for the file.

### Names lie, in both directions

Checking the registry beat guessing, three times:

- 8 of the "21 missing" Tatham puzzles had arrived under other names (Pearl is `masyu`).
- Kurodoko *is* Tatham's Range, so "port Range" was already done.
- `cube_net_fold` is not `cube.c`, and `mental_mapping` is not `map.c`.

Before porting anything, grep `lib/ui/features/games/` for the concept, not the name.

### Generation cost is dominated by rejecting boards, not building them

A Kurodoko hard board takes 172 ms because most proposals come back easier than asked for and
get thrown away. Before optimising the generator, measure whether the time is in `propose` or in
the loop around it — it is almost always the loop.

---

## The review loop

### Codex review is out of credits

Every PR gets a comment saying *"We couldn't complete this review."* The house rule is
self-review, then merge. What that actually costs: the four Kurodoko bugs above were all found
by hand, and two of them (the infinite loop, the unsound `beyond`) would have been caught in
minutes by a reviewer reading the diff.

Until credits return, the substitute is:

1. Write the soundness test **before** the PR, not after. It found three of the four bugs.
2. Re-read every early `continue` and every `return` in a loop.
3. Check the diff for a rule that reports progress without changing anything.

### The `pr` skill template is not optional

`~/.config/opencode/skills/pr/SKILL.md` — Summary, Evidence, Merge Danger with Door and Blast
Radius. The Evidence section is the useful half: it forces the before/after numbers into the PR
where a reviewer can check them.

---

## Measuring things

### `test/board/game_audit.dart` is a tool, not a test

It is deliberately not named `_test.dart` so the suite does not run it. It reports a number
rather than asserting one, because the number is currently bad enough that a red suite would
only repeat what it already says.

```
flutter test test/board/game_audit.dart
AUDIT checked=307 overflow=85 threw=34
```

The count moves by one or two between runs; a few games randomise their layout. Treat it as
"about 119".

### The test suite is now 2 minutes

`flutter test -j 4` takes about 2 minutes, and the Kurodoko engine test alone is 98 seconds of
that because it counts 600 boards. That is the bar doing its job, not a problem to fix — but do
not run the full suite between small edits. Run the one file you are working on.

### A game screen cannot tell it is in the feed

`GameScaffold` is the one seam every game goes through (313 screens, zero exceptions), so embed
mode lives there and is switched by `FeedSession.inFeed`. What it must not do is grow a second
one: a game that reads the feed directly, or a "feed variant" of a game screen, is the start of
313 special cases. If a card needs different chrome, it is the card's job, not the game's.

The corollary, found the hard way: a completion dialog is pushed on the *root* navigator, so it
sits outside the feed's widget subtree. An `InheritedWidget` will not reach it. `FeedSession` is
a static handle for that reason alone.
