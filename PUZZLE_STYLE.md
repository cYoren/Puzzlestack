# The Puzzlestack house style

228 puzzles have to feel like one app. Today they share colours and fonts and nothing else.

Measured on the current tree:

| | Count |
| --- | --- |
| Games that paint their board with `CustomPainter` | 19 |
| Games built from widget grids | 142 |
| Games with any drag interaction | **0** |
| Games calling haptics through `HapticFeedbackUtil` | 152 (good) |
| Games with their own `AnimationController` | 7 |

So: two rendering philosophies, no drag anywhere, and almost no motion. Colour and haptics are
already shared; **feel is not**. Porting 67 more puzzles before fixing that would bake the
inconsistency in 67 more times.

This document is the fix. It is the gate every port and every rebuild passes.

---

## 1. One board contract

Every puzzle, old or new, implements the same interface. A puzzle is rules + a generator;
it is not a screen, and it does not own gestures.

```dart
abstract class PuzzleBoard<S extends PuzzleState> {
  S get state;

  /// What this element can become. This is the whole interaction model.
  List<PuzzleMove<S>> movesFor(ElementRef element);

  S apply(S state, PuzzleMove<S> move);
  bool get isSolved;

  /// How to draw one frame. Shared chrome, shared metrics, puzzle-specific glyphs.
  void paint(PuzzleCanvas canvas, S state);
}
```

A puzzle that draws its own chrome, or wires its own `GestureDetector`, does not pass.

### What landed (Phase 1)

`lib/ui/core/board/` is the whole interaction layer. Four files, no puzzle-specific
code in any of them:

| File | What it owns |
| --- | --- |
| `puzzle_board.dart` | `PuzzleBoard`, `PuzzleMove`, `ElementRef`, `PuzzleCanvas`, `PuzzlePalette`, `BoardHighlight` |
| `puzzle_board_view.dart` | the drag engine: hit test, lift, follow, drop zones, snap, recoil, win cascade |
| `board_motion.dart` | the five moves and their springs, in one place |
| `board_verb.dart` | the five verbs, mapped to `HapticFeedbackUtil` |

Three details that make a port short:

**Geometry is normalised.** `boundsOf()` returns a `Rect` in 0..1 across the board box, and
`PuzzleCanvas` converts to pixels. A board never learns its own size, so the same code paints
at 320dp and on a tablet, and `hitTest` works without a layout pass.

**A move carries its own transition.** `PuzzleMove.apply` is `S Function(S)`, so the notifier
that stores state never learns a puzzle's rules:

```dart
void applyMove(PuzzleMove<SudokuState> move) {
  final next = move.apply(state);
  state = next.copyWith(isSolved: _isSolved(next));
}
```

**`paintElement` is required.** The engine draws the floating copy during a drag and the pop
during the win cascade by calling it, so a board never duplicates its drawing code and never
needs to know it is being animated.

A move with a `target` is draggable; a move without one resolves on tap. That single rule is
why the same engine gives Sudoku a digit you can carry onto a cell, Slitherlink a line you
draw from dot to dot, and Water Sort a tube you pour into another.

## 2. Dragging is declared, not coded

The interaction layer follows **Declarative Dragging** (Horowitz, Blinn & Heer, UIST 2026,
Best Paper — <https://declarative-dragging.github.io/>).

The idea: instead of hand-writing geometry, feedback and animation for every drag, you
declare *which future states a drag can lead to*. The engine speculatively renders those
states, works out where the dragged element lands in each, and synthesizes the drag — float,
drop zones, snapping, transitions — from that.

Why this is the right foundation for 228 puzzles:

- **One drag feel, everywhere.** Connect an island in Bridges, place a tent, swap two tiles,
  slide a row in Netslide: same lift, same snap, same settle, because it is one engine.
- **The rules stay in the rules.** `movesFor()` is the puzzle's whole input surface. A port
  from Tatham's C is then generator + rules + paint, with no gesture code to write or get
  wrong.
- **Discoverability.** Legal targets can be shown while dragging, which is what makes a
  puzzle feel considered rather than guessed at.

Tap remains a first-class path: a tap is a drag that resolved immediately. Puzzles must be
fully playable without dragging, for accessibility.

### What we take from the paper, and what we leave

The demos are **grabby**: things come up with weight, follow your hand, and the world shows
you what is possible while you hold them. That is not decoration, it is the mechanism — you
cannot read a speculative state if the motion is too tight to see it. So we take the
weight and the reveal.

We leave the drift. The demos are desktop mouse, where lag reads as mass; under a finger,
lag reads as broken. On touch the element tracks 1:1, offset 12dp above the fingertip so the
finger does not cover the thing it holds.

We also leave the long tails. A mouse can enjoy a 400ms settle; a thumb doing forty moves a
minute cannot. The rule is **heavy lift, fast land**: generous on the way up, decisive on the
way down. That is what a well-made physical object does, and it is satisfying in a way that
neither Apple-quiet nor toy-floaty is.

## 3. Visual language

On top of `DesignSystem` (Geist, indigo `#4338CA`, amber `#D97706`, AMOLED dark). Board rules:

| Rule | Value |
| --- | --- |
| Touch target | 44dp minimum per cell, always |
| Cell gap | 2dp light / 1.5dp dark |
| Board radius | `radiusMD` (16) — the board is one object, not a tray of tiles |
| Cell radius | `radiusXS` (8), never fully round |
| Stroke weights | **three only**: 1.5 cell, 2.5 given clue, 3 user mark |
| Shadows | none inside the board |
| Gradients | none inside the board |
| Fills per cell | two maximum (base + one state) |

Colour means state, never decoration:

| State | Colour |
| --- | --- |
| Given clue | `ink` / `darkInk` |
| User mark | `primary` `#4338CA` |
| Conflict | `error` `#EF4444`, 12% fill + 1.5 stroke |
| Solved | `success` `#10B981` |
| Empty cell | `surface` white / `#1E1E1E` |
| Board bed | `background` `#F8FAFC` / `#121212` |

Dark mode is AMOLED: board bed is true black, cells `#1E1E1E`, no white text on white fills.

## 4. Motion

Five moves. Nothing longer than 300ms. Nothing loops. **Heavy lift, fast land.**

| Move | Duration | Curve |
| --- | --- | --- |
| Press | 90ms, scale 0.97 | `easeOut` |
| Lift (drag start) | **200ms**, scale 1.08 | spring 260/20 — visible overshoot, weight |
| Drag follow | 1:1 tracking, 12dp above the finger | none — no lag on touch |
| Drop zones | 120ms fade in, `primary` at 8% | `easeOut` |
| Snap (drop) | **160ms**, spring 500/30 | decisive, 1–2% overshoot, never bouncy |
| Invalid | 220ms recoil to origin, spring 320/24, plus an `error` tint pulse | `easeOut` |
| Win cascade | 45ms stagger, 260ms per cell, 1.0→1.06→1.0 pop | `easeOutCubic` |

The asymmetry is the point: 200ms up, 160ms down. The lift is where the object gains
weight and the possible worlds appear; the landing is where it commits. Equal durations
read as a toggle, not as a grab.

The win cascade keeps its 45ms stagger only while it fits: `BoardMotion.staggerFor(count)`
compresses it so a full 81-cell board still finishes inside 500ms instead of taking four
seconds.

Motion is feedback, not decoration. If a cell moves, the player learned something.

## 5. Five verbs

One file, `HapticFeedbackUtil`, already exists. Games emit verbs; they never call
`HapticFeedback` directly. Sound, when enabled, maps to the same five.

| Verb | Haptic | Meaning |
| --- | --- | --- |
| `select` | selection click | touched something |
| `place` | medium | a mark landed |
| `invalid` | heavy | that move is illegal |
| `solve` | heavy + success | puzzle finished |
| `lift` | light | drag began |

## 6. The gate

A puzzle is on brand when all of these are true:

1. It implements `PuzzleBoard`; no `GestureDetector`, no `CustomPaint` outside the contract.
2. It emits verbs, not raw haptics.
3. It uses the motion moves with the values above — including the asymmetry: nothing lands
   slower than it lifted.
4. It is playable by tap alone, and better by drag.
5. It passes the uniqueness test (roadmap Phase 3 bar).
6. It looks right in light and AMOLED dark, at 320dp width and on a tablet.

Anything that fails 1–3 is not a port, it is a fork of the app inside the app.
