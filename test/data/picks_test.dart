import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/key_value_store.dart';
import 'package:puzzle/data/picks/pick_gate.dart';
import 'package:puzzle/data/picks/pick_ledger.dart';

/// The pick rule, played out day by day.
///
/// Everything here is the app's own data layer with a clock and a store poser,
/// because the rule is one function and a screen that repeated it would be the
/// fifth place it could disagree with itself.
void main() {
  late MemoryKeyValueStore rows;
  late DateTime now;
  bool plus = false;

  PickGate gate() => PickGate(
        ledger: PickLedger(rows, now: () => now),
        hasPlus: () => plus,
      );

  setUp(() {
    rows = MemoryKeyValueStore();
    now = DateTime(2026, 11, 16, 10, 30);
    plus = false;
  });

  group('the free allowance', () {
    test('the first play of a game is free, and does not spend a pick',
        () async {
      final PickGate picks = gate();

      expect(await picks.request('sudoku'),
          const PickAllowed(PickReason.firstPlay));
      expect(await picks.request('nonogram'),
          const PickAllowed(PickReason.firstPlay));
      expect(await picks.request('akari'),
          const PickAllowed(PickReason.firstPlay));

      // Three first plays were free; today's counter is still untouched.
      expect((await PickLedger(rows, now: () => now).today()).used, 0);
      expect(await picks.request('hitori'),
          const PickAllowed(PickReason.firstPlay));
    });

    test('re-opening a game you have already played costs one of three',
        () async {
      final PickGate picks = gate();
      await picks.request('sudoku'); // first play, free

      expect(await picks.request('sudoku'),
          const PickAllowed(PickReason.freeAllowance));
      expect(await picks.request('sudoku'),
          const PickAllowed(PickReason.freeAllowance));
      expect(await picks.request('sudoku'),
          const PickAllowed(PickReason.freeAllowance));
      expect(await picks.request('sudoku'),
          const PickRefused(usedToday: 3, freePerDay: 3));
    });

    test('a refusal spends nothing and says exactly how many were used',
        () async {
      final PickGate picks = gate();
      await picks.request('sudoku');
      for (var i = 0; i < 3; i++) {
        await picks.request('sudoku');
      }

      expect(await picks.request('sudoku'),
          const PickRefused(usedToday: 3, freePerDay: 3));
      expect(await picks.request('sudoku'),
          const PickRefused(usedToday: 3, freePerDay: 3),
          reason: 'asking twice must not cost two picks');
      expect((await PickLedger(rows, now: () => now).today()).used, 3);
    });

    test('the first play of a new game is still free when picks are gone',
        () async {
      final PickGate picks = gate();
      await picks.request('sudoku');
      for (var i = 0; i < 3; i++) {
        await picks.request('sudoku');
      }

      expect(await picks.request('nonogram'),
          const PickAllowed(PickReason.firstPlay),
          reason:
              'the free first play is the promise that the app stays usable');
    });
  });

  group('a zero means one thing', () {
    test('no picks used is not "out of picks"', () async {
      const PickDay today = PickDay(day: '2026-11-16');
      expect(today.used, 0);
      expect(today.remaining, 3);
      expect(today.exhausted, isFalse);
    });

    test('a row from another day reads as today with nothing used', () async {
      rows = MemoryKeyValueStore({
        PickLedger.dayKey: {'day': '2026-11-15', 'used': 3},
      });
      final PickDay today = await PickLedger(rows, now: () => now).today();
      expect(today.used, 0);
      expect(today.day, '2026-11-16');
    });

    test('a missing or corrupt row is today with nothing used', () async {
      expect(
          (await PickLedger(MemoryKeyValueStore(), now: () => now).today())
              .used,
          0);
      rows = MemoryKeyValueStore({PickLedger.dayKey: 'nonsense'});
      expect((await PickLedger(rows, now: () => now).today()).used, 0);
      rows = MemoryKeyValueStore({
        PickLedger.dayKey: {'day': '2026-11-16', 'used': -5},
      });
      expect((await PickLedger(rows, now: () => now).today()).used, 0);
    });
  });

  group('Plus', () {
    test('lifts the count entirely', () async {
      plus = true;
      final PickGate picks = gate();
      await picks.request('sudoku');

      for (var i = 0; i < 20; i++) {
        expect(
            await picks.request('sudoku'), const PickAllowed(PickReason.plus));
      }
    });

    test('is read at the moment of the pick, not cached', () async {
      final PickGate picks = gate();
      await picks.request('sudoku');
      for (var i = 0; i < 3; i++) {
        await picks.request('sudoku');
      }
      expect(await picks.request('sudoku'), isA<PickRefused>());

      plus = true;
      expect(await picks.request('sudoku'), const PickAllowed(PickReason.plus));
    });

    test('does not spend the free allowance while it is on', () async {
      plus = true;
      final PickGate picks = gate();
      await picks.request('sudoku');
      await picks.request('sudoku');
      expect((await PickLedger(rows, now: () => now).today()).used, 0);
    });
  });

  group('a new day', () {
    test('gives the three picks back', () async {
      final PickGate picks = gate();
      await picks.request('sudoku');
      for (var i = 0; i < 3; i++) {
        await picks.request('sudoku');
      }
      expect(await picks.request('sudoku'), isA<PickRefused>());

      now = DateTime(2026, 11, 17, 0, 1);
      expect(await picks.request('sudoku'),
          const PickAllowed(PickReason.freeAllowance));
      expect((await PickLedger(rows, now: () => now).today()).used, 1);
    });

    test('never carries yesterday\'s count across midnight', () async {
      final PickLedger ledger = PickLedger(rows, now: () => now);
      await ledger.spend();
      await ledger.spend();
      await ledger.spend();
      expect((await ledger.today()).used, 3);

      now = DateTime(2026, 11, 17, 0, 0, 1);
      expect((await ledger.today()).used, 0);
      // The rollover is written, not just returned.
      expect(
        (rows.read(PickLedger.dayKey) as Map)['used'],
        0,
      );
    });

    test('keeps remembering which games were played', () async {
      final PickGate picks = gate();
      await picks.request('sudoku');
      for (var i = 0; i < 3; i++) {
        await picks.request('sudoku');
      }

      now = DateTime(2026, 11, 17, 9);
      // Still a game that has been opened before, so it costs a pick rather
      // than being free again.
      expect(await picks.request('sudoku'),
          const PickAllowed(PickReason.freeAllowance));
    });
  });

  group('asking is not spending', () {
    test('a preview the player walks away from costs nothing', () async {
      final PickGate picks = gate();

      // The size chooser opens before the board; the player closes it. Twice.
      expect(await picks.preview('sudoku'),
          const PickAllowed(PickReason.firstPlay));
      expect(await picks.preview('sudoku'),
          const PickAllowed(PickReason.firstPlay));

      final PickLedger ledger = PickLedger(rows, now: () => now);
      expect(ledger.hasOpened('sudoku'), isFalse,
          reason: 'a game whose board never opened was never played');
      expect((await ledger.today()).used, 0);

      // And the free first play is still there when the player does open it.
      expect(await picks.request('sudoku'),
          const PickAllowed(PickReason.firstPlay));
      expect(await picks.request('sudoku'),
          const PickAllowed(PickReason.freeAllowance));
    });

    test('a pick is charged once, when the opening is committed', () async {
      final PickGate picks = gate();
      await picks.request('sudoku'); // first play, remembered

      final PickDecision decision = await picks.preview('sudoku');
      expect(decision, const PickAllowed(PickReason.freeAllowance));
      expect((await PickLedger(rows, now: () => now).today()).used, 0,
          reason: 'nothing is spent until the board opens');

      await picks.commit('sudoku', decision);
      expect((await PickLedger(rows, now: () => now).today()).used, 1);
    });

    test('committing a refusal, and Plus, writes nothing', () async {
      final PickGate picks = gate();
      await picks.request('sudoku'); // first play, remembered
      for (int i = 0; i < freePicksPerDay; i++) {
        await picks.commit('sudoku', await picks.preview('sudoku'));
      }
      expect((await PickLedger(rows, now: () => now).today()).used, 3);

      final PickDecision refused = await picks.preview('sudoku');
      expect(refused, isA<PickRefused>());
      await picks.commit('sudoku', refused);
      expect((await PickLedger(rows, now: () => now).today()).used, 3,
          reason: 'a refusal spends nothing');

      plus = true;
      await picks.commit('sudoku', await picks.preview('sudoku'));
      expect((await PickLedger(rows, now: () => now).today()).used, 3,
          reason: 'a Plus opening costs no pick');
      expect(await picks.preview('sudoku'),
          const PickAllowed(PickReason.plus));
    });
  });

  group('persistence', () {
    test('a relaunch remembers today\'s picks and the games opened', () async {
      final PickGate before = gate();
      await before.request('sudoku');
      await before.request('sudoku');

      final PickGate after = gate();
      expect(await after.request('sudoku'),
          const PickAllowed(PickReason.freeAllowance));
      expect(await after.request('sudoku'),
          const PickAllowed(PickReason.freeAllowance));
      expect(await after.request('sudoku'),
          const PickRefused(usedToday: 3, freePerDay: 3));
    });
  });
}
