const List<String> kDefaultLessonAssessments = ['matching', 'recall', 'mcq'];

const List<String> _kCanonicalAssessmentOrder = ['matching', 'recall', 'mcq'];

List<String> normalizeAssessmentTypes(List<String>? rawTypes) {
  final source = rawTypes ?? const <String>[];
  final normalizedSet = <String>{};

  for (final raw in source) {
    final key = raw.trim().toLowerCase();
    switch (key) {
      case 'match':
      case 'matching':
        normalizedSet.add('matching');
        break;
      case 'recall':
        normalizedSet.add('recall');
        break;
      case 'mcq':
        normalizedSet.add('mcq');
        break;
      default:
        break;
    }
  }

  if (normalizedSet.isEmpty) {
    return List<String>.from(kDefaultLessonAssessments);
  }

  // Legacy lesson docs were often saved with only `mcq` as a default value.
  // In learner flow we treat that payload as "all default assessments".
  if (normalizedSet.length == 1 && normalizedSet.contains('mcq')) {
    return List<String>.from(kDefaultLessonAssessments);
  }

  final ordered = <String>[];
  for (final type in _kCanonicalAssessmentOrder) {
    if (normalizedSet.contains(type)) {
      ordered.add(type);
    }
  }

  return ordered;
}

enum AssessmentStatus { notStarted, inProgress, passed, failed, skipped }

extension AssessmentStatusX on AssessmentStatus {
  String get value {
    switch (this) {
      case AssessmentStatus.notStarted:
        return 'not_started';
      case AssessmentStatus.inProgress:
        return 'in_progress';
      case AssessmentStatus.passed:
        return 'passed';
      case AssessmentStatus.failed:
        return 'failed';
      case AssessmentStatus.skipped:
        return 'skipped';
    }
  }
}

class MatchingAssessmentResult {
  final AssessmentStatus status;
  final int attemptCount;
  final DateTime? completedAt;
  final Map<String, String> submittedPairs;
  final Map<String, String> incorrectPairs;
  final String? errorMessage;

  const MatchingAssessmentResult({
    this.status = AssessmentStatus.notStarted,
    this.attemptCount = 0,
    this.completedAt,
    this.submittedPairs = const <String, String>{},
    this.incorrectPairs = const <String, String>{},
    this.errorMessage,
  });

  MatchingAssessmentResult copyWith({
    AssessmentStatus? status,
    int? attemptCount,
    DateTime? completedAt,
    Map<String, String>? submittedPairs,
    Map<String, String>? incorrectPairs,
    String? errorMessage,
  }) {
    return MatchingAssessmentResult(
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      completedAt: completedAt ?? this.completedAt,
      submittedPairs: submittedPairs ?? this.submittedPairs,
      incorrectPairs: incorrectPairs ?? this.incorrectPairs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RecallPromptResult {
  final String targetSign;
  final String detectedSign;
  final bool passed;
  final double confidence;
  final int stableDetectionsAchieved;
  final int requiredStableDetections;
  final DateTime timestamp;

  const RecallPromptResult({
    required this.targetSign,
    required this.detectedSign,
    required this.passed,
    required this.confidence,
    required this.stableDetectionsAchieved,
    required this.requiredStableDetections,
    required this.timestamp,
  });
}

class RecallAssessmentResult {
  final AssessmentStatus status;
  final int attemptCount;
  final DateTime? completedAt;
  final List<String> promptOrder;
  final List<RecallPromptResult> perPromptResults;
  final String? errorMessage;

  const RecallAssessmentResult({
    this.status = AssessmentStatus.notStarted,
    this.attemptCount = 0,
    this.completedAt,
    this.promptOrder = const <String>[],
    this.perPromptResults = const <RecallPromptResult>[],
    this.errorMessage,
  });

  RecallAssessmentResult copyWith({
    AssessmentStatus? status,
    int? attemptCount,
    DateTime? completedAt,
    List<String>? promptOrder,
    List<RecallPromptResult>? perPromptResults,
    String? errorMessage,
  }) {
    return RecallAssessmentResult(
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      completedAt: completedAt ?? this.completedAt,
      promptOrder: promptOrder ?? this.promptOrder,
      perPromptResults: perPromptResults ?? this.perPromptResults,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class McqQuestionRecord {
  final String promptSign;
  final List<String> options;
  final String correctAnswer;

  const McqQuestionRecord({
    required this.promptSign,
    required this.options,
    required this.correctAnswer,
  });
}

class McqAssessmentResult {
  final AssessmentStatus status;
  final int attemptCount;
  final DateTime? completedAt;
  final List<McqQuestionRecord> questions;
  final Map<int, String> selectedAnswers;
  final Map<int, String> correctAnswers;
  final int score;
  final String? errorMessage;

  const McqAssessmentResult({
    this.status = AssessmentStatus.notStarted,
    this.attemptCount = 0,
    this.completedAt,
    this.questions = const <McqQuestionRecord>[],
    this.selectedAnswers = const <int, String>{},
    this.correctAnswers = const <int, String>{},
    this.score = 0,
    this.errorMessage,
  });

  McqAssessmentResult copyWith({
    AssessmentStatus? status,
    int? attemptCount,
    DateTime? completedAt,
    List<McqQuestionRecord>? questions,
    Map<int, String>? selectedAnswers,
    Map<int, String>? correctAnswers,
    int? score,
    String? errorMessage,
  }) {
    return McqAssessmentResult(
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      completedAt: completedAt ?? this.completedAt,
      questions: questions ?? this.questions,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      score: score ?? this.score,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LessonAssessmentSession {
  final String lessonId;
  final String categoryId;
  final List<String> signPool;
  final List<String> enabledAssessments;

  bool guidedPracticePassed;
  MatchingAssessmentResult matchingResult;
  RecallAssessmentResult recallResult;
  McqAssessmentResult mcqResult;

  LessonAssessmentSession({
    required this.lessonId,
    required this.categoryId,
    required this.signPool,
    required List<String> enabledAssessments,
    this.guidedPracticePassed = false,
    MatchingAssessmentResult? matchingResult,
    RecallAssessmentResult? recallResult,
    McqAssessmentResult? mcqResult,
  }) : enabledAssessments = normalizeAssessmentTypes(enabledAssessments),
       matchingResult = matchingResult ?? const MatchingAssessmentResult(),
       recallResult = recallResult ?? const RecallAssessmentResult(),
       mcqResult = mcqResult ?? const McqAssessmentResult();

  bool isAssessmentRequired(String type) {
    return enabledAssessments.contains(type);
  }

  bool get wasSkipped {
    for (final assessment in enabledAssessments) {
      if (_statusFor(assessment) == AssessmentStatus.skipped) {
        return true;
      }
    }
    return false;
  }

  bool get canCompleteLesson {
    if (!guidedPracticePassed) return false;

    for (final assessment in enabledAssessments) {
      if (_statusFor(assessment) != AssessmentStatus.passed) {
        return false;
      }
    }

    return !wasSkipped;
  }

  bool get rewardEligible => canCompleteLesson;

  AssessmentStatus _statusFor(String assessment) {
    switch (assessment) {
      case 'matching':
        return matchingResult.status;
      case 'recall':
        return recallResult.status;
      case 'mcq':
        return mcqResult.status;
      default:
        return AssessmentStatus.notStarted;
    }
  }
}
