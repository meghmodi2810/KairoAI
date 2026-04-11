import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import '../services/sign_detection_service.dart';
import '../theme/app_theme.dart';

class LessonPracticePage extends StatefulWidget {
  final LessonModel lesson;
  final List<SignModel> signs;

  const LessonPracticePage({
    super.key,
    required this.lesson,
    required this.signs,
  });

  @override
  State<LessonPracticePage> createState() => _LessonPracticePageState();
}

class _LessonPracticePageState extends State<LessonPracticePage>
    with WidgetsBindingObserver {
  final SignDetectionService _detection = SignDetectionService();

  StreamSubscription<DetectionResult>? _sub;
  DetectionResult? _result;

  int _index = 0;
  int _matchCount = 0;
  bool _matched = false;
  bool _cameraOn = false;
  bool _loading = true;
  bool _hasPermission = false;
  int _activePracticeSeconds = 0;
  DateTime? _cameraSegmentStart;

  SignModel get _current => widget.signs[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      _cameraSegmentStart = DateTime.now();
      if (!mounted) return;
      setState(() {
        _cameraOn = true;
        _loading = false;
      });
    } catch (_) {
      if (retryOnFail && _hasPermission) {
        await Future.delayed(const Duration(milliseconds: 260));
        if (!mounted) return;
        await _startCamera(retryOnFail: false);
        return;
      }
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _stopCamera() async {
    if (_cameraSegmentStart != null) {
      _activePracticeSeconds +=
          DateTime.now().difference(_cameraSegmentStart!).inSeconds;
      _cameraSegmentStart = null;
    }

    await _sub?.cancel();
    _sub = null;
    try {
      await _detection.stopDetection();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _cameraOn = false);
  }

  void _onDetection(DetectionResult result) {
    if (!mounted || _matched) return;

    setState(() => _result = result);

    final target = _current.word.toUpperCase().trim();
    final detected = result.detectedSign.toUpperCase().trim();

    if (result.handDetected && detected == target && result.confidence >= 0.65) {
      _matchCount++;
      if (_matchCount >= 3) {
        _confirmMatch();
      }
    } else if (result.handDetected && _matchCount > 0) {
      _matchCount--;
    }
  }

  void _confirmMatch() {
    if (_matched) return;
    setState(() => _matched = true);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 900), _nextSign);
  }

  void _nextSign() {
    if (_index >= widget.signs.length - 1) {
      _finish();
      return;
    }

    setState(() {
      _index++;
      _result = null;
      _matchCount = 0;
      _matched = false;
    });
    _detection.resetPrediction().catchError((_) {});
  }

  Future<void> _finish() async {
    final elapsedSeconds = _elapsedPracticeSeconds().clamp(1, 7200);
    await _stopCamera();
    if (!mounted) return;
    Navigator.pop(context, elapsedSeconds);
  }

  int _elapsedPracticeSeconds() {
    if (_cameraSegmentStart == null) return _activePracticeSeconds;
    return _activePracticeSeconds +
        DateTime.now().difference(_cameraSegmentStart!).inSeconds;
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.65) return AppTheme.mintGreen;
    if (confidence >= 0.4) return AppTheme.signalYellow;
    return AppTheme.punchRed;
  }

  @override
  Widget build(BuildContext context) {
    final confidence = _result?.confidence ?? 0;
    final confidenceColor = _confidenceColor(confidence);

    return Scaffold(
      backgroundColor: AppTheme.charcoalNight,
      body: Stack(
        children: [
          Positioned.fill(
            child: _cameraOn && _detection.textureId != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: 720,
                      height: 1280,
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
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
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
                  _hudCircle(
                    icon: Icons.close_rounded,
                    onTap: () {
                      _stopCamera();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 150,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.warmWhite.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.inkBlack, width: 2.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_fixed, color: AppTheme.inkBlack, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'TARGET ${_current.word.toUpperCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.inkBlack,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_matchCount > 3 ? 3 : _matchCount}/3',
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
                  const Spacer(),
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
            top: 90,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (_result?.handDetected ?? false) ? AppTheme.mintGreen : AppTheme.signalYellow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.inkBlack, width: 2.5),
              ),
              child: Text(
                (_result?.handDetected ?? false) ? 'HAND DETECTED' : 'SHOW HAND',
                style: const TextStyle(
                  color: AppTheme.inkBlack,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (_matched)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.mintGreen,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.inkBlack, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.inkBlack, blurRadius: 0, offset: Offset(6, 6)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.inkBlack),
                    SizedBox(width: 8),
                    Text(
                      'NICE MOVE',
                      style: TextStyle(
                        color: AppTheme.inkBlack,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
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
              padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
              decoration: BoxDecoration(
                color: AppTheme.warmWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border.all(color: AppTheme.inkBlack, width: 3),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 68,
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.cobaltBlue),
                      ),
                    )
                  : !_hasPermission
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Need camera access to practice.',
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
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _matchCount == 0
                                        ? 'Hold steady'
                                        : 'One more clean sign',
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
                                valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ...List.generate(
                                  3,
                                  (i) => Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: i < _matchCount ? AppTheme.mintGreen : AppTheme.paperCream,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.inkBlack, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _matched ? null : _nextSign,
                                icon: const Icon(Icons.skip_next_rounded),
                                label: const Text('Skip'),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
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
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.inkBlack, width: 3),
          boxShadow: const [
            BoxShadow(color: AppTheme.inkBlack, blurRadius: 0, offset: Offset(3, 3)),
          ],
        ),
        child: Icon(icon, color: AppTheme.inkBlack, size: 20),
      ),
    );
  }
}
