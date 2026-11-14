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
import '../../../../widgets/game_hud.dart';

class WordSnakeTrailScreen extends ConsumerStatefulWidget {
  const WordSnakeTrailScreen({super.key});

  @override
  ConsumerState<WordSnakeTrailScreen> createState() => _WordSnakeTrailScreenState();
}

/// The words a trail can spell.
///
/// A cell can be used once per attempt, so a word with a repeated letter
/// (BOOK, RIVER, GREEN) cannot be traced even though the generator will place
/// it. Ten words meant the tenth puzzle was the first one again.
final List<String> wordSnakePool = [
  'BLUE',
  'ROSE',
  'PINE',
  'DESK',
  'STAR',
  'FISH',
  'PLAN',
  'WIND',
  'GOLD',
  'LION',
  'LAMP',
  'MINT',
  'SAND',
  'WOLF',
  'CAKE',
  'FROG',
  'MILK',
  'RING',
  'MAZE',
  'QUIZ',
  'JUMP',
  'WAVE',
  'LEAF',
  'RAIN',
  'SNOW',
  'BOAT',
  'SHIP',
  'KING',
  'PARK',
  'LANE',
  'ROPE',
  'VASE',
  'HARP',
  'DRUM',
  'TIGER',
  'CLOUD',
  'MELON',
  'BRAIN',
  'HOUSE',
  'WATER',
  'SUGAR',
  'MUSIC',
  'NIGHT',
  'LIGHT',
  'STONE',
  'HORSE',
  'BREAD',
  'CHAIR',
  'DREAM',
  'OCEAN',
  'PLANT',
  'SMILE',
  'MONEY',
  'YOUTH',
  'WORLD',
  'TEACH',
];

/// The board is `wordSnakeGridSize` square, so no word may be longer than the
/// number of cells a single trail can walk.
const int wordSnakeGridSize = 4;

/// A trail of [length] cells on a [gridSize] square board, one cell per letter
/// and never the same cell twice.
///
/// Depth-first with backtracking, so it always completes: the random walk this
/// replaced could corner itself on a 4x4 board (four steps into a corner) and
/// then had to reuse a cell, which put two of one letter on the board and left
/// the player tracing a word that could not be traced.
List<Point<int>> buildWordSnakeTrail({
  required int gridSize,
  required int length,
  Random? random,
}) {
  final rng = random ?? Random();
  final cells = gridSize * gridSize;
  final wanted = length > cells ? cells : length;
  for (var attempt = 0; attempt < 40; attempt++) {
    final start = Point(rng.nextInt(gridSize), rng.nextInt(gridSize));
    final trail = <Point<int>>[start];
    if (_extendTrail(trail, wanted, gridSize, rng)) return trail;
  }
  // With room on the board this is unreachable; a straight walk along the top
  // row is the fallback so the screen always has a trail to draw.
  return [for (var x = 0; x < wanted; x++) Point(x % gridSize, x ~/ gridSize)];
}

bool _extendTrail(
  List<Point<int>> trail,
  int length,
  int gridSize,
  Random rng,
) {
  if (trail.length == length) return true;
  final last = trail.last;
  final options = <Point<int>>[];
  if (last.x > 0) options.add(Point(last.x - 1, last.y));
  if (last.x < gridSize - 1) options.add(Point(last.x + 1, last.y));
  if (last.y > 0) options.add(Point(last.x, last.y - 1));
  if (last.y < gridSize - 1) options.add(Point(last.x, last.y + 1));
  options.shuffle(rng);
  for (final next in options) {
    if (trail.contains(next)) continue;
    trail.add(next);
    if (_extendTrail(trail, length, gridSize, rng)) return true;
    trail.removeLast();
  }
  return false;
}

class _WordSnakeTrailScreenState extends ConsumerState<WordSnakeTrailScreen> {
  final Random _random = Random();
  int _score = 0;
  final int _targetScore = 3;
  bool _isGameOver = false;

  int get _gridSize => wordSnakeGridSize;
  late List<List<String>> _grid;

  // The secret word trail (sequential cell coordinates)
  late List<Point<int>> _secretTrail;
  late String _secretWord;
  final List<Point<int>> _userTrail = [];

  List<String> get _wordsPool => wordSnakePool;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
  }

  void _generatePuzzle() {
    _userTrail.clear();
    _secretWord = _wordsPool[_random.nextInt(_wordsPool.length)];

    // Generate grid matrix filled with random letters
    _grid = List.generate(_gridSize, (_) => List.generate(_gridSize, (_) {
      return String.fromCharCode(65 + _random.nextInt(26)); // Random A-Z
    }));

    // A trail of exactly one cell per letter, built by depth-first search so
    // it always completes. The random walk this replaced could corner itself
    // (a 4x4 board traps a walk at a corner after four steps) and then place
    // the same letter on a cell twice, which made the word unsolvable.
    _secretTrail = buildWordSnakeTrail(
      gridSize: _gridSize,
      length: _secretWord.length,
      random: _random,
    );
    for (var i = 0; i < _secretWord.length; i++) {
      _grid[_secretTrail[i].y][_secretTrail[i].x] = _secretWord[i];
    }
  }

  void _onCellTapped(int r, int c) {
    if (_isGameOver) return;

    final cellPoint = Point(c, r);
    final expectedIndex = _userTrail.length;

    // Check if the tapped cell is a valid next step in a word snake path spelling _secretWord
    bool isValid = false;
    if (expectedIndex < _secretWord.length && _grid[r][c] == _secretWord[expectedIndex]) {
      if (expectedIndex == 0) {
        isValid = true;
      } else {
        final last = _userTrail.last;
        final isAdjacent = (cellPoint.x - last.x).abs() + (cellPoint.y - last.y).abs() == 1;
        final isNotVisited = !_userTrail.contains(cellPoint);
        if (isAdjacent && isNotVisited) {
          isValid = true;
        }
      }
    }

    if (isValid) {
      HapticFeedbackUtil.lightImpact();
      setState(() {
        _userTrail.add(cellPoint);

        // Check if full word trail successfully traced
        if (_userTrail.length == _secretWord.length) {
          _score++;
          HapticFeedbackUtil.success();
          if (_score >= _targetScore) {
            _isGameOver = true;
            _onGameComplete();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.snackbarWordMatchedTracing),
                backgroundColor: DesignSystem.gameGreen,
                duration: Duration(seconds: 1),
              ),
            );
            setState(() {
              _generatePuzzle();
            });
          }
        }
      });
    } else {
      HapticFeedbackUtil.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.snackbarIncorrectTraceFromStart),
          backgroundColor: DesignSystem.error,
          duration: Duration(milliseconds: 600),
        ),
      );
      setState(() {
        _userTrail.clear();
      });
    }
  }

  void _onGameComplete() async {
    HapticFeedbackUtil.victory();
    await ref.read(gameStreakNotifierProvider.notifier).completeGame('word_snake_trail');
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
            _score = 0;
            _isGameOver = false;
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
      title: L10nGameHelpers.getGameTitle(context, 'word_snake_trail'),
      subtitle: L10nGameHelpers.getGameSubtitle(context, 'word_snake_trail'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            HapticFeedbackUtil.lightImpact();
            setState(() {
              _score = 0;
              _isGameOver = false;
              _generatePuzzle();
            });
          },
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(DesignSystem.spaceMD),
        child: Column(
          children: [
            // Score and Target info
              GameHud(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignSystem.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSM),
                  ),
                  child: Text(
                    'TARGET WORD: $_secretWord',
                    style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.primary, fontSize: 16),
                  ),
                ),
                Text(
                  '${AppLocalizations.of(context)!.statScore}: $_score / $_targetScore',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // The trace grid
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? DesignSystem.darkSurface : DesignSystem.surface,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
                      border: Border.all(
                        color: isDark ? DesignSystem.darkOutline : DesignSystem.outline,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 16,
                      itemBuilder: (context, idx) {
                        final r = idx ~/ 4;
                        final c = idx % 4;
                        final cellPoint = Point(c, r);
                        final isTraced = _userTrail.contains(cellPoint);

                        return GestureDetector(
                          onTap: () => _onCellTapped(r, c),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isTraced
                                  ? DesignSystem.gameGreen.withValues(alpha: 0.2)
                                  : (isDark ? Colors.white10 : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(DesignSystem.radiusSM),
                              border: Border.all(
                                color: isTraced ? DesignSystem.gameGreen : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _grid[r][c],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isTraced ? DesignSystem.gameGreen : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Trail Progress Tracker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_secretWord.length, (idx) {
                final active = _userTrail.length > idx;
                return Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: active ? DesignSystem.gameGreen : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
