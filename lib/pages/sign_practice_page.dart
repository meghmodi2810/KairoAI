import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sign_detection_service.dart';
import '../theme/app_theme.dart';

/// Camera-based sign language practice page.
/// Opens the native camera via platform channels, runs MediaPipe + TFLite
/// inference, and shows live detection results.
class SignPracticePage extends StatefulWidget {
  /// Optional: the specific sign the user should practice.
  final String? targetSign;

  const SignPracticePage({super.key, this.targetSign});

  @override
  State<SignPracticePage> createState() => _SignPracticePageState();
}

class _SignPracticePageState extends State<SignPracticePage>
    with WidgetsBindingObserver {
  final SignDetectionService _detectionService = SignDetectionService();

  StreamSubscription<DetectionResult>? _subscription;
  DetectionResult? _lastResult;
  bool _isDetecting = false;
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isFrontCamera = true;
  String _statusMessage = 'Initializing camera…';

  // Track if the target sign was successfully detected
  bool _targetMatched = false;
  int _matchCount = 0;
  static const int _requiredMatches = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDetection();
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
    } else if (state == AppLifecycleState.resumed && _hasPermission) {
      _startDetection();
    }
  }

  Future<void> _initializeDetection() async {
    // Check / request camera permission
    bool hasPermission = await _detectionService.checkCameraPermission();
    if (!hasPermission) {
      hasPermission = await _detectionService.requestCameraPermission();
    }

    if (!mounted) return;

    if (!hasPermission) {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
        _statusMessage = 'Camera permission is required for sign practice.';
      });
      return;
    }

    setState(() {
      _hasPermission = true;
    });

    await _startDetection();
  }

  Future<void> _startDetection() async {
    if (_isDetecting) return;

    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Starting camera…';
      });

      await _detectionService.startDetection();
      _isFrontCamera = await _detectionService.isFrontCamera();

      _subscription = _detectionService.detectionStream.listen(
        (result) {
          if (!mounted) return;
          setState(() {
            _lastResult = result;
            _isLoading = false;
            _isDetecting = true;
          });

          // Check if target sign matched
          if (widget.targetSign != null &&
              result.handDetected &&
              result.detectedSign.toUpperCase() ==
                  widget.targetSign!.toUpperCase() &&
              result.confidence > 0.6) {
            _matchCount++;
            if (_matchCount >= _requiredMatches && !_targetMatched) {
              setState(() => _targetMatched = true);
              _showMatchSuccess();
            }
          }
        },
        onError: (error) {
          debugPrint('Detection stream error: $error');
          if (mounted) {
            setState(() {
              _statusMessage = 'Detection error. Tap to retry.';
              _isDetecting = false;
              _isLoading = false;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDetecting = true;
          _isLoading = false;
          _statusMessage = '';
        });
      }
    } catch (e) {
      debugPrint('Error starting detection: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Failed to start camera. Tap to retry.';
        });
      }
    }
  }

  Future<void> _stopDetection() async {
    _subscription?.cancel();
    _subscription = null;
    try {
      await _detectionService.stopDetection();
    } catch (_) {}
    if (mounted) {
      setState(() => _isDetecting = false);
    }
  }

  Future<void> _switchCamera() async {
    try {
      final isFront = await _detectionService.switchCamera();
      if (mounted) {
        setState(() {
          _isFrontCamera = isFront;
          _matchCount = 0;
        });
      }
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  void _showMatchSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppTheme.accentGreen, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Great! You signed "${widget.targetSign}" correctly!',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _darken(AppTheme.accentGreen), width: 3)
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _darken(Color c) {
    var hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen camera area (black background — camera runs natively)
          const SizedBox.expand(),

          // Detection overlay
          if (_isDetecting && _lastResult != null)
            _buildDetectionOverlay(cs),

          // Loading / status overlay
          if (_isLoading || !_hasPermission)
            _buildStatusOverlay(cs),

          // Top bar
          _buildTopBar(cs),

          // Bottom panel
          if (_isDetecting) _buildBottomPanel(cs),
        ],
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Back button
            _circleButton(
              icon: Icons.close_rounded,
              color: AppTheme.textMuted,
              onTap: () {
                _stopDetection();
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            // Target sign badge
            if (widget.targetSign != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _targetMatched
                      ? AppTheme.accentGreen
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _targetMatched ? _darken(AppTheme.accentGreen) : const Color(0xFFE5E5E5), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _targetMatched ? _darken(AppTheme.accentGreen) : const Color(0xFFE5E5E5),
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _targetMatched
                          ? Icons.star_rounded
                          : Icons.gps_fixed_rounded,
                      color: _targetMatched ? Colors.white : AppTheme.primaryIndigo,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sign: ${widget.targetSign}',
                      style: TextStyle(
                        color: _targetMatched ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            // Switch camera
            _circleButton(
              icon: Icons.cameraswitch_rounded,
              color: AppTheme.primaryIndigo,
              onTap: _switchCamera,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E5E5), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE5E5E5),
              offset: Offset(0, 4),
            )
          ]
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildStatusOverlay(ColorScheme cs) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFE5E5E5), width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE5E5E5),
              offset: Offset(0, 8),
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator(color: AppTheme.primaryIndigo, strokeWidth: 6)
            else
              Icon(
                _hasPermission ? Icons.videocam_off_rounded : Icons.no_photography_rounded,
                color: AppTheme.textMuted,
                size: 72,
              ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (!_isLoading && !_hasPermission) ...[
              const SizedBox(height: 24),
              _buildBigActionBtn('Grant Permission', Icons.camera_alt_rounded, _initializeDetection),
            ],
            if (!_isLoading && _hasPermission && !_isDetecting) ...[
              const SizedBox(height: 24),
              _buildBigActionBtn('Retry', Icons.refresh_rounded, _startDetection),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildBigActionBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryIndigo,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _darken(AppTheme.primaryIndigo), width: 2),
          boxShadow: [
            BoxShadow(
              color: _darken(AppTheme.primaryIndigo),
              offset: const Offset(0, 6),
            )
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionOverlay(ColorScheme cs) {
    final result = _lastResult!;
    if (!result.handDetected) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: result.confidence > 0.7
                ? AppTheme.accentGreen
                : result.confidence > 0.4
                    ? AppTheme.accentAmber
                    : AppTheme.errorRed,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: result.confidence > 0.7
                ? _darken(AppTheme.accentGreen)
                : result.confidence > 0.4
                    ? _darken(AppTheme.accentAmber)
                    : _darken(AppTheme.errorRed),
              offset: const Offset(0, 8),
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Detected sign — large display
            Text(
              result.detectedSign.isNotEmpty ? result.detectedSign : '…',
              style: TextStyle(
                color: _confidenceColor(result.confidence),
                fontSize: 72,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            // Confidence bar
            _buildConfidenceBar(result.confidence),
            const SizedBox(height: 12),
            Text(
              result.confidencePercent,
              style: TextStyle(
                color: _confidenceColor(result.confidence),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: confidence,
          minHeight: 16,
          backgroundColor: const Color(0xFFF7F7F7),
          valueColor: AlwaysStoppedAnimation<Color>(
            _confidenceColor(confidence),
          ),
        ),
      ),
    );
  }

  Color _confidenceColor(double c) {
    if (c > 0.7) return AppTheme.accentGreen;
    if (c > 0.4) return AppTheme.accentAmber;
    return AppTheme.errorRed;
  }

  Widget _buildBottomPanel(ColorScheme cs) {
    final result = _lastResult;
    final handDetected = result?.handDetected ?? false;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -4),
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hand status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  handDetected ? Icons.front_hand_rounded : Icons.back_hand_rounded,
                  color: handDetected ? AppTheme.accentGreen : AppTheme.textMuted,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  handDetected
                      ? 'Hand detected — show your sign!'
                      : 'Show your hand to the camera',
                  style: TextStyle(
                    color: handDetected ? AppTheme.accentGreen : AppTheme.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Tips
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildTipChip('💡 Good lighting', AppTheme.accentAmber),
                _buildTipChip('🖐️ Hand in frame', AppTheme.primaryIndigo),
                _buildTipChip(
                    _isFrontCamera ? '📷 Front cam' : '📷 Back cam', AppTheme.accentPink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }
}
