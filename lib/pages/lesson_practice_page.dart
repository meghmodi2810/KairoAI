import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import '../services/sign_detection_service.dart';
import '../services/sign_image_service.dart';
import '../theme/app_theme.dart';

/// Full-screen per-lesson camera practice page.
/// Shows each sign from the lesson one at a time:
///   - Top half : reference sign image + sign name
///   - Bottom half: live camera area + detection result overlay
/// Advances automatically on 3 consistent correct detections,
/// or manually via "Next →".
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _detection = SignDetectionService();
  final _imageService = SignImageService();

  StreamSubscription<DetectionResult>? _sub;
  DetectionResult? _lastResult;

  int _signIndex    = 0;
  bool _isCameraOn  = false;
  bool _isLoading   = true;
  bool _hasPermission = false;
  int  _matchCount  = 0;
  bool _matched     = false;
  Set<int> _completed = {};

  // Animation controllers
  late AnimationController _matchAnim;
  late Animation<double>   _matchScale;

  SignModel get _currentSign => widget.signs[_signIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _matchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _matchScale = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _matchAnim, curve: Curves.elasticOut));

    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _matchAnim.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused)  _stopCamera();
    if (state == AppLifecycleState.resumed && _hasPermission) _startCamera();
  }

  // ── Camera lifecycle ──────────────────────────────────────────

  Future<void> _initCamera() async {
    bool ok = await _detection.checkCameraPermission();
    if (!ok) ok = await _detection.requestCameraPermission();
    if (!mounted) return;
    setState(() { _hasPermission = ok; _isLoading = false; });
    if (ok) await _startCamera();
  }

  Future<void> _startCamera() async {
    if (_isCameraOn) return;
    setState(() => _isLoading = true);
    try {
      await _detection.startDetection();
      _sub = _detection.detectionStream.listen(_onDetection, onError: (_) {});
      if (mounted) setState(() { _isCameraOn = true; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _stopCamera() async {
    _sub?.cancel();
    _sub = null;
    try { await _detection.stopDetection(); } catch (_) {}
    if (mounted) setState(() => _isCameraOn = false);
  }

  // ── Detection logic ───────────────────────────────────────────

  void _onDetection(DetectionResult r) {
    if (!mounted || _matched) return;
    setState(() => _lastResult = r);

    final target = _currentSign.word.toUpperCase().trim();
    final detected = r.detectedSign.toUpperCase().trim();

    if (r.handDetected && detected == target && r.confidence >= 0.65) {
      _matchCount++;
      if (_matchCount >= 3) {
        _confirmMatch();
      }
    } else if (r.handDetected && detected != target) {
      // Light penalty — decay match count
      if (_matchCount > 0) _matchCount--;
    }
  }

  void _confirmMatch() {
    if (_matched) return;
    setState(() => _matched = true);
    _completed.add(_signIndex);
    HapticFeedback.heavyImpact();
    _matchAnim.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1200), _nextSign);
  }

  // ── Navigation ────────────────────────────────────────────────

  void _nextSign() {
    if (_signIndex >= widget.signs.length - 1) {
      _finishPractice();
      return;
    }
    if (!mounted) return;
    setState(() {
      _signIndex++;
      _matchCount = 0;
      _matched    = false;
      _lastResult = null;
    });
    _detection.resetPrediction().catchError((_) {});
    _matchAnim.reset();
  }

  void _finishPractice() {
    if (!mounted) return;
    _stopCamera();
    Navigator.pop(context, true); // Return true = practice completed
  }

  // ── Confidence color ─────────────────────────────────────────

  Color _confColor(double c) {
    if (c >= 0.65) return AppTheme.success;
    if (c >= 0.40) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final sign = _currentSign;
    final result = _lastResult;
    final total  = widget.signs.length;
    final progress = (_signIndex + (_matched ? 1 : 0)) / total;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── CAMERA FILLS SCREEN ──
          SizedBox.expand(
            child: _isCameraOn && _detection.textureId != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: 480,
                      height: 640,
                      child: Texture(textureId: _detection.textureId!),
                    ),
                  )
                : const ColoredBox(color: Colors.black),
          ),

          // ── TOP: Reference image + sign info ─────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.40,
            child: _ReferencePanel(
              sign: sign,
              imageService: _imageService,
              matched: _matched,
              matchAnim: _matchScale,
            ),
          ),

          // ── BOTTOM: Detection result card ─────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _DetectionPanel(
              result: result,
              target: sign.word,
              matchCount: _matchCount,
              matched: _matched,
              isCameraOn: _isCameraOn,
              isLoading: _isLoading,
              hasPermission: _hasPermission,
              confColor: _confColor,
              onGrantPermission: _initCamera,
            ),
          ),

          // ── Progress bar ──────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () { _stopCamera(); Navigator.pop(context); },
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _matched ? AppTheme.success : AppTheme.accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_signIndex + 1}/$total',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ]),
                ]),
              ),
            ),
          ),

          // ── "Next →" skip button ─────────────────────────────
          if (!_matched)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 180,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() { _matchCount = 0; _matched = false; });
                  _nextSign();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Skip', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Reference panel (top half) ────────────────────────────────
class _ReferencePanel extends StatelessWidget {
  final SignModel sign;
  final SignImageService imageService;
  final bool matched;
  final Animation<double> matchAnim;

  const _ReferencePanel({
    required this.sign,
    required this.imageService,
    required this.matched,
    required this.matchAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            matched
                ? AppTheme.success.withValues(alpha: 0.4)
                : const Color(0xFF0D0D12).withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
          child: Row(children: [
            // Reference image
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FutureBuilder<dynamic>(
                  future: imageService.getRandomImage(sign.word),
                  builder: (ctx, snap) {
                    if (snap.hasData && snap.data != null) {
                      return Image.memory(snap.data!, fit: BoxFit.contain);
                    }
                    return Container(
                      color: Colors.white.withValues(alpha: 0.05),
                      child: Center(
                        child: Text(sign.word.toUpperCase()[0],
                          style: TextStyle(
                            color: AppTheme.accent.withValues(alpha: 0.6),
                            fontSize: 72, fontWeight: FontWeight.w900)),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Sign name + match indicator
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sign this:', style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(sign.word, style: const TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  if (sign.word.length == 1 && sign.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(sign.description, style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 11), maxLines: 3),
                  ],
                  const SizedBox(height: 12),
                  // Match indicator dots
                  if (matched)
                    ScaleTransition(
                      scale: matchAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.success.withValues(alpha: 0.5)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: const [
                          Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 16),
                          SizedBox(width: 6),
                          Text('Matched!', style: TextStyle(
                            color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Detection panel (bottom card) ─────────────────────────────
class _DetectionPanel extends StatelessWidget {
  final DetectionResult? result;
  final String target;
  final int matchCount;
  final bool matched;
  final bool isCameraOn;
  final bool isLoading;
  final bool hasPermission;
  final Color Function(double) confColor;
  final VoidCallback onGrantPermission;

  const _DetectionPanel({
    required this.result,
    required this.target,
    required this.matchCount,
    required this.matched,
    required this.isCameraOn,
    required this.isLoading,
    required this.hasPermission,
    required this.confColor,
    required this.onGrantPermission,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12).withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Container(width: 36, height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        if (isLoading)
          const SizedBox(height: 60,
            child: Center(child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)))
        else if (!hasPermission)
          _PermissionView(onGrant: onGrantPermission)
        else if (!isCameraOn)
          const SizedBox(height: 60,
            child: Center(child: Text('Camera starting…',
              style: TextStyle(color: Colors.white54, fontSize: 14))))
        else
          _LiveResult(
            result: result,
            target: target,
            matchCount: matchCount,
            matched: matched,
            confColor: confColor,
          ),
      ]),
    );
  }
}

// Live detection result display
class _LiveResult extends StatelessWidget {
  final DetectionResult? result;
  final String target;
  final int matchCount;
  final bool matched;
  final Color Function(double) confColor;

  const _LiveResult({
    required this.result,
    required this.target,
    required this.matchCount,
    required this.matched,
    required this.confColor,
  });

  @override
  Widget build(BuildContext context) {
    final r = result;
    final handDetected = r?.handDetected ?? false;
    final detected  = r?.detectedSign ?? '';
    final confidence = r?.confidence ?? 0.0;
    final isCorrect = handDetected && detected.toUpperCase() == target.toUpperCase();
    final displayColor = isCorrect ? AppTheme.success : (handDetected ? confColor(confidence) : Colors.white38);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Status line
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          handDetected ? Icons.front_hand_rounded : Icons.pan_tool_outlined,
          color: handDetected ? AppTheme.success : Colors.white30,
          size: 18),
        const SizedBox(width: 8),
        Text(
          handDetected ? 'Hand detected' : 'Show your hand to the camera',
          style: TextStyle(
            color: handDetected ? AppTheme.success : Colors.white38,
            fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 14),

      // Detected sign large display
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: displayColor,
            fontSize: 64,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
          child: Text(detected.isNotEmpty ? detected : '—'),
        ),
        if (handDetected && detected.isNotEmpty) ...[
          const SizedBox(width: 12),
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isCorrect ? AppTheme.success : Colors.white24,
            size: 28),
        ],
      ]),

      if (handDetected && confidence > 0) ...[
        const SizedBox(height: 8),
        // Confidence bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(confColor(confidence)),
          ),
        ),
        const SizedBox(height: 4),
        Text('${(confidence * 100).toStringAsFixed(0)}% confidence',
          style: TextStyle(color: Colors.white38, fontSize: 11)),
      ],

      const SizedBox(height: 14),

      // Match progress dots (need 3 to confirm)
      if (handDetected)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < matchCount
                    ? (matched ? AppTheme.success : AppTheme.accent)
                    : Colors.white12,
                boxShadow: i < matchCount
                    ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 6)]
                    : null,
              ),
            ),
          )),
          const SizedBox(width: 8),
          Text('Hold sign for 3 detections',
            style: TextStyle(color: Colors.white30, fontSize: 11)),
        ]),
    ]);
  }
}

class _PermissionView extends StatelessWidget {
  final VoidCallback onGrant;
  const _PermissionView({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 40),
      const SizedBox(height: 8),
      const Text('Camera permission needed', style: TextStyle(color: Colors.white60, fontSize: 14)),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: onGrant,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Grant Permission')),
    ]);
  }
}
