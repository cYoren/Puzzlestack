import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/game_categories.dart';
import '../../../data/game_metadata.dart';
import '../../../data/game_registry.dart';
import '../../../providers/game_session_provider.dart';
import '../../../providers/user_providers.dart';
import '../../../utils/design_system.dart';
import '../../../utils/haptic_feedback.dart';
import '../../../utils/navigation_utils.dart';
import '../../../widgets/super_streak_action.dart';
import '../../../widgets/tangible.dart';
import '../shuffle/shuffle_feed_screen.dart';
import 'category_room_screen.dart';
import 'game_search_delegate.dart';
import '../../core/assist/game_launch.dart';

/// The Puzzlestack home: a calm discovery surface instead of a flat list of
/// three hundred games. Funnels people into the Shuffle feed, surfaces a Daily Pick and a
/// Quick Play row, and tucks the full catalog into six category rooms.
class DiscoveryHomeScreen extends ConsumerWidget {
  const DiscoveryHomeScreen({super.key});

  void _openGame(BuildContext context, WidgetRef ref, GameMetadata game) {
    // Home has no shelf of its own; the completion dialog's "next puzzle" should
    // draw from the whole catalogue.
    ref.read(gameSessionNotifierProvider.notifier).setSession(
          gameId: game.id,
          category: 'ALL',
          query: '',
        );
    launchGame(context, ref, game);
  }

  void _openShuffle(BuildContext context, {String? categoryId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShuffleFeedScreen(categoryId: categoryId),
        fullscreenDialog: true,
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final daily = GameFeed.dailyPick();
    final quick = GameFeed.quickPlay;
    final favorites = _favorites(ref);
    final hidden = ref.watch(
        userDataNotifierProvider.select((d) => d.hiddenGameIds ?? const []));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(context, ref, hidden)),
            SliverToBoxAdapter(child: _shuffleHero(context)),
            if (favorites.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _sectionTitle(context, 'YOUR FAVORITES'),
              ),
              SliverToBoxAdapter(child: _favoritesRow(context, ref, favorites)),
            ],
            SliverToBoxAdapter(
              child: _sectionTitle(context, 'DAILY PICK'),
            ),
            SliverToBoxAdapter(child: _dailyCard(context, ref, daily)),
            if (quick.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _sectionTitle(context, 'QUICK PLAY · UNDER 2 MIN'),
              ),
              SliverToBoxAdapter(child: _quickRow(context, ref, quick)),
            ],
            SliverToBoxAdapter(
              child: _sectionTitle(context, 'EXPLORE BY CATEGORY'),
            ),
            _categoryGrid(context),
            SliverToBoxAdapter(
              child: _sectionTitle(
                context,
                'ALL ${allGamesMetadata.length} PUZZLES',
              ),
            ),
            // One endless list: the builder only makes the rows that are on
            // screen, so 300 games cost nothing until they are scrolled to.
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignSystem.spaceLG,
              ),
              sliver: SliverList.builder(
                itemCount: allGamesMetadata.length,
                itemBuilder: (context, index) {
                  final game = allGamesMetadata[index];
                  if (hidden.contains(game.id)) {
                    return const SizedBox.shrink();
                  }
                  return _allGamesRow(context, ref, game);
                },
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: DesignSystem.spaceXL),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, List<String> hidden) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spaceLG,
        DesignSystem.spaceMD,
        DesignSystem.spaceLG,
        DesignSystem.spaceSM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting().toUpperCase(),
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeSM,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Puzzlestack',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSize3XL,
                    letterSpacing: 0.5,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SuperStreakAction(),
          const SizedBox(width: DesignSystem.spaceSM),
          Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => showSearch(
                context: context,
                delegate: GameSearchDelegate(
                  hiddenIds: hidden.toSet(),
                  onSelected: (g) => _openGame(context, ref, g),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.search_rounded, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shuffleHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSystem.spaceLG,
        vertical: DesignSystem.spaceSM,
      ),
      child: GestureDetector(
        onTap: () => _openShuffle(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignSystem.spaceLG),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignSystem.radiusLG),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignSystem.primary,
                DesignSystem.accentBerry,
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "I'M BORED",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: DesignSystem.fontSizeXS,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Shuffle',
                      style: TextStyle(
                        fontFamily: 'Bebas Neue',
                        color: Colors.white,
                        fontSize: DesignSystem.fontSizeHero,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Swipe through random puzzles, one tap to start.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: DesignSystem.fontSizeSM,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignSystem.spaceMD),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shuffle_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spaceLG,
        DesignSystem.spaceLG,
        DesignSystem.spaceLG,
        DesignSystem.spaceSM,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Bebas Neue',
          fontSize: DesignSystem.fontSizeMD,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _dailyCard(BuildContext context, WidgetRef ref, GameMetadata game) {
    final cat = GameCategories.info(game.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
      child: TangibleContainer(
        onTap: () => _openGame(context, ref, game),
        padding: const EdgeInsets.all(DesignSystem.spaceMD),
        radius: DesignSystem.radiusLG,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: game.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
              ),
              child: Icon(game.icon, color: game.color, size: 28),
            ),
            const SizedBox(width: DesignSystem.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.titleGetter(context),
                    style: TextStyle(
                      fontSize: DesignSystem.fontSizeLG,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${cat.label} · today only',
                    style: TextStyle(
                      fontSize: DesignSystem.fontSizeSM,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_fill_rounded,
              color: game.color,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  /// Favorited games, in registry order, minus anything hidden. Empty until the
  /// player stars a game from a category room.
  List<GameMetadata> _favorites(WidgetRef ref) {
    final ids = ref.watch(
        userDataNotifierProvider.select((d) => d.favoriteGameIds ?? const []));
    if (ids.isEmpty) return const [];
    final hidden = ref.watch(
        userDataNotifierProvider.select((d) => d.hiddenGameIds ?? const []));
    final byId = {for (final g in allGamesMetadata) g.id: g};
    return [
      for (final id in ids)
        if (byId[id] != null && !hidden.contains(id)) byId[id]!,
    ];
  }

  Widget _favoritesRow(
      BuildContext context, WidgetRef ref, List<GameMetadata> games) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
        itemCount: games.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: DesignSystem.spaceSM),
        itemBuilder: (context, i) {
          final g = games[i];
          return Stack(
            children: [
              _quickTile(context, ref, g),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedbackUtil.lightImpact();
                    ref
                        .read(userDataNotifierProvider.notifier)
                        .toggleFavorite(g.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quickRow(
      BuildContext context, WidgetRef ref, List<GameMetadata> games) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
        itemCount: games.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: DesignSystem.spaceSM),
        itemBuilder: (context, i) {
          final g = games[i];
          return _quickTile(context, ref, g);
        },
      ),
    );
  }

  Widget _quickTile(BuildContext context, WidgetRef ref, GameMetadata game) {
    return GestureDetector(
      onTap: () => _openGame(context, ref, game),
      child: Container(
        width: 104,
        padding: const EdgeInsets.all(DesignSystem.spaceSM),
        decoration: BoxDecoration(
          color: game.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
          border: Border.all(color: game.color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(game.icon, color: game.color, size: 26),
            Text(
              game.titleGetter(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: DesignSystem.fontSizeSM,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryGrid(BuildContext context) {
    final cats = GameCategories.all;
    // 1.5 is the shape we want; 104dp is the height the tile needs to hold an
    // icon, a count, a label and a tagline. On a 320dp phone the ratio alone
    // gives 90dp and the tile overflows, so take whichever is taller.
    final width = MediaQuery.sizeOf(context).width;
    final tileWidth =
        (width - 2 * DesignSystem.spaceLG - DesignSystem.spaceSM) / 2;
    final tileHeight = math.max(104.0, tileWidth / 1.5);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: DesignSystem.spaceSM,
          crossAxisSpacing: DesignSystem.spaceSM,
          mainAxisExtent: tileHeight,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _categoryTile(context, cats[i]),
          childCount: cats.length,
        ),
      ),
    );
  }

  Widget _categoryTile(BuildContext context, CategoryInfo cat) {
    final count = GameCategories.countIn(cat.id);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CustomPageRoute(page: CategoryRoomScreen(categoryId: cat.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignSystem.spaceMD),
        decoration: BoxDecoration(
          color: cat.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(DesignSystem.radiusLG),
          border: Border.all(color: cat.color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(cat.icon, color: cat.color, size: 26),
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSizeLG,
                    height: 1.0,
                    color: cat.color,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeLG,
                    fontWeight: FontWeight.w800,
                    // The theme's body height (1.6) makes two lines of text
                    // taller than the tile. Tighten it here, not the tile.
                    height: 1.2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  cat.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeXS,
                    height: 1.2,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _allGamesRow(
    BuildContext context,
    WidgetRef ref,
    GameMetadata game,
  ) {
    return InkWell(
      onTap: () => _openGame(context, ref, game),
      borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignSystem.spaceSM),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: game.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
              ),
              child: Icon(game.icon, color: game.color, size: 22),
            ),
            const SizedBox(width: DesignSystem.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.titleGetter(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    game.subtitleGetter(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: DesignSystem.fontSize2XS,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
