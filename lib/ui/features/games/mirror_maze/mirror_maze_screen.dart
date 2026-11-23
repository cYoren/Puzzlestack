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
import '../../feed/feed_session.dart';
import 'mirror_maze_engine.dart';

class MirrorMazeScreen extends ConsumerStatefulWidget {
  const MirrorMazeScreen({this.seed, super.key});

  /// Fixes the board. A test passes one to get the same deal every run; the
  /// feed passes its own so a repeated card is the same card. Null falls back
  /// to the feed's seed when there is one, and to the clock otherwise.
  final int? seed;

  @override
  ConsumerState<MirrorMazeScreen> createState() => _MirrorMazeScreenState();
}

class _MirrorMazeScreenState extends ConsumerState<MirrorMazeScreen> {
  final int _size = 4; // 4x4 grid

  late final MirrorMazeGenerator _generator;
  late MirrorMazeDeal _deal;
  late List<List<int>> _board;
  MirrorMazeTrace _trace = const MirrorMazeTrace(
    path: <Point<int>>[],
    hit: <Point<int>, int>{},
    exitCell: null,
    exitDir: Point<int>(0, 0),
  );

  /// A new list on every trace, never mutated in place: `_LaserPathPainter`
  /// compares the list it was given with the one before it, so a reused list
  /// repaints as unchanged.
  List<Point<int>> _laserPath = const <Point<int>>[];
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    final int seed = widget.seed ??
        FeedSession.seedOf('mirror_maze') ??
        Random().nextInt(1 << 32);
    _generator = MirrorMazeGenerator(random: Random(seed), size: _size);
    _generatePuzzle();
  }

  void _generatePuzzle() {
    _isSolved = false;
    _deal = _generator.next();
    _board = List.generate(_size, (_) => List.filled(_size, Mirror.empty));
    _traceLaser();
  }

  void _toggleMirror(int r, int c) {
    if (_isSolved) return;
    HapticFeedbackUtil.lightImpact();
    setState(() {
      _board[r][c] = Mirror.next(_board[r][c]);
      _traceLaser();
      _checkWinCondition();
    });
  }

  Map<Point<int>, int> _mirrors() {
    return <Point<int>, int>{
      for (int r = 0; r < _size; r++)
        for (int c = 0; c < _size; c++)
          if (_board[r][c] != Mirror.empty) Point<int>(r, c): _board[r][c],
    };
  }

  void _traceLaser() {
    _trace = traceBeam(
      mirrors: _mirrors(),
      start: _deal.start,
      startDir: _deal.startDir,
      size: _size,
    );
    _laserPath = _trace.path;
  }

  void _checkWinCondition() {
    // The deal is won when the beam left the board from the receiver's cell in
    // the receiver's direction. A beam that never left cannot win, however
    // close its last cell got.
    if (_trace.exitCell != _deal.target) return;
    if (_trace.exitDir != _deal.targetDir) return;
    _isSolved = true;
    _onGameComplete();
  }

  void _onGameComplete() async {
    HapticFeedbackUtil.victory();
    await ref
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('mirror_maze');
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
                                color: (isDark
                                        ? DesignSystem.darkOutline
                                        : DesignSystem.outline)
                                    .withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                            ),
                            child: CustomPaint(
                              painter: _MirrorPainter(
                                mirrorType: _board[r][c],
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
                      painter: _LaserPathPainter(
                          path: _laserPath, cellSize: cellSize),
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
    final start = _deal.start;
    final dir = _deal.startDir;

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
      child: const Icon(Icons.play_arrow_rounded,
          color: DesignSystem.error, size: 24),
    );
  }

  Widget _buildTargetIndicator(double cellSize) {
    final target = _deal.target;
    final dir = _deal.targetDir;

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
      child: const Icon(Icons.gps_fixed_rounded,
          color: DesignSystem.gameGreen, size: 20),
    );
  }
}

class _MirrorPainter extends CustomPainter {
  final int mirrorType;
  final bool hasLaser;
  final bool isDark;

  _MirrorPainter(
      {required this.mirrorType, required this.hasLaser, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (mirrorType == 0) return;

    final paint = Paint()
      ..color = hasLaser
          ? DesignSystem.gameOrange
          : (isDark ? Colors.white38 : Colors.black38)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    if (mirrorType == 1) {
      // /
      canvas.drawLine(Offset(size.width * 0.15, size.height * 0.85),
          Offset(size.width * 0.85, size.height * 0.15), paint);
    } else if (mirrorType == 2) {
      // \
      canvas.drawLine(Offset(size.width * 0.15, size.height * 0.15),
          Offset(size.width * 0.85, size.height * 0.85), paint);
    }
  }

  @override
  bool shouldRepaint(_MirrorPainter oldDelegate) {
    return oldDelegate.mirrorType != mirrorType ||
        oldDelegate.hasLaser != hasLaser ||
        oldDelegate.isDark != isDark;
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
