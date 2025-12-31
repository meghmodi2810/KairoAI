import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../models/app_models.dart';
import '../services/database_service.dart';
import '../services/sign_detection_service.dart';

class PracticePage extends StatefulWidget {
  final LessonModel lesson;
  final String categoryId;
  final List<SignModel> signs;

  const PracticePage({
    super.key,
    required this.lesson,
    required this.categoryId,
    required this.signs,
  });

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  final SignDetectionService _detectionService = SignDetectionService();

  // Camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFrontCamera = true;

  // Practice state
  int _currentSignIndex = 0;
  bool _isDetecting = false;
  String _detectedSign = '';
  double _confidence = 0.0;
  bool _handDetected = false;

  // Results
  List<bool> _results = [];
  int _correctCount = 0;
  DateTime? _startTime;

  // Feedback overlay
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';

  // Stream subscription
  StreamSubscription<DetectionResult>? _detectionSubscription;

  // Theme colors
  static const Color darkBlue = Color(0xFF141938);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color cardBg = Color(0xFF252A5E);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color errorRed = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTime = DateTime.now();
    _results = List.filled(widget.signs.length, false);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionSubscription?.cancel();
    _stopDetection();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _stopDetection();
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final frontCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );
        await _initializeCameraController(frontCamera);
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _initializeCameraController(CameraDescription camera) async {
    _cameraController?.dispose();

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera controller: $e');
    }
  }

  void _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isCameraInitialized = false;
    });

    final newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == (_isFrontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back),
      orElse: () => _cameras.first,
    );

    await _initializeCameraController(newCamera);
  }

  void _startDetection() async {
    if (_isDetecting) return;

    setState(() {
      _isDetecting = true;
    });

    // Use native detection service
    _detectionSubscription = _detectionService.detectionStream.listen((result) {
      if (mounted && _isDetecting) {
        setState(() {
          _handDetected = result.handDetected;
          _detectedSign = result.detectedSign;
          _confidence = result.confidence;
        });

        // Check if detected sign matches current sign
        _checkSign();
      }
    });

    await _detectionService.startDetection();
  }

  void _stopDetection() {
    _detectionSubscription?.cancel();
    _detectionService.stopDetection();
    setState(() {
      _isDetecting = false;
    });
  }

  void _checkSign() {
    if (!_isDetecting) return;

    final currentSign = widget.signs[_currentSignIndex];
    final targetWord = currentSign.word.toLowerCase();
    final detected = _detectedSign.toLowerCase();

    // Check if sign matches (with confidence threshold)
    if (detected == targetWord && _confidence >= 0.7) {
      _onSignCorrect();
    }
  }

  void _onSignCorrect() {
    _stopDetection();
    
    setState(() {
      _results[_currentSignIndex] = true;
      _correctCount++;
      _showFeedback = true;
      _isCorrect = true;
      _feedbackMessage = 'Perfect! 🎉';
    });

    // Mark sign as completed
    _databaseService.completeSign(widget.lesson.id, widget.signs[_currentSignIndex].id);

    // Auto-advance after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _nextSign();
      }
    });
  }

  void _skipSign() {
    _stopDetection();
    
    setState(() {
      _results[_currentSignIndex] = false;
      _showFeedback = true;
      _isCorrect = false;
      _feedbackMessage = 'Skipped';
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _nextSign();
      }
    });
  }

  // ignore: unused_element
  void _retrySign() {
    setState(() {
      _showFeedback = false;
    });
    _startDetection();
  }

  void _nextSign() {
    setState(() {
      _showFeedback = false;
    });

    if (_currentSignIndex < widget.signs.length - 1) {
      setState(() {
        _currentSignIndex++;
      });
    } else {
      _completeLesson();
    }
  }

  void _completeLesson() async {
    final timeSpent = DateTime.now().difference(_startTime!).inSeconds;
    final accuracy = _correctCount / widget.signs.length;

    await _databaseService.completeLesson(
      lessonId: widget.lesson.id,
      categoryId: widget.categoryId,
      accuracy: accuracy,
      timeSpentSeconds: timeSpent,
      gemsEarned: widget.lesson.gemsReward,
      coinsEarned: widget.lesson.coinsReward,
      xpEarned: widget.lesson.xpReward,
      signsCount: widget.signs.length,
    );

    if (mounted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final accuracy = (_correctCount / widget.signs.length * 100).toInt();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Lesson Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildStatRow('Accuracy', '$accuracy%'),
              _buildStatRow('Correct', '$_correctCount/${widget.signs.length}'),
              _buildStatRow('Gems', '+${widget.lesson.gemsReward}'),
              _buildStatRow('Coins', '+${widget.lesson.coinsReward}'),
              _buildStatRow('XP', '+${widget.lesson.xpReward}'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close practice
                    Navigator.pop(context); // Close lesson detail
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentYellow,
                    foregroundColor: darkBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              color: accentYellow,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(child: _buildCameraView()),
            _buildCurrentSign(),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _stopDetection();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          Expanded(
            child: Text(
              widget.lesson.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: widget.signs.asMap().entries.map((entry) {
          final index = entry.key;
          final isCompleted = _results[index];
          final isCurrent = index == _currentSignIndex;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 6,
              decoration: BoxDecoration(
                color: isCompleted
                    ? successGreen
                    : isCurrent
                        ? accentYellow
                        : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCameraView() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _handDetected ? successGreen : Colors.white.withOpacity(0.2),
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            if (_isCameraInitialized && _cameraController != null)
              CameraPreview(_cameraController!)
            else
              Container(
                color: cardBg,
                child: const Center(
                  child: CircularProgressIndicator(color: accentYellow),
                ),
              ),
            
            // Detection overlay
            if (_isDetecting)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _handDetected ? successGreen : errorRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _handDetected ? 'Hand Detected' : 'Show Your Hand',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Detected sign info
            if (_isDetecting && _detectedSign.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detected: $_detectedSign',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '${(_confidence * 100).toInt()}%',
                        style: const TextStyle(
                          color: accentYellow,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Feedback overlay
            if (_showFeedback)
              Container(
                color: _isCorrect
                    ? successGreen.withOpacity(0.8)
                    : errorRed.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCorrect ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _feedbackMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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

  Widget _buildCurrentSign() {
    if (_currentSignIndex >= widget.signs.length) return const SizedBox.shrink();
    
    final currentSign = widget.signs[_currentSignIndex];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🤟', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign "${currentSign.word}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (currentSign.wordInHindi != null)
                  Text(
                    currentSign.wordInHindi!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Skip button
          Expanded(
            child: OutlinedButton(
              onPressed: _skipSign,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Skip'),
            ),
          ),
          const SizedBox(width: 12),
          // Main action button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isDetecting ? _stopDetection : _startDetection,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDetecting ? errorRed : accentYellow,
                foregroundColor: _isDetecting ? Colors.white : darkBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isDetecting ? Icons.stop : Icons.videocam),
                  const SizedBox(width: 8),
                  Text(
                    _isDetecting ? 'Stop' : 'Start Detection',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
