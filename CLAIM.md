# Claim: fix the nonogram G4 flake

Files this branch touches, and nothing else:

- `CLAIM.md` (this file; removed from the PR's final diff)
- `lib/ui/features/games/nonogram/nonogram_engine.dart` — seedable `Random`,
  and the deal is accepted only when the game's own line solver finishes it
- `test/content/deal_families.dart` — the nonogram block only (seeded rng)
- `test/content/nonogram_test.dart` — the deal is deterministic, and every
  built board is finishable by its own rules
- `test/engines/nonogram_engine_test.dart` — the engine refuses a board below
  the bar, and a seed reproduces a deal
- `docs/CATALOG.md` — one line: what the nonogram generator now proves

Measured distribution and the reasoning are in the PR body.
