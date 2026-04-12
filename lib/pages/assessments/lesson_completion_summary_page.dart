import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../models/lesson_assessment_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_brutal_widgets.dart';

class LessonCompletionSummaryPage extends StatelessWidget {
  final LessonModel lesson;
  final LessonAssessmentSession session;
  final int practiceSeconds;

  const LessonCompletionSummaryPage({
    super.key,
    required this.lesson,
    required this.session,
    required this.practiceSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final practiceMinutes = (practiceSeconds / 60).ceil();
    final completionEligible = session.canCompleteLesson;
    final allRequiredPassed = session.allRequiredAssessmentsPassed;

    final subtitle = completionEligible
      ? (allRequiredPassed
          ? 'Guided practice complete. All required assessments passed.'
          : 'Guided practice complete. Required assessments attempted. You can still finish this lesson.')
      : 'Lesson has required steps pending. Resume from the first incomplete assessment.';

    final finishLabel = completionEligible
      ? 'Finish Lesson'
      : 'Resume Required Assessment';

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      appBar: AppBar(
        backgroundColor: AppTheme.paperCream,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Lesson Summary',
          style: TextStyle(
            color: AppTheme.inkBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(
            children: [
              NeoPanel(
                color: AppTheme.softPeach,
                radius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        color: AppTheme.inkBlack,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.inkBlack,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              NeoPanel(
                color: AppTheme.warmWhite,
                radius: 18,
                child: Column(
                  children: [
                    _summaryRow('Practice Time', '$practiceMinutes min'),
                    _summaryRow('Sign Pool', session.signPool.join(', ')),
                    if (session.isAssessmentRequired('matching'))
                      _summaryRow(
                        'Matching',
                        _statusLabel(session.matchingResult.status),
                        valueColor: _statusColor(session.matchingResult.status),
                      ),
                    if (session.isAssessmentRequired('recall'))
                      _summaryRow(
                        'Recall',
                        _statusLabel(session.recallResult.status),
                        valueColor: _statusColor(session.recallResult.status),
                      ),
                    if (session.isAssessmentRequired('mcq'))
                      _summaryRow(
                        'Recognition (MCQ)',
                        _statusLabel(session.mcqResult.status),
                        valueColor: _statusColor(session.mcqResult.status),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              NeoPanel(
                color: AppTheme.mintGreen.withValues(alpha: 0.2),
                radius: 18,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    NeoSticker(
                      label: '+${lesson.xpReward} XP',
                      color: AppTheme.mintGreen,
                      icon: Icons.bolt,
                      rotation: 0,
                    ),
                    NeoSticker(
                      label: '+${lesson.gemsReward} GEMS',
                      color: AppTheme.signalYellow,
                      icon: Icons.diamond,
                      rotation: 0,
                    ),
                    NeoSticker(
                      label: '+${lesson.coinsReward} COINS',
                      color: AppTheme.electricBlue,
                      icon: Icons.monetization_on,
                      rotation: 0,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: NeoSecondaryButton(
                      label: 'Later',
                      icon: Icons.schedule,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NeoPrimaryButton(
                      label: finishLabel,
                      icon: Icons.check_circle,
                      onPressed: completionEligible
                          ? () => Navigator.of(context).pop(true)
                          : () => Navigator.of(context).pop(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.inkBlack,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppTheme.inkBlack,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AssessmentStatus status) {
    switch (status) {
      case AssessmentStatus.passed:
        return 'PASSED';
      case AssessmentStatus.attempted:
        return 'ATTEMPTED';
      case AssessmentStatus.failed:
        return 'FAILED';
      case AssessmentStatus.skipped:
        return 'SKIPPED';
      case AssessmentStatus.inProgress:
        return 'IN PROGRESS';
      case AssessmentStatus.notStarted:
        return 'NOT STARTED';
    }
  }

  Color _statusColor(AssessmentStatus status) {
    switch (status) {
      case AssessmentStatus.passed:
        return AppTheme.mintGreen;
      case AssessmentStatus.attempted:
        return AppTheme.signalYellow;
      case AssessmentStatus.failed:
      case AssessmentStatus.skipped:
        return AppTheme.punchRed;
      case AssessmentStatus.inProgress:
        return AppTheme.signalYellow;
      case AssessmentStatus.notStarted:
        return AppTheme.inkBlack;
    }
  }
}
