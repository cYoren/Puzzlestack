import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/category_fluency/category_fluency_engine.dart';

/// Five categories meant a player who liked the game saw the same five names.
/// A category is cheap to write and a run consumes one, so the pool should be
/// three times the runs before anything repeats.
void main() {
  final engine = CategoryFluencyEngine();
  final categories = engine.categories;

  test('there are enough categories for six runs', () {
    expect(categories.length, greaterThanOrEqualTo(10));
  });

  test('every category can be answered', () {
    for (final category in categories) {
      expect(category.name.trim(), isNotEmpty);
      expect(category.items.length, greaterThanOrEqualTo(20),
          reason: '${category.name} has ${category.items.length} items');
    }
  });

  test('no category is listed twice', () {
    final names = categories.map((c) => c.name).toList();
    expect(names.toSet(), hasLength(names.length));
  });

  test('items are lowercase and trimmed, so a typed answer matches', () {
    for (final category in categories) {
      for (final item in category.items) {
        expect(item, item.toLowerCase().trim(),
            reason: '${category.name}: "$item" would never match');
        expect(item.trim(), isNotEmpty);
      }
    }
  });

  test('the engine accepts a listed item and rejects a stranger', () {
    final category = categories.first;
    final item = category.items.first;
    expect(engine.isValidItem('  ${item.toUpperCase()} ', category), isTrue);
    expect(engine.isValidItem('not a real answer 123', category), isFalse);
  });
}
