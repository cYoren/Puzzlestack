/// Which puzzles the Shuffle feed is allowed to serve.
///
/// The library and the reel are two different products. The library is the whole
/// registry: every puzzle is playable from its category room. The reel is a
/// curated stream, and a puzzle that does not read as a puzzle, or whose
/// interaction does not survive a full-screen vertical swipe, has no business in
/// it. Keeping that verdict in one list means the catalogue stays complete while
/// the reel stays good.
///
/// This list is hand-curated, not inferred. Add ids one per line; the id is the
/// directory name under `lib/ui/features/games/` and the `id:` field in the
/// game's metadata. [curationIdsAreReal] in `test/curation_test.dart` fails the
/// build on a typo, and an empty list is a valid state: the reel simply serves
/// the whole registry.
const Set<String> feedBlocklist = <String>{
  // Paste the curation list here.
};
