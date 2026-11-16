import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/game_metadata.dart';
import '../../../utils/design_system.dart';

/// What a game *is*, drawn small enough to sit on its tile.
///
/// A tile used to carry an icon and a title. An icon says "puzzle", not
/// "Nonogram": forty of them repeat across the catalogue, which is why the grid
/// read as a list of identical cards. This draws the shape of the game instead —
/// a grid with a few cells inked, a route through a maze, three letter tiles, a
/// balance beam — so a player picks by recognition, the way they pick a card off
/// a table.
///
/// The vocabulary is the deck's own: paper, ink, hairline, and the one signal
/// colour. Never a category hue (see `DESIGN.md`), never a photograph, never a
/// gradient. Thirteen motifs cover the catalogue, and each one is different for
/// every game because the layout comes from a hash of the id.
enum GamePreviewKind {
  /// A grid puzzle: sudoku, nonogram, akari, slitherlink.
  grid,

  /// A route through walls, start to exit.
  maze,

  /// A line of travel across cells, with the ball that stops only at a wall.
  ball,

  /// A dotted trail between two points: tracing, path drawing, bridges.
  path,

  /// Letter tiles: anagrams, ladders, word wheels, crosswords.
  letters,

  /// Two words crossing, as a crossword does.
  word,

  /// Arithmetic in ink: operands, an operator, an answer to find.
  numbers,

  /// Overlapping cards: recall, matching, pairs.
  cards,

  /// A pad of dots with a chain through it: sequence and span tasks.
  dots,

  /// Concentric rings and a mark to hit: reflex and precision.
  target,

  /// One shape and a turned copy: rotation, folding, mirrors.
  arrows,

  /// A beam on a fulcrum: balance, equality, inequality.
  bars,

  /// A clock face: time, calendars, modular arithmetic.
  clock,

  /// Stacked blocks and tubes: sorting, pouring, towers.
  stack,

  /// Nested outlines: sets, symmetry, tangrams, silhouettes.
  shapes,
}

/// The kind for a game.
///
/// A rule list, first match wins, then the room's default. It is a mapping over
/// names rather than a hand-written table of 319 entries: names in this registry
/// carry their family (`*_span`, `*_maze`, `*_rotation`), so one rule covers a
/// dozen games and a new port is covered the day it lands.
GamePreviewKind previewKindFor(String id, String category) {
  final String key = id.toLowerCase();

  for (final MapEntry<RegExp, GamePreviewKind> rule in _rules) {
    if (rule.key.hasMatch(key)) return rule.value;
  }

  switch (category) {
    case 'LOGIC':
      return GamePreviewKind.grid;
    case 'MATH':
      return GamePreviewKind.numbers;
    case 'MEMORY':
      return GamePreviewKind.cards;
    case 'SPATIAL':
      return GamePreviewKind.arrows;
    case 'ATTENTION':
      return GamePreviewKind.target;
    case 'WORD':
      return GamePreviewKind.letters;
    default:
      return GamePreviewKind.grid;
  }
}

/// Rules that beat the room default. Ordered: the first match wins, so the
/// narrow ones (`crossword`, `inertia`) sit above the broad ones (`word`,
/// `maze`).
final List<MapEntry<RegExp, GamePreviewKind>> _rules = [
  // Specific games first, because their names would otherwise land in a family
  // they do not belong to.
  MapEntry(RegExp(r'^inertia$'), GamePreviewKind.ball),
  MapEntry(RegExp(r'crossword|cross_word'), GamePreviewKind.word),
  MapEntry(
      RegExp(r'word_search|find_word|word_snake|word_grid|word_mastermind'),
      GamePreviewKind.word),
  MapEntry(
      RegExp(r'klotski|tangle|block_escape|block_stacking|tower_of_london'),
      GamePreviewKind.stack),
  MapEntry(RegExp(r'water_sort|hue_sort|color_flood|pegs|twiddle'),
      GamePreviewKind.stack),
  MapEntry(RegExp(r'balance|inequalit|equation'), GamePreviewKind.bars),
  MapEntry(RegExp(r'clock|calendar|temporal'), GamePreviewKind.clock),
  MapEntry(
      RegExp(r'rotation|rotate|gear|folding|fold_net|cube_net|mirror|symmetr'),
      GamePreviewKind.arrows),
  MapEntry(RegExp(r'venn|tangram|silhouette|topology|negative_space|navon'),
      GamePreviewKind.shapes),
  MapEntry(
      RegExp(r'corsi|simon|sequence|n_back|nback|span|flash|chain_reaction'),
      GamePreviewKind.dots),
  MapEntry(RegExp(r'maze|signpost|ascent|seismic|num_path|number_path'),
      GamePreviewKind.maze),
  MapEntry(RegExp(r'trace|path|bridges|laser|pipes|slitherlink|yajilin|masyu'),
      GamePreviewKind.path),
  MapEntry(
      RegExp(
          r'sudoku|kenken|kakuro|kakurasu|mathrax|clusters|skyscraper|futoshiki'),
      GamePreviewKind.grid),
  MapEntry(
      RegExp(r'nonogram|hitori|heyawake|nurikabe|fillomino|galaxies|shikaku'),
      GamePreviewKind.grid),
  MapEntry(RegExp(r'akari|lighthouses|dominosa|magnets|tents|norinori|gokigen'),
      GamePreviewKind.grid),
  MapEntry(
      RegExp(r'tapa|kurodoko|tenner|triplets|hashi|minesweeper|logic|riddle'),
      GamePreviewKind.grid),

  // Families, in descending order of how much they say about the game.
  MapEntry(
      RegExp(
          r'memory|recall|paired|associate|face_|palace|grocery|shell_game|chimp'),
      GamePreviewKind.cards),
  MapEntry(
      RegExp(r'span|digit|letter_cancel|tracking|schulte|trail_making|search'),
      GamePreviewKind.dots),
  MapEntry(
      RegExp(
          r'word|letter|anagram|spell|vowel|consonant|syllable|rhyme|cryptogram|spooner|palindrome|pangram|oxymoron|portmanteau|homophone|etym|vocab|affix|cognate|grammar|typo|phrase|sentence|story|definit|semantic|analog|reading'),
      GamePreviewKind.letters),
  MapEntry(
      RegExp(
          r'math|arithmetic|sum|number|digit|fraction|prime|factor|modul|percent|algebra|calcul|collatz|exponent|radical|vector|angle|area|pythagor|statistic|estimat|countdown|target_number|bonds|multiplier|divisib'),
      GamePreviewKind.numbers),
  MapEntry(
      RegExp(
          r'reflex|reaction|tap|stroop|flanker|go_no_go|stop_signal|vigilance|blink|attention|focus|distract'),
      GamePreviewKind.target),
  MapEntry(
      RegExp(
          r'shape|shadow|perspective|cross_section|map|spatial|displace|orbit|pixel|pattern_sequence'),
      GamePreviewKind.arrows),
];

/// A stable number for one game. FNV-1a over the id: the same tile is drawn on
/// every launch, on every device, in every locale.
int previewSeedFor(String id) {
  int hash = 0x811c9dc5;
  for (final int unit in id.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

/// The preview itself: a square diagram drawn in ink, sized by [size].
class GamePreview extends StatelessWidget {
  const GamePreview({
    super.key,
    required this.id,
    required this.category,
    this.letter,
    this.size = 64,
    this.dimmed = false,
  });

  final String id;
  final String category;

  /// One character to put on a letter tile. Pass the game's initial so the
  /// word games do not all show the same glyph.
  final String? letter;

  final double size;

  /// Archived games are drawn at half weight, so an opt-in shelf reads as
  /// reference material rather than as more puzzles.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: GamePreviewPainter(
          kind: previewKindFor(id, category),
          seed: previewSeedFor(id),
          letter: letter,
          ink: dark ? DesignSystem.cardInkDark : DesignSystem.cardInk,
          hair: dark ? DesignSystem.hairDark : DesignSystem.hair,
          signal: DesignSystem.accent(context),
          dimmed: dimmed,
        ),
      ),
    );
  }
}

/// Paints one motif. Public so the contact sheet (`test/ui/preview_sheet_test.dart`)
/// can render every game onto one image for review.
class GamePreviewPainter extends CustomPainter {
  GamePreviewPainter({
    required this.kind,
    required this.seed,
    required this.ink,
    required this.hair,
    required this.signal,
    this.letter,
    this.dimmed = false,
  });

  final GamePreviewKind kind;
  final int seed;
  final String? letter;
  final Color ink;
  final Color hair;
  final Color signal;
  final bool dimmed;

  // A small deterministic generator: every motif asks it for the next number.
  int _state = 0;

  int _next() {
    // xorshift, so a seed change moves every decision, not just the first.
    _state ^= _state << 13;
    _state ^= _state >> 17;
    _state ^= _state << 5;
    return _state & 0x7fffffff;
  }

  int _range(int min, int max) => min + (_next() % (max - min + 1));

  @override
  void paint(Canvas canvas, Size size) {
    _state = seed == 0 ? 1 : seed;
    _state &= 0x7fffffff;
    if (_state == 0) _state = 1;

    final double side = math.min(size.width, size.height);
    final Rect box = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side,
      height: side,
    ).deflate(side * 0.06);

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, side / 56)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final _Ink pen = _Ink(
      canvas: canvas,
      box: box,
      ink: ink,
      hair: hair,
      signal: signal,
      stroke: stroke,
      dimmed: dimmed,
    );

    switch (kind) {
      case GamePreviewKind.grid:
        _grid(pen);
      case GamePreviewKind.maze:
        _maze(pen);
      case GamePreviewKind.ball:
        _ball(pen);
      case GamePreviewKind.path:
        _path(pen);
      case GamePreviewKind.letters:
        _letters(pen);
      case GamePreviewKind.word:
        _word(pen);
      case GamePreviewKind.numbers:
        _numbers(pen, side);
      case GamePreviewKind.cards:
        _cards(pen);
      case GamePreviewKind.dots:
        _dots(pen);
      case GamePreviewKind.target:
        _target(pen);
      case GamePreviewKind.arrows:
        _arrows(pen);
      case GamePreviewKind.bars:
        _bars(pen);
      case GamePreviewKind.clock:
        _clock(pen);
      case GamePreviewKind.stack:
        _stack(pen);
      case GamePreviewKind.shapes:
        _shapes(pen);
    }
  }

  // --- The motifs -----------------------------------------------------------

  void _grid(_Ink pen) {
    final int n = _range(4, 6);
    final double cell = pen.box.width / n;
    final int inked = _range(3, 3 + n);

    for (int i = 0; i <= n; i++) {
      pen.line(
        Offset(pen.box.left + i * cell, pen.box.top),
        Offset(pen.box.left + i * cell, pen.box.bottom),
        color: pen.hair,
      );
      pen.line(
        Offset(pen.box.left, pen.box.top + i * cell),
        Offset(pen.box.right, pen.box.top + i * cell),
        color: pen.hair,
      );
    }

    final Set<int> filled = <int>{};
    while (filled.length < inked) {
      filled.add(_next() % (n * n));
    }
    for (final int index in filled) {
      final int row = index ~/ n;
      final int col = index % n;
      pen.fill(
        Rect.fromLTWH(
          pen.box.left + col * cell,
          pen.box.top + row * cell,
          cell,
          cell,
        ).deflate(1.2),
        color: pen.ink.withValues(alpha: 0.82),
      );
    }

    // One cell in the live colour: the move a hint would show.
    final int hint = _next() % (n * n);
    pen.strokeRect(
      Rect.fromLTWH(
        pen.box.left + (hint % n) * cell,
        pen.box.top + (hint ~/ n) * cell,
        cell,
        cell,
      ).deflate(1.5),
      color: pen.signal,
      width: 2,
    );
  }

  void _maze(_Ink pen) {
    const int n = 5;
    final double cell = pen.box.width / n;

    for (int i = 1; i < n; i++) {
      pen.line(
        Offset(pen.box.left + i * cell, pen.box.top),
        Offset(pen.box.left + i * cell, pen.box.bottom),
        color: pen.hair.withValues(alpha: 0.7),
      );
      pen.line(
        Offset(pen.box.left, pen.box.top + i * cell),
        Offset(pen.box.right, pen.box.top + i * cell),
        color: pen.hair.withValues(alpha: 0.7),
      );
    }

    // A monotone staircase from the bottom-left corner to the top-right: every
    // maze reads the same at tile size, and the route is the whole idea.
    final List<Offset> route = [
      Offset(pen.box.left + cell / 2, pen.box.bottom - cell / 2),
    ];
    int row = n - 1;
    int col = 0;
    while (row > 0 || col < n - 1) {
      if (row > 0 && (col == n - 1 || _next().isEven)) {
        row--;
      } else if (col < n - 1) {
        col++;
      }
      route.add(Offset(
        pen.box.left + col * cell + cell / 2,
        pen.box.top + row * cell + cell / 2,
      ));
    }

    for (int i = 0; i < route.length - 1; i++) {
      pen.line(route[i], route[i + 1], color: pen.ink.withValues(alpha: 0.85));
    }
    pen.dot(route.first, pen.box.width * 0.075, color: pen.signal);
    pen.ring(route.last, pen.box.width * 0.075, color: pen.ink);
  }

  void _ball(_Ink pen) {
    const int n = 5;
    final double cell = pen.box.width / n;

    for (int i = 0; i <= n; i++) {
      pen.line(
        Offset(pen.box.left + i * cell, pen.box.top),
        Offset(pen.box.left + i * cell, pen.box.bottom),
        color: pen.hair.withValues(alpha: 0.6),
      );
      pen.line(
        Offset(pen.box.left, pen.box.top + i * cell),
        Offset(pen.box.right, pen.box.top + i * cell),
        color: pen.hair.withValues(alpha: 0.6),
      );
    }

    final int row = _range(1, n - 2);
    final int col = _range(1, n - 2);

    // The lane the ball can travel, and the square it would land on.
    pen.fill(
      Rect.fromLTWH(
        pen.box.left + 1.2,
        pen.box.top + row * cell + 1.2,
        pen.box.width - 2.4,
        cell - 2.4,
      ),
      color: pen.ink.withValues(alpha: 0.07),
    );

    final int landing = _next().isEven ? 0 : n - 1;
    pen.strokeRect(
      Rect.fromLTWH(
        pen.box.left + landing * cell,
        pen.box.top + row * cell,
        cell,
        cell,
      ).deflate(2),
      color: pen.signal.withValues(alpha: 0.55),
      width: 1.4,
    );

    pen.dot(
      Offset(
        pen.box.left + col * cell + cell / 2,
        pen.box.top + row * cell + cell / 2,
      ),
      cell * 0.34,
      color: pen.signal,
    );
  }

  void _path(_Ink pen) {
    final int nodes = _range(4, 5);
    final List<Offset> points = [];
    for (int i = 0; i < nodes; i++) {
      final double t = i / (nodes - 1);
      points.add(Offset(
        pen.box.left + pen.box.width * (0.08 + 0.84 * t),
        pen.box.top +
            pen.box.height *
                (0.2 +
                    0.6 * ((_next() % 100) / 100) * (i.isEven ? 1 : 0.4) +
                    0.1),
      ));
    }

    for (int i = 0; i < points.length - 1; i++) {
      pen.line(points[i], points[i + 1],
          color: pen.ink.withValues(alpha: 0.8), width: 1.4);
      for (final Offset p in [points[i], points[i + 1]]) {
        pen.ring(p, pen.box.width * 0.045, color: pen.hair);
      }
    }
    pen.dot(points.first, pen.box.width * 0.07, color: pen.signal);
    pen.dot(points.last, pen.box.width * 0.07, color: pen.ink);
  }

  void _letters(_Ink pen) {
    const int tiles = 3;
    final double gap = pen.box.width * 0.06;
    final double tile = (pen.box.width - gap * (tiles - 1)) / tiles;
    final String glyph = (letter ?? 'A').toUpperCase();
    final int filled = _next() % tiles;

    for (int i = 0; i < tiles; i++) {
      final Rect rect = Rect.fromLTWH(
        pen.box.left + i * (tile + gap),
        pen.box.top + pen.box.height * 0.16,
        tile,
        pen.box.height * 0.68,
      );
      final bool live = i == filled;
      pen.strokeRect(
        rect,
        color: live ? pen.signal : pen.hair,
        width: live ? 2 : 1.2,
        radius: tile * 0.16,
      );
      if (live) {
        pen.text(
          glyph,
          rect.center,
          size: tile * 0.62,
          color: pen.signal,
        );
      } else if (i > filled) {
        // A blank tile: the slot still to fill.
        pen.line(
          Offset(rect.left + tile * 0.34, rect.center.dy),
          Offset(rect.right - tile * 0.34, rect.center.dy),
          color: pen.hair,
        );
      } else {
        pen.text(
          String.fromCharCode(glyph.codeUnitAt(0) + i + 1),
          rect.center,
          size: tile * 0.5,
          color: pen.ink.withValues(alpha: 0.65),
        );
      }
    }
  }

  void _word(_Ink pen) {
    const int n = 5;
    final double cell = pen.box.width / n;

    // A crossword's shape: one across, one down, sharing a cell.
    final int row = _range(1, n - 2);
    final int col = _range(1, n - 2);

    for (int c = 0; c < n; c++) {
      final Rect rect = Rect.fromLTWH(
          pen.box.left + c * cell, pen.box.top + row * cell, cell, cell);
      pen.strokeRect(rect.deflate(0.8), color: pen.hair);
    }
    for (int r = 0; r < n; r++) {
      final Rect rect = Rect.fromLTWH(
          pen.box.left + col * cell, pen.box.top + r * cell, cell, cell);
      pen.strokeRect(rect.deflate(0.8), color: pen.hair);
    }

    // The shared cell is where the answer starts.
    pen.fill(
      Rect.fromLTWH(
              pen.box.left + col * cell, pen.box.top + row * cell, cell, cell)
          .deflate(3),
      color: pen.signal.withValues(alpha: 0.22),
    );
    pen.strokeRect(
      Rect.fromLTWH(
              pen.box.left + col * cell, pen.box.top + row * cell, cell, cell)
          .deflate(0.8),
      color: pen.signal,
      width: 1.6,
    );

    for (int i = 0; i < 3; i++) {
      final double x = pen.box.left + (col + 1 + (i % 2)) * cell;
      if (x + cell > pen.box.right) continue;
      pen.line(
        Offset(x + cell * 0.25, pen.box.top + row * cell + cell * 0.5),
        Offset(x + cell * 0.75, pen.box.top + row * cell + cell * 0.5),
        color: pen.ink.withValues(alpha: 0.5),
      );
    }
  }

  void _numbers(_Ink pen, double side) {
    final int a = _range(2, 9);
    final int b = _range(2, 9);
    const List<String> operators = ['+', '\u2212', '\u00d7'];
    final String op = operators[_next() % operators.length];

    pen.text(
        '$a $op $b', Offset(pen.box.center.dx, pen.box.center.dy - side * 0.1),
        size: side * 0.2, color: pen.ink, weight: FontWeight.w700);
    pen.line(
      Offset(
          pen.box.left + pen.box.width * 0.18, pen.box.center.dy + side * 0.03),
      Offset(pen.box.right - pen.box.width * 0.18,
          pen.box.center.dy + side * 0.03),
      color: pen.hair,
    );
    pen.strokeRect(
      Rect.fromCenter(
        center: Offset(pen.box.center.dx, pen.box.center.dy + side * 0.21),
        width: side * 0.2,
        height: side * 0.16,
      ),
      color: pen.signal,
      width: 1.8,
      radius: 3,
    );
  }

  void _cards(_Ink pen) {
    final double w = pen.box.width * 0.52;
    final double h = pen.box.height * 0.68;

    final Rect back = Rect.fromLTWH(
      pen.box.left + pen.box.width * 0.10,
      pen.box.top + pen.box.height * 0.10,
      w,
      h,
    );
    final Rect front =
        back.translate(pen.box.width * 0.20, pen.box.height * 0.12);

    pen.strokeRect(back, color: pen.hair, radius: w * 0.12);
    pen.strokeRect(front,
        color: pen.ink.withValues(alpha: 0.75), width: 1.4, radius: w * 0.12);

    // The face-up card carries three pips: something to remember.
    for (int i = 0; i < 3; i++) {
      pen.dot(
        Offset(
          front.left + w * (0.3 + 0.2 * i),
          front.top + h * (0.42 + (i.isEven ? 0.0 : 0.16)),
        ),
        w * 0.07,
        color: i == 1 ? pen.signal : pen.ink.withValues(alpha: 0.7),
      );
    }
  }

  void _dots(_Ink pen) {
    const int n = 3;
    final double step = pen.box.width / (n + 1);
    final List<Offset> grid = [
      for (int r = 0; r < n; r++)
        for (int c = 0; c < n; c++)
          Offset(
            pen.box.left + step * (c + 1),
            pen.box.top + step * (r + 1),
          ),
    ];

    for (final Offset p in grid) {
      pen.dot(p, pen.box.width * 0.028, color: pen.hair);
    }

    // A chain through four of them, the way a span task is played.
    final List<Offset> chain = [];
    int cursor = _next() % grid.length;
    while (chain.length < 4) {
      chain.add(grid[cursor]);
      final List<int> neighbours = [
        if (cursor % n > 0) cursor - 1,
        if (cursor % n < n - 1) cursor + 1,
        if (cursor >= n) cursor - n,
        if (cursor < n * n - n) cursor + n,
      ]..removeWhere((i) => chain.any((p) => p == grid[i]));
      if (neighbours.isEmpty) break;
      cursor = neighbours[_next() % neighbours.length];
    }

    for (int i = 0; i < chain.length - 1; i++) {
      pen.line(chain[i], chain[i + 1], color: pen.signal, width: 1.6);
    }
    for (final Offset p in chain) {
      pen.dot(p, pen.box.width * 0.055, color: pen.signal);
    }
  }

  void _target(_Ink pen) {
    final Offset centre = pen.box.center;
    for (int i = 4; i >= 1; i--) {
      pen.ring(centre, pen.box.width * 0.11 * i,
          color: i == 1 ? pen.ink : pen.hair, width: i == 1 ? 1.6 : 1.2);
    }
    pen.dot(
      Offset(
        centre.dx + pen.box.width * (_next().isEven ? 0.07 : -0.07),
        centre.dy - pen.box.height * (_next().isEven ? 0.05 : 0.09),
      ),
      pen.box.width * 0.055,
      color: pen.signal,
    );
  }

  void _arrows(_Ink pen) {
    // An L-tromino, then the same shape turned a quarter: the thing a spatial
    // game asks you to hold in your head.
    final double cell = pen.box.width * 0.19;
    final Offset origin = Offset(pen.box.left + pen.box.width * 0.14,
        pen.box.top + pen.box.height * 0.30);

    void tromino(Offset at, Color color, {bool fill = true, double turn = 0}) {
      final List<Offset> cells = [
        const Offset(0, 0),
        const Offset(1, 0),
        const Offset(0, 1),
      ];
      for (final Offset c in cells) {
        final Offset local = turn == 0 ? c : Offset(-c.dy, c.dx);
        final Rect rect = Rect.fromLTWH(
          at.dx + local.dx * cell,
          at.dy + local.dy * cell,
          cell,
          cell,
        ).deflate(1.6);
        if (fill) {
          pen.fill(rect, color: color, radius: 2);
        } else {
          pen.strokeRect(rect, color: color, width: 1.2, radius: 2);
        }
      }
    }

    tromino(origin, pen.ink.withValues(alpha: 0.8));
    tromino(
        Offset(pen.box.left + pen.box.width * 0.36,
            pen.box.top + pen.box.height * 0.34),
        pen.signal,
        fill: false,
        turn: 1);

    // The arc between them is the turn.
    pen.canvas.drawArc(
      Rect.fromCenter(
        center: Offset(pen.box.center.dx, pen.coordsY(0.72)),
        width: pen.box.width * 0.5,
        height: pen.box.height * 0.3,
      ),
      0.2,
      1.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = pen.hair,
    );
  }

  void _bars(_Ink pen) {
    final double beamY = pen.box.top + pen.box.height * 0.36;
    pen.line(
      Offset(pen.box.left + pen.box.width * 0.08, beamY),
      Offset(pen.box.right - pen.box.width * 0.08, beamY),
      color: pen.ink,
      width: 2,
    );

    // The fulcrum.
    final Offset apex = Offset(pen.box.center.dx, beamY);
    final Path foot = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(
          apex.dx - pen.box.width * 0.10, pen.box.bottom - pen.box.height * 0.1)
      ..lineTo(
          apex.dx + pen.box.width * 0.10, pen.box.bottom - pen.box.height * 0.1)
      ..close();
    pen.canvas.drawPath(foot, Paint()..color = pen.hair);

    // Two weights, one nearer the pivot: not yet balanced.
    final double w = pen.box.width * 0.14;
    final double h = pen.box.height * 0.14;
    pen.strokeRect(
      Rect.fromLTWH(pen.box.left + pen.box.width * 0.14, beamY - h - 2, w, h),
      color: pen.ink.withValues(alpha: 0.75),
      width: 1.3,
      radius: 2,
    );
    pen.strokeRect(
      Rect.fromLTWH(
          pen.box.right - pen.box.width * 0.14 - w, beamY - h - 2, w, h),
      color: pen.signal,
      width: 1.8,
      radius: 2,
    );
  }

  void _clock(_Ink pen) {
    final Offset centre = pen.box.center;
    final double radius = pen.box.width * 0.38;
    pen.ring(centre, radius, color: pen.ink, width: 1.6);
    for (int i = 0; i < 12; i++) {
      final double angle = math.pi * 2 * i / 12;
      final bool quarter = i % 3 == 0;
      pen.line(
        centre + Offset(math.sin(angle), -math.cos(angle)) * (radius * 0.84),
        centre + Offset(math.sin(angle), -math.cos(angle)) * (radius * 0.96),
        color: quarter ? pen.ink : pen.hair,
        width: quarter ? 1.4 : 1,
      );
    }
    final double hour = math.pi * 2 * (_range(1, 12) / 12);
    final double minute = math.pi * 2 * (_range(0, 11) / 12);
    pen.line(centre,
        centre + Offset(math.sin(hour), -math.cos(hour)) * (radius * 0.5),
        color: pen.ink, width: 2);
    pen.line(centre,
        centre + Offset(math.sin(minute), -math.cos(minute)) * (radius * 0.74),
        color: pen.signal, width: 1.6);
    pen.dot(centre, pen.box.width * 0.035, color: pen.ink);
  }

  void _stack(_Ink pen) {
    // Tubes of poured liquid, side by side: water sort and its relatives.
    const int tubes = 3;
    final double gap = pen.box.width * 0.08;
    final double w = (pen.box.width - gap * (tubes - 1)) / tubes;
    final double h = pen.box.height * 0.74;

    for (int i = 0; i < tubes; i++) {
      final Rect tube = Rect.fromLTWH(
        pen.box.left + i * (w + gap),
        pen.box.top + (pen.box.height - h) / 2,
        w,
        h,
      );
      pen.strokeRect(tube, color: pen.hair, radius: w * 0.28);

      final int bands = _range(1, 3);
      for (int b = 0; b < bands; b++) {
        final double bandH = h / 3;
        pen.fill(
          Rect.fromLTWH(
            tube.left + 1.4,
            tube.bottom - 1.4 - (b + 1) * bandH,
            w - 2.8,
            bandH - 1,
          ),
          color: b == 0 && i == tubes - 1
              ? pen.signal.withValues(alpha: 0.75)
              : pen.ink.withValues(alpha: 0.18 + 0.16 * b),
          radius: w * 0.1,
        );
      }
    }
  }

  void _shapes(_Ink pen) {
    // Two overlapping outlines and the piece that belongs in both.
    final Offset left =
        Offset(pen.box.center.dx - pen.box.width * 0.14, pen.box.center.dy);
    final Offset right =
        Offset(pen.box.center.dx + pen.box.width * 0.14, pen.box.center.dy);
    final double radius = pen.box.width * 0.3;

    pen.ring(left, radius, color: pen.ink.withValues(alpha: 0.75), width: 1.4);
    pen.ring(right, radius, color: pen.signal, width: 1.4);

    final double size = pen.box.width * 0.16;
    pen.fill(
      Rect.fromCenter(
        center: Offset(pen.box.center.dx, pen.box.center.dy),
        width: size,
        height: size,
      ),
      color: pen.hair,
      radius: 2,
    );
  }

  @override
  bool shouldRepaint(GamePreviewPainter old) =>
      old.kind != kind ||
      old.seed != seed ||
      old.ink != ink ||
      old.hair != hair ||
      old.signal != signal ||
      old.letter != letter ||
      old.dimmed != dimmed;
}

/// Drawing helpers in normalised box coordinates, so a motif is written once.
class _Ink {
  _Ink({
    required this.canvas,
    required this.box,
    required this.ink,
    required this.hair,
    required this.signal,
    required this.stroke,
    required this.dimmed,
  }) {
    if (dimmed) {
      // Archived: the same drawing at half weight.
      final double opacity = 0.45;
      ink = ink.withValues(alpha: ink.a * opacity);
      hair = hair.withValues(alpha: hair.a * opacity);
      signal = signal.withValues(alpha: signal.a * 0.7);
    }
  }

  final Canvas canvas;
  final Rect box;
  Color ink;
  Color hair;
  Color signal;
  final Paint stroke;
  final bool dimmed;

  /// A point in the box, where (0,0) is its top-left and (1,1) its bottom-right.
  Offset at(double x, double y) =>
      Offset(box.left + box.width * x, box.top + box.height * y);

  double coordsY(double fraction) => box.top + box.height * fraction;

  void line(Offset a, Offset b, {Color? color, double width = 1}) {
    stroke
      ..color = color ?? hair
      ..strokeWidth = width;
    canvas.drawLine(a, b, stroke);
  }

  void dot(Offset centre, double radius, {Color? color}) {
    canvas.drawCircle(centre, radius, Paint()..color = color ?? ink);
  }

  void ring(Offset centre, double radius, {Color? color, double width = 1.2}) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color ?? hair,
    );
  }

  void fill(Rect rect, {Color? color, double radius = 1.5}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color ?? ink,
    );
  }

  void strokeRect(Rect rect,
      {Color? color, double width = 1.2, double radius = 1.5}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color ?? hair,
    );
  }

  void text(
    String value,
    Offset centre, {
    required double size,
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: size,
          height: 1,
          fontWeight: weight,
          color: color ?? ink,
          fontFamily: 'Geist',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
  }
}

/// The preview for one registry game, with the game's initial as the glyph on
/// the letter tile.
class GameCardPreview extends StatelessWidget {
  const GameCardPreview({
    super.key,
    required this.game,
    required this.title,
    this.size = 64,
    this.dimmed = false,
  });

  final GameMetadata game;
  final String title;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) => GamePreview(
        id: game.id,
        category: game.category,
        letter: title.trim().isEmpty ? null : title.trim().characters.first,
        size: size,
        dimmed: dimmed,
      );
}
