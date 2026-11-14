import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/typoglycemia_decoder/typoglycemia_decoder_screen.dart';

/// Ten sentences, one per run -- and all ten were about typoglycemia itself,
/// one of them citing a Cambridge study this app cannot point to. Meta filler
/// shipped as content.
void main() {
  final sentences = typoglycemiaSentences;

  test('the pool outlasts a session', () {
    expect(sentences.length, greaterThanOrEqualTo(24));
  });

  test('every sentence is prose a reader could meet anywhere', () {
    for (final sentence in sentences) {
      expect(sentence.trim(), sentence, reason: 'leading or trailing space');
      expect(sentence.length, greaterThanOrEqualTo(30), reason: sentence);
      expect(sentence.length, lessThanOrEqualTo(90), reason: sentence);
      expect(sentence.endsWith('.'), isTrue, reason: sentence);
      expect(sentence.contains('  '), isFalse, reason: sentence);
      expect(RegExp(r'^[A-Za-z0-9 ,.\-]+$').hasMatch(sentence), isTrue,
          reason: sentence);
      // Scrambling only works on words long enough to have an inside.
      final words = sentence.replaceAll('.', '').split(' ');
      expect(words.where((word) => word.length >= 4).length,
          greaterThanOrEqualTo(4),
          reason: 'not enough words to scramble: $sentence');
    }
  });

  test('no sentence is offered twice', () {
    expect(sentences.toSet(), hasLength(sentences.length));
  });

  test('the pool does not talk about the game', () {
    // The old pool was ten sentences about typoglycemia, every one of them
    // about reading scrambled words. That is the app describing itself.
    for (final sentence in sentences) {
      final lower = sentence.toLowerCase();
      expect(lower.contains('typoglycemia'), isFalse, reason: sentence);
      expect(lower.contains('jumbled'), isFalse, reason: sentence);
      expect(lower.contains('scrambled'), isFalse, reason: sentence);
      expect(lower.contains('research at cambridge'), isFalse, reason: sentence);
    }
  });
}
