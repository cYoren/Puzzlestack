import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/room_inspector/room_inspector_screen.dart';

/// Eight objects on a 3x3 board: five shown, one swapped for a sixth, so the
/// same eight were the whole memory game.
void main() {
  final objects = roomInspectorObjects;

  test('the pool is big enough that a round is a memory test', () {
    // Five placed, one swapped in, and the swap needs a sixth the board does
    // not already show.
    expect(objects.length, greaterThanOrEqualTo(24));
  });

  test('every object has a label and its own icon', () {
    final labels = objects.map((object) => object.label).toList();
    final icons = objects.map((object) => object.icon).toList();
    expect(labels.toSet(), hasLength(labels.length),
        reason: 'two objects share a label');
    expect(icons.toSet(), hasLength(icons.length),
        reason: 'two objects share an icon, and the swap picks by icon');
    for (final label in labels) {
      expect(RegExp(r'^[A-Z]+$').hasMatch(label), isTrue, reason: label);
    }
  });
}
