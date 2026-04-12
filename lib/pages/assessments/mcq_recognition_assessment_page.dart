import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../models/lesson_assessment_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_brutal_widgets.dart';

enum McqQuestionScope { oneRandom, allSigns }

class McqRecognitionAssessmentPage extends StatefulWidget {
  final List<SignModel> signs;
  final Map<String, String> imageRefsBySignId;
  final List<String> globalDistractorPool;
  final McqQuestionScope questionScope;

  const McqRecognitionAssessmentPage({
    super.key,
    required this.signs,
    required this.imageRefsBySignId,
    required this.globalDistractorPool,
    this.questionScope = McqQuestionScope.allSigns,
  });

  @override
  State<McqRecognitionAssessmentPage> createState() =>
      _McqRecognitionAssessmentPageState();
}

class _McqRecognitionAssessmentPageState
    extends State<McqRecognitionAssessmentPage> {
  final Random _random = Random();
  static const String _kSkippedAnswer = '__SKIPPED__';

  late List<_McqQuestionData> _questions;

  final Map<int, String> _selectedAnswers = <int, String>{};
  final Map<int, String> _correctAnswers = <int, String>{};

  int _attemptCount = 0;
  int _index = 0;
  bool _lockedQuestion = false;
  String? _feedback;
  String? _contentError;

  _McqQuestionData get _currentQuestion => _questions[_index];

  bool get _hasAnsweredAnyQuestion {
    return _selectedAnswers.values.any((answer) => answer != _kSkippedAnswer);
  }

  bool get _allQuestionsAnswered {
    if (_questions.isEmpty) return false;
    if (_selectedAnswers.length != _questions.length) return false;
    return !_selectedAnswers.values.contains(_kSkippedAnswer);
  }

  bool get _allAnswersCorrect {
    if (!_allQuestionsAnswered) return false;

    for (var i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] != _correctAnswers[i]) {
        return false;
      }
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _setupQuestions();
  }

  void _setupQuestions() {
    _contentError = null;
    _selectedAnswers.clear();
    _correctAnswers.clear();
    _attemptCount = 0;
    _index = 0;
    _lockedQuestion = false;
    _feedback = null;
    _questions = _buildQuestions();

    if (_questions.isEmpty && _contentError == null) {
      _contentError =
          'Could not generate recognition questions from this lesson sign pool.';
    }
  }

  List<_McqQuestionData> _buildQuestions() {
    if (widget.signs.isEmpty) {
      _contentError = 'This lesson has no signs for recognition questions.';
      return <_McqQuestionData>[];
    }

    final signsWithMedia = widget.signs
        .where(
          (sign) => (widget.imageRefsBySignId[sign.id] ?? '').trim().isNotEmpty,
        )
        .toList(growable: false);

    List<SignModel> selectedSigns;

    if (widget.questionScope == McqQuestionScope.oneRandom) {
      if (signsWithMedia.isEmpty) {
        _contentError =
            'Recognition requires at least one lesson sign with a valid image.';
        return <_McqQuestionData>[];
      }

      final randomPool = List<SignModel>.from(signsWithMedia)..shuffle(_random);
      selectedSigns = <SignModel>[randomPool.first];
    } else {
      if (signsWithMedia.length != widget.signs.length) {
        _contentError =
            'Recognition requires valid images for all lesson signs in all-sign mode.';
        return <_McqQuestionData>[];
      }

      selectedSigns = List<SignModel>.from(signsWithMedia)..shuffle(_random);
    }

    final lessonLabels = widget.signs
        .map((sign) => sign.word.toUpperCase().trim())
        .toSet();

    final globalPool = widget.globalDistractorPool
        .map((label) => label.toUpperCase().trim())
        .where((label) => label.isNotEmpty)
        .toSet();

    final filteredGlobalPool = _sameTypeGlobalPool(
      lessonLabels: lessonLabels,
      globalPool: globalPool,
    );

    final questions = <_McqQuestionData>[];

    for (final sign in selectedSigns) {
      final correct = sign.word.toUpperCase().trim();

      final wrongSet = <String>{};

      final lessonDistractors =
          lessonLabels
              .where((label) => label != correct)
              .toList(growable: false)
            ..shuffle(_random);
      for (final option in lessonDistractors) {
        if (wrongSet.length >= 3) break;
        wrongSet.add(option);
      }

      if (wrongSet.length < 3) {
        final globalDistractors =
            filteredGlobalPool
                .where(
                  (label) => !lessonLabels.contains(label) && label != correct,
                )
                .toList(growable: false)
              ..shuffle(_random);
        for (final option in globalDistractors) {
          if (wrongSet.length >= 3) break;
          wrongSet.add(option);
        }
      }

      final options = <String>[correct, ...wrongSet.take(3)]..shuffle(_random);

      final imageRef = (widget.imageRefsBySignId[sign.id] ?? '').trim();
      if (imageRef.isEmpty) {
        _contentError =
            'Recognition requires a valid image for each question sign.';
        return <_McqQuestionData>[];
      }

      questions.add(
        _McqQuestionData(
          promptSign: correct,
          correctAnswer: correct,
          options: options,
          imageRef: imageRef,
        ),
      );
    }

    questions.shuffle(_random);
    return questions;
  }

  Set<String> _sameTypeGlobalPool({
    required Set<String> lessonLabels,
    required Set<String> globalPool,
  }) {
    final hasLetters = lessonLabels.any(_isLetterLabel);
    final hasDigits = lessonLabels.any(_isDigitLabel);

    if (hasLetters && !hasDigits) {
      return globalPool.where(_isLetterLabel).toSet();
    }

    if (hasDigits && !hasLetters) {
      return globalPool.where(_isDigitLabel).toSet();
    }

    return globalPool;
  }

  bool _isLetterLabel(String value) {
    return RegExp(r'^[A-Z]$').hasMatch(value);
  }

  bool _isDigitLabel(String value) {
    return RegExp(r'^[0-9]$').hasMatch(value);
  }

  int _calculateScore() {
    var score = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _correctAnswers[i]) {
        score++;
      }
    }
    return score;
  }

  AssessmentStatus _resolveResultStatus({required bool completedAllQuestions}) {
    if (_contentError != null) {
      return AssessmentStatus.failed;
    }

    if (!_hasAnsweredAnyQuestion) {
      return AssessmentStatus.skipped;
    }

    if (completedAllQuestions && _allAnswersCorrect) {
      return AssessmentStatus.passed;
    }

    return AssessmentStatus.attempted;
  }

  McqAssessmentResult _buildResult(AssessmentStatus status, {String? error}) {
    final score = _calculateScore();

    return McqAssessmentResult(
      status: status,
      attemptCount: _attemptCount,
      completedAt: DateTime.now(),
      questions: _questions
          .map(
            (q) => McqQuestionRecord(
              promptSign: q.promptSign,
              options: q.options,
              correctAnswer: q.correctAnswer,
            ),
          )
          .toList(growable: false),
      selectedAnswers: Map<int, String>.from(_selectedAnswers),
      correctAnswers: Map<int, String>.from(_correctAnswers),
      score: score,
      errorMessage: error,
    );
  }

  Future<bool> _onWillPop() async {
    _skipAssessment();
    return false;
  }

  void _answerQuestion(String selectedOption) {
    if (_lockedQuestion) return;

    final correct = _currentQuestion.correctAnswer;
    final isCorrect = selectedOption == correct;

    setState(() {
      _attemptCount += 1;
      _lockedQuestion = true;
      _selectedAnswers[_index] = selectedOption;
      _correctAnswers[_index] = correct;
      _feedback = isCorrect
          ? 'Correct answer'
          : 'Wrong answer\nCorrect answer was $correct';
    });
  }

  void _goNext() {
    if (!_lockedQuestion) return;

    if (_index >= _questions.length - 1) {
      final status = _resolveResultStatus(completedAllQuestions: true);
      Navigator.of(context).pop(_buildResult(status));
      return;
    }

    setState(() {
      _index++;
      _lockedQuestion = false;
      _feedback = null;
    });
  }

  void _skipCurrentQuestion() {
    if (_lockedQuestion) return;

    _selectedAnswers[_index] = _kSkippedAnswer;
    _correctAnswers[_index] = _currentQuestion.correctAnswer;

    if (_index >= _questions.length - 1) {
      final status = _resolveResultStatus(completedAllQuestions: true);
      Navigator.of(context).pop(_buildResult(status));
      return;
    }

    setState(() {
      _index++;
      _lockedQuestion = false;
      _feedback = null;
    });
  }

  void _skipAssessment() {
    final status = _resolveResultStatus(completedAllQuestions: false);
    Navigator.of(context).pop(_buildResult(status));
  }

  Widget _buildOption(String option) {
    final selected = _selectedAnswers[_index] == option;
    final correct = _currentQuestion.correctAnswer == option;

    Color background = AppTheme.warmWhite;
    if (_lockedQuestion) {
      if (selected && correct) {
        background = AppTheme.mintGreen;
      } else if (selected && !correct) {
        background = AppTheme.punchRed.withValues(alpha: 0.2);
      } else if (correct) {
        background = AppTheme.mintGreen.withValues(alpha: 0.2);
      }
    } else if (selected) {
      background = AppTheme.signalYellow;
    }

    return GestureDetector(
      onTap: _lockedQuestion ? null : () => _answerQuestion(option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.inkBlack, width: 3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.inkBlack,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionImage(_McqQuestionData question) {
    if (question.imageRef.isEmpty) {
      return _buildQuestionPlaceholder(question.promptSign);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.paperCream,
      alignment: Alignment.center,
      child: Image.asset(
        question.imageRef,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stackTrace) =>
            _buildQuestionPlaceholder(question.promptSign),
      ),
    );
  }

  Widget _buildQuestionPlaceholder(String signLabel) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.paperCream,
      alignment: Alignment.center,
      child: Text(
        signLabel.toUpperCase().trim(),
        style: TextStyle(
          color: AppTheme.cobaltBlue.withValues(alpha: 0.45),
          fontSize: 72,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildContentError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: NeoPanel(
          color: AppTheme.softPeach,
          radius: 18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline, color: AppTheme.punchRed),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recognition content unavailable',
                      style: TextStyle(
                        color: AppTheme.inkBlack,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _contentError ??
                    'Recognition assessment could not be prepared.',
                style: const TextStyle(
                  color: AppTheme.inkBlack,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: NeoSecondaryButton(
                  label: 'Back to lesson',
                  icon: Icons.arrow_back,
                  onPressed: () {
                    Navigator.of(context).pop(
                      _buildResult(
                        AssessmentStatus.failed,
                        error: _contentError,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.paperCream,
        appBar: AppBar(
          backgroundColor: AppTheme.paperCream,
          elevation: 0,
          leading: IconButton(
            onPressed: _skipAssessment,
            icon: const Icon(Icons.close_rounded, color: AppTheme.inkBlack),
          ),
          title: const Text(
            'Recognition Test',
            style: TextStyle(
              color: AppTheme.inkBlack,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: _contentError != null
            ? _buildContentError()
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    children: [
                      NeoPanel(
                        color: AppTheme.softPeach,
                        radius: 16,
                        shadow: false,
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Look at the sign and answer each question. You can skip a question and continue.',
                                style: TextStyle(
                                  color: AppTheme.inkBlack,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_index + 1}/${_questions.length}',
                              style: const TextStyle(
                                color: AppTheme.inkBlack,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: NeoPanel(
                          color: AppTheme.warmWhite,
                          radius: 16,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: _buildQuestionImage(_currentQuestion),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 8,
                                              childAspectRatio: 2.35,
                                            ),
                                        itemCount:
                                            _currentQuestion.options.length,
                                        itemBuilder: (context, i) {
                                          return _buildOption(
                                            _currentQuestion.options[i],
                                          );
                                        },
                                      ),
                                      if (_feedback != null)
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(top: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                _feedback!.startsWith('Wrong')
                                                ? AppTheme.punchRed.withValues(
                                                    alpha: 0.14,
                                                  )
                                                : AppTheme.mintGreen.withValues(
                                                    alpha: 0.2,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.inkBlack,
                                              width: 2,
                                            ),
                                          ),
                                          child: Text(
                                            _feedback!,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: AppTheme.inkBlack,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: NeoSecondaryButton(
                                      label: 'Skip Question',
                                      icon: Icons.skip_next_rounded,
                                      onPressed: _lockedQuestion
                                          ? null
                                          : _skipCurrentQuestion,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: NeoPrimaryButton(
                                      label: _index == _questions.length - 1
                                          ? 'Finish Test'
                                          : 'Next',
                                      icon: Icons.arrow_forward,
                                      onPressed: _lockedQuestion
                                          ? _goNext
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _McqQuestionData {
  final String promptSign;
  final String correctAnswer;
  final List<String> options;
  final String imageRef;

  const _McqQuestionData({
    required this.promptSign,
    required this.correctAnswer,
    required this.options,
    required this.imageRef,
  });
}
