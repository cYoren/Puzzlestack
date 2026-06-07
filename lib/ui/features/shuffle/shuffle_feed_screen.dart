import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/game_catalog.dart';
import '../../../utils/design_system.dart';

/// The "I'm bored" mode: a full-screen, vertical, TikTok-style feed of puzzles.
/// Swipe up to drop into a fresh random puzzle, no menus in between.
///
/// Each page hosts a real game screen (with its own Scaffold). A slim overlay
/// shows where you are and a lock toggle, because a few games (2048, mazes)
/// use their own vertical swipes; locking pauses feed-scrolling so those games
/// stay fully playable.
class ShuffleFeedScreen extends StatefulWidget {
  /// Optionally start the feed on a specific game (e.g. from a "shuffle this
  /// category" entry point); otherwise the first page is random.
  final String? startGameId;

  /// Optionally restrict the feed to a single category (e.g. 'LOGIC').
  /// When null, the feed draws from every game.
  final String? categoryId;

  const ShuffleFeedScreen({super.key, this.startGameId, this.categoryId});

  @override
  State<ShuffleFeedScreen> createState() => _ShuffleFeedScreenState();
}

class _ShuffleFeedScreenState extends State<ShuffleFeedScreen> {
  final PageController _controller = PageController();
  final Random _random = Random();

  /// Lazily grown list of games in feed order. Index N is built on demand.
  final List<GameInfo> _order = [];

  bool _swipeEnabled = true;
  bool _showHint = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final GameInfo first = (widget.startGameId != null
            ? GameCatalog.find(widget.startGameId!)
            : null) ??
        _pick(exceptId: null);
    _order.add(first);
  }

  /// Picks the next random game, honouring an optional category filter and
  /// avoiding an immediate repeat where possible.
  GameInfo _pick({required String? exceptId}) {
    final String? cat = widget.categoryId;
    if (cat == null) {
      return GameCatalog.randomGame(exceptId: exceptId, random: _random);
    }
    final pool = GameCatalog.inCategory(cat);
    if (pool.isEmpty) {
      return GameCatalog.randomGame(exceptId: exceptId, random: _random);
    }
    if (pool.length == 1 || exceptId == null) {
      return pool[_random.nextInt(pool.length)];
    }
    GameInfo g;
    do {
      g = pool[_random.nextInt(pool.length)];
    } while (g.id == exceptId);
    return g;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Guarantees [_order] has an entry at [index], appending a non-repeating
  /// random game when needed.
  GameInfo _gameAt(int index) {
    while (_order.length <= index) {
      final String? prevId = _order.isNotEmpty ? _order.last.id : null;
      _order.add(_pick(exceptId: prevId));
    }
    return _order[index];
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
      if (index > 0) _showHint = false;
    });
  }

  void _toggleLock() {
    HapticFeedback.lightImpact();
    setState(() => _swipeEnabled = !_swipeEnabled);
  }

  void _nextManually() {
    HapticFeedback.lightImpact();
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            physics: _swipeEnabled
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final game = _gameAt(index);
              // Unique key per page so each game gets a distinct element.
              return KeyedSubtree(
                key: ValueKey('shuffle_${index}_${game.id}'),
                child: game.buildScreen(context),
              );
            },
          ),
          _TopBar(
            game: _gameAt(_currentIndex),
            swipeEnabled: _swipeEnabled,
            onClose: () => Navigator.of(context).maybePop(),
            onToggleLock: _toggleLock,
          ),
          if (_showHint && _swipeEnabled)
            _SwipeHint(onTap: _nextManually),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final GameInfo game;
  final bool swipeEnabled;
  final VoidCallback onClose;
  final VoidCallback onToggleLock;

  const _TopBar({
    required this.game,
    required this.swipeEnabled,
    required this.onClose,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    final cat = GameCatalog.categoryInfo(game.category);
    return SafeArea(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(
            horizontal: DesignSystem.spaceSM,
            vertical: DesignSystem.spaceXS,
          ),
          child: Row(
            children: [
              _circleButton(
                icon: Icons.close_rounded,
                tooltip: 'Exit shuffle',
                onTap: onClose,
              ),
              const Spacer(),
              _pill(cat: cat, title: game.title),
              const Spacer(),
              _circleButton(
                icon: swipeEnabled
                    ? Icons.lock_open_rounded
                    : Icons.lock_rounded,
                tooltip: swipeEnabled
                    ? 'Lock to play freely (pauses swipe)'
                    : 'Unlock swipe-for-next',
                onTap: onToggleLock,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _pill({required CategoryInfo cat, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shuffle_rounded, color: cat.color, size: 16),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              title.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: DesignSystem.fontSize2XS,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeHint extends StatefulWidget {
  final VoidCallback onTap;
  const _SwipeHint({required this.onTap});

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 28,
      child: SafeArea(
        child: Center(
          child: GestureDetector(
            onTap: widget.onTap,
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.45, end: 1.0).animate(_c),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius:
                      BorderRadius.circular(DesignSystem.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.keyboard_arrow_up_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'SWIPE UP FOR ANOTHER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: DesignSystem.fontSize2XS,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
