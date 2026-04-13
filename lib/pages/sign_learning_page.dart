import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../models/lesson_assessment_models.dart';
import '../services/database_service.dart';
import '../services/sign_image_service.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'sign_learning_flow_logic.dart';
import 'assessments/lesson_completion_summary_page.dart';
import 'assessments/matching_assessment_page.dart';
import 'assessments/mcq_recognition_assessment_page.dart';
import 'assessments/recall_assessment_page.dart';
import 'lesson_practice_page.dart';

class SignLearningPage extends StatefulWidget {
  final LessonModel lesson;
  final String categoryId;

  const SignLearningPage({
    super.key,
    required this.lesson,
    required this.categoryId,
  });

  @override
  State<SignLearningPage> createState() => _SignLearningPageState();
}

class _AssessmentMediaBundle {
  final Map<String, String> imageRefsBySignId;
  final List<String> globalDistractorPool;

  const _AssessmentMediaBundle({
    required this.imageRefsBySignId,
    required this.globalDistractorPool,
  });

  const _AssessmentMediaBundle.empty()
    : imageRefsBySignId = const <String, String>{},
      globalDistractorPool = const <String>[];
}

class _SignLearningPageState extends State<SignLearningPage> {
  static const List<String> _assessmentOrder = <String>[
    'matching',
    'recall',
    'mcq',
  ];
  static const McqQuestionScope _mcqQuestionScope = McqQuestionScope.allSigns;

  final DatabaseService _db = DatabaseService();
  final SignImageService _imageService = SignImageService();

  List<SignModel> _signs = [];
  int _index = 0;
  bool _loading = true;
  bool _showTips = false;
  bool _completed = false;
  bool _assessmentFlowStarted = false;
  int _totalPracticeSeconds = 0;
  final Set<String> _practicedSignIds = <String>{};
  final Set<String> _skippedSignIds = <String>{};
  final List<String> _skippedAssessmentTypes = <String>[];
  String? _assessmentResumeType;
  LessonAssessmentSession? _assessmentSession;

  SignModel get _current => _signs[_index];
  bool get _guidedSequenceFinished =>
      _signs.isNotEmpty &&
      (_practicedSignIds.length + _skippedSignIds.length) == _signs.length;
  bool get _guidedPracticeDone =>
      _signs.isNotEmpty && _guidedSequenceFinished && _skippedSignIds.isEmpty;

  int? get _firstPendingGuidedSignIndex {
    if (_signs.isEmpty || _skippedSignIds.isEmpty) return null;
    final pendingIndex = _signs.indexWhere(
      (sign) => _skippedSignIds.contains(sign.id),
    );
    return pendingIndex == -1 ? null : pendingIndex;
  }

  int get _pendingGuidedCount =>
      _signs.where((sign) => _skippedSignIds.contains(sign.id)).length;

  int _pendingAssessmentCountForSession(LessonAssessmentSession session) {
    var pendingCount = 0;
    for (final assessmentType in session.enabledAssessments) {
      if (!_isAssessmentSatisfiedForCompletion(session, assessmentType)) {
        pendingCount += 1;
      }
    }
    return pendingCount;
  }

  String? _firstIncompleteAssessmentTypeForSession(
    LessonAssessmentSession session,
  ) {
    if (_assessmentResumeType != null &&
        session.enabledAssessments.contains(_assessmentResumeType) &&
        !_isAssessmentSatisfiedForCompletion(session, _assessmentResumeType!)) {
      return _assessmentResumeType;
    }
    return session.firstIncompleteAssessmentType;
  }

  Widget _buildGuidedSignMedia(String resolvedRef) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        resolvedRef,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildGuidedPlaceholder(),
      ),
    );
  }

  Widget _buildGuidedPlaceholder() {
    return Center(
      child: Text(
        _current.word.toUpperCase(),
        style: TextStyle(
          color: AppTheme.cobaltBlue.withValues(alpha: 0.45),
          fontWeight: FontWeight.w900,
          fontSize: 96,
        ),
      ),
    );
  }

  String? _normalizeAssessmentType(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'match' || value == 'matching') return 'matching';
    if (value == 'recall' || value == 'mcq') return value;
    return null;
  }

  List<String> _orderedAssessmentTypes(Iterable<String> rawTypes) {
    final normalized = <String>{};
    for (final raw in rawTypes) {
      final type = _normalizeAssessmentType(raw);
      if (type != null) normalized.add(type);
    }

    final ordered = <String>[];
    for (final type in _assessmentOrder) {
      if (normalized.contains(type)) {
        ordered.add(type);
      }
    }
    return ordered;
  }

  List<String> _orderedEnabledAssessmentTypes(Iterable<String> rawTypes) {
    final enabled = widget.lesson.enabledAssessmentTypes;
    return _orderedAssessmentTypes(
      rawTypes,
    ).where(enabled.contains).toList(growable: false);
  }

  String _assessmentTitle(String type) {
    switch (type) {
      case 'matching':
        return 'Matching';
      case 'recall':
        return 'Recall';
      case 'mcq':
        return 'Recognition';
      default:
        return type.toUpperCase();
    }
  }

  Map<String, dynamic> _serializeAssessmentResults(
    LessonAssessmentSession session,
  ) {
    return {
      'matching': session.matchingResult.toMap(),
      'recall': session.recallResult.toMap(),
      'mcq': session.mcqResult.toMap(),
    };
  }

  void _hydrateAssessmentResultsFromMap({
    required LessonAssessmentSession session,
    required Map<String, dynamic> assessmentResults,
  }) {
    final matching = assessmentResults['matching'];
    if (matching is Map) {
      session.matchingResult = MatchingAssessmentResult.fromMap(
        Map<String, dynamic>.from(matching),
      );
    }

    final recall = assessmentResults['recall'];
    if (recall is Map) {
      session.recallResult = RecallAssessmentResult.fromMap(
        Map<String, dynamic>.from(recall),
      );
    }

    final mcq = assessmentResults['mcq'];
    if (mcq is Map) {
      session.mcqResult = McqAssessmentResult.fromMap(
        Map<String, dynamic>.from(mcq),
      );
    }
  }

  Future<void> _persistAssessmentSession(
    LessonAssessmentSession session,
  ) async {
    session.guidedPracticePassed = _guidedPracticeDone;

    final skippedTypes = _orderedEnabledAssessmentTypes(
      session.skippedAssessmentTypes,
    );
    final resumeType = _firstIncompleteAssessmentTypeForSession(session);

    if (mounted) {
      setState(() {
        _assessmentSession = session;
        _skippedAssessmentTypes
          ..clear()
          ..addAll(skippedTypes);
        _assessmentResumeType = resumeType;
      });
    }

    try {
      await _db.saveAssessmentCheckpoint(
        lessonId: widget.lesson.id,
        skippedAssessmentTypes: skippedTypes,
        resumeAssessmentType: resumeType,
        assessmentResults: _serializeAssessmentResults(session),
        guidedPracticeCompleted: _guidedPracticeDone,
        assessmentSummaryReady: false,
      );
    } catch (_) {}
  }

  Future<void> _saveAssessmentSkipAndContinue(
    String type,
    LessonAssessmentSession session,
  ) async {
    await _persistAssessmentSession(session);
    if (!mounted) return;

    final title = _assessmentTitle(type);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Skipped $title assessment and marked pending. Moving to the next step.',
        ),
      ),
    );
  }

  Future<void> _persistGuidedPracticeCheckpoint() async {
    try {
      await _db.saveAssessmentCheckpoint(
        lessonId: widget.lesson.id,
        skippedAssessmentTypes: _orderedEnabledAssessmentTypes(
          _skippedAssessmentTypes,
        ),
        resumeAssessmentType: _assessmentResumeType,
        assessmentResults: _assessmentSession == null
            ? null
            : _serializeAssessmentResults(_assessmentSession!),
        guidedPracticeCompleted: _guidedPracticeDone,
        assessmentSummaryReady: false,
      );
    } catch (_) {}
  }

  Future<void> _restartLessonFromStart() async {
    if (_signs.isEmpty) return;

    final shouldRestart = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restart Lesson'),
        content: const Text(
          'This will restart guided practice and assessments from the beginning. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );

    if (shouldRestart != true) return;

    try {
      await _db.restartLessonProgress(
        lessonId: widget.lesson.id,
        categoryId: widget.categoryId,
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _index = 0;
      _showTips = false;
      _completed = false;
      _assessmentFlowStarted = false;
      _totalPracticeSeconds = 0;
      _practicedSignIds.clear();
      _skippedSignIds.clear();
      _skippedAssessmentTypes.clear();
      _assessmentResumeType = null;
      _assessmentSession = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lesson restarted from the beginning.')),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSigns();
  }

  Future<void> _loadSigns() async {
    try {
      final existingProgress = await _db.getLessonProgress(widget.lesson.id);
      if (existingProgress?.status != 'completed') {
        await _db.startLesson(widget.lesson.id, widget.categoryId);
      }

      final signs = await _db.getSigns(widget.categoryId, widget.lesson.id);
      final progress = existingProgress?.status == 'completed'
          ? existingProgress
          : await _db.getLessonProgress(widget.lesson.id);

      final validSignIds = signs.map((sign) => sign.id).toSet();
      final restoredPracticed = <String>{
        ...?progress?.signsCompleted.where(validSignIds.contains),
      };
      final restoredSkipped = <String>{
        ...?progress?.signsSkipped.where(validSignIds.contains),
      };
      final restoredSession = _buildAssessmentSession(signs: signs);
      final restoredGuidedDone =
          signs.isNotEmpty &&
          restoredPracticed.length == signs.length &&
          restoredSkipped.isEmpty;
      restoredSession.guidedPracticePassed = restoredGuidedDone;
      if (progress != null && progress.assessmentResults.isNotEmpty) {
        _hydrateAssessmentResultsFromMap(
          session: restoredSession,
          assessmentResults: progress.assessmentResults,
        );
      }

      final statusSkipped = restoredSession.skippedAssessmentTypes;
      final restoredSkippedAssessments = _orderedEnabledAssessmentTypes([
        ...?progress?.assessmentsSkipped,
        ...statusSkipped,
      ]);
      final savedAssessmentResume = _normalizeAssessmentType(
        progress?.assessmentResumeFrom ?? '',
      );
      final restoredAssessmentResume =
          savedAssessmentResume != null &&
              restoredSession.enabledAssessments.contains(
                savedAssessmentResume,
              ) &&
              !_isAssessmentSatisfiedForCompletion(
                restoredSession,
                savedAssessmentResume,
              )
          ? savedAssessmentResume
          : restoredSession.firstIncompleteAssessmentType;
      final savedIndex = progress?.guidedCurrentIndex;
      final resumeIndex = computeGuidedResumeIndex(
        signCount: signs.length,
        savedIndex: savedIndex,
        practicedSignIds: restoredPracticed,
        skippedSignIds: restoredSkipped,
        orderedSignIds: signs.map((sign) => sign.id).toList(growable: false),
      );

      if (!mounted) return;
      setState(() {
        _signs = signs;
        _index = resumeIndex;
        _practicedSignIds
          ..clear()
          ..addAll(restoredPracticed);
        _skippedSignIds
          ..clear()
          ..addAll(restoredSkipped);
        _skippedAssessmentTypes
          ..clear()
          ..addAll(restoredSkippedAssessments);
        _assessmentResumeType = restoredAssessmentResume;
        _assessmentSession = restoredSession;
        _totalPracticeSeconds = progress?.timeSpentSeconds ?? 0;
        _loading = false;
      });

      if (restoredSkipped.isNotEmpty) {
        final pendingCount = restoredSkipped.length;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.signalYellow,
              content: Text(
                '$pendingCount guided sign(s) are pending. Lesson completion stays locked until pending steps are done.',
              ),
              duration: const Duration(milliseconds: 1400),
            ),
          );
        });
      } else if (_guidedPracticeDone && restoredAssessmentResume != null) {
        final resumeType = _assessmentTitle(restoredAssessmentResume);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.signalYellow,
              content: Text(
                '$resumeType assessment is pending. Lesson completion remains blocked until pending steps are finished.',
              ),
              duration: const Duration(milliseconds: 1500),
            ),
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  double _calculateLessonAccuracy(LessonAssessmentSession session) {
    final components = <double>[];

    if (_signs.isNotEmpty) {
      final guidedAccuracy = (_practicedSignIds.length / _signs.length).clamp(
        0.0,
        1.0,
      );
      components.add(guidedAccuracy);
    }

    if (session.isAssessmentRequired('matching')) {
      final totalPairs = session.matchingResult.submittedPairs.length;
      if (totalPairs > 0) {
        final incorrectPairs = session.matchingResult.incorrectPairs.length;
        final correctPairs = (totalPairs - incorrectPairs).clamp(0, totalPairs);
        components.add(correctPairs / totalPairs);
      }
    }

    if (session.isAssessmentRequired('recall')) {
      components.add(
        session.recallResult.status == AssessmentStatus.passed ? 1.0 : 0.0,
      );
    }

    if (session.isAssessmentRequired('mcq')) {
      final totalQuestions = session.mcqResult.questions.length;
      if (totalQuestions > 0) {
        components.add((session.mcqResult.score / totalQuestions).clamp(0, 1));
      }
    }

    if (components.isEmpty) return 0;

    final sum = components.fold<double>(0, (acc, value) => acc + value);
    return (sum / components.length).clamp(0.0, 1.0);
  }

  Future<void> _completeLesson({
    required int timeSpentSeconds,
    required double accuracy,
    required LessonAssessmentSession session,
  }) async {
    if (_completed) return;
    _completed = true;
    try {
      await _db.completeLesson(
        lessonId: widget.lesson.id,
        categoryId: widget.categoryId,
        accuracy: accuracy,
        timeSpentSeconds: timeSpentSeconds,
        gemsEarned: widget.lesson.gemsReward,
        coinsEarned: widget.lesson.coinsReward,
        xpEarned: widget.lesson.xpReward,
        signsCount: _signs.length,
        assessmentResults: _serializeAssessmentResults(session),
      );
    } catch (_) {}
  }

  Future<void> _practiceCurrentSign() async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonPracticePage(
          lesson: widget.lesson,
          signs: [_current],
          lessonSignNumber: _index + 1,
          lessonSignTotal: _signs.length,
        ),
      ),
    );

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete this sign practice to unlock the next sign.'),
        ),
      );
      return;
    }

    if (result < 0) {
      final skippedSignId = _current.id;
      final skippedWord = _current.word.toUpperCase();
      final nextIndex = _index >= _signs.length - 1
          ? _index
          : (_index + 1).clamp(0, _signs.length - 1);

      try {
        await _db.markSignSkipped(
          lessonId: widget.lesson.id,
          signId: skippedSignId,
          nextIndex: nextIndex,
        );
      } catch (_) {}

      if (_index >= _signs.length - 1) {
        setState(() {
          _skippedSignIds.add(skippedSignId);
        });
        await _persistGuidedPracticeCheckpoint();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Skipped and marked pending. Lesson completion remains locked.',
            ),
          ),
        );
        if (_guidedSequenceFinished) {
          await _runAssessmentFlow();
        }
        return;
      }

      final nextWord = _signs[nextIndex].word.toUpperCase();

      setState(() {
        _skippedSignIds.add(skippedSignId);
        _index = nextIndex;
        _showTips = false;
      });

      await _persistGuidedPracticeCheckpoint();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.signalYellow,
          content: Text(
            'Skipped $skippedWord and marked pending. Next sign: $nextWord.',
          ),
          duration: const Duration(milliseconds: 950),
        ),
      );
      return;
    }

    final completedSignId = _current.id;
    final nextSignWord = _index < _signs.length - 1
        ? _signs[_index + 1].word.toUpperCase()
        : null;
    final persistedNextIndex = _index >= _signs.length - 1
        ? _index
        : (_index + 1).clamp(0, _signs.length - 1);

    try {
      await _db.completeSign(
        widget.lesson.id,
        completedSignId,
        nextIndex: persistedNextIndex,
      );
    } catch (_) {}

    setState(() {
      _practicedSignIds.add(completedSignId);
      _skippedSignIds.remove(completedSignId);
      _totalPracticeSeconds += result;
    });

    await _persistGuidedPracticeCheckpoint();

    if (_index >= _signs.length - 1) {
      await _runAssessmentFlow();
      return;
    }

    setState(() {
      _index++;
      _showTips = false;
    });

    if (nextSignWord != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.mintGreen,
          content: Text('Great! Next sign: $nextSignWord'),
          duration: const Duration(milliseconds: 950),
        ),
      );
    }
  }

  LessonAssessmentSession _buildAssessmentSession({List<SignModel>? signs}) {
    final sourceSigns = signs ?? _signs;

    return LessonAssessmentSession(
      lessonId: widget.lesson.id,
      categoryId: widget.categoryId,
      signPool: sourceSigns
          .map((sign) => sign.word.toUpperCase().trim())
          .toList(growable: false),
      enabledAssessments: widget.lesson.enabledAssessmentTypes,
      guidedPracticePassed: _guidedPracticeDone,
    );
  }

  Future<_AssessmentMediaBundle> _prepareAssessmentMediaBundle() async {
    List<String> globalLabels = const <String>[];
    try {
      globalLabels = await _db.getGlobalSignLabels();
    } catch (_) {
      globalLabels = const <String>[];
    }

    final imageRefsBySignId = <String, String>{};

    for (final sign in _signs) {
      final resolvedRef =
          (await _imageService.resolveImageRefForWord(
            sign.word,
            lessonImageRef: sign.imageUrl,
            lessonFallbackRef: sign.gifUrl,
            fallbackLabel: sign.id,
          ))?.trim() ??
          '';

      if (resolvedRef.isNotEmpty) {
        imageRefsBySignId[sign.id] = resolvedRef;
      }
    }

    return _AssessmentMediaBundle(
      imageRefsBySignId: imageRefsBySignId,
      globalDistractorPool: globalLabels,
    );
  }

  AssessmentStatus _statusForAssessmentType(
    LessonAssessmentSession session,
    String assessmentType,
  ) {
    switch (assessmentType) {
      case 'matching':
        return session.matchingResult.status;
      case 'recall':
        return session.recallResult.status;
      case 'mcq':
        return session.mcqResult.status;
      default:
        return AssessmentStatus.notStarted;
    }
  }

  bool _isAssessmentSatisfiedForCompletion(
    LessonAssessmentSession session,
    String assessmentType,
  ) {
    final status = _statusForAssessmentType(session, assessmentType);

    if (assessmentType == 'recall') {
      return status == AssessmentStatus.passed;
    }

    if (assessmentType == 'matching' || assessmentType == 'mcq') {
      return status == AssessmentStatus.passed ||
          status == AssessmentStatus.attempted;
    }

    return status == AssessmentStatus.passed;
  }

  bool _shouldRunAssessment(
    LessonAssessmentSession session,
    String assessmentType,
  ) {
    final status = _statusForAssessmentType(session, assessmentType);

    if (status == AssessmentStatus.notStarted ||
        status == AssessmentStatus.inProgress ||
        status == AssessmentStatus.skipped ||
        status == AssessmentStatus.failed) {
      return true;
    }

    return !_isAssessmentSatisfiedForCompletion(session, assessmentType);
  }

  Future<void> _runAssessmentFlow() async {
    if (_assessmentFlowStarted) return;
    _assessmentFlowStarted = true;
    final assessmentFlowStartedAt = DateTime.now();
    var assessmentTimeApplied = false;

    void applyAssessmentFlowTime() {
      if (assessmentTimeApplied) return;
      assessmentTimeApplied = true;

      final elapsed = DateTime.now()
          .difference(assessmentFlowStartedAt)
          .inSeconds;
      if (elapsed <= 0) return;

      if (mounted) {
        setState(() {
          _totalPracticeSeconds += elapsed;
        });
      } else {
        _totalPracticeSeconds += elapsed;
      }
    }

    try {
      if (!_guidedSequenceFinished) {
        await _showBlockedCompletionDialog(
          'Assessments unlock after each guided sign has been practiced or skipped.',
        );
        return;
      }

      final session = _buildAssessmentSession();
      if (_assessmentSession != null) {
        session.matchingResult = _assessmentSession!.matchingResult;
        session.recallResult = _assessmentSession!.recallResult;
        session.mcqResult = _assessmentSession!.mcqResult;
      }
      session.guidedPracticePassed = _guidedPracticeDone;
      _assessmentSession = session;

      final enabledAssessments = session.enabledAssessments;

      final requiresImageAssessments = enabledAssessments.any((type) {
        if (type != 'matching' && type != 'mcq') return false;
        return _shouldRunAssessment(session, type);
      });

      var mediaBundle = const _AssessmentMediaBundle.empty();
      if (requiresImageAssessments) {
        mediaBundle = await _prepareAssessmentMediaBundle();
      }

      if (enabledAssessments.isNotEmpty) {
        for (final assessmentType in enabledAssessments) {
          if (!_shouldRunAssessment(session, assessmentType)) {
            continue;
          }

          if (assessmentType == 'matching') {
            if (_signs.length < 2) {
              session.matchingResult = session.matchingResult.copyWith(
                status: AssessmentStatus.attempted,
                completedAt: DateTime.now(),
                errorMessage: null,
              );
              await _persistAssessmentSession(session);
              continue;
            }

            final matchingResult =
                await Navigator.push<MatchingAssessmentResult>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchingAssessmentPage(
                      signs: _signs,
                      imageRefsBySignId: mediaBundle.imageRefsBySignId,
                    ),
                  ),
                );

            if (!mounted) return;

            final previousAttempts = session.matchingResult.attemptCount;
            final runAttempts = matchingResult?.attemptCount ?? 0;

            session.matchingResult =
                matchingResult ??
                session.matchingResult.copyWith(
                  status: AssessmentStatus.skipped,
                  completedAt: DateTime.now(),
                );
            session.matchingResult = session.matchingResult.copyWith(
              attemptCount: previousAttempts + runAttempts,
            );

            if (session.matchingResult.status == AssessmentStatus.skipped) {
              await _saveAssessmentSkipAndContinue('matching', session);
              continue;
            }

            if (session.matchingResult.status == AssessmentStatus.failed) {
              session.matchingResult = session.matchingResult.copyWith(
                status: AssessmentStatus.attempted,
                completedAt: DateTime.now(),
                errorMessage: null,
              );
              await _persistAssessmentSession(session);
              continue;
            }

            await _persistAssessmentSession(session);

            continue;
          }

          if (assessmentType == 'recall') {
            final recallResult = await Navigator.push<RecallAssessmentResult>(
              context,
              MaterialPageRoute(
                builder: (_) => RecallAssessmentPage(signs: _signs),
              ),
            );

            if (!mounted) return;

            final previousAttempts = session.recallResult.attemptCount;
            final runAttempts = recallResult?.attemptCount ?? 0;

            session.recallResult =
                recallResult ??
                session.recallResult.copyWith(
                  status: AssessmentStatus.skipped,
                  completedAt: DateTime.now(),
                );
            session.recallResult = session.recallResult.copyWith(
              attemptCount: previousAttempts + runAttempts,
            );

            if (session.recallResult.status == AssessmentStatus.skipped) {
              await _saveAssessmentSkipAndContinue('recall', session);
              continue;
            }

            if (session.recallResult.status != AssessmentStatus.passed) {
              await _persistAssessmentSession(session);
              await _showBlockedCompletionDialog(
                'Recall must be completed before you can finish this lesson.',
              );
              return;
            }

            await _persistAssessmentSession(session);
            continue;
          }

          if (assessmentType == 'mcq') {
            final mcqResult = await Navigator.push<McqAssessmentResult>(
              context,
              MaterialPageRoute(
                builder: (_) => McqRecognitionAssessmentPage(
                  signs: _signs,
                  imageRefsBySignId: mediaBundle.imageRefsBySignId,
                  globalDistractorPool: mediaBundle.globalDistractorPool,
                  questionScope: _mcqQuestionScope,
                ),
              ),
            );

            if (!mounted) return;

            final previousAttempts = session.mcqResult.attemptCount;
            final runAttempts = mcqResult?.attemptCount ?? 0;

            session.mcqResult =
                mcqResult ??
                session.mcqResult.copyWith(
                  status: AssessmentStatus.skipped,
                  completedAt: DateTime.now(),
                );
            session.mcqResult = session.mcqResult.copyWith(
              attemptCount: previousAttempts + runAttempts,
            );

            if (session.mcqResult.status == AssessmentStatus.skipped) {
              await _saveAssessmentSkipAndContinue('mcq', session);
              continue;
            }

            if (session.mcqResult.status == AssessmentStatus.failed) {
              await _persistAssessmentSession(session);
              await _showBlockedCompletionDialog(
                'Recognition assessment could not run due to missing content. Please update lesson media and try again.',
              );
              return;
            }

            await _persistAssessmentSession(session);
          }
        }
      }

      await _persistAssessmentSession(session);

      if (!session.canCompleteLesson) {
        final pendingGuidedCount = _pendingGuidedCount;
        final pendingAssessmentCount = _pendingAssessmentCountForSession(
          session,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lesson incomplete: $pendingGuidedCount guided and $pendingAssessmentCount assessment step(s) pending.',
            ),
          ),
        );
        return;
      }

      final shouldComplete = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => LessonCompletionSummaryPage(
            lesson: widget.lesson,
            session: _assessmentSession ?? session,
            practiceSeconds: _totalPracticeSeconds,
          ),
        ),
      );

      if (!mounted) return;

      if (shouldComplete == true) {
        applyAssessmentFlowTime();
        final accuracy = _calculateLessonAccuracy(session);
        await _persistAssessmentSession(session);
        await _completeLesson(
          timeSpentSeconds: _totalPracticeSeconds,
          accuracy: accuracy,
          session: session,
        );
        if (!mounted) return;
        setState(() {
          _assessmentResumeType = null;
          _skippedAssessmentTypes.clear();
        });
        _showCompletionDialog();
      }
    } finally {
      applyAssessmentFlowTime();
      _assessmentFlowStarted = false;
    }
  }

  Future<void> _showBlockedCompletionDialog(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lesson Not Completed'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continue Lesson'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lesson Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nice move. You nailed this lesson.'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (widget.lesson.gemsReward > 0)
                  NeoSticker(
                    label: '+${widget.lesson.gemsReward} GEMS',
                    color: AppTheme.signalYellow,
                    icon: Icons.diamond,
                  ),
                if (widget.lesson.xpReward > 0)
                  NeoSticker(
                    label: '+${widget.lesson.xpReward} XP',
                    color: AppTheme.mintGreen,
                    icon: Icons.bolt,
                  ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _resumePendingGuidedSign() {
    final pendingIndex = _firstPendingGuidedSignIndex;
    if (pendingIndex == null) return;

    setState(() {
      _index = pendingIndex;
      _showTips = false;
    });
  }

  ({String label, VoidCallback onPressed}) _primaryCtaConfig() {
    final session = _assessmentSession ?? _buildAssessmentSession();
    session.guidedPracticePassed = _guidedPracticeDone;

    final cta = decidePrimaryLessonCta(
      currentSignNeedsWork: !_practicedSignIds.contains(_current.id),
      guidedSequenceFinished: _guidedSequenceFinished,
      pendingGuidedCount: _pendingGuidedCount,
      pendingAssessmentCount: _pendingAssessmentCountForSession(session),
      canCompleteLesson: session.canCompleteLesson,
    );

    switch (cta.action) {
      case PrimaryLessonAction.practiceCurrentSign:
        return (label: cta.label, onPressed: _practiceCurrentSign);
      case PrimaryLessonAction.resumePendingGuided:
        return (label: cta.label, onPressed: _resumePendingGuidedSign);
      case PrimaryLessonAction.continueAssessments:
        return (label: cta.label, onPressed: _runAssessmentFlow);
      case PrimaryLessonAction.showCompletionSummary:
        return (label: cta.label, onPressed: _runAssessmentFlow);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.paperCream,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.cobaltBlue),
        ),
      );
    }

    if (_signs.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.paperCream,
        body: NeoEmptyState(
          icon: Icons.sign_language_outlined,
          title: 'No Signs In Lesson',
          subtitle: 'This lesson currently has no sign items.',
        ),
      );
    }

    final progress = (_index + 1) / _signs.length;
    final primaryCta = _primaryCtaConfig();

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.warmWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.inkBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.inkBlack,
                            blurRadius: 0,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.inkBlack,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeoPanel(
                      color: AppTheme.warmWhite,
                      radius: 14,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      shadow: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lesson.title,
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: AppTheme.paperCream,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.cobaltBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_index + 1}/${_signs.length}',
                    style: const TextStyle(
                      color: AppTheme.inkBlack,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: NeoPanel(
                  color: AppTheme.warmWhite,
                  radius: 18,
                  child: Column(
                    children: [
                      Text(
                        _current.word,
                        style: const TextStyle(
                          color: AppTheme.inkBlack,
                          fontSize: 46,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.paperCream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.inkBlack,
                              width: 3,
                            ),
                          ),
                          child: FutureBuilder<String?>(
                            future: _imageService.resolveImageRefForWord(
                              _current.word,
                              lessonImageRef: _current.imageUrl,
                              lessonFallbackRef: _current.gifUrl,
                              fallbackLabel: _current.id,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.cobaltBlue,
                                  ),
                                );
                              }

                              final resolvedRef = (snapshot.data ?? '').trim();
                              if (resolvedRef.isNotEmpty) {
                                return _buildGuidedSignMedia(resolvedRef);
                              }

                              return _buildGuidedPlaceholder();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.signalYellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.inkBlack,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _current.difficulty.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_current.instructions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: GestureDetector(
                  onTap: () => setState(() => _showTips = !_showTips),
                  child: NeoPanel(
                    color: AppTheme.signalYellow,
                    radius: 14,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          color: AppTheme.inkBlack,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showTips ? 'Hide tips' : 'Show tips',
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_showTips)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: NeoPanel(
                  color: AppTheme.softPeach,
                  radius: 14,
                  shadow: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _current.instructions
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${entry.key + 1}. ${entry.value}',
                              style: const TextStyle(
                                color: AppTheme.inkBlack,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              child: Column(
                children: [
                  if (_practicedSignIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'PRACTICED ${_practicedSignIds.length}/${_signs.length}',
                        style: const TextStyle(
                          color: AppTheme.inkBlack,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _assessmentFlowStarted
                          ? null
                          : _restartLessonFromStart,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.inkBlack,
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text(
                        'Restart Lesson',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: NeoPrimaryButton(
                      label: primaryCta.label,
                      onPressed: _assessmentFlowStarted
                          ? null
                          : primaryCta.onPressed,
                      icon: Icons.camera_alt,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
