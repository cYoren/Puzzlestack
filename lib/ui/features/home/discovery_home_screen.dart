import 'package:flutter/material.dart';
import '../../../data/game_catalog.dart';
import '../../../utils/design_system.dart';
import '../../../utils/navigation_utils.dart';
import '../../../widgets/tangible.dart';
import '../shuffle/shuffle_feed_screen.dart';
import 'category_room_screen.dart';
import 'game_search_delegate.dart';

/// The PuzzleBox home: a calm discovery surface instead of a flat list of 161
/// games. Funnels people into the Shuffle feed, surfaces a Daily Pick and a
/// Quick Play row, and tucks the full catalog into six category rooms.
class DiscoveryHomeScreen extends StatelessWidget {
  const DiscoveryHomeScreen({super.key});

  void _openGame(BuildContext context, GameInfo game) {
    Navigator.push(
      context,
      CustomPageRoute(page: game.buildScreen(context)),
    );
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final daily = GameCatalog.dailyPick();
    final quick = GameCatalog.quickPlay;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(child: _shuffleHero(context)),
            SliverToBoxAdapter(
              child: _sectionTitle(context, 'DAILY PICK'),
            ),
            SliverToBoxAdapter(child: _dailyCard(context, daily)),
            if (quick.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _sectionTitle(context, 'QUICK PLAY · UNDER 2 MIN'),
              ),
              SliverToBoxAdapter(child: _quickRow(context, quick)),
            ],
            SliverToBoxAdapter(
              child: _sectionTitle(context, 'EXPLORE BY CATEGORY'),
            ),
            _categoryGrid(context),
            const SliverToBoxAdapter(
              child: SizedBox(height: DesignSystem.spaceXL),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
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
                  'PuzzleBox',
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
          Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => showSearch(
                context: context,
                delegate: GameSearchDelegate(
                  onSelected: (g) => _openGame(context, g),
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

  Widget _dailyCard(BuildContext context, GameInfo game) {
    final cat = GameCatalog.categoryInfo(game.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
      child: TangibleContainer(
        onTap: () => _openGame(context, game),
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
                    game.title,
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

  Widget _quickRow(BuildContext context, List<GameInfo> games) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
        itemCount: games.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: DesignSystem.spaceSM),
        itemBuilder: (context, i) {
          final g = games[i];
          return _quickTile(context, g);
        },
      ),
    );
  }

  Widget _quickTile(BuildContext context, GameInfo game) {
    return GestureDetector(
      onTap: () => _openGame(context, game),
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
              game.title,
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
    final cats = GameCatalog.categories;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: DesignSystem.spaceSM,
          crossAxisSpacing: DesignSystem.spaceSM,
          childAspectRatio: 1.5,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _categoryTile(context, cats[i]),
          childCount: cats.length,
        ),
      ),
    );
  }

  Widget _categoryTile(BuildContext context, CategoryInfo cat) {
    final count = GameCatalog.countInCategory(cat.id);
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
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeLG,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  cat.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeXS,
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
}
