import 'package:flutter_test/flutter_test.dart';
import 'package:kairo_ai/models/lesson_assessment_models.dart';

void main() {
  group('LessonAssessmentSession.canCompleteLesson', () {
    test('guided signs skipped + assessments done => cannot complete', () {
      final session = LessonAssessmentSession(
        lessonId: 'lesson-1',
        categoryId: 'category-1',
        signPool: const ['A', 'B', 'C'],
        enabledAssessments: const ['matching', 'recall', 'mcq'],
        guidedPracticePassed: false,
        matchingResult: const MatchingAssessmentResult(
          status: AssessmentStatus.attempted,
        ),
        recallResult: const RecallAssessmentResult(
          status: AssessmentStatus.passed,
        ),
        mcqResult: const McqAssessmentResult(
          status: AssessmentStatus.attempted,
        ),
      );

      expect(session.canCompleteLesson, isFalse);
    });

    test('guided clear + recall skipped => cannot complete', () {
      final session = LessonAssessmentSession(
        lessonId: 'lesson-1',
        categoryId: 'category-1',
        signPool: const ['A', 'B', 'C'],
        enabledAssessments: const ['matching', 'recall', 'mcq'],
        guidedPracticePassed: true,
        matchingResult: const MatchingAssessmentResult(
          status: AssessmentStatus.attempted,
        ),
        recallResult: const RecallAssessmentResult(
          status: AssessmentStatus.skipped,
        ),
        mcqResult: const McqAssessmentResult(
          status: AssessmentStatus.attempted,
        ),
      );

      expect(session.canCompleteLesson, isFalse);
    });

    test(
      'guided clear + matching attempted + recall passed + mcq attempted => can complete',
      () {
        final session = LessonAssessmentSession(
          lessonId: 'lesson-1',
          categoryId: 'category-1',
          signPool: const ['A', 'B', 'C'],
          enabledAssessments: const ['matching', 'recall', 'mcq'],
          guidedPracticePassed: true,
          matchingResult: const MatchingAssessmentResult(
            status: AssessmentStatus.attempted,
          ),
          recallResult: const RecallAssessmentResult(
            status: AssessmentStatus.passed,
          ),
          mcqResult: const McqAssessmentResult(
            status: AssessmentStatus.attempted,
          ),
        );

        expect(session.canCompleteLesson, isTrue);
      },
    );
  });
}
