import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/kakurasu_sums/kakurasu_sums_screen.dart';

void main() {
  group('KakurasuSumsScreen', () {
    test('countSolutions verifies unique fallback and counts ambiguous sums', () {
      expect(
        KakurasuSumsScreen.countSolutions([9, 10, 10, 6], [9, 10, 10, 6], limit: 2),
        1,
      );
      // Symmetric row/column targets [5, 5, 5, 5] admit multiple solutions.
      expect(
        KakurasuSumsScreen.countSolutions([5, 5, 5, 5], [5, 5, 5, 5], limit: 2),
        2,
      );
    });
  });
}
