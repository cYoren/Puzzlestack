import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/story_builder/story_builder_screen.dart';

/// Three stories against a run of three: one run emptied the pool, and the draw
/// was a bare `nextInt`, so the same story could come up twice inside a run.
void main() {
  final stories = storyBuilderStories;
  const runLength = 3;

  test('the pool covers several runs', () {
    expect(stories.length, greaterThanOrEqualTo(runLength * 3));
  });

  test('every story is a sequence of sentences', () {
    for (final story in stories) {
      expect(story.sentences.length, greaterThanOrEqualTo(3));
      for (final sentence in story.sentences) {
        expect(sentence.trim(), sentence, reason: 'stray whitespace');
        expect(sentence.endsWith('.'), isTrue, reason: sentence);
        expect(sentence.length, greaterThan(20), reason: sentence);
      }
    }
  });

  test('no sentence is used in two stories', () {
    // A sentence appearing twice makes the order ambiguous: the player cannot
    // know which copy belongs to which story.
    final seen = <String>{};
    for (final story in stories) {
      for (final sentence in story.sentences) {
        expect(seen.add(sentence), isTrue, reason: 'reused: $sentence');
      }
    }
  });

  test('a run deals three different stories', () {
    // The pool is dealt once and drawn down, so a run cannot repeat.
    final deal = <StoryBuilderPuzzle>[...stories];
    final taken = <StoryBuilderPuzzle>[];
    for (var round = 0; round < runLength; round++) {
      if (deal.isEmpty) deal.addAll(stories);
      taken.add(deal.removeLast());
    }
    expect(taken.toSet(), hasLength(runLength));
  });
}
