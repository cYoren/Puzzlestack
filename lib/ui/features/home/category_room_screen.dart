import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import '../../../data/game_categories.dart';
import '../../../data/game_metadata.dart';
import '../../../providers/game_session_provider.dart';
import '../../../providers/user_providers.dart';
import '../../../utils/design_system.dart';
import '../../../utils/haptic_feedback.dart';
import '../shuffle/shuffle_feed_screen.dart';
import '../../core/assist/game_launch.dart';

/// One category's "room": its tagline, a category-scoped Shuffle button, and a
/// grid of every game in that category.
///
/// Each tile carries a star (favourite) and a long-press (hide). Both are the
/// only ways the rest of the app learns about a game: the home screen shows a
/// favourites row, and hidden games drop out of every browse surface.
class CategoryRoomScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryRoomScreen({super.key, required this.categoryId});

  void _openGame(BuildContext context, WidgetRef ref, GameMetadata game) {
    // Tells the completion dialog which shelf the player is browsing, so "next
    // puzzle" stays inside this category instead of jumping anywhere.
    ref.read(gameSessionNotifierProvider.notifier).setSession(
          gameId: game.id,
          category: categoryId,
          query: '',
        );
    launchGame(context, ref, game);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = GameCategories.info(categoryId);
    final hidden = ref.watch(
        userDataNotifierProvider.select((d) => d.hiddenGameIds ?? const []));
    final games = GameCategories.inCategory(categoryId)
        .where((g) => !hidden.contains(g.id))
        .toList(growable: false);
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
            SliverToBoxAdapter(
                child: _shuffleBanner(context, cat, games.length)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DesignSystem.spaceLG,
                DesignSystem.spaceMD,
                DesignSystem.spaceLG,
                DesignSystem.spaceXL,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: DesignSystem.spaceSM,
                  crossAxisSpacing: DesignSystem.spaceSM,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _gameTile(context, ref, games[i]),
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

  Widget _gameTile(BuildContext context, WidgetRef ref, GameMetadata game) {
    final isFavorite = ref.watch(userDataNotifierProvider
        .select((d) => (d.favoriteGameIds ?? const []).contains(game.id)));
    return GestureDetector(
      onTap: () => _openGame(context, ref, game),
      onLongPress: () => _hideGame(context, ref, game),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(game.icon, color: game.color, size: 30),
                _favoriteStar(context, ref, game, isFavorite),
              ],
            ),
            Text(
              game.titleGetter(context),
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

  /// The star sits inside the tile, so it needs its own hit target that does not
  /// fall through to the tile's onTap and open the game.
  Widget _favoriteStar(
      BuildContext context, WidgetRef ref, GameMetadata game, bool isFavorite) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedbackUtil.lightImpact();
        ref.read(userDataNotifierProvider.notifier).toggleFavorite(game.id);
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: Icon(
          isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
          size: 20,
          color: isFavorite
              ? game.color
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.28),
        ),
      ),
    );
  }

  void _hideGame(BuildContext context, WidgetRef ref, GameMetadata game) {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedbackUtil.mediumImpact();
    ref.read(userDataNotifierProvider.notifier).toggleHideGame(game.id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l10n.gameHidden),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => ref
              .read(userDataNotifierProvider.notifier)
              .toggleHideGame(game.id),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
