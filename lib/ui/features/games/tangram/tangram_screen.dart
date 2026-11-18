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

class TangramPiece {
  final int id;
  final List<Point<int>> cells; // Relative offsets of cells from pivot (0,0)
  final Color color;

  TangramPiece({required this.id, required this.cells, required this.color});
}

class TangramScreen extends ConsumerStatefulWidget {
  const TangramScreen({super.key});

  @override
  ConsumerState<TangramScreen> createState() => _TangramScreenState();
}

class _TangramScreenState extends ConsumerState<TangramScreen> {
  final Random _random = Random();
  final int _gridSize = 4;

  // Puzzle lists
  late List<Point<int>> _targetOutline; // Cells that must be filled
  late List<TangramPiece> _pieces;

  // Selection & Placement state
  int? _selectedPieceId;
  List<Point<int>?> _piecePlacements = []; // Pivot positions for pieces (index matches piece index)
  List<int> _pieceRotations = []; // 0=0°, 1=90°, 2=180°, 3=270° for each piece

  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
  }

  void _generatePuzzle() {
    _isSolved = false;
    _selectedPieceId = null;

    const palette = [
      DesignSystem.gameBlue,
      DesignSystem.gamePurple,
      DesignSystem.gameTeal,
      DesignSystem.gameOrange,
      DesignSystem.gameRose,
    ];

    // Grow a contiguous 6..10-cell silhouette inside the 4x4 board.
    final targetCount = 6 + _random.nextInt(5);
    final start = Point(_random.nextInt(_gridSize), _random.nextInt(_gridSize));
    final shape = <Point<int>>{start};
    final frontier = <Point<int>>[start];

    List<Point<int>> neighborsOf(Point<int> p) => [
          if (p.x > 0) Point(p.x - 1, p.y),
          if (p.x < _gridSize - 1) Point(p.x + 1, p.y),
          if (p.y > 0) Point(p.x, p.y - 1),
          if (p.y < _gridSize - 1) Point(p.x, p.y + 1),
        ];

    while (shape.length < targetCount && frontier.isNotEmpty) {
      final pick = frontier[_random.nextInt(frontier.length)];
      final candidates = neighborsOf(pick).where((n) => !shape.contains(n)).toList();
      if (candidates.isEmpty) {
        frontier.remove(pick);
        continue;
      }
      final added = candidates[_random.nextInt(candidates.length)];
      shape.add(added);
      frontier.add(added);
    }

    // Carve the silhouette into 2..4 contiguous polyomino pieces so a valid
    // tiling always exists.
    final remaining = Set<Point<int>>.from(shape);
    final rawPieces = <List<Point<int>>>[];
    while (remaining.isNotEmpty) {
      final seed = remaining.elementAt(_random.nextInt(remaining.length));
      final chunkSize = (2 + _random.nextInt(2)).clamp(1, remaining.length);
      final chunk = <Point<int>>{seed};
      final chunkFrontier = <Point<int>>[seed];
      remaining.remove(seed);

      while (chunk.length < chunkSize && chunkFrontier.isNotEmpty) {
        final cur = chunkFrontier[_random.nextInt(chunkFrontier.length)];
        final candidates =
            neighborsOf(cur).where(remaining.contains).toList();
        if (candidates.isEmpty) {
          chunkFrontier.remove(cur);
          continue;
        }
        final next = candidates[_random.nextInt(candidates.length)];
        chunk.add(next);
        chunkFrontier.add(next);
        remaining.remove(next);
      }
      rawPieces.add(chunk.toList());
    }

    // Merge any single-cell orphan piece into an adjacent piece if small enough.
    if (rawPieces.length > 2) {
      for (int i = rawPieces.length - 1; i >= 0; i--) {
        if (rawPieces[i].length != 1) continue;
        final single = rawPieces[i].first;
        for (int j = 0; j < rawPieces.length; j++) {
          if (i == j || rawPieces[j].length >= 4) continue;
          final touches = rawPieces[j].any(
            (p) => (p.x - single.x).abs() + (p.y - single.y).abs() == 1,
          );
          if (touches) {
            rawPieces[j].add(single);
            rawPieces.removeAt(i);
            break;
          }
        }
      }
    }

    _targetOutline = shape.toList();
    _pieces = [
      for (int i = 0; i < rawPieces.length; i++)
        TangramPiece(
          id: i,
          color: palette[i % palette.length],
          cells: _getRotatedCells(rawPieces[i], _random.nextInt(4)),
        ),
    ];

    _piecePlacements = List.filled(_pieces.length, null);
    _pieceRotations = List.filled(_pieces.length, 0);
  }

  /// Returns the cells of a piece after applying the given number of 90° CW
  /// rotations, normalised so the minimum row/col offset is 0.
  List<Point<int>> _getRotatedCells(List<Point<int>> cells, int rotations) {
    var result = cells;
    for (int r = 0; r < (rotations % 4); r++) {
      // 90° clockwise: (x, y) → (y, -x)
      result = result.map((p) => Point(p.y, -p.x)).toList();
    }
    // Normalise so all offsets are non-negative
    final minR = result.map((p) => p.x).reduce(min);
    final minC = result.map((p) => p.y).reduce(min);
    return result.map((p) => Point(p.x - minR, p.y - minC)).toList();
  }

  void _onCellTapped(int r, int c) {
    if (_isSolved || _selectedPieceId == null) return;

    final pieceIdx = _pieces.indexWhere((p) => p.id == _selectedPieceId);
    if (pieceIdx == -1) return;

    HapticFeedbackUtil.lightImpact();
    setState(() {
      final point = Point(r, c);

      // Check if placement fits entirely inside grid boundaries
      bool fits = true;
      final cells = _getRotatedCells(_pieces[pieceIdx].cells, _pieceRotations[pieceIdx]);
      for (var offset in cells) {
        final nr = r + offset.x;
        final nc = c + offset.y;
        if (nr < 0 || nr >= _gridSize || nc < 0 || nc >= _gridSize) {
          fits = false;
          break;
        }
      }

      if (fits) {
        _piecePlacements[pieceIdx] = point;
        _checkWinCondition();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.snackbarPieceDoesNotFit), duration: Duration(milliseconds: 600)),
        );
      }
    });
  }

  void _checkWinCondition() {
    // 1. All pieces must be placed
    for (var placement in _piecePlacements) {
      if (placement == null) return;
    }

    // 2. Track all filled coordinates
    final Set<Point<int>> filled = {};
    for (int i = 0; i < _pieces.length; i++) {
      final placement = _piecePlacements[i]!;
      final cells = _getRotatedCells(_pieces[i].cells, _pieceRotations[i]);
      for (var offset in cells) {
        final pt = Point(placement.x + offset.x, placement.y + offset.y);
        // Overlap check
        if (filled.contains(pt)) return;
        filled.add(pt);
      }
    }

    // 3. Check if filled matches outline exactly
    if (filled.length != _targetOutline.length) return;
    for (var pt in _targetOutline) {
      if (!filled.contains(pt)) return;
    }

    _isSolved = true;
    _onGameComplete();
  }

  void _onGameComplete() async {
    HapticFeedbackUtil.victory();
    await ref.read(gameStreakNotifierProvider.notifier).completeGame('tangram');
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
      title: L10nGameHelpers.getGameTitle(context, 'tangram'),
      subtitle: L10nGameHelpers.getGameSubtitle(context, 'tangram'),
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
      body: Column(
        children: [
          // Target Outline Board
          Expanded(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: isDark ? DesignSystem.darkSurface : DesignSystem.surface,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
                  border: Border.all(
                    color: isDark ? DesignSystem.darkOutline : DesignSystem.outline,
                    width: 2,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double cellSize = constraints.maxWidth / _gridSize;

                    // Compute which cells are currently covered by placed pieces
                    final Map<Point<int>, Color> coveredMap = {};
                    for (int i = 0; i < _pieces.length; i++) {
                      final placement = _piecePlacements[i];
                      if (placement != null) {
                        final rotatedCells = _getRotatedCells(_pieces[i].cells, _pieceRotations[i]);
                        for (var offset in rotatedCells) {
                          final pt = Point(placement.x + offset.x, placement.y + offset.y);
                          coveredMap[pt] = _pieces[i].color;
                        }
                      }
                    }

                    return Stack(
                      children: [
                        for (int r = 0; r < _gridSize; r++)
                          for (int c = 0; c < _gridSize; c++)
                            Positioned(
                              left: c * cellSize,
                              top: r * cellSize,
                              width: cellSize,
                              height: cellSize,
                              child: GestureDetector(
                                onTap: () => _onCellTapped(r, c),
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: coveredMap.containsKey(Point(r, c))
                                        ? coveredMap[Point(r, c)]
                                        : (_targetOutline.contains(Point(r, c))
                                            ? Colors.grey.withValues(alpha: 0.3)
                                            : Colors.transparent),
                                    borderRadius: BorderRadius.circular(DesignSystem.radiusXS),
                                    border: _targetOutline.contains(Point(r, c))
                                        ? Border.all(
                                            color: isDark ? Colors.white30 : Colors.black26,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
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
          // Pieces Dock / Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: isDark ? Colors.black12 : Colors.grey.withValues(alpha: 0.05),
            child: Column(
              children: [
                Text(
                  'PIECES DOCK (Tap to select, then tap grid to place, double-tap to rotate)',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(                mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pieces.length, (index) {
                    final piece = _pieces[index];
                    final isSelected = _selectedPieceId == piece.id;
                    final isPlaced = _piecePlacements[index] != null;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedbackUtil.lightImpact();
                        setState(() {
                          // Toggle or select
                          if (isSelected) {
                            // If selected and already placed, recall/reset placement
                            _piecePlacements[index] = null;
                            _selectedPieceId = null;
                          } else {
                            _selectedPieceId = piece.id;
                          }
                        });
                      },
                      onDoubleTap: () {
                        HapticFeedbackUtil.lightImpact();
                        setState(() {
                          // Rotate the piece 90° CW and clear its placement
                          _pieceRotations[index] = (_pieceRotations[index] + 1) % 4;
                          _piecePlacements[index] = null;
                          _selectedPieceId = piece.id;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DesignSystem.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
                          border: Border.all(
                            color: isSelected ? DesignSystem.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Miniature piece shape representation
                            Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              child: Stack(
                                children: _getRotatedCells(piece.cells, _pieceRotations[index]).map((cell) {
                                  // Map cell relative points to offset multipliers
                                  return Positioned(
                                    left: cell.y * 12.0 + 6,
                                    top: cell.x * 12.0 + 6,
                                    width: 10,
                                    height: 10,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: piece.color.withValues(alpha: isPlaced ? 0.4 : 1.0),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isSelected && !isPlaced)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.rotate_right_rounded,
                                  size: 14,
                                  color: DesignSystem.primary,
                                ),
                              ),
                            Text(
                              isPlaced ? 'PLACED' : (isSelected ? 'ACTIVE' : 'SELECT'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPlaced ? Colors.grey : (isSelected ? DesignSystem.primary : null),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
