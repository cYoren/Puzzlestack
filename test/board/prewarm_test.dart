/// The board a tap asks for already exists when the tap happens.
///
/// Salad's generator costs about 12ms at 5x5 and 270ms at 7x7 (measured on this
/// machine), and it used to run on the tap: "play again" and a size chip froze
/// the screen. The fix is [NextBoard], a one-board-per-key cache built after the
/// board on screen has been painted. These tests watch the cache's own count:
/// the number of boards a game has built may not move between a tap and the
/// state that tap writes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/next_board.dart';
import 'package:puzzle/ui/features/games/mathrax/mathrax_provider.dart';
import 'package:puzzle/ui/features/games/mathrax/mathrax_puzzle.dart';
import 'package:puzzle/ui/features/games/salad/salad_provider.dart';
import 'package:puzzle/ui/features/games/salad/salad_puzzle.dart';

/// A widget that hands the test a live [WidgetRef], so a notifier can be read
/// out of the same container the frames are pumping.
class _Harness extends ConsumerWidget {
  const _Harness(this.onRef);

  final void Function(WidgetRef ref) onRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched, so both notifiers are created inside a frame: the warm-up is a
    // post-frame callback, and a provider first read from the test body would
    // register one for a frame nobody is going to draw.
    ref.watch(saladNotifierProvider);
    ref.watch(mathraxNotifierProvider);
    onRef(ref);
    return const SizedBox.shrink();
  }
}

void main() {
  testWidgets('the cache builds after the frame and take() then takes it',
      (tester) async {
    final board = NextBoard<int, String>((key) => 'board $key');
    addTearDown(board.dispose);

    // Nothing is ready, so the first take pays for the board.
    expect(board.take(1), 'board 1');
    expect(board.built, 1);

    board.fill([1, 2, 3], first: 2);
    // The warm-up runs after a frame, not inside `fill`, and it builds every
    // key at once so a chip tapped on the next frame cannot miss.
    expect(board.built, 1, reason: 'fill() must not generate inside the tap');
    await tester.pumpWidget(const SizedBox.shrink());
    expect(board.built, 4, reason: 'a board for every key');

    expect(board.take(2), 'board 2');
    expect(board.take(3), 'board 3');
    expect(board.built, 4, reason: 'a ready board must not be rebuilt');
  });

  testWidgets('salad: play again and a size chip take the board made ahead',
      (tester) async {
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(child: _Harness((live) => ref = live)),
    );
    // The frame that showed the board is the one the warm-up waited for.
    await tester.pump();

    final medium = ref.read(saladNotifierProvider);
    expect(medium.size, SaladSize.medium);

    final notifier = ref.read(saladNotifierProvider.notifier);
    expect(notifier.boardsBuilt, SaladSize.values.length + 1,
        reason: 'the board on screen plus one waiting for each size');

    // Play again. The count is read *before* any frame goes by: the tap itself
    // must not generate anything.
    final builtBefore = notifier.boardsBuilt;
    notifier.newGame();
    expect(notifier.boardsBuilt, builtBefore,
        reason: 'play again generated a board on the tap');
    final played = ref.read(saladNotifierProvider);
    expect(played.size, SaladSize.medium);
    expect(played.puzzle, isNot(medium.puzzle));

    // Let the warm-up for the board after this one run.
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(notifier.boardsBuilt, builtBefore + 1,
        reason: 'the board after play again should be made ahead');

    // A size chip is the same promise, including the 7x7.
    final builtBeforeChip = notifier.boardsBuilt;
    notifier.setSize(SaladSize.large);
    expect(notifier.boardsBuilt, builtBeforeChip,
        reason: 'the 7x7 chip generated a board on the tap');
    expect(ref.read(saladNotifierProvider).size, SaladSize.large);
  });

  testWidgets('mathrax: play again and a size chip take the board made ahead',
      (tester) async {
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(child: _Harness((live) => ref = live)),
    );
    await tester.pump();

    final medium = ref.read(mathraxNotifierProvider);
    expect(medium.size, MathraxSize.medium);

    final notifier = ref.read(mathraxNotifierProvider.notifier);
    expect(notifier.boardsBuilt, MathraxSize.values.length + 1,
        reason: 'the board on screen plus one waiting for each size');

    final builtBefore = notifier.boardsBuilt;
    notifier.newGame();
    expect(notifier.boardsBuilt, builtBefore,
        reason: 'play again generated a board on the tap');
    final played = ref.read(mathraxNotifierProvider);
    expect(played.size, MathraxSize.medium);
    expect(played.puzzle, isNot(medium.puzzle));

    final builtBeforeChip = notifier.boardsBuilt;
    notifier.setSize(MathraxSize.large);
    expect(notifier.boardsBuilt, builtBeforeChip,
        reason: 'the size chip generated a board on the tap');
    expect(ref.read(mathraxNotifierProvider).size, MathraxSize.large);
  });
}
