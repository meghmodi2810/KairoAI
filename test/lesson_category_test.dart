import 'package:flutter_test/flutter_test.dart';
import 'package:kairo_ai/models/lesson_category.dart';

void main() {
  group('normalizeLessonCategoryId', () {
    test('accepts canonical and old category names', () {
      expect(normalizeLessonCategoryId('alphabet'), LessonCategoryIds.alphabet);
      expect(normalizeLessonCategoryId('Alphabets'), LessonCategoryIds.alphabet);
      expect(normalizeLessonCategoryId('numeric'), LessonCategoryIds.number);
      expect(normalizeLessonCategoryId('Numbers'), LessonCategoryIds.number);
      expect(
        normalizeLessonCategoryId('alpha numeric'),
        LessonCategoryIds.alphaNumeric,
      );
      expect(normalizeLessonCategoryId('both'), LessonCategoryIds.alphaNumeric);
    });
  });

  group('lesson sign pools', () {
    test('validates signs against category', () {
      expect(isSignAllowedForLessonCategory('alphabet', 'A'), isTrue);
      expect(isSignAllowedForLessonCategory('alphabet', '4'), isFalse);

      expect(isSignAllowedForLessonCategory('number', '4'), isTrue);
      expect(isSignAllowedForLessonCategory('number', 'A'), isFalse);

      expect(isSignAllowedForLessonCategory('alpha-numeric', 'A'), isTrue);
      expect(isSignAllowedForLessonCategory('alpha-numeric', '4'), isTrue);
    });

    test('treats O and 0 as the shared ambiguous sign', () {
      expect(normalizeLessonSignLabel('0'), 'O');
      expect(normalizeLessonSignLabel('O / 0'), 'O');
      expect(isSignAllowedForLessonCategory('alphabet', '0'), isTrue);
      expect(isSignAllowedForLessonCategory('number', 'O'), isTrue);
    });

    test('returns invalid signs for a category', () {
      expect(
        invalidLessonSignsForCategory('number', const ['A', '1', '0']),
        const ['A'],
      );
      expect(
        invalidLessonSignsForCategory('alphabet', const ['A', '1', 'O']),
        const ['1'],
      );
    });
  });

  group('classifyLessonCategoryFromSigns', () {
    test('classifies letters, numbers, and mixed lessons', () {
      expect(
        classifyLessonCategoryFromSigns(const ['A', 'B']),
        LessonCategoryIds.alphabet,
      );
      expect(
        classifyLessonCategoryFromSigns(const ['1', '9']),
        LessonCategoryIds.number,
      );
      expect(
        classifyLessonCategoryFromSigns(const ['A', '9']),
        LessonCategoryIds.alphaNumeric,
      );
    });

    test('uses fallback for ambiguous O-only lessons', () {
      expect(
        classifyLessonCategoryFromSigns(
          const ['O'],
          fallbackCategoryId: 'number',
        ),
        LessonCategoryIds.number,
      );
      expect(
        classifyLessonCategoryFromSigns(const ['O']),
        LessonCategoryIds.alphaNumeric,
      );
    });
  });
}
