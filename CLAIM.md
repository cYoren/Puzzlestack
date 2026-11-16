# CLAIM: `release/1.1-plus` (wave 3: `plus-purchase`, `picks`, `stack-chooser`)

One agent, three jobs in order, one commit each on `wave/w3-plus`.

## Files written

**Job 1 `plus-purchase`**

- `lib/data/key_value_store.dart` (new): the tiny storage seam the three new stores share.
- `lib/data/purchase/plus_entitlement.dart` (new): the one place that says whether Plus is owned.
- `lib/data/purchase/plus_store.dart` (new): that row in storage.
- `lib/data/purchase/plus_gateway.dart` (new): the store SDK behind an interface, plus the
  answers it may give. `InAppPurchaseGateway` is the only code that talks to the store.
- `lib/data/purchase/plus_controller.dart` (new): buy, restore, and the launch check.
- `lib/providers/plus_providers.dart` (new): the app reads Plus from here and nowhere else.
- `lib/ui/features/plus/plus_sheet.dart` (new): the single paywall, and the settings row it
  shares. English copy only (see "not done" in the report).
- `lib/ui/features/settings/settings_screen.dart` (edit): one Plus section with buy and restore.
- `lib/main.dart` (edit): opens the stores before the first frame; the launch check runs after.
- `test/data/plus_purchase_test.dart` (new).

**Job 2 `picks`**

- `lib/data/picks/pick_ledger.dart` (new): what has been picked today, and the days before.
- `lib/data/picks/pick_gate.dart` (new): the rule, as one decision type with no booleans.
- `lib/providers/pick_providers.dart` (new).
- `lib/ui/core/assist/game_launch.dart` (edit): every "open a game" passes through the gate.
- `test/data/picks_test.dart` (new).

**Job 3 `stack-chooser`**

- `lib/data/game_tiers.dart` (new): which games have a size ladder, its default, and where the
  remembered tier lives.
- `lib/providers/game_tier_provider.dart` (new): `startTier` / `rememberTier`, the only way a
  game learns a tier.
- `lib/ui/features/home/stack_chooser_sheet.dart` (new): the size and difficulty chooser.
- `lib/ui/core/assist/game_launch.dart` (edit): offers the chooser before the board.
- The 16 game providers that already keep a difficulty tier, so the remembered tier reaches the
  board and an in-game change is remembered: `cube`, `dominosa`, `futoshiki`, `galaxies`,
  `inertia`, `kurodoko`, `lights_out`, `magnets`, `map`, `netslide`, `pegs`, `same_game`,
  `signpost`, `skyscrapers`, `tents_and_trees`, `twiddle` (two lines each, through the shared
  helper; no screen and no board is edited).
- `test/data/stack_chooser_test.dart` (new).

## Files read, not written

`docs/PRODUCT.md`, `docs/FEED.md`, `ROADMAP.md`, `AGENTS.md`, `lib/data/models/`,
`lib/data/repositories/`, `lib/providers/`, `lib/ui/features/home/`, `lib/ui/features/feed/`,
`lib/ui/core/assist/`, `lib/ui/core/board/`, `lib/widgets/`.

## Not touched

The registry, the catalog, the `.arb` files, the board contract, every game screen, every
board, the Deck's deal order, and anything under `docs/` other than this claim.
