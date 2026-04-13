enum PrimaryLessonAction {
  practiceCurrentSign,
  resumePendingGuided,
  continueAssessments,
  showCompletionSummary,
}

class PrimaryLessonCta {
  final String label;
  final PrimaryLessonAction action;

  const PrimaryLessonCta({required this.label, required this.action});
}

int computeGuidedResumeIndex({
  required int signCount,
  required int? savedIndex,
  required Set<String> practicedSignIds,
  required Set<String> skippedSignIds,
  required List<String> orderedSignIds,
}) {
  if (signCount <= 0) return 0;

  final hasValidSavedIndex =
      savedIndex != null && savedIndex >= 0 && savedIndex < signCount;
  if (hasValidSavedIndex) {
    return savedIndex;
  }

  final firstUnworkedIndex = orderedSignIds.indexWhere((signId) {
    final practiced = practicedSignIds.contains(signId);
    final skipped = skippedSignIds.contains(signId);
    return !practiced && !skipped;
  });

  if (firstUnworkedIndex != -1) {
    return firstUnworkedIndex;
  }

  return signCount - 1;
}

PrimaryLessonCta decidePrimaryLessonCta({
  required bool currentSignNeedsWork,
  required bool guidedSequenceFinished,
  required int pendingGuidedCount,
  required int pendingAssessmentCount,
  required bool canCompleteLesson,
}) {
  if (currentSignNeedsWork) {
    return const PrimaryLessonCta(
      label: 'Practice This Sign',
      action: PrimaryLessonAction.practiceCurrentSign,
    );
  }

  if (guidedSequenceFinished && pendingGuidedCount > 0) {
    return const PrimaryLessonCta(
      label: 'Resume Pending Sign',
      action: PrimaryLessonAction.resumePendingGuided,
    );
  }

  if (guidedSequenceFinished && pendingAssessmentCount > 0) {
    return const PrimaryLessonCta(
      label: 'Continue Assessments',
      action: PrimaryLessonAction.continueAssessments,
    );
  }

  if (canCompleteLesson) {
    return const PrimaryLessonCta(
      label: 'View Completion Summary',
      action: PrimaryLessonAction.showCompletionSummary,
    );
  }

  return const PrimaryLessonCta(
    label: 'Continue Lesson',
    action: PrimaryLessonAction.practiceCurrentSign,
  );
}
