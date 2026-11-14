import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/matrix_reasoning/matrix_reasoning_engine.dart';

void main() {
  group('MatrixReasoningEngine', () {
    late MatrixReasoningEngine engine;

    setUp(() {
      engine = MatrixReasoningEngine();
    });

    group('generatePuzzle', () {
      test('returns a puzzle with cells, answer, options, and missingIndex', () {
        final puzzle = engine.generatePuzzle();
        expect(puzzle.cells.length, equals(9));
        expect(puzzle.answer, isNotNull);
        expect(puzzle.options.length, equals(4));
        expect(puzzle.missingIndex, inInclusiveRange(0, 8));
      });

      test('options contain 4 unique cells', () {
        for (int i = 0; i < 20; i++) {
          final puzzle = engine.generatePuzzle();
          expect(puzzle.options.length, equals(4));
          final keys = {
            for (final option in puzzle.options)
              '${option.shape.codePoint}:${option.color.toARGB32()}',
          };
          expect(keys.length, equals(4), reason: 'two options are the same cell');
        }
      });

      test('every wrong option is one attribute away from the answer', () {
        for (final level in [0, 1, 2]) {
          for (int i = 0; i < 10; i++) {
            final puzzle = engine.generatePuzzle(level: level);
            for (final option in puzzle.options) {
              final sameShape = option.shape == puzzle.answer.shape;
              final sameColour = option.color == puzzle.answer.color;
              // The answer itself, or exactly one attribute shared with it.
              expect(
                sameShape || sameColour,
                isTrue,
                reason: 'a distractor shares nothing with the answer',
              );
            }
          }
        }
      });

      test('hard boards are Latin squares across rows and columns', () {
        for (int i = 0; i < 10; i++) {
          final puzzle = engine.generatePuzzle(level: 2);
          for (var row = 0; row < 3; row++) {
            final shapes = {
              for (var col = 0; col < 3; col++) puzzle.cells[row * 3 + col].shape,
            };
            expect(shapes.length, equals(3), reason: 'row \$row repeats a shape');
          }
          for (var col = 0; col < 3; col++) {
            final colours = {
              for (var row = 0; row < 3; row++) puzzle.cells[row * 3 + col].color,
            };
            expect(colours.length, equals(3), reason: 'column \$col repeats a colour');
          }
        }
      });

      test('answer is one of the options', () {
        for (int i = 0; i < 20; i++) {
          final puzzle = engine.generatePuzzle();
          final found = puzzle.options.any((o) =>
              o.shape == puzzle.answer.shape && o.color == puzzle.answer.color);
          expect(found, isTrue);
        }
      });

      test('cells have shape and color', () {
        final puzzle = engine.generatePuzzle();
        for (final cell in puzzle.cells) {
          expect(cell.shape, isNotNull);
          expect(cell.color, isNotNull);
        }
      });
    });

    group('MatrixCell', () {
      test('stores shape and color', () {
        final cell = MatrixCell(shape: MatrixReasoningEngine().generatePuzzle().cells[0].shape, color: MatrixReasoningEngine().generatePuzzle().cells[0].color);
        expect(cell.shape, isNotNull);
        expect(cell.color, isNotNull);
      });
    });
  });
}
