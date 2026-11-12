import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:math' as math;
import '../../../utils/design_system.dart';
import '../../../widgets/tangible.dart';
import '../../../data/game_guides.dart';
import '../../../data/game_metadata.dart';
import '../../../data/game_registry.dart';
import '../../../widgets/game_guide_screen.dart';
import '../../../providers/user_providers.dart';
import '../../../utils/game_clock.dart';
import '../assist/game_assist.dart';

class GameScaffold extends ConsumerStatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final String? subtitle;
  final VoidCallback? onHowToPlay;
  final VoidCallback? onReset;

  const GameScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.subtitle,
    this.onHowToPlay,
    this.onReset,
  });

  @override
  ConsumerState<GameScaffold> createState() => _GameScaffoldState();
}

class _GameScaffoldState extends ConsumerState<GameScaffold> {
  bool _wakelockActive = false;

  /// Resolved once. The registry has 313 entries and `titleGetter` needs a
  /// localisation lookup each time, so doing it on every rebuild would be a
  /// small tax on every frame of a drag.
  GameMetadata? _resolvedGame;

  @override
  void initState() {
    super.initState();
    // The one place every game is timed from. `completeGame` reads this clock,
    // so 313 screens get a personal best without one line each.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = _resolveGame(context);
      if (game != null) GameClock.start(game.id);
    });
  }

  /// The registry entry behind this screen, matched on the title it shows.
  ///
  /// Screens do not pass their id to the shell (there are 313 of them), so the
  /// title is the key. A miss is not an error: a screen that is not registered
  /// simply gets no assist buttons.
  GameMetadata? _resolveGame(BuildContext context) {
    if (_resolvedGame != null) return _resolvedGame;
    final title = widget.title.toUpperCase();
    for (final game in allGamesMetadata) {
      try {
        if (game.titleGetter(context).toUpperCase() == title) {
          _resolvedGame = game;
          return game;
        }
      } catch (_) {
        // A game whose title needs localisation it does not have; skip it.
      }
    }
    return null;
  }

  @override
  void dispose() {
    if (_wakelockActive) {
      WakelockPlus.disable();
    }
    super.dispose();
  }

  void _syncWakelock(bool keepAwake) {
    if (keepAwake != _wakelockActive) {
      _wakelockActive = keepAwake;
      if (keepAwake) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keepAwake = ref.watch(
      userDataNotifierProvider.select((u) => u.isKeepScreenAwakeEnabled ?? false),
    );
    _syncWakelock(keepAwake);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final isMobile = DesignSystem.isMobile(context);
    
    // Calculate a responsive max width.
    // For games, we don't want the board to be wider than the available height
    // to prevent vertical overflow with AspectRatio(1) widgets.
    final availableHeight = mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom - kToolbarHeight;
    final responsiveMaxWidth = math.min(600.0, availableHeight * 0.85);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : math.max(400.0, responsiveMaxWidth)),
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(child: widget.body),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.bottomNavigationBar != null
          ? SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : math.max(400.0, responsiveMaxWidth)),
                  child: widget.bottomNavigationBar,
                ),
              ),
            )
          : null,
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spaceMD,
        DesignSystem.spaceSM,
        DesignSystem.spaceMD,
        DesignSystem.spaceXS,
      ),
      child: Row(
        children: [
          // Back button: simple, modern, borderless flat scaling button
          TangibleButton(
            color: Colors.transparent,
            drawBorder: false,
            onTap: () => Navigator.of(context).pop(),
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
              size: 22,
            ),
          ),
          const SizedBox(width: DesignSystem.spaceSM),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  widget.title.toUpperCase(), // Game titles uppercase
                  style: TextStyle(
                    fontFamily: 'Bebas Neue', // Header font family
                    fontSize: DesignSystem.fontSize2XL, // 24.0 (Gorgeous, high-readability title)
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          // The screen's own controls. `actions` used to be accepted and then
          // dropped on the floor, which is why hint and reset buttons existed
          // in every game and appeared in none.
          ...?widget.actions,
          ..._assistButtons(context),
          // Info / Help button: always shown for every game!
          const SizedBox(width: DesignSystem.spaceSM),
          TangibleButton(
            color: Colors.transparent,
            drawBorder: false,
            onTap: widget.onHowToPlay ?? () => _showDefaultHelpDialog(context),
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.info_outline_rounded,
              color: colorScheme.onSurface,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  /// Hint and solve for the games that can offer them.
  ///
  /// Hint names one step the rules can prove. Solve fills in the answer, behind
  /// a confirmation that says it will not count.
  List<Widget> _assistButtons(BuildContext context) {
    final game = _resolveGame(context);
    if (game == null) return const [];
    final actions = gameAssistFor(game.id, ref);
    if (actions == null || actions.isEmpty) return const [];

    final colorScheme = Theme.of(context).colorScheme;
    // Solve only: every board that has a hint already puts its own lightbulb
    // in `actions`, which the shell now renders. Two hint buttons in a 320dp
    // app bar was the alternative, and it overflowed by 18px.
    if (actions.onSolve == null) return const [];
    return [
      TangibleButton(
        color: Colors.transparent,
        drawBorder: false,
        onTap: () => _confirmSolve(game, actions),
        padding: const EdgeInsets.all(10),
        child: Icon(
          Icons.playlist_add_check_rounded,
          color: colorScheme.onSurface,
          size: 22,
        ),
      ),
    ];
  }

  Future<void> _confirmSolve(
    GameMetadata game,
    GameAssistActions actions,
  ) async {
    final solve = actions.onSolve;
    if (solve == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('SOLVE THIS BOARD?'),
        content: const Text(
          'The answer will be filled in. A solve for you still finishes the '
          'puzzle, but it does not earn XP and does not extend a streak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('KEEP PLAYING'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('SOLVE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    GameAssist.markAssisted(game.id);
    solve();
  }

  void _showDefaultHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Resolve detailed descriptive subtitle
    String? resolvedSubtitle = widget.subtitle;
    final matchingGame = _resolveGame(context);
    final gameId = matchingGame?.id;
    final gameColor = matchingGame?.color;
    if (matchingGame != null) {
      if (resolvedSubtitle == null ||
          resolvedSubtitle.toUpperCase() == widget.title.toUpperCase()) {
        resolvedSubtitle = matchingGame.subtitleGetter(context);
      }
    }

    // Every game ships a written guide. When the title resolves to a game that
    // has one, the info button opens the real thing instead of a dialog.
    if (gameId != null && gameGuides.containsKey(gameId)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameGuideScreen(
            gameId: gameId,
            gameColor: gameColor ?? colorScheme.primary,
          ),
        ),
      );
      return;
    }

    final Map<String, List<String>> detailedRules = {
      'kakuro': [
        "Goal: Fill all empty white cells with digits from 1 to 9.",
        "Sum Rule: The digits in each horizontal or vertical consecutive block (run) must add up to the clue number shown in the triangle above or to the left.",
        "Unique Rule: No digit can be repeated within the same block (row run or column run).",
      ],
      'futoshiki': [
        "Goal: Fill the grid with numbers so that every row and column contains each number exactly once.",
        "Inequality Rule: Respect the greater-than (>) and less-than (<) signs between adjacent cells.",
        "Unique Rule: No number can be repeated in any row or column.",
      ],
      'akari': [
        "Goal: Place light bulbs in white cells to illuminate the entire grid.",
        "Illumination Rule: A bulb illuminates all cells in its row and column, unless blocked by a black cell.",
        "No-Clash Rule: No two light bulbs may illuminate each other.",
        "Clue Rule: Numbered black cells indicate exactly how many light bulbs must be placed in their four adjacent (orthogonal) cells.",
      ],
      'sudoku': [
        "Goal: Fill the 9x9 grid with numbers 1 to 9.",
        "Unique Rule: Each row, column, and 3x3 sub-grid must contain all numbers from 1 to 9 without duplicates.",
      ],
      'alphabet_sudoku': [
        "Goal: Fill the 9x9 grid with letters from A to I.",
        "Unique Rule: Each row, column, and 3x3 sub-grid must contain all letters from A to I without duplicates.",
      ],
      'slitherlink': [
        "Goal: Connect dots on the grid to form a single, continuous loop.",
        "Loop Rule: The loop must be closed, must not self-intersect, and cannot have branches.",
        "Clue Rule: Numbers inside cells indicate exactly how many of their 4 surrounding borders are part of the loop. Empty cells can have any number of borders.",
      ],
      'bridges': [
        "Goal: Connect all circular islands with horizontal or vertical bridges.",
        "Bridge Rules: Bridges cannot cross each other or pass through other islands.",
        "Count Rule: At most two bridges can connect any pair of islands.",
        "Island Rule: The number on an island indicates exactly how many bridges must connect to it. All islands must end up connected in a single network.",
      ],
      'kenken': [
        "Goal: Fill the grid with numbers 1 to N (where N is the grid size).",
        "Unique Rule: Each row and column must contain every number exactly once.",
        "Cage Rule: The numbers in each outlined group of cells (cage) must combine to produce the target value using the shown math operator (+, -, ×, ÷).",
      ],
      'nurikabe': [
        "Goal: Partition the grid into white islands and a continuous blue stream (sea).",
        "Island Rule: Each white island must contain exactly one numbered cell, and its cell count must equal that number.",
        "Stream Rule: All blue stream cells must be connected diagonally or orthogonally.",
        "Block Rule: The blue stream cannot form 2x2 solid blocks of water cells.",
      ],
      'hitori': [
        "Goal: Shade cells to eliminate duplicate numbers in rows and columns.",
        "Unique Rule: In the final grid, no unshaded number can appear more than once in any row or column.",
        "Adjacency Rule: Shaded (black) cells cannot touch horizontally or vertically.",
        "Connectivity Rule: All unshaded cells must be connected to form a single continuous area.",
      ],
      'nonogram': [
        "Goal: Shade cells in the grid to reveal a hidden pixel image.",
        "Clue Rule: The numbers at the start of each row and column indicate the sizes of consecutive blocks of shaded cells.",
        "Spacing Rule: There must be at least one empty cell separating consecutive blocks in a row or column.",
      ],
      'skyscrapers': [
        "Goal: Fill the grid with numbers 1 to N representing skyscrapers of different heights.",
        "Unique Rule: Each row and column must contain every height exactly once.",
        "Visibility Rule: The numbers around the border indicate how many skyscrapers are visible from that direction (taller buildings block shorter ones behind them).",
      ],
      'dominosa': [
        "Goal: Reconstruct a complete set of dominoes on the grid.",
        "Rule: Draw borders around pairs of adjacent cells to form distinct dominoes. Each possible domino combination must appear exactly once in the grid.",
      ],
      'lighthouses': [
        "Goal: Find all hidden ships in the grid.",
        "Rule: Lighthouses (numbered cells) fire beams horizontally and vertically. The number indicates how many ships they illuminate in total.",
        "Rule: Ships cannot touch lighthouses or other ships, even diagonally.",
      ],
      'magnets': [
        "Goal: Place magnetic plates (positive/negative poles) or blank plates in the grid.",
        "Rule: Like magnetic poles (+ and +, or - and -) cannot touch orthogonally.",
        "Rule: Numbers on the borders indicate how many positive (+) and negative (-) poles are in each row/column.",
      ],
      'change_blindness': [
        "Goal: Spot the single tile that changes color or shape between alternating flickers.",
        "Flicker Rule: The board briefly flickers every second. Watch closely to detect what changes.",
        "Time & Score: You have 60 seconds. Each correct spot earns +1 point and advances you to the next trial.",
        "Penalty: Tapping an incorrect tile reduces remaining time by 2 seconds.",
      ],
      'semantic_distance': [
        "Goal: Guess the secret hidden word before time runs out.",
        "Input: Type any word into the input field and press send.",
        "Distance Score: Each submitted guess shows a semantic distance score indicating conceptual distance to the secret word.",
        "Clues: Lower distance scores mean warmer/closer (e.g. 10 is very close, 80 is unrelated).",
        "Victory: Submit the exact secret word to get a distance of 0.0 and solve the puzzle.",
      ],
    };

    final rulesList = gameId != null ? detailedRules[gameId] : null;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: TangibleContainer(
              radius: DesignSystem.radiusLG,
              padding: const EdgeInsets.all(DesignSystem.spaceLG),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: DesignSystem.spaceSM),
                      Text(
                        "HOW TO PLAY",
                        style: TextStyle(
                          fontFamily: 'Bebas Neue',
                          fontSize: DesignSystem.fontSize2XL,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignSystem.spaceMD),
                  Text(
                    widget.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: DesignSystem.spaceMD),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignSystem.spaceMD),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resolvedSubtitle ?? "Objective: Solve the puzzle by completing the goals.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.9),
                            fontSize: 14.0,
                            height: 1.4,
                          ),
                        ),
                        if (rulesList != null && rulesList.isNotEmpty) ...[
                          const SizedBox(height: DesignSystem.spaceMD),
                          Divider(color: colorScheme.outline.withValues(alpha: 0.3), height: 1),
                          const SizedBox(height: DesignSystem.spaceMD),
                          Text(
                            "RULES & CONDITIONS:",
                            style: TextStyle(
                              fontSize: DesignSystem.fontSizeSM,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: DesignSystem.spaceSM),
                          ...rulesList.map((rule) => Padding(
                            padding: const EdgeInsets.only(bottom: DesignSystem.spaceXS),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "• ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    rule,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                                      fontSize: 13.0,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignSystem.spaceLG),
                  TangibleButton(
                    color: colorScheme.primary,
                    width: double.infinity,
                    onTap: () => Navigator.of(context).pop(),
                    child: Center(
                      child: Text(
                        "GOT IT",
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

