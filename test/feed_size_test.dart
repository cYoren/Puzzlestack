import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_tiers.dart';
import 'package:puzzle/data/key_value_store.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/game_stats_repository.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/providers/game_stats_provider.dart';
import 'package:puzzle/providers/game_tier_provider.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/feed/feed_session.dart';
import 'package:puzzle/ui/features/games/futoshiki/futoshiki_engine.dart';
import 'package:puzzle/ui/features/games/futoshiki/futoshiki_provider.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_engine.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_provider.dart';
import 'package:puzzle/ui/features/games/minesweeper/minesweeper_provider.dart';
import 'package:puzzle/ui/features/games/nonogram/nonogram_provider.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_provider.dart';
import 'package:puzzle/ui/features/games/word_search/word_search_provider.dart';

class _SeededStatsNotifier extends GameStatsNotifier {
  _SeededStatsNotifier(this._initial);
  final Map<String, GameStat> _initial;

  @override
  Map<String, GameStat> build() => _initial;
}

class _FakeUserRepository extends UserRepository {
  @override
  UserData getUserData() => UserData.initial();

  @override
  Future<void> saveUserData(UserData data) async {}

  @override
  List<GameStreak> getAllGameStreaks() => const [];

  @override
  Future<void> saveGameCompletion(UserData userData, GameStreak streak) async {}
}

void main() {
  tearDown(() {
    while (FeedSession.current != null) {
      FeedSession.deactivate(FeedSession.current!);
    }
  });

  test(
      'ladder games open at easy in the feed without overwriting Stack tier, '
      'and step up after two solves under 120s', () async {
    final MemoryKeyValueStore tierRows = MemoryKeyValueStore();
    await GameTierStore(tierRows).remember('futoshiki', 'hard');

    // Outside the feed: uses remembered Stack tier ('hard').
    final ProviderContainer stackContainer = ProviderContainer(
      overrides: [
        gameTierStoreProvider.overrideWithValue(GameTierStore(tierRows)),
      ],
    );
    addTearDown(stackContainer.dispose);
    expect(
      stackContainer.read(futoshikiNotifierProvider).difficulty,
      FutoshikiDifficulty.hard,
    );

    // Inside the feed with 0 solves: opens at feed tier ('easy', 4x4) and keeps
    // 'hard' untouched in storage.
    final FeedSession feed = FeedSession(
      next: () {},
      restart: () {},
      close: () {},
      isRoute: false,
    );
    FeedSession.activate(feed);

    final ProviderContainer feedContainer = ProviderContainer(
      overrides: [
        gameTierStoreProvider.overrideWithValue(GameTierStore(tierRows)),
      ],
    );
    addTearDown(feedContainer.dispose);
    expect(
      feedContainer.read(futoshikiNotifierProvider).difficulty,
      FutoshikiDifficulty.easy,
    );
    expect(
      feedContainer.read(lightsOutNotifierProvider).difficulty,
      LightsOutDifficulty.easy,
    );
    expect(GameTierStore(tierRows).tierFor('futoshiki'), 'hard');

    // Suspending the feed (when launching from Stack) restores 'hard'.
    final release = FeedSession.suspend();
    feedContainer.read(tierRevisionProvider('futoshiki').notifier).state++;
    expect(
      feedContainer.read(futoshikiNotifierProvider).difficulty,
      FutoshikiDifficulty.hard,
    );
    release();

    // After two timed solves <= 120s, feed steps up one rung to 'medium'.
    final ProviderContainer steppedContainer = ProviderContainer(
      overrides: [
        gameTierStoreProvider.overrideWithValue(GameTierStore(tierRows)),
        gameStatsProvider.overrideWith(
          () => _SeededStatsNotifier({
            'futoshiki': const GameStat(solves: 2, times: [45000, 62000]),
          }),
        ),
      ],
    );
    addTearDown(steppedContainer.dispose);
    expect(
      steppedContainer.read(futoshikiNotifierProvider).difficulty,
      FutoshikiDifficulty.medium,
    );
  });

  test(
      'classic generators use feed sizes inside FeedSession and full sizes outside',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final FeedSession feed = FeedSession(
      next: () {},
      restart: () {},
      close: () {},
      isRoute: false,
      seedFor: (_) => 12345,
    );
    FeedSession.activate(feed);

    final ProviderContainer inFeed = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
      ],
    );
    addTearDown(inFeed.dispose);

    inFeed.listen(sudokuNotifierProvider, (_, __) {}, fireImmediately: true);
    inFeed.listen(nonogramNotifierProvider, (_, __) {}, fireImmediately: true);
    inFeed.listen(
      minesweeperNotifierProvider,
      (_, __) {},
      fireImmediately: true,
    );
    inFeed.listen(
      wordSearchNotifierProvider,
      (_, __) {},
      fireImmediately: true,
    );

    final SudokuState sudokuFeed =
        await inFeed.read(sudokuNotifierProvider.future);
    expect(sudokuFeed.currentBoard.length, 4);

    // Sudoku hint fills one cell cleanly.
    final int beforeZeros =
        sudokuFeed.currentBoard.expand((r) => r).where((v) => v == 0).length;
    inFeed.read(sudokuNotifierProvider.notifier).hint();
    final int afterZeros = inFeed
        .read(sudokuNotifierProvider)
        .value!
        .currentBoard
        .expand((r) => r)
        .where((v) => v == 0)
        .length;
    expect(afterZeros, beforeZeros - 1);

    final NonogramState nonogramFeed =
        await inFeed.read(nonogramNotifierProvider.future);
    expect(nonogramFeed.size, 5);

    final MinesweeperState minesFeed = inFeed.read(minesweeperNotifierProvider);
    expect(minesFeed.rows, 6);
    expect(minesFeed.cols, 6);
    expect(minesFeed.minesRemaining, 5);

    await inFeed.read(wordSearchNotifierProvider.notifier).initGame();
    final WordSearchState wsFeed = inFeed.read(wordSearchNotifierProvider);
    expect(wsFeed.board!.size, 6);
    expect(wsFeed.board!.words.length, lessThanOrEqualTo(4));

    // Deactivating feed restores Stack sizes.
    FeedSession.deactivate(feed);
    final ProviderContainer inStack = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
      ],
    );
    addTearDown(inStack.dispose);
    final MinesweeperState minesStack =
        inStack.read(minesweeperNotifierProvider);
    expect(minesStack.rows, 10);
    expect(minesStack.cols, 8);
    expect(minesStack.minesRemaining, 12);
  });
}
