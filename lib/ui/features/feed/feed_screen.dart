import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_categories.dart';
import '../../../data/game_guides.dart';
import '../../../data/game_metadata.dart';
import '../../../data/game_registry.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/user_providers.dart';
import '../../../utils/design_system.dart';
import '../../../utils/haptic_feedback.dart';
import '../../../widgets/deck.dart';
import '../../../widgets/game_guide_screen.dart';
import 'feed_deck.dart';
import 'feed_session.dart';

/// The deal: Puzzlestack's front door.
///
/// One puzzle per screen, all of it playable right there, and a swipe up deals
/// the next card. There are no menus between puzzles, no "start" button and no
/// list to scroll: the app opens on something to solve, which is the only
/// argument a puzzle app really has.
///
/// It is a tab (so the bottom bar stays) or a pushed route (from a category).
/// The deck deals a real shuffled pass over every puzzle, so nothing repeats
/// until the bag is empty and the counter on the card is true.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({
    super.key,
    this.startGameId,
    this.categoryId,
    this.isRoute = false,
  });

  /// Open on a specific game instead of the first card of the deal.
  final String? startGameId;

  /// Deal only from one category.
  final String? categoryId;

  /// True when pushed as its own page: adds a close button and puts the deck at
  /// the top of the screen.
  final bool isRoute;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  static const Duration _deal = Duration(milliseconds: 380);

  final PageController _controller = PageController();
  late final FeedDeck _deck;
  late final FeedSession _session;

  int _index = 0;
  bool _locked = false;

  /// Bumped per card to force a fresh build (and therefore a fresh board) when
  /// the player asks for a restart.
  final Map<int, int> _restartEpochs = {};

  @override
  void initState() {
    super.initState();
    final hidden = ref.read(userDataNotifierProvider
        .select((d) => (d.hiddenGameIds ?? const []).toSet()));
    _deck = FeedDeck(categoryId: widget.categoryId, hidden: hidden);

    _session = FeedSession(
      next: _next,
      restart: () => _restart(_index),
      close: _close,
      isRoute: widget.isRoute,
    );
    FeedSession.activate(_session);
  }

  @override
  void dispose() {
    FeedSession.deactivate(_session);
    _controller.dispose();
    super.dispose();
  }

  GameMetadata _gameAt(int index) {
    if (index == 0 && widget.startGameId != null) {
      final GameMetadata? pinned = GameFeed.find(widget.startGameId!);
      if (pinned != null) return pinned;
    }
    return _deck.gameAt(index);
  }

  void _next() {
    if (!mounted || !_controller.hasClients) return;
    HapticFeedbackUtil.lightImpact();
    _controller.nextPage(duration: _deal, curve: Curves.easeOutCubic);
  }

  void _restart(int index) {
    if (!mounted) return;
    HapticFeedbackUtil.mediumImpact();
    setState(() => _restartEpochs[index] = (_restartEpochs[index] ?? 0) + 1);
  }

  void _close() {
    if (widget.isRoute) Navigator.of(context).maybePop();
  }

  void _onPageChanged(int index) {
    HapticFeedbackUtil.selectionClick();
    setState(() => _index = index);
  }

  void _toggleLock() {
    HapticFeedbackUtil.lightImpact();
    setState(() => _locked = !_locked);
    if (_locked) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 88),
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            duration: const Duration(milliseconds: 1600),
            content: Text(
              AppLocalizations.of(context)?.feedScrollLocked ??
                  'Scroll locked for this puzzle',
              style: TextStyle(
                color: Theme.of(context).colorScheme.surface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
    }
  }

  void _openGuide(BuildContext context, GameMetadata game) {
    if (!gameGuides.containsKey(game.id)) return;
    HapticFeedbackUtil.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameGuideScreen(
          gameId: game.id,
          gameColor: DesignSystem.accent(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bed = DesignSystem.paperOf(context);

    return Scaffold(
      backgroundColor: bed,
      body: Stack(
        children: [
          ScrollConfiguration(
            // Flutter's default web behaviour refuses to drag with a mouse, so
            // the feed would only page by wheel on desktop. A deck should deal
            // the same way with a trackpad, a mouse and a thumb.
            behavior: const _FeedScrollBehavior(),
            child: PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical,
              physics: _locked
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final GameMetadata game = _gameAt(index);
                final int epoch = _restartEpochs[index] ?? 0;
                return _FeedCard(
                  key: ValueKey('card_${index}_${game.id}_$epoch'),
                  game: game,
                  index: index,
                  deck: _deck,
                  locked: _locked,
                  isFirst: index == 0,
                  showClose: widget.isRoute,
                  onClose: _close,
                  onNext: _next,
                  onRestart: () => _restart(index),
                  onToggleLock: _toggleLock,
                  onGuide: () => _openGuide(context, game),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Drag with anything: on a phone that is a thumb, on a laptop it is a mouse.
class _FeedScrollBehavior extends MaterialScrollBehavior {
  const _FeedScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    super.key,
    required this.game,
    required this.index,
    required this.deck,
    required this.locked,
    required this.isFirst,
    required this.showClose,
    required this.onClose,
    required this.onNext,
    required this.onRestart,
    required this.onToggleLock,
    required this.onGuide,
  });

  final GameMetadata game;
  final int index;
  final FeedDeck deck;
  final bool locked;
  final bool isFirst;
  final bool showClose;
  final VoidCallback onClose;
  final VoidCallback onNext;
  final VoidCallback onRestart;
  final VoidCallback onToggleLock;
  final VoidCallback onGuide;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color muted = DesignSystem.muted(context);
    final Color accent = DesignSystem.accent(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spaceMD,
        0,
        DesignSystem.spaceMD,
        22,
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 48,
              child: _TopBar(showClose: showClose, onClose: onClose),
            ),
          ),
          Expanded(
            child: DeckCard(
              clip: true,
              padding: EdgeInsets.zero,
              lift: isDark ? 0 : 1,
              // Two empty cards under the live one: the stack is the promise
              // that a swipe has somewhere to go.
              pile: 2,
              child: Column(
                children: [
                  _cardHeader(context, muted, accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignSystem.spaceSM,
                      ),
                      child: game.builder(context),
                    ),
                  ),
                  _cardFooter(context, colors, muted, accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardHeader(BuildContext context, Color muted, Color accent) {
    final CategoryInfo cat = GameCategories.info(game.category);
    final int position = deck.positionInDeck(index);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesignSystem.hairline(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            cat.label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: DesignSystem.fontSizeSM + 2,
              letterSpacing: 1.6,
              height: 1,
              color: muted,
            ),
          ),
          const Spacer(),
          Text(
            position.toString().padLeft(3, '0'),
            style: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: DesignSystem.fontSizeSM + 2,
              letterSpacing: 1.2,
              height: 1,
              color: DesignSystem.muted(context),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            ' / ${deck.deckSize}',
            style: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: DesignSystem.fontSizeSM + 2,
              letterSpacing: 1.2,
              height: 1,
              color: muted.withValues(alpha: 0.55),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardFooter(
      BuildContext context, ColorScheme colors, Color muted, Color accent) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: DesignSystem.hairline(context), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              game.titleGetter(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: DesignSystem.fontSize3XL,
                height: 0.95,
                letterSpacing: 0.4,
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              game.subtitleGetter(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: DesignSystem.fontSizeXS,
                height: 1.3,
                color: muted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _quietButton(
                context,
                icon: Icons.refresh_rounded,
                tooltip: l10n?.restartPuzzle ?? 'Restart',
                onTap: onRestart,
              ),
              const SizedBox(width: 2),
              _quietButton(
                context,
                icon: Icons.help_outline_rounded,
                tooltip: l10n?.howToPlay ?? 'How to Play',
                onTap: onGuide,
              ),
              const Spacer(),
              _quietButton(
                context,
                icon: locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                tooltip: locked
                    ? (l10n?.unlockScroll ?? 'Unlock scrolling')
                    : (l10n?.lockScroll ?? 'Lock scrolling'),
                onTap: onToggleLock,
                tinted: true,
              ),
              const SizedBox(width: 6),
              _nextButton(context, accent, l10n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quietButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool tinted = false,
  }) {
    final Color muted = DesignSystem.muted(context);
    final Color accent = DesignSystem.accent(context);
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: tinted ? accent : muted),
        ),
      ),
    );
  }

  Widget _nextButton(
      BuildContext context, Color accent, AppLocalizations? l10n) {
    return Semantics(
      button: true,
      label: l10n?.nextPuzzle ?? 'Next puzzle',
      child: GestureDetector(
        onTap: onNext,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 16, right: 10),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (l10n?.next ?? 'Next').toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: DesignSystem.fontSizeLG,
                  letterSpacing: 1.2,
                  height: 1,
                  color: DesignSystem.onAccent(context),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: DesignSystem.onAccent(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showClose, required this.onClose});

  final bool showClose;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: DeckMark(size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          'PUZZLESTACK',
          style: TextStyle(
            fontFamily: 'Bebas Neue',
            fontSize: DesignSystem.fontSizeLG,
            letterSpacing: 1.4,
            height: 1,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        if (showClose)
          IconButton(
            onPressed: onClose,
            iconSize: 20,
            color: DesignSystem.muted(context),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }
}

/// Every game the registry knows, for the home screen's counter.
int deckTotal() => allGamesMetadata.length;
