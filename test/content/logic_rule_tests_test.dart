import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_profiles.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/games/gokigen_naname/gokigen_naname_screen.dart';
import 'package:puzzle/ui/features/games/masyu/masyu_screen.dart';
import 'package:puzzle/ui/features/games/kakurasu_sums/kakurasu_sums_screen.dart';
import 'package:puzzle/ui/features/games/shikaku/shikaku_screen.dart';
import 'package:puzzle/ui/features/games/tenner_grid/tenner_grid_screen.dart';
import 'package:puzzle/ui/features/games/triplets_logic/triplets_logic_screen.dart';
import 'package:puzzle/ui/features/games/tapa/tapa_engine.dart';
import 'package:puzzle/ui/features/games/yajilin/yajilin_engine.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';

/// The Logic room's missing rule tests (release gate G3).
///
/// The ids are the `rule-tests` list in docs/TRIAGE-LOGIC.md, not a list made
/// up here. Each test builds one instance that satisfies the game's own rules,
/// shows that its win test accepts it, then mutates it until exactly one rule
/// breaks and shows the win test rejects it.
void main() {
  group('tapa', () {
    test('a wall that matches every clue wins; one wrong clue digit loses', () {
      final puzzle = TapaEngine.generatePuzzle(random: Random(3));
      final cells = _tapaCells(puzzle);
      expect(TapaEngine.isSolved(cells, puzzle.size), isTrue,
          reason: 'the generator solution must satisfy the rule');

      final clue = _firstTapaClue(cells);
      expect(clue, isNotNull);
      final broken = _tapaCells(puzzle);
      final wrong = (clue!.clues!.first + 1) % 5;
      broken[clue.row][clue.col] = TapaCell(
        row: clue.row,
        col: clue.col,
        clues: [wrong],
        state: TapaCellState.white,
      );
      expect(TapaEngine.isSolved(broken, puzzle.size), isFalse,
          reason: 'a clue that no longer matches the wall must lose');
    });
  });

  group('yajilin', () {
    test('a loop that satisfies every clue wins; one wrong clue count loses',
        () {
      final puzzle = _yajilinLoopPuzzle();
      expect(YajilinEngine.isSolved(puzzle.grid, puzzle.edges, puzzle.size),
          isTrue);

      final broken = _yajilinLoopPuzzle();
      broken.grid[0][1] = YajilinCell(
        r: 0,
        c: 1,
        clue: YajilinClue(ArrowDirection.down, 2),
      );
      expect(
        YajilinEngine.isSolved(broken.grid, broken.edges, broken.size),
        isFalse,
        reason: 'the ray holds one black cell, not two',
      );
    });
  });

  group('kakurasu_sums', () {
    testWidgets('a grid that meets every target wins; one cell short loses',
        (tester) async {
      await _pump(tester, const KakurasuSumsScreen());
      final table = find.byType(Table);
      final targets = _kakurasuTargets(tester, table);
      final solution = _kakurasuSolution(targets);
      expect(solution, isNotNull);

      final cells = find.descendant(
        of: table,
        matching: find.byType(GestureDetector),
      );
      expect(cells, findsNWidgets(16));

      final omitted = _firstSetBit(solution!);
      for (var i = 0; i < 16; i++) {
        if (i != omitted && solution & (1 << i) != 0) {
          _tapGesture(tester, cells.at(i));
          await tester.pump();
        }
      }
      expect(_kakurasuScore(tester), 0,
          reason: 'one shaded cell short must not win');

      _tapGesture(tester, cells.at(omitted));
      await tester.pumpAndSettle();
      expect(_kakurasuScore(tester), 1, reason: 'the completed grid must win');
    });
  });

  group('triplets_logic', () {
    testWidgets('two of each shape in every line wins; two cells swapped lose',
        (tester) async {
      await _pump(tester, const TripletsLogicScreen());
      final grid = find.byType(GridView);
      final cells = find.descendant(
        of: grid,
        matching: find.byType(GestureDetector),
      );
      expect(cells, findsNWidgets(36));

      final fixed = List.generate(6, (_) => List<int>.filled(6, 0));
      for (var i = 0; i < 36; i++) {
        final icon = find.descendant(
          of: cells.at(i),
          matching: find.byType(Icon),
        );
        if (icon.evaluate().isNotEmpty) {
          fixed[i ~/ 6][i % 6] = _tripletShape(tester.widget<Icon>(icon));
        }
      }

      final solution = _solveTriplets(fixed);
      expect(solution, isNotNull, reason: 'the fixed cells must have a finish');
      final broken = _swapTwoInARow(solution!, fixed);
      expect(broken, isNotNull, reason: 'need a two-cell mutation');

      await _fillTriplets(tester, grid, cells, broken!, fixed);
      expect(_tripletsScore(tester), 0,
          reason: 'two swapped cells break the column counts');

      for (var r = 0; r < 6; r++) {
        for (var c = 0; c < 6; c++) {
          if (fixed[r][c] != 0 || broken[r][c] == solution[r][c]) continue;
          await tester.tap(_tripletTool(tester, grid, solution[r][c]));
          await tester.pump();
          _tapGesture(tester, cells.at(r * 6 + c));
          await tester.pump();
        }
      }
      await tester.pumpAndSettle();
      expect(_tripletsScore(tester), 1, reason: 'the corrected grid must win');
    });
  });

  group('tenner_grid', () {
    testWidgets('rows, column sums and diagonals win; two cells swapped lose',
        (tester) async {
      await _pump(tester, const TennerGridScreen());
      final gestures = find.byType(GestureDetector);
      final indices = <int>[];
      for (var i = 0; i < gestures.evaluate().length; i++) {
        final size = tester.getSize(gestures.at(i));
        if (size.height >= 44 && size.height <= 52 && size.width < 45) {
          indices.add(i);
        }
      }
      expect(indices, hasLength(30));

      final level = _tennerLevel(tester, gestures, indices);
      expect(level, isNotNull,
          reason: 'the fixed cells name one of the levels');
      final solution = level!.solution;
      final broken = _tennerSwap(solution, level.fixed);
      expect(broken, isNotNull, reason: 'need a two-cell mutation');

      await _fillTenner(tester, gestures, indices, broken!, level.fixed);
      expect(_tennerScore(tester), 0,
          reason: 'two swapped cells break a column sum');

      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 10; c++) {
          if (level.fixed[r][c] || broken[r][c] == solution[r][c]) continue;
          _tapGesture(tester, gestures.at(indices[r * 10 + c]));
          await tester.pump();
          await tester.tap(
            find.widgetWithText(ElevatedButton, '${solution[r][c]}'),
          );
          await tester.pump();
        }
      }
      await tester.pumpAndSettle();
      expect(_tennerScore(tester), 1, reason: 'the corrected grid must win');
    });
  });

  group('shikaku', () {
    testWidgets('one number per rectangle and its area wins; many numbers lose',
        (tester) async {
      await _pump(tester, const ShikakuScreen());
      final grid = find.byType(GridView);
      final cells = find.descendant(
        of: grid,
        matching: find.byType(GestureDetector),
      );
      expect(cells, findsNWidgets(36));

      var board = _shikakuBoard(tester, cells);
      for (var attempt = 0;
          attempt < 10 && _shikakuClues(board).length < 2;
          attempt++) {
        await tester.tap(find.byIcon(Icons.refresh_rounded));
        await tester.pumpAndSettle();
        board = _shikakuBoard(tester, cells);
      }
      expect(_shikakuClues(board).length, greaterThan(1),
          reason: 'a one-number board would make the broken instance valid');

      _tapGesture(tester, cells.at(0));
      await tester.pump();
      _tapGesture(tester, cells.at(35));
      await tester.pumpAndSettle();
      expect(find.byType(GameCompletionDialog), findsNothing,
          reason: 'one box holding every number breaks the rule');

      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pumpAndSettle();

      final rectangles = _solveShikaku(board);
      expect(rectangles, isNotNull, reason: 'the dealt board has a finish');
      for (final rect in rectangles!) {
        _tapGesture(tester, cells.at(rect[0] * 6 + rect[1]));
        await tester.pump();
        _tapGesture(tester, cells.at(rect[2] * 6 + rect[3]));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byType(GameCompletionDialog), findsOneWidget);
    });
  });

  group('gokigen_naname', () {
    testWidgets('counts at every vertex and no loop wins; one diagonal loses',
        (tester) async {
      await _pump(tester, const GokigenNanameScreen());
      final gestures = find.byType(GestureDetector);
      final indices = <int>[];
      for (var i = 0; i < gestures.evaluate().length; i++) {
        final size = tester.getSize(gestures.at(i));
        if (size.width >= 70 &&
            size.width <= 90 &&
            size.height >= 70 &&
            size.height <= 90) {
          indices.add(i);
        }
      }
      expect(indices, hasLength(16));

      final firstRect = tester.getRect(gestures.at(indices.first));
      final board = firstRect.topLeft;
      final cellWidth = firstRect.width;
      final cellHeight = firstRect.height;
      final clues = List.generate(5, (_) => List<int?>.filled(5, null));
      for (final element in find.byType(Text).evaluate()) {
        final text = element.widget as Text;
        final data = text.data;
        final style = text.style;
        if (data == null ||
            data.length != 1 ||
            int.tryParse(data) == null ||
            style?.fontSize != 13 ||
            style?.fontWeight != FontWeight.bold) {
          continue;
        }
        final point = tester.getRect(find.byWidget(text)).center - board;
        final c = (point.dx / cellWidth).round();
        final r = (point.dy / cellHeight).round();
        if (r >= 0 && r <= 4 && c >= 0 && c <= 4) {
          clues[r][c] = int.parse(data);
        }
      }
      expect(clues.expand((row) => row).where((c) => c != null), isNotEmpty);
      final solution = _solveGokigen(clues);
      expect(solution, isNotNull, reason: 'the clues must have a finish');
      final broken = _brokenGokigen(clues, solution!);
      expect(broken, isNotNull, reason: 'need a one-diagonal mutation');

      await _fillGokigen(tester, gestures, indices, broken!);
      expect(find.byType(GameCompletionDialog), findsNothing,
          reason: 'one wrong diagonal breaks the vertex counts');

      for (var i = 0; i < 16; i++) {
        var state = broken[i ~/ 4][i % 4];
        while (state != 0) {
          _tapGesture(tester, gestures.at(indices[i]));
          await tester.pump();
          state = (state + 1) % 3;
        }
      }
      await _fillGokigen(tester, gestures, indices, solution);
      expect(find.byType(GameCompletionDialog), findsOneWidget);
    });
  });

  group('masyu', () {
    testWidgets('a loop that meets every clue wins; a clue-breaking loop loses',
        (tester) async {
      await _pump(tester, const MasyuScreen());
      final gestures = find.byType(GestureDetector);
      final indices = <int>[];
      for (var i = 0; i < gestures.evaluate().length; i++) {
        final size = tester.getSize(gestures.at(i));
        if (size.width >= 70 &&
            size.width <= 80 &&
            size.height >= 70 &&
            size.height <= 80) {
          indices.add(i);
        }
      }
      expect(indices, hasLength(16));

      final firstRect = tester.getRect(gestures.at(indices.first));
      final board = firstRect.topLeft;
      final clues = List.generate(4, (_) => List<String?>.filled(4, null));
      for (final element in find.byType(Container).evaluate()) {
        final container = element.widget as Container;
        final decoration = container.decoration;
        final size = tester.getSize(find.byWidget(container));
        if (size.width != 18 ||
            size.height != 18 ||
            decoration is! BoxDecoration ||
            decoration.shape != BoxShape.circle) {
          continue;
        }
        final point = tester.getRect(find.byWidget(container)).center - board;
        final c = (point.dx / firstRect.width).floor();
        final r = (point.dy / firstRect.height).floor();
        if (r < 0 || r > 3 || c < 0 || c > 3) continue;
        clues[r][c] = decoration.color == Colors.white ? 'white' : 'black';
      }
      expect(clues.expand((row) => row).where((c) => c != null), isNotEmpty);

      final cycles = _masyuCycles();
      List<List<int>>? valid;
      List<List<int>>? broken;
      for (final cycle in cycles) {
        final tracks = _masyuTracks(cycle);
        if (_masyuCluesOk(tracks, clues)) {
          valid ??= tracks;
        } else {
          broken ??= tracks;
        }
      }
      expect(valid, isNotNull, reason: 'the clues must have a finish');
      expect(broken, isNotNull, reason: 'need a loop that breaks the clues');

      await _fillMasyu(tester, gestures, indices, broken!);
      expect(find.byType(GameCompletionDialog), findsNothing,
          reason: 'a loop that ignores a circle must not win');

      for (var i = 0; i < 16; i++) {
        var track = broken[i ~/ 4][i % 4];
        while (track != 0) {
          _tapGesture(tester, gestures.at(indices[i]));
          await tester.pump();
          track = (track + 1) % 7;
        }
      }
      await _fillMasyu(tester, gestures, indices, valid!);
      expect(find.byType(GameCompletionDialog), findsOneWidget);
    });
  });

  group('the registry', () {
    test('every kept Logic rule-tests id is covered or listed as blocked', () {
      for (final id in _logicRuleIds) {
        final profile = gameProfiles[id];
        expect(profile, isNotNull, reason: '$id is not in the registry');
        expect(profile!.tier, isNot(GameTier.archive), reason: '$id is kept');
      }

      final missing = _logicRuleIds
          .where((id) => !_coveredRuleIds.contains(id))
          .where((id) => !_blockedRuleIds.contains(id))
          .toList()
        ..sort();
      expect(missing, isEmpty,
          reason: 'kept Logic games with no rule test: ${missing.join(', ')}');

      expect(
        _coveredRuleIds.intersection(_blockedRuleIds),
        isEmpty,
        reason: 'an id cannot be both covered and blocked',
      );
      expect(_coveredRuleIds.difference(_logicRuleIds), isEmpty,
          reason: 'a test claims an id outside this room list');
      expect(_blockedRuleIds.difference(_logicRuleIds), isEmpty,
          reason: 'a blocked id is not in this room list');
    });
  });
}

const _logicRuleIds = <String>{
  'gokigen_naname',
  'kakurasu_sums',
  'masyu',
  'shikaku',
  'tapa',
  'tenner_grid',
  'triplets_logic',
  'yajilin',
};

const _coveredRuleIds = <String>{
  'gokigen_naname',
  'kakurasu_sums',
  'masyu',
  'shikaku',
  'tapa',
  'tenner_grid',
  'triplets_logic',
  'yajilin',
};

const _blockedRuleIds = <String>{};

int _tripletsScore(WidgetTester tester) {
  final text = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? '')
      .firstWhere((data) => data.contains('/ 3'));
  return int.parse(RegExp(r'(\d+) / 3').firstMatch(text)!.group(1)!);
}

int _tripletShape(Icon icon) {
  if (icon.icon == Icons.circle) return 1;
  if (icon.icon == Icons.crop_square) return 2;
  return 3;
}

List<List<int>>? _solveTriplets(List<List<int>> fixed) {
  final grid = List.generate(6, (_) => List<int>.filled(6, 0));
  final rowCounts = List.generate(6, (_) => List<int>.filled(4, 0));
  final colCounts = List.generate(6, (_) => List<int>.filled(4, 0));

  bool place(int index) {
    if (index == 36) return true;
    final r = index ~/ 6;
    final c = index % 6;
    final choices = fixed[r][c] != 0 ? [fixed[r][c]] : [1, 2, 3];
    for (final value in choices) {
      if (rowCounts[r][value] == 2 || colCounts[c][value] == 2) continue;
      if (c >= 2 && grid[r][c - 1] == value && grid[r][c - 2] == value) {
        continue;
      }
      if (r >= 2 && grid[r - 1][c] == value && grid[r - 2][c] == value) {
        continue;
      }
      grid[r][c] = value;
      rowCounts[r][value]++;
      colCounts[c][value]++;
      if (place(index + 1)) return true;
      rowCounts[r][value]--;
      colCounts[c][value]--;
      grid[r][c] = 0;
    }
    return false;
  }

  return place(0) ? grid : null;
}

List<List<int>>? _swapTwoInARow(
  List<List<int>> solution,
  List<List<int>> fixed,
) {
  for (var r = 0; r < 6; r++) {
    for (var a = 0; a < 6; a++) {
      for (var b = a + 1; b < 6; b++) {
        if (fixed[r][a] != 0 || fixed[r][b] != 0) continue;
        if (solution[r][a] == solution[r][b]) continue;
        final candidate = [
          for (final row in solution) List<int>.from(row),
        ];
        final value = candidate[r][a];
        candidate[r][a] = candidate[r][b];
        candidate[r][b] = value;
        if (_tripletsNoThree(candidate) && _tripletsRowsValid(candidate)) {
          return candidate;
        }
      }
    }
  }
  return null;
}

bool _tripletsRowsValid(List<List<int>> grid) {
  for (final row in grid) {
    final counts = List<int>.filled(4, 0);
    for (final value in row) {
      counts[value]++;
    }
    if (counts[1] != 2 || counts[2] != 2 || counts[3] != 2) return false;
  }
  return true;
}

bool _tripletsNoThree(List<List<int>> grid) {
  for (var r = 0; r < 6; r++) {
    for (var c = 0; c < 4; c++) {
      if (grid[r][c] == grid[r][c + 1] && grid[r][c] == grid[r][c + 2]) {
        return false;
      }
    }
  }
  for (var c = 0; c < 6; c++) {
    for (var r = 0; r < 4; r++) {
      if (grid[r][c] == grid[r + 1][c] && grid[r][c] == grid[r + 2][c]) {
        return false;
      }
    }
  }
  return true;
}

Future<void> _fillTriplets(
  WidgetTester tester,
  Finder grid,
  Finder cells,
  List<List<int>> values,
  List<List<int>> fixed,
) async {
  for (var shape = 1; shape <= 3; shape++) {
    final icon = _tripletTool(tester, grid, shape);
    await tester.tap(icon);
    await tester.pump();
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < 6; c++) {
        if (fixed[r][c] != 0 || values[r][c] != shape) continue;
        _tapGesture(tester, cells.at(r * 6 + c));
        await tester.pump();
      }
    }
  }
  await tester.pumpAndSettle();
}

Finder _tripletTool(WidgetTester tester, Finder grid, int shape) {
  final icon = switch (shape) {
    1 => Icons.circle,
    2 => Icons.crop_square,
    _ => Icons.change_history,
  };
  final top = tester.getRect(grid).top;
  final matches = find.byIcon(icon).evaluate();
  for (final element in matches) {
    final rect = tester.getRect(find.byWidget(element.widget));
    if (rect.center.dy < top) return find.byWidget(element.widget);
  }
  throw StateError('shape tool $shape not found above the grid');
}

class _TennerLevel {
  const _TennerLevel(this.fixed, this.solution);

  final List<List<bool>> fixed;
  final List<List<int>> solution;
}

const _tennerLevels = [
  _TennerLevel(
    [
      [false, true, false, false, false, true, false, true, false, true],
      [true, false, true, false, false, true, false, true, false, false],
      [false, true, false, true, true, true, false, false, false, false],
    ],
    [
      [3, 2, 7, 0, 1, 5, 8, 9, 4, 6],
      [9, 6, 1, 5, 2, 0, 4, 7, 8, 3],
      [0, 5, 7, 9, 8, 6, 1, 3, 2, 4],
    ],
  ),
  _TennerLevel(
    [
      [true, true, false, false, false, true, false, false, true, false],
      [true, true, false, false, false, false, true, false, false, true],
      [false, false, true, true, false, false, true, true, false, false],
    ],
    [
      [8, 7, 3, 9, 4, 1, 0, 6, 5, 2],
      [5, 6, 0, 7, 2, 8, 3, 9, 4, 1],
      [1, 3, 9, 6, 4, 7, 5, 2, 0, 8],
    ],
  ),
];

_TennerLevel? _tennerLevel(
  WidgetTester tester,
  Finder gestures,
  List<int> indices,
) {
  final values = List.generate(3, (_) => List<int>.filled(10, -1));
  for (var i = 0; i < 30; i++) {
    final text = find.descendant(
      of: gestures.at(indices[i]),
      matching: find.byType(Text),
    );
    final data = tester.widget<Text>(text).data;
    if (data != null && data.isNotEmpty)
      values[i ~/ 10][i % 10] = int.parse(data);
  }
  for (final level in _tennerLevels) {
    var matches = true;
    for (var r = 0; r < 3 && matches; r++) {
      for (var c = 0; c < 10; c++) {
        if (level.fixed[r][c] && values[r][c] != level.solution[r][c]) {
          matches = false;
          break;
        }
        if (!level.fixed[r][c] && values[r][c] != -1) {
          matches = false;
          break;
        }
      }
    }
    if (matches) return level;
  }
  return null;
}

List<List<int>>? _tennerSwap(
  List<List<int>> solution,
  List<List<bool>> fixed,
) {
  for (var r = 0; r < 3; r++) {
    for (var a = 0; a < 10; a++) {
      for (var b = a + 1; b < 10; b++) {
        if (fixed[r][a] || fixed[r][b]) continue;
        final candidate = [
          for (final row in solution) List<int>.from(row),
        ];
        final value = candidate[r][a];
        candidate[r][a] = candidate[r][b];
        candidate[r][b] = value;
        if (_tennerRowsAndDiagonals(candidate)) return candidate;
      }
    }
  }
  return null;
}

bool _tennerRowsAndDiagonals(List<List<int>> grid) {
  for (final row in grid) {
    if (row.toSet().length != 10) return false;
  }
  for (var r = 0; r < 2; r++) {
    for (var c = 0; c < 10; c++) {
      for (var dc = -1; dc <= 1; dc++) {
        final nc = c + dc;
        if (nc >= 0 && nc < 10 && grid[r][c] == grid[r + 1][nc]) {
          return false;
        }
      }
    }
  }
  return true;
}

Future<void> _fillTenner(
  WidgetTester tester,
  Finder gestures,
  List<int> indices,
  List<List<int>> values,
  List<List<bool>> fixed,
) async {
  for (var r = 0; r < 3; r++) {
    for (var c = 0; c < 10; c++) {
      if (fixed[r][c]) continue;
      _tapGesture(tester, gestures.at(indices[r * 10 + c]));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '${values[r][c]}'));
      await tester.pump();
    }
  }
  await tester.pumpAndSettle();
}

int _tennerScore(WidgetTester tester) {
  final text = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? '')
      .firstWhere((data) => data.contains('/ 3'));
  return int.parse(RegExp(r'(\d+) / 3').firstMatch(text)!.group(1)!);
}

List<List<int>> _shikakuBoard(WidgetTester tester, Finder cells) {
  final board = List.generate(6, (_) => List<int>.filled(6, 0));
  for (var i = 0; i < 36; i++) {
    final text = find.descendant(
      of: cells.at(i),
      matching: find.byType(Text),
    );
    if (text.evaluate().isNotEmpty) {
      board[i ~/ 6][i % 6] = int.parse(tester.widget<Text>(text).data!);
    }
  }
  return board;
}

List<List<int>> _shikakuClues(List<List<int>> board) {
  final clues = <List<int>>[];
  for (var r = 0; r < 6; r++) {
    for (var c = 0; c < 6; c++) {
      if (board[r][c] > 0) clues.add([r, c, board[r][c]]);
    }
  }
  return clues;
}

List<List<int>>? _solveShikaku(List<List<int>> board) {
  final assigned = List.generate(6, (_) => List.filled(6, false));
  final answer = <List<int>>[];

  bool place() {
    var r0 = -1;
    var c0 = -1;
    for (var r = 0; r < 6 && r0 == -1; r++) {
      for (var c = 0; c < 6; c++) {
        if (!assigned[r][c]) {
          r0 = r;
          c0 = c;
          break;
        }
      }
    }
    if (r0 == -1) return true;

    for (var height = 1; r0 + height <= 6; height++) {
      for (var width = 1; c0 + width <= 6; width++) {
        final r1 = r0 + height - 1;
        final c1 = c0 + width - 1;
        var free = true;
        for (var r = r0; r <= r1 && free; r++) {
          for (var c = c0; c <= c1; c++) {
            if (assigned[r][c]) {
              free = false;
              break;
            }
          }
        }
        if (!free) break;
        final clues = <int>[];
        for (var r = r0; r <= r1; r++) {
          for (var c = c0; c <= c1; c++) {
            if (board[r][c] > 0) clues.add(board[r][c]);
          }
        }
        if (clues.length != 1 || clues.single != height * width) continue;

        for (var r = r0; r <= r1; r++) {
          for (var c = c0; c <= c1; c++) {
            assigned[r][c] = true;
          }
        }
        answer.add([r0, c0, r1, c1]);
        if (place()) return true;
        answer.removeLast();
        for (var r = r0; r <= r1; r++) {
          for (var c = c0; c <= c1; c++) {
            assigned[r][c] = false;
          }
        }
      }
    }
    return false;
  }

  return place() ? answer : null;
}

List<List<int>>? _solveGokigen(List<List<int?>> clues) {
  for (var mask = 0; mask < 1 << 16; mask++) {
    final states = List.generate(
      4,
      (r) => List.generate(4, (c) => (mask >> (r * 4 + c)) & 1 == 1 ? 1 : 2),
    );
    if (_gokigenCluesMatch(clues, states) && !_gokigenHasCycle(states)) {
      return states;
    }
  }
  return null;
}

List<List<int>>? _brokenGokigen(
  List<List<int?>> clues,
  List<List<int>> solution,
) {
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      final broken = [
        for (final row in solution) List<int>.from(row),
      ];
      broken[r][c] = broken[r][c] == 1 ? 2 : 1;
      if (!_gokigenCluesMatch(clues, broken) && !_gokigenHasCycle(broken)) {
        return broken;
      }
    }
  }
  return null;
}

bool _gokigenCluesMatch(List<List<int?>> clues, List<List<int?>> states) {
  final counts = List.generate(5, (_) => List<int>.filled(5, 0));
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      final diag = states[r][c];
      if (diag == 1) {
        counts[r + 1][c]++;
        counts[r][c + 1]++;
      } else if (diag == 2) {
        counts[r][c]++;
        counts[r + 1][c + 1]++;
      }
    }
  }
  for (var r = 0; r <= 4; r++) {
    for (var c = 0; c <= 4; c++) {
      if (clues[r][c] != null && counts[r][c] != clues[r][c]) return false;
    }
  }
  return true;
}

bool _gokigenHasCycle(List<List<int>> states) {
  final parent = List.generate(25, (i) => i);
  int find(int i) => parent[i] == i ? i : parent[i] = find(parent[i]);
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      final diag = states[r][c];
      final v1 = diag == 1 ? (r + 1) * 5 + c : r * 5 + c;
      final v2 = diag == 1 ? r * 5 + (c + 1) : (r + 1) * 5 + (c + 1);
      final a = find(v1);
      final b = find(v2);
      if (a == b) return true;
      parent[a] = b;
    }
  }
  return false;
}

Future<void> _fillGokigen(
  WidgetTester tester,
  Finder gestures,
  List<int> indices,
  List<List<int>> states,
) async {
  for (var i = 0; i < 16; i++) {
    for (var tap = 0; tap < states[i ~/ 4][i % 4]; tap++) {
      _tapGesture(tester, gestures.at(indices[i]));
      await tester.pump();
    }
  }
  await tester.pumpAndSettle();
}

List<List<List<int>>> _masyuCycles() {
  final cycles = <String, List<List<int>>>{};
  final path = <List<int>>[];
  final visited = List.generate(4, (_) => List.filled(4, false));

  void walk(int r, int c) {
    path.add([r, c]);
    visited[r][c] = true;
    for (final step in const [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0],
    ]) {
      final nr = r + step[0];
      final nc = c + step[1];
      if (nr < 0 || nr > 3 || nc < 0 || nc > 3) continue;
      if (nr == path.first[0] && nc == path.first[1]) {
        if (path.length >= 4) {
          final key =
              (path.map((p) => p[0] * 4 + p[1]).toList()..sort()).join(',');
          cycles[key] = [
            for (final p in path) [p[0], p[1]]
          ];
        }
        continue;
      }
      if (!visited[nr][nc]) walk(nr, nc);
    }
    path.removeLast();
    visited[r][c] = false;
  }

  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      walk(r, c);
    }
  }
  return cycles.values.toList();
}

List<List<int>> _masyuTracks(List<List<int>> cycle) {
  final tracks = List.generate(4, (_) => List<int>.filled(4, 0));
  for (var i = 0; i < cycle.length; i++) {
    final curr = cycle[i];
    final prev = cycle[(i - 1 + cycle.length) % cycle.length];
    final next = cycle[(i + 1) % cycle.length];
    final dirs = {_masyuDir(curr, prev), _masyuDir(curr, next)};
    final type = dirs.contains('left') && dirs.contains('right')
        ? 1
        : dirs.contains('top') && dirs.contains('bottom')
            ? 2
            : dirs.contains('bottom') && dirs.contains('right')
                ? 3
                : dirs.contains('left') && dirs.contains('bottom')
                    ? 4
                    : dirs.contains('top') && dirs.contains('right')
                        ? 5
                        : 6;
    tracks[curr[0]][curr[1]] = type;
  }
  return tracks;
}

String _masyuDir(List<int> from, List<int> to) {
  if (to[1] == from[1] + 1) return 'right';
  if (to[1] == from[1] - 1) return 'left';
  if (to[0] == from[0] + 1) return 'bottom';
  return 'top';
}

Set<String> _masyuConnections(int type) {
  return switch (type) {
    1 => {'left', 'right'},
    2 => {'top', 'bottom'},
    3 => {'bottom', 'right'},
    4 => {'left', 'bottom'},
    5 => {'top', 'right'},
    6 => {'left', 'top'},
    _ => <String>{},
  };
}

bool _masyuCluesOk(List<List<int>> tracks, List<List<String?>> clues) {
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      final clue = clues[r][c];
      final type = tracks[r][c];
      if (clue == 'white') {
        if (type != 1 && type != 2) return false;
        var turn = false;
        if (type == 1) {
          if (c > 0 && tracks[r][c - 1] >= 3) turn = true;
          if (c < 3 && tracks[r][c + 1] >= 3) turn = true;
        } else {
          if (r > 0 && tracks[r - 1][c] >= 3) turn = true;
          if (r < 3 && tracks[r + 1][c] >= 3) turn = true;
        }
        if (!turn) return false;
      } else if (clue == 'black') {
        if (type < 3) return false;
        for (final dir in _masyuConnections(type)) {
          if (dir == 'right' && (c + 1 > 3 || tracks[r][c + 1] != 1)) {
            return false;
          }
          if (dir == 'left' && (c - 1 < 0 || tracks[r][c - 1] != 1)) {
            return false;
          }
          if (dir == 'bottom' && (r + 1 > 3 || tracks[r + 1][c] != 2)) {
            return false;
          }
          if (dir == 'top' && (r - 1 < 0 || tracks[r - 1][c] != 2)) {
            return false;
          }
        }
      }
    }
  }
  return true;
}

Future<void> _fillMasyu(
  WidgetTester tester,
  Finder gestures,
  List<int> indices,
  List<List<int>> tracks,
) async {
  for (var i = 0; i < 16; i++) {
    for (var tap = 0; tap < tracks[i ~/ 4][i % 4]; tap++) {
      _tapGesture(tester, gestures.at(indices[i]));
      await tester.pump();
    }
  }
  await tester.pumpAndSettle();
}

class _FakeRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}

  @override
  List<GameStreak> getAllGameStreaks() => const [];

  @override
  Future<void> saveGameCompletion(UserData data, GameStreak streak) async {}
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [userRepositoryProvider.overrideWithValue(_FakeRepository())],
      child: MaterialApp(
        theme: DesignSystem.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _tapGesture(WidgetTester tester, Finder finder) {
  tester.widget<GestureDetector>(finder).onTap!();
}

List<List<TapaCell>> _tapaCells(TapaPuzzle puzzle) {
  return [
    for (var r = 0; r < puzzle.size; r++)
      [
        for (var c = 0; c < puzzle.size; c++)
          TapaCell(
            row: r,
            col: c,
            clues: puzzle.grid[r][c].clues,
            state: puzzle.solutionBlack[r][c]
                ? TapaCellState.black
                : TapaCellState.white,
          ),
      ],
  ];
}

TapaCell? _firstTapaClue(List<List<TapaCell>> cells) {
  for (final row in cells) {
    for (final cell in row) {
      if (cell.isClue) return cell;
    }
  }
  return null;
}

YajilinPuzzle _yajilinLoopPuzzle() {
  const size = 3;
  final grid = List.generate(
    size,
    (r) => List.generate(
      size,
      (c) => YajilinCell(
        r: r,
        c: c,
        clue: r == 0 && c == 1
            ? YajilinClue(ArrowDirection.down, 1)
            : r == 1 && c == 0
                ? YajilinClue(ArrowDirection.right, 1)
                : null,
        state:
            r == 1 && c == 1 ? YajilinCellState.black : YajilinCellState.empty,
      ),
    ),
  );
  const edges = [
    [0, 0, 0, 1],
    [0, 1, 0, 2],
    [0, 2, 1, 2],
    [1, 2, 2, 2],
    [2, 2, 2, 1],
    [2, 1, 2, 0],
    [2, 0, 1, 0],
    [1, 0, 0, 0],
  ];
  return YajilinPuzzle(
    size: size,
    grid: grid,
    edges: {for (final e in edges) YajilinEdge(e[0], e[1], e[2], e[3])},
  );
}

({List<int> rows, List<int> cols}) _kakurasuTargets(
  WidgetTester tester,
  Finder table,
) {
  final rect = tester.getRect(table);
  final cell = rect.width / 6;
  final rows = List<int?>.filled(4, null);
  final cols = List<int?>.filled(4, null);
  final texts =
      find.descendant(of: table, matching: find.byType(Text)).evaluate();
  for (final element in texts) {
    final text = element.widget as Text;
    final point = tester.getRect(find.byWidget(text)).center - rect.topLeft;
    final r = (point.dy / cell).floor();
    final c = (point.dx / cell).floor();
    final value = int.parse(text.data!);
    if (c == 5 && r >= 1 && r <= 4) rows[r - 1] = value;
    if (r == 5 && c >= 1 && c <= 4) cols[c - 1] = value;
  }
  return (rows: rows.cast<int>(), cols: cols.cast<int>());
}

int? _kakurasuSolution(({List<int> rows, List<int> cols}) targets) {
  for (var bits = 0; bits < 1 << 16; bits++) {
    var ok = true;
    for (var r = 0; r < 4 && ok; r++) {
      var sum = 0;
      for (var c = 0; c < 4; c++) {
        if (bits & (1 << (r * 4 + c)) != 0) sum += c + 1;
      }
      if (sum != targets.rows[r]) ok = false;
    }
    for (var c = 0; c < 4 && ok; c++) {
      var sum = 0;
      for (var r = 0; r < 4; r++) {
        if (bits & (1 << (r * 4 + c)) != 0) sum += r + 1;
      }
      if (sum != targets.cols[c]) ok = false;
    }
    if (ok) return bits;
  }
  return null;
}

int _firstSetBit(int bits) {
  for (var i = 0; i < 16; i++) {
    if (bits & (1 << i) != 0) return i;
  }
  return 0;
}

int _kakurasuScore(WidgetTester tester) {
  final text = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? '')
      .firstWhere((data) => data.contains('/ 3'));
  return int.parse(RegExp(r'(\d+) / 3').firstMatch(text)!.group(1)!);
}
