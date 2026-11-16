/// Opening the app on a named puzzle.
///
/// Every page of the website names one game, and the day the web build is hosted
/// the page's Play button has to land on that game instead of on whatever card
/// the deal happened to shuffle first. A URL is the only thing that can carry
/// that across a browser navigation:
///
///   https://…/?game=nonogram        (an id)
///   https://…/?game=tents-and-trees (a page slug)
///   https://…/?game=2048            (a slug that is not the id: `game_2048`)
///
/// Deliberately tolerant: an unknown value, a `#fragment`, a query from a source
/// we do not control, or a plain launch all resolve to null, and the app opens on
/// the deal exactly as it did before.
library;

/// The registry id a launch URL asks for, or null.
///
/// [knownIds] is the registry; passing it lets a slug (`tents-and-trees`) resolve
/// back to its id (`tents_and_trees`) instead of being guessed at.
String? gameIdFromUri(Uri uri, {Iterable<String> knownIds = const []}) {
  final String? raw = uri.queryParameters['game']?.trim();
  if (raw == null || raw.isEmpty) return null;

  final String wanted = raw.toLowerCase();
  for (final String id in knownIds) {
    if (id.toLowerCase() == wanted) return id;
    if (slugFor(id) == wanted) return id;
  }
  // No registry to check against: accept an id-shaped value, so a caller that
  // has not read the catalogue can still act. With a registry, an unknown id is
  // a typo or a probe and must not open anything.
  if (knownIds.isEmpty && RegExp(r'^[a-z0-9_]+$').hasMatch(wanted)) {
    return wanted;
  }
  return null;
}

/// The website's slug for a game id: `tents_and_trees` -> `tents-and-trees`.
///
/// Kept in step with `slugOverrides` in `tool/site_export.dart`; the test there
/// and here read the same rules.
String slugFor(String id) => switch (id) {
      'game_2048' => '2048',
      'sdmt' => 'symbol-digit',
      'd2_attention' => 'attention-d2',
      _ => id.replaceAll('_', '-'),
    };
