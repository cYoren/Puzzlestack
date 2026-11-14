import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/word_grid_connection/word_grid_connection_screen.dart';

/// Twelve categories, four to a board: a player saw every category three boards
/// in. Worse than the repetition, a word in two categories (ORANGE is a fruit
/// and a colour) makes a board with two right answers.
void main() {
  final categories = wordGridCategories;

  test('the pool outlasts a session', () {
    expect(categories.length, greaterThanOrEqualTo(30));
  });

  test('every category is a group of at least four words', () {
    for (final category in categories) {
      expect(category.title, category.title.toUpperCase());
      expect(category.words.length, greaterThanOrEqualTo(4), reason: category.title);
      expect(category.words.toSet(), hasLength(category.words.length),
          reason: '${category.title} lists a word twice');
      for (final word in category.words) {
        expect(RegExp(r'^[A-Z]+$').hasMatch(word), isTrue,
            reason: '${category.title}: $word');
      }
    }
  });

  test('no category repeats, and no word belongs to two', () {
    final titles = categories.map((category) => category.title).toList();
    expect(titles.toSet(), hasLength(titles.length));
    final owners = <String, String>{};
    for (final category in categories) {
      for (final word in category.words) {
        final owner = owners[word];
        expect(owner == null || owner == category.title, isTrue,
            reason: '$word is in both $owner and ${category.title}, '
                'so a board could group it either way');
        owners[word] = category.title;
      }
    }
  });
}
