import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/user_data.dart';
import '../models/game_streak.dart';

class UserRepository {
  static const String userDataBoxName = 'user_data';
  static const String gameStreakBoxName = 'game_streaks';
  static const String _metaBoxName = 'app_meta';
  static const String _versionKey = 'schema_version';
  static const int _currentSchemaVersion = 1;

  Future<void> init() async {
    try {
      await _openBoxes();
    } on FileSystemException catch (error) {
      // A disk problem is not a broken store: the data may be perfectly
      // readable once there is space to write. Deleting it here would turn a
      // full disk into lost progress, so this one is rethrown untouched.
      debugPrint('UserRepository: storage unavailable ($error)');
      rethrow;
    } on Object catch (error) {
      // The local store moved to the maintained fork of the same engine
      // (`hive` -> `hive_ce`): same typeIds, same field indices, same binary
      // layout, so a box written by the old engine is expected to read. "Expect"
      // is not "know", and the failure mode if it does not is a crash loop at
      // launch, which is the worst possible shape for a data problem. So the
      // box is set aside once and the app starts clean instead of never
      // starting; a player loses a streak rather than the whole app.
      debugPrint(
        'UserRepository: stored data could not be read, starting '
        'fresh ($error)',
      );
      await _setAsideUnreadableBoxes();
      await _openBoxes();
    }
    await _tidyUp();
  }

  /// Compaction and the schema version are housekeeping. Nothing in here is
  /// allowed to delete anything: a failure leaves the boxes exactly as they
  /// were, which is the difference between a full disk and lost progress.
  Future<void> _tidyUp() async {
    try {
      final userBox = Hive.box<UserData>(userDataBoxName);
      final streakBox = Hive.box<GameStreak>(gameStreakBoxName);
      final metaBox = Hive.box(_metaBoxName);
      await userBox.compact();
      await streakBox.compact();
      final version = metaBox.get(_versionKey, defaultValue: 0) as int;
      if (version < _currentSchemaVersion) {
        _validateExistingData(userBox, streakBox);
        await metaBox.put(_versionKey, _currentSchemaVersion);
      }
    } on FileSystemException catch (error) {
      debugPrint('UserRepository: housekeeping skipped ($error)');
    }
  }

  /// Deletes the three boxes so the next open starts empty.
  ///
  /// Deliberately not silent: the message above is the only trace, and it names
  /// the error.
  Future<void> _setAsideUnreadableBoxes() async {
    for (final name in [userDataBoxName, gameStreakBoxName, _metaBoxName]) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } on Object catch (error) {
        debugPrint('UserRepository: could not clear $name ($error)');
      }
    }
  }

  /// Opens the three boxes. A throw here means the stored bytes cannot be read
  /// as this app's types: that is the only failure allowed to lose data.
  Future<void> _openBoxes() async {
    await Hive.openBox<UserData>(userDataBoxName);
    await Hive.openBox<GameStreak>(gameStreakBoxName);
    await Hive.openBox(_metaBoxName);
  }

  void _validateExistingData(Box<UserData> userBox, Box<GameStreak> streakBox) {
    final userData = userBox.get('current');
    if (userData != null && !userData.isValid) {
      userBox.put('current', userData.sanitized());
    }

    for (final streak in streakBox.values) {
      if (!streak.isValid) {
        streakBox.put(streak.gameId, streak.sanitized());
      }
    }
  }

  UserData getUserData() {
    try {
      final box = Hive.box<UserData>(userDataBoxName);
      final data = box.get('current', defaultValue: UserData.initial())!;
      return data.isValid ? data : data.sanitized();
    } catch (e) {
      debugPrint('getUserData error: $e');
      return UserData.initial();
    }
  }

  Future<void> saveUserData(UserData data) async {
    try {
      final box = Hive.box<UserData>(userDataBoxName);
      await box.put('current', data.isValid ? data : data.sanitized());
    } catch (e) {
      debugPrint('saveUserData error: $e');
      rethrow;
    }
  }

  List<GameStreak> getAllGameStreaks() {
    try {
      final box = Hive.box<GameStreak>(gameStreakBoxName);
      return box.values.where((s) => s.isValid).toList();
    } catch (e) {
      debugPrint('getAllGameStreaks error: $e');
      return [];
    }
  }

  GameStreak getGameStreak(String gameId) {
    try {
      final box = Hive.box<GameStreak>(gameStreakBoxName);
      final streak = box.get(gameId, defaultValue: GameStreak.initial(gameId))!;
      return streak.isValid ? streak : streak.sanitized();
    } catch (e) {
      debugPrint('getGameStreak error: $e');
      return GameStreak.initial(gameId);
    }
  }

  Future<void> saveGameStreak(GameStreak streak) async {
    try {
      final box = Hive.box<GameStreak>(gameStreakBoxName);
      await box.put(
        streak.gameId,
        streak.isValid ? streak : streak.sanitized(),
      );
    } catch (e) {
      debugPrint('saveGameStreak error: $e');
      rethrow;
    }
  }

  Future<void> saveAllGameStreaks(List<GameStreak> streaks) async {
    try {
      final box = Hive.box<GameStreak>(gameStreakBoxName);
      final validStreaks = streaks.where((s) => s.isValid);
      final streakMap = {for (var s in validStreaks) s.gameId: s};
      await box.putAll(streakMap);
    } catch (e) {
      debugPrint('saveAllGameStreaks error: $e');
      rethrow;
    }
  }

  Future<void> saveGameCompletion(UserData userData, GameStreak streak) async {
    try {
      final userBox = Hive.box<UserData>(userDataBoxName);
      final streakBox = Hive.box<GameStreak>(gameStreakBoxName);
      await Future.wait([
        userBox.put(
          'current',
          userData.isValid ? userData : userData.sanitized(),
        ),
        streakBox.put(
          streak.gameId,
          streak.isValid ? streak : streak.sanitized(),
        ),
      ]);
    } catch (e) {
      debugPrint('saveGameCompletion error: $e');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    try {
      await Hive.box<UserData>(userDataBoxName).clear();
      await Hive.box<GameStreak>(gameStreakBoxName).clear();
    } catch (e) {
      debugPrint('clearAll error: $e');
      rethrow;
    }
  }
}
