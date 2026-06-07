import 'package:flutter/material.dart';
import '../../../data/game_catalog.dart';
import '../../../utils/design_system.dart';

/// Search across all 161 games by title or category. Returns the chosen game
/// through [onSelected]; the caller handles navigation.
class GameSearchDelegate extends SearchDelegate<void> {
  final void Function(GameInfo game) onSelected;

  GameSearchDelegate({required this.onSelected})
      : super(searchFieldLabel: 'Search 161 puzzles');

  List<GameInfo> _results() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return GameCatalog.all;
    return GameCatalog.all.where((g) {
      return g.title.toLowerCase().contains(q) ||
          g.category.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _list(context);

  @override
  Widget buildSuggestions(BuildContext context) => _list(context);

  Widget _list(BuildContext context) {
    final results = _results();
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No puzzles match "$query"',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final g = results[i];
        final cat = GameCatalog.categoryInfo(g.category);
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: g.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
            ),
            child: Icon(g.icon, color: g.color, size: 22),
          ),
          title: Text(
            g.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(cat.label),
          onTap: () {
            close(context, null);
            onSelected(g);
          },
        );
      },
    );
  }
}
