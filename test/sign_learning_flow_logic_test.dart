import 'package:flutter_test/flutter_test.dart';
import 'package:kairo_ai/pages/sign_learning_flow_logic.dart';

void main() {
  group('computeGuidedResumeIndex', () {
    test('reopening keeps saved guidedCurrentIndex when valid', () {
      final resumeIndex = computeGuidedResumeIndex(
        signCount: 5,
        savedIndex: 3,
        practicedSignIds: const {'sign-0'},
        skippedSignIds: const {'sign-1'},
        orderedSignIds: const [
          'sign-0',
          'sign-1',
          'sign-2',
          'sign-3',
          'sign-4',
        ],
      );

      expect(resumeIndex, 3);
    });

    test('falls back to next unworked sign when saved index is invalid', () {
      final resumeIndex = computeGuidedResumeIndex(
        signCount: 5,
        savedIndex: 99,
        practicedSignIds: const {'sign-0', 'sign-1'},
        skippedSignIds: const {'sign-2'},
        orderedSignIds: const [
          'sign-0',
          'sign-1',
          'sign-2',
          'sign-3',
          'sign-4',
        ],
      );

      expect(resumeIndex, 3);
    });
  });

  group('decidePrimaryLessonCta', () {
    test('shows practice when current sign still needs work', () {
      final cta = decidePrimaryLessonCta(
        currentSignNeedsWork: true,
        guidedSequenceFinished: false,
        pendingGuidedCount: 0,
        pendingAssessmentCount: 3,
        canCompleteLesson: false,
      );

      expect(cta.label, 'Practice This Sign');
      expect(cta.action, PrimaryLessonAction.practiceCurrentSign);
    });

    test('prioritizes pending guided signs before assessments', () {
      final cta = decidePrimaryLessonCta(
        currentSignNeedsWork: false,
        guidedSequenceFinished: true,
        pendingGuidedCount: 2,
        pendingAssessmentCount: 1,
        canCompleteLesson: false,
      );

      expect(cta.label, 'Resume Pending Sign');
      expect(cta.action, PrimaryLessonAction.resumePendingGuided);
    });

    test('shows continue assessments once guided sequence is clear', () {
      final cta = decidePrimaryLessonCta(
        currentSignNeedsWork: false,
        guidedSequenceFinished: true,
        pendingGuidedCount: 0,
        pendingAssessmentCount: 2,
        canCompleteLesson: false,
      );

      expect(cta.label, 'Continue Assessments');
      expect(cta.action, PrimaryLessonAction.continueAssessments);
    });

    test('shows completion summary action when all requirements are met', () {
      final cta = decidePrimaryLessonCta(
        currentSignNeedsWork: false,
        guidedSequenceFinished: true,
        pendingGuidedCount: 0,
        pendingAssessmentCount: 0,
        canCompleteLesson: true,
      );

      expect(cta.label, 'View Completion Summary');
      expect(cta.action, PrimaryLessonAction.showCompletionSummary);
    });
  });
}
