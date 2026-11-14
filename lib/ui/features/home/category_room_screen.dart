import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_categories.dart';
import '../../../data/game_metadata.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/game_session_provider.dart';
import '../../../providers/user_providers.dart';
import '../../../utils/design_system.dart';
import '../../../utils/haptic_feedback.dart';
import '../../../widgets/deck.dart';
import '../../core/assist/game_launch.dart';
import '../feed/feed_screen.dart';

/// One room of the stack: every puzzle in a category, filed as cards.
///
/// The deal this room offers is the same feed as everywhere else, scoped to the
/// category, so a room is never a dead end that drops you back into a list.
class CategoryRoomScreen extends ConsumerWidget {
  const CategoryRoomScreen({super.key, required this.categoryId});

  final String categoryId;

  void _openGame(BuildContext context, WidgetRef ref, GameMetadata game) {
    HapticFeedbackUtil.selectionClick();
    // Tells the result card which shelf the player is browsing, so "next" stays
    // inside this room instead of jumping anywhere.
    ref.read(gameSessionNotifierProvider.notifier).setSession(
          gameId: game.id,
          category: categoryId,
          query: '',
        );
    launchGame(context, ref, game);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CategoryInfo cat = GameCategories.info(categoryId);
    final List<String> hidden = ref.watch(
        userDataNotifierProvider.select((d) => d.hiddenGameIds ?? const []));
    final List<GameMetadata> games = GameCategories.inCategory(categoryId)
        .where((g) => !hidden.contains(g.id))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: DesignSystem.paperOf(context),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(context, cat, games.length)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DesignSystem.spaceLG,
                DesignSystem.spaceSM,
                DesignSystem.spaceLG,
                DesignSystem.spaceXL,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: DesignSystem.spaceSM,
                  crossAxisSpacing: DesignSystem.spaceSM,
                  mainAxisExtent: 96,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) =>
                      _gameTile(context, ref, games[i], i + 1),
                  childCount: games.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, CategoryInfo cat, int count) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spaceLG,
        DesignSystem.spaceSM,
        DesignSystem.spaceLG,
        DesignSystem.spaceMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkResponse(
                onTap: () => Navigator.of(context).maybePop(),
                radius: 24,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_back_rounded,
                      size: 20, color: DesignSystem.muted(context)),
                ),
              ),
              const Spacer(),
              DeckNumber('$count',
                  size: 22, color: DesignSystem.muted(context)),
            ],
          ),
          const SizedBox(height: DesignSystem.spaceSM),
          Text(
            cat.label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: DesignSystem.fontSizeHero + 8,
              height: 0.9,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cat.tagline,
            style: TextStyle(
              fontSize: DesignSystem.fontSizeSM,
              height: 1.3,
              color: DesignSystem.muted(context),
            ),
          ),
          const SizedBox(height: DesignSystem.spaceMD),
          _dealRow(context, cat, l10n),
        ],
      ),
    );
  }

  Widget _dealRow(
      BuildContext context, CategoryInfo cat, AppLocalizations? l10n) {
    return Semantics(
      button: true,
      label: l10n?.shuffleCategory ?? 'Deal this room',
      child: GestureDetector(
        onTap: () {
          HapticFeedbackUtil.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FeedScreen(categoryId: categoryId, isRoute: true),
            ),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: DesignSystem.accent(context),
            borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (l10n?.shuffleCategory ?? 'Deal this room').toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: DesignSystem.fontSizeLG,
                  letterSpacing: 1.2,
                  height: 1,
                  color: DesignSystem.onAccent(context),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_downward_rounded,
                  size: 18, color: DesignSystem.onAccent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameTile(BuildContext context, WidgetRef ref, GameMetadata game,
      int position) {
    final bool isFavorite = ref.watch(userDataNotifierProvider
        .select((d) => (d.favoriteGameIds ?? const []).contains(game.id)));
    return DeckCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      radius: 16,
      onTap: () => _openGame(context, ref, game),
      onLongPress: () => _hideGame(context, ref, game),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(game.icon, size: 18, color: DesignSystem.muted(context)),
              const Spacer(),
              _favoriteStar(context, ref, game, isFavorite),
              const SizedBox(width: 6),
              DeckNumber(
                position.toString().padLeft(2, '0'),
                size: 16,
                color: DesignSystem.hairline(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            game.titleGetter(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: DesignSystem.fontSizeSM,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// The star and the long-press are the only two things the rest of the app
  /// learns from a room: the stack shows a favourites row, and hidden games
  /// drop out of every browse surface.
  Widget _favoriteStar(
      BuildContext context, WidgetRef ref, GameMetadata game, bool isFavorite) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedbackUtil.lightImpact();
        ref.read(userDataNotifierProvider.notifier).toggleFavorite(game.id);
      },
      child: Icon(
        isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
        size: 18,
        color: isFavorite
            ? DesignSystem.accent(context)
            : DesignSystem.hairline(context),
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
