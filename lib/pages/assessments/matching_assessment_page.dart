import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../models/lesson_assessment_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_brutal_widgets.dart';

class MatchingAssessmentPage extends StatefulWidget {
  final List<SignModel> signs;
  final Map<String, String> imageRefsBySignId;

  const MatchingAssessmentPage({
    super.key,
    required this.signs,
    required this.imageRefsBySignId,
  });

  @override
  State<MatchingAssessmentPage> createState() => _MatchingAssessmentPageState();
}

class _MatchingAssessmentPageState extends State<MatchingAssessmentPage> {
  static const double _slotHeight = 158;
  static const double _slotSpacing = 10;

  final List<SignModel> _signs = <SignModel>[];
  final List<String> _labels = <String>[];

  final Map<String, String> _assignedBySignId = <String, String>{};
  final Set<String> _incorrectSignIds = <String>{};
  final List<String> _submitReviewLines = <String>[];
  final Map<String, String> _latestIncorrectPairs = <String, String>{};

  String? _selectedSignId;
  String? _feedback;
  String? _contentError;
  bool _feedbackError = false;
  bool _readyForNextAssessment = false;
  int _attemptCount = 0;

  double get _slotExtent => _slotHeight + _slotSpacing;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    if (widget.signs.length < 2) {
      _contentError = 'Matching requires at least two signs in this lesson.';
      return;
    }

    final shuffledSigns = List<SignModel>.from(widget.signs)..shuffle();
    final shuffledLabels = shuffledSigns
        .map((sign) => sign.word.toUpperCase().trim())
        .toList(growable: false)
      ..shuffle();

    _signs.addAll(shuffledSigns);
    _labels.addAll(shuffledLabels);
    _selectedSignId = _signs.first.id;
  }

  bool get _hasSigns => _signs.isNotEmpty;
  bool get _allAssigned => _assignedBySignId.length == _signs.length;
  double get _progress =>
      _hasSigns ? _assignedBySignId.length / _signs.length : 0;

  Future<bool> _onWillPop() async {
    _skipAssessment();
    return false;
  }

  void _showFeedback(String message, {required bool isError}) {
    setState(() {
      _feedback = message;
      _feedbackError = isError;
    });
  }

  String? _ownerOfLabel(String label) {
    for (final entry in _assignedBySignId.entries) {
      if (entry.value == label) return entry.key;
    }
    return null;
  }

  void _selectSign(String signId) {
    setState(() {
      _selectedSignId = signId;
      _feedback = null;
    });
  }

  void _assignLabelToSelected(String label) {
    if (!_hasSigns || _selectedSignId == null) {
      _showFeedback('Select a sign first.', isError: true);
      return;
    }

    final selectedSignId = _selectedSignId!;
    final currentOwner = _ownerOfLabel(label);
    if (currentOwner != null && currentOwner != selectedSignId) {
      _showFeedback('That label is already used.', isError: true);
      return;
    }

    final selectedSign = _signs.firstWhere((sign) => sign.id == selectedSignId);
    final expected = selectedSign.word.toUpperCase().trim();

    setState(() {
      _assignedBySignId[selectedSignId] = label;
      _incorrectSignIds.clear();
      _submitReviewLines.clear();
      _latestIncorrectPairs.clear();
      _readyForNextAssessment = false;
      _feedback = label == expected ? 'Matched $label' : 'Paired $label';
      _feedbackError = false;
    });
  }

  void _clearSelectedPair() {
    if (_selectedSignId == null) return;
    final signId = _selectedSignId!;

    if (!_assignedBySignId.containsKey(signId)) {
      _showFeedback('Selected sign has no pair yet.', isError: true);
      return;
    }

    setState(() {
      final removed = _assignedBySignId.remove(signId);
      _incorrectSignIds.remove(signId);
      _submitReviewLines.clear();
      _latestIncorrectPairs.clear();
      _readyForNextAssessment = false;
      _feedback = 'Removed $removed';
      _feedbackError = false;
    });
  }

  void _resetAllPairs() {
    if (_assignedBySignId.isEmpty) return;

    setState(() {
      _assignedBySignId.clear();
      _incorrectSignIds.clear();
      _submitReviewLines.clear();
      _latestIncorrectPairs.clear();
      _readyForNextAssessment = false;
      _feedback = 'Reset all pairs.';
      _feedbackError = false;
      if (_signs.isNotEmpty) {
        _selectedSignId = _signs.first.id;
      }
    });
  }

  void _submitPairs() {
    if (!_allAssigned) {
      _showFeedback('Pair all signs before submitting.', isError: true);
      return;
    }

    _attemptCount += 1;

    final incorrectPairs = <String, String>{};
    final incorrectSignIds = <String>{};
    final reviewLines = <String>[];

    for (final entry in _signs.asMap().entries) {
      final index = entry.key;
      final sign = entry.value;
      final expected = sign.word.toUpperCase().trim();
      final selected = (_assignedBySignId[sign.id] ?? '').toUpperCase().trim();
      if (selected != expected) {
        incorrectPairs[expected] = selected;
        incorrectSignIds.add(sign.id);
        reviewLines.add(
          'Sign ${index + 1}: correct $expected (you chose ${selected.isEmpty ? '--' : selected})',
        );
      }
    }

    setState(() {
      _latestIncorrectPairs
        ..clear()
        ..addAll(incorrectPairs);
      _incorrectSignIds
        ..clear()
        ..addAll(incorrectSignIds);
      _submitReviewLines
        ..clear()
        ..addAll(reviewLines);
      _readyForNextAssessment = true;
      if (incorrectSignIds.isEmpty) {
        _feedback = 'All pairs are correct. Tap Next to continue.';
        _feedbackError = false;
      } else {
        _feedback =
            'Some pairs are wrong. This attempt is recorded. Tap Next to continue.';
        _feedbackError = true;
      }
    });
  }

  void _finishAssessment({
    required AssessmentStatus status,
    String? errorMessage,
  }) {
    Navigator.of(context).pop(
      MatchingAssessmentResult(
        status: status,
        attemptCount: _attemptCount,
        completedAt: DateTime.now(),
        submittedPairs: Map<String, String>.from(_assignedBySignId),
        incorrectPairs: Map<String, String>.from(_latestIncorrectPairs),
        errorMessage: errorMessage,
      ),
    );
  }

  void _goNextAssessment() {
    final status = _latestIncorrectPairs.isEmpty
        ? AssessmentStatus.passed
        : AssessmentStatus.attempted;

    _finishAssessment(status: status);
  }

  void _failDueToContent() {
    _finishAssessment(
      status: AssessmentStatus.failed,
      errorMessage: _contentError,
    );
  }

  void _skipAssessment() {
    if (_contentError != null) {
      _failDueToContent();
      return;
    }

    if (_attemptCount > 0) {
      final status = _latestIncorrectPairs.isEmpty
          ? AssessmentStatus.passed
          : AssessmentStatus.attempted;
      _finishAssessment(status: status);
      return;
    }

    _finishAssessment(status: AssessmentStatus.skipped);
  }

  Widget _buildImageOrPlaceholder(
    SignModel sign, {
    required double width,
    required double height,
    double fontSize = 28,
  }) {
    final imageRef = (widget.imageRefsBySignId[sign.id] ?? '').trim();
    if (imageRef.isEmpty) {
      return _buildSignPlaceholder(sign, width: width, height: height, fontSize: fontSize);
    }

    return Image.asset(
      imageRef,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, error, stackTrace) => _buildSignPlaceholder(
        sign,
        width: width,
        height: height,
        fontSize: fontSize,
      ),
    );
  }

  Widget _buildSignPlaceholder(
    SignModel sign, {
    required double width,
    required double height,
    required double fontSize,
  }) {
    return Container(
      width: width,
      height: height,
      color: AppTheme.paperCream,
      alignment: Alignment.center,
      child: Text(
        sign.word.toUpperCase().trim(),
        style: TextStyle(
          color: AppTheme.cobaltBlue.withValues(alpha: 0.45),
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _buildSignTile(SignModel sign, int index) {
    final selected = sign.id == _selectedSignId;
    final isPaired = _assignedBySignId.containsKey(sign.id);
    final incorrect = _incorrectSignIds.contains(sign.id);

    final borderColor = incorrect
        ? AppTheme.punchRed
        : selected
        ? AppTheme.cobaltBlue
        : isPaired
        ? AppTheme.mintGreen
        : AppTheme.inkBlack;

    return GestureDetector(
      onTap: () => _selectSign(sign.id),
      child: Container(
        height: _slotHeight,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPaired
              ? AppTheme.mintGreen.withValues(alpha: 0.2)
              : AppTheme.warmWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageOrPlaceholder(
                  sign,
                  width: double.infinity,
                  height: double.infinity,
                  fontSize: 44,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Sign ${index + 1}',
                  style: const TextStyle(
                    color: AppTheme.inkBlack,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off_outlined,
                  color: selected ? AppTheme.cobaltBlue : AppTheme.inkBlack,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              isPaired ? 'Paired' : 'Tap to select',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: incorrect ? AppTheme.punchRed : AppTheme.inkBlack,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelTile(String label) {
    final owner = _ownerOfLabel(label);
    final selectedOwns = owner != null && owner == _selectedSignId;
    final usedByOther = owner != null && owner != _selectedSignId;
    final enabled = !usedByOther;

    return SizedBox(
      height: _slotHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: GestureDetector(
            onTap: enabled ? () => _assignLabelToSelected(label) : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              decoration: BoxDecoration(
                color: selectedOwns
                    ? AppTheme.mintGreen.withValues(alpha: 0.35)
                    : AppTheme.signalYellow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.inkBlack, width: 2.2),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedOwns
                        ? Icons.check_circle_rounded
                        : Icons.touch_app_rounded,
                    color: AppTheme.inkBlack,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.inkBlack,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchingBoard() {
    final itemCount = _signs.length;
    final boardHeight = itemCount == 0
        ? 0.0
        : (itemCount * _slotExtent) - _slotSpacing;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final leftWidth = totalWidth * 0.62;
        final rightWidth = totalWidth * 0.24;
        final gapWidth = totalWidth - leftWidth - rightWidth;

        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: leftWidth,
                  child: const Text(
                    'Signs',
                    style: TextStyle(
                      color: AppTheme.inkBlack,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(
                  width: gapWidth,
                  child: const Center(
                    child: Text(
                      'Links',
                      style: TextStyle(
                        color: AppTheme.inkBlack,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: rightWidth,
                  child: const Text(
                    'Labels',
                    style: TextStyle(
                      color: AppTheme.inkBlack,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: boardHeight,
                  child: Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: leftWidth,
                            child: Column(
                              children: _signs
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final isLast =
                                        entry.key == _signs.length - 1;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isLast ? 0 : _slotSpacing,
                                      ),
                                      child: _buildSignTile(
                                        entry.value,
                                        entry.key,
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                          ),
                          SizedBox(width: gapWidth),
                          SizedBox(
                            width: rightWidth,
                            child: Column(
                              children: _labels
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final isLast =
                                        entry.key == _labels.length - 1;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isLast ? 0 : _slotSpacing,
                                      ),
                                      child: _buildLabelTile(entry.value),
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                          ),
                        ],
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _ConnectorLinesPainter(
                              signs: _signs,
                              labels: _labels,
                              assignedBySignId: _assignedBySignId,
                              incorrectSignIds: _incorrectSignIds,
                              leftWidth: leftWidth,
                              gapWidth: gapWidth,
                              slotHeight: _slotHeight,
                              slotSpacing: _slotSpacing,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color color = AppTheme.warmWhite,
  }) {
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.inkBlack, width: 2.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppTheme.inkBlack),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.inkBlack,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnavailableState() {
    final hasContentIssue = _contentError != null;

    return Center(
      child: NeoPanel(
        color: AppTheme.softPeach,
        radius: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasContentIssue
                  ? 'Matching content unavailable for this lesson.'
                  : 'No signs available for this matching test.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.inkBlack,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            if (hasContentIssue) ...[
              const SizedBox(height: 8),
              Text(
                _contentError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.inkBlack,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildActionButton(
              label: 'Back',
              icon: Icons.arrow_back,
              onPressed: hasContentIssue ? _failDueToContent : _skipAssessment,
            ),
          ],
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
            'Matching Test',
            style: TextStyle(
              color: AppTheme.inkBlack,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _skipAssessment,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppTheme.inkBlack,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        body: !_hasSigns
          ? _buildUnavailableState()
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Classic mode: select a sign, then select a label.',
                                    style: TextStyle(
                                      color: AppTheme.inkBlack,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_assignedBySignId.length}/${_signs.length}',
                                  style: const TextStyle(
                                    color: AppTheme.inkBlack,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 9,
                                backgroundColor: AppTheme.warmWhite,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.cobaltBlue,
                                ),
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
                          shadow: false,
                          child: _buildMatchingBoard(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_feedback != null)
                        NeoPanel(
                          color: _feedbackError
                              ? AppTheme.punchRed.withValues(alpha: 0.2)
                              : AppTheme.mintGreen.withValues(alpha: 0.25),
                          radius: 14,
                          shadow: false,
                          child: Text(
                            _feedback!,
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      if (_feedback != null) const SizedBox(height: 10),
                      if (_submitReviewLines.isNotEmpty)
                        NeoPanel(
                          color: AppTheme.softPeach,
                          radius: 14,
                          shadow: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Correct Answers',
                                style: TextStyle(
                                  color: AppTheme.inkBlack,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 110,
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: _submitReviewLines
                                        .map(
                                          (line) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              line,
                                              style: const TextStyle(
                                                color: AppTheme.inkBlack,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_submitReviewLines.isNotEmpty)
                        const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'Clear Sign',
                              icon: Icons.backspace_outlined,
                              onPressed: _selectedSignId == null
                                  ? null
                                  : _clearSelectedPair,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              label: 'Reset',
                              icon: Icons.replay,
                              onPressed: _assignedBySignId.isEmpty
                                  ? null
                                  : _resetAllPairs,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              label: _readyForNextAssessment
                                  ? 'Next'
                                  : 'Submit',
                              icon: _readyForNextAssessment
                                  ? Icons.arrow_forward
                                  : Icons.check,
                              color: AppTheme.signalYellow,
                              onPressed: _readyForNextAssessment
                                  ? _goNextAssessment
                                  : _submitPairs,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ConnectorLinesPainter extends CustomPainter {
  final List<SignModel> signs;
  final List<String> labels;
  final Map<String, String> assignedBySignId;
  final Set<String> incorrectSignIds;
  final double leftWidth;
  final double gapWidth;
  final double slotHeight;
  final double slotSpacing;

  const _ConnectorLinesPainter({
    required this.signs,
    required this.labels,
    required this.assignedBySignId,
    required this.incorrectSignIds,
    required this.leftWidth,
    required this.gapWidth,
    required this.slotHeight,
    required this.slotSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = AppTheme.inkBlack.withValues(alpha: 0.18)
      ..strokeWidth = 1.2;

    final centerX = leftWidth + (gapWidth / 2);
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      guidePaint,
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    for (final entry in assignedBySignId.entries) {
      final signIndex = signs.indexWhere((sign) => sign.id == entry.key);
      final labelIndex = labels.indexOf(entry.value);
      if (signIndex == -1 || labelIndex == -1) continue;

      final isIncorrect = incorrectSignIds.contains(entry.key);
      final lineColor = isIncorrect ? AppTheme.punchRed : AppTheme.cobaltBlue;
      linePaint.color = lineColor;

      final startY = signIndex * (slotHeight + slotSpacing) + (slotHeight / 2);
      final endY = labelIndex * (slotHeight + slotSpacing) + (slotHeight / 2);

      final start = Offset(leftWidth + 1, startY);
      final end = Offset(leftWidth + gapWidth - 1, endY);

      final controlDistance = gapWidth * 0.35;
      final c1 = Offset(start.dx + controlDistance, start.dy);
      final c2 = Offset(end.dx - controlDistance, end.dy);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);

      canvas.drawPath(path, linePaint);
      canvas.drawCircle(start, 3, Paint()..color = lineColor);
      canvas.drawCircle(end, 3, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorLinesPainter oldDelegate) {
    // Pairing maps are mutated in place, so always repaint to keep lines in sync.
    return true;
  }
}
