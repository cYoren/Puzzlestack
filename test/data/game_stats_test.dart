import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/repositories/game_stats_repository.dart';

void main() {
  group('GameStat', () {
    test('a fresh record has no best time and no percentile', () {
      const stat = GameStat();
      expect(stat.bestMs, isNull);
      expect(stat.fasterThan, isNull);
    });

    test('percentile needs three solves before it says anything', () {
      final stat = const GameStat().record(9000).record(7000);
      expect(stat.fasterThan, isNull);
      final third = stat.record(5000);
      expect(third.fasterThan, isNotNull);
      // 5000 beats both earlier times, but is not faster than itself.
      expect(third.fasterThan, equals(67));
    });

    test('assisted solves are counted, never hidden', () {
      final stat = const GameStat().record(4000, assisted: true);
      expect(stat.solves, 1);
      expect(stat.assisted, 1);
    });

    test('the history is capped', () {
      var stat = const GameStat();
      for (var i = 0; i < GameStat.maxTimes + 10; i++) {
        stat = stat.record(1000 + i);
      }
      expect(stat.times.length, equals(GameStat.maxTimes));
      expect(stat.solves, equals(GameStat.maxTimes + 10));
    });

    test('a corrupt row decodes to an empty record instead of throwing', () {
      expect(GameStat.fromJson(null).solves, 0);
      expect(GameStat.fromJson('nonsense').solves, 0);
      expect(
        GameStat.fromJson({
          'solves': -4,
          'assisted': 'x',
          'times': [0, -1, 5000, 'nope'],
        }).times,
        equals([5000]),
      );
    });
  });
}
