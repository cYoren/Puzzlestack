import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/core/board/puzzle_board.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_board.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_provider.dart';

const Color red = Color(0xFFEF4444);
const Color blue = Color(0xFF3B82F6);

WaterSortState _state() => WaterSortState(
      tubes: [
        [red, blue],
        [blue],
        [red],
        [],
      ],
    );

void main() {
  group('WaterSortBoard', () {
    test('every tube is an element with bounds', () {
      final board = WaterSortBoard(state: _state());
      expect(board.elements, hasLength(4));
      for (final element in board.elements) {
        expect(board.boundsOf(element), isNotNull);
      }
    });

    test('every tube sits inside the board box and none overlap', () {
      final board = WaterSortBoard(state: _state());
      final rects = board.elements.map((e) => board.boundsOf(e)!).toList();
      for (final rect in rects) {
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(1.0));
        expect(rect.bottom, lessThanOrEqualTo(1.0));
      }
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(rects[i].overlaps(rects[j]), isFalse,
              reason: 'tube $i overlaps tube $j');
        }
      }
    });

    test('a pour is offered only where the colours match', () {
      final board = WaterSortBoard(state: _state());
      final targets = board
          .movesFor(WaterSortBoard.tube(0))
          .map((move) => move.target)
          .toList();

      expect(targets, contains(WaterSortBoard.tube(1)),
          reason: 'blue onto blue');
      expect(targets, contains(WaterSortBoard.tube(3)), reason: 'into empty');
      expect(targets, isNot(contains(WaterSortBoard.tube(2))),
          reason: 'blue onto red is illegal');
      expect(targets, isNot(contains(WaterSortBoard.tube(0))),
          reason: 'a tube cannot pour into itself');
    });

    test('applying a pour moves the whole matching run', () {
      final board = WaterSortBoard(state: _state());
      final move = board
          .movesFor(WaterSortBoard.tube(0))
          .firstWhere((m) => m.target == WaterSortBoard.tube(1));

      final next = board.apply(board.state, move);
      expect(next.tubes[0], [red]);
      expect(next.tubes[1], [blue, blue]);
      expect(next.selectedTubeIndex, isNull);
    });

    test('tapping picks up a tube, then pours into another', () {
      final board = WaterSortBoard(state: _state());
      final picked = board.apply(
        board.state,
        board.tapMove(WaterSortBoard.tube(0))!,
      );
      expect(picked.selectedTubeIndex, 0);

      final pour = WaterSortBoard(state: picked)
          .tapMove(WaterSortBoard.tube(1))!;
      expect(pour.kind, MoveKind.place);

      final next = WaterSortBoard(state: picked).apply(picked, pour);
      expect(next.tubes[1], [blue, blue]);
    });

    test('an empty tube cannot be picked up', () {
      final board = WaterSortBoard(state: _state());
      expect(board.tapMove(WaterSortBoard.tube(3)), isNull);
    });
  });
}
