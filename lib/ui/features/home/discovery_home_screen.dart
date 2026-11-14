import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_categories.dart';
import '../../../data/game_metadata.dart';
import '../../../data/game_registry.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/game_session_provider.dart';
import '../../../providers/user_providers.dart';
import '../../../utils/design_system.dart';
import '../../../utils/haptic_feedback.dart';
import '../../../utils/navigation_utils.dart';
import '../../../widgets/deck.dart';
import '../../core/assist/game_launch.dart';
import '../main_shell/main_shell.dart';
import '../feed/feed_screen.dart';
import 'category_room_screen.dart';
import 'game_search_delegate.dart';

/// The stack: every puzzle, filed in six rooms.
///
/// This is the surface for someone who knows what they want. The deal is the
/// default tab because most people do not, and this page does not repeat it:
/// no second "shuffle" poster, just the six rooms, a card for today, a short
/// row for when you have two minutes, and a way to find one by name.
class DiscoveryHomeScreen extends ConsumerWidget {
  const DiscoveryHomeScreen({super.key});

  void _openGame(BuildContext context, WidgetRef ref, GameMetadata game) {
    HapticFeedbackUtil.selectionClick();
    // The stack has no shelf of its own; "next" after a solve should draw from
    // the whole catalogue rather than from the row the game was found in.
    ref.read(gameSessionNotifierProvider.notifier).setSession(
          gameId: game.id,
          category: 'ALL',
          query: '',
        );
    launchGame(context, ref, game);
  }

  List<GameMetadata> _favorites(WidgetRef ref) {
    final List<String> ids = ref.watch(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> hidden = ref
        .watch(userDataNotifierProvider.select(
            (d) => d.hiddenGameIds ?? const []))
        .toSet();
    // The daily pick is the same for everyone, so it is not drawn from this
    // player's hidden games; the card is what a hidden game suppresses.
    final GameMetadata daily = GameFeed.dailyPick();
    final bool dailyHidden = GameFeed.dailyPickIsHidden(exclude: hidden);
    final List<GameMetadata> quick = GameFeed.quickPlay
        .where((g) => !hidden.contains(g.id))
        .toList(growable: false);
    final List<GameMetadata> favorites = _favorites(ref);

    return Scaffold(
      backgroundColor: DesignSystem.paperOf(context),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header(context, ref, hidden.toList())),
                SliverToBoxAdapter(child: _dealCard(context, ref)),
                if (favorites.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _section(context, 'Your games'),
                  ),
                  SliverToBoxAdapter(
                      child: _favoritesRow(context, ref, favorites)),
                ],
                if (!dailyHidden)
                  SliverToBoxAdapter(child: _todayCard(context, ref, daily)),
                if (quick.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _section(
                        context,
                        AppLocalizations.of(context)?.quickPlay ??
                            'Under two minutes'),
                  ),
                  SliverToBoxAdapter(child: _quickRow(context, ref, quick)),
                ],
                SliverToBoxAdapter(
                  child: _section(context,
                      AppLocalizations.of(context)?.rooms ?? 'Six rooms'),
                ),
                _roomGrid(context),
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignSystem.spaceXL),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, List<String> hidden) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spaceLG,
        DesignSystem.spaceMD,
        DesignSystem.spaceSM,
        DesignSystem.spaceMD,
      ),
      child: Row(
        children: [
          const Expanded(child: StackWordmark(size: 26)),
          _chromeButton(
            context,
            icon: Icons.search_rounded,
            tooltip: MaterialLocalizations.of(context).searchFieldLabel,
            onTap: () => showSearch(
              context: context,
              delegate: GameSearchDelegate(
                hiddenIds: hidden.toSet(),
                onSelected: (g) => _openGame(context, ref, g),
              ),
            ),
          ),
          _chromeButton(
            context,
            icon: Icons.tune_rounded,
            tooltip: AppLocalizations.of(context)?.settings ?? 'Settings',
            onTap: () => openSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _chromeButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: DesignSystem.muted(context)),
        ),
      ),
    );
  }

  /// The one place the whole deck is offered as a thing to do: a stack of
  /// cards with the count on it. Tapping deals a full-screen hand.
  Widget _dealCard(BuildContext context, WidgetRef ref) {
    final int total = allGamesMetadata.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spaceLG,
        0,
        DesignSystem.spaceLG,
        DesignSystem.spaceSM,
      ),
      child: DeckCard(
        pile: 2,
        lift: 1.2,
        padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
        onTap: () {
          HapticFeedbackUtil.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FeedScreen(isRoute: true)),
          );
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEAL',
                    style: TextStyle(
                      fontFamily: 'Bebas Neue',
                      fontSize: DesignSystem.fontSizeHero + 6,
                      height: 0.9,
                      letterSpacing: 0.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)?.dealSubtitle ??
                        'Every puzzle, one card at a time.',
                    style: TextStyle(
                      fontSize: DesignSystem.fontSizeSM,
                      height: 1.3,
                      color: DesignSystem.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignSystem.spaceSM),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                DeckNumber('$total',
                    size: 44, color: DesignSystem.accent(context)),
                Text(
                  (AppLocalizations.of(context)?.puzzles ?? 'puzzles')
                      .toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSize2XS,
                    letterSpacing: 1.4,
                    height: 1,
                    color: DesignSystem.muted(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayCard(BuildContext context, WidgetRef ref, GameMetadata game) {
    final Color accent = DesignSystem.accent(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spaceLG,
        DesignSystem.spaceSM,
        DesignSystem.spaceLG,
        DesignSystem.spaceSM,
      ),
      child: DeckCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        onTap: () => _openGame(context, ref, game),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    game.titleGetter(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Bebas Neue',
                      fontSize: DesignSystem.fontSize2XL,
                      height: 1,
                      letterSpacing: 0.4,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DeckChip(
                  label: (AppLocalizations.of(context)?.todaysCard ??
                          "Today's card")
                      .toUpperCase(),
                  icon: Icons.wb_sunny_outlined,
                  tint: accent,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              game.subtitleGetter(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: DesignSystem.fontSizeXS,
                height: 1.35,
                color: DesignSystem.muted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spaceLG,
        DesignSystem.spaceMD,
        DesignSystem.spaceLG,
        DesignSystem.spaceSM,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Bebas Neue',
          fontSize: DesignSystem.fontSizeXL,
          letterSpacing: 0.6,
          height: 1,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _quickRow(BuildContext context, WidgetRef ref, List<GameMetadata> games) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
        itemCount: games.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: DesignSystem.spaceSM),
        itemBuilder: (context, i) => _quickTile(context, ref, games[i]),
      ),
    );
  }

  /// Favourites are the player's own shelf: a short row above the daily card,
  /// each tile with a way off the shelf.
  Widget _favoritesRow(
      BuildContext context, WidgetRef ref, List<GameMetadata> games) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
        itemCount: games.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: DesignSystem.spaceSM),
        itemBuilder: (context, i) {
          final GameMetadata game = games[i];
          return Stack(
            children: [
              _quickTile(context, ref, game),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedbackUtil.lightImpact();
                    ref
                        .read(userDataNotifierProvider.notifier)
                        .toggleFavorite(game.id);
                  },
                  child: Icon(Icons.close_rounded,
                      size: 14, color: DesignSystem.muted(context)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quickTile(BuildContext context, WidgetRef ref, GameMetadata game) {
    return DeckCard(
      padding: const EdgeInsets.all(12),
      radius: 16,
      onTap: () => _openGame(context, ref, game),
      child: SizedBox(
        width: 92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(game.icon, size: 20, color: DesignSystem.accent(context)),
            const SizedBox(height: 12),
            Text(
              game.titleGetter(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: DesignSystem.fontSizeXS,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomGrid(BuildContext context) {
    final List<CategoryInfo> cats = GameCategories.all;
    // 104dp is the height the tile needs to hold a count, a name and a
    // tagline. On a 320dp phone the ratio alone gives 90dp and the tile
    // overflows, so take whichever is taller.
    final double width = math.min(MediaQuery.sizeOf(context).width, 760);
    final int columns = width > 620 ? 3 : 2;
    final double tileWidth = (width -
            2 * DesignSystem.spaceLG -
            (columns - 1) * DesignSystem.spaceSM) /
        columns;
    // Tall enough for a name, a count and a two-line tagline; never a slab.
    final double tileHeight = (tileWidth / 2.3).clamp(88.0, 104.0);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: DesignSystem.spaceSM,
          crossAxisSpacing: DesignSystem.spaceSM,
          mainAxisExtent: tileHeight,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _roomTile(context, cats[i]),
          childCount: cats.length,
        ),
      ),
    );
  }

  Widget _roomTile(BuildContext context, CategoryInfo cat) {
    final int count = GameCategories.countIn(cat.id);
    return DeckCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      onTap: () {
        HapticFeedbackUtil.selectionClick();
        Navigator.push(
          context,
          CustomPageRoute(page: CategoryRoomScreen(categoryId: cat.id)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  cat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSizeXL,
                    height: 1,
                    letterSpacing: 0.4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              DeckNumber('$count',
                  size: 18, color: DesignSystem.muted(context)),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            cat.tagline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: DesignSystem.fontSizeXS,
              height: 1.25,
              color: DesignSystem.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}
