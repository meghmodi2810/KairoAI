import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../models/lesson_assessment_models.dart';
import '../../services/sign_detection_service.dart';
import '../../theme/app_theme.dart';

class RecallAssessmentPage extends StatefulWidget {
  final List<SignModel> signs;

  const RecallAssessmentPage({super.key, required this.signs});

  @override
  State<RecallAssessmentPage> createState() => _RecallAssessmentPageState();
}

class _RecallAssessmentPageState extends State<RecallAssessmentPage>
    with WidgetsBindingObserver {
  static const int _requiredStableDetections = 3;
  static const double _minConfidence = 0.65;

  final SignDetectionService _detection = SignDetectionService();

  StreamSubscription<DetectionResult>? _sub;
  DetectionResult? _result;

  late final List<SignModel> _promptOrder;
  final List<RecallPromptResult> _perPromptResults = <RecallPromptResult>[];

  int _index = 0;
  int _matchCount = 0;
  int _attemptCount = 1;
  bool _promptLocked = false;
  bool _cameraOn = false;
  bool _loading = true;
  bool _hasPermission = false;
  bool get _hasPrompts => _promptOrder.isNotEmpty;

  SignModel get _currentPrompt => _promptOrder[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final shuffled = List<SignModel>.from(widget.signs)..shuffle();
    _promptOrder = shuffled.isEmpty
        ? <SignModel>[]
        : <SignModel>[shuffled.first];
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopCamera();
    }
    if (state == AppLifecycleState.resumed && _hasPermission) {
      _startCamera();
    }
  }

  Future<void> _initCamera() async {
    bool granted = await _detection.checkCameraPermission();
    if (!granted) {
      granted = await _detection.requestCameraPermission();
    }

    if (!mounted) return;
    setState(() {
      _hasPermission = granted;
      _loading = false;
    });

    if (granted) {
      await _startCamera();
    }
  }

  Future<void> _startCamera({bool retryOnFail = true}) async {
    if (_cameraOn) return;

    setState(() => _loading = true);
    try {
      await _detection.startDetection();
      _sub = _detection.detectionStream.listen(_onDetection);
      if (!mounted) return;
      setState(() {
        _cameraOn = true;
        _loading = false;
      });
    } catch (_) {
      if (retryOnFail && _hasPermission) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        await _startCamera(retryOnFail: false);
        return;
      }
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _stopCamera() async {
    await _sub?.cancel();
    _sub = null;

    try {
      await _detection.stopDetection();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _cameraOn = false);
  }

  void _onDetection(DetectionResult result) {
    if (!mounted || _promptLocked || !_hasPrompts) return;

    setState(() => _result = result);

    final target = _currentPrompt.word.toUpperCase().trim();
    final detected = result.detectedSign.toUpperCase().trim();

    if (result.handDetected &&
        detected == target &&
        result.confidence >= _minConfidence) {
      _matchCount++;
      if (_matchCount >= _requiredStableDetections) {
        _confirmPromptPass();
      }
    } else if (result.handDetected && _matchCount > 0) {
      _matchCount--;
    }
  }

  void _confirmPromptPass() {
    if (_promptLocked) return;

    _promptLocked = true;
    HapticFeedback.heavyImpact();

    final detection = _result;
    _perPromptResults.add(
      RecallPromptResult(
        targetSign: _currentPrompt.word.toUpperCase().trim(),
        detectedSign: (detection?.detectedSign ?? '').toUpperCase().trim(),
        passed: true,
        confidence: detection?.confidence ?? 0,
        stableDetectionsAchieved: _matchCount,
        requiredStableDetections: _requiredStableDetections,
        timestamp: DateTime.now(),
      ),
    );

    Future.delayed(const Duration(milliseconds: 750), _advancePrompt);
  }

  Future<void> _advancePrompt() async {
    if (_index >= _promptOrder.length - 1) {
      await _finishPassed();
      return;
    }

    setState(() {
      _index++;
      _promptLocked = false;
      _matchCount = 0;
      _result = null;
    });

    _detection.resetPrediction().catchError((_) {});
  }

  Future<void> _finishPassed() async {
    await _stopCamera();
    if (!mounted) return;

    Navigator.of(context).pop(
      RecallAssessmentResult(
        status: AssessmentStatus.passed,
        attemptCount: _attemptCount,
        completedAt: DateTime.now(),
        promptOrder: _promptOrder
            .map((sign) => sign.word.toUpperCase().trim())
            .toList(growable: false),
        perPromptResults: List<RecallPromptResult>.from(_perPromptResults),
      ),
    );
  }

  Future<void> _skipRecall() async {
    await _stopCamera();
    if (!mounted) return;

    Navigator.of(context).pop(
      RecallAssessmentResult(
        status: AssessmentStatus.skipped,
        attemptCount: _attemptCount,
        completedAt: DateTime.now(),
        promptOrder: _promptOrder
            .map((sign) => sign.word.toUpperCase().trim())
            .toList(growable: false),
        perPromptResults: List<RecallPromptResult>.from(_perPromptResults),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    await _skipRecall();
    return false;
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= _minConfidence) return AppTheme.mintGreen;
    if (confidence >= 0.4) return AppTheme.signalYellow;
    return AppTheme.punchRed;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPrompts) {
      return Scaffold(
        backgroundColor: AppTheme.paperCream,
        appBar: AppBar(
          backgroundColor: AppTheme.paperCream,
          elevation: 0,
          title: const Text(
            'Recall Test',
            style: TextStyle(
              color: AppTheme.inkBlack,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: Center(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(
                const RecallAssessmentResult(status: AssessmentStatus.skipped),
              );
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ),
      );
    }

    final confidence = _result?.confidence ?? 0;
    final confidenceColor = _confidenceColor(confidence);
    final prediction = (_result?.handDetected ?? false)
        ? ((_result?.detectedSign.trim().isNotEmpty ?? false)
              ? _result!.detectedSign.toUpperCase().trim()
              : '--')
        : '--';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.charcoalNight,
        body: Stack(
          children: [
            Positioned.fill(
              child: _cameraOn && _detection.textureId != null
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: 1080,
                        height: 1440,
                        child: Texture(textureId: _detection.textureId!),
                      ),
                    )
                  : const ColoredBox(color: Colors.black),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.68),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    _hudCircle(icon: Icons.close_rounded, onTap: _skipRecall),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warmWhite.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.inkBlack,
                            width: 2.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.psychology_alt,
                              color: AppTheme.inkBlack,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'RECALL ${_currentPrompt.word.toUpperCase().trim()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.inkBlack,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_index + 1}/${_promptOrder.length}',
                              style: const TextStyle(
                                color: AppTheme.inkBlack,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _hudCircle(
                      icon: Icons.cameraswitch_rounded,
                      onTap: () => _detection.switchCamera(),
                      background: AppTheme.electricBlue,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 92,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (_result?.handDetected ?? false)
                      ? AppTheme.mintGreen
                      : AppTheme.signalYellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.inkBlack, width: 2.5),
                ),
                child: Text(
                  (_result?.handDetected ?? false)
                      ? 'HAND DETECTED'
                      : 'SHOW HAND',
                  style: const TextStyle(
                    color: AppTheme.inkBlack,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 130,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.signalYellow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.inkBlack, width: 3),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Target',
                      style: TextStyle(
                        color: AppTheme.inkBlack,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _currentPrompt.word.toUpperCase().trim(),
                      style: const TextStyle(
                        color: AppTheme.inkBlack,
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  12,
                  10,
                  12,
                  MediaQuery.of(context).padding.bottom + 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warmWhite,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  border: Border.all(color: AppTheme.inkBlack, width: 3),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 66,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.cobaltBlue,
                          ),
                        ),
                      )
                    : !_hasPermission
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Need camera access for recall test.',
                            style: TextStyle(
                              color: AppTheme.inkBlack,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _initCamera,
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Enable Camera'),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _matchCount == 0
                                      ? 'Perform the prompted sign from memory.'
                                      : 'Hold steady for one more clean match.',
                                  style: const TextStyle(
                                    color: AppTheme.inkBlack,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                '${(confidence * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: AppTheme.inkBlack,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: confidence,
                              minHeight: 10,
                              backgroundColor: AppTheme.paperCream,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                confidenceColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Prediction: $prediction',
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ...List.generate(
                                _requiredStableDetections,
                                (i) => Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      right: i == _requiredStableDetections - 1
                                          ? 0
                                          : 6,
                                    ),
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: i < _matchCount
                                          ? AppTheme.mintGreen
                                          : AppTheme.paperCream,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.inkBlack,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: _skipRecall,
                              icon: const Icon(Icons.skip_next_rounded),
                              label: const Text('Skip Test'),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudCircle({
    required IconData icon,
    required VoidCallback onTap,
    Color background = AppTheme.warmWhite,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: background,
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
        child: Icon(icon, color: AppTheme.inkBlack),
      ),
    );
  }
}
