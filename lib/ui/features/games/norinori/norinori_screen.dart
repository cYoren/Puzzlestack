import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/utils/haptic_feedback.dart';
import 'package:puzzle/utils/l10n_game_helpers.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';
import '../../../core/juice/game_scaffold.dart';

class NorinoriPuzzle {
  final List<List<int>> roomIds; // 4x4 array of room indexes (e.g. 0 to K)
  final int totalRooms;

  NorinoriPuzzle({required this.roomIds, required this.totalRooms});
}

class NorinoriScreen extends ConsumerStatefulWidget {
  const NorinoriScreen({super.key});

  @override
  ConsumerState<NorinoriScreen> createState() => _NorinoriScreenState();
}

class _NorinoriScreenState extends ConsumerState<NorinoriScreen> {
  final Random _random = Random();
  final int _size = 4;

  final List<NorinoriPuzzle> _puzzles = [
    // Puzzle 1: 4 rooms
    NorinoriPuzzle(
      roomIds: [
        [0, 0, 1, 1],
        [0, 2, 2, 1],
        [3, 3, 2, 2],
        [3, 3, 2, 2]
      ],
      totalRooms: 4,
    ),
    // Puzzle 2: 3 rooms
    NorinoriPuzzle(
      roomIds: [
        [0, 0, 0, 1],
        [0, 2, 1, 1],
        [2, 2, 2, 1],
        [2, 2, 1, 1]
      ],
      totalRooms: 3,
    ),
    // Puzzle 3: 4 rooms
    NorinoriPuzzle(
      roomIds: [
        [0, 0, 0, 1],
        [3, 3, 1, 1],
        [3, 3, 2, 2],
        [3, 3, 2, 2]
      ],
      totalRooms: 4,
    ),
  ];

  late NorinoriPuzzle _currentPuzzle;
  late List<List<bool>> _shaded;
  bool _isSolved = false;

  /// What the player just did wrong, in one line, and the cells it refers to.
  String? _flash;
  Set<int> _flashCells = <int>{};
  Timer? _flashTimer;

  final List<Color> _roomColors = [
    DesignSystem.gameBlue.withValues(alpha: 0.15),
    DesignSystem.gamePurple.withValues(alpha: 0.15),
    DesignSystem.gameTeal.withValues(alpha: 0.15),
    DesignSystem.gameOrange.withValues(alpha: 0.15),
    DesignSystem.gamePink.withValues(alpha: 0.15),
  ];

  final List<Color> _borderColors = [
    DesignSystem.gameBlue,
    DesignSystem.gamePurple,
    DesignSystem.gameTeal,
    DesignSystem.gameOrange,
    DesignSystem.gamePink,
  ];

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _generatePuzzle() {
    _isSolved = false;
    _currentPuzzle = _puzzles[_random.nextInt(_puzzles.length)];
    _shaded = List.generate(_size, (_) => List.generate(_size, (_) => false));
  }

  /// The size of the shaded domino containing (r, c), or 0 when it is blank.
  int _groupSizeAt(List<List<bool>> shaded, int r, int c) {
    if (!shaded[r][c]) return 0;
    final seen = <Point<int>>{Point(r, c)};
    final queue = <Point<int>>[Point(r, c)];
    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      for (final next in [
        Point(cell.x - 1, cell.y),
        Point(cell.x + 1, cell.y),
        Point(cell.x, cell.y - 1),
        Point(cell.x, cell.y + 1),
      ]) {
        if (next.x < 0 || next.x >= _size || next.y < 0 || next.y >= _size) {
          continue;
        }
        if (shaded[next.x][next.y] && seen.add(next)) queue.add(next);
      }
    }
    return seen.length;
  }

  /// Why shading [r, c] would be illegal right now, or null.
  ///
  /// Only rules the player can check by looking are pre-empted: a room that
  /// already has its two, and a domino that would grow to three. The rest —
  /// exactly two per room, all of it in dominoes — is the win condition.
  String? _refusalFor(List<List<bool>> next, int r, int c) {
    var room = 0;
    for (var rr = 0; rr < _size; rr++) {
      for (var cc = 0; cc < _size; cc++) {
        if (next[rr][cc] &&
            _currentPuzzle.roomIds[rr][cc] == _currentPuzzle.roomIds[r][c]) {
          room++;
        }
      }
    }
    if (room > 2) {
      return 'THAT ROOM ALREADY HAS ITS TWO.';
    }
    if (_groupSizeAt(next, r, c) > 2) {
      return 'A SHADED GROUP IS EXACTLY TWO CELLS — NOT THREE.';
    }
    return null;
  }

  void _showFlash(String message, Set<int> cells) {
    _flashTimer?.cancel();
    setState(() {
      _flash = message;
      _flashCells = cells;
    });
    _flashTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _flash = null;
        _flashCells = <int>{};
      });
    });
  }

  void _toggleCell(int r, int c) {
    if (_isSolved) return;

    final next = [
      for (final row in _shaded) List<bool>.from(row),
    ];
    next[r][c] = !next[r][c];

    if (next[r][c]) {
      final refusal = _refusalFor(next, r, c);
      if (refusal != null) {
        HapticFeedbackUtil.error();
        _showFlash(refusal, {r * _size + c});
        return;
      }
    }

    HapticFeedbackUtil.lightImpact();
    setState(() {
      _shaded = next;
      _flash = null;
      _flashCells = <int>{};
    });
    _checkWinCondition();
  }

  bool _isComplete(List<List<bool>> shaded) {
    final counts = List.filled(_currentPuzzle.totalRooms, 0);
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        if (shaded[r][c]) counts[_currentPuzzle.roomIds[r][c]]++;
      }
    }
    if (counts.any((count) => count != 2)) return false;
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        if (shaded[r][c] && _groupSizeAt(shaded, r, c) != 2) return false;
      }
    }
    return true;
  }

  /// Brute force over 4x4, which is fast enough to run on a tap.
  List<List<bool>>? _answer() {
    for (var mask = 0; mask < (1 << (_size * _size)); mask++) {
      final shaded = [
        for (var r = 0; r < _size; r++)
          [for (var c = 0; c < _size; c++) (mask & (1 << (r * _size + c))) != 0],
      ];
      if (_isComplete(shaded)) return shaded;
    }
    return null;
  }

  void _hint() {
    if (_isSolved) return;
    final answer = _answer();
    if (answer == null) return;
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        if (answer[r][c] && !_shaded[r][c]) {
          HapticFeedbackUtil.selection();
          _showFlash('THIS CELL IS SHADED IN THE ANSWER.', {r * _size + c});
          return;
        }
      }
    }
  }

  void _solve() {
    if (_isSolved) return;
    final answer = _answer();
    if (answer == null) return;
    setState(() {
      _shaded = answer;
      _flash = null;
      _flashCells = <int>{};
    });
    _checkWinCondition();
  }

  void _checkWinCondition() {
    if (!_isComplete(_shaded)) return;
    _isSolved = true;
    _onGameComplete();
  }

  void _onGameComplete() async {
    HapticFeedbackUtil.victory();
    await ref.read(gameStreakNotifierProvider.notifier).completeGame('norinori');
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameCompletionDialog(
        title: AppLocalizations.of(context)!.wellDone.toUpperCase(),
        message: AppLocalizations.of(context)!.completed,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _generatePuzzle();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GameScaffold(
      title: L10nGameHelpers.getGameTitle(context, 'norinori'),
      subtitle: L10nGameHelpers.getGameSubtitle(context, 'norinori'),
      actions: [
        IconButton(
          icon: const Icon(Icons.lightbulb_outline_rounded),
          onPressed: _hint,
        ),
        IconButton(
          icon: const Icon(Icons.playlist_add_check_rounded),
          onPressed: _solve,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            HapticFeedbackUtil.lightImpact();
            setState(() {
              _generatePuzzle();
            });
          },
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSystem.spaceLG,
              vertical: DesignSystem.spaceSM,
            ),
            child: Text(
              'SHADE EXACTLY TWO CELLS IN EVERY ROOM. SHADED CELLS TOUCH IN PAIRS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: DesignSystem.fontSize2XS,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: AnimatedSwitcher(
              duration: DesignSystem.durationFast,
              child: _flash == null
                  ? const SizedBox.shrink()
                  : Text(
                      _flash!,
                      key: ValueKey(_flash),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: DesignSystem.fontSize2XS,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: DesignSystem.error,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340, maxHeight: 340),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
          decoration: BoxDecoration(
            color: isDark ? DesignSystem.darkSurface : DesignSystem.surface,
            borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
            border: Border.all(
              color: isDark ? DesignSystem.darkOutline : DesignSystem.outline,
              width: 3,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double cellSize = constraints.maxWidth / _size;

              return Stack(
                children: [
                  // Grid cell representation
                  for (int r = 0; r < _size; r++)
                    for (int c = 0; c < _size; c++)
                      Positioned(
                        left: c * cellSize,
                        top: r * cellSize,
                        width: cellSize,
                        height: cellSize,
                        child: GestureDetector(
                          onTap: () => _toggleCell(r, c),
                          child: Container(
                            foregroundDecoration: _flashCells.contains(r * _size + c)
                                ? BoxDecoration(
                                    border: Border.all(
                                      color: DesignSystem.error,
                                      width: 3,
                                    ),
                                  )
                                : null,
                            decoration: BoxDecoration(
                              color: _shaded[r][c]
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : _roomColors[_currentPuzzle.roomIds[r][c] % _roomColors.length],
                              border: Border(
                                top: BorderSide(
                                  color: r > 0 && _currentPuzzle.roomIds[r][c] == _currentPuzzle.roomIds[r - 1][c]
                                      ? Colors.grey.withValues(alpha: 0.2)
                                      : _borderColors[_currentPuzzle.roomIds[r][c] % _borderColors.length],
                                  width: r > 0 && _currentPuzzle.roomIds[r][c] == _currentPuzzle.roomIds[r - 1][c] ? 1 : 3.5,
                                ),
                                left: BorderSide(
                                  color: c > 0 && _currentPuzzle.roomIds[r][c] == _currentPuzzle.roomIds[r][c - 1]
                                      ? Colors.grey.withValues(alpha: 0.2)
                                      : _borderColors[_currentPuzzle.roomIds[r][c] % _borderColors.length],
                                  width: c > 0 && _currentPuzzle.roomIds[r][c] == _currentPuzzle.roomIds[r][c - 1] ? 1 : 3.5,
                                ),
                                bottom: BorderSide(
                                  color: r < _size - 1 && _currentPuzzle.roomIds[r][c] == _currentPuzzle.roomIds[r + 1][c]
                                      ? Colors.grey.withValues(alpha: 0.2)
                                      : _borderColors[_currentPuzzle.roomIds[r][c] % _borderColors.length],
                                  width: r < _size - 1 && _currentPuzzle.roomIds[r][c] == _currentPuzzle.roomIds[r + 1][c] ? 1 : 3.5,
                                ),
                                right: BorderSide(
                                  color: c < _size - 1 && _currentPuzzle.roomIds[r][c] == _currentPuzzle.roomIds[r][c + 1]
                                      ? Colors.grey.withValues(alpha: 0.2)
                                      : _borderColors[_currentPuzzle.roomIds[r][c] % _borderColors.length],
                                  width: c < _size - 1 && _currentPuzzle.roomIds[r][c] == _currentPuzzle.roomIds[r][c + 1] ? 1 : 3.5,
                                ),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: _shaded[r][c]
                                ? Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
