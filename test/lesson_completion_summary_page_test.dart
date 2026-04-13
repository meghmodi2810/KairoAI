import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairo_ai/models/app_models.dart';
import 'package:kairo_ai/models/lesson_assessment_models.dart';
import 'package:kairo_ai/pages/assessments/lesson_completion_summary_page.dart';

LessonModel _lesson() {
  return LessonModel(
    id: 'lesson-1',
    categoryId: 'category-1',
    unitNumber: 1,
    title: 'Alphabet Basics',
    subtitle: 'Unit 1',
    description: 'Practice signs',
    order: 1,
    totalSigns: 3,
    focusPoints: const ['shape'],
    testTypes: const ['matching', 'recall', 'mcq'],
  );
}

LessonAssessmentSession _completableSession() {
  return LessonAssessmentSession(
    lessonId: 'lesson-1',
    categoryId: 'category-1',
    signPool: const ['A', 'B', 'C'],
    enabledAssessments: const ['matching', 'recall', 'mcq'],
    guidedPracticePassed: true,
    matchingResult: const MatchingAssessmentResult(
      status: AssessmentStatus.attempted,
    ),
    recallResult: const RecallAssessmentResult(status: AssessmentStatus.passed),
    mcqResult: const McqAssessmentResult(status: AssessmentStatus.attempted),
  );
}

void main() {
  testWidgets('Later action is removed and finish action is present', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LessonCompletionSummaryPage(
          lesson: _lesson(),
          session: _completableSession(),
          practiceSeconds: 120,
        ),
      ),
    );

    expect(find.text('Later'), findsNothing);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Text) return false;
        final data = widget.data;
        if (data == null) return false;
        return data.toLowerCase().contains('finish lesson');
      }),
      findsOneWidget,
    );
  });

  test('summary requires canCompleteLesson == true', () {
    final blockedSession = LessonAssessmentSession(
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
      mcqResult: const McqAssessmentResult(status: AssessmentStatus.attempted),
    );

    expect(
      () => LessonCompletionSummaryPage(
        lesson: _lesson(),
        session: blockedSession,
        practiceSeconds: 120,
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
