import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/data/game_tiers.dart';
import 'package:puzzle/data/key_value_store.dart';
import 'package:puzzle/data/picks/pick_gate.dart';
import 'package:puzzle/data/purchase/plus_gateway.dart';
import 'package:puzzle/providers/game_tier_provider.dart';
import 'package:puzzle/providers/pick_providers.dart';
import 'package:puzzle/providers/plus_providers.dart';
import 'package:puzzle/ui/core/assist/game_launch.dart';
import 'package:puzzle/ui/features/home/stack_chooser_sheet.dart';
import 'package:puzzle/ui/features/games/cube/cube_engine.dart';
import 'package:puzzle/ui/features/games/cube/cube_provider.dart';
import 'package:puzzle/ui/features/games/dominosa/dominosa_engine.dart';
import 'package:puzzle/ui/features/games/dominosa/dominosa_provider.dart';
import 'package:puzzle/ui/features/games/futoshiki/futoshiki_engine.dart';
import 'package:puzzle/ui/features/games/futoshiki/futoshiki_provider.dart';
import 'package:puzzle/ui/features/games/galaxies/galaxies_engine.dart';
import 'package:puzzle/ui/features/games/galaxies/galaxies_provider.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_engine.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_provider.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_engine.dart';
import 'package:puzzle/ui/features/games/kurodoko/kurodoko_provider.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_engine.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_provider.dart';
import 'package:puzzle/ui/features/games/magnets/magnets_engine.dart';
import 'package:puzzle/ui/features/games/magnets/magnets_provider.dart';
import 'package:puzzle/ui/features/games/map/map_engine.dart';
import 'package:puzzle/ui/features/games/map/map_provider.dart';
import 'package:puzzle/ui/features/games/netslide/netslide_engine.dart';
import 'package:puzzle/ui/features/games/netslide/netslide_provider.dart';
import 'package:puzzle/ui/features/games/pegs/pegs_engine.dart';
import 'package:puzzle/ui/features/games/pegs/pegs_provider.dart';
import 'package:puzzle/ui/features/games/same_game/same_game_engine.dart';
import 'package:puzzle/ui/features/games/same_game/same_game_provider.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_engine.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_provider.dart';
import 'package:puzzle/ui/features/games/skyscrapers/skyscrapers_engine.dart';
import 'package:puzzle/ui/features/games/skyscrapers/skyscrapers_provider.dart';
import 'package:puzzle/ui/features/games/tents_and_trees/tents_and_trees_engine.dart';
import 'package:puzzle/ui/features/games/tents_and_trees/tents_and_trees_provider.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_engine.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_provider.dart';

/// The size chooser, end to end: the table, the row in storage, and the board
/// that opens at the size the player picked.
///
/// One adapter per game is the only per-game code here, and it is the same two
/// lines each provider carries: read the tier, choose a tier. Everything else
/// is the shared mechanism, so a game wired wrongly fails here rather than in
/// a player's hands.
void main() {
  group('which games are asked for a size', () {
    test('a game with one size is not offered a choice', () {
      // The classics are frozen at one board. A chooser with one option is a
      // question with one answer, so the sheet never opens for them.
      expect(offersTierChoice('sudoku'), isFalse);
      expect(offersTierChoice('nonogram'), isFalse);
      expect(offersTierChoice('minesweeper'), isFalse);
      expect(offersTierChoice('reserved_for_a_later_game'), isFalse);
      expect(gameLadders.containsKey('sudoku'), isFalse);
    });

    test('the sixteen ports with a difficulty are the ones asked', () {
      expect(
        gameLadders.keys.toSet(),
        <String>{
          'cube',
          'dominosa',
          'futoshiki',
          'galaxies',
          'inertia',
          'kurodoko',
          'lights_out',
          'magnets',
          'map',
          'netslide',
          'pegs',
          'same_game',
          'signpost',
          'skyscrapers',
          'tents_and_trees',
          'twiddle',
        },
      );
      for (final String gameId in gameLadders.keys) {
        expect(offersTierChoice(gameId), isTrue);
      }
    });

    test('every ladder has real rungs and a default it offers', () {
      for (final GameLadder ladder in gameLadders.values) {
        expect(ladder.tiers.length, greaterThanOrEqualTo(2),
            reason: '${ladder.gameId} asks a question worth asking');
        expect(ladder.has(ladder.defaultTier), isTrue,
            reason: '${ladder.gameId} opens at a rung it has');
        expect(
          ladder.tiers.map((GameTier tier) => tier.id).toSet().length,
          ladder.tiers.length,
          reason: '${ladder.gameId} has no duplicate rungs',
        );
        for (final GameTier tier in ladder.tiers) {
          expect(tier.id, isNotEmpty);
          expect(tier.label, isNotEmpty);
          expect(tier.detail, isNotEmpty);
          // Plain words, sentence case, no dashes.
          expect(tier.label.contains(RegExp('[-\u2013\u2014]')), isFalse);
          expect(tier.detail.contains(RegExp('[-\u2013\u2014]')), isFalse);
        }
      }
    });
  });

  group('a fresh install', () {
    test('opens each game at the ladder default', () {
      final MemoryKeyValueStore rows = MemoryKeyValueStore();
      for (final String gameId in _games.keys) {
        final ProviderContainer container = _open(rows, gameId);
        expect(
          _games[gameId]!.tierNow(container),
          _ladderOf(gameId).defaultTier,
          reason: gameId,
        );
        container.dispose();
      }
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  group('every rung generates', () {
    test('each ladder builds a board at each of its tiers', () {
      for (final String gameId in _games.keys) {
        for (final GameTier tier in _ladderOf(gameId).tiers) {
          final ProviderContainer container =
              _open(MemoryKeyValueStore(), gameId);
          _games[gameId]!.choose(container, tier.id);
          expect(
            _games[gameId]!.tierNow(container),
            tier.id,
            reason: '$gameId at ${tier.id}',
          );
          container.dispose();
        }
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  group('the remembered tier', () {
    test('survives a rebuild of the app', () {
      final MemoryKeyValueStore rows = MemoryKeyValueStore();
      for (final String gameId in _games.keys) {
        final GameLadder ladder = _ladderOf(gameId);
        final String chosen = ladder.tiers.last.id;

        final ProviderContainer first = _open(rows, gameId);
        _games[gameId]!.choose(first, chosen);
        expect(_games[gameId]!.tierNow(first), chosen);
        first.dispose();

        // A new container over the same rows is the next launch.
        final ProviderContainer next = _open(rows, gameId);
        expect(_games[gameId]!.tierNow(next), chosen, reason: gameId);
        next.dispose();
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('a board that is already alive takes the size just chosen', () async {
      final MemoryKeyValueStore rows = MemoryKeyValueStore();
      final ProviderContainer container = _open(rows, 'cube');

      // The Deal keeps the current card mounted behind its tabs, so this board
      // exists before the player opens the same game from the Stack.
      expect(container.read(cubeNotifierProvider).difficulty,
          CubeDifficulty.medium);

      // What the chooser's write alone leaves behind: the row is stored, the
      // live board has not heard about it. That was the defect.
      await GameTierStore(rows).remember('cube', 'hard');
      expect(container.read(cubeNotifierProvider).difficulty,
          CubeDifficulty.medium);

      // The launch bumps this game's revision, and the board that is opening is
      // rebuilt at the size the player just picked.
      container.read(tierRevisionProvider('cube').notifier).state++;
      expect(
          container.read(cubeNotifierProvider).difficulty, CubeDifficulty.hard);
    });

    test('choosing a size for one game leaves every other live board untouched',
        () async {
      final MemoryKeyValueStore rows = MemoryKeyValueStore();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          gameTierStoreProvider.overrideWithValue(GameTierStore(rows)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(cubeNotifierProvider, (_, __) {}, fireImmediately: true);
      container.listen(
        dominosaNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      final CubeState cubeInDeal = container.read(cubeNotifierProvider);
      expect(
        container.read(dominosaNotifierProvider).difficulty,
        DominosaDifficulty.medium,
      );

      await GameTierStore(rows).remember('dominosa', 'hard');
      container.read(tierRevisionProvider('dominosa').notifier).state++;

      expect(
        container.read(dominosaNotifierProvider).difficulty,
        DominosaDifficulty.hard,
      );
      expect(
        identical(container.read(cubeNotifierProvider), cubeInDeal),
        isTrue,
        reason: 'opening Dominosa from Stack must not re-deal Cube in the Deal',
      );
    });

    test('is one row per game, beside the first-play flag', () {
      final MemoryKeyValueStore rows = MemoryKeyValueStore();
      final GameTierStore store = GameTierStore(rows);
      expect(GameTierStore.boxName, 'game_stats');
      expect(GameTierStore.rowKey('cube'), 'tier.cube');

      final ProviderContainer container = _open(rows, 'cube');
      _games['cube']!.choose(container, 'hard');
      container.dispose();

      expect(store.tierFor('cube'), 'hard');
      expect(store.tierFor('twiddle'), isNull);
    });

    test('a rung the game no longer has falls back to the default', () async {
      final MemoryKeyValueStore rows = MemoryKeyValueStore();
      final GameTierStore store = GameTierStore(rows);
      await rows.write(GameTierStore.rowKey('cube'), 'impossible');

      expect(store.startFor('cube'), _ladderOf('cube').defaultTier);

      final ProviderContainer container = _open(rows, 'cube');
      expect(_games['cube']!.tierNow(container), 'medium');
      container.dispose();
    });
  });

  group('the chooser', () {
    testWidgets('a game with no ladder never opens the sheet', (tester) async {
      expect(offersTierChoice('sudoku'), isFalse);
      // Nothing to show: the launcher's branch is this one predicate.
      expect(gameLadders['sudoku'], isNull);
    });

    testWidgets('choosing a tier reaches the board', (tester) async {
      final MemoryKeyValueStore rows = MemoryKeyValueStore();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          gameTierStoreProvider.overrideWithValue(GameTierStore(rows)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(cubeNotifierProvider, (_, __) {}, fireImmediately: true);
      expect(container.read(cubeNotifierProvider).difficulty.name, 'medium');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (BuildContext context) => Scaffold(
                body: Center(
                  child: Consumer(
                    builder: (BuildContext context, WidgetRef ref, _) =>
                        TextButton(
                      onPressed: () async {
                        final GameLadder ladder = gameLadders['cube']!;
                        final GameTier? chosen = await showStackChooserSheet(
                          context,
                          ladder: ladder,
                          gameTitle: 'Cube',
                          currentTierId: ref
                                  .read(gameTierStoreProvider)
                                  .startFor('cube') ??
                              ladder.defaultTier,
                        );
                        if (chosen == null) return;
                        await ref.rememberTier('cube', chosen.id);
                      },
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a size'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);

      await tester.tap(find.text('Hard'));
      await tester.pumpAndSettle();

      expect(GameTierStore(rows).tierFor('cube'), 'hard');

      // The next board of this game opens at the size just chosen.
      final ProviderContainer next = _open(rows, 'cube');
      expect(next.read(cubeNotifierProvider).difficulty, CubeDifficulty.hard);
      next.dispose();
    });

    testWidgets('closing it chooses nothing', (tester) async {
      final MemoryKeyValueStore rows = MemoryKeyValueStore();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showStackChooserSheet(
                    context,
                    ladder: gameLadders['cube']!,
                    gameTitle: 'Cube',
                    currentTierId: 'medium',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(GameTierStore(rows).tierFor('cube'), isNull);
    });

    testWidgets(
      'buying Plus on a fourth pick continues into the size chooser and opens at that size',
      (tester) async {
        final MemoryKeyValueStore rows = MemoryKeyValueStore();
        final ProviderContainer container = _plusLaunchContainer(rows);
        addTearDown(container.dispose);

        // Dominosa is held by the Deal behind the tabs; Cube has been played
        // and today's three picks are spent.
        container.listen(
          dominosaNotifierProvider,
          (_, __) {},
          fireImmediately: true,
        );
        final DominosaState dominosaInDeal =
            container.read(dominosaNotifierProvider);
        final PickGate picks = container.read(pickGateProvider);
        await picks.request('cube');
        for (int i = 0; i < 3; i++) {
          await picks.request('cube');
        }

        await tester.pumpWidget(_launchHarness(container));
        await tester.tap(find.text('launch-cube'));
        await tester.pumpAndSettle();

        // Paywall sits over the preview board.
        expect(find.text('PUZZLESTACK PLUS'), findsOneWidget);
        await tester.tap(find.text('GET PLUS'));
        await tester.pumpAndSettle();

        // Buying Plus continues straight into the size chooser rather than
        // stranding the player on the preview tier.
        expect(find.text('Choose a size'), findsOneWidget);
        await tester.tap(find.text('Hard'));
        await tester.pumpAndSettle();

        expect(find.text('board:hard'), findsOneWidget);
        expect(GameTierStore(rows).tierFor('cube'), 'hard');
        expect(
          identical(container.read(dominosaNotifierProvider), dominosaInDeal),
          isTrue,
        );
      },
    );

    testWidgets(
      'closing the size chooser after buying Plus leaves no preview board open',
      (tester) async {
        final MemoryKeyValueStore rows = MemoryKeyValueStore();
        final ProviderContainer container = _plusLaunchContainer(rows);
        addTearDown(container.dispose);

        final PickGate picks = container.read(pickGateProvider);
        await picks.request('cube');
        for (int i = 0; i < 3; i++) {
          await picks.request('cube');
        }

        await tester.pumpWidget(_launchHarness(container));
        await tester.tap(find.text('launch-cube'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('GET PLUS'));
        await tester.pumpAndSettle();

        expect(find.text('Choose a size'), findsOneWidget);
        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();

        expect(container.read(plusProvider).ownsPlus, isTrue);
        expect(find.textContaining('board:'), findsNothing);
        expect(find.text('launch-cube'), findsOneWidget);
      },
    );
  });
}

class _InstantPlusStore implements PlusGateway {
  final StreamController<PurchaseEvent> _events =
      StreamController<PurchaseEvent>.broadcast();

  @override
  Stream<PurchaseEvent> get events => _events.stream;

  @override
  Future<String?> price() async => 'US\$4.99';

  @override
  Future<PurchaseAnswer> buy() async => PurchaseAnswer.purchased;

  @override
  Future<RestoreAnswer> restore() async => RestoreAnswer.owned;

  @override
  Future<void> completePurchase(PurchaseEvent event) async {}

  @override
  Future<void> dispose() async => _events.close();
}

ProviderContainer _plusLaunchContainer(MemoryKeyValueStore rows) =>
    ProviderContainer(
      overrides: <Override>[
        gameTierStoreProvider.overrideWithValue(GameTierStore(rows)),
        pickStoreProvider.overrideWithValue(rows),
        plusStoreProvider.overrideWithValue(rows),
        plusGatewayProvider.overrideWithValue(_InstantPlusStore.new),
      ],
    );

Widget _launchHarness(ProviderContainer container) {
  final GameMetadata cubeMeta = GameMetadata(
    id: 'cube',
    category: 'logic',
    icon: Icons.check_box_outline_blank,
    color: Colors.blue,
    titleGetter: (_) => 'Cube',
    subtitleGetter: (_) => 'Roll the cube',
    builder: (_) => Consumer(
      builder: (_, WidgetRef ref, __) {
        final CubeState state = ref.watch(cubeNotifierProvider);
        return Scaffold(
            body: Center(child: Text('board:${state.difficulty.name}')));
      },
    ),
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, _) => TextButton(
              onPressed: () => launchGame(context, ref, cubeMeta),
              child: const Text('launch-cube'),
            ),
          ),
        ),
      ),
    ),
  );
}

GameLadder _ladderOf(String gameId) => gameLadders[gameId]!;

/// A container over [rows], holding [gameId]'s board open so its state is not
/// rebuilt between the two reads a test makes.
ProviderContainer _open(KeyValueStore rows, String gameId) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      gameTierStoreProvider.overrideWithValue(GameTierStore(rows)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(_games[gameId]!.provider, (_, __) {}, fireImmediately: true);
  return container;
}

/// What a game's provider is asked, and what it answers.
class _Game {
  _Game({
    required this.provider,
    required this.tierNow,
    required this.choose,
  });

  final ProviderListenable<dynamic> provider;

  /// The tier the board was built at, as its stored id.
  final String Function(ProviderContainer container) tierNow;

  /// Chooses a tier by its stored id, exactly as the size chip does.
  final void Function(ProviderContainer container, String tierId) choose;
}

_Game _enumGame<T extends Enum>({
  required ProviderListenable<dynamic> provider,
  required List<T> values,
  required T Function(ProviderContainer container) current,
  required void Function(ProviderContainer container, T tier) choose,
}) =>
    _Game(
      provider: provider,
      tierNow: (ProviderContainer container) => current(container).name,
      choose: (ProviderContainer container, String tierId) => choose(
        container,
        values.firstWhere((T tier) => tier.name == tierId),
      ),
    );

final Map<String, _Game> _games = <String, _Game>{
  'cube': _enumGame<CubeDifficulty>(
    provider: cubeNotifierProvider,
    values: CubeDifficulty.values,
    current: (c) => c.read(cubeNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(cubeNotifierProvider.notifier).setDifficulty(tier),
  ),
  'dominosa': _enumGame<DominosaDifficulty>(
    provider: dominosaNotifierProvider,
    values: DominosaDifficulty.values,
    current: (c) => c.read(dominosaNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(dominosaNotifierProvider.notifier).setDifficulty(tier),
  ),
  'futoshiki': _enumGame<FutoshikiDifficulty>(
    provider: futoshikiNotifierProvider,
    values: FutoshikiDifficulty.values,
    current: (c) => c.read(futoshikiNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(futoshikiNotifierProvider.notifier).setDifficulty(tier),
  ),
  'galaxies': _enumGame<GalaxiesDifficulty>(
    provider: galaxiesNotifierProvider,
    values: GalaxiesDifficulty.values,
    current: (c) => c.read(galaxiesNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(galaxiesNotifierProvider.notifier).setDifficulty(tier),
  ),
  'inertia': _enumGame<InertiaDifficulty>(
    provider: inertiaNotifierProvider,
    values: InertiaDifficulty.values,
    current: (c) => c.read(inertiaNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(inertiaNotifierProvider.notifier).setDifficulty(tier),
  ),
  // Kurodoko's three tiers are static constants, not an enum, so its id is the
  // label the engine already carries.
  'kurodoko': _Game(
    provider: kurodokoNotifierProvider,
    tierNow: (c) => c.read(kurodokoNotifierProvider).difficulty.label,
    choose: (c, tierId) {
      final KurodokoDifficulty tier = KurodokoDifficulty.values
          .firstWhere((KurodokoDifficulty value) => value.label == tierId);
      c.read(kurodokoNotifierProvider.notifier).setDifficulty(tier);
    },
  ),
  'lights_out': _enumGame<LightsOutDifficulty>(
    provider: lightsOutNotifierProvider,
    values: LightsOutDifficulty.values,
    current: (c) => c.read(lightsOutNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(lightsOutNotifierProvider.notifier).setDifficulty(tier),
  ),
  'magnets': _enumGame<MagnetsDifficulty>(
    provider: magnetsNotifierProvider,
    values: MagnetsDifficulty.values,
    current: (c) => c.read(magnetsNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(magnetsNotifierProvider.notifier).setDifficulty(tier),
  ),
  'map': _enumGame<MapDifficulty>(
    provider: mapNotifierProvider,
    values: MapDifficulty.values,
    current: (c) => c.read(mapNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(mapNotifierProvider.notifier).setDifficulty(tier),
  ),
  'netslide': _enumGame<NetDifficulty>(
    provider: netslideNotifierProvider,
    values: NetDifficulty.values,
    current: (c) => c.read(netslideNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(netslideNotifierProvider.notifier).setDifficulty(tier),
  ),
  'pegs': _enumGame<PegsDifficulty>(
    provider: pegsNotifierProvider,
    values: PegsDifficulty.values,
    current: (c) => c.read(pegsNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(pegsNotifierProvider.notifier).setDifficulty(tier),
  ),
  'same_game': _enumGame<SameGameDifficulty>(
    provider: sameGameNotifierProvider,
    values: SameGameDifficulty.values,
    current: (c) => c.read(sameGameNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(sameGameNotifierProvider.notifier).setDifficulty(tier),
  ),
  'signpost': _enumGame<SignpostDifficulty>(
    provider: signpostNotifierProvider,
    values: SignpostDifficulty.values,
    current: (c) => c.read(signpostNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(signpostNotifierProvider.notifier).setDifficulty(tier),
  ),
  'skyscrapers': _enumGame<SkyscrapersDifficulty>(
    provider: skyscrapersNotifierProvider,
    values: SkyscrapersDifficulty.values,
    current: (c) => c.read(skyscrapersNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(skyscrapersNotifierProvider.notifier).setDifficulty(tier),
  ),
  'tents_and_trees': _enumGame<TentsDifficulty>(
    provider: tentsAndTreesNotifierProvider,
    values: TentsDifficulty.values,
    current: (c) => c.read(tentsAndTreesNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(tentsAndTreesNotifierProvider.notifier).setDifficulty(tier),
  ),
  'twiddle': _enumGame<TwiddleDifficulty>(
    provider: twiddleNotifierProvider,
    values: TwiddleDifficulty.values,
    current: (c) => c.read(twiddleNotifierProvider).difficulty,
    choose: (c, tier) =>
        c.read(twiddleNotifierProvider.notifier).setDifficulty(tier),
  ),
};
