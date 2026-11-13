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
    this.onBrowse,
  });

  /// Open on a specific game instead of the first card of the deal.
  final String? startGameId;

  /// Deal only from one category.
  final String? categoryId;

  /// True when pushed as its own page: adds a close button and puts the deck at
  /// the top of the screen.
  final bool isRoute;

  /// Present when the feed is a tab. On short phones the bottom bar is dropped
  /// so the board gets the height, and this is the way back to the stack.
  final VoidCallback? onBrowse;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with TickerProviderStateMixin {
  late final FeedDeck _deck;
  late final FeedSession _session;
  late final AnimationController _settle;

  /// How far the arriving card has turned face up. The next card waits in the
  /// deck showing its back; when it lands, the back fades and the puzzle is
  /// already there underneath.
  late final AnimationController _reveal;

  int _index = 0;

  /// How far the live card has been pulled off the deck, in pixels. Positive is
  /// up (deal the next card), negative is down (put this one back).
  double _drag = 0;

  /// Height of one card slot, measured on layout. Every threshold below is a
  /// fraction of it, so a small phone and a tablet deal the same way.
  double _slot = 1;

  /// How much of the next card is showing. Kept outside the drag value so the
  /// deck can settle without the gesture changing.
  bool _locked = false;
  final Map<int, int> _restartEpochs = {};

  @override
  void initState() {
    super.initState();
    final hidden = ref.read(userDataNotifierProvider
        .select((d) => (d.hiddenGameIds ?? const []).toSet()));
    _deck = FeedDeck(categoryId: widget.categoryId, hidden: hidden);

    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );

    // The controller works in card heights, not pixels: an AnimationController
    // is bounded to -1.2..1.2 so a settle never overruns the deck.
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      lowerBound: -1.2,
      upperBound: 1.2,
    )
      ..addListener(() => setState(() => _drag = _settle.value * _slot))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _commit();
      });

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
    _reveal.dispose();
    _settle.dispose();
    super.dispose();
  }

  GameMetadata _gameAt(int index) {
    if (index == 0 && widget.startGameId != null) {
      final GameMetadata? pinned = GameFeed.find(widget.startGameId!);
      if (pinned != null) return pinned;
    }
    return _deck.gameAt(index);
  }

  // --- The deal ------------------------------------------------------------

  void _next() {
    if (_settle.isAnimating) return;
    _animateTo(_slot);
  }

  /// Animate the live card to [target] pixels off the deck, then commit it.
  void _animateTo(double target) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      setState(() => _drag = target);
      _commit();
      return;
    }
    final double from = _drag;
    _settle
      ..stop()
      ..value = from / _slot;
    _settle.animateTo(
      target / _slot,
      duration: Duration(
        milliseconds: (200 + 160 * (target - from).abs() / _slot).round(),
      ),
      curve: Curves.easeOutCubic,
    );
    HapticFeedbackUtil.lightImpact();
  }

  /// The drag ended: deal, go back, or settle. Distance or a throw decides.
  void _release({required double velocity}) {
    final bool deal = velocity < -650 || _drag > _slot * 0.16;
    final bool back = velocity > 650 || _drag < -_slot * 0.16;

    if (deal) {
      _animateTo(_slot);
    } else if (back && _index > 0) {
      _animateTo(-_slot);
    } else {
      _animateTo(0);
    }
  }

  /// The card landed: adopt the new index and let the deck fall back to rest.
  void _commit() {
    final bool forward = _drag >= _slot * 0.5;
    final bool backward = _drag <= -_slot * 0.5 && _index > 0;

    if (forward) {
      HapticFeedbackUtil.selectionClick();
      setState(() {
        _index += 1;
        _drag = 0;
      });
      _settle.value = 0;
      _reveal.forward(from: 0);
    } else if (backward) {
      HapticFeedbackUtil.selectionClick();
      setState(() {
        _index -= 1;
        _drag = 0;
      });
      _settle.value = 0;
      _reveal.forward(from: 0);
    } else {
      setState(() => _drag = 0);
      _settle.value = 0;
    }
  }

  void _restart(int index) {
    if (!mounted) return;
    HapticFeedbackUtil.mediumImpact();
    setState(() => _restartEpochs[index] = (_restartEpochs[index] ?? 0) + 1);
  }

  void _close() {
    if (widget.isRoute) Navigator.of(context).maybePop();
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

  // --- The stack -----------------------------------------------------------

  /// One card of the deck.
  ///
  /// [depth] is where it sits in the stack: 0 is the live slot, 1 and 2 are the
  /// cards behind it. [advance] (0..1) is how far it has moved one place
  /// forward, which is what makes the whole stack step up when the live card is
  /// pulled: the next card slides into the live slot and grows as it does.
  Widget _card(
    BuildContext context, {
    required int index,
    required int depth,
    required double advance,
    bool live = false,
    bool fromAbove = false,
  }) {
    if (index < 0) return const SizedBox.shrink();

    final double a = advance.clamp(0.0, 1.0);
    final double effDepth = live ? 0.0 : (depth - a).clamp(0.0, 2.0);
    // The cards behind are inset and dropped, not scaled: a stack peeks out at
    // the sides and below the front card, the way a deck does on a table.
    final double inset = live ? 0.0 : 9.0 * effDepth;
    final double drop = live ? -_drag : (fromAbove ? -13.0 : 13.0) * effDepth;
    final double rotation = live ? -0.014 * a : 0.010 * a;
    final double scale = live ? 1 - 0.02 * a : 1.0;
    final double wash = live ? 0.45 * a : 0.16 * (1 - a);

    // The next card stays face down until the player is committed to it:
    // building a puzzle behind the live card would start its timer, and showing
    // its footer through the gap reads as two screens fighting.
    final bool faceUp = live || a > 0.35;

    final GameMetadata game = _gameAt(index);
    final Widget content = faceUp
        ? _FeedCard(
            key: ValueKey(
                'card_${index}_${game.id}_${_restartEpochs[index] ?? 0}'),
            game: game,
            index: index,
            deck: _deck,
            locked: _locked,
            onNext: _next,
            onRestart: () => _restart(index),
            onToggleLock: _toggleLock,
            onGuide: () => _openGuide(context, game),
          )
        : DeckCard(
            key: ValueKey('back_$index'),
            padding: EdgeInsets.zero,
            child: const SizedBox.expand(),
          );

    return Positioned.fill(
      // Keyed by slot, not by position: when the deck steps up, the card that
      // was behind has to keep its game state as it becomes the live one.
      key: ValueKey('slot_$index'),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: inset),
        child: IgnorePointer(
          ignoring: !live,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..translateByDouble(0.0, drop, 0.0, 1.0)
              ..rotateZ(rotation)
              ..scaleByDouble(scale, scale, 1.0, 1.0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: live && !_locked
                  ? (details) {
                      _settle.stop();
                      setState(() {
                        _drag = (_drag - details.delta.dy)
                            .clamp(-_slot * 1.2, _slot * 1.2);
                      });
                    }
                  : null,
              onVerticalDragEnd: live && !_locked
                  ? (details) =>
                      _release(velocity: details.primaryVelocity ?? 0)
                  : null,
              child: Stack(
                children: [
                  Positioned.fill(child: content),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _CardBack(
                        wash: wash,
                        reveal: live ? _reveal : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bed = DesignSystem.paperOf(context);

    return Scaffold(
      backgroundColor: bed,
      body: LayoutBuilder(
        builder: (context, constraints) {
          _slot = (constraints.maxHeight -
                  MediaQuery.paddingOf(context).top -
                  kToolbarHeight -
                  22)
              .clamp(1.0, 10000.0);
          final double progress = (_drag / _slot).clamp(-1.0, 1.0);
          final bool forward = progress >= 0;

          return Listener(
            onPointerSignal: (event) {
              if (_locked || _settle.isAnimating) return;
              if (event is! PointerScrollEvent) return;
              if (event.scrollDelta.dy > 0) {
                _animateTo(_slot);
              } else if (event.scrollDelta.dy < 0 && _index > 0) {
                _animateTo(-_slot);
              }
            },
            child: Stack(
              children: [
                // Painted back to front: the stack, then the live card on top.
                if (forward) ...[
                  _card(context,
                      index: _index + 2, depth: 2, advance: progress),
                  _card(context,
                      index: _index + 1, depth: 1, advance: progress),
                ] else
                  _card(context,
                      index: _index - 1,
                      depth: 1,
                      advance: -progress,
                      fromAbove: true),
                _card(context,
                    index: _index, depth: 0, advance: progress, live: true),
                // The wordmark belongs to the deck, not to each card: it stays
                // put while the cards are dealt underneath it.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ColoredBox(
                    color: bed,
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: SizedBox(
                            height: kToolbarHeight,
                            child: _TopBar(
                              showClose: widget.isRoute,
                              onClose: _close,
                              onBrowse: widget.onBrowse,
                            ),
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
      ),
    );
  }
}

/// The back of a card in the deck: paper, a hairline, and the mark.
///
/// It covers the puzzle underneath until the card has landed, which is what
/// keeps a half-dealt card from showing its footer through the gap. [wash]
/// pushes background cards away from the eye; [reveal] fades the back off as
/// the card takes the live slot.
class _CardBack extends StatelessWidget {
  const _CardBack({required this.wash, this.reveal});

  final double wash;
  final Animation<double>? reveal;

  @override
  Widget build(BuildContext context) {
    // The same box as a face card, so a card turning over never changes size.
    final Widget back = Padding(
      padding: EdgeInsets.fromLTRB(
        DesignSystem.spaceMD,
        MediaQuery.paddingOf(context).top + kToolbarHeight,
        DesignSystem.spaceMD,
        22,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DeckCard(
            padding: EdgeInsets.zero,
            // The mark sits low on the back, where the peel uncovers it first.
            child: Align(
              alignment: const Alignment(0, 0.42),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(opacity: 0.22, child: DeckMark(size: 52)),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: 0.16,
                    child: Text(
                      'PUZZLESTACK',
                      style: TextStyle(
                        fontFamily: 'Bebas Neue',
                        fontSize: DesignSystem.fontSizeSM,
                        letterSpacing: 3,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final Widget washed = Stack(
      children: [
        Positioned.fill(child: back),
        if (wash > 0)
          Positioned.fill(
            child: ColoredBox(
              color: DesignSystem.paperOf(context).withValues(alpha: wash),
            ),
          ),
      ],
    );

    final Animation<double>? fade = reveal;
    if (fade == null) return washed;
    return AnimatedBuilder(
      animation: fade,
      child: washed,
      builder: (context, child) {
        final double visibility = 1 - fade.value;
        if (visibility <= 0.01) return const SizedBox.shrink();
        return Opacity(opacity: visibility, child: child);
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    super.key,
    required this.game,
    required this.index,
    required this.deck,
    required this.locked,
    required this.onNext,
    required this.onRestart,
    required this.onToggleLock,
    required this.onGuide,
  });

  final GameMetadata game;
  final int index;
  final FeedDeck deck;
  final bool locked;
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
      // The fixed wordmark bar above owns this space; the card starts under it.
      padding: EdgeInsets.fromLTRB(
        DesignSystem.spaceMD,
        MediaQuery.paddingOf(context).top + kToolbarHeight,
        DesignSystem.spaceMD,
        22,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Expanded(
                child: DeckCard(
                  clip: true,
                  padding: EdgeInsets.zero,
                  lift: isDark ? 0 : 1,
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
        ),
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
    // On a short phone the board needs the height more than the subtitle does.
    final bool compact = MediaQuery.sizeOf(context).height < 760;
    return Container(
      padding: EdgeInsets.fromLTRB(18, compact ? 10 : 14, 12, compact ? 8 : 12),
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
                fontSize: compact
                    ? DesignSystem.fontSize2XL
                    : DesignSystem.fontSize3XL,
                height: 0.95,
                letterSpacing: 0.4,
                color: colors.onSurface,
              ),
            ),
          ),
          if (!compact) ...[
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
          ],
          SizedBox(height: compact ? 4 : 10),
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
  const _TopBar({
    required this.showClose,
    required this.onClose,
    required this.onBrowse,
  });

  final bool showClose;
  final VoidCallback onClose;
  final VoidCallback? onBrowse;

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
        if (onBrowse != null)
          IconButton(
            onPressed: onBrowse,
            iconSize: 20,
            color: DesignSystem.muted(context),
            tooltip: AppLocalizations.of(context)?.navStack ?? 'Stack',
            icon: const Icon(Icons.grid_view_rounded),
          ),
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
