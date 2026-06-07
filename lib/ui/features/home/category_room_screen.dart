import 'package:flutter/material.dart';
import '../../../data/game_catalog.dart';
import '../../../utils/design_system.dart';
import '../../../utils/navigation_utils.dart';
import '../shuffle/shuffle_feed_screen.dart';

/// One category's "room": its tagline, a category-scoped Shuffle button, and a
/// grid of every game in that category.
class CategoryRoomScreen extends StatelessWidget {
  final String categoryId;

  const CategoryRoomScreen({super.key, required this.categoryId});

  void _openGame(BuildContext context, GameInfo game) {
    Navigator.push(
      context,
      CustomPageRoute(page: game.buildScreen(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = GameCatalog.categoryInfo(categoryId);
    final games = GameCatalog.inCategory(categoryId);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          cat.label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Bebas Neue',
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _shuffleBanner(context, cat, games.length)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DesignSystem.spaceLG,
                DesignSystem.spaceMD,
                DesignSystem.spaceLG,
                DesignSystem.spaceXL,
              ),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: DesignSystem.spaceSM,
                  crossAxisSpacing: DesignSystem.spaceSM,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _gameTile(context, games[i]),
                  childCount: games.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shuffleBanner(BuildContext context, CategoryInfo cat, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spaceLG,
        DesignSystem.spaceSM,
        DesignSystem.spaceLG,
        0,
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShuffleFeedScreen(categoryId: categoryId),
            fullscreenDialog: true,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(DesignSystem.spaceMD),
          decoration: BoxDecoration(
            color: cat.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(DesignSystem.radiusLG),
            border: Border.all(color: cat.color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shuffle_rounded, color: cat.color, size: 24),
              ),
              const SizedBox(width: DesignSystem.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shuffle ${cat.label}',
                      style: TextStyle(
                        fontSize: DesignSystem.fontSizeLG,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$count games · ${cat.tagline}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              Icon(Icons.chevron_right_rounded, color: cat.color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameTile(BuildContext context, GameInfo game) {
    return GestureDetector(
      onTap: () => _openGame(context, game),
      child: Container(
        padding: const EdgeInsets.all(DesignSystem.spaceMD),
        decoration: BoxDecoration(
          color: game.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(DesignSystem.radiusLG),
          border: Border.all(color: game.color.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(game.icon, color: game.color, size: 30),
            Text(
              game.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: DesignSystem.fontSizeMD,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
