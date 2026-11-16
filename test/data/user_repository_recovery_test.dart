import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';

/// The store moved engines (`hive` -> `hive_ce`), so the first launch after the
/// upgrade is the first time this app has ever read those boxes with the new
/// code. If they cannot be read, the app must still start.
///
/// These two tests are the rule in both directions: unreadable data recovers,
/// and readable data is never touched.
void main() {
  late Directory dir;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('puzzlestack-recovery');
    Hive.init(dir.path);
    // `main.dart` registers these at startup; a test that opens the same boxes
    // has to do the same or every write is an unknown type.
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserDataAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(GameStreakAdapter());
  });

  tearDown(() async {
    await Hive.close();
    for (final file in dir.listSync()) {
      if (file is File) file.deleteSync();
      if (file is Directory) file.deleteSync(recursive: true);
    }
    Hive.init(dir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('a box that cannot be decoded does not stop the app starting', () async {
    // A real box file with bytes no adapter can read, which is what a store
    // written by a different engine would look like.
    File('${dir.path}/user_data.hive')
        .writeAsBytesSync(List<int>.generate(64, (i) => 0x7F ^ i));

    final repository = UserRepository();
    await repository.init();

    // Started clean rather than throwing, and usable: a save survives a reopen.
    expect(repository.getUserData().xp, UserData.initial().xp);
    await repository.saveUserData(UserData.initial().copyWith(xp: 42));
    await Hive.close();
    Hive.init(dir.path);
    final reopened = UserRepository();
    await reopened.init();
    expect(reopened.getUserData().xp, 42);
  });

  test('a healthy store is preserved across a reopen', () async {
    final repository = UserRepository();
    await repository.init();
    await repository.saveUserData(UserData.initial().copyWith(xp: 7));
    await Hive.box<GameStreak>(UserRepository.gameStreakBoxName).put(
      'pegs',
      GameStreak(
        gameId: 'pegs',
        currentStreak: 3,
        lastSolvedDate: DateTime(2026),
        solvedToday: true,
      ),
    );

    await Hive.close();
    Hive.init(dir.path);

    final reopened = UserRepository();
    await reopened.init();
    expect(reopened.getUserData().xp, 7);
    expect(
      Hive.box<GameStreak>(UserRepository.gameStreakBoxName)
          .get('pegs')
          ?.currentStreak,
      3,
    );
  });
}
