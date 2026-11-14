import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/l10n_game_helpers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/game_metadata.dart';
import '../data/game_registry.dart';
import '../ui/features/feed/feed_session.dart';
import '../utils/design_system.dart';
import '../utils/game_clock.dart';
import '../providers/game_stats_provider.dart';
import '../utils/haptic_feedback.dart';
import '../utils/navigation_utils.dart';
import '../providers/game_providers.dart';
import '../providers/game_session_provider.dart';
import '../providers/user_providers.dart';
import 'deck.dart';
import 'tangible.dart';

class GameCompletionDialog extends ConsumerStatefulWidget {
  final VoidCallback onHome;
  final VoidCallback onPlayAgain;
  final String title;
  final String message;
  final bool isVictory;

  const GameCompletionDialog({
    super.key,
    required this.onHome,
    required this.onPlayAgain,
    this.title = '',
    required this.message,
    this.isVictory = true,
  });

  @override
  ConsumerState<GameCompletionDialog> createState() =>
      _GameCompletionDialogState();
}

class _GameCompletionDialogState extends ConsumerState<GameCompletionDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isVictory) {
        HapticFeedbackUtil.victory();
      } else {
        HapticFeedbackUtil.vibrate();
      }
    });
  }

  /// The feed's win state: one card, one action. Solve, tap, next puzzle.
  Widget _feedSheet(
      BuildContext context, AppLocalizations l10n, FeedSession feed) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = DesignSystem.accent(context);
    final Color muted = DesignSystem.muted(context);

    void deal() {
      Navigator.of(context, rootNavigator: true).pop();
      feed.next();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: DeckCard(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isVictory
                        ? Icons.check_rounded
                        : Icons.remove_rounded,
                    size: 18,
                    color: widget.isVictory
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? DesignSystem.solvedDark
                            : DesignSystem.solved)
                        : muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Bebas Neue',
                      fontSize: DesignSystem.fontSize2XL,
                      letterSpacing: 1.2,
                      height: 1,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: DesignSystem.fontSizeSM,
                  height: 1.45,
                  color: muted,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _roundAction(
                    context,
                    icon: Icons.refresh_rounded,
                    tooltip: l10n.playAgain,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      widget.onPlayAgain();
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: l10n.nextPuzzle,
                      child: GestureDetector(
                        onTap: deal,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius:
                                BorderRadius.circular(DesignSystem.radiusFull),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.nextPuzzle.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Bebas Neue',
                                  fontSize: DesignSystem.fontSizeLG,
                                  letterSpacing: 1.2,
                                  height: 1,
                                  color: DesignSystem.onAccent(context),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_downward_rounded,
                                  size: 18,
                                  color: DesignSystem.onAccent(context)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundAction(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DesignSystem.hairline(context)),
            ),
            child: Icon(icon, size: 20, color: DesignSystem.muted(context)),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  /// "Faster than 62% of your solves", when there is enough history to say it.
  ///
  /// It is deliberately this player's own record. A percentile invented from a
  /// population we cannot see would be a nice number and a lie.
  String? _paceLine() {
    final gameId = GameClock.lastGameId;
    if (gameId == null) return null;
    final stat = ref.read(gameStatsProvider)[gameId];
    if (stat == null) return null;
    final percentile = stat.fasterThan;
    if (percentile == null) return null;
    return 'FASTER THAN $percentile% OF YOUR SOLVES (${stat.solves} TIMED)';
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    // Inside the feed the puzzle is a card, not a page: solving it should deal
    // the next card, not offer a tour of the app.
    final FeedSession? feed = FeedSession.current;
    if (feed != null) return _feedSheet(context, l10n, feed);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final session = ref.read(gameSessionNotifierProvider);
    final localizedTitles = {
      for (final game in allGamesMetadata)
        game.id: L10nGameHelpers.getGameTitle(context, game.id),
    };
    final gameList = ref.read(filteredGamesProvider(
      searchQuery: session.searchQuery,
      selectedCategory: session.selectedCategory,
      localizedTitles: localizedTitles,
    ));
    final streaks = ref.read(gameStreakNotifierProvider);

    GameMetadata? nextGame;
    bool isSameGame = true;

    if (gameList.isNotEmpty) {
      final currentIndex = session.lastGameId != null
          ? gameList.indexWhere((g) => g.id == session.lastGameId)
          : -1;

      // 1. Search forward from currentIndex + 1 for an unsolved game (not solved today)
      int searchStart =
          currentIndex != -1 ? (currentIndex + 1) % gameList.length : 0;
      for (int i = 0; i < gameList.length; i++) {
        final idx = (searchStart + i) % gameList.length;
        if (idx == currentIndex) continue;
        final candidate = gameList[idx];
        final isSolvedToday = streaks[candidate.id]?.solvedToday ?? false;
        if (!isSolvedToday) {
          nextGame = candidate;
          break;
        }
      }

      // 2. If all games are solved today, simply pick the next game in order
      if (nextGame == null) {
        if (currentIndex != -1) {
          final nextIndex = (currentIndex + 1) % gameList.length;
          nextGame = gameList[nextIndex];
        } else {
          nextGame = gameList.first;
        }
      }

      isSameGame = nextGame.id == session.lastGameId;
    }

    final next = nextGame;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: TangibleContainer(
          radius: DesignSystem.radiusLG,
          padding: const EdgeInsets.all(DesignSystem.spaceLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _launchUrl(
                          'https://play.google.com/store/apps/details?id=com.medhub.puzzlestack'),
                      borderRadius:
                          BorderRadius.circular(DesignSystem.radiusXS),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: DesignSystem.accentAmber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.leaveReview.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 12,
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    InkWell(
                      onTap: () => _launchUrl(
                          'https://github.com/cYoren/Puzzlestack/issues'),
                      borderRadius:
                          BorderRadius.circular(DesignSystem.radiusXS),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bug_report_rounded,
                              size: 14,
                              color: DesignSystem.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.reportError.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignSystem.spaceMD),
              Text(
                widget.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 32,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: DesignSystem.spaceSM),
              Text(
                widget.message.toUpperCase(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              if (_paceLine() case final pace?) ...[
                const SizedBox(height: DesignSystem.spaceSM),
                Text(
                  pace,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: DesignSystem.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
              const SizedBox(height: DesignSystem.spaceLG),
              if (next != null && !isSameGame)
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TangibleButton(
                        onTap: widget.onPlayAgain,
                        color: colorScheme.surface,
                        padding: const EdgeInsets.all(11),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignSystem.spaceSM),
                    Expanded(
                      flex: 3,
                      child: TangibleButton(
                        onTap: () {
                          ref
                              .read(gameSessionNotifierProvider.notifier)
                              .setSession(
                                gameId: next.id,
                                category: session.selectedCategory,
                                query: session.searchQuery,
                              );
                          final nav = Navigator.of(context);
                          nav.pop();
                          nav.pushReplacement(
                            CustomPageRoute(page: next.builder(nav.context)),
                          );
                        },
                        color: DesignSystem.primary,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: Center(
                          child: Text(
                            l10n.playNext.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: DesignSystem.fontSizeMD,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                TangibleButton(
                  onTap: widget.onPlayAgain,
                  color: DesignSystem.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Center(
                    child: Text(
                      l10n.playAgain.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: DesignSystem.fontSizeMD,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: DesignSystem.spaceMD),
              Row(
                children: [
                  Expanded(
                    child: TangibleButton(
                      onTap: widget.onHome,
                      color: colorScheme.surface,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      child: Center(
                        child: Text(
                          l10n.home.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700,
                            fontSize: DesignSystem.fontSizeSM,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignSystem.spaceSM),
                  Expanded(
                    child: TangibleButton(
                      onTap: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          PageRouteBuilder(
                            opaque: false,
                            barrierColor: Colors.black.withValues(alpha: 0.05),
                            transitionDuration:
                                const Duration(milliseconds: 200),
                            pageBuilder: (reviewCtx, _, __) {
                              return Consumer(
                                builder: (reviewCtx, ref, _) {
                                  final reviewTheme = Theme.of(reviewCtx);
                                  final reviewColorScheme =
                                      reviewTheme.colorScheme;
                                  final reviewL10n =
                                      AppLocalizations.of(reviewCtx) ?? l10n;

                                  return Material(
                                    color: Colors.transparent,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: SafeArea(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: DesignSystem.spaceLG,
                                                right: DesignSystem.spaceLG,
                                                bottom: DesignSystem.spaceXL,
                                              ),
                                              child: Center(
                                                child: Container(
                                                  width: double.infinity,
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 380),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: TangibleButton(
                                                          onTap: () {
                                                            final nav =
                                                                Navigator.of(
                                                                    reviewCtx);
                                                            nav.popUntil(
                                                                (route) => route
                                                                    .isFirst);
                                                          },
                                                          color:
                                                              reviewColorScheme
                                                                  .surface,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 14,
                                                                  horizontal:
                                                                      16),
                                                          child: Center(
                                                            child: Text(
                                                              reviewL10n.home
                                                                  .toUpperCase(),
                                                              style: reviewTheme
                                                                  .textTheme
                                                                  .labelMedium
                                                                  ?.copyWith(
                                                                color: reviewColorScheme
                                                                    .onSurface
                                                                    .withValues(
                                                                        alpha:
                                                                            0.7),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize:
                                                                    DesignSystem
                                                                        .fontSizeMD,
                                                                letterSpacing:
                                                                    0.5,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: DesignSystem
                                                              .spaceMD),
                                                      Expanded(
                                                        child: TangibleButton(
                                                          onTap: () {
                                                            final nav =
                                                                Navigator.of(
                                                                    reviewCtx);
                                                            if (next != null) {
                                                              ref
                                                                  .read(gameSessionNotifierProvider
                                                                      .notifier)
                                                                  .setSession(
                                                                    gameId:
                                                                        next.id,
                                                                    category:
                                                                        session
                                                                            .selectedCategory,
                                                                    query: session
                                                                        .searchQuery,
                                                                  );
                                                              nav.pushAndRemoveUntil(
                                                                CustomPageRoute(
                                                                    page: next
                                                                        .builder(
                                                                            nav.context)),
                                                                (route) => route
                                                                    .isFirst,
                                                              );
                                                            } else {
                                                              nav.popUntil(
                                                                  (route) => route
                                                                      .isFirst);
                                                            }
                                                          },
                                                          color: DesignSystem
                                                              .primary,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 14,
                                                                  horizontal:
                                                                      16),
                                                          child: Center(
                                                            child: Text(
                                                              (next != null &&
                                                                          !isSameGame
                                                                      ? reviewL10n
                                                                          .playNext
                                                                      : reviewL10n
                                                                          .playAgain)
                                                                  .toUpperCase(),
                                                              style:
                                                                  const TextStyle(
                                                                fontFamily:
                                                                    'Geist',
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize:
                                                                    DesignSystem
                                                                        .fontSizeMD,
                                                                letterSpacing:
                                                                    0.5,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                      color: colorScheme.surface,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.seeCompleted.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w700,
                              fontSize: DesignSystem.fontSizeSM,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
