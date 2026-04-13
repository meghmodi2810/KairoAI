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

enum AssessmentStatus {
  notStarted,
  inProgress,
  attempted,
  passed,
  failed,
  skipped,
}

AssessmentStatus assessmentStatusFromValue(String? rawValue) {
  final value = (rawValue ?? '').trim().toLowerCase();

  switch (value) {
    case 'in_progress':
    case 'inprogress':
      return AssessmentStatus.inProgress;
    case 'attempted':
      return AssessmentStatus.attempted;
    case 'passed':
      return AssessmentStatus.passed;
    case 'failed':
      return AssessmentStatus.failed;
    case 'skipped':
      return AssessmentStatus.skipped;
    case 'not_started':
    case 'notstarted':
    default:
      return AssessmentStatus.notStarted;
  }
}

extension AssessmentStatusX on AssessmentStatus {
  String get value {
    switch (this) {
      case AssessmentStatus.notStarted:
        return 'not_started';
      case AssessmentStatus.inProgress:
        return 'in_progress';
      case AssessmentStatus.attempted:
        return 'attempted';
      case AssessmentStatus.passed:
        return 'passed';
      case AssessmentStatus.failed:
        return 'failed';
      case AssessmentStatus.skipped:
        return 'skipped';
    }
  }
}

DateTime? _coerceDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);

  try {
    final converted = (value as dynamic).toDate();
    if (converted is DateTime) return converted;
  } catch (_) {}

  return null;
}

Map<String, dynamic> _coerceStringDynamicMap(dynamic value) {
  if (value is! Map) return <String, dynamic>{};
  final map = <String, dynamic>{};

  for (final entry in value.entries) {
    final key = entry.key?.toString();
    if (key == null || key.isEmpty) continue;
    map[key] = entry.value;
  }

  return map;
}

Map<String, String> _coerceStringStringMap(dynamic value) {
  final source = _coerceStringDynamicMap(value);
  final map = <String, String>{};

  for (final entry in source.entries) {
    final normalizedValue = (entry.value ?? '').toString().trim();
    if (normalizedValue.isEmpty) continue;
    map[entry.key] = normalizedValue;
  }

  return map;
}

Map<int, String> _coerceIntStringMap(dynamic value) {
  final source = _coerceStringDynamicMap(value);
  final map = <int, String>{};

  for (final entry in source.entries) {
    final key = int.tryParse(entry.key);
    if (key == null) continue;

    final normalizedValue = (entry.value ?? '').toString().trim();
    if (normalizedValue.isEmpty) continue;

    map[key] = normalizedValue;
  }

  return map;
}

Map<String, String> _stringifyIntStringMap(Map<int, String> source) {
  final map = <String, String>{};
  for (final entry in source.entries) {
    map[entry.key.toString()] = entry.value;
  }
  return map;
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

  factory MatchingAssessmentResult.fromMap(Map<String, dynamic> data) {
    return MatchingAssessmentResult(
      status: assessmentStatusFromValue(data['status']?.toString()),
      attemptCount: (data['attemptCount'] as num?)?.toInt() ?? 0,
      completedAt: _coerceDateTime(data['completedAt']),
      submittedPairs: _coerceStringStringMap(data['submittedPairs']),
      incorrectPairs: _coerceStringStringMap(data['incorrectPairs']),
      errorMessage: (data['errorMessage'] ?? '').toString().trim().isEmpty
          ? null
          : data['errorMessage'].toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      'attemptCount': attemptCount,
      'completedAt': completedAt?.toIso8601String(),
      'submittedPairs': submittedPairs,
      'incorrectPairs': incorrectPairs,
      'errorMessage': errorMessage,
    };
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

  factory RecallPromptResult.fromMap(Map<String, dynamic> data) {
    return RecallPromptResult(
      targetSign: (data['targetSign'] ?? '').toString(),
      detectedSign: (data['detectedSign'] ?? '').toString(),
      passed: data['passed'] == true,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
      stableDetectionsAchieved:
          (data['stableDetectionsAchieved'] as num?)?.toInt() ?? 0,
      requiredStableDetections:
          (data['requiredStableDetections'] as num?)?.toInt() ?? 0,
      timestamp: _coerceDateTime(data['timestamp']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetSign': targetSign,
      'detectedSign': detectedSign,
      'passed': passed,
      'confidence': confidence,
      'stableDetectionsAchieved': stableDetectionsAchieved,
      'requiredStableDetections': requiredStableDetections,
      'timestamp': timestamp.toIso8601String(),
    };
  }
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

  factory RecallAssessmentResult.fromMap(Map<String, dynamic> data) {
    final rawPromptOrder = data['promptOrder'];
    final promptOrder = rawPromptOrder is List
        ? rawPromptOrder.map((item) => item.toString()).toList(growable: false)
        : const <String>[];

    final rawPerPrompt = data['perPromptResults'];
    final perPromptResults = rawPerPrompt is List
        ? rawPerPrompt
              .whereType<Map>()
              .map(
                (item) => RecallPromptResult.fromMap(
                  _coerceStringDynamicMap(item),
                ),
              )
              .toList(growable: false)
        : const <RecallPromptResult>[];

    return RecallAssessmentResult(
      status: assessmentStatusFromValue(data['status']?.toString()),
      attemptCount: (data['attemptCount'] as num?)?.toInt() ?? 0,
      completedAt: _coerceDateTime(data['completedAt']),
      promptOrder: promptOrder,
      perPromptResults: perPromptResults,
      errorMessage: (data['errorMessage'] ?? '').toString().trim().isEmpty
          ? null
          : data['errorMessage'].toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      'attemptCount': attemptCount,
      'completedAt': completedAt?.toIso8601String(),
      'promptOrder': promptOrder,
      'perPromptResults': perPromptResults
          .map((result) => result.toMap())
          .toList(growable: false),
      'errorMessage': errorMessage,
    };
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

  factory McqQuestionRecord.fromMap(Map<String, dynamic> data) {
    final rawOptions = data['options'];

    return McqQuestionRecord(
      promptSign: (data['promptSign'] ?? '').toString(),
      options: rawOptions is List
          ? rawOptions.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      correctAnswer: (data['correctAnswer'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'promptSign': promptSign,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }
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

  factory McqAssessmentResult.fromMap(Map<String, dynamic> data) {
    final rawQuestions = data['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
              .whereType<Map>()
              .map(
                (item) => McqQuestionRecord.fromMap(
                  _coerceStringDynamicMap(item),
                ),
              )
              .toList(growable: false)
        : const <McqQuestionRecord>[];

    return McqAssessmentResult(
      status: assessmentStatusFromValue(data['status']?.toString()),
      attemptCount: (data['attemptCount'] as num?)?.toInt() ?? 0,
      completedAt: _coerceDateTime(data['completedAt']),
      questions: questions,
      selectedAnswers: _coerceIntStringMap(data['selectedAnswers']),
      correctAnswers: _coerceIntStringMap(data['correctAnswers']),
      score: (data['score'] as num?)?.toInt() ?? 0,
      errorMessage: (data['errorMessage'] ?? '').toString().trim().isEmpty
          ? null
          : data['errorMessage'].toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      'attemptCount': attemptCount,
      'completedAt': completedAt?.toIso8601String(),
      'questions': questions
          .map((question) => question.toMap())
          .toList(growable: false),
      'selectedAnswers': _stringifyIntStringMap(selectedAnswers),
      'correctAnswers': _stringifyIntStringMap(correctAnswers),
      'score': score,
      'errorMessage': errorMessage,
    };
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
      if (!_isCompletionStateSatisfied(
        type: assessment,
        status: _statusFor(assessment),
      )) {
        return false;
      }
    }

    return true;
  }

  bool get rewardEligible => canCompleteLesson;

  bool get allRequiredAssessmentsPassed {
    for (final assessment in enabledAssessments) {
      if (_statusFor(assessment) != AssessmentStatus.passed) {
        return false;
      }
    }
    return true;
  }

  String? get firstIncompleteAssessmentType {
    for (final assessment in enabledAssessments) {
      if (!_isCompletionStateSatisfied(
        type: assessment,
        status: _statusFor(assessment),
      )) {
        return assessment;
      }
    }
    return null;
  }

  List<String> get skippedAssessmentTypes {
    final skipped = <String>[];
    for (final assessment in enabledAssessments) {
      if (_statusFor(assessment) == AssessmentStatus.skipped) {
        skipped.add(assessment);
      }
    }
    return skipped;
  }

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

  bool _isCompletionStateSatisfied({
    required String type,
    required AssessmentStatus status,
  }) {
    if (status == AssessmentStatus.skipped ||
        status == AssessmentStatus.failed ||
        status == AssessmentStatus.notStarted ||
        status == AssessmentStatus.inProgress) {
      return false;
    }

    if (type == 'recall') {
      return status == AssessmentStatus.passed;
    }

    if (type == 'matching' || type == 'mcq') {
      return status == AssessmentStatus.passed ||
          status == AssessmentStatus.attempted;
    }

    return status == AssessmentStatus.passed;
  }
}
