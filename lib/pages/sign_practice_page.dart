import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sign_detection_service.dart';
import '../theme/app_theme.dart';

class SignPracticePage extends StatefulWidget {
  final String? targetSign;

  const SignPracticePage({super.key, this.targetSign});

  @override
  State<SignPracticePage> createState() => _SignPracticePageState();
}

class _SignPracticePageState extends State<SignPracticePage>
    with WidgetsBindingObserver {
  final SignDetectionService _detectionService = SignDetectionService();

  StreamSubscription<DetectionResult>? _subscription;
  DetectionResult? _result;

  bool _detecting = false;
  bool _loading = true;
  bool _hasPermission = false;
  bool _frontCamera = true;
  bool _targetMatched = false;
  int _matchCount = 0;

  static const int _requiredMatches = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopDetection();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopDetection();
    }
    if (state == AppLifecycleState.resumed && _hasPermission) {
      _startDetection();
    }
  }

  Future<void> _initialize() async {
    final allowed = await _detectionService.checkCameraPermission();

    if (!mounted) return;
    setState(() {
      _hasPermission = allowed;
      _loading = false;
    });

    if (allowed) {
      await _startDetection();
    }
  }

  Future<void> _requestCameraPermission() async {
    setState(() => _loading = true);
    final allowed = await _detectionService.requestCameraPermission();
    if (!mounted) return;
    setState(() {
      _hasPermission = allowed;
      _loading = false;
    });
    if (allowed) {
      await _startDetection();
    }
  }

  Future<void> _startDetection({bool retryOnFail = true}) async {
    if (_detecting) return;
    try {
      setState(() => _loading = true);
      await _detectionService.startDetection();
      _frontCamera = await _detectionService.isFrontCamera();

      _subscription = _detectionService.detectionStream.listen(
        (data) {
          if (!mounted) return;
          setState(() {
            _result = data;
            _loading = false;
            _detecting = true;
          });

          if (widget.targetSign != null &&
              data.handDetected &&
              data.detectedSign.toUpperCase() == widget.targetSign!.toUpperCase() &&
              data.confidence > 0.6) {
            _matchCount++;
            if (_matchCount >= _requiredMatches && !_targetMatched) {
              setState(() => _targetMatched = true);
              _showSuccess();
            }
          }
        },
        onError: (error) {
          debugPrint('Practice stream error: $error');
          if (!mounted) return;
          setState(() {
            _loading = false;
            _detecting = false;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _detecting = true;
      });
    } catch (e) {
      debugPrint('Failed to start detection: $e');
      if (retryOnFail && _hasPermission) {
        await Future.delayed(const Duration(milliseconds: 260));
        if (!mounted) return;
        await _startDetection(retryOnFail: false);
        return;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _detecting = false;
      });
    }
  }

  Future<void> _stopDetection() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _detectionService.stopDetection();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _detecting = false);
  }

  Future<void> _switchCamera() async {
    try {
      final value = await _detectionService.switchCamera();
      if (!mounted) return;
      setState(() {
        _frontCamera = value;
        _matchCount = 0;
      });
    } catch (e) {
      debugPrint('Switch camera error: $e');
    }
  }

  void _showSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nice move. Target sign matched.'),
        backgroundColor: AppTheme.mintGreen,
      ),
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence > 0.7) return AppTheme.mintGreen;
    if (confidence > 0.4) return AppTheme.signalYellow;
    return AppTheme.punchRed;
  }

  @override
  Widget build(BuildContext context) {
    final confidence = _result?.confidence ?? 0;
    final confidenceColor = _confidenceColor(confidence);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _detecting && _detectionService.textureId != null
                ? Align(
                    alignment: Alignment.topCenter,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: 480,
                        height: 640,
                        child: Texture(textureId: _detectionService.textureId!),
                      ),
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
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.76),
                    ],
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
                  _circleButton(
                    icon: Icons.close_rounded,
                    onTap: () {
                      _stopDetection();
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  if (widget.targetSign != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _targetMatched ? AppTheme.mintGreen : AppTheme.signalYellow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.inkBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(color: AppTheme.inkBlack, blurRadius: 0, offset: Offset(4, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _targetMatched ? Icons.check_circle : Icons.gps_fixed,
                            color: AppTheme.inkBlack,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'TARGET ${widget.targetSign}',
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  _circleButton(
                    icon: Icons.cameraswitch_rounded,
                    onTap: _switchCamera,
                    background: AppTheme.electricBlue,
                  ),
                ],
              ),
            ),
          ),
          if (_loading || !_hasPermission)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.warmWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.inkBlack, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.inkBlack, blurRadius: 0, offset: Offset(6, 6)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loading)
                      const CircularProgressIndicator(color: AppTheme.cobaltBlue)
                    else
                      const Icon(Icons.no_photography_rounded, color: AppTheme.inkBlack, size: 46),
                    const SizedBox(height: 10),
                    Text(
                      _loading
                          ? 'Starting camera...'
                          : 'Need camera access to practice.',
                      style: const TextStyle(
                        color: AppTheme.inkBlack,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_loading && !_hasPermission) ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _requestCameraPermission,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Grant Permission'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
              decoration: BoxDecoration(
                color: AppTheme.warmWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: AppTheme.inkBlack, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        (_result?.handDetected ?? false) ? Icons.front_hand : Icons.pan_tool_alt,
                        color: (_result?.handDetected ?? false) ? AppTheme.mintGreen : AppTheme.punchRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (_result?.handDetected ?? false)
                              ? 'Hand detected'
                              : 'Show your hand in frame',
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        _frontCamera ? 'FRONT' : 'BACK',
                        style: const TextStyle(
                          color: AppTheme.inkBlack,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.inkBlack, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: confidence,
                              backgroundColor: AppTheme.paperCream,
                              valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppTheme.inkBlack,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  if (widget.targetSign != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ...List.generate(
                          _requiredMatches,
                          (i) => Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: i == _requiredMatches - 1 ? 0 : 6),
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
                    const SizedBox(height: 4),
                    const Text(
                      'Hold steady for 3 clean detections',
                      style: TextStyle(
                        color: AppTheme.inkBlack,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
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
        child: Icon(icon, color: AppTheme.inkBlack),
      ),
    );
  }
}
