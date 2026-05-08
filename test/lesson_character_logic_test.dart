import 'package:flutter_test/flutter_test.dart';
import 'package:kairo_ai/models/lesson_character_models.dart';

void main() {
  group('normalizeSignCharacters', () {
    test('dedupes repeated characters case-insensitively', () {
      expect(
        normalizeSignCharacters(const ['a', 'A', ' 1 ', '1', '', 'b']),
        const ['A', '1', 'B'],
      );
    });
  });

  group('buildWordPrerequisiteResult', () {
    test('marks word ready when every required character is completed', () {
      final result = buildWordPrerequisiteResult(
        requiredCharacters: const ['K', 'A', 'I'],
        completedCharacters: const ['A', 'I', 'K', 'R'],
      );

      expect(result.isReady, isTrue);
      expect(result.missingCharacters, isEmpty);
    });

    test('returns missing characters when prerequisites are incomplete', () {
      final result = buildWordPrerequisiteResult(
        requiredCharacters: const ['K', 'A', 'I', 'R', 'O'],
        completedCharacters: const ['A', 'I'],
      );

      expect(result.isReady, isFalse);
      expect(result.missingCharacters, const {'K', 'R', 'O'});
    });
  });

  group('LessonCharacterIndex', () {
    test('groups multiple lessons per missing character', () {
      const index = LessonCharacterIndex([
        LessonCharacterCandidate(
          categoryId: 'cat-1',
          categoryName: 'Basics',
          lessonId: 'lesson-1',
          lessonTitle: 'First Signs',
          categoryOrder: 1,
          lessonOrder: 1,
          characters: {'A', 'B', 'C'},
        ),
        LessonCharacterCandidate(
          categoryId: 'cat-1',
          categoryName: 'Basics',
          lessonId: 'lesson-2',
          lessonTitle: 'More Signs',
          categoryOrder: 1,
          lessonOrder: 2,
          characters: {'C', 'D', 'E'},
        ),
      ]);

      final grouped = index.candidatesByCharacter(const {'C'});

      expect(grouped['C'], hasLength(2));
      expect(grouped['C']!.map((candidate) => candidate.lessonId), [
        'lesson-1',
        'lesson-2',
      ]);
    });

    test('ranks lessons covering the most missing characters first', () {
      const index = LessonCharacterIndex([
        LessonCharacterCandidate(
          categoryId: 'cat-1',
          categoryName: 'Basics',
          lessonId: 'lesson-1',
          lessonTitle: 'One Match',
          categoryOrder: 1,
          lessonOrder: 1,
          characters: {'A'},
        ),
        LessonCharacterCandidate(
          categoryId: 'cat-2',
          categoryName: 'Combo',
          lessonId: 'lesson-2',
          lessonTitle: 'Three Matches',
          categoryOrder: 2,
          lessonOrder: 1,
          characters: {'A', 'B', 'C'},
        ),
      ]);

      final ranked = index.rankedCandidatesFor(const {'A', 'B', 'C'});

      expect(ranked.first.lessonId, 'lesson-2');
    });
  });
}
