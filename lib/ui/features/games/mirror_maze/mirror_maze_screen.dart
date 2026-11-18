import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/utils/l10n_game_helpers.dart';
import 'package:puzzle/utils/haptic_feedback.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';
import '../../../core/juice/game_scaffold.dart';

// Mirror state: 0 = empty, 1 = diagonal / (bottom-left to top-right), 2 = diagonal \ (top-left to bottom-right)
class MirrorCell {
  int mirrorType = 0;
}

class MirrorMazePuzzle {
  final Point<int> laserStart; // start cell
  final Point<int> laserDir;   // initial movement vector (dx, dy)
  final Point<int> targetCell; // target cell
  final Point<int> targetDir;   // target exit direction vector (dx, dy)

  MirrorMazePuzzle({
    required this.laserStart,
    required this.laserDir,
    required this.targetCell,
    required this.targetDir,
  });
}

class MirrorMazeScreen extends ConsumerStatefulWidget {
  const MirrorMazeScreen({super.key});

  @override
  ConsumerState<MirrorMazeScreen> createState() => _MirrorMazeScreenState();
}

class _MirrorMazeScreenState extends ConsumerState<MirrorMazeScreen> {
  final Random _random = Random();
  final int _size = 4; // 4x4 grid

  late MirrorMazePuzzle _currentPuzzle;
  late List<List<MirrorCell>> _board;
  final List<Point<int>> _laserPath = [];
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
  }

  MirrorMazePuzzle _generateRandomPuzzle() {
    for (int attempt = 0; attempt < 200; attempt++) {
      final side = _random.nextInt(4);
      final offset = _random.nextInt(_size);
      late Point<int> start;
      late Point<int> dir;
      switch (side) {
        case 0:
          start = Point(0, offset);
          dir = const Point(1, 0);
        case 1:
          start = Point(_size - 1, offset);
          dir = const Point(-1, 0);
        case 2:
          start = Point(offset, 0);
          dir = const Point(0, 1);
        default:
          start = Point(offset, _size - 1);
          dir = const Point(0, -1);
      }

      // Simulate random valid mirror placements inside the 4x4 grid until the
      // ray exits the board, requiring at least 2 reflections.
      final mirrors = List.generate(_size, (_) => List.filled(_size, 0));
      var cur = start;
      var curDir = dir;
      int reflections = 0;
      Point<int>? exitCell;
      Point<int>? exitDir;

      for (int step = 0; step < 16; step++) {
        if (mirrors[cur.x][cur.y] == 0 && step > 0 && _random.nextDouble() < 0.4) {
          final m = _random.nextBool() ? 1 : 2;
          mirrors[cur.x][cur.y] = m;
          curDir = m == 1
              ? Point(-curDir.y, -curDir.x)
              : Point(curDir.y, curDir.x);
          reflections++;
        } else if (mirrors[cur.x][cur.y] != 0) {
          final m = mirrors[cur.x][cur.y];
          curDir = m == 1
              ? Point(-curDir.y, -curDir.x)
              : Point(curDir.y, curDir.x);
        }

        final next = Point(cur.x + curDir.x, cur.y + curDir.y);
        if (next.x < 0 || next.x >= _size || next.y < 0 || next.y >= _size) {
          exitCell = cur;
          exitDir = curDir;
          break;
        }
        cur = next;
      }

      if (exitCell != null &&
          exitDir != null &&
          reflections >= 2 &&
          exitCell != start) {
        return MirrorMazePuzzle(
          laserStart: start,
          laserDir: dir,
          targetCell: exitCell,
          targetDir: exitDir,
        );
      }
    }

    return MirrorMazePuzzle(
      laserStart: const Point(0, 0),
      laserDir: const Point(0, 1),
      targetCell: const Point(3, 2),
      targetDir: const Point(1, 0),
    );
  }

  void _generatePuzzle() {
    _isSolved = false;
    _currentPuzzle = _generateRandomPuzzle();
    _board = List.generate(_size, (_) => List.generate(_size, (_) => MirrorCell()));
    _traceLaser();
  }

  void _toggleMirror(int r, int c) {
    if (_isSolved) return;
    HapticFeedbackUtil.lightImpact();
    setState(() {
      _board[r][c].mirrorType = (_board[r][c].mirrorType + 1) % 3;
      _traceLaser();
      _checkWinCondition();
    });
  }

  void _traceLaser() {
    _laserPath.clear();

    Point<int> current = _currentPuzzle.laserStart;
    Point<int> dir = _currentPuzzle.laserDir;

    _laserPath.add(current);

    int steps = 0;
    while (steps < 20) { // Limit loop iterations
      final r = current.x;
      final c = current.y;

      // Handle reflection if inside board
      final mirror = _board[r][c].mirrorType;
      if (mirror == 1) { // /
        // Swap dir.x and -dir.y
        dir = Point(-dir.y, -dir.x);
      } else if (mirror == 2) { // \
        // Swap dir.x and dir.y
        dir = Point(dir.y, dir.x);
      }

      // Next step
      final next = Point(current.x + dir.x, current.y + dir.y);

      // Check if next coordinate goes outside bounds
      if (next.x < 0 || next.x >= _size || next.y < 0 || next.y >= _size) {
        // Exit path trace
        break;
      }

      _laserPath.add(next);
      current = next;
      steps++;
    }
  }

  void _checkWinCondition() {
    if (_laserPath.isEmpty) return;

    // Check if the final node in the laser path is the target cell
    final finalNode = _laserPath.last;
    if (finalNode == _currentPuzzle.targetCell) {
      // Trace what direction the beam exits this cell
      // We look at the final segment direction
      Point<int> finalDir;
      if (_laserPath.length == 1) {
        finalDir = _currentPuzzle.laserDir;
      } else {
        final secondLast = _laserPath[_laserPath.length - 2];
        finalDir = Point(finalNode.x - secondLast.x, finalNode.y - secondLast.y);
      }

      // Re-apply target cell mirror reflection to see if it matches targetDir
      final mirror = _board[finalNode.x][finalNode.y].mirrorType;
      Point<int> exitDir = finalDir;
      if (mirror == 1) {
        exitDir = Point(-finalDir.y, -finalDir.x);
      } else if (mirror == 2) {
        exitDir = Point(finalDir.y, finalDir.x);
      }

      if (exitDir == _currentPuzzle.targetDir) {
        _isSolved = true;
        _onGameComplete();
      }
    }
  }

  void _onGameComplete() async {
    HapticFeedbackUtil.victory();
    await ref.read(gameStreakNotifierProvider.notifier).completeGame('mirror_maze');
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
      title: L10nGameHelpers.getGameTitle(context, 'mirror_maze'),
      subtitle: L10nGameHelpers.getGameSubtitle(context, 'mirror_maze'),
      actions: [
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
      body: Center(
        child: Container(
          width: 300,
          height: 300,
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
                clipBehavior: Clip.none,
                children: [
                  // Laser source indicator
                  _buildSourceIndicator(cellSize),
                  // Target receiver indicator
                  _buildTargetIndicator(cellSize),
                  // Draw Cells and mirrors
                  for (int r = 0; r < _size; r++)
                    for (int c = 0; c < _size; c++)
                      Positioned(
                        left: c * cellSize,
                        top: r * cellSize,
                        width: cellSize,
                        height: cellSize,
                        child: GestureDetector(
                          onTap: () => _toggleMirror(r, c),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: (isDark ? DesignSystem.darkOutline : DesignSystem.outline).withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                            ),
                            child: CustomPaint(
                              painter: _MirrorPainter(
                                mirrorType: _board[r][c].mirrorType,
                                hasLaser: _laserPath.contains(Point(r, c)),
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                  // Draw Laser path
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _LaserPathPainter(path: _laserPath, cellSize: cellSize),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSourceIndicator(double cellSize) {
    final start = _currentPuzzle.laserStart;
    final dir = _currentPuzzle.laserDir;

    double left = start.y * cellSize;
    double top = start.x * cellSize;

    if (dir.y == 1) left -= 20; // Enters from Left
    if (dir.y == -1) left += cellSize; // Enters from Right
    if (dir.x == 1) top -= 20; // Enters from Top
    if (dir.x == -1) top += cellSize; // Enters from Bottom

    return Positioned(
      left: left + (dir.y != 0 ? 0 : cellSize / 2 - 10),
      top: top + (dir.x != 0 ? 0 : cellSize / 2 - 10),
      width: 20,
      height: 20,
      child: const Icon(Icons.play_arrow_rounded, color: DesignSystem.error, size: 24),
    );
  }

  Widget _buildTargetIndicator(double cellSize) {
    final target = _currentPuzzle.targetCell;
    final dir = _currentPuzzle.targetDir;

    double left = target.y * cellSize;
    double top = target.x * cellSize;

    if (dir.y == 1) left += cellSize; // Exits to Right
    if (dir.y == -1) left -= 20; // Exits to Left
    if (dir.x == 1) top += cellSize; // Exits to Bottom
    if (dir.x == -1) top -= 20; // Exits to Top

    return Positioned(
      left: left + (dir.y != 0 ? 0 : cellSize / 2 - 10),
      top: top + (dir.x != 0 ? 0 : cellSize / 2 - 10),
      width: 20,
      height: 20,
      child: const Icon(Icons.gps_fixed_rounded, color: DesignSystem.gameGreen, size: 20),
    );
  }
}

class _MirrorPainter extends CustomPainter {
  final int mirrorType;
  final bool hasLaser;
  final bool isDark;

  _MirrorPainter({required this.mirrorType, required this.hasLaser, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (mirrorType == 0) return;

    final paint = Paint()
      ..color = hasLaser ? DesignSystem.gameOrange : (isDark ? Colors.white38 : Colors.black38)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    if (mirrorType == 1) { // /
      canvas.drawLine(Offset(size.width * 0.15, size.height * 0.85), Offset(size.width * 0.85, size.height * 0.15), paint);
    } else if (mirrorType == 2) { // \
      canvas.drawLine(Offset(size.width * 0.15, size.height * 0.15), Offset(size.width * 0.85, size.height * 0.85), paint);
    }
  }

  @override
  bool shouldRepaint(_MirrorPainter oldDelegate) {
    return oldDelegate.mirrorType != mirrorType || oldDelegate.hasLaser != hasLaser || oldDelegate.isDark != isDark;
  }
}

class _LaserPathPainter extends CustomPainter {
  final List<Point<int>> path;
  final double cellSize;

  _LaserPathPainter({required this.path, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final paint = Paint()
      ..color = DesignSystem.error.withValues(alpha: 0.85)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final drawPath = Path();
    final half = cellSize / 2.0;

    Offset getCenter(Point<int> pt) {
      return Offset(pt.y * cellSize + half, pt.x * cellSize + half);
    }

    drawPath.moveTo(getCenter(path.first).dx, getCenter(path.first).dy);
    for (int i = 1; i < path.length; i++) {
      final nextCenter = getCenter(path[i]);
      drawPath.lineTo(nextCenter.dx, nextCenter.dy);
    }

    canvas.drawPath(drawPath, paint);
  }

  @override
  bool shouldRepaint(_LaserPathPainter oldDelegate) {
    return oldDelegate.path != path || oldDelegate.cellSize != cellSize;
  }
}
