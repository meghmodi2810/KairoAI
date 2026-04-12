import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../models/lesson_assessment_models.dart';
import '../services/database_service.dart';
import '../services/sign_image_service.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
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
  final Map<String, String> imageUrlsBySignId;
  final List<String> globalDistractorPool;

  const _AssessmentMediaBundle({
    required this.imageUrlsBySignId,
    required this.globalDistractorPool,
  });

  const _AssessmentMediaBundle.empty()
    : imageUrlsBySignId = const <String, String>{},
      globalDistractorPool = const <String>[];
}

class _SignLearningPageState extends State<SignLearningPage> {
  static const List<String> _assessmentOrder = <String>[
    'matching',
    'recall',
    'mcq',
  ];

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
  bool get _allGuidedSignsAttempted =>
      _signs.isNotEmpty &&
      (_practicedSignIds.length + _skippedSignIds.length) == _signs.length;
  bool get _guidedPracticeDone =>
      _signs.isNotEmpty &&
      _practicedSignIds.length == _signs.length &&
      _skippedSignIds.isEmpty;

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

  Future<void> _persistAssessmentCheckpoint(List<String> skippedTypes) async {
    final orderedSkipped = _orderedEnabledAssessmentTypes(skippedTypes);
    final resumeType = orderedSkipped.isEmpty ? null : orderedSkipped.first;

    if (mounted) {
      setState(() {
        _skippedAssessmentTypes
          ..clear()
          ..addAll(orderedSkipped);
        _assessmentResumeType = resumeType;
      });
    }

    try {
      await _db.saveAssessmentCheckpoint(
        lessonId: widget.lesson.id,
        skippedAssessmentTypes: orderedSkipped,
        resumeAssessmentType: resumeType,
      );
    } catch (_) {}
  }

  Future<void> _markAssessmentSkipped(String type) async {
    final normalized = _normalizeAssessmentType(type);
    if (normalized == null) return;

    await _persistAssessmentCheckpoint([
      ..._skippedAssessmentTypes,
      normalized,
    ]);
  }

  Future<void> _markAssessmentPassed(String type) async {
    final normalized = _normalizeAssessmentType(type);
    if (normalized == null) return;

    await _persistAssessmentCheckpoint(
      _skippedAssessmentTypes.where((item) => item != normalized).toList(),
    );
  }

  Future<void> _saveAssessmentSkipAndExit(String type) async {
    await _markAssessmentSkipped(type);
    if (!mounted) return;

    final title = _assessmentTitle(type);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Skipped $title assessment saved. You can resume from it anytime.',
        ),
      ),
    );
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
      final restoredSkippedAssessments = _orderedEnabledAssessmentTypes(
        progress?.assessmentsSkipped ?? const <String>[],
      );
      final savedAssessmentResume = _normalizeAssessmentType(
        progress?.assessmentResumeFrom ?? '',
      );
      final restoredAssessmentResume =
          savedAssessmentResume != null &&
              restoredSkippedAssessments.contains(savedAssessmentResume)
          ? savedAssessmentResume
          : (restoredSkippedAssessments.isNotEmpty
                ? restoredSkippedAssessments.first
                : null);

      final savedIndex = progress?.guidedCurrentIndex;
      final firstUnpracticedIndex = signs.indexWhere(
        (sign) => !restoredPracticed.contains(sign.id),
      );
      final firstSkippedIndex = signs.indexWhere(
        (sign) => restoredSkipped.contains(sign.id),
      );
      final resumeIndex = signs.isEmpty
          ? 0
          : firstSkippedIndex != -1
          ? firstSkippedIndex
          : (savedIndex != null && savedIndex >= 0 && savedIndex < signs.length)
          ? savedIndex
          : firstUnpracticedIndex == -1
          ? signs.length - 1
          : firstUnpracticedIndex;

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
        _totalPracticeSeconds = progress?.timeSpentSeconds ?? 0;
        _loading = false;
      });

      if (restoredSkipped.isNotEmpty) {
        final skippedWord = signs[resumeIndex].word.toUpperCase();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.signalYellow,
              content: Text(
                'You skipped $skippedWord earlier. Start from here.',
              ),
              duration: const Duration(milliseconds: 1400),
            ),
          );
        });
      } else if (_guidedPracticeDone && restoredSkippedAssessments.isNotEmpty) {
        final resumeType = _assessmentTitle(restoredAssessmentResume!);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.signalYellow,
              content: Text(
                'You skipped $resumeType assessment earlier. Resume from there.',
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

  Future<void> _completeLesson(int timeSpentSeconds) async {
    if (_completed) return;
    _completed = true;
    try {
      await _db.completeLesson(
        lessonId: widget.lesson.id,
        categoryId: widget.categoryId,
        accuracy: 1.0,
        timeSpentSeconds: timeSpentSeconds,
        gemsEarned: widget.lesson.gemsReward,
        coinsEarned: widget.lesson.coinsReward,
        xpEarned: widget.lesson.xpReward,
        signsCount: _signs.length,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Skipped sign saved. Complete pending signs before assessments.',
            ),
          ),
        );
        return;
      }

      final nextWord = _signs[nextIndex].word.toUpperCase();

      setState(() {
        _skippedSignIds.add(skippedSignId);
        _index = nextIndex;
        _showTips = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.signalYellow,
          content: Text(
            'Skipped $skippedWord. Next sign: $nextWord (completion remains locked).',
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

  LessonAssessmentSession _buildAssessmentSession() {
    return LessonAssessmentSession(
      lessonId: widget.lesson.id,
      categoryId: widget.categoryId,
      signPool: _signs
          .map((sign) => sign.word.toUpperCase().trim())
          .toList(growable: false),
      enabledAssessments: widget.lesson.enabledAssessmentTypes,
      guidedPracticePassed: _allGuidedSignsAttempted,
    );
  }

  Future<_AssessmentMediaBundle> _prepareAssessmentMediaBundle() async {
    final data = await Future.wait<dynamic>([
      _db.getGlobalSignImageUrls(),
      _db.getGlobalSignLabels(),
    ]);

    final globalImages = data[0] as Map<String, String>;
    final globalLabels = data[1] as List<String>;

    final imageUrlsBySignId = <String, String>{};

    for (final sign in _signs) {
      final normalizedWord = sign.word.toUpperCase().trim();

      final syncedLessonMediaUrl = (sign.imageUrl ?? '').trim();
      final lessonPictureUrl = (sign.gifUrl ?? '').trim();
      final globalSignImageUrl = (globalImages[normalizedWord] ?? '').trim();

      final resolvedUrl = syncedLessonMediaUrl.isNotEmpty
          ? syncedLessonMediaUrl
          : lessonPictureUrl.isNotEmpty
          ? lessonPictureUrl
          : globalSignImageUrl;

      if (resolvedUrl.isNotEmpty) {
        imageUrlsBySignId[sign.id] = resolvedUrl;
      }
    }

    return _AssessmentMediaBundle(
      imageUrlsBySignId: imageUrlsBySignId,
      globalDistractorPool: globalLabels,
    );
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
      final session = _buildAssessmentSession();
      _assessmentSession = session;
      final enabledAssessments = session.enabledAssessments;

      if (!session.guidedPracticePassed) {
        await _showBlockedCompletionDialog(
          'Lesson not completed. Finish guided practice for all signs first.',
        );
        return;
      }

      final requiresImageAssessments =
          enabledAssessments.contains('matching') ||
          enabledAssessments.contains('mcq');

      var mediaBundle = const _AssessmentMediaBundle.empty();
      if (requiresImageAssessments) {
        mediaBundle = await _prepareAssessmentMediaBundle();
      }

      if (enabledAssessments.isNotEmpty) {
        final skippedBeforeRun = _orderedEnabledAssessmentTypes(
          _skippedAssessmentTypes,
        ).toSet();

        var resumeFromType = enabledAssessments.first;
        if (_assessmentResumeType != null &&
            enabledAssessments.contains(_assessmentResumeType)) {
          resumeFromType = _assessmentResumeType!;
        } else {
          final firstSkippedInOrder = enabledAssessments.firstWhere(
            skippedBeforeRun.contains,
            orElse: () => enabledAssessments.first,
          );
          resumeFromType = firstSkippedInOrder;
        }

        final startIndex = enabledAssessments.indexOf(resumeFromType);

        // Restore already-completed assessments before the resume point,
        // but never auto-pass anything that is still marked as skipped.
        for (final completedType in enabledAssessments.take(startIndex)) {
          if (skippedBeforeRun.contains(completedType)) continue;

          if (completedType == 'matching') {
            session.matchingResult = session.matchingResult.copyWith(
              status: AssessmentStatus.passed,
              completedAt: DateTime.now(),
            );
            continue;
          }

          if (completedType == 'recall') {
            session.recallResult = session.recallResult.copyWith(
              status: AssessmentStatus.passed,
              completedAt: DateTime.now(),
            );
            continue;
          }

          if (completedType == 'mcq') {
            session.mcqResult = session.mcqResult.copyWith(
              status: AssessmentStatus.passed,
              completedAt: DateTime.now(),
            );
          }
        }

        for (final assessmentType in enabledAssessments.skip(startIndex)) {
          if (assessmentType == 'matching') {
            final matchingResult =
                await Navigator.push<MatchingAssessmentResult>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchingAssessmentPage(
                      signs: _signs,
                      imageUrlsBySignId: mediaBundle.imageUrlsBySignId,
                    ),
                  ),
                );

            if (!mounted) return;

            session.matchingResult =
                matchingResult ??
                session.matchingResult.copyWith(
                  status: AssessmentStatus.skipped,
                  completedAt: DateTime.now(),
                );

            if (session.matchingResult.status == AssessmentStatus.passed) {
              await _markAssessmentPassed('matching');
            } else if (session.matchingResult.status ==
                AssessmentStatus.skipped) {
              await _saveAssessmentSkipAndExit('matching');
              return;
            } else {
              await _showBlockedCompletionDialog(
                'Lesson not completed. Finish all assessments to earn rewards.',
              );
              return;
            }
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

            session.recallResult =
                recallResult ??
                session.recallResult.copyWith(
                  status: AssessmentStatus.skipped,
                  completedAt: DateTime.now(),
                );

            if (session.recallResult.status == AssessmentStatus.passed) {
              await _markAssessmentPassed('recall');
            } else if (session.recallResult.status ==
                AssessmentStatus.skipped) {
              await _saveAssessmentSkipAndExit('recall');
              return;
            } else {
              await _showBlockedCompletionDialog(
                'Lesson not completed. Finish all assessments to earn rewards.',
              );
              return;
            }
            continue;
          }

          if (assessmentType == 'mcq') {
            final mcqResult = await Navigator.push<McqAssessmentResult>(
              context,
              MaterialPageRoute(
                builder: (_) => McqRecognitionAssessmentPage(
                  signs: _signs,
                  imageUrlsBySignId: mediaBundle.imageUrlsBySignId,
                  globalDistractorPool: mediaBundle.globalDistractorPool,
                ),
              ),
            );

            if (!mounted) return;

            session.mcqResult =
                mcqResult ??
                session.mcqResult.copyWith(
                  status: AssessmentStatus.skipped,
                  completedAt: DateTime.now(),
                );

            if (session.mcqResult.status == AssessmentStatus.passed) {
              await _markAssessmentPassed('mcq');
            } else if (session.mcqResult.status == AssessmentStatus.skipped) {
              await _saveAssessmentSkipAndExit('mcq');
              return;
            } else {
              await _showBlockedCompletionDialog(
                'Lesson not completed. Finish all assessments to earn rewards.',
              );
              return;
            }
          }
        }
      }

      if (_skippedSignIds.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You skipped guided signs. Lesson saved as incomplete. Next time you will resume from skipped signs.',
            ),
          ),
        );
        return;
      }

      if (_skippedAssessmentTypes.isNotEmpty) {
        final resumeType = _assessmentTitle(_skippedAssessmentTypes.first);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Skipped $resumeType assessment saved. Next time you will resume from there.',
            ),
          ),
        );
        return;
      }

      if (!session.canCompleteLesson || !session.rewardEligible) {
        await _showBlockedCompletionDialog(
          'Lesson not completed. Finish all assessments to earn rewards.',
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
        await _completeLesson(_totalPracticeSeconds);
        if (!mounted) return;
        _showCompletionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lesson saved as incomplete. You can continue assessments anytime.',
            ),
          ),
        );
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

    final isLast = _index == _signs.length - 1;
    final progress = (_index + 1) / _signs.length;

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
                          child: FutureBuilder<dynamic>(
                            future: _imageService.getRandomImage(_current.word),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.cobaltBlue,
                                  ),
                                );
                              }
                              if (snapshot.hasData && snapshot.data != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.contain,
                                  ),
                                );
                              }
                              return Center(
                                child: Text(
                                  _current.word.toUpperCase(),
                                  style: TextStyle(
                                    color: AppTheme.cobaltBlue.withValues(
                                      alpha: 0.45,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 96,
                                  ),
                                ),
                              );
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
                      label: _guidedPracticeDone
                          ? 'Continue Assessments'
                          : isLast
                          ? 'Practice & Start Assessments'
                          : 'Practice This Sign',
                      onPressed: _guidedPracticeDone
                          ? _runAssessmentFlow
                          : _practiceCurrentSign,
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
