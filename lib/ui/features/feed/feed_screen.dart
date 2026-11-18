import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_categories.dart';
import '../../../data/game_guides.dart';
import '../../../data/game_metadata.dart';
import '../../../data/game_profiles.dart';
import '../../../data/game_registry.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/daily_five_providers.dart';
import '../../../providers/game_stats_provider.dart';
import '../../../providers/pick_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../utils/design_system.dart';
import '../../../utils/haptic_feedback.dart';
import '../../../widgets/deck.dart';
import '../../../widgets/game_guide_screen.dart';
import '../../core/assist/game_assist.dart';
import '../../core/assist/hint_request.dart';
import '../../core/juice/game_scope.dart';
import '../daily/daily_five_screen.dart';
import 'deal_order.dart';
import 'feed_deck.dart';
import 'feed_session.dart';

/// The deal: Puzzlestack's front door.
///
/// One puzzle per screen, all of it playable right there, and a swipe up deals
/// the next card.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({
    super.key,
    this.startGameId,
    this.categoryId,
    this.isRoute = false,
    this.isActive = true,
    this.onBrowse,
  });

  /// Open on a specific game instead of the first card of the deal.
  final String? startGameId;

  /// Deal only from one category.
  final String? categoryId;

  /// True when pushed as its own page: adds a close button and puts the deck at
  /// the top of the screen.
  final bool isRoute;

  /// False when this feed tab is parked behind another tab in `IndexedStack`.
  final bool isActive;

  /// Present when the feed is a tab on short phones.
  final VoidCallback? onBrowse;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with TickerProviderStateMixin {
  FeedDeck? _deckInstance;
  FeedDeck get _deck => _deckInstance!;
  late final FeedSession _session;
  late final AnimationController _settle;
  late final AnimationController _reveal;

  int _index = 0;
  double _drag = 0;

  static const double _slop = 22;
  static const double _chromeSlop = 8;

  double _travelled = 0;
  bool _armed = false;
  bool _chromeGesture = false;
  double _slot = 1;

  final Map<int, int> _restartEpochs = <int, int>{};
  final Map<String, int> _quickSkips = <String, int>{};
  final Set<String> _seenThisSession = <String>{};
  int _cardsSeenCount = 0;
  DateTime _cardShownAt = DateTime.now();
  bool _currentCardSolved = false;
  String _localeCode = 'en';

  @override
  void initState() {
    super.initState();

    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );

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
      seedFor: (String gameId) => _deck.seedAt(_index, gameId),
      onSolved: (_) => _currentCardSolved = true,
    );
    if (widget.isActive) {
      FeedSession.activate(_session);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String resolvedLocale =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    if (_deckInstance == null) {
      _localeCode = resolvedLocale;
      final DealHistory initialHistory = _buildHistory(localeCode: _localeCode);
      _deckInstance = FeedDeck(
        categoryId: widget.categoryId,
        hidden: initialHistory.blocked,
        history: initialHistory,
        includeFirstTen:
            widget.startGameId == null && widget.categoryId == null,
        seedStore: SeedHistoryStore(ref.read(pickStoreProvider)),
      );
      _seenThisSession.add(_gameAt(0).id);
      return;
    }
    if (resolvedLocale != _localeCode) {
      _localeCode = resolvedLocale;
      _deck.updateHistory(
        _buildHistory(localeCode: _localeCode),
        keepThroughIndex: _index - 1,
      );
    }
  }

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        FeedSession.activate(_session);
      } else {
        FeedSession.deactivate(_session);
      }
    }
  }

  @override
  void dispose() {
    FeedSession.deactivate(_session);
    _reveal.dispose();
    _settle.dispose();
    super.dispose();
  }

  DealHistory _buildHistory({String? localeCode}) {
    final userData = ref.read(userDataNotifierProvider);
    final stats = ref.read(gameStatsProvider);
    final Set<String> solvedIds = <String>{
      for (final entry in stats.entries)
        if (entry.value.solves > 0) entry.key,
    };
    return DealHistory(
      blocked: (userData.hiddenGameIds ?? const <String>[]).toSet(),
      liked: (userData.favoriteGameIds ?? const <String>[]).toSet(),
      solved: solvedIds,
      quickSkips: Map<String, int>.unmodifiable(_quickSkips),
      seen: <String>{...solvedIds, ..._seenThisSession},
      cardsSeen: (userData.totalSolved ?? 0) + _cardsSeenCount,
      localeCode: localeCode ?? _localeCode,
    );
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

  void _release({
    required double velocity,
    double travelled = 0,
    bool fromChrome = false,
  }) {
    final double requiredSlop = fromChrome ? _chromeSlop : _slop;
    if (travelled.abs() < requiredSlop) {
      _animateTo(0);
      return;
    }
    final double ratio = fromChrome ? 0.14 : 0.30;
    final double fling = fromChrome ? 450 : 900;
    final bool deal = velocity < -fling || _drag > _slot * ratio;
    final bool back = velocity > fling || _drag < -_slot * ratio;

    if (deal) {
      _animateTo(_slot);
    } else if (back && _index > 0) {
      _animateTo(-_slot);
    } else {
      _animateTo(0);
    }
  }

  void _commit() {
    final bool forward = _drag >= _slot * 0.5;
    final bool backward = _drag <= -_slot * 0.5 && _index > 0;

    if (forward) {
      final GameMetadata leaving = _gameAt(_index);
      if (!_currentCardSolved &&
          DateTime.now().difference(_cardShownAt).inSeconds < 5) {
        _quickSkips[leaving.id] = (_quickSkips[leaving.id] ?? 0) + 1;
      }
      _cardsSeenCount += 1;
      HapticFeedbackUtil.selectionClick();
      setState(() {
        _index += 1;
        _drag = 0;
        _cardShownAt = DateTime.now();
        _currentCardSolved = false;
      });
      _seenThisSession.add(_gameAt(_index).id);
      _deck.updateHistory(_buildHistory());
      _settle.value = 0;
      _reveal.forward(from: 0);
    } else if (backward) {
      HapticFeedbackUtil.selectionClick();
      setState(() {
        _index -= 1;
        _drag = 0;
        _cardShownAt = DateTime.now();
        _currentCardSolved = false;
      });
      _settle.value = 0;
      _reveal.forward(from: 0);
    } else {
      setState(() => _drag = 0);
      _settle.value = 0;
    }
  }

  void _onChromeDragUpdate(DragUpdateDetails details) {
    _settle.stop();
    _chromeGesture = true;
    _travelled += details.delta.dy;
    if (!_armed) {
      if (_travelled.abs() < _chromeSlop) return;
      _armed = true;
      setState(() {
        _drag = (-_travelled).clamp(-_slot * 1.2, _slot * 1.2);
      });
      return;
    }
    setState(() {
      _drag = (_drag - details.delta.dy).clamp(-_slot * 1.2, _slot * 1.2);
    });
  }

  void _onChromeDragEnd(DragEndDetails details) {
    final double travelled = _travelled;
    _travelled = 0;
    _armed = false;
    _chromeGesture = false;
    _release(
      velocity: details.primaryVelocity ?? 0,
      travelled: travelled,
      fromChrome: true,
    );
  }

  void _restart(int index) {
    if (!mounted) return;
    HapticFeedbackUtil.mediumImpact();
    setState(() => _restartEpochs[index] = (_restartEpochs[index] ?? 0) + 1);
  }

  bool _isLiked(GameMetadata game) => ref.watch(
        userDataNotifierProvider
            .select((d) => (d.favoriteGameIds ?? const []).contains(game.id)),
      );

  void _toggleLike(GameMetadata game) {
    HapticFeedbackUtil.lightImpact();
    ref.read(userDataNotifierProvider.notifier).toggleFavorite(game.id);
    _deck.updateHistory(_buildHistory());
  }

  void _block(GameMetadata game) {
    final l10n = AppLocalizations.of(context);
    HapticFeedbackUtil.mediumImpact();
    ref.read(userDataNotifierProvider.notifier).toggleHideGame(game.id);
    _deck.updateHistory(_buildHistory(), keepThroughIndex: _index);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 88),
          content: Text(l10n?.gameHidden ?? 'Hidden from the deal'),
          action: SnackBarAction(
            label: l10n?.undo ?? 'Undo',
            onPressed: () {
              ref
                  .read(userDataNotifierProvider.notifier)
                  .toggleHideGame(game.id);
              _deck.updateHistory(_buildHistory(), keepThroughIndex: _index);
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  void _close() {
    if (widget.isRoute) Navigator.of(context).maybePop();
  }

  void _openGuide(BuildContext context, GameMetadata game) {
    if (!gameGuides.containsKey(game.id)) return;
    HapticFeedbackUtil.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GameGuideScreen(
          gameId: game.id,
          gameColor: DesignSystem.accent(context),
        ),
      ),
    );
  }

  void _openDailyFive(BuildContext context) {
    HapticFeedbackUtil.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const DailyFiveScreen()),
    );
  }

  // --- The stack -----------------------------------------------------------

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
    final double inset = live ? 0.0 : 9.0 * effDepth;
    final double drop = live ? -_drag : (fromAbove ? -13.0 : 13.0) * effDepth;
    final double rotation = live ? -0.014 * a : 0.010 * a;
    final double scale = live ? 1 - 0.02 * a : 1.0;
    final double wash = live ? 0.45 * a : 0.16 * (1 - a);

    final bool faceUp = live || a > 0.35;
    final GameMetadata game = _gameAt(index);

    final Widget content = faceUp
        ? _FeedCard(
            key: ValueKey(
              'card_${index}_${game.id}_${_restartEpochs[index] ?? 0}',
            ),
            game: game,
            index: index,
            deck: _deck,
            live: live && widget.isActive,
            onNext: _next,
            onRestart: () => _restart(index),
            onGuide: () => _openGuide(context, game),
            liked: _isLiked(game),
            onLike: () => _toggleLike(game),
            onBlock: () => _block(game),
            onChromeDragUpdate: live ? _onChromeDragUpdate : null,
            onChromeDragEnd: live ? _onChromeDragEnd : null,
          )
        : DeckCard(
            key: ValueKey('back_$index'),
            padding: EdgeInsets.zero,
            child: const SizedBox.expand(),
          );

    return Positioned.fill(
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
              onVerticalDragUpdate: live
                  ? (details) {
                      if (_chromeGesture) return;
                      _settle.stop();
                      _travelled += details.delta.dy;
                      if (!_armed) {
                        if (_travelled.abs() < _slop) return;
                        _armed = true;
                        setState(() {
                          _drag =
                              (-_travelled).clamp(-_slot * 1.2, _slot * 1.2);
                        });
                        return;
                      }
                      setState(() {
                        _drag = (_drag - details.delta.dy)
                            .clamp(-_slot * 1.2, _slot * 1.2);
                      });
                    }
                  : null,
              onVerticalDragEnd: live
                  ? (details) {
                      if (_chromeGesture) return;
                      final double travelled = _travelled;
                      _travelled = 0;
                      _armed = false;
                      _release(
                        velocity: details.primaryVelocity ?? 0,
                        travelled: travelled,
                      );
                    }
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
    final int dailyStreak =
        ref.watch(dailyFiveProvider.select((s) => s.streak));
    final bool dailyDone =
        ref.watch(dailyFiveProvider.select((s) => s.today.isComplete));

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
              if (_settle.isAnimating) return;
              if (event is! PointerScrollEvent) return;
              if (event.scrollDelta.dy > 0) {
                _animateTo(_slot);
              } else if (event.scrollDelta.dy < 0 && _index > 0) {
                _animateTo(-_slot);
              }
            },
            child: Stack(
              children: [
                if (forward) ...[
                  _card(
                    context,
                    index: _index + 2,
                    depth: 2,
                    advance: progress,
                  ),
                  _card(
                    context,
                    index: _index + 1,
                    depth: 1,
                    advance: progress,
                  ),
                ] else
                  _card(
                    context,
                    index: _index - 1,
                    depth: 1,
                    advance: -progress,
                    fromAbove: true,
                  ),
                _card(
                  context,
                  index: _index,
                  depth: 0,
                  advance: progress,
                  live: true,
                ),
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
                              onDailyFive: () => _openDailyFive(context),
                              dailyStreak: dailyStreak,
                              dailyDone: dailyDone,
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

class _CardBack extends StatelessWidget {
  const _CardBack({required this.wash, this.reveal});

  final double wash;
  final Animation<double>? reveal;

  @override
  Widget build(BuildContext context) {
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
            child: Align(
              alignment: const Alignment(0, 0.42),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Opacity(opacity: 0.22, child: DeckMark(size: 52)),
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

class _FeedCard extends ConsumerStatefulWidget {
  const _FeedCard({
    super.key,
    required this.game,
    required this.index,
    required this.deck,
    required this.live,
    required this.onNext,
    required this.onRestart,
    required this.onGuide,
    required this.liked,
    required this.onLike,
    required this.onBlock,
    this.onChromeDragUpdate,
    this.onChromeDragEnd,
  });

  final GameMetadata game;
  final int index;
  final FeedDeck deck;
  final bool live;
  final VoidCallback onNext;
  final VoidCallback onRestart;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onBlock;
  final VoidCallback onGuide;
  final GestureDragUpdateCallback? onChromeDragUpdate;
  final GestureDragEndCallback? onChromeDragEnd;

  @override
  ConsumerState<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends ConsumerState<_FeedCard>
    with SingleTickerProviderStateMixin {
  Timer? _idleTimer;
  late final AnimationController _nudgeController;
  bool _nudgedOnce = false;
  bool _interacted = false;

  @override
  void initState() {
    super.initState();
    _nudgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _armIdleNudgeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.live && widget.live) {
      _armIdleNudgeIfNeeded();
    } else if (oldWidget.live && !widget.live) {
      _idleTimer?.cancel();
      _idleTimer = null;
    }
  }

  void _armIdleNudgeIfNeeded() {
    _idleTimer?.cancel();
    if (!widget.live || _nudgedOnce || _interacted) return;
    final int solves = ref.read(gameStatsProvider)[widget.game.id]?.solves ?? 0;
    if (solves > 0) return;
    _idleTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _interacted || _nudgedOnce) return;
      setState(() => _nudgedOnce = true);
      _nudgeController.forward(from: 0);
    });
  }

  void _onBoardPointerDown() {
    if (_interacted) return;
    _interacted = true;
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _nudgeController.dispose();
    super.dispose();
  }

  static String _goalText(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.length <= 60) return trimmed;
    return '${trimmed.substring(0, 59).trimRight()}\u2026';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color muted = DesignSystem.muted(context);
    final Color accent = DesignSystem.accent(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final GameAssistActions? assist = gameAssistFor(widget.game.id, ref);

    return Padding(
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
                      GestureDetector(
                        key: ValueKey<String>(
                          'feed_card_header_${widget.index}',
                        ),
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: widget.onChromeDragUpdate,
                        onVerticalDragEnd: widget.onChromeDragEnd,
                        child: _cardHeader(context, muted, accent),
                      ),
                      Expanded(
                        child: Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: (_) => _onBoardPointerDown(),
                          child: AnimatedBuilder(
                            animation: _nudgeController,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignSystem.spaceSM,
                              ),
                              child: GameScope(
                                gameId: widget.game.id,
                                child: widget.game.builder(context),
                              ),
                            ),
                            builder: (context, child) {
                              final double t = _nudgeController.value;
                              final double pulse = t <= 0 || t >= 1
                                  ? 0.0
                                  : (1.0 - (2 * t - 1).abs());
                              final bool active = pulse > 0.001;
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: active
                                          ? Border.all(
                                              color: accent.withValues(
                                                alpha: 0.55 * pulse,
                                              ),
                                              width: 2.5,
                                            )
                                          : null,
                                    ),
                                    child: Transform.scale(
                                      scale: 1.0 + 0.012 * pulse,
                                      child: child,
                                    ),
                                  ),
                                  if (active)
                                    const IgnorePointer(
                                      key: ValueKey<String>('feed_idle_nudge'),
                                      child: SizedBox.expand(),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      GestureDetector(
                        key: ValueKey<String>(
                          'feed_card_footer_${widget.index}',
                        ),
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: widget.onChromeDragUpdate,
                        onVerticalDragEnd: widget.onChromeDragEnd,
                        child: _cardFooter(
                          context,
                          colors,
                          muted,
                          accent,
                          assist?.onHint,
                        ),
                      ),
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
    final CategoryInfo cat = GameCategories.info(widget.game.category);
    final CardKind kind = cardKindOf(widget.game.id);
    final int position = widget.deck.positionInDeck(widget.index);
    final String goal = _goalText(widget.game.subtitleGetter(context));
    final bool compact = MediaQuery.sizeOf(context).height < 700;

    return Container(
      padding: EdgeInsets.fromLTRB(18, compact ? 9 : 11, 18, compact ? 8 : 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesignSystem.hairline(context), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${kind.name.toUpperCase()} \u00b7 ${cat.label.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSizeSM + 2,
                    letterSpacing: 1.4,
                    height: 1,
                    color: muted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                ' / ${widget.deck.deckSize}',
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
          if (goal.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              goal,
              key: ValueKey<String>('feed_goal_${widget.game.id}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: DesignSystem.fontSizeXS,
                height: 1.25,
                color: muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardFooter(
    BuildContext context,
    ColorScheme colors,
    Color muted,
    Color accent,
    VoidCallback? onHint,
  ) {
    final l10n = AppLocalizations.of(context);
    final bool compact = MediaQuery.sizeOf(context).height < 760;
    final bool narrow = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: EdgeInsets.fromLTRB(
        narrow ? 12 : 18,
        compact ? 8 : 12,
        narrow ? 8 : 12,
        compact ? 6 : 10,
      ),
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
              widget.game.titleGetter(context),
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
          SizedBox(height: compact ? 4 : 8),
          Row(
            children: [
              _quietButton(
                context,
                icon: Icons.refresh_rounded,
                tooltip: l10n?.restartPuzzle ?? 'Restart',
                onTap: widget.onRestart,
                narrow: narrow,
              ),
              if (onHint != null)
                _quietButton(
                  context,
                  key: ValueKey<String>('feed_hint_${widget.game.id}'),
                  icon: Icons.lightbulb_outline_rounded,
                  tooltip: 'Hint',
                  onTap: () => requestHint(context, ref, onHint),
                  narrow: narrow,
                ),
              _quietButton(
                context,
                icon: Icons.help_outline_rounded,
                tooltip: l10n?.howToPlay ?? 'How to Play',
                onTap: widget.onGuide,
                narrow: narrow,
              ),
              const Spacer(),
              _quietButton(
                context,
                icon: widget.liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                tooltip: widget.liked
                    ? 'Remove from favourites'
                    : 'Add to favourites',
                onTap: widget.onLike,
                tinted: widget.liked,
                narrow: narrow,
              ),
              _quietButton(
                context,
                icon: Icons.visibility_off_outlined,
                tooltip: 'Hide from the deal',
                onTap: widget.onBlock,
                narrow: narrow,
              ),
              const SizedBox(width: 4),
              Flexible(child: _nextButton(context, accent, l10n)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quietButton(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool tinted = false,
    bool narrow = false,
  }) {
    final Color muted = DesignSystem.muted(context);
    final Color accent = DesignSystem.accent(context);
    return Tooltip(
      key: key,
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: narrow ? 32 : 36,
          height: 44,
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
        onTap: widget.onNext,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 14, right: 8),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    (l10n?.next ?? 'Next').toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Bebas Neue',
                      fontSize: DesignSystem.fontSizeLG,
                      letterSpacing: 1.2,
                      height: 1,
                      color: DesignSystem.onAccent(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: DesignSystem.onAccent(context),
              ),
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
    required this.onDailyFive,
    required this.dailyStreak,
    required this.dailyDone,
  });

  final bool showClose;
  final VoidCallback onClose;
  final VoidCallback? onBrowse;
  final VoidCallback onDailyFive;
  final int dailyStreak;
  final bool dailyDone;

  @override
  Widget build(BuildContext context) {
    final Color muted = DesignSystem.muted(context);
    final Color accent = DesignSystem.accent(context);

    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: DeckMark(size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'PUZZLESTACK',
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: DesignSystem.fontSizeLG,
                  letterSpacing: 1.4,
                  height: 1,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          key: const ValueKey<String>('feed_daily_five_chip'),
          onTap: onDailyFive,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
              border: Border.all(
                color: dailyDone ? accent : DesignSystem.hairline(context),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                dailyStreak > 0 ? 'DAILY 5 \u00b7 ${dailyStreak}D' : 'DAILY 5',
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: DesignSystem.fontSizeSM,
                  letterSpacing: 1.1,
                  height: 1,
                  color: dailyDone ? accent : muted,
                ),
              ),
            ),
          ),
        ),
        if (onBrowse != null)
          IconButton(
            onPressed: onBrowse,
            iconSize: 20,
            color: muted,
            tooltip: AppLocalizations.of(context)?.navStack ?? 'Stack',
            icon: const Icon(Icons.grid_view_rounded),
          ),
        if (showClose)
          IconButton(
            onPressed: onClose,
            iconSize: 20,
            color: muted,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }
}

/// Every game the registry knows, for the home screen's counter.
int deckTotal() => allGamesMetadata.length;
